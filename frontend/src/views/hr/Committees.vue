<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { 
  ShieldCheck, Users, Plus, Search, Filter, Calendar, Building2, 
  MoreVertical, Edit2, Trash2, Eye, UserPlus, CheckCircle2, 
  AlertCircle, ChevronRight, X, Clock, FileText, Award, Gavel, 
  Scale, Shield, UserCheck, Check, Info
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import BaseTabs from '../../components/BaseTabs.vue';
import UnderlineTabs from '../../components/UnderlineTabs.vue';
import MetricCard from '../../components/MetricCard.vue';
import BaseButton from '../../components/BaseButton.vue';
import BasePagination from '../../components/BasePagination.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';

// ─── Types & Interfaces ───
export type CommitteeRole = 'chair' | 'member' | 'secretary' | 'treasurer' | 'observer';
export type RowState = 'active' | 'inactive';

export interface Committee {
  id: number;
  uuid: string;
  code: string;
  name: string;
  name_am?: string;
  description: string;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  category: 'disciplinary' | 'grievance' | 'recruitment' | 'safety' | 'audit' | 'general';
  start_date: string;
  end_date?: string | null; // null = standing committee
  user_id: number;
  state: RowState;
}

export interface CommitteeMember {
  id: number;
  uuid: string;
  tenant_id: number;
  entity_id: number;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  avatar?: string;
  department: string;
  committee_id: number;
  committee_code?: string;
  committee_name?: string;
  role_lookup_value_id: CommitteeRole;
  start_date: string;
  end_date?: string | null;
  user_id: number;
  state: RowState;
}

// ─── Initial Seed Data ───
const initialCommittees: Committee[] = [
  {
    id: 1,
    uuid: 'cmt_001-disc',
    code: 'CMT-DISC',
    name: 'Disciplinary Hearing Committee',
    name_am: 'የዲሲፕሊን ሰሚ ኮሚቴ',
    description: 'Adjudicates formal code-of-conduct violations, integrity breaches, and recommends statutory employment actions in accordance with Ethiopian Labour Proclamation.',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Enterprise Group (HQ)',
    category: 'disciplinary',
    start_date: '2022-01-10',
    end_date: null, // Standing
    user_id: 101,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'cmt_002-grv',
    code: 'CMT-GRV',
    name: 'Workplace Grievance Redressal Committee',
    name_am: 'የቅሬታ ሰሚ ኮሚቴ',
    description: 'Receives and investigates workplace disputes, interpersonal conflicts, harassment allegations, and compensation fairness appeals.',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Enterprise Group (HQ)',
    category: 'grievance',
    start_date: '2022-01-10',
    end_date: null, // Standing
    user_id: 101,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'cmt_003-rec',
    code: 'CMT-REC',
    name: 'Executive & Senior Recruitment Panel',
    name_am: 'የቅጥርና ምልመላ ኮሚቴ',
    description: 'Oversees candidate screening, structured panel interviews, background verifications, and salary band alignment for management positions.',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    category: 'recruitment',
    start_date: '2026-01-05',
    end_date: null, // Standing
    user_id: 104,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'cmt_004-safe',
    code: 'CMT-SAFE',
    name: 'Occupational Safety & Health (OSH) Committee',
    name_am: 'የደህንነትና ጤና ኮሚቴ',
    description: 'Monitors warehouse safety protocols, hazard mitigation, fire drills, and statutory industrial hygiene compliance across all facilities.',
    tenant_id: 1,
    entity_id: 9,
    entity_name: 'Kality Logistics & Storage Hub',
    category: 'safety',
    start_date: '2025-03-01',
    end_date: null, // Standing
    user_id: 102,
    state: 'active'
  },
  {
    id: 5,
    uuid: 'cmt_005-aud',
    code: 'CMT-AUD',
    name: 'Annual Stock Count & Asset Audit Panel',
    name_am: 'የዓመታዊ ቆጠራና ኦዲት ኮሚቴ',
    description: 'Ad-hoc multi-departmental panel conducting physical stock verification, reconciliation with general ledger, and scrap write-off inspections.',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    category: 'audit',
    start_date: '2026-06-01',
    end_date: '2026-06-30', // Ad-hoc
    user_id: 103,
    state: 'active'
  }
];

const initialMembers: CommitteeMember[] = [
  // Committee 1: Disciplinary
  { id: 1, uuid: 'cmm_1', tenant_id: 1, entity_id: 3, employee_id: 7, employee_name: 'Yohannes Girma', employee_code: 'EMP-007', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80', department: 'Legal & Compliance', committee_id: 1, role_lookup_value_id: 'chair', start_date: '2022-01-10', end_date: null, user_id: 101, state: 'active' },
  { id: 2, uuid: 'cmm_2', tenant_id: 1, entity_id: 3, employee_id: 14, employee_name: 'Tigist Assefa', employee_code: 'EMP-014', avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80', department: 'Human Resources', committee_id: 1, role_lookup_value_id: 'secretary', start_date: '2022-01-10', end_date: null, user_id: 101, state: 'active' },
  { id: 3, uuid: 'cmm_3', tenant_id: 1, entity_id: 3, employee_id: 22, employee_name: 'Dawit Yohannes', employee_code: 'EMP-022', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80', department: 'Operations', committee_id: 1, role_lookup_value_id: 'member', start_date: '2022-01-10', end_date: null, user_id: 101, state: 'active' },
  { id: 4, uuid: 'cmm_4', tenant_id: 1, entity_id: 3, employee_id: 31, employee_name: 'Bethlehem Haile', employee_code: 'EMP-031', avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=100&auto=format&fit=crop&q=80', department: 'Finance & Accounts', committee_id: 1, role_lookup_value_id: 'treasurer', start_date: '2022-01-10', end_date: null, user_id: 101, state: 'active' },
  
  // Committee 2: Grievance
  { id: 5, uuid: 'cmm_5', tenant_id: 1, entity_id: 3, employee_id: 44, employee_name: 'Marta Tadesse', employee_code: 'EMP-044', avatar: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=100&auto=format&fit=crop&q=80', department: 'Administration', committee_id: 2, role_lookup_value_id: 'chair', start_date: '2022-01-10', end_date: null, user_id: 101, state: 'active' },
  { id: 6, uuid: 'cmm_6', tenant_id: 1, entity_id: 3, employee_id: 52, employee_name: 'Solomon Bekele', employee_code: 'EMP-052', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=80', department: 'Quality Assurance', committee_id: 2, role_lookup_value_id: 'member', start_date: '2022-01-10', end_date: null, user_id: 101, state: 'active' },
  { id: 7, uuid: 'cmm_7', tenant_id: 1, entity_id: 3, employee_id: 61, employee_name: 'Senait Desta', employee_code: 'EMP-061', avatar: 'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?w=100&auto=format&fit=crop&q=80', department: 'Internal Audit', committee_id: 2, role_lookup_value_id: 'observer', start_date: '2022-01-10', end_date: null, user_id: 101, state: 'active' },

  // Committee 3: Recruitment
  { id: 8, uuid: 'cmm_8', tenant_id: 1, entity_id: 7, employee_id: 14, employee_name: 'Tigist Assefa', employee_code: 'EMP-014', avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100&auto=format&fit=crop&q=80', department: 'Human Resources', committee_id: 3, role_lookup_value_id: 'chair', start_date: '2026-01-05', end_date: null, user_id: 104, state: 'active' },
  { id: 9, uuid: 'cmm_9', tenant_id: 1, entity_id: 7, employee_id: 73, employee_name: 'Kassahun Belay', employee_code: 'EMP-073', avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&auto=format&fit=crop&q=80', department: 'Branch Management', committee_id: 3, role_lookup_value_id: 'member', start_date: '2026-01-05', end_date: null, user_id: 104, state: 'active' },

  // Committee 4: Safety
  { id: 10, uuid: 'cmm_10', tenant_id: 1, entity_id: 9, employee_id: 88, employee_name: 'Yared Tsegaye', employee_code: 'EMP-088', avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&auto=format&fit=crop&q=80', department: 'Procurement & Logistics', committee_id: 4, role_lookup_value_id: 'chair', start_date: '2025-03-01', end_date: null, user_id: 102, state: 'active' },
  { id: 11, uuid: 'cmm_11', tenant_id: 1, entity_id: 9, employee_id: 95, employee_name: 'Abel Tesfaye', employee_code: 'EMP-095', avatar: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=100&auto=format&fit=crop&q=80', department: 'Facility & Safety', committee_id: 4, role_lookup_value_id: 'secretary', start_date: '2025-03-01', end_date: null, user_id: 102, state: 'active' },

  // Committee 5: Stock Audit (Ad-Hoc)
  { id: 12, uuid: 'cmm_12', tenant_id: 1, entity_id: 7, employee_id: 31, employee_name: 'Bethlehem Haile', employee_code: 'EMP-031', avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=100&auto=format&fit=crop&q=80', department: 'Finance & Accounts', committee_id: 5, role_lookup_value_id: 'chair', start_date: '2026-06-01', end_date: '2026-06-30', user_id: 103, state: 'active' },
  { id: 13, uuid: 'cmm_13', tenant_id: 1, entity_id: 7, employee_id: 22, employee_name: 'Dawit Yohannes', employee_code: 'EMP-022', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80', department: 'Operations', committee_id: 5, role_lookup_value_id: 'member', start_date: '2026-06-01', end_date: '2026-06-30', user_id: 103, state: 'active' }
];

// ─── Reactive State ───
const committees = ref<Committee[]>([]);
const members = ref<CommitteeMember[]>([]);

const loadData = () => {
  const c = localStorage.getItem('haleta_erp_committees');
  committees.value = c ? JSON.parse(c) : initialCommittees;

  const m = localStorage.getItem('haleta_erp_committee_members');
  members.value = m ? JSON.parse(m) : initialMembers;
};

const saveData = () => {
  localStorage.setItem('haleta_erp_committees', JSON.stringify(committees.value));
  localStorage.setItem('haleta_erp_committee_members', JSON.stringify(members.value));
};

onMounted(() => {
  loadData();
  window.addEventListener('click', closeMenu);
});

onUnmounted(() => {
  window.removeEventListener('click', closeMenu);
});

// ─── Primary Tabs Standard (BaseTabs) ───
type MainView = 'panels_overview' | 'committees_table' | 'members_directory';
const activeMainTab = ref<MainView>('panels_overview');

const mainTabs = [
  { id: 'panels_overview' as const, label: 'Panels Overview', icon: ShieldCheck },
  { id: 'committees_table' as const, label: 'Committees Registry', icon: Building2 },
  { id: 'members_directory' as const, label: 'Appointed Members Roster', icon: Users }
];

// ─── Secondary Filter Tabs (UnderlineTabs) ───
type CategoryFilter = 'all' | 'standing' | 'adhoc' | 'disciplinary' | 'recruitment_safety';
const activeCategoryFilter = ref<CategoryFilter>('all');

const categoryTabs = computed(() => [
  { id: 'all' as const, label: 'All Committees', count: committees.value.length },
  { id: 'standing' as const, label: 'Standing Panels', count: committees.value.filter(c => !c.end_date).length },
  { id: 'adhoc' as const, label: 'Ad-Hoc / Special', count: committees.value.filter(c => !!c.end_date).length },
  { id: 'disciplinary' as const, label: 'Disciplinary & Grievance', count: committees.value.filter(c => c.category === 'disciplinary' || c.category === 'grievance').length },
  { id: 'recruitment_safety' as const, label: 'Recruitment & Safety', count: committees.value.filter(c => c.category === 'recruitment' || c.category === 'safety').length }
]);

// ─── Search & Filtering ───
const searchQuery = ref('');
const entityFilter = ref('All');
const roleFilter = ref('All');

const filteredCommittees = computed(() => {
  return committees.value.filter(c => {
    const matchesSearch = 
      c.name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      c.code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      c.entity_name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      c.description.toLowerCase().includes(searchQuery.value.toLowerCase());

    const matchesEntity = entityFilter.value === 'All' || c.entity_name === entityFilter.value;

    let matchesCategory = true;
    if (activeCategoryFilter.value === 'standing') matchesCategory = !c.end_date;
    else if (activeCategoryFilter.value === 'adhoc') matchesCategory = !!c.end_date;
    else if (activeCategoryFilter.value === 'disciplinary') matchesCategory = c.category === 'disciplinary' || c.category === 'grievance';
    else if (activeCategoryFilter.value === 'recruitment_safety') matchesCategory = c.category === 'recruitment' || c.category === 'safety';

    return matchesSearch && matchesEntity && matchesCategory;
  });
});

const filteredMembers = computed(() => {
  return members.value.map(m => {
    const parent = committees.value.find(c => c.id === m.committee_id);
    return {
      ...m,
      committee_code: parent?.code || 'CMT',
      committee_name: parent?.name || 'Committee'
    };
  }).filter(m => {
    const matchesSearch = 
      m.employee_name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      m.employee_code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      m.department.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      (m.committee_name && m.committee_name.toLowerCase().includes(searchQuery.value.toLowerCase()));

    const matchesRole = roleFilter.value === 'All' || m.role_lookup_value_id === roleFilter.value;
    return matchesSearch && matchesRole;
  });
});

// ─── Action Menu & Modals ───
const openActionMenuId = ref<number | null>(null);
const toggleMenu = (e: MouseEvent, id: number) => {
  e.stopPropagation();
  openActionMenuId.value = openActionMenuId.value === id ? null : id;
};
const closeMenu = () => {
  openActionMenuId.value = null;
};

// Committee Details Slide-over Drawer
const selectedCommitteeForView = ref<Committee | null>(null);
const showDetailDrawer = ref(false);

const openCommitteeDetails = (c: Committee) => {
  selectedCommitteeForView.value = c;
  showDetailDrawer.value = true;
};

const getCommitteeMembers = (committeeId: number) => {
  return members.value.filter(m => m.committee_id === committeeId);
};

const getCommitteeChair = (committeeId: number) => {
  return members.value.find(m => m.committee_id === committeeId && m.role_lookup_value_id === 'chair') || null;
};

// ─── Formatters & Role Badges ───
const formatRole = (role: CommitteeRole) => {
  const map: Record<string, string> = {
    chair: 'Committee Chair',
    member: 'Panel Member',
    secretary: 'Secretary / Rapporteur',
    treasurer: 'Treasurer',
    observer: 'Independent Observer'
  };
  return map[role] || role;
};

const getRolePillClass = (role: CommitteeRole) => {
  if (role === 'chair') return 'pill-chair';
  if (role === 'secretary') return 'pill-secretary';
  if (role === 'treasurer') return 'pill-treasurer';
  if (role === 'observer') return 'pill-observer';
  return 'pill-member';
};

// ─── Create Committee Modal (<= 5 Required Fields Standard) ───
const showCreateCommitteeModal = ref(false);
const committeeForm = ref({
  code: '',
  name: '',
  entity_name: 'Haleta Enterprise Group (HQ)',
  category: 'disciplinary' as Committee['category'],
  start_date: '2026-01-01',
  end_date: '',
  description: ''
});

const handleSaveCommittee = () => {
  if (!committeeForm.value.code || !committeeForm.value.name) {
    alert('Please enter committee code and name.');
    return;
  }

  const nextId = committees.value.length ? Math.max(...committees.value.map(c => c.id)) + 1 : 1;
  const newCmt: Committee = {
    id: nextId,
    uuid: `cmt_${nextId.toString().padStart(3, '0')}-${committeeForm.value.code.toLowerCase().replace(/[^a-z0-9]/g, '')}`,
    code: committeeForm.value.code.toUpperCase(),
    name: committeeForm.value.name,
    description: committeeForm.value.description || 'Statutory committee established under Haleta corporate governance charter.',
    tenant_id: 1,
    entity_id: 3,
    entity_name: committeeForm.value.entity_name,
    category: committeeForm.value.category,
    start_date: committeeForm.value.start_date,
    end_date: committeeForm.value.end_date || null,
    user_id: 101,
    state: 'active'
  };

  committees.value.unshift(newCmt);
  saveData();
  showCreateCommitteeModal.value = false;
};

// ─── Add Member Modal ───
const showAddMemberModal = ref(false);
const memberForm = ref({
  committee_id: 1,
  employee_name: '',
  employee_code: 'EMP-102',
  department: 'Human Resources',
  role_lookup_value_id: 'member' as CommitteeRole,
  start_date: '2026-01-10',
  end_date: ''
});

const openAddMemberForCommittee = (committeeId: number) => {
  memberForm.value.committee_id = committeeId;
  showAddMemberModal.value = true;
};

const handleSaveMember = () => {
  if (!memberForm.value.employee_name) {
    alert('Please enter employee name.');
    return;
  }

  const nextId = members.value.length ? Math.max(...members.value.map(m => m.id)) + 1 : 1;
  const newMem: CommitteeMember = {
    id: nextId,
    uuid: `cmm_${nextId}`,
    tenant_id: 1,
    entity_id: 3,
    employee_id: Math.floor(100 + Math.random() * 900),
    employee_name: memberForm.value.employee_name,
    employee_code: memberForm.value.employee_code || `EMP-${nextId}`,
    avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&auto=format&fit=crop&q=80',
    department: memberForm.value.department,
    committee_id: memberForm.value.committee_id,
    role_lookup_value_id: memberForm.value.role_lookup_value_id,
    start_date: memberForm.value.start_date,
    end_date: memberForm.value.end_date || null,
    user_id: 101,
    state: 'active'
  };

  members.value.push(newMem);
  saveData();
  showAddMemberModal.value = false;
};

const deleteMember = (id: number) => {
  if (!confirm('Remove this appointed member from the committee?')) return;
  members.value = members.value.filter(m => m.id !== id);
  saveData();
};

const deleteCommittee = (id: number) => {
  if (!confirm('Are you sure you want to dissolve/remove this committee?')) return;
  committees.value = committees.value.filter(c => c.id !== id);
  members.value = members.value.filter(m => m.committee_id !== id);
  saveData();
  if (selectedCommitteeForView.value?.id === id) {
    showDetailDrawer.value = false;
  }
};
</script>

<template>
  <div class="committees-page">
    <!-- Breadcrumb Standard -->
    <div class="page-breadcrumb-bar">
      <AppBreadcrumb 
        :items="[
          { label: 'Human Resources', to: '/hr' },
          { label: 'Committees & Governance Panels' }
        ]" 
      />
    </div>

    <!-- Header Area -->
    <div class="page-header-row">
      <div class="page-title-group">
        <h1 class="page-title">Committees & Governance Panels</h1>
        <p class="page-subtitle">Multi-member panels for disciplinary hearings, workplace grievances, safety, and recruitment governance.</p>
      </div>
      <div class="page-actions-group">
        <BaseButton variant="outline" size="md">
          <FileText :size="15" />
          <span>Export Charters</span>
        </BaseButton>
        <BaseButton variant="primary" size="md" @click="showCreateCommitteeModal = true">
          <Plus :size="16" />
          <span>Create Committee</span>
        </BaseButton>
      </div>
    </div>

    <!-- KPI Metric Cards Standard -->
    <div class="metrics-grid">
      <MetricCard 
        label="Total Panels" 
        :value="committees.length" 
        subtext="Active Governance Charters"
        trend="2 New"
        trend-type="up"
        :icon="ShieldCheck"
      />
      <MetricCard 
        label="Standing Panels" 
        :value="committees.filter(c => !c.end_date).length" 
        subtext="Permanent Statutory Bodies"
        :icon="Building2"
      />
      <MetricCard 
        label="Ad-Hoc Committees" 
        :value="committees.filter(c => !!c.end_date).length" 
        subtext="Time-bound Audit & Reviews"
        :icon="Clock"
      />
      <MetricCard 
        label="Appointed Members" 
        :value="members.length" 
        subtext="Serving across all panels"
        :icon="Users"
      />
    </div>

    <!-- Primary Tab Bar Standard (BaseTabs) -->
    <div class="main-tabs-container">
      <BaseTabs 
        v-model="activeMainTab"
        :tabs="mainTabs"
        size="md"
      />
    </div>

    <!-- Sub-Filters Bar Standard (UnderlineTabs) -->
    <div class="sub-tabs-container">
      <UnderlineTabs 
        v-model="activeCategoryFilter"
        :tabs="categoryTabs"
        size="md"
        justify="start"
      />
    </div>

    <!-- Toolbar: Search & Filter Controls -->
    <div class="table-toolbar">
      <div class="toolbar-left">
        <div class="search-input-box">
          <Search :size="15" class="search-icon" />
          <input 
            type="text" 
            v-model="searchQuery" 
            class="custom-search-input"
          />
        </div>
        <div class="filter-select-wrap">
          <FormSelect 
            v-model="entityFilter"
            :options="['All', 'Haleta Enterprise Group (HQ)', 'Bole Commercial Branch', 'Kality Logistics & Storage Hub']"
          />
        </div>
      </div>
      <div class="toolbar-right">
        <span class="entries-counter">
          {{ activeMainTab === 'members_directory' ? `${filteredMembers.length} Appointees` : `${filteredCommittees.length} Committees` }}
        </span>
      </div>
    </div>

    <!-- TAB 1: PANELS OVERVIEW (CARDS + ROSTER) -->
    <div v-if="activeMainTab === 'panels_overview'" class="panels-overview-grid">
      <div 
        v-for="cmt in filteredCommittees" 
        :key="cmt.id" 
        class="committee-card"
        @click="openCommitteeDetails(cmt)"
      >
        <!-- Card Header -->
        <div class="card-top-row">
          <div class="code-and-cat">
            <span class="cmt-code-badge">{{ cmt.code }}</span>
            <span :class="['standing-pill', cmt.end_date ? 'pill-adhoc' : 'pill-standing']">
              {{ cmt.end_date ? 'Ad-Hoc Panel' : 'Standing Committee' }}
            </span>
          </div>
          <button class="btn-card-dots" @click.stop="toggleMenu($event, cmt.id)">
            <MoreVertical :size="15" />
          </button>
        </div>

        <!-- Committee Title & Entity -->
        <div class="card-title-section">
          <h3 class="cmt-name">{{ cmt.name }}</h3>
          <div class="cmt-entity-row">
            <Building2 :size="13" />
            <span>{{ cmt.entity_name }}</span>
          </div>
        </div>

        <!-- Description / Mandate -->
        <p class="cmt-mandate">{{ cmt.description }}</p>

        <!-- Chair & Members Preview -->
        <div class="members-summary-box">
          <div class="chair-info-row" v-if="getCommitteeChair(cmt.id)">
            <span class="chair-lbl">Chairperson:</span>
            <div class="chair-chip">
              <img :src="getCommitteeChair(cmt.id)?.avatar || 'https://i.pravatar.cc/100?u=' + cmt.id" class="chair-avatar" />
              <span class="chair-name">{{ getCommitteeChair(cmt.id)?.employee_name }}</span>
            </div>
          </div>

          <div class="roster-avatars-row">
            <div class="avatar-stack">
              <img 
                v-for="m in getCommitteeMembers(cmt.id).slice(0, 4)" 
                :key="m.id" 
                :src="m.avatar || 'https://i.pravatar.cc/100?u=' + m.id" 
                :title="`${m.employee_name} (${m.role_lookup_value_id})`"
                class="stack-avatar"
              />
              <span v-if="getCommitteeMembers(cmt.id).length > 4" class="stack-more">
                +{{ getCommitteeMembers(cmt.id).length - 4 }}
              </span>
            </div>
            <span class="member-count-text">{{ getCommitteeMembers(cmt.id).length }} Appointees</span>
          </div>
        </div>

        <!-- Footer: Dates & Quick Action -->
        <div class="card-footer-row">
          <div class="dates-meta">
            <Calendar :size="12" />
            <span>Since {{ cmt.start_date }}</span>
          </div>
          <button class="btn-manage-link" @click.stop="openAddMemberForCommittee(cmt.id)">
            <UserPlus :size="13" />
            <span>Add Member</span>
          </button>
        </div>
      </div>

      <div v-if="filteredCommittees.length === 0" class="empty-panels-box">
        <Info :size="32" class="text-gray-400" />
        <p>No committees found matching your filter criteria.</p>
        <BaseButton variant="primary" size="sm" @click="showCreateCommitteeModal = true">
          <Plus :size="14" />
          <span>Create New Committee</span>
        </BaseButton>
      </div>
    </div>

    <!-- TAB 2: COMMITTEES REGISTRY (FULL DATA TABLE) -->
    <div v-else-if="activeMainTab === 'committees_table'" class="table-card-wrapper">
      <div class="table-container">
        <table class="erp-table">
          <thead>
            <tr>
              <th style="width: 140px;">Code</th>
              <th>Committee Name</th>
              <th>Owning Entity / Branch</th>
              <th>Type / Mandate</th>
              <th>Chairperson</th>
              <th>Members</th>
              <th>Tenure</th>
              <th>State</th>
              <th style="width: 70px; text-align: center;">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="cmt in filteredCommittees" :key="cmt.id" class="table-row" @click="openCommitteeDetails(cmt)">
              <td>
                <span class="cmt-code-badge">{{ cmt.code }}</span>
              </td>
              <td>
                <div class="name-cell">
                  <span class="cmt-table-name">{{ cmt.name }}</span>
                  <span v-if="cmt.name_am" class="cmt-amharic-sub">{{ cmt.name_am }}</span>
                </div>
              </td>
              <td>
                <span class="text-xs text-muted">{{ cmt.entity_name }}</span>
              </td>
              <td>
                <span :class="['standing-pill', cmt.end_date ? 'pill-adhoc' : 'pill-standing']">
                  {{ cmt.end_date ? 'Ad-Hoc' : 'Standing' }}
                </span>
              </td>
              <td>
                <div class="chair-cell-inline" v-if="getCommitteeChair(cmt.id)">
                  <img :src="getCommitteeChair(cmt.id)?.avatar" class="mini-avatar" />
                  <span>{{ getCommitteeChair(cmt.id)?.employee_name }}</span>
                </div>
                <span v-else class="text-xs text-muted">-</span>
              </td>
              <td>
                <span class="member-badge-count">{{ getCommitteeMembers(cmt.id).length }} Members</span>
              </td>
              <td>
                <div class="tenure-cell">
                  <span>{{ cmt.start_date }}</span>
                  <span class="text-xs text-muted">{{ cmt.end_date ? 'to ' + cmt.end_date : '(Standing)' }}</span>
                </div>
              </td>
              <td>
                <span class="status-pill status-active">{{ cmt.state }}</span>
              </td>
              <td class="action-cell" @click.stop>
                <div class="action-dropdown-wrapper">
                  <button class="btn-action-dots" @click="toggleMenu($event, cmt.id)">
                    <MoreVertical :size="15" />
                  </button>
                  <div v-if="openActionMenuId === cmt.id" class="action-dropdown-menu">
                    <button class="action-menu-item" @click="openCommitteeDetails(cmt); closeMenu();">
                      <Eye :size="14" />
                      <span>View Charter & Members</span>
                    </button>
                    <button class="action-menu-item" @click="openAddMemberForCommittee(cmt.id); closeMenu();">
                      <UserPlus :size="14" />
                      <span>Appoint Member</span>
                    </button>
                    <button class="action-menu-item text-red-600" @click="deleteCommittee(cmt.id); closeMenu();">
                      <Trash2 :size="14" />
                      <span>Dissolve Committee</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- TAB 3: APPOINTED MEMBERS ROSTER (LINE TABLE) -->
    <div v-else-if="activeMainTab === 'members_directory'" class="table-card-wrapper">
      <div class="table-container">
        <table class="erp-table">
          <thead>
            <tr>
              <th style="width: 260px;">Employee</th>
              <th>Committee & Panel</th>
              <th>Assigned Role</th>
              <th>Department</th>
              <th>Start Date</th>
              <th>Term Expiry</th>
              <th>State</th>
              <th style="width: 70px; text-align: center;">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="m in filteredMembers" :key="m.id" class="table-row">
              <td>
                <div class="user-identity-cell">
                  <img :src="m.avatar || 'https://i.pravatar.cc/100?u=' + m.id" class="party-avatar" />
                  <div class="identity-info">
                    <span class="party-name-link">{{ m.employee_name }}</span>
                    <span class="party-code-sub">{{ m.employee_code }} • ID {{ m.employee_id }}</span>
                  </div>
                </div>
              </td>
              <td>
                <div class="cell-subtext">
                  <span class="font-medium">{{ m.committee_name }}</span>
                  <span class="text-xs text-muted">{{ m.committee_code }}</span>
                </div>
              </td>
              <td>
                <span :class="['role-pill', getRolePillClass(m.role_lookup_value_id)]">
                  {{ formatRole(m.role_lookup_value_id) }}
                </span>
              </td>
              <td>
                <span class="text-xs text-muted">{{ m.department }}</span>
              </td>
              <td>
                <span class="text-xs">{{ m.start_date }}</span>
              </td>
              <td>
                <span class="text-xs text-muted">{{ m.end_date || 'Ongoing Term' }}</span>
              </td>
              <td>
                <span class="status-pill status-active">{{ m.state }}</span>
              </td>
              <td class="action-cell" @click.stop>
                <button class="btn-delete-item" @click="deleteMember(m.id)" title="Remove Member">
                  <Trash2 :size="14" />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- DETAIL SLIDE-OVER DRAWER (FULL COMMITTEE CHARTER & ROSTER) -->
    <div v-if="showDetailDrawer && selectedCommitteeForView" class="drawer-backdrop" @click="showDetailDrawer = false">
      <div class="drawer-card" @click.stop>
        <div class="drawer-header">
          <div class="drawer-title-group">
            <span class="cmt-code-badge">{{ selectedCommitteeForView.code }}</span>
            <h2 class="drawer-title">{{ selectedCommitteeForView.name }}</h2>
          </div>
          <button class="btn-close-drawer" @click="showDetailDrawer = false">
            <X :size="18" />
          </button>
        </div>

        <div class="drawer-body">
          <!-- Overview Block -->
          <div class="drawer-section">
            <h4 class="section-heading">Charter & Terms of Reference</h4>
            <p class="mandate-text">{{ selectedCommitteeForView.description }}</p>
            <div class="spec-grid-two">
              <div><strong>Owning Entity:</strong> {{ selectedCommitteeForView.entity_name }}</div>
              <div><strong>Type:</strong> {{ selectedCommitteeForView.end_date ? 'Ad-Hoc Panel' : 'Standing Committee' }}</div>
              <div><strong>Constituted On:</strong> {{ selectedCommitteeForView.start_date }}</div>
              <div><strong>Dissolution Date:</strong> {{ selectedCommitteeForView.end_date || 'Permanent Mandate' }}</div>
            </div>
          </div>

          <!-- Members List Block -->
          <div class="drawer-section">
            <div class="flex-between">
              <h4 class="section-heading">Appointed Committee Members ({{ getCommitteeMembers(selectedCommitteeForView.id).length }})</h4>
              <BaseButton variant="outline" size="sm" @click="openAddMemberForCommittee(selectedCommitteeForView.id)">
                <Plus :size="13" />
                <span>Appoint Member</span>
              </BaseButton>
            </div>

            <div class="drawer-members-list">
              <div 
                v-for="mem in getCommitteeMembers(selectedCommitteeForView.id)" 
                :key="mem.id"
                class="drawer-member-card"
              >
                <div class="member-left">
                  <img :src="mem.avatar || 'https://i.pravatar.cc/100?u=' + mem.id" class="member-card-avatar" />
                  <div class="member-info">
                    <span class="mem-name">{{ mem.employee_name }}</span>
                    <span class="mem-sub">{{ mem.department }} • {{ mem.employee_code }}</span>
                  </div>
                </div>
                <div class="member-right">
                  <span :class="['role-pill', getRolePillClass(mem.role_lookup_value_id)]">
                    {{ formatRole(mem.role_lookup_value_id) }}
                  </span>
                  <button class="btn-del-mini" @click="deleteMember(mem.id)">
                    <Trash2 :size="13" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- QUICK CREATE COMMITTEE MODAL (<= 5 Required Fields Standard) -->
    <QuickCreateModal 
      :show="showCreateCommitteeModal"
      title="Create Governance Committee"
      width="md"
      @update:show="showCreateCommitteeModal = $event"
      @save="handleSaveCommittee"
      @cancel="showCreateCommitteeModal = false"
    >
      <div class="modal-form-body">
        <div class="form-grid-two">
          <FormInput 
            label="Committee Business Code"
            v-model="committeeForm.code"
            :required="true"
          />
          <FormSelect 
            label="Panel Category"
            v-model="committeeForm.category"
            :required="true"
            :options="[
              { value: 'disciplinary', label: 'Disciplinary Hearing' },
              { value: 'grievance', label: 'Workplace Grievance' },
              { value: 'recruitment', label: 'Recruitment Panel' },
              { value: 'safety', label: 'Occupational Safety & Health' },
              { value: 'audit', label: 'Stock & Asset Audit' },
              { value: 'general', label: 'General Committee' }
            ]"
          />
        </div>

        <FormInput 
          label="Committee Name (English)"
          v-model="committeeForm.name"
          :required="true"
        />

        <FormSelect 
          label="Owning Entity / Branch"
          v-model="committeeForm.entity_name"
          :required="true"
          :options="[
            'Haleta Enterprise Group (HQ)',
            'Bole Commercial Branch',
            'Kality Logistics & Storage Hub'
          ]"
        />

        <div class="form-grid-two">
          <FormInput 
            label="Constitution Date"
            type="date"
            v-model="committeeForm.start_date"
            :required="true"
          />
          <FormInput 
            label="End Date (Leave empty for Standing)"
            type="date"
            v-model="committeeForm.end_date"
          />
        </div>

        <FormTextarea 
          label="Terms of Reference & Mandate"
          v-model="committeeForm.description"
          :rows="3"
        />
      </div>
    </QuickCreateModal>

    <!-- APPOINT MEMBER MODAL -->
    <QuickCreateModal 
      :show="showAddMemberModal"
      title="Appoint Committee Member"
      width="md"
      @update:show="showAddMemberModal = $event"
      @save="handleSaveMember"
      @cancel="showAddMemberModal = false"
    >
      <div class="modal-form-body">
        <FormSelect 
          label="Assign to Committee"
          v-model="memberForm.committee_id"
          :options="committees.map(c => ({ value: c.id, label: `${c.code} - ${c.name}` }))"
          :required="true"
        />

        <div class="form-grid-two">
          <FormInput 
            label="Employee Full Name"
            v-model="memberForm.employee_name"
            :required="true"
          />
          <FormInput 
            label="Employee Code"
            v-model="memberForm.employee_code"
          />
        </div>

        <div class="form-grid-two">
          <FormSelect 
            label="Committee Role"
            v-model="memberForm.role_lookup_value_id"
            :required="true"
            :options="[
              { value: 'chair', label: 'Chairperson' },
              { value: 'secretary', label: 'Secretary / Rapporteur' },
              { value: 'member', label: 'Committee Member' },
              { value: 'treasurer', label: 'Treasurer' },
              { value: 'observer', label: 'Independent Observer' }
            ]"
          />
          <FormInput 
            label="Primary Department"
            v-model="memberForm.department"
          />
        </div>

        <div class="form-grid-two">
          <FormInput 
            label="Appointment Start Date"
            type="date"
            v-model="memberForm.start_date"
            :required="true"
          />
          <FormInput 
            label="Term End Date (Optional)"
            type="date"
            v-model="memberForm.end_date"
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.committees-page {
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

/* Tabs */
.main-tabs-container { margin-bottom: 14px; }
.sub-tabs-container { margin-bottom: 16px; }

/* Toolbar */
.table-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: #ffffff;
  border-radius: 10px 10px 0 0;
  border-bottom: 1px solid #f0f0f0;
  margin-bottom: 0;
}
.toolbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
}
.search-input-box {
  position: relative;
  width: 260px;
}
.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #9ca3af;
}
.custom-search-input {
  width: 100%;
  height: 36px;
  padding: 0 12px 0 32px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  outline: none;
  background-color: #ffffff;
}
.custom-search-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.08);
}
.filter-select-wrap {
  width: 240px;
}
.entries-counter {
  font-size: 12.5px;
  color: #737373;
}

/* CARDS VIEW */
.panels-overview-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-top: 16px;
}
.committee-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  cursor: pointer;
  transition: all 0.15s;
  box-shadow: 0 1px 3px rgba(0,0,0,0.02);
}
.committee-card:hover {
  border-color: #0B529C;
  box-shadow: 0 4px 12px rgba(11, 82, 156, 0.08);
  transform: translateY(-1px);
}
.card-top-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.code-and-cat {
  display: flex;
  align-items: center;
  gap: 8px;
}
.cmt-code-badge {
  font-size: 11.5px;
  font-weight: 700;
  color: #0B529C;
  background: #eff6ff;
  padding: 2px 8px;
  border-radius: 6px;
}
.standing-pill {
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 6px;
}
.pill-standing { background: #ecfdf5; color: #047857; }
.pill-adhoc { background: #fef3c7; color: #b45309; }

.btn-card-dots {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 4px;
}

.card-title-section {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.cmt-name {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.cmt-entity-row {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #737373;
}
.cmt-mandate {
  font-size: 12.5px;
  color: #52525b;
  line-height: 1.45;
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.members-summary-box {
  background: #f8fafc;
  padding: 10px 12px;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  border: 1px solid #f1f5f9;
}
.chair-info-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.chair-lbl { font-size: 11px; color: #737373; font-weight: 500; }
.chair-chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.chair-avatar {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  object-fit: cover;
}
.chair-name {
  font-size: 12px;
  font-weight: 600;
  color: #404040;
}

.roster-avatars-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.avatar-stack {
  display: flex;
  align-items: center;
}
.stack-avatar {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  border: 2px solid #ffffff;
  margin-left: -6px;
  object-fit: cover;
}
.stack-avatar:first-child { margin-left: 0; }
.stack-more {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #e2e8f0;
  color: #475569;
  font-size: 10px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-left: -6px;
  border: 2px solid #ffffff;
}
.member-count-text {
  font-size: 11.5px;
  color: #737373;
  font-weight: 500;
}

.card-footer-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: 6px;
  border-top: 1px solid #f0f0f0;
}
.dates-meta {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11.5px;
  color: #737373;
}
.btn-manage-link {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #0B529C;
  font-weight: 600;
  background: none;
  border: none;
  cursor: pointer;
  padding: 4px 6px;
  border-radius: 6px;
}
.btn-manage-link:hover { background: #eff6ff; }

/* TABLE VIEW */
.table-card-wrapper {
  background: #ffffff;
  border-radius: 0 0 12px 12px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.03);
  overflow: hidden;
}
.table-container { overflow-x: auto; }
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
.table-row:hover { background-color: #f9fafb; }

.cmt-table-name { font-weight: 600; color: #404040; }
.cmt-amharic-sub { font-size: 11px; color: #9ca3af; margin-left: 6px; }
.chair-cell-inline {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
}
.mini-avatar {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  object-fit: cover;
}
.member-badge-count {
  font-size: 11.5px;
  background: #f1f5f9;
  color: #334155;
  padding: 2px 8px;
  border-radius: 6px;
  font-weight: 500;
}
.tenure-cell {
  display: flex;
  flex-direction: column;
  font-size: 12px;
}

/* User Identity Cell */
.user-identity-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}
.party-avatar {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  object-fit: cover;
}
.party-name-link { font-size: 13px; font-weight: 500; color: #404040; }
.party-code-sub { font-size: 11px; color: #737373; }

/* Role Pills */
.role-pill {
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 6px;
}
.pill-chair { background: #fee2e2; color: #b91c1c; }
.pill-secretary { background: #e0f2fe; color: #0369a1; }
.pill-treasurer { background: #fef3c7; color: #92400e; }
.pill-observer { background: #f3e8ff; color: #6b21a8; }
.pill-member { background: #f1f5f9; color: #475569; }

.status-pill {
  display: inline-block;
  padding: 2px 10px;
  font-size: 11.5px;
  border-radius: 12px;
  font-weight: 500;
  text-transform: capitalize;
}
.status-active { background: #ecfdf5; color: #059669; }

/* Actions */
.action-cell { text-align: center; }
.action-dropdown-wrapper { position: relative; display: inline-block; }
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
}
.btn-action-dots:hover { background: #f0f0f0; color: #404040; }
.action-dropdown-menu {
  position: absolute;
  right: 0;
  top: 100%;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
  border-radius: 8px;
  z-index: 50;
  width: 200px;
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
.action-menu-item:hover { background: #f8fafc; color: #0B529C; }

.btn-delete-item {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 4px;
  border-radius: 4px;
}
.btn-delete-item:hover { color: #dc2626; background: #fee2e2; }

/* DRAWER */
.drawer-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.35);
  z-index: 100;
  display: flex;
  justify-content: flex-end;
}
.drawer-card {
  width: 520px;
  height: 100%;
  background: #ffffff;
  box-shadow: -4px 0 24px rgba(0,0,0,0.12);
  display: flex;
  flex-direction: column;
}
.drawer-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 24px;
  border-bottom: 1px solid #f0f0f0;
}
.drawer-title-group {
  display: flex;
  align-items: center;
  gap: 10px;
}
.drawer-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.btn-close-drawer {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
}
.drawer-body {
  padding: 20px 24px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.drawer-section {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.section-heading {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.mandate-text {
  font-size: 13px;
  color: #52525b;
  line-height: 1.5;
  background: #f8fafc;
  padding: 12px 14px;
  border-radius: 8px;
  margin: 0;
  border: 1px solid #f1f5f9;
}
.spec-grid-two {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
  font-size: 12.5px;
  color: #737373;
}
.flex-between {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.drawer-members-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.drawer-member-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  background: #fafafa;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}
.member-left {
  display: flex;
  align-items: center;
  gap: 10px;
}
.member-card-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  object-fit: cover;
}
.member-info {
  display: flex;
  flex-direction: column;
}
.mem-name { font-size: 13px; font-weight: 600; color: #404040; }
.mem-sub { font-size: 11.5px; color: #737373; }
.member-right {
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-del-mini {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 4px;
}
.btn-del-mini:hover { color: #dc2626; }

/* MODAL FORM */
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
.empty-panels-box {
  grid-column: span 3;
  text-align: center;
  padding: 40px;
  color: #737373;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}
</style>
