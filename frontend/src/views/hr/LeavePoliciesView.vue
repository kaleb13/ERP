<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, MoreVertical, Eye, CheckCircle2,
  Trash2, ShieldCheck, AlertCircle,
  LayoutGrid, List
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import { useToast } from '../../composables/useToast';
import { 
  leavePoliciesData, 
  type LeavePolicyRecord 
} from './leavePolicyData';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'Leave Policies' }
];

const { toast } = useToast();
const policies = leavePoliciesData;
const searchQuery = ref('');
const filterState = ref('All');
const activeActionMenuId = ref<number | null>(null);

// Primary View Mode: Clean Minimal Cards (Figma Node 7009:113269 default) vs Table
type ViewMode = 'cards' | 'table';
const viewMode = ref<ViewMode>('cards');

const viewTabs: BaseTabItem<ViewMode>[] = [
  { id: 'cards', label: 'Card View', icon: LayoutGrid },
  { id: 'table', label: 'Table View', icon: List }
];

const showToast = (msg: string) => {
  toast.success(msg);
};

// ─── Table Columns (AGENTS.md Standard) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Policy Name & Code', visible: true, sortable: true },
  { key: 'entity_name', label: 'Owning Entity / Branch', visible: true, sortable: true },
  { key: 'work_calendar_name', label: 'Work Calendar', visible: true, sortable: true },
  { key: 'effective_period', label: 'Effective Period', visible: true, sortable: true },
  { key: 'rules_count', label: 'Entitlement Rules', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', width: '48px', align: 'center', visible: true }
]);

const handleToggleColumn = (colKey: string | { key: string; visible: boolean }) => {
  const k = typeof colKey === 'string' ? colKey : colKey.key;
  const col = tableColumns.value.find(c => c.key === k);
  if (col) col.visible = typeof colKey === 'string' ? !col.visible : colKey.visible;
};

// ─── Filtering ───
const filteredPolicies = computed(() => {
  return policies.value.filter(p => {
    if (searchQuery.value) {
      const q = searchQuery.value.toLowerCase().trim();
      const matchName = p.name.toLowerCase().includes(q);
      const matchCode = p.code.toLowerCase().includes(q);
      const matchEntity = p.entity_name.toLowerCase().includes(q);
      const matchCal = p.work_calendar_name.toLowerCase().includes(q);
      if (!matchName && !matchCode && !matchEntity && !matchCal) return false;
    }
    if (filterState.value !== 'All' && p.state !== filterState.value) {
      return false;
    }
    return true;
  });
});

// ─── Selection for Batch Operations (AGENTS.md Standard) ───
const selectedIds = ref<number[]>([]);

const isAllSelected = computed(() => {
  return filteredPolicies.value.length > 0 && selectedIds.value.length === filteredPolicies.value.length;
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedIds.value = [];
  } else {
    selectedIds.value = filteredPolicies.value.map(p => p.id);
  }
};

const toggleSelectRow = (id: number) => {
  const idx = selectedIds.value.indexOf(id);
  if (idx > -1) {
    selectedIds.value.splice(idx, 1);
  } else {
    selectedIds.value.push(id);
  }
};

const handleBatchDelete = () => {
  policies.value = policies.value.filter(p => !selectedIds.value.includes(p.id));
  showToast(`Deleted ${selectedIds.value.length} leave policy rulebook(s).`);
  selectedIds.value = [];
};

// ─── Navigation ───
const goToCreate = () => {
  router.push('/hr/leave-policies/create');
};

const goToDetail = (id: number) => {
  activeActionMenuId.value = null;
  router.push(`/hr/leave-policies/${id}`);
};

const handleToggleState = (item: LeavePolicyRecord) => {
  item.state = item.state === 'active' ? 'inactive' : 'active';
  activeActionMenuId.value = null;
  showToast(`Policy "${item.code}" marked as ${item.state}.`);
};

const handleDeletePolicy = (id: number) => {
  const idx = policies.value.findIndex(p => p.id === id);
  if (idx > -1) {
    const deleted = policies.value.splice(idx, 1)[0];
    showToast(`Policy "${deleted.name}" deleted.`);
  }
  activeActionMenuId.value = null;
};
</script>

<template>
  <div class="leave-policies-page" @click="activeActionMenuId = null">
    <!-- Breadcrumb Bar (AGENTS.md: Exact Sidebar Page Name Only) -->
    <div class="breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ─── TOP HEADER CARD (Figma Node 7009:113278) ─── -->
    <div class="policies-top-card">
      <div class="header-main-row">
        <div class="header-text-block">
          <h1 class="page-title">Leave Policy Rulebooks</h1>
          <p class="page-subtitle">
            Organizational rule catalogs binding leave types to statutory accrual formulas, work calendars, and carry-forward ceilings.
          </p>
        </div>
        <AppButton variant="primary" @click="goToCreate">
          <template #icon-left><Plus :size="16" /></template>
          Create Leave Policy
        </AppButton>
      </div>

      <!-- Standalone Tabs Row (AGENTS.md: Primary Tab Rounded Group) -->
      <div class="header-tabs-row">
        <BaseTabs
          v-model="viewMode"
          :tabs="viewTabs"
          type="rounded"
        />
      </div>
    </div>

    <!-- ─── VIEW 1: MINIMALIST CARDS VIEW (Figma Node 7009:113269 Default) ─── -->
    <div v-if="viewMode === 'cards'" class="cards-view-wrapper">
      <div class="policy-cards-grid">
        <div 
          v-for="item in filteredPolicies" 
          :key="item.id"
          class="minimal-policy-card"
          @click="goToDetail(item.id)"
        >
          <!-- Card Header: Title + Code + BaseBadge (Figma Node 7009:113293) -->
          <div class="card-header-line">
            <div class="card-identity-block">
              <h3 class="card-policy-name">{{ item.name }}</h3>
              <span class="card-policy-code">{{ item.code }}</span>
            </div>
            <BaseBadge :color="item.state === 'active' ? 'success' : 'gray'">
              {{ item.state === 'active' ? 'Active' : 'Inactive' }}
            </BaseBadge>
          </div>

          <!-- 2x2 Key-Value Metadata Grid (Figma Node 7009:113299) -->
          <div class="card-meta-grid">
            <div class="meta-col">
              <span class="meta-label">Owning Entity</span>
              <span class="meta-val">{{ item.entity_name }}</span>
            </div>
            <div class="meta-col">
              <span class="meta-label">Working Calendar</span>
              <span class="meta-val">{{ item.work_calendar_name }}</span>
            </div>
            <div class="meta-col">
              <span class="meta-label">Effective Period</span>
              <span class="meta-val">{{ item.effective_from }} ➔ {{ item.effective_to || 'Current' }}</span>
            </div>
            <div class="meta-col">
              <span class="meta-label">Policy Rules</span>
              <span class="meta-val">{{ item.rules_count || item.rules?.length || 4 }} Rules</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State in Cards View -->
      <div v-if="filteredPolicies.length === 0" class="cards-empty-state">
        <AlertCircle :size="32" class="empty-icon" />
        <p class="empty-title">No Leave Policies Found</p>
        <p class="empty-desc">Create your first organizational leave policy rulebook to configure statutory accrual formulas.</p>
        <AppButton variant="primary" size="sm" @click="goToCreate">
          <template #icon-left><Plus :size="15" /></template>
          Create Leave Policy
        </AppButton>
      </div>
    </div>

    <!-- ─── VIEW 2: DENSE DIRECTORY TABLE VIEW ─── -->
    <div v-else class="table-view-wrapper">
      <AppDataTable
        title="Leave Policies Directory"
        subtitle="Tabular rulebook register with column customization, batch selection, and inline actions."
        :columns="tableColumns"
        :data="filteredPolicies"
        v-model:searchQuery="searchQuery"
        searchPlaceholder="Search policies by name, code, entity, or calendar..."
        @toggleColumn="handleToggleColumn"
      >
        <template #default>
          <div class="table-responsive">
            <table class="erp-table">
              <thead>
                <tr>
                  <th class="th-checkbox" width="40">
                    <input
                      type="checkbox"
                      :checked="isAllSelected"
                      @change="toggleSelectAll"
                      class="table-checkbox"
                      aria-label="Select all policies"
                    />
                  </th>
                  <th 
                    v-for="col in tableColumns.filter(c => c.visible !== false)" 
                    :key="col.key"
                    :style="{ width: col.width, textAlign: col.align || 'left' }"
                  >
                    {{ col.label }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="item in filteredPolicies" 
                  :key="item.id"
                  class="erp-row clickable-row"
                  @click="goToDetail(item.id)"
                >
                  <!-- Checkbox -->
                  <td class="td-checkbox" @click.stop>
                    <input
                      type="checkbox"
                      :checked="selectedIds.includes(item.id)"
                      @change="toggleSelectRow(item.id)"
                      class="table-checkbox"
                      aria-label="Select policy row"
                    />
                  </td>

                  <!-- Name & Code -->
                  <td v-if="tableColumns.find(c => c.key === 'name')?.visible !== false">
                    <div class="name-column-wrap">
                      <span class="table-name-primary">{{ item.name }}</span>
                      <span class="table-code-subtext">{{ item.code }}</span>
                    </div>
                  </td>

                  <!-- Owning Entity / Branch -->
                  <td v-if="tableColumns.find(c => c.key === 'entity_name')?.visible !== false">
                    <span class="table-text-tertiary">{{ item.entity_name }}</span>
                  </td>

                  <!-- Work Calendar -->
                  <td v-if="tableColumns.find(c => c.key === 'work_calendar_name')?.visible !== false">
                    <div class="calendar-cell-wrap">
                      <span class="table-text-tertiary">{{ item.work_calendar_name }}</span>
                      <span class="calendar-hours-subtext">{{ item.calendar_weekly_hours }} hrs/wk</span>
                    </div>
                  </td>

                  <!-- Effective Period -->
                  <td v-if="tableColumns.find(c => c.key === 'effective_period')?.visible !== false">
                    <span class="table-text-tertiary">
                      {{ item.effective_from }} ➔ {{ item.effective_to || 'Current' }}
                    </span>
                  </td>

                  <!-- Rules Count -->
                  <td v-if="tableColumns.find(c => c.key === 'rules_count')?.visible !== false">
                    <span class="table-text-tertiary font-medium">{{ item.rules_count }} Rules</span>
                  </td>

                  <!-- State (Standard BaseBadge) -->
                  <td v-if="tableColumns.find(c => c.key === 'state')?.visible !== false">
                    <BaseBadge :color="item.state === 'active' ? 'success' : 'gray'">
                      {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                    </BaseBadge>
                  </td>

                  <!-- Actions Menu (3-dot kebab MoreVertical) -->
                  <td 
                    v-if="tableColumns.find(c => c.key === 'actions')?.visible !== false" 
                    class="td-actions"
                    @click.stop
                  >
                    <div class="action-menu-relative">
                      <button 
                        type="button"
                        class="btn-action-dots" 
                        @click="activeActionMenuId = activeActionMenuId === item.id ? null : item.id"
                        title="Actions"
                      >
                        <MoreVertical :size="15" />
                      </button>

                      <div v-if="activeActionMenuId === item.id" class="dropdown-action-menu">
                        <button class="dropdown-item" @click="goToDetail(item.id)">
                          <Eye :size="14" />
                          <span>View Policy Blueprint</span>
                        </button>
                        <button class="dropdown-item" @click="handleToggleState(item)">
                          <ShieldCheck :size="14" />
                          <span>Mark as {{ item.state === 'active' ? 'Inactive' : 'Active' }}</span>
                        </button>
                        <div class="dropdown-divider"></div>
                        <button class="dropdown-item text-danger" @click="handleDeletePolicy(item.id)">
                          <Trash2 :size="14" />
                          <span>Delete Policy</span>
                        </button>
                      </div>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </template>
      </AppDataTable>
    </div>

    <!-- Table Floating Action Bar for Batch Selection -->
    <TableFloatingBar
      :selected-count="selectedIds.length"
      @clear="selectedIds = []"
    >
      <button class="btn-floating-action btn-danger" @click="handleBatchDelete">
        <Trash2 :size="14" />
        <span>Delete Selected ({{ selectedIds.length }})</span>
      </button>
    </TableFloatingBar>
  </div>
</template>

<style scoped>
.leave-policies-page {
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

/* ─── TOP HEADER CARD (Figma Node 7009:113278) ─── */
.policies-top-card {
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.header-main-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 20px;
}

.header-text-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.page-title {
  font-size: 20px;
  font-weight: 600;
  color: #404040; /* Secondary is darkest standard color */
  line-height: 30px;
  margin: 0;
}

.page-subtitle {
  font-size: 14px;
  font-weight: 400;
  color: #737373; /* Tertiary */
  line-height: 20px;
  margin: 0;
}

.header-tabs-row {
  display: flex;
  align-items: center;
}

/* ─── CARDS VIEW WRAPPER & GRID (Figma Node 7009:113269) ─── */
.cards-view-wrapper {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.policy-cards-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 24px;
}

@media (max-width: 960px) {
  .policy-cards-grid {
    grid-template-columns: 1fr;
  }
}

/* Minimalist Policy Card (Figma Node 7009:113288) */
.minimal-policy-card {
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.minimal-policy-card:hover {
  border-color: #d4d4d4;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.04);
}

.card-header-line {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding-bottom: 8px;
  border-bottom: 0.5px solid #e5e5e5;
}

.card-identity-block {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.card-policy-name {
  font-size: 16px;
  font-weight: 600;
  color: #404040; /* Secondary */
  line-height: 24px;
  margin: 0;
}

.card-policy-code {
  font-size: 14px;
  font-weight: 400;
  color: #737373; /* Tertiary */
  line-height: 20px;
}

/* 2x2 Key-Value Metadata Grid (Figma Node 7009:113299) */
.card-meta-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.meta-col {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.meta-label {
  font-size: 14px;
  font-weight: 400;
  color: #737373; /* Tertiary */
  line-height: 20px;
}

.meta-val {
  font-size: 16px;
  font-weight: 500;
  color: #737373; /* Tertiary (Figma Node 7009:113299) */
  line-height: 24px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Cards Empty State */
.cards-empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  background-color: #ffffff;
  border: 1px dashed #e5e5e5;
  border-radius: 16px;
  text-align: center;
}

.empty-icon {
  color: #a3a3a3;
  margin-bottom: 12px;
}

.empty-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 6px 0;
}

.empty-desc {
  font-size: 14px;
  color: #737373;
  max-width: 440px;
  margin: 0 0 20px 0;
  line-height: 1.5;
}

/* ─── TABLE VIEW STYLING ─── */
.table-view-wrapper {
  display: flex;
  flex-direction: column;
}

.table-responsive {
  width: 100%;
  overflow-x: auto;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  text-align: left;
}

.erp-table thead th {
  padding: 12px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  border-bottom: 1px solid #e5e5e5;
  background-color: #fafafa;
  white-space: nowrap;
}

.th-checkbox,
.td-checkbox {
  width: 40px;
  padding: 12px 0 12px 16px;
  text-align: center;
}

.table-checkbox {
  cursor: pointer;
  width: 16px;
  height: 16px;
  accent-color: #0B529C;
}

.erp-row {
  border-bottom: 1px solid #f0f0f0;
  transition: background-color 0.15s ease;
}

.erp-row:hover {
  background-color: #fafafa;
}

.clickable-row {
  cursor: pointer;
}

.erp-table tbody td {
  padding: 12px 16px;
  vertical-align: middle;
}

.name-column-wrap {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.table-code-subtext {
  font-size: 12px;
  color: #737373;
}

.table-text-tertiary {
  color: #737373;
  font-size: 13px;
}

.calendar-cell-wrap {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.calendar-hours-subtext {
  font-size: 11px;
  color: #a3a3a3;
}

/* 3-Dot Action Menu */
.td-actions {
  width: 48px;
  text-align: center;
  position: relative;
}

.action-menu-relative {
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
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f0f0f0;
  color: #404040;
}

.dropdown-action-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  padding: 4px;
  min-width: 170px;
  z-index: 50;
  display: flex;
  flex-direction: column;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  font-size: 13px;
  color: #404040;
  background: none;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.15s ease;
  width: 100%;
}

.dropdown-item:hover {
  background-color: #f5f5f5;
}

.dropdown-item.text-danger {
  color: #e7000b;
}

.dropdown-item.text-danger:hover {
  background-color: #fef2f2;
}

.dropdown-divider {
  height: 1px;
  background-color: #e5e5e5;
  margin: 4px 0;
}

/* Floating bar action button */
.btn-floating-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  border: 1px solid transparent;
  cursor: pointer;
  background: #ffffff;
  color: #404040;
}

.btn-floating-action.btn-danger {
  color: #e7000b;
  border-color: #fca5a5;
  background-color: #fef2f2;
}

.btn-floating-action.btn-danger:hover {
  background-color: #fee2e2;
}
</style>
