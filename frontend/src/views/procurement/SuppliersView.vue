<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  LayoutGrid, List, Star, MoreVertical, Eye,
  Ban, RotateCcw, Search, AlertCircle, AlertTriangle,
  ArrowRight, FileText, ShieldAlert
} from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable, { type ColumnDef, type SortOption } from '../../components/AppDataTable.vue';
import BaseAlert from '../../components/BaseAlert.vue';
import BaseAvatar from '../../components/BaseAvatar.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import BadgeGroup from '../../components/BadgeGroup.vue';
import BaseDropdownMenu, { type DropdownMenuItem } from '../../components/BaseDropdownMenu.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormSelect from '../../components/FormSelect.vue';
import { useToast } from '../../composables/useToast';
import { formatDisplayDate } from '../../utils/dateFormat';
import StarRating from '../../components/StarRating.vue';
import SupplierRatingModal from './SupplierRatingModal.vue';
import {
  suppliersStore,
  type SupplierRecord,
  formatCurrency,
  getEligibilityBadgeColor,
  getEligibilityLabel,
  getRiskBadgeColor,
  getRiskLabel,
  getGradeBadgeColor,
  getGradeLabel
} from './supplierData';

const router = useRouter();
const { toast } = useToast();

const breadcrumbItems: BreadcrumbItem[] = [{ label: 'Supplier Hub' }];

// ─── View Mode (Card View Default + Table View Tab — LeavePoliciesView Pattern)
type ViewMode = 'cards' | 'table';
const viewMode = ref<ViewMode>('cards');
const viewTabs: BaseTabItem<ViewMode>[] = [
  { id: 'cards', label: 'Card View', icon: LayoutGrid },
  { id: 'table', label: 'Table View', icon: List }
];

// ─── Search, Filter & Sort State ─────────────────────────────────────────────
const showRiskAlert = ref(true);
const searchQuery = ref('');
const filterOrigin = ref('');
const filterStatus = ref('');
const filterRisk = ref('');
const currentSort = ref('legal_name');
const sortOrder = ref<'asc' | 'desc'>('asc');
const currentPage = ref(1);
const perPage = ref(10);
const selectedIds = ref<number[]>([]);

const sortOptions: SortOption[] = [
  { key: 'legal_name', label: 'Supplier Name' },
  { key: 'rating', label: 'Scorecard Rating' },
  { key: 'risk_score', label: 'Risk Score' },
  { key: 'qualified_to', label: 'Qualification Expiry' }
];

const tableColumns = ref<ColumnDef[]>([
  { key: 'supplier', label: 'Supplier', visible: true, sortable: true, hideable: false },
  { key: 'categories', label: 'Approved Categories', visible: true, sortable: false },
  { key: 'rating', label: 'Rating', visible: true, sortable: true },
  { key: 'risk', label: 'Risk Level', visible: true, sortable: true },
  { key: 'qualified_to', label: 'Qualified Until', visible: true, sortable: true },
  { key: 'status', label: 'Status', visible: true, sortable: false },
  { key: 'actions', label: 'Actions', visible: true, sortable: false, hideable: false },
  { key: 'origin', label: 'Origin', visible: false, sortable: false },
  { key: 'max_order', label: 'Max Order Cap', visible: false, sortable: false }
]);

const isColVisible = (key: string) =>
  tableColumns.value.find((c) => c.key === key)?.visible !== false;

const visibleColCount = computed(() => tableColumns.value.filter((c) => c.visible !== false).length);

const handleToggleColumn = (key: string) => {
  const col = tableColumns.value.find((c) => c.key === key);
  if (col && col.hideable !== false) col.visible = !col.visible;
};

const activeFilterCount = computed(() => {
  let c = 0;
  if (filterOrigin.value) c += 1;
  if (filterStatus.value) c += 1;
  if (filterRisk.value) c += 1;
  return c;
});

const resetFilters = () => {
  filterOrigin.value = '';
  filterStatus.value = '';
  filterRisk.value = '';
  currentPage.value = 1;
};

const filteredSuppliers = computed(() => {
  const q = searchQuery.value.trim().toLowerCase();
  let rows = suppliersStore.value.filter((s) => {
    if (filterOrigin.value && s.origin !== filterOrigin.value) return false;
    if (filterStatus.value && s.eligibility_status !== filterStatus.value) return false;
    if (filterRisk.value && s.risk.risk_level !== filterRisk.value) return false;
    if (!q) return true;
    return (
      s.legal_name.toLowerCase().includes(q) ||
      s.code.toLowerCase().includes(q) ||
      s.tin.toLowerCase().includes(q) ||
      s.categories.some((c) => c.category_name.toLowerCase().includes(q))
    );
  });

  rows = rows.slice().sort((a, b) => {
    let cmp = 0;
    if (currentSort.value === 'rating') {
      cmp = (a.scorecard?.overall_score ?? -1) - (b.scorecard?.overall_score ?? -1);
    } else if (currentSort.value === 'risk_score') {
      cmp = a.risk.risk_score - b.risk.risk_score;
    } else if (currentSort.value === 'qualified_to') {
      cmp = a.qualification.qualified_to.localeCompare(b.qualification.qualified_to);
    } else {
      cmp = a.legal_name.localeCompare(b.legal_name);
    }
    return sortOrder.value === 'asc' ? cmp : -cmp;
  });

  return rows;
});

const paginatedSuppliers = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredSuppliers.value.slice(start, start + perPage.value);
});

const isAllPageSelected = computed(() => {
  if (paginatedSuppliers.value.length === 0) return false;
  return paginatedSuppliers.value.every((s) => selectedIds.value.includes(s.id));
});

const toggleSelectAll = (checked: boolean) => {
  if (checked) {
    selectedIds.value = Array.from(
      new Set([...selectedIds.value, ...paginatedSuppliers.value.map((s) => s.id)])
    );
  } else {
    const pageSet = new Set(paginatedSuppliers.value.map((s) => s.id));
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

// ─── Live Risk & Compliance Flags (from SupplierRiskEvent / RiskProfile / Docs)
const activeRiskFlags = computed(() => {
  const flags: Array<{
    key: string;
    supplierId: number;
    supplierName: string;
    badge: string;
    shortLabel: string;
    summaryClause: string;
  }> = [];

  for (const s of suppliersStore.value) {
    if (s.risk.requires_dual_approval) {
      flags.push({
        key: `dual-${s.id}`,
        supplierId: s.id,
        supplierName: s.legal_name,
        badge: 'Dual Approval',
        shortLabel: `Risk ${s.risk.risk_score}`,
        summaryClause: `requires secondary PO sign-off (Risk ${s.risk.risk_score})`
      });
    }
    for (const ev of s.risk.events) {
      if (ev.status === 'open') {
        flags.push({
          key: `ev-${s.id}-${ev.id}`,
          supplierId: s.id,
          supplierName: s.legal_name,
          badge: `${ev.risk_level.toUpperCase()} Risk`,
          shortLabel: ev.event_type === 'late_delivery' ? 'Late Cold-Chain Deliveries' : ev.description,
          summaryClause: `has ${ev.description.charAt(0).toLowerCase()}${ev.description.slice(1).replace(/\.$/, '')}`
        });
      }
    }
    for (const doc of s.documents) {
      if (doc.review_result === 'non_compliant') {
        flags.push({
          key: `doc-${s.id}-${doc.id}`,
          supplierId: s.id,
          supplierName: s.legal_name,
          badge: 'Doc Flag',
          shortLabel: `${doc.document_type} Non-Compliant`,
          summaryClause: `a non-compliant ${doc.document_type}`
        });
      }
    }
  }
  return flags;
});

const riskAlertSummary = computed(() => {
  const flags = activeRiskFlags.value;
  if (flags.length === 0) return '';
  const leadSupplier = flags[0].supplierName;
  const clauses = flags.slice(0, 3).map((f) => f.summaryClause);
  if (clauses.length === 1) return `${leadSupplier} ${clauses[0]}.`;
  if (clauses.length === 2) return `${leadSupplier} ${clauses[0]} and ${clauses[1]}.`;
  return `${leadSupplier} ${clauses[0]}, ${clauses[1]}, and ${clauses[2]}.`;
});

// ─── Actions ─────────────────────────────────────────────────────────────────
const goToDetail = (s: SupplierRecord, tab?: string) =>
  router.push(tab ? { path: `/procurement/suppliers/${s.id}`, query: { tab } } : `/procurement/suppliers/${s.id}`);
const goToSupplierById = (id: number) => router.push(`/procurement/suppliers/${id}`);

const getStarRatingValue = (s: SupplierRecord) => {
  if (!s.scorecard) return 0;
  const score = s.scorecard.overall_score;
  if (score <= 0) return 0;
  return Math.max(0.5, Math.min(5, Math.round((score / 20) * 2) / 2));
};

// ─── Interactive Clickable Star Rating (Card View & Table View) ──────────────
const showRatingModal = ref(false);
const ratingTargetSupplier = ref<SupplierRecord | null>(null);
const ratingInitialStars = ref(4);

const openRatingModalFor = (s: SupplierRecord, clickedStars: number) => {
  ratingTargetSupplier.value = s;
  ratingInitialStars.value = clickedStars;
  showRatingModal.value = true;
};

const toggleSuspend = (s: SupplierRecord) => {
  const now = new Date();
  const today = now.toISOString().split('T')[0];
  const timestamp = `${today} ${now.toTimeString().slice(0, 5)}`;
  const prev = s.eligibility_status;

  if (s.eligibility_status === 'active') {
    s.eligibility_status = 'suspended';
    s.status_logs.unshift({
      id: Date.now(),
      scope: 'Whole Supplier',
      from_status: prev,
      to_status: 'suspended',
      effective_from: today,
      effective_to: null,
      changed_at: timestamp,
      changed_by: 'Marta Tadesse',
      reason: 'Suspended from Supplier Monitoring directory.'
    });
    toast.warning(`${s.legal_name} suspended.`);
  } else {
    s.eligibility_status = 'active';
    s.status_logs.unshift({
      id: Date.now(),
      scope: 'Whole Supplier',
      from_status: prev,
      to_status: 'reinstated',
      effective_from: today,
      effective_to: null,
      changed_at: timestamp,
      changed_by: 'Marta Tadesse',
      reason: 'Reinstated to active eligibility.'
    });
    toast.success(`${s.legal_name} reinstated.`);
  }
};

const getRowActionItems = (s: SupplierRecord): DropdownMenuItem[] => [
  { key: 'view', label: 'View 360° Profile', icon: Eye, onClick: () => goToDetail(s) },
  { key: 'rate', label: 'Record Performance', icon: Star, onClick: () => goToDetail(s, 'performance') },
  { key: 'risk', label: 'Log Risk Event', icon: ShieldAlert, onClick: () => goToDetail(s, 'risk') },
  { key: 'prices', label: 'Manage Price Lists', icon: FileText, onClick: () => goToDetail(s, 'price_lists') },
  { key: 'div', divider: true },
  {
    key: 'suspend',
    label: s.eligibility_status === 'active' ? 'Suspend Supplier' : 'Reinstate Supplier',
    icon: s.eligibility_status === 'active' ? Ban : RotateCcw,
    destructive: s.eligibility_status === 'active',
    onClick: () => toggleSuspend(s)
  }
];

const formatCategoriesSummary = (s: SupplierRecord) => {
  const active = s.categories.filter((c) => c.status === 'active');
  if (active.length === 0) return 'No active categories';
  const names = active.slice(0, 2).map((c) => c.category_name).join(', ');
  return active.length > 2 ? `${names} +${active.length - 2}` : names;
};
</script>

<template>
  <div class="suppliers-page">
    <AppBreadcrumb :items="breadcrumbItems" :noMargin="true" />

    <!-- Top Header Card (Monitoring View: Title + Card/Table Tabs, no Register CTA) -->
    <div class="suppliers-top-card">
      <div class="header-main-row">
        <div class="header-text-block">
          <h1 class="page-title">Supplier Hub</h1>
          <p class="page-subtitle">
            Monitor active suppliers, risk flags, scorecard ratings, compliance expiries, and agreed price lists.
          </p>
        </div>
      </div>

      <!-- Live Risk & Compliance Alert Banner (QMT Alert - 2: Figma 10777:61788) -->
      <BaseAlert
        v-if="showRiskAlert && activeRiskFlags.length > 0"
        type="subtle"
        status="warning"
        :title="`${activeRiskFlags.length} Active Supplier Risk & Compliance Flag(s)`"
        :description="riskAlertSummary"
        :closable="true"
        @close="showRiskAlert = false"
      >
        <template #icon>
          <AlertTriangle :size="20" />
        </template>
        <template #badges>
          <BadgeGroup
            v-for="flag in activeRiskFlags.slice(0, 3)"
            :key="flag.key"
            :badgeLabel="flag.badge"
            :message="flag.shortLabel"
            color="warning"
            size="md"
            :clickable="true"
            @click="goToSupplierById(flag.supplierId)"
          />
        </template>
      </BaseAlert>

      <div class="header-tabs-row">
        <BaseTabs v-model="viewMode" :tabs="viewTabs" type="rounded" size="sm" />

        <div v-if="viewMode === 'cards'" class="cards-search-box">
          <Search :size="16" class="search-icon" />
          <input
            v-model="searchQuery"
            type="text"
            class="cards-search-input"
            placeholder="Search suppliers..."
          />
        </div>
      </div>
    </div>

    <!-- VIEW 1: SUPPLIER CARDS VIEW (DEFAULT — Figma 10734:32445) -->
    <div v-if="viewMode === 'cards'" class="cards-view-wrapper">
      <div v-if="filteredSuppliers.length > 0" class="supplier-cards-grid">
        <div
          v-for="supplier in filteredSuppliers"
          :key="supplier.id"
          class="supplier-card"
          @click="goToDetail(supplier)"
        >
          <!-- Top Section (16px bottom padding + 1px #E5E5E5 subtle divider) -->
          <div class="card-top-section">
            <div class="card-identity">
              <BaseAvatar
                :src="supplier.logo_url"
                :name="supplier.legal_name"
                size="md"
                status="company"
                :placeholder="!supplier.logo_url"
                :bordered="true"
              />
              <div class="card-identity-text">
                <h3 class="card-supplier-name">{{ supplier.legal_name }}</h3>
                <span class="card-supplier-sub">
                  {{ supplier.code }} • {{ supplier.origin === 'local' ? 'Local' : 'Foreign' }} • {{ supplier.business_type }}
                </span>
              </div>
            </div>

            <div class="card-top-right">
              <!-- Interactive Half-Star Rating Stack (Click any star/half-star to rate) -->
              <div class="card-rating-stack" @click.stop>
                <StarRating
                  :model-value="getStarRatingValue(supplier)"
                  :size="17"
                  :interactive="true"
                  :allow-half="true"
                  :aria-label="supplier.scorecard ? `${supplier.scorecard.overall_score} out of 100` : 'Click a star to rate'"
                  @select="(val) => openRatingModalFor(supplier, val)"
                />
                <div v-if="supplier.scorecard" class="rating-meta-line">
                  <span class="rating-score">{{ Math.round(supplier.scorecard.overall_score) }}</span>
                  <span class="rating-denom"> / 100 • {{ getGradeLabel(supplier.scorecard.grade) }}</span>
                </div>
                <span v-else class="rating-unrated">Not rated yet</span>
              </div>

              <!-- 3-Dot Schema Action Menu (stops card navigation) -->
              <div class="card-actions-wrap" @click.stop>
                <BaseDropdownMenu :items="getRowActionItems(supplier)" minWidth="210px">
                  <template #trigger="{ toggle }">
                    <button
                      type="button"
                      class="btn-card-dots"
                      title="Supplier Actions"
                      aria-label="Supplier Actions"
                      @click.stop="toggle"
                    >
                      <MoreVertical :size="18" />
                    </button>
                  </template>
                </BaseDropdownMenu>
              </div>
            </div>
          </div>

          <!-- Bottom Description Section (Regular Tertiary text + Inline Sliding Arrow) -->
          <p class="card-summary-desc">
            Supplies {{ formatCategoriesSummary(supplier) }}, qualified until
            {{ formatDisplayDate(supplier.qualification.qualified_to) }} with
            {{
              supplier.qualification.maximum_order_value !== null
                ? `${formatCurrency(supplier.qualification.maximum_order_value, supplier.qualification.currency_id)} order cap`
                : 'no order cap'
            }}.
            {{ supplier.price_lists.length }} price {{ supplier.price_lists.length === 1 ? 'list' : 'lists' }}
            &amp;
            {{ supplier.portal_users.length }} portal {{ supplier.portal_users.length === 1 ? 'user' : 'users' }}
            active.<ArrowRight :size="14" class="desc-inline-arrow" aria-hidden="true" />
          </p>
        </div>
      </div>

      <div v-else class="cards-empty-state">
        <AlertCircle :size="32" class="empty-icon" />
        <p class="empty-title">No suppliers found</p>
        <p class="empty-desc">Adjust your search or register a new supplier to get started.</p>
      </div>
    </div>

    <!-- VIEW 2: TABLE VIEW -->
    <AppDataTable
      v-else
      v-model:searchQuery="searchQuery"
      searchPlaceholder="Search suppliers..."
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
      :totalEntries="filteredSuppliers.length"
      v-model:currentPage="currentPage"
      v-model:perPage="perPage"
      @toggleColumn="handleToggleColumn"
      @resetFilter="resetFilters"
    >
      <template #filter-panel>
        <div class="filter-panel-grid">
          <FormSelect
            v-model="filterOrigin"
            label="Origin"
            :options="[
              { value: '', label: 'All Origins' },
              { value: 'local', label: 'Local' },
              { value: 'foreign', label: 'Foreign' }
            ]"
            placeholder="Select Origin"
          />
          <FormSelect
            v-model="filterStatus"
            label="Status"
            :options="[
              { value: '', label: 'All Statuses' },
              { value: 'active', label: 'Active' },
              { value: 'suspended', label: 'Suspended' },
              { value: 'blacklisted', label: 'Blacklisted' },
              { value: 'expired', label: 'Expired' }
            ]"
            placeholder="Select Status"
          />
          <FormSelect
            v-model="filterRisk"
            label="Risk Level"
            :options="[
              { value: '', label: 'All Risk Levels' },
              { value: 'low', label: 'Low Risk' },
              { value: 'medium', label: 'Medium Risk' },
              { value: 'high', label: 'High Risk' }
            ]"
            placeholder="Select Risk"
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
                  @update:modelValue="(v: boolean) => toggleSelectAll(Boolean(v))"
                />
                <span>Supplier</span>
              </div>
            </th>
            <th v-if="isColVisible('categories')">Approved Categories</th>
            <th v-if="isColVisible('rating')">Rating</th>
            <th v-if="isColVisible('risk')">Risk Level</th>
            <th v-if="isColVisible('qualified_to')">Qualified Until</th>
            <th v-if="isColVisible('origin')">Origin</th>
            <th v-if="isColVisible('max_order')">Max Order Cap</th>
            <th v-if="isColVisible('status')">Status</th>
            <th v-if="isColVisible('actions')" class="th-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="paginatedSuppliers.length === 0">
            <td :colspan="visibleColCount" class="empty-row-cell">No suppliers found.</td>
          </tr>
          <tr
            v-for="supplier in paginatedSuppliers"
            :key="supplier.id"
            class="erp-row"
            :class="{ 'row-selected': selectedIds.includes(supplier.id) }"
            @click="goToDetail(supplier)"
          >
            <td class="td-lead" @click.stop>
              <div class="lead-cell-wrap">
                <FormCheckbox
                  :modelValue="selectedIds.includes(supplier.id)"
                  @update:modelValue="(v: boolean) => toggleSelectRow(supplier.id, Boolean(v))"
                />
                <BaseAvatar
                  :src="supplier.logo_url"
                  :name="supplier.legal_name"
                  size="md"
                  status="company"
                  :placeholder="!supplier.logo_url"
                />
                <div class="lead-text-stack" @click="goToDetail(supplier)">
                  <span class="cell-primary-title">{{ supplier.legal_name }}</span>
                  <span class="cell-subtext">{{ supplier.code }} • TIN {{ supplier.tin }}</span>
                </div>
              </div>
            </td>
            <td v-if="isColVisible('categories')">
              <span class="tertiary-plain-text">{{ formatCategoriesSummary(supplier) }}</span>
            </td>
            <td v-if="isColVisible('rating')" @click.stop>
              <div
                class="table-rating-cell"
                :title="supplier.scorecard ? `${supplier.scorecard.overall_score.toFixed(1)} / 100 (${getGradeLabel(supplier.scorecard.grade)}) — click a star to rate` : 'Click a star to rate'"
              >
                <StarRating
                  :model-value="getStarRatingValue(supplier)"
                  :size="20"
                  :interactive="true"
                  :allow-half="true"
                  :aria-label="`Rate ${supplier.legal_name}`"
                  @select="(val) => openRatingModalFor(supplier, val)"
                />
              </div>
            </td>
            <td v-if="isColVisible('risk')">
              <BaseBadge size="sm" :color="getRiskBadgeColor(supplier.risk.risk_level)">
                {{ getRiskLabel(supplier.risk.risk_level) }}
              </BaseBadge>
            </td>
            <td v-if="isColVisible('qualified_to')">
              <span class="tertiary-plain-text">
                {{ formatDisplayDate(supplier.qualification.qualified_to) }}
              </span>
            </td>
            <td v-if="isColVisible('origin')">
              <span class="tertiary-plain-text">
                {{ supplier.origin === 'local' ? 'Local' : 'Foreign' }}
              </span>
            </td>
            <td v-if="isColVisible('max_order')">
              <span class="tertiary-plain-text">
                {{
                  supplier.qualification.maximum_order_value !== null
                    ? formatCurrency(supplier.qualification.maximum_order_value, supplier.qualification.currency_id)
                    : 'No Cap'
                }}
              </span>
            </td>
            <td v-if="isColVisible('status')">
              <BaseBadge size="sm" :color="getEligibilityBadgeColor(supplier.eligibility_status)">
                {{ getEligibilityLabel(supplier.eligibility_status) }}
              </BaseBadge>
            </td>
            <td v-if="isColVisible('actions')" class="td-actions" @click.stop>
              <BaseDropdownMenu :items="getRowActionItems(supplier)" minWidth="190px">
                <template #trigger="{ toggle }">
                  <button type="button" class="btn-action-dots" title="Actions" @click.stop="toggle">
                    <MoreVertical :size="18" />
                  </button>
                </template>
              </BaseDropdownMenu>
            </td>
          </tr>
        </tbody>
      </table>
    </AppDataTable>

    <SupplierRatingModal
      v-model="showRatingModal"
      :supplier="ratingTargetSupplier"
      :initial-stars="ratingInitialStars"
    />
  </div>
</template>

<style scoped>
.suppliers-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.suppliers-top-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.header-main-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
}

.header-text-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.page-title {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: #404040;
}

.page-subtitle {
  margin: 0;
  font-size: 14px;
  color: #737373;
}

.header-tabs-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.cards-search-box {
  position: relative;
  width: 340px;
  max-width: 100%;
}

.search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #737373;
  pointer-events: none;
}

.cards-search-input {
  width: 100%;
  height: 38px;
  padding: 0 14px 0 36px;
  border: 1px solid #d4d4d4;
  border-radius: 8px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  outline: none;
}

.cards-search-input:focus {
  border-color: #404040;
}

/* Risk Alert Banner */
.risk-alert-banner {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 14px 16px;
  background-color: #fffbeb;
  border: 1px solid #ffd230;
  border-radius: 12px;
}

.risk-alert-lead {
  display: flex;
  align-items: center;
  gap: 8px;
}

.risk-alert-icon {
  color: #e17100;
  flex-shrink: 0;
}

.risk-alert-title {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.risk-alert-items {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

/* Balanced 2-Column Supplier Cards Grid (Figma 10734:32445) */
.supplier-cards-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.supplier-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 14px;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  cursor: pointer;
  transition: background-color 0.18s ease, border-color 0.18s ease, box-shadow 0.18s ease;
}

.supplier-card:hover {
  background-color: #fafafa;
  border-color: #d4d4d4;
  box-shadow: 0 4px 12px rgba(10, 13, 18, 0.05);
}

.supplier-card:hover .desc-inline-arrow {
  transform: translateX(4px);
  color: #0b529c;
}

.card-top-section {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding-bottom: 16px;
  border-bottom: 1px solid #e5e5e5;
}

.card-identity {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
  flex: 1;
}

.card-identity-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.card-supplier-name {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.card-supplier-sub {
  font-size: 12px;
  color: #737373;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.card-top-right {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

.card-rating-stack {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 5px;
}

.star-row {
  display: inline-flex;
  align-items: center;
  gap: 3px;
}

.rating-star-filled {
  color: #e17100;
  fill: #e17100;
  flex-shrink: 0;
}

.rating-star-empty {
  color: #d4d4d4;
  fill: transparent;
  flex-shrink: 0;
}

.rating-meta-line {
  font-size: 12px;
  line-height: 16px;
  white-space: nowrap;
}

.rating-score {
  font-size: 12px;
  font-weight: 600;
  color: #404040;
}

.rating-denom {
  font-size: 12px;
  color: #737373;
}

.rating-unrated {
  font-size: 12px;
  color: #737373;
}

.card-actions-wrap {
  display: inline-flex;
  align-items: center;
}

.btn-card-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  padding: 0;
  border: none;
  border-radius: 6px;
  background: transparent;
  color: #737373;
  cursor: pointer;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.btn-card-dots:hover {
  background-color: #efefef;
  color: #404040;
}

.card-summary-desc {
  margin: 0;
  font-size: 12.5px;
  font-weight: 400;
  line-height: 19px;
  color: #737373;
}

.desc-inline-arrow {
  display: inline-block;
  vertical-align: -2.5px;
  margin-left: 6px;
  color: #737373;
  transition: transform 0.2s cubic-bezier(0.22, 1, 0.36, 1), color 0.2s ease;
}

.cards-empty-state {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 48px 24px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.empty-icon {
  color: #737373;
}

.empty-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.empty-desc {
  margin: 0;
  font-size: 13px;
  color: #737373;
}

/* Table View */
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

.table-rating-cell {
  display: inline-flex;
  align-items: center;
  gap: 2px;
}

.star-click-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 1px;
  border: none;
  background: transparent;
  cursor: pointer;
  transition: transform 0.12s ease;
}

.star-click-btn:hover {
  transform: scale(1.12);
}

.card-star-img {
  display: block;
  width: 17px;
  height: 17px;
  flex-shrink: 0;
}

.table-star-icon {
  display: block;
  width: 20px;
  height: 20px;
  flex-shrink: 0;
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
}

.btn-action-dots:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.empty-row-cell {
  padding: 40px 24px !important;
  text-align: center;
  color: #737373;
  font-size: 13.5px;
}

@media (max-width: 1280px) {
  .supplier-cards-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 800px) {
  .supplier-cards-grid {
    grid-template-columns: 1fr;
  }
}
</style>

