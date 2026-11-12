<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, Search, MoreVertical, Eye,
  Edit, Users, CheckCircle2
} from 'lucide-vue-next';;

import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import MetricCard from '../../components/MetricCard.vue';
import UnderlineTabs from '../../components/UnderlineTabs.vue';
import AppDataTable from '../../components/AppDataTable.vue';

import {
  clientAssignmentsData,
  updateAssignmentState,
  deleteClientAssignment,
  type ClientAssignmentRecord,
  type ClientAssignmentState
} from './clientAssignmentData';

const router = useRouter();

// ─── BREADCRUMB (Rule 3: Exact Sidebar Page Name Only) ────────────────────
const breadcrumbs = [
  { label: 'Client Assignments' }
];

// ─── SEARCH & FILTERING ───────────────────────────────────────────────────
const searchQuery = ref('');
const activeTab = ref('all');

// ─── KPI METRICS (Rule 2) ─────────────────────────────────────────────────
const totalPlacements = computed(() => clientAssignmentsData.value.length);
const activePlacements = computed(() =>
  clientAssignmentsData.value.filter(a => a.assignment_state_lookup_value_id === 'active').length
);
const internalLeasedCount = computed(() =>
  clientAssignmentsData.value.filter(a => a.is_tenant_client).length
);
const externalLeasedCount = computed(() =>
  clientAssignmentsData.value.filter(a => !a.is_tenant_client).length
);

// ─── SECONDARY UNDERLINE TABS (Rule 1) ────────────────────────────────────
const statusTabs = computed(() => [
  {
    id: 'all',
    label: 'All Placements',
    count: clientAssignmentsData.value.length
  },
  {
    id: 'active',
    label: 'Active Placements',
    count: clientAssignmentsData.value.filter(a => a.assignment_state_lookup_value_id === 'active').length
  },
  {
    id: 'completed',
    label: 'Completed',
    count: clientAssignmentsData.value.filter(a => a.assignment_state_lookup_value_id === 'completed').length
  },
  {
    id: 'recalled_terminated',
    label: 'Recalled / Terminated',
    count: clientAssignmentsData.value.filter(a => ['recalled', 'terminated'].includes(a.assignment_state_lookup_value_id)).length
  }
]);

// Filtered Records
const filteredAssignments = computed(() => {
  return clientAssignmentsData.value.filter(item => {
    // Tab filter
    if (activeTab.value === 'active' && item.assignment_state_lookup_value_id !== 'active') return false;
    if (activeTab.value === 'completed' && item.assignment_state_lookup_value_id !== 'completed') return false;
    if (activeTab.value === 'recalled_terminated' && !['recalled', 'terminated'].includes(item.assignment_state_lookup_value_id)) return false;

    // Search query filter
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase();
      const matchEmp = item.employee_name.toLowerCase().includes(q) || item.employee_code.toLowerCase().includes(q);
      const matchClient = item.client_party_name.toLowerCase().includes(q);
      const matchCode = item.code.toLowerCase().includes(q);
      const matchRole = (item.client_position_name || item.client_role_title || '').toLowerCase().includes(q);
      const matchAgreement = item.hr_service_agreement_code.toLowerCase().includes(q);
      if (!matchEmp && !matchClient && !matchCode && !matchRole && !matchAgreement) return false;
    }
    return true;
  });
});

// ─── SELECTION ───────────────────────────────────────────────────────────
const selectedIds = ref<number[]>([]);
const isAllSelected = computed(() => {
  return (
    filteredAssignments.value.length > 0 &&
    filteredAssignments.value.every(a => selectedIds.value.includes(a.id))
  );
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedIds.value = [];
  } else {
    selectedIds.value = filteredAssignments.value.map(a => a.id);
  }
};

const toggleSelectRow = (id: number) => {
  const idx = selectedIds.value.indexOf(id);
  if (idx !== -1) {
    selectedIds.value.splice(idx, 1);
  } else {
    selectedIds.value.push(id);
  }
};

import { type ColumnDef } from '../../components/BaseTable.vue';

// ─── TABLE COLUMNS (Non-scrollable: Important columns only) ───────────────
const tableColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Leased Worker & Code', visible: true },
  { key: 'client', label: 'Client & Agreement', visible: true },
  { key: 'role', label: 'Client Role / Seat', visible: true },
  { key: 'placement_period', label: 'Placement Period', visible: true },
  { key: 'status', label: 'Status', visible: true },
  { key: 'actions', label: 'Actions', visible: true },
  { key: 'client_branch', label: 'Client Branch', visible: false },
  { key: 'duty_station', label: 'Duty Station', visible: false },
  { key: 'state', label: 'State', visible: false }
]);

const handleToggleColumn = (colKey: string | { key: string; visible: boolean }) => {
  const k = typeof colKey === 'string' ? colKey : colKey.key;
  const col = tableColumns.value.find(c => c.key === k);
  if (col) col.visible = typeof colKey === 'string' ? !col.visible : colKey.visible;
};

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

// ─── UNIVERSAL DATE FORMATTER (Rule 22: MMM D, YYYY) ──────────────────────
const formatDate = (dateStr: string | null) => {
  if (!dateStr) return '—';
  try {
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${months[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
  } catch {
    return dateStr;
  }
};

// ─── NAVIGATION ───────────────────────────────────────────────────────────
const handleCreateAssignment = () => {
  router.push('/hr/client-assignments/create');
};

const navigateToEdit = (id: number) => {
  closeActionMenu();
  router.push({
    path: '/hr/client-assignments/create',
    query: { id: id.toString() }
  });
};

// ─── ACTION MENU POPUP ───────────────────────────────────────────────────
const openActionMenuId = ref<number | null>(null);

const toggleActionMenu = (id: number, event: MouseEvent) => {
  event.stopPropagation();
  openActionMenuId.value = openActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  openActionMenuId.value = null;
};

// ─── DETAIL INSPECTION MODAL ──────────────────────────────────────────────
const selectedAssignment = ref<ClientAssignmentRecord | null>(null);
const isDetailModalOpen = ref(false);

const openDetailModal = (item: ClientAssignmentRecord) => {
  selectedAssignment.value = item;
  isDetailModalOpen.value = true;
  closeActionMenu();
};

const closeDetailModal = () => {
  isDetailModalOpen.value = false;
  selectedAssignment.value = null;
};

const handleStateChange = (id: number, newState: ClientAssignmentState) => {
  updateAssignmentState(id, newState);
  closeActionMenu();
  if (selectedAssignment.value && selectedAssignment.value.id === id) {
    selectedAssignment.value.assignment_state_lookup_value_id = newState;
  }
};
</script>

<template>
  <div class="client-assignments-page" @click="closeActionMenu">
    <!-- Breadcrumb (Rule 3) -->
    <div class="page-breadcrumb">
      <AppBreadcrumb :items="breadcrumbs" />
    </div>

    <!-- 4 KPI Metrics Cards (Rule 2) -->
    <div class="metrics-grid">
      <MetricCard
        label="TOTAL PLACEMENTS"
        :value="totalPlacements"
        subtext="Staff deployed under service agreements"
      />
      <MetricCard
        label="ACTIVE PLACEMENTS"
        :value="activePlacements"
        subtext="Currently operational field assignments"
      />
      <MetricCard
        label="INTERNAL SISTER TENANTS"
        :value="internalLeasedCount"
        subtext="Placed in client branches & org seats"
      />
      <MetricCard
        label="EXTERNAL COMMERCIAL CLIENTS"
        :value="externalLeasedCount"
        subtext="Placed at external corporate duty stations"
      />
    </div>

    <!-- Secondary UnderlineTabs (Rule 1) -->
    <div class="tabs-container">
      <UnderlineTabs
        v-model="activeTab"
        :tabs="statusTabs"
      />
    </div>

    <!-- Unified Table Card (Rule 10) -->
    <div class="table-card-wrapper">
      <AppDataTable
        title="Client Assignments"
        subtitle="Manage leased staff deployments, client organizational seats, duty stations, and payslip cost allocation splits."
        :totalEntries="filteredAssignments.length"
        v-model:searchQuery="searchQuery"
        :columns="tableColumns"
        @toggleColumn="handleToggleColumn"
      >
        <!-- Table Toolbar Actions Slot -->
        <template #actions>
          <AppButton variant="primary" size="sm" @click="handleCreateAssignment">
  <template #icon-left><Plus :size="15" /></template>
  Assign Leased Staff
</AppButton>
        </template>

        <!-- Data Table (Rules 8, 9: Non-scrollable, important columns only) -->
        <template #default>
          <table class="erp-table">
            <thead>
              <tr>
                <th class="th-checkbox">
                  <input
                    type="checkbox"
                    :checked="isAllSelected"
                    class="table-checkbox"
                    @change="toggleSelectAll"
                  />
                </th>
                <th v-if="isColumnVisible('employee')">Leased Worker & Code</th>
                <th v-if="isColumnVisible('client')">Client & Agreement</th>
                <th v-if="isColumnVisible('role')">Client Role / Seat</th>
                <th v-if="isColumnVisible('client_branch')">Client Branch</th>
                <th v-if="isColumnVisible('duty_station')">Duty Station</th>
                <th v-if="isColumnVisible('placement_period')">Placement Period</th>
                <th v-if="isColumnVisible('status')">Status</th>
                <th v-if="isColumnVisible('state')">State</th>
                <th v-if="isColumnVisible('actions')" class="th-actions"></th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="item in filteredAssignments"
                :key="item.id"
                class="erp-table-row"
                :class="{ 'row-selected': selectedIds.includes(item.id) }"
              >
                <!-- Selection Checkbox -->
                <td class="td-checkbox">
                  <input
                    type="checkbox"
                    :checked="selectedIds.includes(item.id)"
                    class="table-checkbox"
                    @change="toggleSelectRow(item.id)"
                  />
                </td>

                <!-- Leased Worker Name & Code (Rule 9: Name on top, Code underneath as subtext) -->
                <td v-if="isColumnVisible('employee')" class="td-employee">
                  <div class="employee-cell-wrap" @click="openDetailModal(item)">
                    <span class="table-name-primary">{{ item.employee_name }}</span>
                    <span class="table-code-subtext">{{ item.employee_code }} • {{ item.code }}</span>
                  </div>
                </td>

                <!-- Client & Agreement (Rule 9: Tertiary text, code subtext) -->
                <td v-if="isColumnVisible('client')" class="td-client">
                  <div class="client-cell-wrap">
                    <span class="tertiary-text font-medium">{{ item.client_party_name }}</span>
                    <span class="table-code-subtext">{{ item.hr_service_agreement_code }}</span>
                  </div>
                </td>

                <!-- Client Role / Seat (Position if tenant client, verbatim title if external) -->
                <td v-if="isColumnVisible('role')">
                  <span class="tertiary-text font-medium">
                    {{ item.is_tenant_client ? (item.client_position_name || 'Assigned Seat') : (item.client_role_title || '—') }}
                  </span>
                </td>

                <!-- Client Branch (Optional / Hidden by default) -->
                <td v-if="isColumnVisible('client_branch')">
                  <span class="tertiary-text">
                    {{ item.is_tenant_client ? (item.client_branch_name || '—') : 'External Counterparty' }}
                  </span>
                </td>

                <!-- Duty Station (Optional / Hidden by default) -->
                <td v-if="isColumnVisible('duty_station')">
                  <span class="tertiary-text">{{ item.duty_station_name || '—' }}</span>
                </td>

                <!-- Placement Period (Rule 22: MMM D, YYYY) -->
                <td v-if="isColumnVisible('placement_period')">
                  <span class="tertiary-text">
                    {{ formatDate(item.start_date) }} – {{ item.end_date ? formatDate(item.end_date) : 'Ongoing' }}
                  </span>
                </td>

                <!-- Status (Lifecycle state) -->
                <td v-if="isColumnVisible('status')">
                  <span
                    class="status-pill"
                    :class="`status-${item.assignment_state_lookup_value_id}`"
                  >
                    {{ item.assignment_state_lookup_value_id.replace(/\b\w/g, l => l.toUpperCase()) }}
                  </span>
                </td>

                <!-- State (Rule 9: Active / Inactive) -->
                <td v-if="isColumnVisible('state')">
                  <span
                    class="state-pill"
                    :class="`state-${item.state}`"
                  >
                    {{ item.state.charAt(0).toUpperCase() + item.state.slice(1) }}
                  </span>
                </td>

                <!-- Actions Menu -->
                <td v-if="isColumnVisible('actions')" class="td-actions">
                  <div class="action-dropdown-wrap">
                    <button
                      type="button"
                      class="btn-action-dots"
                      @click="toggleActionMenu(item.id, $event)"
                    >
                      <MoreVertical :size="15" />
                    </button>

                    <div
                      v-if="openActionMenuId === item.id"
                      class="action-menu-dropdown"
                      @click.stop
                    >
                      <button
                        type="button"
                        class="menu-item"
                        @click="openDetailModal(item)"
                      >
                        <Eye :size="13" />
                        <span>View Assignment Details</span>
                      </button>

                      <button
                        type="button"
                        class="menu-item"
                        @click="navigateToEdit(item.id)"
                      >
                        <Edit :size="13" />
                        <span>Edit Deployment</span>
                      </button>

                      <div class="menu-divider"></div>

                      <button
                        v-if="item.assignment_state_lookup_value_id === 'active'"
                        type="button"
                        class="menu-item menu-item-warning"
                        @click="handleStateChange(item.id, 'completed')"
                      >
                        <CheckCircle2 :size="13" />
                        <span>Mark as Completed</span>
                      </button>

                      <button
                        v-if="item.assignment_state_lookup_value_id === 'active'"
                        type="button"
                        class="menu-item menu-item-danger"
                        @click="handleStateChange(item.id, 'recalled')"
                      >
                        <Users :size="13" />
                        <span>Recall to Provider</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>

              <!-- Empty State -->
              <tr v-if="filteredAssignments.length === 0">
                <td colspan="10" class="td-empty">
                  <div class="empty-state-content">
                    <Users :size="28" class="empty-icon" />
                    <p class="empty-title">No client placements found</p>
                    <p class="empty-desc">No leased employee assignments match your active filter criteria.</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </template>
      </AppDataTable>
    </div>

    <!-- ─── INSPECTION MODAL ──────────────────────────────────────────────── -->
    <div
      v-if="isDetailModalOpen && selectedAssignment"
      class="detail-backdrop"
      @click.self="closeDetailModal"
    >
      <div class="detail-modal-card">
        <!-- Modal Header -->
        <div class="detail-modal-header">
          <div class="detail-header-info">
            <span class="detail-code-badge">{{ selectedAssignment.code }}</span>
            <h3 class="detail-title">{{ selectedAssignment.employee_name }}</h3>
            <span class="detail-sub">
              {{ selectedAssignment.is_tenant_client ? selectedAssignment.client_position_name : selectedAssignment.client_role_title }} 
              at {{ selectedAssignment.client_party_name }}
            </span>
          </div>

          <button type="button" class="btn-modal-close" @click="closeDetailModal">
            &times;
          </button>
        </div>

        <!-- Modal Body -->
        <div class="detail-modal-body">
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">CLIENT ORGANIZATION</span>
              <span class="info-value font-medium">{{ selectedAssignment.client_party_name }}</span>
            </div>

            <div class="info-item">
              <span class="info-label">GOVERNING AGREEMENT</span>
              <span class="info-value font-mono">{{ selectedAssignment.hr_service_agreement_code }}</span>
            </div>

            <div class="info-item">
              <span class="info-label">TENANCY ARCHITECTURE</span>
              <span class="info-value">
                {{ selectedAssignment.is_tenant_client ? 'Internal Haleta Tenant Structure' : 'External Commercial Client' }}
              </span>
            </div>

            <div v-if="selectedAssignment.is_tenant_client" class="info-item">
              <span class="info-label">CLIENT BRANCH & ORG UNIT</span>
              <span class="info-value">
                {{ selectedAssignment.client_branch_name }} • {{ selectedAssignment.client_organization_unit_name }}
              </span>
            </div>

            <div class="info-item">
              <span class="info-label">PHYSICAL DUTY STATION</span>
              <span class="info-value">{{ selectedAssignment.duty_station_name || 'Client Premises' }}</span>
            </div>

            <div class="info-item">
              <span class="info-label">PLACEMENT PERIOD</span>
              <span class="info-value">
                {{ formatDate(selectedAssignment.start_date) }} – {{ selectedAssignment.end_date ? formatDate(selectedAssignment.end_date) : 'Ongoing' }}
              </span>
            </div>
          </div>

          <!-- Notes -->
          <div v-if="selectedAssignment.notes" class="modal-section-block">
            <h4 class="section-block-title">Assignment Scope & Notes</h4>
            <p class="section-notes-text">{{ selectedAssignment.notes }}</p>
          </div>

          <!-- Payslip Cost Allocations Sub-table (HR Schema Designer 1.sql lines 2340-2362) -->
          <div class="modal-section-block">
            <div class="sub-table-header">
              <h4 class="section-block-title">Payslip Cost Allocations (Cost Split Lines)</h4>
              <span class="sub-table-count">{{ (selectedAssignment.cost_allocations || []).length }} Lines</span>
            </div>

            <table class="sub-table">
              <thead>
                <tr>
                  <th>Payslip #</th>
                  <th>Target Type</th>
                  <th>Target Destination</th>
                  <th>Split Share</th>
                  <th>Order</th>
                  <th>State</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="alloc in (selectedAssignment.cost_allocations || [])" :key="alloc.id">
                  <td class="font-mono text-xs">{{ alloc.payslip_number }}</td>
                  <td>
                    <span class="tertiary-text">
                      {{ alloc.target_entity_id ? 'Branch Entity' : alloc.organization_unit_id ? 'Organization Unit' : 'Client Assignment' }}
                    </span>
                  </td>
                  <td class="font-medium">
                    {{ alloc.target_entity_name || alloc.organization_unit_name || 'This Client Assignment (Direct)' }}
                  </td>
                  <td class="font-medium">
                    {{ alloc.percent ? `${alloc.percent}% of Gross` : `${alloc.amount?.toLocaleString()} ETB Fixed` }}
                  </td>
                  <td>{{ alloc.order }}</td>
                  <td>
                    <span class="pill-badge pill-settled">
                      {{ alloc.state }}
                    </span>
                  </td>
                </tr>
                <tr v-if="!selectedAssignment.cost_allocations || selectedAssignment.cost_allocations.length === 0">
                  <td colspan="6" class="td-sub-empty">
                    No explicit payslip cost allocation splits recorded (100% defaulted to client assignment).
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Modal Footer -->
        <div class="detail-modal-footer">
          <AppButton variant="outline" size="sm" @click="closeDetailModal">
            Close
          </AppButton>
          <AppButton
            variant="primary"
            size="sm"
            @click="navigateToEdit(selectedAssignment.id)"
          >
            Edit Deployment
          </AppButton>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.client-assignments-page {
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
}

/* Breadcrumb */
.page-breadcrumb {
  margin-bottom: 2px;
}

/* KPI Metrics Grid */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

@media (max-width: 1024px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Tabs */
.tabs-container {
  display: flex;
  border-bottom: 1px solid #e2e8f0;
}

/* Table Card */
.table-card-wrapper {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
  overflow: hidden;
}

/* Toolbar Buttons */
.btn-primary-add {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding: 0 14px;
  background-color: #0b529c;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-primary-add:hover {
  background-color: #083e77;
}

/* Search Box */
.table-search-box {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 34px;
  padding: 0 10px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  width: 320px;
}

.search-icon {
  color: #94a3b8;
}

.search-input {
  border: none;
  background: transparent;
  outline: none;
  font-size: 12.5px;
  color: #404040;
  width: 100%;
}

/* Table & Cells */
.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  height: 34px;
  padding: 8px 14px;
  background-color: #fafafa;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
  user-select: none;
}

.erp-table td {
  height: 44px;
  padding: 8px 14px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.erp-table-row:hover td {
  background-color: #f8fafc;
}

.row-selected td {
  background-color: #eff6ff !important;
}

.th-checkbox,
.td-checkbox {
  width: 40px;
  text-align: center;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  cursor: pointer;
  accent-color: #0b529c;
}

/* Employee Column */
.employee-cell-wrap {
  display: flex;
  flex-direction: column;
  gap: 2px;
  cursor: pointer;
}

.client-cell-wrap {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.table-name-primary:hover {
  color: #0b529c;
}

.table-code-subtext {
  font-size: 11.5px;
  font-family: monospace;
  color: #737373;
}

/* Tertiary text */
.tertiary-text {
  font-size: 12.5px;
  color: #737373;
}

/* Status & State Pills */
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
}

.status-active {
  background-color: #ecfdf5;
  color: #059669;
}

.status-completed {
  background-color: #f1f5f9;
  color: #64748b;
}

.status-recalled {
  background-color: #fffbeb;
  color: #d97706;
}

.status-terminated {
  background-color: #fef2f2;
  color: #dc2626;
}

.status-draft {
  background-color: #f1f5f9;
  color: #64748b;
}

.state-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 500;
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
.th-actions,
.td-actions {
  width: 48px;
  text-align: center;
}

.action-dropdown-wrap {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  border-radius: 6px;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.action-menu-dropdown {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  width: 200px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  padding: 4px;
  z-index: 50;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 7px 10px;
  border: none;
  background: transparent;
  border-radius: 6px;
  font-size: 12.5px;
  color: #404040;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.12s;
}

.menu-item:hover {
  background-color: #f1f5f9;
  color: #0b529c;
}

.menu-item-warning:hover {
  background-color: #fffbeb;
  color: #d97706;
}

.menu-item-danger:hover {
  background-color: #fef2f2;
  color: #dc2626;
}

.menu-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 3px 0;
}

/* Empty State */
.td-empty {
  padding: 48px 0 !important;
  text-align: center;
}

.empty-state-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.empty-icon {
  color: #94a3b8;
}

.empty-title {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
  margin: 0;
}

.empty-desc {
  font-size: 12px;
  color: #737373;
  margin: 0;
}

/* ─── MODAL STYLES ──────────────────────────────────────────────────────── */
.detail-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.detail-modal-card {
  background-color: #ffffff;
  border-radius: 12px;
  width: 100%;
  max-width: 680px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.detail-modal-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid #f1f5f9;
}

.detail-header-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.detail-code-badge {
  display: inline-block;
  font-family: monospace;
  font-size: 11.5px;
  color: #0b529c;
  background-color: #eff6ff;
  padding: 2px 8px;
  border-radius: 4px;
  width: fit-content;
}

.detail-title {
  font-size: 17px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.detail-sub {
  font-size: 13px;
  color: #737373;
}

.btn-modal-close {
  background: none;
  border: none;
  font-size: 24px;
  color: #94a3b8;
  cursor: pointer;
  line-height: 1;
}

.btn-modal-close:hover {
  color: #404040;
}

.detail-modal-body {
  padding: 20px 24px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-label {
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
}

.info-value {
  font-size: 13.5px;
  color: #404040;
}

.modal-section-block {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.section-block-title {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.section-notes-text {
  font-size: 13px;
  color: #737373;
  line-height: 1.5;
  background-color: #f8fafc;
  padding: 10px 14px;
  border-radius: 6px;
  margin: 0;
}

/* Sub-table */
.sub-table-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.sub-table-count {
  font-size: 12px;
  color: #737373;
}

.sub-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.sub-table th {
  padding: 6px 10px;
  background-color: #f8fafc;
  color: #737373;
  font-weight: 500;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

.sub-table td {
  padding: 6px 10px;
  border-bottom: 1px solid #f1f5f9;
  color: #404040;
}

.td-sub-empty {
  text-align: center;
  color: #94a3b8;
  padding: 16px 0 !important;
}

.pill-badge {
  padding: 2px 8px;
  border-radius: 9999px;
  font-size: 11px;
  text-transform: capitalize;
}

.pill-settled {
  background-color: #ecfdf5;
  color: #059669;
}

/* Modal Footer */
.detail-modal-footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 24px;
  background-color: #f8fafc;
  border-top: 1px solid #f1f5f9;
}

.btn-modal-secondary {
  height: 34px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  cursor: pointer;
}

.btn-modal-secondary:hover {
  background-color: #f1f5f9;
}

.btn-modal-primary {
  height: 34px;
  padding: 0 16px;
  background-color: #0b529c;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
}

.btn-modal-primary:hover {
  background-color: #083e77;
}
</style>
