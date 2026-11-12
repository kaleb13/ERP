<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, MoreVertical, Eye, CheckCircle2,
  Trash2, ShieldCheck, AlertCircle, Calendar,
  LayoutGrid, List, ArrowRight
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import { 
  leavePoliciesData, 
  type LeavePolicyRecord 
} from './leavePolicyData';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'Leave Policies' }
];

const policies = leavePoliciesData;
const searchQuery = ref('');
const filterState = ref('All');
const activeActionMenuId = ref<number | null>(null);
const toastMessage = ref<string | null>(null);

// Primary View Mode: Clean Minimal Cards (per user request)
type ViewMode = 'cards' | 'table';
const viewMode = ref<ViewMode>('cards');

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Table Columns (AGENTS.md Rule 9) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Policy Name & Code', visible: true, sortable: true },
  { key: 'entity_name', label: 'Owning Entity / Branch', visible: true, sortable: true },
  { key: 'work_calendar_name', label: 'Work Calendar', visible: true, sortable: true },
  { key: 'effective_period', label: 'Effective Period', visible: true, sortable: true },
  { key: 'rules_count', label: 'Entitlement Rules', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: '', width: '48px', align: 'center', visible: true }
]);

const handleToggleColumn = (colKey: string | { key: string; visible: boolean }) => {
  const k = typeof colKey === 'string' ? colKey : colKey.key;
  const col = tableColumns.value.find(c => c.key === k);
  if (col) col.visible = typeof colKey === 'string' ? !col.visible : colKey.visible;
};

const isColVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

// ─── Filtering ───
const stateFilterOptions: SelectOption[] = [
  { value: 'All', label: 'All States' },
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' }
];

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

// ─── Selection for Batch Operations (AGENTS.md Rule 11) ───
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
    <!-- Breadcrumb Bar (AGENTS.md Rule 3: Exact Sidebar Page Name Only) -->
    <div class="breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Toast Notification -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- Table Card Container (AGENTS.md Rule 10: Unified Table Card Layout) -->
    <AppDataTable
      title="Leave Policies"
      subtitle="Master rulebooks binding organizational entities to work calendars, statutory accrual formulas, and carry-forward ceilings."
      :columns="tableColumns"
      :data="filteredPolicies"
      v-model:searchQuery="searchQuery"
      searchPlaceholder="Search policies by name, code, entity, or calendar..."
      @toggleColumn="handleToggleColumn"
    >
      <!-- Top Action Slot: Create Button -->
      <template #actions>
        <AppButton variant="primary" size="sm" @click="goToCreate">
  <template #icon-left><Plus :size="15" /></template>
  Create Leave Policy
</AppButton>
      </template>

      <!-- Filters Slot with State Filter & View Mode Switcher -->
      <template #filters>
        <div class="filter-controls-cluster">
          <div class="filter-dropdown-wrap">
            <FormSelect
              v-model="filterState"
              :options="stateFilterOptions"
              placeholder="Select"
              class="filter-select"
            />
          </div>

          <!-- View Mode Toggle: Cards (Default) vs Table -->
          <div class="view-mode-toggle">
            <button
              type="button"
              class="view-toggle-btn"
              :class="{ 'active': viewMode === 'cards' }"
              @click="viewMode = 'cards'"
              title="Clean Minimal Cards View"
            >
              <LayoutGrid :size="14" />
              <span>Cards</span>
            </button>
            <button
              type="button"
              class="view-toggle-btn"
              :class="{ 'active': viewMode === 'table' }"
              @click="viewMode = 'table'"
              title="Dense Table View"
            >
              <List :size="14" />
              <span>Table</span>
            </button>
          </div>
        </div>
      </template>

      <!-- Content Slot -->
      <template #default>
        <!-- VIEW 1: CLEAN MINIMAL BLUEPRINT CARDS (Default) -->
        <div v-if="viewMode === 'cards'" class="policy-cards-grid">
          <div 
            v-for="item in filteredPolicies" 
            :key="item.id"
            class="clean-policy-card"
            :class="{ 'card-selected': selectedIds.includes(item.id) }"
            @click="goToDetail(item.id)"
          >
            <!-- Card Header: Checkbox + Title/Code (Schema: name, code) + State (Schema: state) + Actions -->
            <div class="card-header-row">
              <div class="card-identity-cluster">
                <!-- Row Selection Checkbox -->
                <div class="card-checkbox-wrap" @click.stop>
                  <input
                    type="checkbox"
                    :checked="selectedIds.includes(item.id)"
                    @change="toggleSelectRow(item.id)"
                    class="table-checkbox"
                    title="Select policy"
                  />
                </div>

                <!-- Title & Code (Schema: name, code) -->
                <div class="card-title-block">
                  <h3 class="card-policy-name">{{ item.name }}</h3>
                  <span class="card-policy-code">{{ item.code }}</span>
                </div>
              </div>

              <!-- State Badge (Schema: state = active | inactive) & Action Menu -->
              <div class="card-header-actions" @click.stop>
                <span 
                  class="status-pill"
                  :class="item.state === 'active' ? 'state-active' : 'state-inactive'"
                >
                  {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                </span>

                <div class="action-menu-relative">
                  <button 
                    type="button"
                    class="btn-card-dots" 
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
              </div>
            </div>

            <!-- Optional Description (Schema: description) -->
            <p v-if="item.description" class="card-policy-desc">{{ item.description }}</p>

            <!-- Card Scope & Calendar Metadata Grid (Schema: entity_id, work_calendar_id, effective_from, effective_to) -->
            <div class="card-meta-grid">
              <div class="meta-item">
                <span class="meta-label">Owning Entity</span>
                <span class="meta-val">{{ item.entity_name }}</span>
              </div>
              <div class="meta-item">
                <span class="meta-label">Work Calendar</span>
                <span class="meta-val">{{ item.work_calendar_name }} ({{ item.calendar_weekly_hours }}h)</span>
              </div>
              <div class="meta-item">
                <span class="meta-label">Effective Period</span>
                <span class="meta-val">{{ item.effective_from }} ➔ {{ item.effective_to || 'Current' }}</span>
              </div>
            </div>

            <!-- Child Relation: LeavePolicyRule Entitlement Summary -->
            <div class="card-rules-block" v-if="item.rules && item.rules.length > 0">
              <div class="rules-header-line">
                <span class="rules-caption">Entitlement Rules</span>
                <span class="rules-count-badge">{{ item.rules.length }} Rules</span>
              </div>
              <div class="rules-pills-row">
                <div 
                  v-for="rule in item.rules" 
                  :key="rule.id" 
                  class="rule-pill-item"
                >
                  <span class="pill-type-name">{{ rule.leave_type_name }}</span>
                  <span class="pill-days-val">{{ rule.days_per_year }}d{{ rule.extra_days_per_service_year > 0 ? ` (+${rule.extra_days_per_service_year}/yr)` : '' }}</span>
                </div>
              </div>
            </div>

            <!-- Card Footer -->
            <div class="card-footer-row">
              <span class="footer-note">Applies to subtree unless overridden</span>
              <span class="card-view-link">
                <span>View Details</span>
                <ArrowRight :size="13" />
              </span>
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

        <!-- VIEW 2: DENSE TABULAR VIEW -->
        <div v-else class="table-responsive">
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

                <!-- Name & Code (Rule 4: Name on top, Code as subtext) -->
                <td v-if="tableColumns.find(c => c.key === 'name')?.visible !== false">
                  <div class="name-column-wrap">
                    <span class="table-name-primary">{{ item.name }}</span>
                    <span class="table-code-subtext">{{ item.code }}</span>
                  </div>
                </td>

                <!-- Owning Entity / Branch (Rule 5: Tertiary color #737373) -->
                <td v-if="tableColumns.find(c => c.key === 'entity_name')?.visible !== false">
                  <span class="table-text-tertiary">{{ item.entity_name }}</span>
                </td>

                <!-- Work Calendar (Rule 5: Tertiary color #737373) -->
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

                <!-- Rules Count (Rule 6: Plain text default, no decorative pills) -->
                <td v-if="tableColumns.find(c => c.key === 'rules_count')?.visible !== false">
                  <span class="table-text-tertiary font-medium">{{ item.rules_count }} Rules</span>
                </td>

                <!-- State (Rule 9: Active/Inactive solely on State column) -->
                <td v-if="tableColumns.find(c => c.key === 'state')?.visible !== false">
                  <span 
                    class="status-pill"
                    :class="item.state === 'active' ? 'state-active' : 'state-inactive'"
                  >
                    {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                  </span>
                </td>

                <!-- Actions Menu -->
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

              <!-- Empty Table State -->
              <tr v-if="filteredPolicies.length === 0">
                <td colspan="8" class="empty-table-cell">
                  <div class="empty-table-state">
                    <AlertCircle :size="28" class="empty-icon" />
                    <p class="empty-title">No Leave Policies Found</p>
                    <p class="empty-desc">Create your first organizational leave policy rulebook to configure statutory accrual formulas.</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
    </AppDataTable>

    <!-- Floating Batch Action Bar (AGENTS.md Rule 11) -->
    <TableFloatingBar 
      :show="selectedIds.length > 0"
      :selected-count="selectedIds.length"
      :total-count="filteredPolicies.length"
      @delete="handleBatchDelete" 
      @close="selectedIds = []" 
    />
  </div>
</template>

<style scoped>
.leave-policies-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
}

.breadcrumb-bar {
  display: flex;
  align-items: center;
}

/* Toast */
.toast-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #ecfdf5;
  color: #065f46;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 10px 14px;
  font-size: 13px;
  font-weight: 500;
  width: fit-content;
}

.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: all 0.25s ease;
}
.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translateY(-6px);
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

.filter-controls-cluster {
  display: flex;
  align-items: center;
  gap: 12px;
}

.filter-dropdown-wrap {
  width: 150px;
}

/* View Mode Toggle Button Group */
.view-mode-toggle {
  display: inline-flex;
  align-items: center;
  background-color: #f1f5f9;
  border-radius: 8px;
  padding: 2px;
  gap: 2px;
}

.view-toggle-btn {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 32px;
  padding: 0 12px;
  border: none;
  background: transparent;
  color: #64748b;
  font-size: 12.5px;
  font-weight: 500;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.view-toggle-btn:hover {
  color: #0f172a;
}
.view-toggle-btn.active {
  background-color: #ffffff;
  color: #0B529C;
  font-weight: 600;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

/* ═════════════════════════════════════════════════════════════════════ */
/* VIEW 1: CLEAN & MINIMAL BLUEPRINT CARDS                               */
/* ═════════════════════════════════════════════════════════════════════ */
.policy-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
  gap: 16px;
  padding: 6px 0;
}

.clean-policy-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 18px 20px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  cursor: pointer;
  transition: all 0.18s ease;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}
.clean-policy-card:hover {
  border-color: #cbd5e1;
  box-shadow: 0 8px 22px -4px rgba(11, 82, 156, 0.08);
  transform: translateY(-2px);
}
.clean-policy-card.card-selected {
  border-color: #0B529C;
  background-color: #f8fafc;
  box-shadow: 0 0 0 1px #0B529C;
}

/* Card Header */
.card-header-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 12px;
}

.card-identity-cluster {
  display: flex;
  align-items: center;
  gap: 12px;
}

.card-checkbox-wrap {
  display: flex;
  align-items: center;
}

.card-title-block {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.card-policy-name {
  font-size: 15.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
  line-height: 1.3;
}

.card-policy-code {
  font-size: 11.5px;
  color: #737373;
  font-family: monospace;
}

.card-policy-desc {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
  line-height: 1.4;
}

.card-header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-card-dots {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  border-radius: 6px;
  color: #94a3b8;
  cursor: pointer;
  transition: all 0.12s ease;
}
.btn-card-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

/* Card Scope & Calendar Metadata Grid (Clean 3-item grid) */
.card-meta-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
  padding: 10px 14px;
  background-color: #f8fafc;
  border-radius: 8px;
  border: 1px solid #f1f5f9;
}
@media (max-width: 640px) {
  .card-meta-grid {
    grid-template-columns: 1fr;
  }
}

.meta-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
  overflow: hidden;
}

.meta-label {
  font-size: 11px;
  color: #737373;
  font-weight: 500;
}

.meta-val {
  font-size: 12.5px;
  color: #404040;
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Entitlement Rule Pills */
.card-rules-block {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.rules-header-line {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.rules-caption {
  font-size: 11.5px;
  font-weight: 600;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.rules-count-badge {
  font-size: 11px;
  font-weight: 500;
  color: #0B529C;
  background-color: #e0f2fe;
  padding: 1px 6px;
  border-radius: 4px;
}

.rules-pills-row {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.rule-pill-item {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 3px 8px;
  font-size: 11.5px;
}

.pill-type-name {
  color: #404040;
  font-weight: 500;
}

.pill-days-val {
  color: #0B529C;
  font-weight: 600;
}

/* Card Footer */
.card-footer-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: 10px;
  border-top: 1px solid #f1f5f9;
}

.footer-note {
  font-size: 11.5px;
  color: #94a3b8;
}

.card-view-link {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 600;
  color: #0B529C;
  transition: gap 0.15s ease;
}
.clean-policy-card:hover .card-view-link {
  gap: 7px;
}

.cards-empty-state {
  grid-column: 1 / -1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 48px 24px;
  background-color: #ffffff;
  border: 1px dashed #cbd5e1;
  border-radius: 12px;
  text-align: center;
}
.empty-btn {
  margin-top: 12px;
}

/* ═════════════════════════════════════════════════════════════════════ */
/* VIEW 2: DENSE TABLE VIEW                                              */
/* ═════════════════════════════════════════════════════════════════════ */
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
  height: 36px;
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
  background-color: #f8fafc;
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

/* Name Column Hierarchy (AGENTS.md Rule 4 & 5) */
.name-column-wrap {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.table-name-primary {
  font-weight: 500;
  color: #404040;
}
.table-code-subtext {
  font-size: 11.5px;
  color: #737373;
  font-family: monospace;
}

.calendar-cell-wrap {
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.calendar-hours-subtext {
  font-size: 11.5px;
  color: #94a3b8;
}

.table-text-tertiary {
  color: #737373;
}

/* Status Pill (Rule 9: Active/Inactive solely on State column) */
.status-pill {
  font-size: 11.5px;
  font-weight: 500;
  padding: 2px 10px;
  border-radius: 9999px;
  display: inline-block;
  white-space: nowrap;
}
.state-active {
  background-color: #ecfdf5;
  color: #059669;
}
.state-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

/* Actions Menu */
.td-actions {
  text-align: center;
  width: 48px;
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
  transition: all 0.12s ease;
}
.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.dropdown-action-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  width: 190px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
  padding: 4px;
  z-index: 50;
  display: flex;
  flex-direction: column;
  animation: dropdownIn 0.12s ease-out;
}
@keyframes dropdownIn {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 10px;
  font-size: 12.5px;
  color: #404040;
  border: none;
  background: transparent;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.12s ease;
}
.dropdown-item:hover {
  background-color: #f8fafc;
}
.dropdown-item.text-danger {
  color: #ef4444;
}
.dropdown-item.text-danger:hover {
  background-color: #fef2f2;
}
.dropdown-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 4px 0;
}

/* Empty Table State */
.empty-table-cell {
  padding: 48px 24px !important;
  text-align: center;
}
.empty-table-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.empty-icon {
  color: #94a3b8;
  margin-bottom: 8px;
}
.empty-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px;
}
.empty-desc {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
  max-width: 380px;
}
</style>
