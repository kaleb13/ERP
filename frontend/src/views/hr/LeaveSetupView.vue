<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  Plus, MoreVertical, Eye, CheckCircle2,
  ShieldCheck, AlertCircle, ListFilter
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import { useToast } from '../../composables/useToast';
import { 
  leavePoliciesData, 
  leaveTypesData, 
  createLeaveType,
  type LeavePolicyRecord,
  type LeaveTypeRecord
} from './leavePolicyData';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3: Exact Sidebar Page Name Only) ───
// STRICTLY NO separate back button! Breadcrumb itself is the sole navigation.
const breadcrumbItems = [
  { label: 'Leave Setup' }
];

// ─── Top Tabs: <BaseTabs /> Primary Capsule Standard (AGENTS.md Rule 1) ───
type SetupTab = 'policies' | 'types';
const activeTab = ref<SetupTab>('policies');

const syncTabFromRoute = () => {
  const t = route.query.tab as string;
  if (t === 'types') {
    activeTab.value = 'types';
  } else {
    activeTab.value = 'policies';
  }
};

onMounted(() => { syncTabFromRoute(); });
watch(() => route.query.tab, () => { syncTabFromRoute(); });

const handleTabChange = (tabId: SetupTab) => {
  activeTab.value = tabId;
  router.replace({ query: { ...route.query, tab: tabId } });
};

const setupTabs = computed<BaseTabItem<SetupTab>[]>(() => [
  { 
    id: 'policies', 
    label: 'Leave Policies', 
    icon: ShieldCheck, 
    count: leavePoliciesData.value.length 
  },
  { 
    id: 'types', 
    label: 'Leave Types', 
    icon: ListFilter, 
    count: leaveTypesData.value.length 
  }
]);

// Toast Notification
const { toast } = useToast();
const showToast = (msg: string) => {
  toast.success(msg);
};

// =========================================================================
// TAB 1: LEAVE POLICIES LOGIC
// =========================================================================
const policies = leavePoliciesData;
const policySearch = ref('');
const policyFilterState = ref('All');
const activePolicyMenuId = ref<number | null>(null);

const policyColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Policy Name & Code', visible: true, sortable: true },
  { key: 'entity_name', label: 'Owning Entity / Branch', visible: true, sortable: true },
  { key: 'work_calendar_name', label: 'Work Calendar', visible: true, sortable: true },
  { key: 'effective_period', label: 'Effective Period', visible: true, sortable: true },
  { key: 'rules_count', label: 'Entitlement Rules', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', width: '48px', align: 'center', visible: true }
]);

const stateFilterOptions: SelectOption[] = [
  { value: 'All', label: 'All States' },
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' }
];

const filteredPolicies = computed(() => {
  return policies.value.filter(p => {
    if (policySearch.value) {
      const q = policySearch.value.toLowerCase().trim();
      const matchName = p.name.toLowerCase().includes(q);
      const matchCode = p.code.toLowerCase().includes(q);
      const matchEntity = p.entity_name.toLowerCase().includes(q);
      const matchCal = p.work_calendar_name.toLowerCase().includes(q);
      if (!matchName && !matchCode && !matchEntity && !matchCal) return false;
    }
    if (policyFilterState.value !== 'All' && p.state !== policyFilterState.value) {
      return false;
    }
    return true;
  });
});

const selectedPolicyIds = ref<number[]>([]);
const isAllPoliciesSelected = computed(() => {
  return filteredPolicies.value.length > 0 && selectedPolicyIds.value.length === filteredPolicies.value.length;
});

const toggleSelectAllPolicies = () => {
  if (isAllPoliciesSelected.value) {
    selectedPolicyIds.value = [];
  } else {
    selectedPolicyIds.value = filteredPolicies.value.map(p => p.id);
  }
};

const toggleSelectPolicyRow = (id: number) => {
  const idx = selectedPolicyIds.value.indexOf(id);
  if (idx > -1) selectedPolicyIds.value.splice(idx, 1);
  else selectedPolicyIds.value.push(id);
};

const handleBatchDeletePolicies = () => {
  policies.value = policies.value.filter(p => !selectedPolicyIds.value.includes(p.id));
  showToast(`Deleted ${selectedPolicyIds.value.length} leave policy rulebook(s).`);
  selectedPolicyIds.value = [];
};

const goToCreatePolicy = () => {
  router.push('/hr/leave-policies/create');
};

const goToPolicyDetail = (id: number) => {
  activePolicyMenuId.value = null;
  router.push(`/hr/leave-policies/${id}`);
};

const handleTogglePolicyState = (item: LeavePolicyRecord) => {
  item.state = item.state === 'active' ? 'inactive' : 'active';
  activePolicyMenuId.value = null;
  showToast(`Policy "${item.code}" marked as ${item.state}.`);
};

// =========================================================================
// TAB 2: LEAVE TYPES LOGIC (QuickCreateModal for <= 5 fields per Rule 4)
// =========================================================================
const leaveTypes = leaveTypesData;
const typeSearch = ref('');
const isQuickCreateTypeOpen = ref(false);
const activeTypeMenuId = ref<number | null>(null);

const quickTypeForm = ref({
  code: '',
  name: '',
  description: '',
  is_paid: true,
  requires_attachment: false,
  affects_attendance: true
});

const typeColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Leave Type Name & Code', visible: true, sortable: true },
  { key: 'is_paid', label: 'Compensation Type', visible: true, sortable: true },
  { key: 'requires_attachment', label: 'Document Evidence', visible: true, sortable: true },
  { key: 'affects_attendance', label: 'Affects Attendance', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', width: '48px', align: 'center', visible: true }
]);

const filteredTypes = computed(() => {
  if (!typeSearch.value) return leaveTypes.value;
  const q = typeSearch.value.toLowerCase().trim();
  return leaveTypes.value.filter(t => 
    t.name.toLowerCase().includes(q) || 
    t.code.toLowerCase().includes(q) ||
    t.description.toLowerCase().includes(q)
  );
});

const selectedTypeIds = ref<number[]>([]);
const isAllTypesSelected = computed(() => {
  return filteredTypes.value.length > 0 && selectedTypeIds.value.length === filteredTypes.value.length;
});

const toggleSelectAllTypes = () => {
  if (isAllTypesSelected.value) selectedTypeIds.value = [];
  else selectedTypeIds.value = filteredTypes.value.map(t => t.id);
};

const toggleSelectTypeRow = (id: number) => {
  const idx = selectedTypeIds.value.indexOf(id);
  if (idx > -1) selectedTypeIds.value.splice(idx, 1);
  else selectedTypeIds.value.push(id);
};

const handleBatchDeleteTypes = () => {
  leaveTypes.value = leaveTypes.value.filter(t => !selectedTypeIds.value.includes(t.id));
  showToast(`Deleted ${selectedTypeIds.value.length} leave category(ies).`);
  selectedTypeIds.value = [];
};

const openQuickCreateType = () => {
  quickTypeForm.value = {
    code: '',
    name: '',
    description: '',
    is_paid: true,
    requires_attachment: false,
    affects_attendance: true
  };
  isQuickCreateTypeOpen.value = true;
};

const handleQuickSaveType = () => {
  if (!quickTypeForm.value.code.trim() || !quickTypeForm.value.name.trim()) {
    alert('Please enter both leave code and name.');
    return;
  }

  const newRec = createLeaveType({
    code: quickTypeForm.value.code,
    name: quickTypeForm.value.name,
    description: quickTypeForm.value.description,
    is_paid: quickTypeForm.value.is_paid,
    requires_attachment: quickTypeForm.value.requires_attachment,
    affects_attendance: quickTypeForm.value.affects_attendance
  });

  showToast(`Leave category "${newRec.name}" created.`);
  isQuickCreateTypeOpen.value = false;
};

const handleExpandTypeCreate = () => {
  isQuickCreateTypeOpen.value = false;
  router.push({
    path: '/hr/leave-types/create',
    query: {
      code: quickTypeForm.value.code,
      name: quickTypeForm.value.name,
      description: quickTypeForm.value.description,
      is_paid: String(quickTypeForm.value.is_paid),
      requires_attachment: String(quickTypeForm.value.requires_attachment),
      affects_attendance: String(quickTypeForm.value.affects_attendance)
    }
  });
};

const handleToggleTypeState = (item: LeaveTypeRecord) => {
  item.state = item.state === 'active' ? 'inactive' : 'active';
  activeTypeMenuId.value = null;
  showToast(`Leave type "${item.code}" marked as ${item.state}.`);
};
</script>

<template>
  <div class="leave-setup-page" @click="activePolicyMenuId = null; activeTypeMenuId = null">
    <!-- Breadcrumb Bar (AGENTS.md Rule 3: Exact Sidebar Page Name Only) -->
    <div class="breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Top Primary Capsule Tabs (AGENTS.md Rule 1: <BaseTabs />) -->
    <div class="tabs-header-wrap">
      <BaseTabs
        :model-value="activeTab"
        :tabs="setupTabs"
        @update:model-value="handleTabChange"
      />
    </div>

    <!-- ================================================================= -->
    <!-- TAB 1: LEAVE POLICIES -->
    <!-- ================================================================= -->
    <div v-show="activeTab === 'policies'" class="setup-tab-body">
      <AppDataTable
        title="Leave Policy Rulebooks"
        subtitle="Organizational rule catalogs binding leave types to statutory accrual formulas, work calendars, and carry-forward ceilings."
        :columns="policyColumns"
        :data="filteredPolicies"
        v-model:searchQuery="policySearch"
        searchPlaceholder="Search policies by name, code, entity, or calendar..."
      >
        <!-- Top Action Slot: Create Policy Button -->
        <template #actions>
          <AppButton variant="primary" size="sm" @click="goToCreatePolicy">
            <template #icon-left><Plus :size="16" /></template>
            Create Leave Policy
          </AppButton>
        </template>

        <!-- Filters Slot -->
        <template #filters>
          <div class="filter-dropdown-wrap">
            <FormSelect
              v-model="policyFilterState"
              :options="stateFilterOptions"
              placeholder="Select"
              class="filter-select"
            />
          </div>
        </template>

        <!-- Custom Table Slot -->
        <template #default>
          <div class="table-responsive">
            <table class="erp-table">
              <thead>
                <tr>
                  <th class="th-checkbox" width="40">
                    <input
                      type="checkbox"
                      :checked="isAllPoliciesSelected"
                      @change="toggleSelectAllPolicies"
                      class="table-checkbox"
                      aria-label="Select all policies"
                    />
                  </th>
                  <th>Policy Name &amp; Code</th>
                  <th>Owning Entity / Branch</th>
                  <th>Work Calendar</th>
                  <th>Effective Period</th>
                  <th>Entitlement Rules</th>
                  <th>State</th>
                  <th width="48" class="text-center"></th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="item in filteredPolicies" 
                  :key="item.id"
                  class="erp-row clickable-row"
                  @click="goToPolicyDetail(item.id)"
                >
                  <!-- Checkbox -->
                  <td class="td-checkbox" @click.stop>
                    <input
                      type="checkbox"
                      :checked="selectedPolicyIds.includes(item.id)"
                      @change="toggleSelectPolicyRow(item.id)"
                      class="table-checkbox"
                      aria-label="Select policy row"
                    />
                  </td>

                  <!-- Name & Code (Rule 4: Name on top, Code as subtext) -->
                  <td>
                    <div class="name-column-wrap">
                      <span class="table-name-primary">{{ item.name }}</span>
                      <span class="table-code-subtext">{{ item.code }}</span>
                    </div>
                  </td>

                  <!-- Owning Entity / Branch -->
                  <td>
                    <span class="table-text-tertiary">{{ item.entity_name }}</span>
                  </td>

                  <!-- Work Calendar -->
                  <td>
                    <span class="table-text-tertiary">{{ item.work_calendar_name }}</span>
                  </td>

                  <!-- Effective Period -->
                  <td>
                    <span class="table-text-tertiary">
                      {{ item.effective_from }} 
                      <template v-if="item.effective_to">➔ {{ item.effective_to }}</template>
                      <template v-else>➔ Current</template>
                    </span>
                  </td>

                  <!-- Rules Count -->
                  <td>
                    <span class="table-text-tertiary">{{ item.rules_count }} Rules Defined</span>
                  </td>

                  <!-- State -->
                  <td>
                    <BaseBadge :color="item.state === 'active' ? 'success' : 'gray'">
                      {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                    </BaseBadge>
                  </td>

                  <!-- Actions Menu -->
                  <td class="td-actions" @click.stop>
                    <div class="action-menu-relative">
                      <button 
                        class="btn-action-dots" 
                        @click="activePolicyMenuId = activePolicyMenuId === item.id ? null : item.id"
                        title="Actions"
                      >
                        <MoreVertical :size="15" />
                      </button>

                      <div v-if="activePolicyMenuId === item.id" class="dropdown-action-menu">
                        <button class="dropdown-item" @click="goToPolicyDetail(item.id)">
                          <Eye :size="14" />
                          <span>View Policy Rules</span>
                        </button>
                        <button class="dropdown-item" @click="handleTogglePolicyState(item)">
                          <ShieldCheck :size="14" />
                          <span>Mark as {{ item.state === 'active' ? 'Inactive' : 'Active' }}</span>
                        </button>
                      </div>
                    </div>
                  </td>
                </tr>

                <!-- Empty State -->
                <tr v-if="filteredPolicies.length === 0">
                  <td colspan="8" class="empty-table-cell">
                    <div class="empty-state-wrap">
                      <AlertCircle :size="32" class="empty-icon" />
                      <p class="empty-title">No Leave Policies Found</p>
                      <p class="empty-desc">Create your first organizational leave policy rulebook to configure statutory accrual formulas.</p>
                      <AppButton variant="primary" size="sm" @click="goToCreatePolicy">
                        <template #icon-left><Plus :size="15" /></template>
                        Create Leave Policy
                      </AppButton>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </template>
      </AppDataTable>

      <!-- Floating Batch Bar for Policies -->
      <TableFloatingBar 
        :count="selectedPolicyIds.length" 
        @delete="handleBatchDeletePolicies" 
      />
    </div>

    <!-- ================================================================= -->
    <!-- TAB 2: LEAVE TYPES -->
    <!-- ================================================================= -->
    <div v-show="activeTab === 'types'" class="setup-tab-body">
      <AppDataTable
        title="Leave Category Catalog"
        subtitle="Master catalog of statutory and enterprise leave types governing paid compensation, documentation, and attendance impact."
        :columns="typeColumns"
        :data="filteredTypes"
        v-model:searchQuery="typeSearch"
        searchPlaceholder="Search leave categories by name, code, or description..."
      >
        <!-- Top Action Slot: Quick Create Type Button -->
        <template #actions>
          <AppButton variant="primary" size="sm" @click="openQuickCreateType">
            <template #icon-left><Plus :size="16" /></template>
            Create Leave Type
          </AppButton>
        </template>

        <!-- Custom Table Slot -->
        <template #default>
          <div class="table-responsive">
            <table class="erp-table">
              <thead>
                <tr>
                  <th class="th-checkbox" width="40">
                    <input
                      type="checkbox"
                      :checked="isAllTypesSelected"
                      @change="toggleSelectAllTypes"
                      class="table-checkbox"
                      aria-label="Select all types"
                    />
                  </th>
                  <th>Leave Type Name &amp; Code</th>
                  <th>Compensation Type</th>
                  <th>Document Evidence</th>
                  <th>Affects Attendance</th>
                  <th>State</th>
                  <th width="48" class="text-center"></th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="item in filteredTypes" 
                  :key="item.id"
                  class="erp-row"
                >
                  <!-- Checkbox -->
                  <td class="td-checkbox">
                    <input
                      type="checkbox"
                      :checked="selectedTypeIds.includes(item.id)"
                      @change="toggleSelectTypeRow(item.id)"
                      class="table-checkbox"
                      aria-label="Select type row"
                    />
                  </td>

                  <!-- Name & Code -->
                  <td>
                    <div class="name-column-wrap">
                      <span class="table-name-primary">{{ item.name }}</span>
                      <span class="table-code-subtext">{{ item.code }}</span>
                    </div>
                  </td>

                  <!-- Compensation Type (Plain text tertiary per Rule 6) -->
                  <td>
                    <span class="table-text-tertiary">
                      {{ item.is_paid ? 'Paid Rest Leave' : 'Unpaid Absence' }}
                    </span>
                  </td>

                  <!-- Document Evidence -->
                  <td>
                    <span class="table-text-tertiary">
                      {{ item.requires_attachment ? 'Mandatory Certificate' : 'Self-Certified / None' }}
                    </span>
                  </td>

                  <!-- Affects Attendance -->
                  <td>
                    <span class="table-text-tertiary">
                      {{ item.affects_attendance ? 'Yes (Clocking Exempt)' : 'No' }}
                    </span>
                  </td>

                  <!-- State -->
                  <td>
                    <BaseBadge :color="item.state === 'active' ? 'success' : 'gray'">
                      {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                    </BaseBadge>
                  </td>

                  <!-- Actions Menu -->
                  <td class="td-actions">
                    <div class="action-menu-relative">
                      <button 
                        class="btn-action-dots" 
                        @click="activeTypeMenuId = activeTypeMenuId === item.id ? null : item.id"
                        title="Actions"
                      >
                        <MoreVertical :size="15" />
                      </button>

                      <div v-if="activeTypeMenuId === item.id" class="dropdown-action-menu">
                        <button class="dropdown-item" @click="handleToggleTypeState(item)">
                          <ShieldCheck :size="14" />
                          <span>Mark as {{ item.state === 'active' ? 'Inactive' : 'Active' }}</span>
                        </button>
                      </div>
                    </div>
                  </td>
                </tr>

                <!-- Empty State -->
                <tr v-if="filteredTypes.length === 0">
                  <td colspan="7" class="empty-table-cell">
                    <div class="empty-state-wrap">
                      <AlertCircle :size="32" class="empty-icon" />
                      <p class="empty-title">No Leave Types Found</p>
                      <p class="empty-desc">Register standard leave categories (Annual, Sick, Maternity, etc.) in the catalog.</p>
                      <AppButton variant="primary" size="sm" @click="openQuickCreateType">
                        <template #icon-left><Plus :size="15" /></template>
                        Create Leave Type
                      </AppButton>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </template>
      </AppDataTable>

      <!-- Floating Batch Bar for Types -->
      <TableFloatingBar 
        :count="selectedTypeIds.length" 
        @delete="handleBatchDeleteTypes" 
      />
    </div>

    <!-- ─── QUICK CREATE LEAVE TYPE MODAL (AGENTS.md Rule 4: <= 5 Required Fields) ─── -->
    <QuickCreateModal
      v-model:show="isQuickCreateTypeOpen"
      title="Create Leave Type"
      :showExpandButton="true"
      @save="handleQuickSaveType"
      @expand="handleExpandTypeCreate"
    >
      <div class="modal-form-stack">
        <!-- Leave Code -->
        <div class="form-group">
          <label class="form-label required">Leave Code</label>
          <FormInput
            v-model="quickTypeForm.code"
            hint="Statutory uppercase identifier, e.g. ANNUAL, SICK, PATERNITY"
          />
        </div>

        <!-- Leave Name -->
        <div class="form-group">
          <label class="form-label required">Leave Category Name</label>
          <FormInput
            v-model="quickTypeForm.name"
          />
        </div>

        <!-- Description -->
        <div class="form-group">
          <label class="form-label">Category Scope Description</label>
          <FormInput
            v-model="quickTypeForm.description"
          />
        </div>

        <!-- Governance Checkboxes (Rule 5: Both Title and Description) -->
        <div class="modal-flags-stack">
          <FormCheckbox
            v-model="quickTypeForm.is_paid"
            label="Paid Leave Compensation"
            description="Employees receive basic salary compensation during approved absence."
          />

          <FormCheckbox
            v-model="quickTypeForm.requires_attachment"
            label="Mandatory Supporting Document"
            description="Requests must include medical certificate, court summons, or official evidence."
          />

          <FormCheckbox
            v-model="quickTypeForm.affects_attendance"
            label="Affects Attendance &amp; Shift Roster"
            description="Exempts employee from automated biometric shift clocking infractions during leave."
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.leave-setup-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: #fafafa;
  min-height: 100vh;
}

.breadcrumb-bar {
  display: flex;
  align-items: center;
}

.tabs-header-wrap {
  width: fit-content;
}

.setup-tab-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* Primary Action Button (Rule 6: 8px to 10px rounded rectangle, NEVER pills) */
.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  height: 38px;
  padding: 0 16px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-primary-action:hover {
  background-color: #09427d;
}

.filter-dropdown-wrap {
  width: 170px;
}

/* Table Architecture (AGENTS.md Rule 8 & 9) */
.table-responsive {
  width: 100%;
  overflow-x: auto;
}

.erp-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.erp-table td {
  height: 48px;
  padding: 8px 16px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.clickable-row {
  cursor: pointer;
  transition: background-color 0.12s ease;
}
.clickable-row:hover {
  background-color: #fafafa;
}

.th-checkbox,
.td-checkbox {
  width: 40px;
  text-align: center;
  padding-left: 14px !important;
  padding-right: 8px !important;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  border-radius: 4px;
  border: 1px solid #cbd5e1;
  accent-color: #0B529C;
  cursor: pointer;
}

/* Rule 4: Name on top, Code as subtext */
.name-column-wrap {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.table-name-primary {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}
.table-code-subtext {
  font-size: 11.5px;
  color: #737373;
}

/* Rule 5: Tertiary color #737373 for all texts in subsequent columns */
.table-text-tertiary {
  color: #737373;
  font-size: 13px;
}

/* Action Dropdown Menu */
.td-actions {
  text-align: center;
}
.action-menu-relative {
  position: relative;
  display: inline-block;
}
.btn-action-dots {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  border-radius: 6px;
  color: #737373;
  cursor: pointer;
  transition: background-color 0.12s ease;
}
.btn-action-dots:hover {
  background-color: #e5e5e5;
  color: #404040;
}

.dropdown-action-menu {
  position: absolute;
  right: 0;
  top: 32px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08);
  width: 170px;
  padding: 4px;
  z-index: 50;
}
.dropdown-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border: none;
  background: transparent;
  font-size: 12.5px;
  color: #404040;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
}
.dropdown-item:hover {
  background-color: #fafafa;
}

/* Empty State */
.empty-table-cell {
  padding: 48px 16px !important;
  text-align: center;
}
.empty-state-wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  max-width: 420px;
  margin: 0 auto;
}
.empty-icon {
  color: #94a3b8;
  margin-bottom: 6px;
}
.empty-title {
  font-size: 14.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.empty-desc {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}
.empty-btn {
  margin-top: 10px;
}

/* Modal Form */
.modal-form-stack {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.form-group {
  display: flex;
  flex-direction: column;
}
.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}
.form-label.required::after {
  content: ' *';
  color: #dc2626;
}
.modal-flags-stack {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding-top: 8px;
  border-top: 1px solid #f1f5f9;
}
</style>
