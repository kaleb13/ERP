<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, Eye, CheckCircle2, Clock,
  Calendar, Filter, MoreVertical, Check,
  CheckSquare, X
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import MetricCard from '../../components/MetricCard.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormInput from '../../components/FormInput.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import {
  separationsData,
  SEPARATION_TYPE_MAP,
  SEPARATION_STATUS_MAP,
  addSeparationRecord,
  type SeparationType,
  type SeparationStatus,
  type EmployeeSeparationRecord
} from './separationData';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3) ───
// Exact Sidebar Page Name Only: [Monitor] > Employee Separations
const breadcrumbItems = [
  { label: 'Employee Separations' }
];

// ─── Role-Adaptive View Switcher ───
// Allows toggling between Admin view (with metrics and governance) and Staff/Supervisor view
const isAdminView = ref(true);

// ─── Active Tab Filter (UnderlineTabs Standard AGENTS.md Rule 1) ───
type SeparationTabKey = 'all' | 'pending' | 'approved' | 'in_clearance' | 'cleared' | 'settled' | 'draft';
const activeTab = ref<SeparationTabKey>('all');

const searchQuery = ref('');
const selectedTypeFilter = ref<string>('all');
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Metric Cards Computed (AGENTS.md Rule 2 & Rule 21) ───
const metrics = computed(() => {
  const total = separationsData.value.length;
  const inClearance = separationsData.value.filter(s => s.separation_state === 'in_clearance').length;
  const pending = separationsData.value.filter(s => s.separation_state === 'pending').length;
  const settled = separationsData.value.filter(s => s.separation_state === 'settled').length;

  return {
    total,
    inClearance,
    pending,
    settled
  };
});

// ─── Tabs Configuration ───
const underlineTabs = computed<UnderlineTabItem<SeparationTabKey>[]>(() => [
  { id: 'all', label: 'All Separations', count: separationsData.value.length },
  { id: 'pending', label: 'Pending Approval', count: separationsData.value.filter(s => s.separation_state === 'pending').length, badgeVariant: 'warning' },
  { id: 'approved', label: 'Approved (Ready for Clearance)', count: separationsData.value.filter(s => s.separation_state === 'approved').length, badgeVariant: 'primary' },
  { id: 'in_clearance', label: 'In Clearance', count: separationsData.value.filter(s => s.separation_state === 'in_clearance').length, badgeVariant: 'primary' },
  { id: 'cleared', label: 'Cleared', count: separationsData.value.filter(s => s.separation_state === 'cleared').length, badgeVariant: 'success' },
  { id: 'settled', label: 'Settled & Paid', count: separationsData.value.filter(s => s.separation_state === 'settled').length },
  { id: 'draft', label: 'Draft', count: separationsData.value.filter(s => s.separation_state === 'draft').length }
]);

// ─── Filtered Dataset ───
const filteredSeparations = computed(() => {
  return separationsData.value.filter(s => {
    // Tab filter
    if (activeTab.value !== 'all' && s.separation_state !== activeTab.value) return false;

    // Type filter
    if (selectedTypeFilter.value !== 'all' && s.separation_type !== selectedTypeFilter.value) return false;

    // Search query
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase();
      const matchName = s.employee_name.toLowerCase().includes(q);
      const matchCode = s.code.toLowerCase().includes(q);
      const matchEmpCode = s.employee_code.toLowerCase().includes(q);
      const matchDept = s.department.toLowerCase().includes(q);
      if (!matchName && !matchCode && !matchEmpCode && !matchDept) return false;
    }

    return true;
  });
});

// ─── Table Columns (AGENTS.md Rule 9: Atomic Columns) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Employee', visible: true },
  { key: 'separation_type', label: 'Separation Type', visible: true },
  { key: 'notice_date', label: 'Notice Date', visible: true },
  { key: 'last_working_date', label: 'Last Working Date', visible: true },
  { key: 'is_rehire_eligible', label: 'Rehire Eligible', visible: true },
  { key: 'separation_state', label: 'Separation Status', visible: true },
  { key: 'clearance', label: 'Clearance', visible: true },
  { key: 'disciplinary_action', label: 'Disciplinary Case', visible: false },
  { key: 'approved_by', label: 'Approved By', visible: false },
  { key: 'state', label: 'State', visible: false }
]);

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

// ─── Universal Date Formatter (AGENTS.md Rule 22: MMM D, YYYY) ───
const formatDate = (dateStr?: string | null) => {
  if (!dateStr) return '-';
  try {
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  } catch {
    return dateStr;
  }
};

// ─── Quick Create Modal State (AGENTS.md Rule 4: <= 5 Fields) ───
const isQuickCreateOpen = ref(false);
const quickForm = ref({
  employee_id: '',
  separation_type: 'resignation' as SeparationType,
  notice_date: new Date().toISOString().substring(0, 10),
  last_working_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().substring(0, 10),
  is_rehire_eligible: true
});

const employeeOptions = [
  { value: '18', label: 'Kidst Tesfaye (EMP-0018) • HQ Security Supervisor' },
  { value: '19', label: 'Binyam Getachew (EMP-0019) • Senior Accountant' },
  { value: '20', label: 'Tigist Alemu (EMP-0020) • Recruitment Specialist' },
  { value: '21', label: 'Kassahun Bekele (EMP-0021) • Fleet & Logistics Director' },
  { value: '15', label: 'Marta Tadesse (EMP-0015) • Systems Analyst' },
  { value: '14', label: 'Abebe Kebede (EMP-0014) • Store Manager' },
  { value: '22', label: 'Hana Mesfin (EMP-0022) • Finance Specialist' }
];

const separationTypeOptions = [
  { value: 'resignation', label: 'Resignation' },
  { value: 'termination', label: 'Termination' },
  { value: 'end_of_contract', label: 'End of Contract' },
  { value: 'retirement', label: 'Retirement' },
  { value: 'redundancy', label: 'Redundancy' },
  { value: 'mutual_agreement', label: 'Mutual Agreement' },
  { value: 'death', label: 'Death in Service' }
];

const handleSaveQuickCreate = () => {
  if (!quickForm.value.employee_id) {
    showToast('Please select an employee.');
    return;
  }

  const selectedEmp = employeeOptions.find(e => e.value === quickForm.value.employee_id);
  const nameParts = selectedEmp?.label.split(' • ') || ['Unknown Employee', 'General'];
  const nameCode = nameParts[0].split(' (');
  const empName = nameCode[0];
  const empCode = nameCode[1] ? nameCode[1].replace(')', '') : 'EMP-0000';

  const newRecord = addSeparationRecord({
    employee_id: parseInt(quickForm.value.employee_id, 10),
    employee_name: empName,
    employee_code: empCode,
    employee_avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    department: nameParts[1] || 'Operations',
    position: nameParts[1] || 'Staff Member',
    separation_type: quickForm.value.separation_type,
    separation_state: 'pending',
    notice_date: quickForm.value.notice_date,
    last_working_date: quickForm.value.last_working_date,
    reason: 'Initiated via Quick Exit Registration.',
    disciplinary_action_id: null,
    is_rehire_eligible: quickForm.value.is_rehire_eligible,
    exit_interview_note: null,
    approved_by_employee_id: null,
    approved_by_name: null,
    approved_at: null
  });

  isQuickCreateOpen.value = false;
  showToast(`Separation case ${newRecord.code} initiated successfully.`);
};

// ─── Expand Full Form Navigation (AGENTS.md Rule 4) ───
const handleExpandFullForm = () => {
  isQuickCreateOpen.value = false;
  router.push({
    path: '/hr/separations/create',
    query: {
      employee_id: quickForm.value.employee_id,
      separation_type: quickForm.value.separation_type,
      notice_date: quickForm.value.notice_date,
      last_working_date: quickForm.value.last_working_date,
      is_rehire_eligible: String(quickForm.value.is_rehire_eligible)
    }
  });
};

// ─── Interactive Action Dropdown & Detail Navigation (AGENTS.md Golden Triad) ───
const activeActionMenuId = ref<number | null>(null);

const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenus = () => {
  activeActionMenuId.value = null;
};

if (typeof window !== 'undefined') {
  window.addEventListener('click', closeActionMenus);
}

const handleInspectDetails = (id: number) => {
  activeActionMenuId.value = null;
  router.push(`/hr/separations/${id}`);
};

const handleApproveRow = (item: EmployeeSeparationRecord) => {
  item.separation_state = 'approved';
  item.approved_by_name = 'Solomon Worku (HR Director)';
  item.approved_at = new Date().toISOString();
  activeActionMenuId.value = null;
  showToast(`Exit case ${item.code} approved.`);
};

const handleCancelRow = (item: EmployeeSeparationRecord) => {
  item.separation_state = 'cancelled';
  activeActionMenuId.value = null;
  showToast(`Exit case ${item.code} cancelled.`);
};

// ─── Clickable Metric Cards as Quick Filters ───
const handleMetricClick = (tabKey: SeparationTabKey) => {
  if (activeTab.value === tabKey && tabKey !== 'all') {
    activeTab.value = 'all';
  } else {
    activeTab.value = tabKey;
  }
};

// ─── Direct Clearance Navigation ───
const handleNavigateToClearance = (separationId: number, openRegister = false) => {
  activeActionMenuId.value = null;
  router.push({
    path: '/hr/exit-clearance',
    query: {
      separation_id: String(separationId),
      ...(openRegister ? { openRegister: 'true' } : {})
    }
  });
};
</script>

<template>
  <div class="page-container">
    <!-- Breadcrumb Standard (AGENTS.md Rule 3: Exact Sidebar Page Name Only) -->
    <div class="breadcrumb-header-row">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Admin KPI Metrics Grid (AGENTS.md Rule 2 & Rule 21 Type B) -->
    <!-- Clickable Filter Behavior: Clicking a card filters the table by that status! -->
    <div class="metrics-grid">
      <div 
        class="metric-clickable-wrapper" 
        :class="{ 'is-active-filter': activeTab === 'all' }"
        @click="handleMetricClick('all')"
      >
        <MetricCard
          label="Total Separations"
          :value="metrics.total"
          subtext="All recorded employee exit cases"
          :showMenu="false"
        />
      </div>
      <div 
        class="metric-clickable-wrapper" 
        :class="{ 'is-active-filter': activeTab === 'in_clearance' }"
        @click="handleMetricClick('in_clearance')"
      >
        <MetricCard
          label="In Clearance"
          :value="metrics.inClearance"
          subtext="Active departmental handovers in progress"
          :showMenu="false"
        />
      </div>
      <div 
        class="metric-clickable-wrapper" 
        :class="{ 'is-active-filter': activeTab === 'pending' }"
        @click="handleMetricClick('pending')"
      >
        <MetricCard
          label="Pending Approval"
          :value="metrics.pending"
          subtext="Awaiting executive or HR sign-off"
          :showMenu="false"
        />
      </div>
      <div 
        class="metric-clickable-wrapper" 
        :class="{ 'is-active-filter': activeTab === 'settled' }"
        @click="handleMetricClick('settled')"
      >
        <MetricCard
          label="Settled & Finalized"
          :value="metrics.settled"
          subtext="Clearance finalized and accounts settled"
          :showMenu="false"
        />
      </div>
    </div>

    <!-- Admin UnderlineTabs (AGENTS.md Rule 1) -->
    <div class="tabs-wrapper">
      <UnderlineTabs
        v-model="activeTab"
        :tabs="underlineTabs"
      />
    </div>

    <!-- Master Single Table Card Standard (AGENTS.md Rule 10) -->
    <AppDataTable
      title="Employee Separations"
      subtitle="Lifecycle management of employee exits, statutory notice periods, and cross-departmental clearances."
      v-model:searchQuery="searchQuery"
      :columns="tableColumns"
      :totalEntries="filteredSeparations.length"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Primary Action in Toolbar #actions Slot (AGENTS.md Rule 10) -->
      <template #actions>
        <AppButton variant="primary" size="sm" @click="isQuickCreateOpen = true">
  <template #icon-left><Plus :size="15" /></template>
  Initiate Separation
</AppButton>
      </template>

      <!-- Canonical Table (AGENTS.md Rule 8, 9, 10) -->
      <template #default>
        <table class="erp-table">
          <thead>
            <tr>
              <th class="th-checkbox"><input type="checkbox" /></th>
              <!-- Rule 4: Name Column First, with Code inside -->
              <th>Employee</th>
              <th v-if="tableColumns.find(c => c.key === 'separation_type')?.visible">Separation Type</th>
              <th v-if="tableColumns.find(c => c.key === 'notice_date')?.visible">Notice Date</th>
              <th v-if="tableColumns.find(c => c.key === 'last_working_date')?.visible">Last Working Date</th>
              <th v-if="tableColumns.find(c => c.key === 'is_rehire_eligible')?.visible">Rehire Eligible</th>
              <th v-if="tableColumns.find(c => c.key === 'disciplinary_action')?.visible">Disciplinary Case</th>
              <th v-if="tableColumns.find(c => c.key === 'approved_by')?.visible">Approved By</th>
              <th v-if="tableColumns.find(c => c.key === 'separation_state')?.visible">Separation Status</th>
              <th v-if="tableColumns.find(c => c.key === 'clearance')?.visible">Clearance</th>
              <th v-if="tableColumns.find(c => c.key === 'state')?.visible">State</th>
              <th class="th-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="filteredSeparations.length === 0">
              <td colspan="10" class="td-empty">No separation records found matching criteria.</td>
            </tr>
            <tr 
              v-for="item in filteredSeparations" 
              :key="item.id"
              class="clickable-row"
              @click="handleInspectDetails(item.id)"
            >
              <td class="td-checkbox" @click.stop><input type="checkbox" /></td>
              
              <!-- Rule 4 & 5: Name in Secondary Color #404040, Code underneath in Tertiary #737373 -->
              <td class="td-identity">
                <img :src="item.employee_avatar" :alt="item.employee_name" class="table-avatar" />
                <div class="identity-text">
                  <span class="table-name-primary">{{ item.employee_name }}</span>
                  <span class="table-code-subtext">{{ item.code }} • {{ item.department }}</span>
                </div>
              </td>

              <!-- Subsequent Columns strictly styled in Tertiary Color #737373 (Rule 5) -->
              <td v-if="tableColumns.find(c => c.key === 'separation_type')?.visible" class="td-tertiary">
                {{ SEPARATION_TYPE_MAP[item.separation_type] }}
              </td>

              <td v-if="tableColumns.find(c => c.key === 'notice_date')?.visible" class="td-tertiary">
                {{ formatDate(item.notice_date) }}
              </td>

              <td v-if="tableColumns.find(c => c.key === 'last_working_date')?.visible" class="td-tertiary">
                {{ formatDate(item.last_working_date) }}
              </td>

              <td v-if="tableColumns.find(c => c.key === 'is_rehire_eligible')?.visible" class="td-tertiary">
                <span v-if="item.is_rehire_eligible === true">Eligible</span>
                <span v-else-if="item.is_rehire_eligible === false">Ineligible</span>
                <span v-else>-</span>
              </td>

              <td v-if="tableColumns.find(c => c.key === 'disciplinary_action')?.visible" class="td-tertiary">
                {{ item.disciplinary_reference || '-' }}
              </td>

              <td v-if="tableColumns.find(c => c.key === 'approved_by')?.visible" class="td-tertiary">
                {{ item.approved_by_name || '-' }}
              </td>

              <!-- Status Pills strictly for Lifecycle State (Rule 6 & 9) -->
              <td v-if="tableColumns.find(c => c.key === 'separation_state')?.visible" class="td-state">
                <span 
                  class="status-pill"
                  :style="{ 
                    backgroundColor: SEPARATION_STATUS_MAP[item.separation_state].bg, 
                    color: SEPARATION_STATUS_MAP[item.separation_state].color 
                  }"
                >
                  {{ SEPARATION_STATUS_MAP[item.separation_state].label }}
                </span>
              </td>

              <!-- Clearance Column: Badge / Button to go to and create clearance for approved separation -->
              <td v-if="tableColumns.find(c => c.key === 'clearance')?.visible" class="td-clearance" @click.stop>
                <button 
                  v-if="item.separation_state === 'approved'"
                  type="button" 
                  class="btn-clearance-badge is-start"
                  title="Separation approved. Click to open Exit Clearance and register checkpoints."
                  @click="handleNavigateToClearance(item.id, true)"
                >
                  <CheckSquare :size="12" />
                  <span>+ Start Clearance</span>
                </button>
                <button 
                  v-else-if="item.separation_state === 'in_clearance'"
                  type="button" 
                  class="btn-clearance-badge is-active"
                  title="Clearance in progress. Click to view checkpoints."
                  @click="handleNavigateToClearance(item.id, false)"
                >
                  <Clock :size="12" />
                  <span>In Clearance →</span>
                </button>
                <button 
                  v-else-if="item.separation_state === 'cleared'"
                  type="button" 
                  class="btn-clearance-badge is-cleared"
                  title="Department checkpoints cleared. Click to view clearance log."
                  @click="handleNavigateToClearance(item.id, false)"
                >
                  <CheckCircle2 :size="12" />
                  <span>Cleared ✓</span>
                </button>
                <span v-else-if="item.separation_state === 'settled'" class="clearance-muted-label">
                  Settled
                </span>
                <span v-else-if="item.separation_state === 'pending' || item.separation_state === 'draft'" class="clearance-muted-label">
                  Awaiting Approval
                </span>
                <span v-else class="clearance-muted-label">
                  -
                </span>
              </td>

              <!-- State (Rule 9: Active / Inactive reserved for State) -->
              <td v-if="tableColumns.find(c => c.key === 'state')?.visible">
                <span class="status-pill" :class="item.state === 'active' ? 'status-active' : 'status-inactive'">
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </span>
              </td>

              <!-- Standardized 3-Dots Action Dropdown Menu (AGENTS.md Rule 8) -->
              <td class="td-actions" @click.stop>
                <div class="action-dropdown-wrapper">
                  <button 
                    type="button" 
                    class="btn-action-dots"
                    title="Actions"
                    @click="toggleActionMenu(item.id)"
                  >
                    <MoreVertical :size="15" />
                  </button>

                  <div v-if="activeActionMenuId === item.id" class="action-popup-menu">
                    <button type="button" class="popup-item" @click="handleInspectDetails(item.id)">
                      <Eye :size="13" />
                      <span>View Details</span>
                    </button>
                    <button 
                      v-if="item.separation_state === 'pending'"
                      type="button" 
                      class="popup-item item-approve" 
                      @click="handleApproveRow(item)"
                    >
                      <Check :size="13" />
                      <span>Approve Exit</span>
                    </button>
                    <button 
                      v-if="item.separation_state === 'approved'"
                      type="button" 
                      class="popup-item" 
                      @click="handleNavigateToClearance(item.id, true)"
                    >
                      <CheckSquare :size="13" />
                      <span>Start Exit Clearance</span>
                    </button>
                    <button 
                      v-else-if="item.separation_state === 'in_clearance' || item.separation_state === 'cleared'"
                      type="button" 
                      class="popup-item" 
                      @click="handleNavigateToClearance(item.id, false)"
                    >
                      <CheckSquare :size="13" />
                      <span>View Exit Clearance</span>
                    </button>
                    <button 
                      v-if="item.separation_state !== 'settled' && item.separation_state !== 'cancelled'"
                      type="button" 
                      class="popup-item item-cancel" 
                      @click="handleCancelRow(item)"
                    >
                      <X :size="13" />
                      <span>Cancel Request</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </template>
    </AppDataTable>

    <!-- QuickCreateModal (AGENTS.md Rule 4 & 20 & 24) -->
    <!-- <= 5 Required scanning fields, Header Title ONLY, NO descriptions/notes, Save button plain text -->
    <QuickCreateModal
      v-model:show="isQuickCreateOpen"
      title="Initiate Employee Separation"
      @save="handleSaveQuickCreate"
      @expand="handleExpandFullForm"
    >
      <div class="quick-form-grid">
        <FormSelect
          v-model="quickForm.employee_id"
          label="Employee"
          :options="employeeOptions"
          placeholder="Select"
          required
        />

        <FormSelect
          v-model="quickForm.separation_type"
          label="Separation Type"
          :options="separationTypeOptions"
          placeholder="Select"
          required
        />

        <div class="date-field-group">
          <label class="compact-field-label">Notice Date</label>
          <div class="calendar-input-wrapper">
            <Calendar :size="15" class="cal-left-icon" />
            <input 
              v-model="quickForm.notice_date" 
              type="date" 
              class="cal-input" 
              required
            />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>

        <div class="date-field-group">
          <label class="compact-field-label">Last Working Date</label>
          <div class="calendar-input-wrapper">
            <Calendar :size="15" class="cal-left-icon" />
            <input 
              v-model="quickForm.last_working_date" 
              type="date" 
              class="cal-input" 
              required
            />
            <span class="gc-pill-tag">GC</span>
          </div>
        </div>

        <!-- Rule 5 & 80: FormCheckbox with BOTH Label and Business Description -->
        <FormCheckbox
          v-model="quickForm.is_rehire_eligible"
          label="Rehire Eligibility"
          description="Designate whether this employee may be considered for future re-employment within Haleta ERP tenant organizations."
        />
      </div>
    </QuickCreateModal>

    <!-- Case Inspector Modal / Drawer -->
    <div v-if="isCaseInspectorOpen && selectedCase" class="modal-backdrop" @click="isCaseInspectorOpen = false">
      <div class="inspector-card" @click.stop>
        <div class="inspector-header">
          <div class="inspector-title-group">
            <span class="case-code-pill">{{ selectedCase.code }}</span>
            <h3 class="inspector-title">{{ selectedCase.employee_name }}</h3>
            <p class="inspector-sub">{{ selectedCase.position }} • {{ selectedCase.department }}</p>
          </div>
          <button type="button" class="btn-close-inspector" @click="isCaseInspectorOpen = false">✕</button>
        </div>

        <div class="inspector-body">
          <div class="inspector-section">
            <span class="section-label">Exit Case Timeline</span>
            <div class="timeline-row">
              <div class="timeline-node">
                <span class="node-label">Notice Given</span>
                <span class="node-val">{{ formatDate(selectedCase.notice_date) }}</span>
              </div>
              <div class="timeline-node">
                <span class="node-label">Last Working Date</span>
                <span class="node-val">{{ formatDate(selectedCase.last_working_date) }}</span>
              </div>
              <div class="timeline-node">
                <span class="node-label">Separation Mode</span>
                <span class="node-val">{{ SEPARATION_TYPE_MAP[selectedCase.separation_type] }}</span>
              </div>
              <div class="timeline-node">
                <span class="node-label">Lifecycle Status</span>
                <span class="status-pill" :style="{ backgroundColor: SEPARATION_STATUS_MAP[selectedCase.separation_state].bg, color: SEPARATION_STATUS_MAP[selectedCase.separation_state].color }">
                  {{ SEPARATION_STATUS_MAP[selectedCase.separation_state].label }}
                </span>
              </div>
            </div>
          </div>

          <div class="inspector-section">
            <span class="section-label">Formal Exit Reason & Documentation</span>
            <p class="narrative-text">{{ selectedCase.reason }}</p>
          </div>

          <div v-if="selectedCase.exit_interview_note" class="inspector-section">
            <span class="section-label">Exit Interview Notes</span>
            <p class="narrative-text">{{ selectedCase.exit_interview_note }}</p>
          </div>

          <div class="inspector-section">
            <span class="section-label">Rehire Verdict & Approval</span>
            <div class="meta-two-col">
              <div>
                <span class="meta-sub">Rehire Eligible:</span>
                <span class="meta-val">{{ selectedCase.is_rehire_eligible ? 'Yes (Clear record)' : 'No (Restricted)' }}</span>
              </div>
              <div>
                <span class="meta-sub">Approved By:</span>
                <span class="meta-val">{{ selectedCase.approved_by_name || 'Pending Review' }}</span>
              </div>
            </div>
          </div>
        </div>

        <div class="inspector-footer">
          <button 
            type="button" 
            class="btn-secondary-action" 
            @click="isCaseInspectorOpen = false"
          >
            Close
          </button>
          <router-link
            to="/hr/exit-clearance"
            class="btn-primary-action"
          >
            View Departmental Clearance →
          </router-link>
        </div>
      </div>
    </div>

    <!-- Toast Notification -->
    <div v-if="toastMessage" class="toast-popup">
      {{ toastMessage }}
    </div>
  </div>
</template>

<style scoped>
.page-container {
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  background-color: var(--primitive-color-neutral-50, #f8fafc);
  min-height: 100vh;
}

.breadcrumb-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.role-switcher-badge {
  display: flex;
  align-items: center;
  gap: 8px;
}

.role-switcher-label {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
}

.role-pill-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 28px;
  padding: 0 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 500;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}

.role-pill-btn.is-active {
  background-color: #eff6ff;
  border-color: #bfdbfe;
  color: #0b529c;
}

.role-icon {
  color: #0b529c;
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}

.tabs-wrapper {
  margin-top: -4px;
}

.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 18px;
  border-radius: 8px;
  background-color: #0b529c;
  color: #ffffff;
  font-size: 13.5px;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary-create:hover {
  background-color: #083e76;
}

/* ─── Table Cell Proportions (AGENTS.md Rule 8 & 9) ─── */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  background-color: #fafafa;
  color: #737373;
  font-size: 12px;
  font-weight: 500;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.clickable-row {
  cursor: pointer;
  transition: background-color 0.1s ease;
}

.clickable-row:hover {
  background-color: #f8fafc;
}

.th-checkbox, .td-checkbox {
  width: 38px;
  text-align: center;
}

.td-identity {
  display: flex;
  align-items: center;
  gap: 10px;
}

.table-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  object-fit: cover;
}

.identity-text {
  display: flex;
  flex-direction: column;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.table-code-subtext {
  font-size: 11.5px;
  color: #737373;
}

.td-tertiary {
  color: #737373;
}

.status-pill {
  display: inline-block;
  padding: 2.5px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
}

.metric-clickable-wrapper {
  cursor: pointer;
  border-radius: 10px;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.metric-clickable-wrapper:hover {
  transform: translateY(-2px);
}

.metric-clickable-wrapper.is-active-filter {
  box-shadow: 0 0 0 2px #0b529c;
}

.action-dropdown-wrapper {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-dots:hover {
  color: #0b529c;
  border-color: #0b529c;
  background-color: #f8fafc;
}

.action-popup-menu {
  position: absolute;
  right: 0;
  top: 32px;
  background-color: #ffffff;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  padding: 4px;
  z-index: 100;
  min-width: 160px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.popup-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 7px 10px;
  background: none;
  border: none;
  font-size: 12.5px;
  color: #404040;
  text-align: left;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.12s ease;
}

.popup-item:hover {
  background-color: #f1f5f9;
  color: #0b529c;
}

.popup-item.item-approve {
  color: #059669;
}

.popup-item.item-approve:hover {
  background-color: #ecfdf5;
}

.popup-item.item-cancel {
  color: #dc2626;
}

.popup-item.item-cancel:hover {
  background-color: #fee2e2;
}

.td-empty {
  text-align: center;
  padding: 36px 0;
  color: #737373;
}

/* ─── Calendar Input Standard (AGENTS.md Rule 17 & 23) ─── */
.quick-form-grid {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.date-field-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.compact-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.calendar-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}

.cal-left-icon {
  position: absolute;
  left: 10px;
  color: #94a3b8;
  pointer-events: none;
}

.cal-input {
  width: 100%;
  height: 38px;
  padding: 0 42px 0 34px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
}

.cal-input:focus {
  border-color: #0b529c;
  outline: none;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.cal-input::-webkit-calendar-picker-indicator {
  opacity: 0;
  width: 100%;
  height: 100%;
  position: absolute;
  left: 0;
  top: 0;
  cursor: pointer;
}

.gc-pill-tag {
  position: absolute;
  right: 8px;
  padding: 2px 6px;
  background-color: #f1f5f9;
  color: #64748b;
  font-size: 10.5px;
  font-weight: 600;
  border-radius: 4px;
  pointer-events: none;
}

/* ─── Inspector Modal ─── */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.inspector-card {
  background-color: #ffffff;
  border-radius: 12px;
  width: 580px;
  max-width: 90vw;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.inspector-header {
  padding: 18px 20px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  border-bottom: 1px solid #f1f5f9;
}

.case-code-pill {
  display: inline-block;
  padding: 2px 8px;
  background-color: #eff6ff;
  color: #0b529c;
  font-size: 11px;
  font-weight: 600;
  border-radius: 4px;
  margin-bottom: 4px;
}

.inspector-title {
  font-size: 17px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.inspector-sub {
  font-size: 12px;
  color: #737373;
  margin: 2px 0 0;
}

.btn-close-inspector {
  background: none;
  border: none;
  font-size: 16px;
  color: #94a3b8;
  cursor: pointer;
}

.inspector-body {
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.section-label {
  display: block;
  font-size: 11.5px;
  font-weight: 600;
  text-transform: uppercase;
  color: #94a3b8;
  margin-bottom: 6px;
  letter-spacing: 0.5px;
}

.timeline-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
  background-color: #f8fafc;
  padding: 10px 14px;
  border-radius: 8px;
}

.timeline-node {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.node-label {
  font-size: 11px;
  color: #737373;
}

.node-val {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
}

.narrative-text {
  font-size: 13px;
  color: #404040;
  line-height: 1.5;
  background-color: #f8fafc;
  padding: 12px 14px;
  border-radius: 8px;
  margin: 0;
}

.meta-two-col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  font-size: 12.5px;
}

.meta-sub {
  color: #737373;
  margin-right: 6px;
}

.meta-val {
  color: #404040;
  font-weight: 500;
}

.inspector-footer {
  padding: 14px 20px;
  background-color: #f8fafc;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.btn-secondary-action {
  height: 36px;
  padding: 0 16px;
  border-radius: 8px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  color: #404040;
  font-size: 13px;
  cursor: pointer;
}

.btn-primary-action {
  display: inline-flex;
  align-items: center;
  height: 36px;
  padding: 0 18px;
  border-radius: 8px;
  background-color: #0b529c;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  text-decoration: none;
}

.toast-popup {
  position: fixed;
  bottom: 24px;
  right: 24px;
  background-color: #1e293b;
  color: #ffffff;
  padding: 10px 18px;
  border-radius: 8px;
  font-size: 13px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  z-index: 2000;
}

/* ─── Clearance Column Badges & Actions (AGENTS.md Rule 6: 8px Radius) ─── */
.td-clearance {
  white-space: nowrap;
}

.btn-clearance-badge {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 27px;
  padding: 0 11px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.18s ease;
  border: 1px solid transparent;
}

.btn-clearance-badge.is-start {
  background-color: #e0f2fe;
  color: #0369a1;
  border-color: #bae6fd;
}

.btn-clearance-badge.is-start:hover {
  background-color: #0B529C;
  color: #ffffff;
  border-color: #0B529C;
  transform: translateY(-1px);
  box-shadow: 0 2px 5px rgba(11, 82, 156, 0.15);
}

.btn-clearance-badge.is-active {
  background-color: #f3e8ff;
  color: #7c3aed;
  border-color: #e9d5ff;
}

.btn-clearance-badge.is-active:hover {
  background-color: #7c3aed;
  color: #ffffff;
  border-color: #7c3aed;
  transform: translateY(-1px);
}

.btn-clearance-badge.is-cleared {
  background-color: #ecfdf5;
  color: #059669;
  border-color: #a7f3d0;
}

.btn-clearance-badge.is-cleared:hover {
  background-color: #059669;
  color: #ffffff;
  border-color: #059669;
}

.clearance-muted-label {
  font-size: 12px;
  color: #737373;
}
</style>
