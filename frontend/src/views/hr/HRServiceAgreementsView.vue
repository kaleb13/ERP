<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, Search, MoreVertical, Users,
  FileText, Eye, CheckCircle2, AlertTriangle,
  X
} from 'lucide-vue-next';;

import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import MetricCard from '../../components/MetricCard.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import AppDataTable from '../../components/AppDataTable.vue';

import {
  serviceAgreementsData,
  updateAgreementState,
  deleteServiceAgreement,
  type HRServiceAgreementRecord,
  type AgreementType,
  type AgreementState,
  type PayrollResponsibility,
  type ServiceFeeType
} from './serviceAgreementData';

const router = useRouter();

// ─── BREADCRUMBS (Rule 3: Exact Sidebar Page Name Only) ───────────────────
const breadcrumbs = [
  { label: 'HR Service Agreements' }
];

// ─── KPI METRICS (Rule 2) ─────────────────────────────────────────────────
const totalAgreements = computed(() => serviceAgreementsData.value.length);
const activeContracts = computed(() =>
  serviceAgreementsData.value.filter(a => a.agreement_state_lookup_value_id === 'active').length
);
const leasedHeadcountCap = computed(() => {
  return serviceAgreementsData.value
    .filter(a => a.agreement_state_lookup_value_id === 'active' && a.max_employees !== null)
    .reduce((sum, a) => sum + (a.max_employees || 0), 0);
});
const clientFundedCount = computed(() =>
  serviceAgreementsData.value.filter(a => a.payroll_responsibility_lookup_value_id === 'client_funds_employer_pays').length
);

// ─── SECONDARY TABS (Rule 1: UnderlineTabs for Sub-views) ─────────────────
type TabId = 'all' | 'active' | 'pending_approval' | 'draft' | 'expired_suspended';
const activeTab = ref<TabId>('all');

const statusTabs = computed<UnderlineTabItem<TabId>[]>(() => [
  { id: 'all', label: 'All Agreements', count: serviceAgreementsData.value.length },
  { id: 'active', label: 'Active & In Effect', count: activeContracts.value, badgeVariant: 'success' },
  { id: 'pending_approval', label: 'Pending Approval', count: serviceAgreementsData.value.filter(a => a.agreement_state_lookup_value_id === 'pending_approval').length, badgeVariant: 'warning' },
  { id: 'draft', label: 'Draft', count: serviceAgreementsData.value.filter(a => a.agreement_state_lookup_value_id === 'draft').length },
  { id: 'expired_suspended', label: 'Expired / Suspended', count: serviceAgreementsData.value.filter(a => ['expired', 'suspended', 'terminated'].includes(a.agreement_state_lookup_value_id)).length }
]);

// ─── SEARCH & FILTERING ──────────────────────────────────────────────────
const searchQuery = ref('');

const filteredAgreements = computed(() => {
  return serviceAgreementsData.value.filter(item => {
    // Tab filter
    if (activeTab.value === 'active' && item.agreement_state_lookup_value_id !== 'active') return false;
    if (activeTab.value === 'pending_approval' && item.agreement_state_lookup_value_id !== 'pending_approval') return false;
    if (activeTab.value === 'draft' && item.agreement_state_lookup_value_id !== 'draft') return false;
    if (activeTab.value === 'expired_suspended' && !['expired', 'suspended', 'terminated'].includes(item.agreement_state_lookup_value_id)) return false;

    // Search query filter
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase();
      const matchClient = item.client_party_name.toLowerCase().includes(q);
      const matchCode = item.code.toLowerCase().includes(q);
      const matchProvider = item.provider_name.toLowerCase().includes(q);
      const matchNotes = (item.notes || '').toLowerCase().includes(q);
      if (!matchClient && !matchCode && !matchProvider && !matchNotes) return false;
    }
    return true;
  });
});

// ─── SELECTION ───────────────────────────────────────────────────────────
const selectedIds = ref<number[]>([]);
const isAllSelected = computed(() => {
  return (
    filteredAgreements.value.length > 0 &&
    filteredAgreements.value.every(a => selectedIds.value.includes(a.id))
  );
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedIds.value = [];
  } else {
    selectedIds.value = filteredAgreements.value.map(a => a.id);
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

// ─── TABLE COLUMNS (Rule 9: Atomic columns, Name first, Code subtext) ────
const tableColumns = ref<ColumnDef[]>([
  { key: 'client', label: 'Client & Agreement', visible: true },
  { key: 'provider', label: 'Provider Entity', visible: true },
  { key: 'agreement_type', label: 'Agreement Type', visible: true },
  { key: 'valid_period', label: 'Effective Timeline', visible: true },
  { key: 'status', label: 'Status', visible: true },
  { key: 'actions', label: 'Actions', visible: true },
  { key: 'client_type', label: 'Client Tenancy', visible: false },
  { key: 'payroll_resp', label: 'Payroll Responsibility', visible: false },
  { key: 'fee_model', label: 'Service Fee Model', visible: false },
  { key: 'headcount_cap', label: 'Headcount Cap', visible: false },
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

// ─── FORMATTERS & HELPERS ─────────────────────────────────────────────────
const formatAgreementType = (type: AgreementType) => {
  switch (type) {
    case 'staffing': return 'Staffing Supply';
    case 'outsourcing': return 'Operations Outsourcing';
    case 'employer_of_record': return 'Employer of Record (EOR)';
    case 'secondment_out': return 'Secondment Outbound';
    case 'consultancy': return 'Workforce Consultancy';
    default: return type;
  }
};

const formatPayrollResponsibility = (resp: PayrollResponsibility) => {
  switch (resp) {
    case 'client_funds_employer_pays': return 'Client Funds (Employer Pays)';
    case 'employer_pays': return 'Employer Direct';
    case 'client_pays_directly': return 'Client Direct';
    default: return resp;
  }
};

const formatFeeModel = (item: HRServiceAgreementRecord) => {
  if (!item.service_fee_type_lookup_value_id || item.service_fee_value === null) {
    return '— (Billed Separately)';
  }
  switch (item.service_fee_type_lookup_value_id) {
    case 'percent_of_payroll':
      return `${item.service_fee_value.toFixed(2)}% of Gross Payroll`;
    case 'fixed_per_employee':
      return `${item.service_fee_value.toLocaleString()} ${item.billing_currency_code} / Employee`;
    case 'fixed_monthly':
      return `${item.service_fee_value.toLocaleString()} ${item.billing_currency_code} Monthly Fixed`;
    case 'markup_percent':
      return `${item.service_fee_value.toFixed(2)}% Net Cost Markup`;
    default:
      return `${item.service_fee_value} ${item.billing_currency_code}`;
  }
};

// Universal Date Formatting Standard (Rule 22: MMM D, YYYY)
const formatDate = (dateStr: string | null | undefined) => {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
};

// ─── NAVIGATION ───────────────────────────────────────────────────────────
const handleCreateAgreement = () => {
  router.push('/hr/service-agreements/create');
};

const navigateToEdit = (id: number) => {
  closeActionMenu();
  router.push({
    path: '/hr/service-agreements/create',
    query: { id: id.toString() }
  });
};

const navigateToAssignments = (agreementId: number) => {
  closeActionMenu();
  router.push({
    path: '/hr/client-assignments',
    query: { agreement_id: agreementId.toString() }
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
const selectedAgreement = ref<HRServiceAgreementRecord | null>(null);
const isDetailModalOpen = ref(false);

const openDetailModal = (item: HRServiceAgreementRecord) => {
  selectedAgreement.value = item;
  isDetailModalOpen.value = true;
  closeActionMenu();
};

const closeDetailModal = () => {
  isDetailModalOpen.value = false;
  selectedAgreement.value = null;
};

const handleStateChange = (id: number, newState: AgreementState) => {
  updateAgreementState(id, newState);
  closeActionMenu();
  if (selectedAgreement.value && selectedAgreement.value.id === id) {
    selectedAgreement.value.agreement_state_lookup_value_id = newState;
  }
};
</script>

<template>
  <div class="service-agreements-page" @click="closeActionMenu">
    <!-- Breadcrumb (Rule 3) -->
    <div class="page-breadcrumb">
      <AppBreadcrumb :items="breadcrumbs" />
    </div>

    <!-- 4 KPI Metrics Cards (Rule 2) -->
    <div class="metrics-grid">
      <MetricCard
        label="TOTAL AGREEMENTS"
        :value="totalAgreements"
        subtext="Workforce supply contracts logged"
      />
      <MetricCard
        label="ACTIVE CONTRACTS"
        :value="activeContracts"
        subtext="Currently operational pipelines"
      />
      <MetricCard
        label="LEASED HEADCOUNT CAP"
        :value="leasedHeadcountCap + ' Staff'"
        subtext="Cumulative placement capacity"
      />
      <MetricCard
        label="CLIENT-FUNDED PAYROLL"
        :value="clientFundedCount"
        subtext="Cross-entity payroll funding models"
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
        title="HR Service Agreements"
        subtitle="Manage workforce supply contracts, employer-of-record facilities, cross-entity staffing, and service fee models."
        :totalEntries="filteredAgreements.length"
        v-model:searchQuery="searchQuery"
        :columns="tableColumns"
        @toggleColumn="handleToggleColumn"
      >
        <!-- Table Toolbar Actions Slot -->
        <template #actions>
          <AppButton variant="primary" size="sm" @click="handleCreateAgreement">
  <template #icon-left><Plus :size="15" /></template>
  Create Service Agreement
</AppButton>
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
                <th v-if="isColumnVisible('client')">Client & Agreement</th>
                <th v-if="isColumnVisible('provider')">Provider Entity</th>
                <th v-if="isColumnVisible('client_type')">Client Tenancy</th>
                <th v-if="isColumnVisible('agreement_type')">Agreement Type</th>
                <th v-if="isColumnVisible('payroll_resp')">Payroll Responsibility</th>
                <th v-if="isColumnVisible('fee_model')">Service Fee Model</th>
                <th v-if="isColumnVisible('headcount_cap')">Headcount Cap</th>
                <th v-if="isColumnVisible('valid_period')">Effective Timeline</th>
                <th v-if="isColumnVisible('status')">Status</th>
                <th v-if="isColumnVisible('state')">State</th>
                <th v-if="isColumnVisible('actions')" class="th-actions"></th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="item in filteredAgreements"
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

                <!-- Client Name & Code (Rule 9: Name on top, Code underneath as subtext) -->
                <td v-if="isColumnVisible('client')" class="td-client">
                  <div class="client-cell-wrap" @click="openDetailModal(item)">
                    <span class="table-name-primary">{{ item.client_party_name }}</span>
                    <span class="table-code-subtext">{{ item.code }}</span>
                  </div>
                </td>

                <!-- Provider Entity (Rule 9: Tertiary text) -->
                <td v-if="isColumnVisible('provider')" class="td-provider">
                  <span class="tertiary-text">{{ item.provider_name }}</span>
                </td>

                <!-- Client Tenancy (Separation Principle: Tenant vs External) -->
                <td v-if="isColumnVisible('client_type')" class="td-tenancy">
                  <span v-if="item.client_entity_id" class="tertiary-text">
                    Haleta Tenant ({{ item.client_entity_name }})
                  </span>
                  <span v-else class="tertiary-text">
                    External Client (Sales Billing)
                  </span>
                </td>

                <!-- Agreement Type -->
                <td v-if="isColumnVisible('agreement_type')">
                  <span class="tertiary-text">{{ formatAgreementType(item.agreement_type_lookup_value_id) }}</span>
                </td>

                <!-- Payroll Responsibility -->
                <td v-if="isColumnVisible('payroll_resp')">
                  <span class="tertiary-text">{{ formatPayrollResponsibility(item.payroll_responsibility_lookup_value_id) }}</span>
                </td>

                <!-- Service Fee Model -->
                <td v-if="isColumnVisible('fee_model')">
                  <span class="tertiary-text">{{ formatFeeModel(item) }}</span>
                </td>

                <!-- Headcount Cap -->
                <td v-if="isColumnVisible('headcount_cap')">
                  <span class="tertiary-text">
                    {{ item.max_employees ? `${item.max_employees} Staff Max` : 'Uncapped' }}
                  </span>
                </td>

                <!-- Effective Timeline (Rule 22: MMM D, YYYY) -->
                <td v-if="isColumnVisible('valid_period')">
                  <span class="tertiary-text">
                    {{ formatDate(item.start_date) }} – {{ item.end_date ? formatDate(item.end_date) : 'Open-ended' }}
                  </span>
                </td>

                <!-- Status (Lifecycle state) -->
                <td v-if="isColumnVisible('status')">
                  <span
                    class="status-pill"
                    :class="`status-${item.agreement_state_lookup_value_id}`"
                  >
                    {{ item.agreement_state_lookup_value_id.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase()) }}
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
                        <span>View Contract Terms</span>
                      </button>

                      <button
                        type="button"
                        class="menu-item"
                        @click="navigateToAssignments(item.id)"
                      >
                        <Users :size="13" />
                        <span>View Leased Staff</span>
                      </button>

                      <button
                        type="button"
                        class="menu-item"
                        @click="navigateToEdit(item.id)"
                      >
                        <FileText :size="13" />
                        <span>Edit Agreement</span>
                      </button>

                      <div class="menu-divider"></div>

                      <button
                        v-if="item.agreement_state_lookup_value_id === 'draft' || item.agreement_state_lookup_value_id === 'pending_approval'"
                        type="button"
                        class="menu-item"
                        @click="handleStateChange(item.id, 'active')"
                      >
                        <CheckCircle2 :size="13" />
                        <span>Activate Contract</span>
                      </button>

                      <button
                        v-if="item.agreement_state_lookup_value_id === 'active'"
                        type="button"
                        class="menu-item menu-item-warning"
                        @click="handleStateChange(item.id, 'suspended')"
                      >
                        <AlertTriangle :size="13" />
                        <span>Suspend Contract</span>
                      </button>

                      <button
                        v-if="item.agreement_state_lookup_value_id !== 'terminated'"
                        type="button"
                        class="menu-item menu-item-danger"
                        @click="handleStateChange(item.id, 'terminated')"
                      >
                        <X :size="13" />
                        <span>Terminate Contract</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>

              <!-- Empty State -->
              <tr v-if="filteredAgreements.length === 0">
                <td colspan="12" class="td-empty">
                  <div class="empty-state-content">
                    <FileText :size="38" class="empty-icon" />
                    <p class="empty-title">No service agreements found</p>
                    <p class="empty-desc">No workforce supply contracts match your current search or tab filter.</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </template>
      </AppDataTable>
    </div>

    <!-- ─── CONTRACT INSPECTION MODAL ───────────────────────────────────────── -->
    <div v-if="isDetailModalOpen && selectedAgreement" class="detail-backdrop" @click.self="closeDetailModal">
      <div class="detail-modal-card">
        <!-- Modal Header -->
        <div class="detail-header">
          <div>
            <div class="ticket-badge-row">
              <span class="ticket-code-pill">{{ selectedAgreement.code }}</span>
              <span class="status-pill" :class="`status-${selectedAgreement.agreement_state_lookup_value_id}`">
                {{ selectedAgreement.agreement_state_lookup_value_id.replace('_', ' ').toUpperCase() }}
              </span>
            </div>
            <h3 class="detail-subject-title">{{ selectedAgreement.client_party_name }}</h3>
          </div>
          <button type="button" class="btn-close-modal" @click="closeDetailModal">
            <X :size="18" />
          </button>
        </div>

        <!-- Modal Body Content -->
        <div class="detail-body-scroll">
          <!-- Agreement Identification Card -->
          <div class="info-block-card">
            <h4 class="block-title">Contracting Parties & Tenancy Scope</h4>
            <div class="requester-grid">
              <div>
                <span class="field-label">Provider Entity (Employer)</span>
                <p class="field-val">{{ selectedAgreement.provider_name }}</p>
              </div>
              <div>
                <span class="field-label">Client Identity (Party)</span>
                <p class="field-val">{{ selectedAgreement.client_party_name }} (Party #{{ selectedAgreement.client_party_id }})</p>
              </div>
              <div>
                <span class="field-label">Client Haleta Tenancy</span>
                <p class="field-val">
                  {{ selectedAgreement.client_entity_id ? `Internal Tenant: ${selectedAgreement.client_entity_name}` : 'External Client (Non-Tenant)' }}
                </p>
              </div>
              <div>
                <span class="field-label">Agreement Type</span>
                <p class="field-val">{{ formatAgreementType(selectedAgreement.agreement_type_lookup_value_id) }}</p>
              </div>
            </div>
          </div>

          <!-- Commercial & Payroll Terms Card -->
          <div class="info-block-card">
            <h4 class="block-title">Commercial & Payroll Responsibility Terms</h4>
            <div class="requester-grid">
              <div>
                <span class="field-label">Payroll Responsibility</span>
                <p class="field-val">{{ formatPayrollResponsibility(selectedAgreement.payroll_responsibility_lookup_value_id) }}</p>
              </div>
              <div>
                <span class="field-label">Service Fee Model</span>
                <p class="field-val">{{ formatFeeModel(selectedAgreement) }}</p>
              </div>
              <div>
                <span class="field-label">Billing Currency</span>
                <p class="field-val">{{ selectedAgreement.billing_currency_code }}</p>
              </div>
              <div>
                <span class="field-label">Headcount Ceiling</span>
                <p class="field-val">{{ selectedAgreement.max_employees ? `${selectedAgreement.max_employees} Staff Placements Max` : 'Uncapped Headcount' }}</p>
              </div>
            </div>
          </div>

          <!-- Timeline & Governance -->
          <div class="info-block-card">
            <h4 class="block-title">Validity Timeline & Governance</h4>
            <div class="requester-grid">
              <div>
                <span class="field-label">Start Date</span>
                <p class="field-val">{{ formatDate(selectedAgreement.start_date) }}</p>
              </div>
              <div>
                <span class="field-label">Expiration Date</span>
                <p class="field-val">{{ selectedAgreement.end_date ? formatDate(selectedAgreement.end_date) : 'Open-Ended (Permanent)' }}</p>
              </div>
              <div>
                <span class="field-label">Created At</span>
                <p class="field-val">{{ formatDate(selectedAgreement.created_at) }}</p>
              </div>
              <div>
                <span class="field-label">Record State</span>
                <p class="field-val">{{ selectedAgreement.state.toUpperCase() }}</p>
              </div>
            </div>
          </div>

          <!-- Contractual Scope & Notes -->
          <div class="info-block-card">
            <h4 class="block-title">Contractual Terms & Scope Notes</h4>
            <p class="desc-text">{{ selectedAgreement.notes || 'No special contractual notes recorded.' }}</p>
          </div>
        </div>

        <!-- Modal Footer Actions -->
        <div class="detail-footer">
          <button
            type="button"
            class="btn-footer-secondary"
            @click="closeDetailModal"
          >
            Close
          </button>
          <button
            type="button"
            class="btn-footer-primary"
            @click="navigateToAssignments(selectedAgreement.id)"
          >
            <Users :size="14" />
            <span>View Leased Staff Under Contract</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.service-agreements-page {
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
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

@media (max-width: 1024px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Tabs */
.tabs-container {
  margin-top: 4px;
}

/* Table Card Wrapper */
.table-card-wrapper {
  background: #ffffff;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

/* Toolbar elements */
.btn-primary-add {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  padding: 0 18px;
  background-color: #0b529c;
  color: #ffffff;
  border: none;
  border-radius: 8px; /* Rule 6: 8-10px */
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
}

.search-input {
  width: 100%;
  height: 38px;
  padding: 0 12px 0 34px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  outline: none;
}

.search-input:focus {
  border-color: #0b529c;
  background-color: #ffffff;
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

/* Client & Agreement Column */
.td-client {
  /* No fixed min-width to avoid forcing horizontal scrolling */
}

.client-cell-wrap {
  display: flex;
  flex-direction: column;
  gap: 2px;
  cursor: pointer;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 500;
  color: #404040; /* Rule 7 */
}

.table-name-primary:hover {
  color: #0b529c;
}

.table-code-subtext {
  font-size: 11.5px;
  font-family: monospace;
  color: #737373;
}

/* Tertiary text (Rule 9) */
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

.status-pending_approval {
  background-color: #fffbeb;
  color: #d97706;
}

.status-draft {
  background-color: #f1f5f9;
  color: #64748b;
}

.status-expired {
  background-color: #fef2f2;
  color: #dc2626;
}

.status-suspended {
  background-color: #fef2f2;
  color: #dc2626;
}

.status-terminated {
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
  max-height: 88vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.15);
  overflow: hidden;
}

.detail-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid #e2e8f0;
}

.ticket-badge-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.ticket-code-pill {
  font-size: 12px;
  font-family: monospace;
  font-weight: 600;
  color: #0b529c;
  background-color: #eff6ff;
  padding: 2px 8px;
  border-radius: 4px;
}

.detail-subject-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.btn-close-modal {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 6px;
  color: #94a3b8;
  cursor: pointer;
  transition: all 0.15s;
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
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.block-title {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.requester-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.field-label {
  font-size: 11px;
  font-weight: 500;
  color: #737373;
}

.field-val {
  margin: 2px 0 0 0;
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

.detail-footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  padding: 16px 24px;
  border-top: 1px solid #e2e8f0;
  background-color: #fafafa;
}

.btn-footer-secondary {
  height: 36px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
}

.btn-footer-secondary:hover {
  background-color: #f1f5f9;
}

.btn-footer-primary {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 36px;
  padding: 0 16px;
  background-color: #0b529c;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
}

.btn-footer-primary:hover {
  background-color: #09427d;
}
</style>
