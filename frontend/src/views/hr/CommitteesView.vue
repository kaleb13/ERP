<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import {
  Users, Plus, Search, Filter,
  MoreVertical, Edit2, Trash2, Eye,
  Check, Calendar, CheckCircle2, X,
  ShieldCheck, UserPlus
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import { useToast } from '../../composables/useToast';

const router = useRouter();
const { toast } = useToast();

// ─── Lookups & Types (HR Schema Designer 1.sql lines 460–507) ───
export type RowState = 'active' | 'inactive';
export type CommitteeRole = 'chair' | 'member' | 'secretary' | 'treasurer' | 'observer';

export interface CommitteeMemberRecord {
  id: number;
  uuid: string;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  committee_id: number;
  role: CommitteeRole;
  role_label: string;
  start_date: string;
  end_date: string | null;
  state: RowState;
}

export interface CommitteeRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  description: string | null;
  tenant_id: number;
  entity_id: number;
  entity_name: string;
  start_date: string;
  end_date: string | null;
  members: CommitteeMemberRecord[];
  chair_name: string;
  state: RowState;
}

// ─── Breadcrumbs (Rule 3: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'Committees' }
];

// ─── State Management ───
const searchQuery = ref('');
const filterType = ref('All'); // 'All' | 'standing' | 'adhoc'
const filterEntity = ref('All');
const filterState = ref('All');
const currentSort = ref('name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);

// Committee Create/Edit Modal State
const showQuickCreate = ref(false);
const editingCommitteeId = ref<number | null>(null);

// Committee Inspection & Member Management Modal State
const activeCommitteeForMembers = ref<CommitteeRecord | null>(null);
const showAddMemberModal = ref(false);
const editingMemberId = ref<number | null>(null);

// ─── Table Columns (Strict Single-Information & Name-First Hierarchy: Rule 9) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Committee Name', visible: true, sortable: true },
  { key: 'chair', label: 'Committee Chair / Lead', visible: true, sortable: true },
  { key: 'members_count', label: 'Members', visible: true, sortable: true },
  { key: 'committee_type', label: 'Panel Type & Term', visible: true, sortable: true },
  { key: 'entity', label: 'Owning Entity', visible: true, sortable: true },
  { key: 'start_date', label: 'Constituted Date', visible: false, sortable: true },
  { key: 'description', label: 'Mandate & Terms', visible: false, sortable: false },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Dropdowns & Lookup Seed Options ───
const entityOptions = [
  { value: 0, label: 'All Entities' },
  { value: 1, label: 'QMT Business Group' },
  { value: 3, label: 'Haleta Addis Ababa HQ' },
  { value: 7, label: 'Haleta Grand Hotel & Suites' },
  { value: 9, label: 'Haleta East Regional Office' }
];

const committeeRoleOptions = [
  { value: 'chair', label: 'Chair / Chairperson' },
  { value: 'member', label: 'Committee Member' },
  { value: 'secretary', label: 'Committee Secretary' },
  { value: 'treasurer', label: 'Treasurer' },
  { value: 'observer', label: 'Observer' }
];

const availableEmployees = [
  { id: 7, code: 'EMP-007', name: 'Abebe Kebede', position: 'Head of Legal & Governance' },
  { id: 14, code: 'EMP-014', name: 'Sara Tadesse', position: 'Senior HR Specialist' },
  { id: 22, code: 'EMP-022', name: 'Dawit Alemu', position: 'Internal Audit Lead' },
  { id: 31, code: 'EMP-031', name: 'Bethlehem Haile', position: 'Senior Finance Officer' },
  { id: 44, code: 'EMP-044', name: 'Yonas Bekele', position: 'Operations Supervisor' },
  { id: 56, code: 'EMP-056', name: 'Marta Getachew', position: 'EHS & Safety Officer' },
  { id: 62, code: 'EMP-062', name: 'Tewodros Kassahun', position: 'Inventory Controller' }
];

// ─── Mock Data Aligned 100% with HR Schema Designer 1.sql lines 479–507 ───
const committees = ref<CommitteeRecord[]>([
  {
    id: 1,
    uuid: 'cmt-uuid-001',
    code: 'CMT-DISC',
    name: 'Disciplinary Committee',
    description: 'Statutory internal panel hearing employee misconduct, code-of-conduct violations, and recommending administrative disciplinary measures.',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    start_date: '2022-01-10',
    end_date: null,
    chair_name: 'Abebe Kebede',
    state: 'active',
    members: [
      {
        id: 1,
        uuid: 'cmtm-uuid-001',
        employee_id: 7,
        employee_name: 'Abebe Kebede',
        employee_code: 'EMP-007',
        committee_id: 1,
        role: 'chair',
        role_label: 'Chairperson',
        start_date: '2022-01-10',
        end_date: null,
        state: 'active'
      },
      {
        id: 2,
        uuid: 'cmtm-uuid-002',
        employee_id: 14,
        employee_name: 'Sara Tadesse',
        employee_code: 'EMP-014',
        committee_id: 1,
        role: 'member',
        role_label: 'Member',
        start_date: '2022-01-10',
        end_date: null,
        state: 'active'
      },
      {
        id: 3,
        uuid: 'cmtm-uuid-003',
        employee_id: 22,
        employee_name: 'Dawit Alemu',
        employee_code: 'EMP-022',
        committee_id: 1,
        role: 'secretary',
        role_label: 'Secretary',
        start_date: '2022-01-10',
        end_date: null,
        state: 'active'
      },
      {
        id: 4,
        uuid: 'cmtm-uuid-004',
        employee_id: 31,
        employee_name: 'Bethlehem Haile',
        employee_code: 'EMP-031',
        committee_id: 1,
        role: 'treasurer',
        role_label: 'Treasurer',
        start_date: '2022-01-10',
        end_date: null,
        state: 'active'
      }
    ]
  },
  {
    id: 2,
    uuid: 'cmt-uuid-002',
    code: 'CMT-GRV',
    name: 'Grievance Committee',
    description: 'Independent hearing body reviewing employee workplace grievances, unfair treatment claims, and resolving workplace disputes.',
    tenant_id: 1,
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    start_date: '2022-01-10',
    end_date: null,
    chair_name: 'Yonas Bekele',
    state: 'active',
    members: [
      {
        id: 5,
        uuid: 'cmtm-uuid-005',
        employee_id: 44,
        employee_name: 'Yonas Bekele',
        employee_code: 'EMP-044',
        committee_id: 2,
        role: 'chair',
        role_label: 'Chairperson',
        start_date: '2022-01-10',
        end_date: null,
        state: 'active'
      },
      {
        id: 6,
        uuid: 'cmtm-uuid-006',
        employee_id: 14,
        employee_name: 'Sara Tadesse',
        employee_code: 'EMP-014',
        committee_id: 2,
        role: 'member',
        role_label: 'Member',
        start_date: '2022-01-10',
        end_date: null,
        state: 'active'
      },
      {
        id: 7,
        uuid: 'cmtm-uuid-007',
        employee_id: 7,
        employee_name: 'Abebe Kebede',
        employee_code: 'EMP-007',
        committee_id: 2,
        role: 'observer',
        role_label: 'Observer',
        start_date: '2022-01-10',
        end_date: null,
        state: 'active'
      }
    ]
  },
  {
    id: 3,
    uuid: 'cmt-uuid-003',
    code: 'CMT-REC',
    name: 'Recruitment & Selection Panel',
    description: 'Expert recruitment board conducting competency interviews, technical assessments, and final hire recommendations.',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'Haleta Grand Hotel & Suites',
    start_date: '2026-01-05',
    end_date: null,
    chair_name: 'Sara Tadesse',
    state: 'active',
    members: [
      {
        id: 8,
        uuid: 'cmtm-uuid-008',
        employee_id: 14,
        employee_name: 'Sara Tadesse',
        employee_code: 'EMP-014',
        committee_id: 3,
        role: 'chair',
        role_label: 'Chairperson',
        start_date: '2026-01-05',
        end_date: null,
        state: 'active'
      },
      {
        id: 9,
        uuid: 'cmtm-uuid-009',
        employee_id: 22,
        employee_name: 'Dawit Alemu',
        employee_code: 'EMP-022',
        committee_id: 3,
        role: 'member',
        role_label: 'Member',
        start_date: '2026-01-05',
        end_date: null,
        state: 'active'
      }
    ]
  },
  {
    id: 4,
    uuid: 'cmt-uuid-004',
    code: 'CMT-SAFE',
    name: 'Occupational Safety & Health Committee',
    description: 'Enterprise safety oversight panel reviewing workplace accident logs, compliance with statutory safety norms, and hazard mitigation.',
    tenant_id: 1,
    entity_id: 9,
    entity_name: 'Haleta East Regional Office',
    start_date: '2025-03-01',
    end_date: null,
    chair_name: 'Marta Getachew',
    state: 'active',
    members: [
      {
        id: 10,
        uuid: 'cmtm-uuid-010',
        employee_id: 56,
        employee_name: 'Marta Getachew',
        employee_code: 'EMP-056',
        committee_id: 4,
        role: 'chair',
        role_label: 'Chairperson',
        start_date: '2025-03-01',
        end_date: null,
        state: 'active'
      },
      {
        id: 11,
        uuid: 'cmtm-uuid-011',
        employee_id: 44,
        employee_name: 'Yonas Bekele',
        employee_code: 'EMP-044',
        committee_id: 4,
        role: 'secretary',
        role_label: 'Secretary',
        start_date: '2025-03-01',
        end_date: null,
        state: 'active'
      }
    ]
  },
  {
    id: 5,
    uuid: 'cmt-uuid-005',
    code: 'CMT-AUD',
    name: 'Stock Count & Inventory Audit Committee',
    description: 'Ad-hoc annual fiscal year stock verification and physical warehouse reconciliation panel.',
    tenant_id: 1,
    entity_id: 7,
    entity_name: 'Haleta Grand Hotel & Suites',
    start_date: '2026-06-01',
    end_date: '2026-06-30',
    chair_name: 'Tewodros Kassahun',
    state: 'active',
    members: [
      {
        id: 12,
        uuid: 'cmtm-uuid-012',
        employee_id: 62,
        employee_name: 'Tewodros Kassahun',
        employee_code: 'EMP-062',
        committee_id: 5,
        role: 'chair',
        role_label: 'Chairperson',
        start_date: '2026-06-01',
        end_date: '2026-06-30',
        state: 'active'
      },
      {
        id: 13,
        uuid: 'cmtm-uuid-013',
        employee_id: 31,
        employee_name: 'Bethlehem Haile',
        employee_code: 'EMP-031',
        committee_id: 5,
        role: 'member',
        role_label: 'Member',
        start_date: '2026-06-01',
        end_date: '2026-06-30',
        state: 'active'
      }
    ]
  }
]);

// ─── Computed Filtered Records ───
const filteredCommittees = computed(() => {
  let result = [...committees.value];

  // Search filter
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.trim().toLowerCase();
    result = result.filter(c => 
      c.name.toLowerCase().includes(q) ||
      c.code.toLowerCase().includes(q) ||
      c.chair_name.toLowerCase().includes(q) ||
      (c.description && c.description.toLowerCase().includes(q))
    );
  }

  // Panel Type filter
  if (filterType.value === 'standing') {
    result = result.filter(c => !c.end_date);
  } else if (filterType.value === 'adhoc') {
    result = result.filter(c => !!c.end_date);
  }

  // Owning Entity filter
  if (filterEntity.value !== 'All') {
    result = result.filter(c => c.entity_id === Number(filterEntity.value));
  }

  // State filter
  if (filterState.value !== 'All') {
    result = result.filter(c => c.state === filterState.value);
  }

  // Sorting
  result.sort((a, b) => {
    let aVal: any = a[currentSort.value as keyof CommitteeRecord] ?? '';
    let bVal: any = b[currentSort.value as keyof CommitteeRecord] ?? '';

    if (typeof aVal === 'string') {
      aVal = aVal.toLowerCase();
      bVal = (bVal as string).toLowerCase();
    }

    if (aVal < bVal) return sortOrder.value === 'asc' ? -1 : 1;
    if (aVal > bVal) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });

  return result;
});

// Selection helpers
const isAllSelected = computed(() => {
  return filteredCommittees.value.length > 0 && selectedRowIds.value.length === filteredCommittees.value.length;
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredCommittees.value.map(r => r.id);
  }
};

const toggleSelectRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) {
    selectedRowIds.value.splice(idx, 1);
  } else {
    selectedRowIds.value.push(id);
  }
};

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) col.visible = !col.visible;
};

// ─── Toast (Strict useToast Standard) ───
const showToast = (message: string) => {
  toast.success('Committees', message);
};

// ─── Quick Create / Edit Committee Form State (<= 5 Required Fields Flow: Rule 4) ───
const quickForm = ref({
  name: '',
  code: '',
  entity_id: 3,
  start_date: new Date().toISOString().split('T')[0],
  end_date: '' as string,
  description: ''
});

const openCreateModal = () => {
  editingCommitteeId.value = null;
  quickForm.value = {
    name: '',
    code: '',
    entity_id: 3,
    start_date: new Date().toISOString().split('T')[0],
    end_date: '',
    description: ''
  };
  showQuickCreate.value = true;
};

const openEditModal = (cmt: CommitteeRecord) => {
  editingCommitteeId.value = cmt.id;
  quickForm.value = {
    name: cmt.name,
    code: cmt.code,
    entity_id: cmt.entity_id,
    start_date: cmt.start_date,
    end_date: cmt.end_date || '',
    description: cmt.description || ''
  };
  showQuickCreate.value = true;
  closeActionMenu();
};

const handleSaveQuickCreate = () => {
  if (!quickForm.value.name.trim()) {
    alert('Please enter a Committee Name.');
    return;
  }
  if (!quickForm.value.start_date) {
    alert('Please specify the Constituted Date.');
    return;
  }

  const entityObj = entityOptions.find(e => e.value === quickForm.value.entity_id);

  // Derive human-readable code automatically if omitted (e.g. CMT-SAFETY)
  let finalCode = quickForm.value.code.trim().toUpperCase();
  if (!finalCode) {
    const acronym = quickForm.value.name.trim().toUpperCase().replace(/[^A-Z0-9]/g, '_').slice(0, 8);
    finalCode = `CMT-${acronym}`;
  }

  if (editingCommitteeId.value) {
    // Edit existing committee
    const target = committees.value.find(c => c.id === editingCommitteeId.value);
    if (target) {
      target.name = quickForm.value.name.trim();
      target.code = finalCode;
      target.entity_id = quickForm.value.entity_id;
      target.entity_name = entityObj ? entityObj.label : 'Haleta Addis Ababa HQ';
      target.start_date = quickForm.value.start_date;
      target.end_date = quickForm.value.end_date ? quickForm.value.end_date : null;
      target.description = quickForm.value.description.trim() || null;
      showToast(`Committee "${target.name}" updated successfully.`);
    }
  } else {
    // Create new committee
    const newId = Date.now();
    committees.value.unshift({
      id: newId,
      uuid: `cmt-uuid-${newId}`,
      code: finalCode,
      name: quickForm.value.name.trim(),
      description: quickForm.value.description.trim() || null,
      tenant_id: 1,
      entity_id: quickForm.value.entity_id,
      entity_name: entityObj ? entityObj.label : 'Haleta Addis Ababa HQ',
      start_date: quickForm.value.start_date,
      end_date: quickForm.value.end_date ? quickForm.value.end_date : null,
      chair_name: '— Unassigned',
      members: [],
      state: 'active'
    });
    showToast(`Committee "${quickForm.value.name.trim()}" constituted successfully.`);
  }

  showQuickCreate.value = false;
  editingCommitteeId.value = null;
};

// ─── Expand Full Form Navigation (Rule 4) ───
const handleExpandToFullForm = () => {
  showQuickCreate.value = false;
  router.push({
    path: '/hr/committees/create',
    query: {
      name: quickForm.value.name,
      code: quickForm.value.code,
      entity_id: String(quickForm.value.entity_id),
      start_date: quickForm.value.start_date,
      end_date: quickForm.value.end_date,
      description: quickForm.value.description
    }
  });
};

// ─── Committee Member Management State & Handlers (CommitteeMember [LINE]) ───
const memberForm = ref({
  employee_id: 7,
  role: 'member' as CommitteeRole,
  start_date: new Date().toISOString().split('T')[0],
  end_date: '' as string
});

const openMemberManager = (cmt: CommitteeRecord) => {
  activeCommitteeForMembers.value = cmt;
  closeActionMenu();
};

const openAddMemberModal = () => {
  editingMemberId.value = null;
  memberForm.value = {
    employee_id: availableEmployees[0].id,
    role: 'member',
    start_date: new Date().toISOString().split('T')[0],
    end_date: ''
  };
  showAddMemberModal.value = true;
};

const openEditMemberModal = (member: CommitteeMemberRecord) => {
  editingMemberId.value = member.id;
  memberForm.value = {
    employee_id: member.employee_id,
    role: member.role,
    start_date: member.start_date,
    end_date: member.end_date || ''
  };
  showAddMemberModal.value = true;
};

const handleSaveMember = () => {
  if (!activeCommitteeForMembers.value) return;

  const emp = availableEmployees.find(e => e.id === memberForm.value.employee_id);
  const roleObj = committeeRoleOptions.find(r => r.value === memberForm.value.role);

  if (!emp) {
    alert('Please select an employee.');
    return;
  }

  if (editingMemberId.value) {
    // Edit member
    const target = activeCommitteeForMembers.value.members.find(m => m.id === editingMemberId.value);
    if (target) {
      target.employee_id = emp.id;
      target.employee_name = emp.name;
      target.employee_code = emp.code;
      target.role = memberForm.value.role;
      target.role_label = roleObj ? roleObj.label.split('/')[0].trim() : 'Member';
      target.start_date = memberForm.value.start_date;
      target.end_date = memberForm.value.end_date ? memberForm.value.end_date : null;
      showToast(`Updated member appointment for "${emp.name}".`);
    }
  } else {
    // Add new member
    const newMemberId = Date.now();
    activeCommitteeForMembers.value.members.push({
      id: newMemberId,
      uuid: `cmtm-uuid-${newMemberId}`,
      employee_id: emp.id,
      employee_name: emp.name,
      employee_code: emp.code,
      committee_id: activeCommitteeForMembers.value.id,
      role: memberForm.value.role,
      role_label: roleObj ? roleObj.label.split('/')[0].trim() : 'Member',
      start_date: memberForm.value.start_date,
      end_date: memberForm.value.end_date ? memberForm.value.end_date : null,
      state: 'active'
    });
    showToast(`Appointed "${emp.name}" to ${activeCommitteeForMembers.value.name}.`);
  }

  // Update committee chair summary name
  const chairMember = activeCommitteeForMembers.value.members.find(m => m.role === 'chair' && m.state === 'active');
  activeCommitteeForMembers.value.chair_name = chairMember ? chairMember.employee_name : '— Unassigned';

  showAddMemberModal.value = false;
  editingMemberId.value = null;
};

const handleRemoveMember = (memberId: number) => {
  if (!activeCommitteeForMembers.value) return;
  activeCommitteeForMembers.value.members = activeCommitteeForMembers.value.members.filter(m => m.id !== memberId);
  
  // Re-sync chair name
  const chairMember = activeCommitteeForMembers.value.members.find(m => m.role === 'chair' && m.state === 'active');
  activeCommitteeForMembers.value.chair_name = chairMember ? chairMember.employee_name : '— Unassigned';
  
  showToast('Member removed from committee panel.');
};

const handleToggleMemberState = (member: CommitteeMemberRecord) => {
  member.state = member.state === 'active' ? 'inactive' : 'active';
  
  // Re-sync chair name
  if (activeCommitteeForMembers.value) {
    const chairMember = activeCommitteeForMembers.value.members.find(m => m.role === 'chair' && m.state === 'active');
    activeCommitteeForMembers.value.chair_name = chairMember ? chairMember.employee_name : '— Unassigned';
  }
  
  showToast(`Member appointment is now ${member.state}.`);
};

// ─── Actions Menu Handlers ───
const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const handleToggleState = (cmt: CommitteeRecord) => {
  cmt.state = cmt.state === 'active' ? 'inactive' : 'active';
  showToast(`Committee "${cmt.name}" is now ${cmt.state}.`);
  closeActionMenu();
};

const handleDelete = (id: number) => {
  committees.value = committees.value.filter(c => c.id !== id);
  selectedRowIds.value = selectedRowIds.value.filter(i => i !== id);
  showToast('Committee deleted successfully.');
  closeActionMenu();
};

const handleBatchDelete = () => {
  committees.value = committees.value.filter(c => !selectedRowIds.value.includes(c.id));
  showToast(`Deleted ${selectedRowIds.value.length} selected committees.`);
  selectedRowIds.value = [];
};

const handleGlobalClick = (e: MouseEvent) => {
  const target = e.target as HTMLElement;
  if (!target.closest('.action-menu-container')) {
    closeActionMenu();
  }
};

onMounted(() => {
  window.addEventListener('click', handleGlobalClick);
});

onUnmounted(() => {
  window.removeEventListener('click', handleGlobalClick);
});
</script>

<template>
  <div class="committees-page">
    <!-- ═══ BREADCRUMB NAVIGATION (Rule 3: Exact Sidebar Page Name Only) ═══ -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ═══ UNIFIED TABLE CARD: <AppDataTable /> (Rule 10.1 & Rule 9) ═══ -->
    <AppDataTable
      title="Committees &amp; Panels"
      subtitle="Standing and ad-hoc panels for disciplinary hearings, employee grievances, recruitment selections, safety oversight, and stock audit committees."
      :columns="tableColumns"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Toolbar Filter Controls -->
      <template #filters>
        <!-- Search Input -->
        <div class="filter-search-box">
          <Search :size="14" class="search-icon" />
          <input 
            type="text" 
            v-model="searchQuery" 
            placeholder="Search committee, code, or chair..." 
            class="filter-search-input"
          />
          <button v-if="searchQuery" @click="searchQuery = ''" class="search-clear-btn" aria-label="Clear search">
            <X :size="12" />
          </button>
        </div>

        <!-- Committee Term / Type Filter -->
        <div class="filter-select-box">
          <FormSelect
            v-model="filterType"
            label="Term Type:"
            :options="[
              { value: 'All', label: 'All Panels' },
              { value: 'standing', label: 'Standing Committees (Permanent)' },
              { value: 'adhoc', label: 'Ad-Hoc / Fixed Term Panels' }
            ]"
            placeholder="Select Panel"
          />
        </div>

        <!-- Owning Entity Filter -->
        <div class="filter-select-box">
          <FormSelect
            v-model="filterEntity"
            label="Entity:"
            :options="[
              { value: 'All', label: 'All Entities' },
              ...entityOptions.filter(e => Number(e.value) > 0)
            ]"
            placeholder="Select Entity"
          />
        </div>

        <!-- State Filter -->
        <div class="filter-select-box">
          <FormSelect
            v-model="filterState"
            label="State:"
            :options="[
              { value: 'All', label: 'All States' },
              { value: 'active', label: 'Active' },
              { value: 'inactive', label: 'Inactive' }
            ]"
            placeholder="Select State"
          />
        </div>
      </template>

      <!-- Primary Action: + Add Committee (Rule 10.2) -->
      <template #actions>
        <AppButton variant="primary" size="sm" @click="openCreateModal">
  <template #icon-left><Plus :size="15" /></template>
  Add Committee
</AppButton>
      </template>

      <!-- Table Body -->
      <div class="table-container">
        <table class="erp-table">
          <thead>
            <tr>
              <!-- Checkbox Select All -->
              <th class="col-checkbox">
                <input 
                  type="checkbox" 
                  :checked="isAllSelected" 
                  @change="toggleSelectAll" 
                  class="table-checkbox" 
                />
              </th>

              <!-- Name & Code Header (Rule 9.4 & 9.5) -->
              <th v-if="isColumnVisible('name')" class="col-name">Committee Name</th>
              <th v-if="isColumnVisible('chair')" class="col-chair">Committee Chair / Lead</th>
              <th v-if="isColumnVisible('members_count')" class="col-count">Members</th>
              <th v-if="isColumnVisible('committee_type')" class="col-type">Panel Type &amp; Term</th>
              <th v-if="isColumnVisible('entity')" class="col-entity">Owning Entity</th>
              <th v-if="isColumnVisible('start_date')" class="col-date">Constituted Date</th>
              <th v-if="isColumnVisible('description')" class="col-desc">Mandate &amp; Terms</th>
              <th v-if="isColumnVisible('state')" class="col-state">State</th>
              <th v-if="isColumnVisible('actions')" class="col-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <!-- Empty State -->
            <tr v-if="filteredCommittees.length === 0">
              <td :colspan="tableColumns.length + 1" class="empty-state-cell">
                <div class="empty-state-container">
                  <ShieldCheck :size="36" class="empty-state-icon" />
                  <p class="empty-state-title">No committees found</p>
                  <p class="empty-state-subtext">No standing or ad-hoc panels match your current filter and search criteria.</p>
                </div>
              </td>
            </tr>

            <!-- Data Rows -->
            <tr 
              v-for="item in filteredCommittees" 
              :key="item.id"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
            >
              <!-- Checkbox Cell -->
              <td class="col-checkbox">
                <input 
                  type="checkbox" 
                  :checked="selectedRowIds.includes(item.id)" 
                  @change="toggleSelectRow(item.id)" 
                  class="table-checkbox" 
                />
              </td>

              <!-- Name & Code (Rule 9.4 & 9.5: Secondary Color #404040 for Name, Subtext Code) -->
              <td v-if="isColumnVisible('name')" class="col-name" @click="openMemberManager(item)">
                <div class="field-name-block cursor-pointer">
                  <span class="table-name-primary">{{ item.name }}</span>
                  <span class="table-code-subtext">{{ item.code }}</span>
                </div>
              </td>

              <!-- Committee Chair (Rule 9.8: Plain Tertiary Text #737373, Zero Foreign Avatars) -->
              <td v-if="isColumnVisible('chair')" class="col-chair">
                <span class="tertiary-plain-text">{{ item.chair_name }}</span>
              </td>

              <!-- Active Members Count (Rule 9.6: Plain Tertiary Text #737373, Anti-Badge) -->
              <td v-if="isColumnVisible('members_count')" class="col-count" @click="openMemberManager(item)">
                <span class="tertiary-plain-text cursor-pointer hover:text-slate-900" title="Click to view and manage committee members">
                  {{ item.members.length }} {{ item.members.length === 1 ? 'Member' : 'Members' }}
                </span>
              </td>

              <!-- Type / Term (Rule 9.6: Plain Tertiary Text #737373) -->
              <td v-if="isColumnVisible('committee_type')" class="col-type">
                <span class="tertiary-plain-text">
                  {{ item.end_date ? `Ad-Hoc (Ends ${item.end_date})` : 'Standing Committee' }}
                </span>
              </td>

              <!-- Owning Entity -->
              <td v-if="isColumnVisible('entity')" class="col-entity">
                <span class="tertiary-plain-text">{{ item.entity_name }}</span>
              </td>

              <!-- Constituted Date -->
              <td v-if="isColumnVisible('start_date')" class="col-date">
                <span class="tertiary-plain-text">{{ item.start_date }}</span>
              </td>

              <!-- Mandate Description -->
              <td v-if="isColumnVisible('description')" class="col-desc">
                <span class="tertiary-plain-text text-truncate">{{ item.description || '—' }}</span>
              </td>

              <!-- Lifecycle State (Rule 9.9: Rounded State Pills solely for Active/Inactive) -->
              <td v-if="isColumnVisible('state')" class="col-state">
                <BaseBadge :color="item.state === 'active' ? 'success' : 'gray'">
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
              </td>

              <!-- Actions Dropdown -->
              <td v-if="isColumnVisible('actions')" class="col-actions">
                <div class="action-menu-container">
                  <button 
                    type="button" 
                    class="btn-action-dots" 
                    @click.stop="toggleActionMenu(item.id)"
                    aria-label="Actions"
                  >
                    <MoreVertical :size="14" />
                  </button>

                  <div v-if="activeActionMenuId === item.id" class="action-dropdown" @click.stop>
                    <button class="dropdown-item" @click="openMemberManager(item)">
                      <Eye :size="14" class="dropdown-icon" />
                      <span>View &amp; Manage Members</span>
                    </button>
                    <button class="dropdown-item" @click="openEditModal(item)">
                      <Edit2 :size="14" class="dropdown-icon" />
                      <span>Edit Committee</span>
                    </button>
                    <button class="dropdown-item" @click="handleToggleState(item)">
                      <Check :size="14" class="dropdown-icon" />
                      <span>{{ item.state === 'active' ? 'Deactivate' : 'Activate' }}</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button class="dropdown-item dropdown-item-danger" @click="handleDelete(item.id)">
                      <Trash2 :size="14" class="dropdown-icon" />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </AppDataTable>

    <!-- ═══ FLOATING BATCH ACTION BAR (Rule 11.3) ═══ -->
    <TableFloatingBar 
      :count="selectedRowIds.length" 
      @delete="handleBatchDelete" 
    />

    <!-- ═══ QUICK CREATE / EDIT COMMITTEE MODAL (< 5 Required Fields Flow: Rule 4) ═══ -->
    <QuickCreateModal
      :show="showQuickCreate"
      :title="editingCommitteeId ? 'Edit Committee' : 'Add Committee'"
      :showExpandButton="!editingCommitteeId"
      expandRoute="/hr/committees/create"
      saveLabel="Save"
      @update:show="showQuickCreate = $event"
      @expand="handleExpandToFullForm"
      @save="handleSaveQuickCreate"
      @cancel="showQuickCreate = false"
    >
      <div class="modal-form-stack">
        <!-- Field 1: Committee Name (Schema column: name) -->
        <FormInput 
          label="Committee Name"
          v-model="quickForm.name" 
          required
        />

        <!-- Field 2: Committee Business Code (Schema column: code) -->
        <FormInput 
          label="Committee Code"
          v-model="quickForm.code" 
          hint="Leave blank to auto-generate (e.g. CMT-DISC, CMT-GRV)."
        />

        <!-- Field 3: Owning Entity (Schema column: entity_id) -->
        <FormSelect 
          label="Owning Entity"
          v-model="quickForm.entity_id" 
          :options="entityOptions.filter(e => e.value > 0)"
          placeholder="Select Owning Entity"
          required
        />

        <!-- Field 4: Constituted & Dissolution Dates (Schema columns: start_date, end_date) -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="gc-date-field">
            <label class="gc-field-label">Constituted Date <span class="required-star">*</span></label>
            <div class="gc-date-input-wrap">
              <Calendar :size="14" class="gc-cal-icon" />
              <input
                type="date"
                v-model="quickForm.start_date"
                class="gc-date-input"
                required
              />
              <span class="gc-pill-tag">GC</span>
            </div>
          </div>

          <div class="gc-date-field">
            <label class="gc-field-label">Dissolution Date (Optional)</label>
            <div class="gc-date-input-wrap">
              <Calendar :size="14" class="gc-cal-icon" />
              <input
                type="date"
                v-model="quickForm.end_date"
                class="gc-date-input"
              />
              <span class="gc-pill-tag">GC</span>
            </div>
            <p class="gc-hint-text">Leave blank for standing / permanent panel.</p>
          </div>
        </div>
      </div>
    </QuickCreateModal>

    <!-- ═══ COMMITTEE MEMBERS INSPECTION & ROSTER MODAL (Rule 11: Dynamic Child Sub-Table) ═══ -->
    <QuickCreateModal
      v-if="activeCommitteeForMembers"
      :show="!!activeCommitteeForMembers"
      :title="`Committee Roster: ${activeCommitteeForMembers.name}`"
      :showExpandButton="false"
      saveLabel="Save"
      @update:show="activeCommitteeForMembers = null"
      @save="activeCommitteeForMembers = null"
      @cancel="activeCommitteeForMembers = null"
    >
      <div class="roster-modal-content">
        <!-- Committee Info Banner -->
        <div class="roster-info-card">
          <div class="roster-info-row">
            <div class="info-pill-item">
              <span class="info-pill-label">Code:</span>
              <span class="info-pill-val font-mono">{{ activeCommitteeForMembers.code }}</span>
            </div>
            <div class="info-pill-item">
              <span class="info-pill-label">Entity:</span>
              <span class="info-pill-val">{{ activeCommitteeForMembers.entity_name }}</span>
            </div>
            <div class="info-pill-item">
              <span class="info-pill-label">Constituted:</span>
              <span class="info-pill-val">{{ activeCommitteeForMembers.start_date }}</span>
            </div>
            <div class="info-pill-item">
              <span class="info-pill-label">Type:</span>
              <span class="info-pill-val">{{ activeCommitteeForMembers.end_date ? `Ad-Hoc (Ends ${activeCommitteeForMembers.end_date})` : 'Standing' }}</span>
            </div>
          </div>
          <p v-if="activeCommitteeForMembers.description" class="roster-mandate-text">
            {{ activeCommitteeForMembers.description }}
          </p>
        </div>

        <!-- Members Sub-Table Header & Action (Rule 11) -->
        <div class="roster-toolbar">
          <div class="roster-title-wrap">
            <Users :size="16" class="section-icon" />
            <span class="roster-title">Appointed Members ({{ activeCommitteeForMembers.members.length }})</span>
          </div>
          <button type="button" class="btn-add-member" @click="openAddMemberModal">
            <UserPlus :size="13" />
            <span>Appoint Member</span>
          </button>
        </div>

        <!-- Sub-Table (Rule 11: Minimalist Inline Child Table) -->
        <div class="child-subtable-wrapper">
          <table class="child-table">
            <thead>
              <tr>
                <th class="child-th-no">#</th>
                <th class="child-th-name">Employee</th>
                <th class="child-th-role">Committee Role</th>
                <th class="child-th-period">Term Period</th>
                <th class="child-th-state">State</th>
                <th class="child-th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <!-- Empty Members State -->
              <tr v-if="activeCommitteeForMembers.members.length === 0">
                <td colspan="6" class="child-empty-state">
                  No members appointed yet. Click "Appoint Member" to add members to this panel.
                </td>
              </tr>

              <!-- Member Rows -->
              <tr v-for="(m, idx) in activeCommitteeForMembers.members" :key="m.id">
                <td class="child-td-no">{{ idx + 1 }}</td>
                <td class="child-td-name">
                  <div class="member-emp-block">
                    <span class="member-emp-name">{{ m.employee_name }}</span>
                    <span class="member-emp-code">{{ m.employee_code }}</span>
                  </div>
                </td>
                <td class="child-td-role">
                  <span class="member-role-text" :class="m.role === 'chair' ? 'role-chair' : ''">
                    {{ m.role_label }}
                  </span>
                </td>
                <td class="child-td-period">
                  <span class="child-tertiary-text">
                    {{ m.start_date }} → {{ m.end_date || 'Present' }}
                  </span>
                </td>
                <td class="child-td-state">
                  <BaseBadge :color="m.state === 'active' ? 'success' : 'gray'">
                    {{ m.state === 'active' ? 'Active' : 'Inactive' }}
                  </BaseBadge>
                </td>
                <td class="child-td-actions">
                  <div class="child-actions-group">
                    <button 
                      type="button" 
                      class="btn-child-icon" 
                      @click="openEditMemberModal(m)" 
                      title="Edit appointment"
                    >
                      <Edit2 :size="13" />
                    </button>
                    <button 
                      type="button" 
                      class="btn-child-icon" 
                      @click="handleToggleMemberState(m)" 
                      :title="m.state === 'active' ? 'Deactivate member' : 'Activate member'"
                    >
                      <Check :size="13" />
                    </button>
                    <button 
                      type="button" 
                      class="btn-child-icon btn-child-danger" 
                      @click="handleRemoveMember(m.id)" 
                      title="Remove member"
                    >
                      <Trash2 :size="13" />
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </QuickCreateModal>

    <!-- ═══ APPOINT / EDIT MEMBER MODAL ═══ -->
    <QuickCreateModal
      :show="showAddMemberModal"
      :title="editingMemberId ? 'Edit Committee Member Appointment' : 'Appoint Committee Member'"
      :showExpandButton="false"
      saveLabel="Save"
      @update:show="showAddMemberModal = $event"
      @save="handleSaveMember"
      @cancel="showAddMemberModal = false"
    >
      <div class="modal-form-stack">
        <!-- Select Employee (Schema column: employee_id) -->
        <div class="modal-form-group">
          <label class="modal-field-label">
            Employee <span class="required-star">*</span>
          </label>
          <FormSelect 
            v-model="memberForm.employee_id" 
            :options="availableEmployees.map(e => ({ value: e.id, label: `${e.name} (${e.code}) — ${e.position}` }))"
            placeholder="Select Employee"
          />
        </div>

        <!-- Select Role (Schema column: role_lookup_value_id) -->
        <div class="modal-form-group">
          <label class="modal-field-label">
            Committee Role <span class="required-star">*</span>
          </label>
          <FormSelect 
            v-model="memberForm.role" 
            :options="committeeRoleOptions"
            placeholder="Select Role"
          />
        </div>

        <!-- Appointment Dates (Schema columns: start_date, end_date) -->
        <div class="modal-form-grid-2">
          <div class="modal-form-group">
            <label class="modal-field-label">
              Appointment Start Date <span class="required-star">*</span>
            </label>
            <FormInput 
              type="date"
              v-model="memberForm.start_date" 
            />
          </div>

          <div class="modal-form-group">
            <label class="modal-field-label">End Date (Optional)</label>
            <FormInput 
              type="date"
              v-model="memberForm.end_date" 
              hint="Leave blank for open-ended tenure."
            />
          </div>
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.committees-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  width: 100%;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

/* GC Date Picker Field */
.gc-date-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.gc-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.required-star {
  color: #ef4444;
}

.gc-date-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.gc-cal-icon {
  position: absolute;
  left: 10px;
  color: #94a3b8;
  pointer-events: none;
}

.gc-date-input {
  width: 100%;
  height: 38px;
  padding: 0 42px 0 32px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  color: #404040;
  outline: none;
}

.gc-date-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.gc-pill-tag {
  position: absolute;
  right: 8px;
  background-color: #f5f5f5;
  color: #737373;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 4px;
  pointer-events: none;
}

.gc-hint-text {
  font-size: 11.5px;
  color: #737373;
  margin: 4px 0 0;
}

/* Filters */
.filter-search-box {
  position: relative;
  display: flex;
  align-items: center;
  width: 260px;
}

.search-icon {
  position: absolute;
  left: 10px;
  color: #94a3b8;
  pointer-events: none;
}

.filter-search-input {
  width: 100%;
  height: 38px;
  padding: 0 28px 0 32px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  background-color: #ffffff;
  outline: none;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.filter-search-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.search-clear-btn {
  position: absolute;
  right: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 2px;
}

.search-clear-btn:hover {
  color: #737373;
}

.filter-select-box {
  display: flex;
  align-items: center;
  gap: 6px;
}

.filter-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #737373;
  white-space: nowrap;
}

.filter-select {
  height: 38px;
  padding: 0 28px 0 10px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  background-color: #ffffff;
  outline: none;
  cursor: pointer;
}

.filter-select:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

/* Primary Action Button (Rule 6: 8px-10px well-rounded rectangle) */
.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary-create:hover {
  background-color: #09427d;
}

/* Table container & Standard Rows */
.table-container {
  overflow-x: auto;
  width: 100%;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  white-space: nowrap;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  border-bottom: 1px solid #f1f5f9;
  font-size: 13px;
  color: #404040;
}

.erp-table tr:hover td {
  background-color: #fafafa;
}

.row-selected td {
  background-color: #eff6ff !important;
}

.col-checkbox {
  width: 40px;
  padding-right: 0 !important;
  text-align: center;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  border-radius: 4px;
  accent-color: #0B529C;
  cursor: pointer;
}

.field-name-block {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.table-code-subtext {
  font-size: 11.5px;
  color: #737373;
  font-family: monospace;
}

.tertiary-plain-text {
  font-size: 13px;
  color: #737373;
}

.text-truncate {
  display: inline-block;
  max-width: 240px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Members Count Button */
.btn-members-badge {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 8px;
  background-color: #f5f5f5;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12px;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-members-badge:hover {
  background-color: #e5e5e5;
  border-color: #cbd5e1;
  color: #0B529C;
}

.inline-icon {
  color: #737373;
}

/* Actions Menu */
.col-actions {
  width: 60px;
  text-align: center;
}

.action-menu-container {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  background: transparent;
  border: 1px solid transparent;
  border-radius: 6px;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f5f5f5;
  border-color: #e2e8f0;
  color: #404040;
}

.action-dropdown {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  width: 190px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  padding: 4px;
  z-index: 50;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  height: 32px;
  padding: 0 8px;
  background: transparent;
  border: none;
  border-radius: 6px;
  font-size: 12.5px;
  color: #404040;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.1s ease;
}

.dropdown-item:hover {
  background-color: #fafafa;
}

.dropdown-icon {
  color: #737373;
}

.dropdown-divider {
  height: 1px;
  background-color: #f5f5f5;
  margin: 2px 0;
}

.dropdown-item-danger {
  color: #dc2626;
}

.dropdown-item-danger:hover {
  background-color: #fef2f2;
}

.dropdown-item-danger .dropdown-icon {
  color: #dc2626;
}

/* Empty State */
.empty-state-cell {
  padding: 48px 16px !important;
  text-align: center;
}

.empty-state-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.empty-state-icon {
  color: #cbd5e1;
}

.empty-state-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.empty-state-subtext {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* Modal Form Controls */
.modal-form-stack {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.modal-form-group {
  display: flex;
  flex-direction: column;
}

.modal-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}

.required-star {
  color: #dc2626;
}

.modal-form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

/* Roster Modal Styling */
.roster-modal-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.roster-info-card {
  background-color: #fafafa;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.roster-info-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 16px;
}

.info-pill-item {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 12.5px;
}

.info-pill-label {
  color: #737373;
  font-weight: 500;
}

.info-pill-val {
  color: #404040;
  font-weight: 600;
}

.roster-mandate-text {
  font-size: 12px;
  color: #737373;
  line-height: 1.45;
  margin: 0;
}

.roster-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.roster-title-wrap {
  display: flex;
  align-items: center;
  gap: 6px;
}

.section-icon {
  color: #0B529C;
}

.roster-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.btn-add-member {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 32px;
  padding: 0 12px;
  background-color: #ffffff;
  border: 1px solid #0B529C;
  border-radius: 6px;
  color: #0B529C;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-add-member:hover {
  background-color: #f0f7ff;
}

/* Child Sub-Table (Rule 11) */
.child-subtable-wrapper {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}

.child-table {
  width: 100%;
  border-collapse: collapse;
}

.child-table th {
  height: 32px;
  padding: 6px 12px;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
  text-align: left;
}

.child-table td {
  height: 36px;
  padding: 6px 12px;
  border-bottom: 1px solid #f1f5f9;
  font-size: 12.5px;
  color: #404040;
}

.child-th-no, .child-td-no {
  width: 36px;
  text-align: center;
  color: #94a3b8;
}

.member-emp-block {
  display: flex;
  flex-direction: column;
}

.member-emp-name {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.member-emp-code {
  font-size: 11px;
  color: #737373;
  font-family: monospace;
}

.member-role-text {
  font-size: 12px;
  color: #737373;
}

.role-chair {
  color: #0B529C;
  font-weight: 600;
}

.child-tertiary-text {
  font-size: 12px;
  color: #737373;
}

.child-empty-state {
  padding: 24px !important;
  text-align: center;
  color: #94a3b8;
  font-size: 12.5px;
}

.child-actions-group {
  display: flex;
  align-items: center;
  gap: 4px;
}

.btn-child-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  background: transparent;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  color: #737373;
  cursor: pointer;
  transition: all 0.1s ease;
}

.btn-child-icon:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.btn-child-danger:hover {
  background-color: #fef2f2;
  border-color: #fecaca;
  color: #dc2626;
}

.cursor-pointer {
  cursor: pointer;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-3px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
