<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, MoreVertical, Eye, Edit2, Trash2, Check, X,
  UserCheck, ShieldCheck, Clock, FileCheck
} from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable, { type ColumnDef, type SortOption } from '../../components/AppDataTable.vue';
import BaseAvatar from '../../components/BaseAvatar.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import BaseDropdownMenu, { type DropdownMenuItem } from '../../components/BaseDropdownMenu.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormSelect from '../../components/FormSelect.vue';
import MetricCard from '../../components/MetricCard.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import { useToast } from '../../composables/useToast';
import { formatDisplayDate } from '../../utils/dateFormat';
import {
  supplierRegistrationsStore,
  supplierRegistrationCategoriesStore,
  type SupplierRegistrationRecord,
  businessTypeOptions,
  originOptions,
  registrationStatusOptions,
  getStatusLabel,
  getStatusBadgeColor,
  getBusinessTypeLabel,
  getOriginLabel,
  getEntityLabel
} from './supplierRegistrationData';

const router = useRouter();
const { toast } = useToast();

const breadcrumbItems: BreadcrumbItem[] = [{ label: 'Supplier Registrations' }];

// ─── Table State ─────────────────────────────────────────────────────────────
const searchQuery = ref('');
const currentPage = ref(1);
const perPage = ref(10);
const currentSort = ref('registration_number');
const sortOrder = ref<'asc' | 'desc'>('desc');

const filterBusinessType = ref('');
const filterOrigin = ref('');
const filterStatus = ref('');
const filterState = ref('');

const selectedIds = ref<number[]>([]);

const sortOptions: SortOption[] = [
  { key: 'registration_number', label: 'Registration Number' },
  { key: 'legal_name', label: 'Legal Name' },
  { key: 'submitted_at', label: 'Submitted On' },
  { key: 'status', label: 'Status' }
];

const tableColumns = ref<ColumnDef[]>([
  { key: 'registration', label: 'Registration', visible: true, sortable: true, hideable: false },
  { key: 'tin', label: 'TIN', visible: true, sortable: false },
  { key: 'business_type', label: 'Business Type', visible: true, sortable: false },
  { key: 'origin', label: 'Origin', visible: true, sortable: false },
  { key: 'verification', label: 'Email Verified', visible: true, sortable: false },
  { key: 'status', label: 'Status', visible: true, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: false },
  { key: 'actions', label: 'Actions', visible: true, sortable: false, hideable: false },
  { key: 'contact', label: 'Contact Person', visible: false, sortable: false },
  { key: 'entity', label: 'Applied To', visible: false, sortable: false },
  { key: 'submitted_at', label: 'Submitted On', visible: false, sortable: false }
]);

const isColumnVisible = (key: string) =>
  tableColumns.value.find((c) => c.key === key)?.visible !== false;

const visibleColumnCount = computed(
  () => tableColumns.value.filter((c) => c.visible !== false).length
);

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find((c) => c.key === key);
  if (col && col.hideable !== false) {
    col.visible = !col.visible;
  }
};

// ─── Metrics ─────────────────────────────────────────────────────────────────
const totalCount = computed(() => supplierRegistrationsStore.value.length);
const pendingVerificationCount = computed(
  () =>
    supplierRegistrationsStore.value.filter(
      (r) => r.supplier_registration_status_lookup_value_id === 'pending_verification'
    ).length
);
const pendingReviewCount = computed(
  () =>
    supplierRegistrationsStore.value.filter(
      (r) => r.supplier_registration_status_lookup_value_id === 'pending_review'
    ).length
);
const approvedCount = computed(
  () =>
    supplierRegistrationsStore.value.filter(
      (r) => r.supplier_registration_status_lookup_value_id === 'approved'
    ).length
);

// ─── Filtering & Sorting ─────────────────────────────────────────────────────
const activeFilterCount = computed(() => {
  let count = 0;
  if (filterBusinessType.value) count += 1;
  if (filterOrigin.value) count += 1;
  if (filterStatus.value) count += 1;
  if (filterState.value) count += 1;
  return count;
});

const resetFilters = () => {
  filterBusinessType.value = '';
  filterOrigin.value = '';
  filterStatus.value = '';
  filterState.value = '';
  currentPage.value = 1;
};

const filteredRegistrations = computed(() => {
  const q = searchQuery.value.trim().toLowerCase();
  let rows = supplierRegistrationsStore.value.filter((r) => {
    if (filterBusinessType.value && r.business_type_lookup_value_id !== filterBusinessType.value) return false;
    if (filterOrigin.value && r.origin_lookup_value_id !== filterOrigin.value) return false;
    if (
      filterStatus.value &&
      r.supplier_registration_status_lookup_value_id !== filterStatus.value
    ) {
      return false;
    }
    if (filterState.value && r.state !== filterState.value) return false;
    if (!q) return true;
    return (
      r.registration_number.toLowerCase().includes(q) ||
      r.legal_name.toLowerCase().includes(q) ||
      r.trade_name.toLowerCase().includes(q) ||
      r.tin.toLowerCase().includes(q) ||
      r.email.toLowerCase().includes(q) ||
      r.contact_person_name.toLowerCase().includes(q)
    );
  });

  rows = rows.slice().sort((a, b) => {
    let cmp = 0;
    if (currentSort.value === 'legal_name') {
      cmp = a.legal_name.localeCompare(b.legal_name);
    } else if (currentSort.value === 'submitted_at') {
      cmp = (a.submitted_at ?? '').localeCompare(b.submitted_at ?? '');
    } else if (currentSort.value === 'status') {
      cmp = a.supplier_registration_status_lookup_value_id.localeCompare(
        b.supplier_registration_status_lookup_value_id
      );
    } else {
      cmp = a.registration_number.localeCompare(b.registration_number);
    }
    return sortOrder.value === 'asc' ? cmp : -cmp;
  });

  return rows;
});

const paginatedRegistrations = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredRegistrations.value.slice(start, start + perPage.value);
});

// ─── Selection ───────────────────────────────────────────────────────────────
const isAllPageSelected = computed(() => {
  if (paginatedRegistrations.value.length === 0) return false;
  return paginatedRegistrations.value.every((r) => selectedIds.value.includes(r.id));
});

const toggleSelectAllPage = (checked: boolean) => {
  if (checked) {
    const merged = new Set([...selectedIds.value, ...paginatedRegistrations.value.map((r) => r.id)]);
    selectedIds.value = Array.from(merged);
  } else {
    const pageSet = new Set(paginatedRegistrations.value.map((r) => r.id));
    selectedIds.value = selectedIds.value.filter((id) => !pageSet.has(id));
  }
};

const toggleSelectRow = (id: number, checked: boolean) => {
  if (checked) {
    if (!selectedIds.value.includes(id)) selectedIds.value.push(id);
  } else {
    selectedIds.value = selectedIds.value.filter((x) => x !== id);
  }
};

const selectAllFiltered = () => {
  selectedIds.value = filteredRegistrations.value.map((r) => r.id);
};

// ─── Actions ─────────────────────────────────────────────────────────────────
const goToCreate = () => router.push('/procurement/supplier-registrations/create');
const goToDetail = (r: SupplierRegistrationRecord) =>
  router.push(`/procurement/supplier-registrations/${r.id}`);
const goToEdit = (r: SupplierRegistrationRecord) =>
  router.push(`/procurement/supplier-registrations/${r.id}/edit`);

const isEditable = (r: SupplierRegistrationRecord) =>
  ['draft', 'returned'].includes(r.supplier_registration_status_lookup_value_id);

const removeRegistrations = (ids: number[]) => {
  const set = new Set(ids);
  supplierRegistrationCategoriesStore.value = supplierRegistrationCategoriesStore.value.filter(
    (c) => !set.has(c.supplier_registration_id)
  );
  supplierRegistrationsStore.value = supplierRegistrationsStore.value.filter((r) => !set.has(r.id));
  selectedIds.value = selectedIds.value.filter((id) => !set.has(id));
};

const handleToggleState = (r: SupplierRegistrationRecord) => {
  r.state = r.state === 'active' ? 'inactive' : 'active';
  toast.success(`${r.registration_number} marked as ${r.state === 'active' ? 'Active' : 'Inactive'}.`);
};

const handleDelete = (r: SupplierRegistrationRecord) => {
  removeRegistrations([r.id]);
  toast.success(`Registration "${r.registration_number}" deleted.`);
};

const handleBulkDelete = () => {
  const deletable = supplierRegistrationsStore.value
    .filter((r) => selectedIds.value.includes(r.id) && r.supplier_registration_status_lookup_value_id === 'draft')
    .map((r) => r.id);
  if (deletable.length === 0) {
    toast.error('Only draft registrations can be deleted.');
    return;
  }
  removeRegistrations(deletable);
  toast.success(`${deletable.length} draft registration(s) deleted.`);
};

const getActionItems = (r: SupplierRegistrationRecord): DropdownMenuItem[] => [
  { key: 'view', label: 'View Details', icon: Eye, onClick: () => goToDetail(r) },
  { key: 'edit', label: 'Edit Record', icon: Edit2, disabled: !isEditable(r), onClick: () => goToEdit(r) },
  {
    key: 'toggle',
    label: r.state === 'active' ? 'Deactivate' : 'Activate',
    icon: r.state === 'active' ? X : Check,
    onClick: () => handleToggleState(r)
  },
  { key: 'divider', divider: true },
  {
    key: 'delete',
    label: 'Delete',
    icon: Trash2,
    destructive: true,
    disabled: r.supplier_registration_status_lookup_value_id !== 'draft',
    onClick: () => handleDelete(r)
  }
];
</script>

<template>
  <div class="supplier-registrations-page">
    <AppBreadcrumb :items="breadcrumbItems" :noMargin="true" />

    <div class="metrics-grid">
      <MetricCard
        label="Total Registrations"
        :value="totalCount"
        subtext="All supplier applications"
        :icon="UserCheck"
        :show-menu="false"
      />
      <MetricCard
        label="Pending Verification"
        :value="pendingVerificationCount"
        subtext="Awaiting email and phone confirmation"
        :icon="Clock"
        :show-menu="false"
      />
      <MetricCard
        label="Pending Review"
        :value="pendingReviewCount"
        subtext="Awaiting officer decision"
        :icon="FileCheck"
        :show-menu="false"
      />
      <MetricCard
        label="Approved"
        :value="approvedCount"
        subtext="Core supplier created"
        :icon="ShieldCheck"
        :show-menu="false"
      />
    </div>

    <AppDataTable
      title="Supplier Registrations"
      subtitle="Officer-entered supplier applications, their verification progress, and the categories requested for approval."
      v-model:searchQuery="searchQuery"
      searchPlaceholder="Search by number, legal name, TIN, or contact..."
      :showSearch="true"
      :showFilter="true"
      :filterCount="activeFilterCount"
      :showSort="true"
      :sortOptions="sortOptions"
      v-model:currentSort="currentSort"
      v-model:sortOrder="sortOrder"
      :showColumns="true"
      :columns="tableColumns"
      :showFullscreen="true"
      :totalEntries="filteredRegistrations.length"
      v-model:currentPage="currentPage"
      v-model:perPage="perPage"
      @toggleColumn="handleToggleColumn"
      @resetFilter="resetFilters"
    >
      <template #actions>
        <AppButton variant="primary" size="sm" @click="goToCreate">
          <template #icon-left><Plus :size="15" /></template>
          Create Registration
        </AppButton>
      </template>

      <template #filter-panel>
        <div class="filter-panel-grid">
          <FormSelect
            v-model="filterBusinessType"
            label="Business Type"
            :options="[{ value: '', label: 'All Business Types' }, ...businessTypeOptions]"
            placeholder="Select Type"
          />
          <FormSelect
            v-model="filterOrigin"
            label="Origin"
            :options="[{ value: '', label: 'All Origins' }, ...originOptions]"
            placeholder="Select Origin"
          />
          <FormSelect
            v-model="filterStatus"
            label="Status"
            :options="[{ value: '', label: 'All Statuses' }, ...registrationStatusOptions]"
            placeholder="Select Status"
          />
          <FormSelect
            v-model="filterState"
            label="State"
            :options="[
              { value: '', label: 'All States' },
              { value: 'active', label: 'Active' },
              { value: 'inactive', label: 'Inactive' }
            ]"
            placeholder="Select State"
          />
        </div>
        <div v-if="activeFilterCount > 0" class="filter-panel-footer">
          <AppButton variant="outline" size="sm" @click="resetFilters">Reset Filters</AppButton>
        </div>
      </template>

      <table class="erp-table">
        <thead>
          <tr>
            <th class="th-lead">
              <div class="lead-cell-wrap">
                <FormCheckbox
                  :modelValue="isAllPageSelected"
                  @update:modelValue="(v: boolean) => toggleSelectAllPage(Boolean(v))"
                />
                <span>Registration</span>
              </div>
            </th>
            <th v-if="isColumnVisible('tin')">TIN</th>
            <th v-if="isColumnVisible('business_type')">Business Type</th>
            <th v-if="isColumnVisible('origin')">Origin</th>
            <th v-if="isColumnVisible('verification')">Email Verified</th>
            <th v-if="isColumnVisible('contact')">Contact Person</th>
            <th v-if="isColumnVisible('entity')">Applied To</th>
            <th v-if="isColumnVisible('submitted_at')">Submitted On</th>
            <th v-if="isColumnVisible('status')">Status</th>
            <th v-if="isColumnVisible('state')">State</th>
            <th v-if="isColumnVisible('actions')" class="th-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="paginatedRegistrations.length === 0">
            <td :colspan="visibleColumnCount" class="empty-row-cell">
              <div class="empty-state-box">
                <UserCheck :size="32" class="empty-state-icon" />
                <p class="empty-state-title">No supplier registrations found</p>
                <p class="empty-state-sub">
                  Adjust your search or filters, or create a new supplier registration.
                </p>
              </div>
            </td>
          </tr>

          <tr
            v-for="reg in paginatedRegistrations"
            :key="reg.id"
            class="erp-row"
            :class="{ 'row-selected': selectedIds.includes(reg.id) }"
            @click="goToDetail(reg)"
          >
            <td class="td-lead" @click.stop>
              <div class="lead-cell-wrap">
                <FormCheckbox
                  :modelValue="selectedIds.includes(reg.id)"
                  @update:modelValue="(v: boolean) => toggleSelectRow(reg.id, Boolean(v))"
                />
                <BaseAvatar :src="reg.logo_url" :name="reg.legal_name" size="sm" />
                <div class="lead-text-stack" @click="goToDetail(reg)">
                  <span class="cell-primary-title">{{ reg.legal_name }}</span>
                  <span class="cell-subtext">{{ reg.registration_number }}</span>
                </div>
              </div>
            </td>

            <td v-if="isColumnVisible('tin')">
              <span class="tertiary-plain-text">{{ reg.tin }}</span>
            </td>

            <td v-if="isColumnVisible('business_type')">
              <span class="tertiary-plain-text">
                {{ getBusinessTypeLabel(reg.business_type_lookup_value_id) }}
              </span>
            </td>

            <td v-if="isColumnVisible('origin')">
              <span class="tertiary-plain-text">{{ getOriginLabel(reg.origin_lookup_value_id) }}</span>
            </td>

            <td v-if="isColumnVisible('verification')">
              <span class="tertiary-plain-text">
                {{ reg.email_verified_at ? formatDisplayDate(reg.email_verified_at) : 'Not verified' }}
              </span>
            </td>

            <td v-if="isColumnVisible('contact')">
              <span class="tertiary-plain-text">{{ reg.contact_person_name }}</span>
            </td>

            <td v-if="isColumnVisible('entity')">
              <span class="tertiary-plain-text">{{ getEntityLabel(reg.entity_id) }}</span>
            </td>

            <td v-if="isColumnVisible('submitted_at')">
              <span class="tertiary-plain-text">{{ formatDisplayDate(reg.submitted_at) }}</span>
            </td>

            <td v-if="isColumnVisible('status')">
              <BaseBadge
                size="sm"
                :color="getStatusBadgeColor(reg.supplier_registration_status_lookup_value_id)"
              >
                {{ getStatusLabel(reg.supplier_registration_status_lookup_value_id) }}
              </BaseBadge>
            </td>

            <td v-if="isColumnVisible('state')">
              <BaseBadge size="sm" :color="reg.state === 'active' ? 'success' : 'gray'">
                {{ reg.state === 'active' ? 'Active' : 'Inactive' }}
              </BaseBadge>
            </td>

            <td v-if="isColumnVisible('actions')" class="td-actions" @click.stop>
              <BaseDropdownMenu :items="getActionItems(reg)" minWidth="188px">
                <template #trigger="{ toggle }">
                  <button
                    type="button"
                    class="btn-action-dots"
                    title="Registration Actions"
                    @click.stop="toggle"
                  >
                    <MoreVertical :size="18" />
                  </button>
                </template>
              </BaseDropdownMenu>
            </td>
          </tr>
        </tbody>
      </table>
    </AppDataTable>

    <TableFloatingBar
      :show="selectedIds.length > 0"
      :selectedCount="selectedIds.length"
      :totalCount="filteredRegistrations.length"
      :showChangeStatus="false"
      :showDuplicate="false"
      :showEdit="false"
      :showMore="false"
      @selectAll="selectAllFiltered"
      @clear="selectedIds = []"
      @delete="handleBulkDelete"
    />
  </div>
</template>

<style scoped>
.supplier-registrations-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

.filter-panel-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  padding: 16px;
}

.filter-panel-footer {
  display: flex;
  justify-content: flex-end;
  padding: 10px 16px;
  border-top: 1px solid #e5e5e5;
  background-color: #fafafa;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table thead th {
  height: 44px;
  padding: 0 16px;
  background-color: #fafafa;
  border-bottom: 1px solid #e9eaeb;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
  white-space: nowrap;
}

.erp-table thead th.th-lead {
  padding-left: 24px;
}

.erp-table thead th.th-actions {
  text-align: center;
  padding-right: 24px;
  width: 80px;
}

.erp-row {
  height: 72px;
  border-bottom: 1px solid #e9eaeb;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.erp-row:hover {
  background-color: #fafafa;
}

.erp-row.row-selected {
  background-color: #f1f7fe;
}

.erp-table tbody td {
  padding: 12px 16px;
  vertical-align: middle;
}

.erp-table tbody td.td-lead {
  padding-left: 24px;
}

.erp-table tbody td.td-actions {
  text-align: center;
  padding-right: 24px;
}

.lead-cell-wrap {
  display: flex;
  align-items: center;
  gap: 12px;
}

.lead-text-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.cell-primary-title {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

.cell-subtext {
  font-size: 12px;
  color: #737373;
}

.tertiary-plain-text {
  font-size: 13.5px;
  color: #737373;
}

.btn-action-dots {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: none;
  background: transparent;
  color: #737373;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  outline: none !important;
  box-shadow: none !important;
  -webkit-tap-highlight-color: transparent !important;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.empty-row-cell {
  padding: 48px 24px !important;
  text-align: center;
}

.empty-state-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.empty-state-icon {
  color: #737373;
  margin-bottom: 4px;
}

.empty-state-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.empty-state-sub {
  margin: 0;
  font-size: 13px;
  color: #737373;
}

@media (max-width: 1120px) {
  .metrics-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 640px) {
  .metrics-grid {
    grid-template-columns: 1fr;
  }
}
</style>

