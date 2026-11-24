<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  Plus, Check, X, AlertTriangle,
  Filter, Eye, CheckCircle2
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import MetricCard from '../../components/MetricCard.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import { useToast } from '../../composables/useToast';
import {
  clearanceItemsData,
  separationsData,
  CLEARANCE_STATE_MAP,
  SEPARATION_STATUS_MAP,
  updateClearanceState,
  addClearanceItem,
  type ClearanceItemState,
  type ClearanceItemRecord
} from './separationData';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3) ───
// Exact Sidebar Page Name Only: [Monitor] > Exit Clearance
const breadcrumbItems = [
  { label: 'Exit Clearance' }
];

// ─── Role-Adaptive View Switcher ───
const isAdminView = ref(true);

// ─── Active Tab Filter (UnderlineTabs Standard AGENTS.md Rule 1) ───
type ClearanceTabKey = 'all' | 'pending' | 'flagged' | 'cleared' | 'waived';
const activeTab = ref<ClearanceTabKey>('all');

const searchQuery = ref('');
const selectedDeptFilter = ref<string>('all');
const selectedSeparationFilter = ref<number | 'all'>('all');
const selectedRowIds = ref<number[]>([]);
const { toast } = useToast();

const getClearanceStatusColor = (state: string): 'warning' | 'success' | 'error' | 'blue' | 'indigo' => {
  switch (state) {
    case 'cleared': return 'success';
    case 'pending': return 'warning';
    case 'flagged': return 'error';
    case 'waived': return 'blue';
    default: return 'indigo';
  }
};

const showToast = (msg: string) => {
  toast.success(msg);
};

// ─── Dedicated Clearance Creation Modal State (Rule 4: <= 5 Fields) ───
const isRegisterModalOpen = ref(false);
const registerForm = ref({
  separation_id: '',
  organization_unit_id: '5',
  title: '',
  notes: ''
});

const currentFilteredSeparation = computed(() => {
  if (selectedSeparationFilter.value === 'all') return null;
  return separationsData.value.find(s => s.id === selectedSeparationFilter.value);
});

const approvedSeparationOptions = computed(() => {
  return separationsData.value
    .filter(s => s.separation_state !== 'draft' && s.separation_state !== 'cancelled')
    .map(s => ({
      value: String(s.id),
      label: `${s.code} • ${s.employee_name} (${s.employee_code}) - ${s.department}`
    }));
});

const clearingUnitOptions = [
  { value: '5', label: 'Information Technology' },
  { value: '4', label: 'Facilities & Hardware Assets' },
  { value: '2', label: 'Finance & Accounts' },
  { value: '1', label: 'Human Resources' },
  { value: '3', label: 'Plant Operations & Security' },
  { value: '6', label: 'Procurement & Logistics' }
];

const openRegisterModal = (preselectedSepId?: number) => {
  const sepId = preselectedSepId || (selectedSeparationFilter.value !== 'all' ? selectedSeparationFilter.value : undefined);
  registerForm.value = {
    separation_id: sepId ? String(sepId) : (approvedSeparationOptions.value[0]?.value || ''),
    organization_unit_id: '5',
    title: '',
    notes: ''
  };
  isRegisterModalOpen.value = true;
};

const handleSaveClearanceItem = () => {
  if (!registerForm.value.separation_id) {
    showToast('Please select an exit case.');
    return;
  }
  if (!registerForm.value.title.trim()) {
    showToast('Please enter a clearance task / asset title.');
    return;
  }

  const item = addClearanceItem({
    employee_separation_id: parseInt(registerForm.value.separation_id, 10),
    organization_unit_id: parseInt(registerForm.value.organization_unit_id, 10),
    title: registerForm.value.title.trim(),
    notes: registerForm.value.notes.trim() || null
  });

  if (item) {
    showToast(`Clearance item "${item.title}" registered for ${item.separation_code}.`);
    isRegisterModalOpen.value = false;
  }
};

onMounted(() => {
  if (route.query.separation_id) {
    selectedSeparationFilter.value = Number(route.query.separation_id);
    if (route.query.openRegister === 'true') {
      openRegisterModal(Number(route.query.separation_id));
    }
  }
});

// ─── Metric Cards Computed (AGENTS.md Rule 2 & Rule 21) ───
const metrics = computed(() => {
  const pending = clearanceItemsData.value.filter(c => c.clearance_state === 'pending').length;
  const flagged = clearanceItemsData.value.filter(c => c.clearance_state === 'flagged').length;
  const cleared = clearanceItemsData.value.filter(c => c.clearance_state === 'cleared').length;
  const totalFlaggedValue = clearanceItemsData.value
    .filter(c => c.clearance_state === 'flagged' && c.flagged_amount)
    .reduce((sum, c) => sum + (c.flagged_amount || 0), 0)
    .toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

  return {
    pending,
    flagged,
    cleared,
    totalFlaggedValue: `${totalFlaggedValue} ETB`
  };
});

// ─── Tabs Configuration ───
const underlineTabs = computed<BaseTabItem<ClearanceTabKey>[]>(() => [
  { id: 'all', label: 'All Items', count: clearanceItemsData.value.length },
  { id: 'pending', label: 'Pending Sign-off', count: clearanceItemsData.value.filter(c => c.clearance_state === 'pending').length, badgeVariant: 'warning' },
  { id: 'flagged', label: 'Flagged (Deduction)', count: clearanceItemsData.value.filter(c => c.clearance_state === 'flagged').length, badgeVariant: 'danger' },
  { id: 'cleared', label: 'Cleared', count: clearanceItemsData.value.filter(c => c.clearance_state === 'cleared').length, badgeVariant: 'success' },
  { id: 'waived', label: 'Waived', count: clearanceItemsData.value.filter(c => c.clearance_state === 'waived').length }
]);

// ─── Department Options for Filtering ───
const departmentFilterOptions = [
  { value: 'all', label: 'All Departments' },
  { value: 'Information Technology', label: 'Information Technology' },
  { value: 'Facilities & Hardware Assets', label: 'Facilities & Assets' },
  { value: 'Finance & Payroll', label: 'Finance & Payroll' },
  { value: 'Human Resources', label: 'Human Resources' },
  { value: 'Plant Operations & Security', label: 'Plant Operations' }
];

// ─── Filtered Dataset ───
const filteredItems = computed(() => {
  return clearanceItemsData.value.filter(item => {
    // Separation case filter
    if (selectedSeparationFilter.value !== 'all' && item.employee_separation_id !== selectedSeparationFilter.value) {
      return false;
    }

    // Tab filter
    if (activeTab.value !== 'all' && item.clearance_state !== activeTab.value) return false;

    // Dept filter
    if (selectedDeptFilter.value !== 'all' && item.organization_unit_name !== selectedDeptFilter.value) return false;

    // Search query
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase();
      const matchTitle = item.title.toLowerCase().includes(q);
      const matchEmp = item.employee_name.toLowerCase().includes(q);
      const matchCode = item.separation_code.toLowerCase().includes(q);
      const matchDept = item.organization_unit_name.toLowerCase().includes(q);
      if (!matchTitle && !matchEmp && !matchCode && !matchDept) return false;
    }

    return true;
  });
});

// ─── Table Columns (AGENTS.md Rule 9: Atomic Columns) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'title', label: 'Clearance Item & Case', visible: true },
  { key: 'department', label: 'Clearing Unit', visible: true },
  { key: 'employee', label: 'Departing Employee', visible: true },
  { key: 'clearance_state', label: 'Clearance Status', visible: true },
  { key: 'flagged_amount', label: 'Flagged Deduction (ETB)', visible: true },
  { key: 'cleared_by', label: 'Cleared By', visible: true },
  { key: 'cleared_at', label: 'Clearance Date', visible: true },
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

// ─── Multi-Selection Logic for Floating Bar (Rule 11) ───
const isAllSelected = computed(() => {
  return filteredItems.value.length > 0 && selectedRowIds.value.length === filteredItems.value.length;
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedRowIds.value = [];
  } else {
    selectedRowIds.value = filteredItems.value.map(i => i.id);
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

const handleBatchClear = () => {
  selectedRowIds.value.forEach(id => {
    updateClearanceState(id, 'cleared');
  });
  showToast(`${selectedRowIds.value.length} clearance items marked as cleared.`);
  selectedRowIds.value = [];
};

// ─── Item Level Action Handlers ───
const handleQuickClear = (item: ClearanceItemRecord) => {
  updateClearanceState(item.id, 'cleared');
  showToast(`Item "${item.title}" cleared successfully.`);
};

const handleQuickWaive = (item: ClearanceItemRecord) => {
  updateClearanceState(item.id, 'waived', null, 'Waived per management authorization.');
  showToast(`Item "${item.title}" waived.`);
};

// ─── Flag Modal State (For feeding Final Settlement Line deduction) ───
const isFlagModalOpen = ref(false);
const activeFlagItem = ref<ClearanceItemRecord | null>(null);
const flagForm = ref({
  amount: 0,
  reason: ''
});

const openFlagModal = (item: ClearanceItemRecord) => {
  activeFlagItem.value = item;
  flagForm.value = {
    amount: item.flagged_amount || 1500,
    reason: item.notes || 'Unreturned asset / pending cash float reconciliation'
  };
  isFlagModalOpen.value = true;
};

const handleSaveFlag = () => {
  if (!activeFlagItem.value) return;
  if (flagForm.value.amount <= 0) {
    showToast('Please specify a positive deduction amount.');
    return;
  }

  updateClearanceState(
    activeFlagItem.value.id, 
    'flagged', 
    flagForm.value.amount, 
    flagForm.value.reason
  );

  isFlagModalOpen.value = false;
  showToast(`Flagged ${flagForm.value.amount.toLocaleString()} ETB deduction on ${activeFlagItem.value.separation_code}.`);
};

// ─── Interactive Action Dropdown (AGENTS.md Rule 8) ───
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

// ─── Clickable Metric Cards as Quick Filters ───
const handleMetricClick = (tabKey: ClearanceTabKey) => {
  if (activeTab.value === tabKey && tabKey !== 'all') {
    activeTab.value = 'all';
  } else {
    activeTab.value = tabKey;
  }
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
        :class="{ 'is-active-filter': activeTab === 'pending' }"
        @click="handleMetricClick('pending')"
      >
        <MetricCard
          label="Pending Clearance Items"
          :value="metrics.pending"
          subtext="Awaiting department handover sign-off"
          :showMenu="false"
        />
      </div>
      <div 
        class="metric-clickable-wrapper" 
        :class="{ 'is-active-filter': activeTab === 'flagged' }"
        @click="handleMetricClick('flagged')"
      >
        <MetricCard
          label="Flagged for Deduction"
          :value="metrics.flagged"
          subtext="Unreturned assets & financial liabilities"
          :showMenu="false"
        />
      </div>
      <div 
        class="metric-clickable-wrapper" 
        :class="{ 'is-active-filter': activeTab === 'all' }"
        @click="handleMetricClick('all')"
      >
        <MetricCard
          label="Total Flagged Value"
          :value="metrics.totalFlaggedValue"
          subtext="Total recoverable liabilities for settlement"
          :showMenu="false"
        />
      </div>
      <div 
        class="metric-clickable-wrapper" 
        :class="{ 'is-active-filter': activeTab === 'cleared' }"
        @click="handleMetricClick('cleared')"
      >
        <MetricCard
          label="Cleared Handover Items"
          :value="metrics.cleared"
          subtext="Successfully verified & signed off"
          :showMenu="false"
        />
      </div>
    </div>

    <!-- Primary Tab Group (AGENTS.md Single Tab Rule) -->
    <div class="tabs-toolbar-row">
      <BaseTabs
        v-model="activeTab"
        :tabs="underlineTabs"
        type="rounded"
      />
      
      <div class="dept-filter-box">
        <FormSelect
          v-model="selectedDeptFilter"
          label="Filter Department:"
          :options="departmentFilterOptions"
          placeholder="Select Department"
        />
      </div>
    </div>

    <!-- Active Separation Filter Banner -->
    <div v-if="selectedSeparationFilter !== 'all' && currentFilteredSeparation" class="sep-filter-banner">
      <div class="sep-filter-info">
        <span class="sep-filter-title">Filtered by Exit Case:</span>
        <span class="sep-filter-pill">{{ currentFilteredSeparation.code }}</span>
        <span class="sep-filter-emp">{{ currentFilteredSeparation.employee_name }} ({{ currentFilteredSeparation.employee_code }})</span>
        <span class="sep-filter-dept">• {{ currentFilteredSeparation.department }}</span>
      </div>
      <AppButton variant="outline" size="xs" @click="selectedSeparationFilter = 'all'">
        <template #icon-left><X :size="13" /></template>
        Show All Clearances
      </AppButton>
    </div>

    <!-- Master Single Table Card Standard (AGENTS.md Rule 10) -->
    <AppDataTable
      title="Exit Clearance"
      subtitle="Cross-departmental sign-off registry verifying property surrender, software access revocation, and financial settlement deductions."
      v-model:searchQuery="searchQuery"
      :columns="tableColumns"
      :totalEntries="filteredItems.length"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Action button inside AppDataTable header per Rule 10 -->
      <template #actions>
        <AppButton variant="primary" size="sm" @click="openRegisterModal()">
  <template #icon-left><Plus :size="15" /></template>
  Register Clearance Item
</AppButton>
      </template>

      <!-- Canonical Table (AGENTS.md Rule 8, 9, 10) -->
      <template #default>
        <table class="erp-table">
          <thead>
            <tr>
              <th class="th-checkbox">
                <input 
                  type="checkbox" 
                  :checked="isAllSelected"
                  @change="toggleSelectAll" 
                />
              </th>
              <th>Clearance Item &amp; Case</th>
              <th v-if="tableColumns.find(c => c.key === 'department')?.visible">Clearing Unit</th>
              <th v-if="tableColumns.find(c => c.key === 'employee')?.visible">Departing Employee</th>
              <th v-if="tableColumns.find(c => c.key === 'clearance_state')?.visible">Clearance Status</th>
              <th v-if="tableColumns.find(c => c.key === 'flagged_amount')?.visible">Flagged Deduction</th>
              <th v-if="tableColumns.find(c => c.key === 'cleared_by')?.visible">Cleared By</th>
              <th v-if="tableColumns.find(c => c.key === 'cleared_at')?.visible">Clearance Date</th>
              <th v-if="tableColumns.find(c => c.key === 'state')?.visible">State</th>
              <th class="th-actions">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="filteredItems.length === 0">
              <td colspan="9" class="td-empty">No clearance items matching criteria.</td>
            </tr>
            <tr 
              v-for="item in filteredItems" 
              :key="item.id"
              :class="{ 'row-selected': selectedRowIds.includes(item.id) }"
            >
              <td class="td-checkbox">
                <input 
                  type="checkbox" 
                  :checked="selectedRowIds.includes(item.id)"
                  @change="toggleSelectRow(item.id)" 
                />
              </td>

              <!-- First Column: Item Name in Secondary #404040, Case Code in Tertiary #737373 -->
              <td class="td-primary-info">
                <span class="table-name-primary">{{ item.title }}</span>
                <span class="table-code-subtext">{{ item.separation_code }}</span>
              </td>

              <!-- Clearing Unit (Tertiary #737373, Zero decorative badge per Rule 6) -->
              <td v-if="tableColumns.find(c => c.key === 'department')?.visible" class="td-tertiary">
                {{ item.organization_unit_name }}
              </td>

              <!-- Departing Employee (Rule 8: Zero foreign avatars in middle columns!) -->
              <td v-if="tableColumns.find(c => c.key === 'employee')?.visible" class="td-tertiary">
                {{ item.employee_name }}
              </td>

              <!-- Clearance State Status Pill (Rule 6 & 9) -->
              <td v-if="tableColumns.find(c => c.key === 'clearance_state')?.visible" class="td-state">
                <BaseBadge :color="getClearanceStatusColor(item.clearance_state)">
                  {{ CLEARANCE_STATE_MAP[item.clearance_state].label }}
                </BaseBadge>
              </td>

              <!-- Flagged Amount -->
              <td v-if="tableColumns.find(c => c.key === 'flagged_amount')?.visible" class="td-tertiary font-numeric">
                <span v-if="item.flagged_amount" class="text-danger">
                  {{ item.flagged_amount.toLocaleString('en-US', { minimumFractionDigits: 2 }) }} ETB
                </span>
                <span v-else>-</span>
              </td>

              <td v-if="tableColumns.find(c => c.key === 'cleared_by')?.visible" class="td-tertiary">
                {{ item.cleared_by_name || '-' }}
              </td>

              <td v-if="tableColumns.find(c => c.key === 'cleared_at')?.visible" class="td-tertiary">
                {{ formatDate(item.cleared_at) }}
              </td>

              <!-- State (Rule 9: Active / Inactive reserved for State) -->
              <td v-if="tableColumns.find(c => c.key === 'state')?.visible">
                <BaseBadge :color="item.state === 'active' ? 'success' : 'gray'">
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </BaseBadge>
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
                    <button 
                      v-if="item.clearance_state !== 'cleared'"
                      type="button" 
                      class="popup-item item-approve" 
                      @click="activeActionMenuId = null; handleQuickClear(item)"
                    >
                      <Check :size="13" />
                      <span>Sign-off & Clear</span>
                    </button>
                    <button 
                      v-if="item.clearance_state !== 'flagged'"
                      type="button" 
                      class="popup-item item-danger" 
                      @click="activeActionMenuId = null; openFlagModal(item)"
                    >
                      <AlertTriangle :size="13" />
                      <span>Flag for Deduction</span>
                    </button>
                    <button 
                      v-if="item.clearance_state !== 'waived' && item.clearance_state !== 'cleared'"
                      type="button" 
                      class="popup-item" 
                      @click="activeActionMenuId = null; handleQuickWaive(item)"
                    >
                      <X :size="13" />
                      <span>Waive Item</span>
                    </button>
                    <button 
                      type="button" 
                      class="popup-item" 
                      @click="activeActionMenuId = null; router.push(`/hr/separations/${item.employee_separation_id}`)"
                    >
                      <Eye :size="13" />
                      <span>View Exit Case</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </template>
    </AppDataTable>

    <!-- Floating Batch Action Bar Standard (AGENTS.md Rule 11 & Rule 3) -->
    <TableFloatingBar
      :show="selectedRowIds.length > 0"
      :selectedCount="selectedRowIds.length"
      :totalCount="filteredItems.length"
      :showChangeStatus="false"
      :showDuplicate="false"
      :showEdit="false"
      :showDelete="false"
      @selectAll="toggleSelectAll"
      @close="selectedRowIds = []"
    >
      <template #custom-actions>
        <AppButton variant="primary" size="sm" @click="handleBatchClear">
          <template #icon-left><CheckCircle2 :size="14" /></template>
          <span>Clear Selected Items</span>
        </AppButton>
      </template>
    </TableFloatingBar>

    <!-- Flag Item Modal (Feeding Final Settlement Deduction Line) -->
    <QuickCreateModal
      v-model:show="isFlagModalOpen"
      title="Flag Clearance Liability / Deduction"
      saveLabel="Apply Flagged Deduction"
      :showExpandButton="false"
      @save="handleSaveFlag"
    >
      <div v-if="activeFlagItem" class="flag-modal-body">
        <div class="active-item-summary">
          <span class="summary-code">{{ activeFlagItem.separation_code }}</span>
          <h4 class="summary-title">{{ activeFlagItem.title }}</h4>
          <p class="summary-emp">{{ activeFlagItem.employee_name }} • {{ activeFlagItem.organization_unit_name }}</p>
        </div>

        <FormInput
          v-model="flagForm.amount"
          type="number"
          label="Recoverable Deduction Amount (ETB)"
          hint="This financial liability will automatically feed as a deduction line into the employee's Final Settlement calculation."
          required
        />
      </div>
    </QuickCreateModal>

    <!-- Register Clearance Item Modal (Rule 4: <= 5 Essential Fields) -->
    <QuickCreateModal
      v-model:show="isRegisterModalOpen"
      title="Register Clearance Item"
      subtitle="Register a departmental sign-off checkpoint or asset recovery task for an approved exit case."
      saveLabel="Register Item"
      :showExpandButton="false"
      @save="handleSaveClearanceItem"
    >
      <div class="register-clearance-body">
        <FormSelect
          v-model="registerForm.separation_id"
          label="Departing Staff / Exit Case"
          :options="approvedSeparationOptions"
          placeholder="Select"
          required
        />

        <FormSelect
          v-model="registerForm.organization_unit_id"
          label="Clearing Department"
          :options="clearingUnitOptions"
          placeholder="Select"
          required
        />

        <FormInput
          v-model="registerForm.title"
          label="Clearance Task / Asset Title"
          required
        />

        <div class="form-compact-group">
          <label class="form-compact-label">Handover Instructions & Notes</label>
          <textarea
            v-model="registerForm.notes"
            class="form-compact-textarea"
            rows="2"
          ></textarea>
        </div>
      </div>
    </QuickCreateModal>
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

.tabs-toolbar-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: -4px;
}

.dept-filter-box {
  display: flex;
  align-items: center;
  gap: 8px;
}

.dept-filter-label {
  font-size: 12px;
  color: #737373;
}

.dept-select {
  height: 32px;
  padding: 0 10px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  font-size: 12.5px;
  color: #404040;
  background-color: #ffffff;
  outline: none;
}

.dept-select:focus {
  border-color: #0b529c;
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

.row-selected {
  background-color: #f0fdf4 !important;
}

.th-checkbox, .td-checkbox {
  width: 38px;
  text-align: center;
}

.td-primary-info {
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

.font-numeric {
  font-variant-numeric: tabular-nums;
}

.text-danger {
  color: #dc2626;
  font-weight: 600;
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
  background-color: #fafafa;
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
  min-width: 170px;
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
  background-color: #f5f5f5;
  color: #0b529c;
}

.popup-item.item-approve {
  color: #059669;
}

.popup-item.item-approve:hover {
  background-color: #ecfdf5;
}

.popup-item.item-danger {
  color: #dc2626;
}

.popup-item.item-danger:hover {
  background-color: #fee2e2;
}

.btn-floating-batch {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 14px;
  border-radius: 6px;
  background-color: #059669;
  color: #ffffff;
  font-size: 12.5px;
  font-weight: 500;
  border: none;
  cursor: pointer;
}

.flag-modal-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.active-item-summary {
  background-color: #fafafa;
  padding: 12px 14px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.summary-code {
  font-size: 11px;
  font-weight: 600;
  color: #0b529c;
}

.summary-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 4px 0 2px;
}

.summary-emp {
  font-size: 12px;
  color: #737373;
  margin: 0;
}

.td-empty {
  text-align: center;
  padding: 36px 0;
  color: #737373;
}

.btn-primary-register {
  height: 34px;
  padding: 0 16px;
  background-color: #0b529c;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary-register:hover {
  background-color: #083e76;
}

/* ─── Separation Case Filter Banner ─── */
.sep-filter-banner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background-color: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 8px;
  margin-bottom: 2px;
}

.sep-filter-info {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #1e3a8a;
}

.sep-filter-title {
  font-weight: 500;
  color: #1e40af;
}

.sep-filter-pill {
  font-size: 11.5px;
  font-weight: 600;
  background-color: #dbeafe;
  color: #1d4ed8;
  padding: 2px 8px;
  border-radius: 4px;
}

.sep-filter-emp {
  font-weight: 600;
  color: #404040;
}

.sep-filter-dept {
  color: #737373;
  font-size: 12.5px;
}

.btn-clear-filter {
  background: transparent;
  border: 1px solid #93c5fd;
  color: #1d4ed8;
  font-size: 12px;
  font-weight: 500;
  padding: 4px 10px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-clear-filter:hover {
  background-color: #dbeafe;
  border-color: #60a5fa;
}

/* ─── Register Modal Body ─── */
.register-clearance-body {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.form-compact-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.form-compact-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.form-compact-textarea {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px 12px;
  font-size: 13.5px;
  color: #404040;
  outline: none;
  font-family: inherit;
  resize: vertical;
}

.form-compact-textarea:focus {
  border-color: #0b529c;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.bulk-init-panel {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 12px 14px;
  background-color: #fafafa;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  margin-top: 4px;
}
</style>
