<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus,
  Search,
  Filter,
  ArrowUpDown,
  Columns,
  Maximize2,
  MoreVertical,
  CheckCircle2,
  FileText,
  Users,
  Building2,
  Briefcase,
  X,
  Eye,
  Check,
  Send,
  LifeBuoy,
  UserCheck,
  ExternalLink,
  Clock,
  AlertCircle
} from 'lucide-vue-next';

import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import MetricCard from '../../components/MetricCard.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';

import {
  serviceRequestsData,
  createServiceRequest,
  updateServiceRequest,
  assignServiceRequest,
  resolveServiceRequest,
  updateServiceRequestState,
  deleteServiceRequest,
  type HRServiceRequestRecord,
  type HRServiceRequestCategory,
  type HRServiceRequestState
} from './hrServiceRequestData';

const router = useRouter();

// ─── BREADCRUMBS (Rule 3: Exact Sidebar Page Name Only) ───────────────────
const breadcrumbs = [
  { label: 'HR Service Requests' }
];

// ─── KPI METRICS (Rule 2) ─────────────────────────────────────────────────
const totalRequests = computed(() => serviceRequestsData.value.length);
const openRequests = computed(() =>
  serviceRequestsData.value.filter(r => r.request_state_lookup_value_id === 'open').length
);
const inProgressRequests = computed(() =>
  serviceRequestsData.value.filter(r => ['assigned', 'in_progress'].includes(r.request_state_lookup_value_id)).length
);
const resolvedClosedRequests = computed(() =>
  serviceRequestsData.value.filter(r => ['resolved', 'closed'].includes(r.request_state_lookup_value_id)).length
);

// ─── SECONDARY TABS (Rule 1: UnderlineTabs for Sub-views) ─────────────────
type TabId = 'all' | 'open' | 'in_progress' | 'resolved' | 'closed';
const activeTab = ref<TabId>('all');

const statusTabs = computed<UnderlineTabItem<TabId>[]>(() => [
  { id: 'all', label: 'All Requests', count: serviceRequestsData.value.length },
  { id: 'open', label: 'Open', count: openRequests.value, badgeVariant: 'primary' },
  { id: 'in_progress', label: 'In Progress', count: inProgressRequests.value, badgeVariant: 'warning' },
  { id: 'resolved', label: 'Resolved', count: serviceRequestsData.value.filter(r => r.request_state_lookup_value_id === 'resolved').length, badgeVariant: 'success' },
  { id: 'closed', label: 'Closed', count: serviceRequestsData.value.filter(r => r.request_state_lookup_value_id === 'closed').length }
]);

// ─── SEARCH & FILTERING ──────────────────────────────────────────────────
const searchQuery = ref('');

const filteredRequests = computed(() => {
  return serviceRequestsData.value.filter(r => {
    // Tab filtering
    if (activeTab.value === 'open' && r.request_state_lookup_value_id !== 'open') return false;
    if (activeTab.value === 'in_progress' && !['assigned', 'in_progress'].includes(r.request_state_lookup_value_id)) return false;
    if (activeTab.value === 'resolved' && r.request_state_lookup_value_id !== 'resolved') return false;
    if (activeTab.value === 'closed' && r.request_state_lookup_value_id !== 'closed') return false;

    // Search query filtering
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase();
      const matchSubject = r.subject.toLowerCase().includes(q);
      const matchCode = r.code.toLowerCase().includes(q);
      const matchEmp = r.employee_name.toLowerCase().includes(q);
      const matchEmpCode = r.employee_code.toLowerCase().includes(q);
      const matchHandler = (r.assigned_to_name || '').toLowerCase().includes(q);
      if (!matchSubject && !matchCode && !matchEmp && !matchEmpCode && !matchHandler) return false;
    }
    return true;
  });
});

// ─── SELECTION ───────────────────────────────────────────────────────────
const selectedIds = ref<number[]>([]);
const isAllSelected = computed(() => {
  return (
    filteredRequests.value.length > 0 &&
    filteredRequests.value.every(r => selectedIds.value.includes(r.id))
  );
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedIds.value = [];
  } else {
    selectedIds.value = filteredRequests.value.map(r => r.id);
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

// ─── TABLE COLUMNS (Rule 9: Atomic columns, Name/Subject first, Code subtext)
interface TableCol {
  id: string;
  name: string;
  visible: boolean;
}

const tableColumns = ref<TableCol[]>([
  { id: 'subject', name: 'Subject & Ticket', visible: true },
  { id: 'employee', name: 'Requester Employee', visible: true },
  { id: 'category', name: 'Service Category', visible: true },
  { id: 'assigned_to', name: 'Assigned Handler', visible: true },
  { id: 'status', name: 'Status', visible: true },
  { id: 'actions', name: 'Actions', visible: true },
  { id: 'linked_reference', name: 'Linked Fulfillment', visible: false },
  { id: 'state', name: 'State', visible: false }
]);

const isColumnVisible = (id: string) => {
  const col = tableColumns.value.find(c => c.id === id);
  return col ? col.visible : true;
};

// ─── QUICK CREATE MODAL (AGENTS.md Rule 4: <= 5 Required Fields Standard) ─
const showQuickCreate = ref(false);

const quickForm = ref<{
  employee_id: number;
  entity_id: number;
  category: HRServiceRequestCategory;
  subject: string;
  description: string;
}>({
  employee_id: 22,
  entity_id: 1,
  category: 'letter',
  subject: '',
  description: ''
});

const employeeOptions = [
  { value: 22, label: 'Hana Mesfin Tadesse (EMP-0022 - Finance)' },
  { value: 14, label: 'Solomon Bekele Worku (EMP-0014 - HR)' },
  { value: 31, label: 'Helen Berhanu Haile (EMP-0031 - Talent)' },
  { value: 44, label: 'Dawit Tadesse Mengistu (EMP-0044 - Audit)' },
  { value: 15, label: 'Yared Alemu Kassaye (EMP-0015 - IT)' },
  { value: 12, label: 'Abebe Kebede Wolde (EMP-0012 - Retail)' }
];

const categoryOptions = [
  { value: 'letter', label: 'Official Employee Letter' },
  { value: 'id_card', label: 'Staff ID & RFID Card' },
  { value: 'payslip_copy', label: 'Certified Payslip Copy' },
  { value: 'data_correction', label: 'Profile Data Correction' },
  { value: 'benefit_inquiry', label: 'Benefits & Medical Insurance' },
  { value: 'general', label: 'General HR Inquiry' }
];

const entityOptions = [
  { value: 1, label: 'Haleta Corporate Headquarters' },
  { value: 3, label: 'Haleta Addis Ababa Branch' }
];

const handleOpenQuickCreate = () => {
  quickForm.value = {
    employee_id: 22,
    entity_id: 1,
    category: 'letter',
    subject: '',
    description: ''
  };
  showQuickCreate.value = true;
};

const handleSaveQuickCreate = () => {
  if (!quickForm.value.subject.trim()) {
    alert('Please enter a request subject.');
    return;
  }

  const emp = employeeOptions.find(e => e.value === quickForm.value.employee_id);
  const empName = emp ? emp.label.split(' (')[0] : 'Employee';
  const empCode = emp ? emp.label.split('(')[1]?.split(' -')[0] || 'EMP-0000' : 'EMP-0000';

  createServiceRequest({
    employee_id: quickForm.value.employee_id,
    employee_name: empName,
    employee_code: empCode,
    department: 'Corporate Department',
    position: 'Staff Member',
    tenant_id: 1,
    entity_id: quickForm.value.entity_id,
    entity_name: quickForm.value.entity_id === 3 ? 'Haleta Addis Ababa Branch' : 'Haleta Corporate Headquarters',
    category_lookup_value_id: quickForm.value.category,
    subject: quickForm.value.subject.trim(),
    description: quickForm.value.description.trim() || null,
    request_state_lookup_value_id: 'open',
    assigned_to_employee_id: null,
    assigned_to_name: null,
    linked_reference: null,
    resolution_note: null,
    resolved_at: null,
    user_id: 7,
    state: 'active'
  });

  showQuickCreate.value = false;
};

// Expand to full form (Rule 4)
const handleExpandFullForm = () => {
  showQuickCreate.value = false;
  router.push({
    path: '/hr/service-requests/create',
    query: {
      employee_id: quickForm.value.employee_id.toString(),
      entity_id: quickForm.value.entity_id.toString(),
      category: quickForm.value.category,
      subject: quickForm.value.subject,
      description: quickForm.value.description
    }
  });
};

// ─── FORMATTERS & HELPERS ─────────────────────────────────────────────────
const formatCategory = (cat: HRServiceRequestCategory) => {
  switch (cat) {
    case 'letter': return 'Letter Request';
    case 'id_card': return 'Staff ID Card';
    case 'payslip_copy': return 'Payslip Copy';
    case 'data_correction': return 'Profile Data Correction';
    case 'benefit_inquiry': return 'Benefit Inquiry';
    case 'general': return 'General Inquiry';
    default: return cat;
  }
};

const formatRequestState = (state: HRServiceRequestState) => {
  switch (state) {
    case 'open': return 'Open';
    case 'assigned': return 'Assigned';
    case 'in_progress': return 'In Progress';
    case 'resolved': return 'Resolved';
    case 'closed': return 'Closed';
    case 'cancelled': return 'Cancelled';
    default: return state;
  }
};

// Universal Date Formatting Standard (Rule 22: MMM D, YYYY)
const formatDate = (dateStr: string | null | undefined) => {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
};

// ─── DETAIL & FULFILLMENT MODAL ───────────────────────────────────────────
const selectedRequest = ref<HRServiceRequestRecord | null>(null);
const showDetailModal = ref(false);
const detailResolutionNote = ref('');
const detailAssigneeId = ref<number>(14);

const openDetailModal = (item: HRServiceRequestRecord) => {
  selectedRequest.value = item;
  detailResolutionNote.value = item.resolution_note || '';
  detailAssigneeId.value = item.assigned_to_employee_id || 14;
  showDetailModal.value = true;
};

const closeDetailModal = () => {
  showDetailModal.value = false;
  selectedRequest.value = null;
};

const handleAssignInModal = () => {
  if (!selectedRequest.value) return;
  const handler = employeeOptions.find(e => e.value === detailAssigneeId.value);
  const handlerName = handler ? handler.label.split(' (')[0] : 'Solomon Bekele Worku';
  assignServiceRequest(selectedRequest.value.id, detailAssigneeId.value, handlerName);
};

const handleResolveInModal = () => {
  if (!selectedRequest.value) return;
  if (!detailResolutionNote.value.trim()) {
    alert('Please enter a resolution note.');
    return;
  }

  // If category is letter, simulate linking to letter #67 per schema example line 2251
  if (selectedRequest.value.category_lookup_value_id === 'letter' && !selectedRequest.value.linked_reference) {
    resolveServiceRequest(
      selectedRequest.value.id,
      detailResolutionNote.value.trim(),
      67,
      'LTR-2026-0067'
    );
  } else {
    resolveServiceRequest(selectedRequest.value.id, detailResolutionNote.value.trim());
  }
  closeDetailModal();
};

const handleCloseInModal = () => {
  if (!selectedRequest.value) return;
  updateServiceRequestState(selectedRequest.value.id, 'closed');
  closeDetailModal();
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

const handleDirectResolve = (item: HRServiceRequestRecord) => {
  closeActionMenu();
  openDetailModal(item);
};

const handleCancelRequest = (item: HRServiceRequestRecord) => {
  closeActionMenu();
  if (confirm(`Cancel service request ${item.code}?`)) {
    updateServiceRequestState(item.id, 'cancelled');
  }
};
</script>

<template>
  <div class="service-requests-page" @click="closeActionMenu">
    <!-- Breadcrumb (Rule 3) -->
    <div class="page-breadcrumb">
      <AppBreadcrumb :items="breadcrumbs" />
    </div>

    <!-- KPI Metric Cards (Rule 2) -->
    <div class="metrics-grid">
      <MetricCard
        label="TOTAL REQUESTS"
        :value="totalRequests"
        subtext="All employee service tickets logged"
      />
      <MetricCard
        label="OPEN & UNASSIGNED"
        :value="openRequests"
        subtext="Pending first triage review"
      />
      <MetricCard
        label="IN PROGRESS"
        :value="inProgressRequests"
        subtext="Assigned & active HR fulfillment"
      />
      <MetricCard
        label="RESOLVED & CLOSED"
        :value="resolvedClosedRequests"
        subtext="Successfully completed tickets"
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
        title="HR Service Requests"
        subtitle="Manage employee helpdesk tickets, document issuing requests, profile corrections, and benefits inquiries."
        :total-items="filteredRequests.length"
        :current-page="1"
        :per-page="10"
        :columns="tableColumns"
        @toggle-column="(colId) => {
          const col = tableColumns.find(c => c.id === colId);
          if (col) col.visible = !col.visible;
        }"
      >
        <!-- Table Toolbar Actions Slot -->
        <template #actions>
          <button
            type="button"
            class="btn-primary-add"
            @click="handleOpenQuickCreate"
          >
            <Plus :size="16" />
            <span>Create Service Request</span>
          </button>
        </template>

        <!-- Search Bar -->
        <template #search>
          <div class="table-search-box">
            <Search :size="14" class="search-icon" />
            <input
              v-model="searchQuery"
              type="text"
              class="search-input"
              placeholder="Search by subject, code, employee, handler..."
            />
          </div>
        </template>

        <!-- Data Table (Rules 8, 9) -->
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
                <th v-if="isColumnVisible('subject')">Subject & Ticket</th>
                <th v-if="isColumnVisible('employee')">Requester</th>
                <th v-if="isColumnVisible('category')">Service Category</th>
                <th v-if="isColumnVisible('assigned_to')">Assigned Handler</th>
                <th v-if="isColumnVisible('linked_reference')">Linked Fulfillment</th>
                <th v-if="isColumnVisible('status')">Status</th>
                <th v-if="isColumnVisible('state')">State</th>
                <th v-if="isColumnVisible('actions')" class="th-actions"></th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="item in filteredRequests"
                :key="item.id"
                class="erp-table-row"
                :class="{ 'row-selected': selectedIds.includes(item.id) }"
              >
                <!-- Checkbox -->
                <td class="td-checkbox">
                  <input
                    type="checkbox"
                    :checked="selectedIds.includes(item.id)"
                    class="table-checkbox"
                    @change="toggleSelectRow(item.id)"
                  />
                </td>

                <!-- Subject & Code (Rule 4: Zero standalone code column, Name/Subject first) -->
                <td v-if="isColumnVisible('subject')" class="td-subject">
                  <div class="subject-cell-wrapper" @click="openDetailModal(item)">
                    <span class="table-name-primary">{{ item.subject }}</span>
                    <span class="table-code-subtext">{{ item.code }}</span>
                  </div>
                </td>

                <!-- Requester (Rule 8: Cross-entity plain text name in tertiary color) -->
                <td v-if="isColumnVisible('employee')" class="td-requester">
                  <span class="table-name-tertiary">{{ item.employee_name }}</span>
                  <span class="table-sub-tertiary">{{ item.employee_code }} • {{ item.department }}</span>
                </td>

                <!-- Category (Rule 6: Anti-Badge Standard, plain text in tertiary color) -->
                <td v-if="isColumnVisible('category')" class="td-category">
                  <span class="tertiary-text">{{ formatCategory(item.category_lookup_value_id) }}</span>
                </td>

                <!-- Assigned Handler (Rule 8: Plain text in tertiary color) -->
                <td v-if="isColumnVisible('assigned_to')" class="td-handler">
                  <span class="tertiary-text">{{ item.assigned_to_name || '— (Unassigned)' }}</span>
                </td>

                <!-- Linked Fulfillment (Rule 6: Plain text with subtle link) -->
                <td v-if="isColumnVisible('linked_reference')" class="td-fulfillment">
                  <div v-if="item.linked_reference?.employee_letter_code" class="linked-badge-cell">
                    <FileText :size="12" class="link-icon" />
                    <span>Letter {{ item.linked_reference.employee_letter_code }}</span>
                  </div>
                  <span v-else-if="item.linked_reference?.note" class="tertiary-text">
                    {{ item.linked_reference.note }}
                  </span>
                  <span v-else class="tertiary-text">—</span>
                </td>

                <!-- Status (Lifecycle state) -->
                <td v-if="isColumnVisible('status')">
                  <span
                    class="status-pill"
                    :class="`status-${item.request_state_lookup_value_id}`"
                  >
                    {{ formatRequestState(item.request_state_lookup_value_id) }}
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
                        @click="openDetailModal(item); closeActionMenu()"
                      >
                        <Eye :size="13" />
                        <span>View Ticket Details</span>
                      </button>
                      <button
                        v-if="['open', 'assigned', 'in_progress'].includes(item.request_state_lookup_value_id)"
                        type="button"
                        class="menu-item"
                        @click="handleDirectResolve(item)"
                      >
                        <Check :size="13" />
                        <span>Resolve Ticket</span>
                      </button>
                      <button
                        v-if="item.request_state_lookup_value_id === 'resolved'"
                        type="button"
                        class="menu-item"
                        @click="updateServiceRequestState(item.id, 'closed'); closeActionMenu()"
                      >
                        <CheckCircle2 :size="13" />
                        <span>Close Ticket</span>
                      </button>
                      <button
                        v-if="item.request_state_lookup_value_id !== 'cancelled'"
                        type="button"
                        class="menu-item menu-item-danger"
                        @click="handleCancelRequest(item)"
                      >
                        <X :size="13" />
                        <span>Cancel Request</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>

              <!-- Empty State -->
              <tr v-if="filteredRequests.length === 0">
                <td colspan="9" class="td-empty">
                  <LifeBuoy :size="32" class="empty-icon" />
                  <p class="empty-title">No service requests found</p>
                  <p class="empty-sub">There are no tickets matching the current filter criteria.</p>
                </td>
              </tr>
            </tbody>
          </table>
        </template>
      </AppDataTable>
    </div>

    <!-- ─── QUICK CREATE MODAL (AGENTS.md Rule 4 & 15: <= 5 Essential Fields, Zero Textareas) ── -->
    <QuickCreateModal
      v-model:show="showQuickCreate"
      title="Create HR Service Request"
      @save="handleSaveQuickCreate"
      @expand="handleExpandFullForm"
    >
      <div class="quick-modal-body">
        <FormSelect
          v-model="quickForm.employee_id"
          label="Requester Employee *"
          :options="employeeOptions"
        />

        <div class="form-grid-2">
          <FormSelect
            v-model="quickForm.category"
            label="Service Category *"
            :options="categoryOptions"
          />
          <FormSelect
            v-model="quickForm.entity_id"
            label="Owning Entity *"
            :options="entityOptions"
          />
        </div>

        <FormInput
          v-model="quickForm.subject"
          label="Request Subject *"
          required
        />
      </div>
    </QuickCreateModal>

    <!-- ─── TICKET DETAIL & FULFILLMENT MODAL ─────────────────────────────── -->
    <div v-if="showDetailModal && selectedRequest" class="detail-backdrop" @click.self="closeDetailModal">
      <div class="detail-modal-card">
        <!-- Modal Header -->
        <div class="detail-header">
          <div>
            <div class="ticket-badge-row">
              <span class="ticket-code-pill">{{ selectedRequest.code }}</span>
              <span class="status-pill" :class="`status-${selectedRequest.request_state_lookup_value_id}`">
                {{ formatRequestState(selectedRequest.request_state_lookup_value_id) }}
              </span>
            </div>
            <h3 class="detail-subject-title">{{ selectedRequest.subject }}</h3>
          </div>
          <button type="button" class="btn-close-modal" @click="closeDetailModal">
            <X :size="18" />
          </button>
        </div>

        <!-- Modal Body Content -->
        <div class="detail-body-scroll">
          <!-- Requester Card -->
          <div class="info-block-card">
            <h4 class="block-title">Requester Information</h4>
            <div class="requester-grid">
              <div>
                <span class="field-label">Employee</span>
                <p class="field-val">{{ selectedRequest.employee_name }} ({{ selectedRequest.employee_code }})</p>
              </div>
              <div>
                <span class="field-label">Department & Role</span>
                <p class="field-val">{{ selectedRequest.department }} • {{ selectedRequest.position }}</p>
              </div>
              <div>
                <span class="field-label">Category</span>
                <p class="field-val">{{ formatCategory(selectedRequest.category_lookup_value_id) }}</p>
              </div>
              <div>
                <span class="field-label">Logged Date</span>
                <p class="field-val">{{ formatDate(selectedRequest.created_at) }}</p>
              </div>
            </div>
          </div>

          <!-- Description -->
          <div class="info-block-card">
            <h4 class="block-title">Request Context</h4>
            <p class="desc-text">{{ selectedRequest.description || 'No detailed description provided.' }}</p>
          </div>

          <!-- Assignment & Handler -->
          <div class="info-block-card">
            <h4 class="block-title">Handler Assignment</h4>
            <div class="assignment-row">
              <div class="select-handler-wrap">
                <FormSelect
                  v-model="detailAssigneeId"
                  label="Assigned HR Specialist"
                  :options="employeeOptions"
                />
              </div>
              <button
                type="button"
                class="btn-reassign"
                @click="handleAssignInModal"
              >
                Assign Handler
              </button>
            </div>
          </div>

          <!-- Letter Category Fulfillment Banner -->
          <div v-if="selectedRequest.category_lookup_value_id === 'letter'" class="letter-fulfillment-box">
            <FileText :size="18" class="letter-box-icon" />
            <div class="letter-box-text">
              <span class="letter-box-title">Letter Category Fulfillment</span>
              <p class="letter-box-desc">
                Per schema note, letter tickets are fulfilled by issuing an <code>EmployeeLetter</code> and linking its ID. Resolving this ticket will cross-link it to Employee Letter #67 (<code>LTR-2026-0067</code>).
              </p>
            </div>
          </div>

          <!-- Resolution Note (when resolving or resolved) -->
          <div class="info-block-card">
            <h4 class="block-title">Resolution Notes & Findings</h4>
            <FormTextarea
              v-model="detailResolutionNote"
              label="Resolution Note *"
              rows="3"
            />
            <p v-if="selectedRequest.resolved_at" class="resolved-timestamp">
              Resolved at: {{ new Date(selectedRequest.resolved_at).toLocaleString('en-GB') }}
            </p>
          </div>
        </div>

        <!-- Modal Footer Actions -->
        <div class="detail-footer">
          <button type="button" class="btn-cancel" @click="closeDetailModal">
            Close
          </button>
          <div class="footer-right-actions">
            <button
              v-if="['open', 'assigned', 'in_progress'].includes(selectedRequest.request_state_lookup_value_id)"
              type="button"
              class="btn-resolve-primary"
              @click="handleResolveInModal"
            >
              <Check :size="14" />
              <span>Mark as Resolved</span>
            </button>
            <button
              v-if="selectedRequest.request_state_lookup_value_id === 'resolved'"
              type="button"
              class="btn-close-ticket"
              @click="handleCloseInModal"
            >
              <CheckCircle2 :size="14" />
              <span>Close Ticket</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.service-requests-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 24px 32px;
  background-color: #f8fafc;
  min-height: 100vh;
}

.page-breadcrumb {
  margin-bottom: -4px;
}

/* Metrics Grid (Rule 2) */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.tabs-container {
  margin-top: 4px;
}

/* Table Card Wrapper (Rule 10) */
.table-card-wrapper {
  background: #ffffff;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  overflow: hidden;
}

/* Table Toolbar Buttons */
.btn-primary-add {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  padding: 0 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px; /* Rule 6: 8-10px well-rounded rectangle */
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary-add:hover {
  background-color: #09427d;
}

.table-search-box {
  position: relative;
  width: 320px;
}

.search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
  pointer-events: none;
}

.search-input {
  width: 100%;
  height: 38px;
  padding: 0 12px 0 34px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  outline: none;
  transition: border-color 0.15s ease;
}

.search-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

/* Table Styles (Rule 8, 9) */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  background-color: #fafafa;
  color: #737373;
  font-size: 12px;
  font-weight: 500;
  border-bottom: 1px solid #e2e8f0;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
}

.erp-table-row:hover {
  background-color: #f8fafc;
}

.row-selected {
  background-color: #f0f7ff !important;
}

.th-checkbox,
.td-checkbox {
  width: 36px;
  padding-right: 0 !important;
  text-align: center;
}

.table-checkbox {
  cursor: pointer;
  width: 15px;
  height: 15px;
  accent-color: #0B529C;
}

/* Name/Subject column (Rule 9: Secondary color #404040 for Name, Tertiary for others) */
.subject-cell-wrapper {
  display: flex;
  flex-direction: column;
  cursor: pointer;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 500;
  color: #404040; /* Rule 9: Secondary Color for Name/Subject */
}

.table-code-subtext {
  font-size: 11.5px;
  color: #737373;
  margin-top: 2px;
}

.table-name-tertiary {
  display: block;
  font-size: 13px;
  font-weight: 500;
  color: #737373; /* Rule 5/9: Tertiary for right columns */
}

.table-sub-tertiary {
  display: block;
  font-size: 11.5px;
  color: #94a3b8;
}

.tertiary-text {
  color: #737373; /* Rule 5/9 */
  font-size: 12.5px;
}

/* Linked Fulfillment cell */
.linked-badge-cell {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  color: #0B529C;
  font-size: 12px;
  font-weight: 500;
}

.link-icon {
  color: #0B529C;
}

/* Status Pills */
.status-pill {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
}

.status-open {
  background-color: #eff6ff;
  color: #1d4ed8;
}

.status-assigned {
  background-color: #fef3c7;
  color: #b45309;
}

.status-in_progress {
  background-color: #fef9c3;
  color: #a16207;
}

.status-resolved {
  background-color: #ecfdf5;
  color: #059669;
}

.status-closed {
  background-color: #f1f5f9;
  color: #475569;
}

.status-cancelled {
  background-color: #fef2f2;
  color: #dc2626;
}

/* State Pills (Active / Inactive) */
.state-pill {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
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

/* Action Dropdown Menu */
.th-actions,
.td-actions {
  width: 44px;
  text-align: right;
  padding-right: 12px !important;
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
  background: transparent;
  border: none;
  border-radius: 6px;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #0B529C;
}

.action-menu-dropdown {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  width: 175px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  padding: 4px;
  z-index: 50;
}

.menu-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  background: transparent;
  border: none;
  border-radius: 6px;
  font-size: 12.5px;
  color: #404040;
  text-align: left;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.menu-item:hover {
  background-color: #f8fafc;
  color: #0B529C;
}

.menu-item-danger {
  color: #ef4444;
}

.menu-item-danger:hover {
  background-color: #fef2f2;
  color: #dc2626;
}

/* Empty State */
.td-empty {
  text-align: center;
  padding: 48px 16px !important;
}

.empty-icon {
  margin: 0 auto 12px;
  color: #94a3b8;
}

.empty-title {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
  margin: 0 0 4px 0;
}

.empty-sub {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* Quick Create Form Grid */
.quick-modal-body {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

/* Detail Modal Styles */
.detail-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  backdrop-filter: blur(2px);
}

.detail-modal-card {
  width: 680px;
  max-width: 95vw;
  max-height: 90vh;
  background: #ffffff;
  border-radius: 12px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.detail-header {
  padding: 18px 24px;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  border-bottom: 1px solid #f1f5f9;
}

.ticket-badge-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.ticket-code-pill {
  font-size: 12px;
  font-weight: 600;
  color: #0B529C;
  background-color: #eff6ff;
  padding: 2px 8px;
  border-radius: 6px;
}

.detail-subject-title {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.btn-close-modal {
  background: transparent;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 4px;
  border-radius: 6px;
}

.btn-close-modal:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.detail-body-scroll {
  padding: 20px 24px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.info-block-card {
  background: #fafafa;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px 16px;
}

.block-title {
  margin: 0 0 10px 0;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #737373;
}

.requester-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.field-label {
  display: block;
  font-size: 11px;
  color: #94a3b8;
  margin-bottom: 2px;
}

.field-val {
  margin: 0;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.desc-text {
  margin: 0;
  font-size: 13px;
  color: #404040;
  line-height: 1.5;
}

.assignment-row {
  display: flex;
  align-items: flex-end;
  gap: 12px;
}

.select-handler-wrap {
  flex: 1;
}

.btn-reassign {
  height: 38px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  font-size: 12.5px;
  color: #404040;
  font-weight: 500;
  cursor: pointer;
}

.btn-reassign:hover {
  background-color: #f8fafc;
  border-color: #0B529C;
  color: #0B529C;
}

.letter-fulfillment-box {
  background-color: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 8px;
  padding: 12px 16px;
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.letter-box-icon {
  color: #0B529C;
  margin-top: 2px;
  flex-shrink: 0;
}

.letter-box-title {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: #0B529C;
  margin-bottom: 2px;
}

.letter-box-desc {
  margin: 0;
  font-size: 12px;
  color: #1e3a8a;
  line-height: 1.45;
}

.resolved-timestamp {
  margin: 8px 0 0 0;
  font-size: 11.5px;
  color: #059669;
  font-style: italic;
}

.detail-footer {
  padding: 14px 24px;
  background-color: #fafafa;
  border-top: 1px solid #f1f5f9;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.btn-cancel {
  height: 38px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #64748b;
  cursor: pointer;
}

.footer-right-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-resolve-primary {
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
}

.btn-resolve-primary:hover {
  background-color: #09427d;
}

.btn-close-ticket {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #10b981;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-close-ticket:hover {
  background-color: #059669;
}
</style>
