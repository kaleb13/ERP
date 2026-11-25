<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRoute } from 'vue-router';
import {
  ChevronDown, ChevronRight, MoreVertical,
  Check, PauseCircle, XCircle, ExternalLink,
  Filter, X, RotateCcw,
  PanelLeft
} from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import BaseDropdownMenu, { type DropdownMenuItem } from '../../components/BaseDropdownMenu.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import { useToast } from '../../composables/useToast';
import { formatDisplayDate, formatDisplayDateRange } from '../../utils/dateFormat';

import {
  procurementPlansStore,
  getPlanVersions,
  getCurrentPlanVersion,
  getVersionLines,
  getPlanPeriodTypeLabel,
  getPlanStatusLabel,
  getPlanStatusBadgeColor,
  getPlanVersionStatusBadgeColor,
  getPlanLineStatusLabel,
  getPlanLineStatusBadgeColor,
  formatCurrencyETB,
  type ProcurementPlanVersionRecord,
  type ProcurementPlanVersionLineRecord,
  type PlanLineStatus
} from './procurementPlanData';

const route = useRoute();
const { toast } = useToast();

const planId = computed(() => Number(route.params.id));
const plan = computed(() => procurementPlansStore.value.find((p) => p.id === planId.value));
const versions = computed(() => (plan.value ? getPlanVersions(plan.value.id) : []));
const selectedVersionId = ref<string>('');

const initializeSelectedVersion = () => {
  if (!plan.value) return;
  const current = getCurrentPlanVersion(plan.value.id);
  selectedVersionId.value = current ? String(current.id) : '';
};

watch(planId, initializeSelectedVersion, { immediate: true });

const orderedVersions = computed(() =>
  versions.value.slice().sort((a, b) => b.version_number - a.version_number)
);

const activeVersion = computed(() =>
  versions.value.find((v) => String(v.id) === selectedVersionId.value) || versions.value[0]
);

const selectVersion = (versionId: number) => {
  selectedVersionId.value = String(versionId);
};

const versionLines = computed(() =>
  activeVersion.value ? getVersionLines(activeVersion.value.id) : []
);

const totalEstimated = computed(() =>
  versionLines.value.reduce((sum, l) => sum + (Number(l.estimated_amount) || 0), 0)
);

const totalActual = computed(() =>
  versionLines.value.reduce((sum, l) => sum + (Number(l.actual_amount) || 0), 0)
);

const isNotesOpen = ref(true);

// ─── Single-Approval Side Panel State (Figma 10178:33832) ────────────────────
const isPendingApproval = computed(() =>
  Boolean(
    plan.value &&
      ['submitted', 'returned', 'revised'].includes(plan.value.plan_status_lookup_value_id)
  )
);
const isFocusMode = ref(false);
const approvalResolution = ref<'approved' | 'returned' | 'rejected' | ''>('');
const approvalRemark = ref('');
const approvalResolutionError = ref<string | undefined>(undefined);
const isSubmittingDecision = ref(false);

const approvalResolutionOptions: SelectOption[] = [
  { value: 'approved', label: 'Approve Procurement Plan' },
  { value: 'returned', label: 'Return for Revision' },
  { value: 'rejected', label: 'Reject Procurement Plan' }
];

const toggleFocusMode = () => {
  isFocusMode.value = !isFocusMode.value;
  if (isFocusMode.value) {
    toast.info('Focus mode enabled — approval sidebar minimized.');
  } else {
    toast.info('Approval sidebar restored.');
  }
};

const handleSubmitApprovalDecision = () => {
  if (!plan.value) return;
  approvalResolutionError.value = undefined;
  if (!approvalResolution.value) {
    approvalResolutionError.value = 'Please select a resolution.';
    toast.error('Please select an approval resolution.');
    return;
  }
  isSubmittingDecision.value = true;
  const chosen = approvalResolution.value;
  setTimeout(() => {
    isSubmittingDecision.value = false;
    if (!plan.value) return;
    plan.value.plan_status_lookup_value_id = chosen;
    if (chosen === 'approved') {
      plan.value.approved_at = new Date().toISOString().slice(0, 16).replace('T', ' ');
      if (activeVersion.value) {
        activeVersion.value.plan_version_status_lookup_value_id = 'approved';
      }
      versionLines.value.forEach((l) => {
        if (l.plan_line_status_lookup_value_id === 'pending') {
          l.plan_line_status_lookup_value_id = 'approved';
        }
      });
      toast.success(`${plan.value.plan_number} approved and activated.`);
    } else if (chosen === 'returned') {
      toast.warning(`${plan.value.plan_number} returned for revision.`);
    } else {
      if (activeVersion.value) {
        activeVersion.value.plan_version_status_lookup_value_id = 'rejected';
      }
      toast.error(`${plan.value.plan_number} has been rejected.`);
    }
    approvalResolution.value = '';
    approvalRemark.value = '';
  }, 250);
};

// ─── Activity Log State (Figma 10679:31692) ──────────────────────────────────
const activityFilterStatus = ref<'all' | 'approved' | 'submitted' | 'rejected'>('all');

const filteredActivityVersions = computed(() => {
  return orderedVersions.value.filter((v) => {
    if (
      activityFilterStatus.value !== 'all' &&
      v.plan_version_status_lookup_value_id !== activityFilterStatus.value
    ) {
      return false;
    }
    return true;
  });
});

const activityFilterItems = computed<DropdownMenuItem[]>(() => [
  { key: 'section-status', sectionLabel: 'Filter by Version Status' },
  {
    key: 'all',
    label: 'All Statuses',
    selected: activityFilterStatus.value === 'all',
    onClick: () => {
      activityFilterStatus.value = 'all';
    }
  },
  {
    key: 'approved',
    label: 'Approved Only',
    selected: activityFilterStatus.value === 'approved',
    onClick: () => {
      activityFilterStatus.value = 'approved';
    }
  },
  {
    key: 'submitted',
    label: 'Submitted Only',
    selected: activityFilterStatus.value === 'submitted',
    onClick: () => {
      activityFilterStatus.value = 'submitted';
    }
  },
  {
    key: 'rejected',
    label: 'Rejected Only',
    selected: activityFilterStatus.value === 'rejected',
    onClick: () => {
      activityFilterStatus.value = 'rejected';
    }
  }
]);

const activityMoreItems = computed<DropdownMenuItem[]>(() => {
  const items: DropdownMenuItem[] = [];
  if (orderedVersions.value.length > 0) {
    items.push({
      key: 'latest-preview',
      label: 'See Latest Change Preview',
      icon: ExternalLink,
      onClick: () => openChangePreview(orderedVersions.value[0])
    });
    items.push({ key: 'div-1', divider: true });
  }
  items.push({
    key: 'reset-filter',
    label: 'Reset Filter',
    icon: RotateCcw,
    disabled: activityFilterStatus.value === 'all',
    onClick: () => {
      activityFilterStatus.value = 'all';
    }
  });
  return items;
});

const getLineActionItems = (line: ProcurementPlanVersionLineRecord): DropdownMenuItem[] => [
  {
    key: 'approve',
    label: 'Approve Line',
    icon: Check,
    onClick: () => updateLineStatus(line, 'approved')
  },
  {
    key: 'hold',
    label: 'Place On Hold',
    icon: PauseCircle,
    onClick: () => updateLineStatus(line, 'on_hold')
  },
  { key: 'div', divider: true },
  {
    key: 'reject',
    label: 'Reject Line',
    icon: XCircle,
    destructive: true,
    onClick: () => updateLineStatus(line, 'rejected')
  }
];

// ─── Change Preview Modal State ───────────────────────────────────────────────
const previewTargetVersion = ref<ProcurementPlanVersionRecord | null>(null);

const previewPreviousVersion = computed(() => {
  if (!previewTargetVersion.value) return null;
  const idx = orderedVersions.value.findIndex((v) => v.id === previewTargetVersion.value!.id);
  if (idx === -1 || idx + 1 >= orderedVersions.value.length) return null;
  return orderedVersions.value[idx + 1];
});

interface VersionDiffRow {
  key: string;
  itemName: string;
  changeType: 'Added' | 'Modified' | 'Removed' | 'Unchanged';
  prevQty: number | null;
  prevPrice: number | null;
  prevAmount: number | null;
  currQty: number | null;
  currPrice: number | null;
  currAmount: number | null;
  deltaAmount: number;
}

const previewDiffRows = computed<VersionDiffRow[]>(() => {
  if (!previewTargetVersion.value) return [];
  const currLines = getVersionLines(previewTargetVersion.value.id);
  const prevLines = previewPreviousVersion.value
    ? getVersionLines(previewPreviousVersion.value.id)
    : [];

  const rows: VersionDiffRow[] = [];
  const matchedPrevIds = new Set<number>();

  currLines.forEach((curr) => {
    const match =
      prevLines.find((p) => curr.carried_from_line_id && p.id === curr.carried_from_line_id) ||
      prevLines.find(
        (p) =>
          !matchedPrevIds.has(p.id) &&
          ((curr.product_id && p.product_id === curr.product_id) ||
            p.description === curr.description)
      );

    if (match) {
      matchedPrevIds.add(match.id);
      const changed =
        match.planned_quantity !== curr.planned_quantity ||
        match.estimated_unit_price !== curr.estimated_unit_price;
      rows.push({
        key: `curr-${curr.id}`,
        itemName: curr.product_name || curr.description,
        changeType: changed ? 'Modified' : 'Unchanged',
        prevQty: match.planned_quantity,
        prevPrice: match.estimated_unit_price,
        prevAmount: match.estimated_amount,
        currQty: curr.planned_quantity,
        currPrice: curr.estimated_unit_price,
        currAmount: curr.estimated_amount,
        deltaAmount: curr.estimated_amount - match.estimated_amount
      });
    } else {
      rows.push({
        key: `curr-${curr.id}`,
        itemName: curr.product_name || curr.description,
        changeType: 'Added',
        prevQty: null,
        prevPrice: null,
        prevAmount: null,
        currQty: curr.planned_quantity,
        currPrice: curr.estimated_unit_price,
        currAmount: curr.estimated_amount,
        deltaAmount: curr.estimated_amount
      });
    }
  });

  prevLines.forEach((prev) => {
    if (!matchedPrevIds.has(prev.id)) {
      rows.push({
        key: `prev-${prev.id}`,
        itemName: prev.product_name || prev.description,
        changeType: 'Removed',
        prevQty: prev.planned_quantity,
        prevPrice: prev.estimated_unit_price,
        prevAmount: prev.estimated_amount,
        currQty: null,
        currPrice: null,
        currAmount: null,
        deltaAmount: -prev.estimated_amount
      });
    }
  });

  return rows;
});

const previewTotalDelta = computed(() =>
  previewDiffRows.value.reduce((sum, r) => sum + r.deltaAmount, 0)
);

const openChangePreview = (ver: ProcurementPlanVersionRecord) => {
  previewTargetVersion.value = ver;
};

const closeChangePreview = () => {
  previewTargetVersion.value = null;
};

const breadcrumbItems = computed<BreadcrumbItem[]>(() => [
  { label: 'Procurement Plans', to: '/procurement/plans' },
  { label: plan.value ? plan.value.plan_number : 'Plan Detail' }
]);

const updateLineStatus = (line: ProcurementPlanVersionLineRecord, status: PlanLineStatus) => {
  line.plan_line_status_lookup_value_id = status;
  if (status === 'on_hold' && !line.decision_note) {
    line.decision_note = 'Placed on hold during plan review.';
  } else if (status === 'approved') {
    line.decision_note = '';
  }
  toast.success(`Line #${line.line_number} (${line.product_name}) marked as ${getPlanLineStatusLabel(status)}.`);
};
</script>

<template>
  <div class="plan-detail-page">
    <!-- Clean Transparent Canvas Breadcrumb (Zero Back Buttons, Zero Floating Action Buttons) -->
    <AppBreadcrumb :items="breadcrumbItems" :noMargin="true" />

    <div v-if="!plan" class="clean-card empty-detail-card">
      <p class="empty-title">Procurement plan not found</p>
      <p class="empty-sub">The requested plan ID does not exist in the current store.</p>
    </div>

    <template v-else>
      <div
        :class="
          isPendingApproval
            ? ['detail-split-layout', { 'is-focus-mode': isFocusMode }]
            : 'dossier-column'
        "
      >
        <div class="dossier-column">
          <!-- Plan Dossier Header Card -->
      <div class="clean-card detail-dossier-card">
        <div class="detail-header-row">
          <div>
            <h2 class="detail-title">{{ plan.name }}</h2>
            <span class="detail-code">{{ plan.plan_number }} • UUID: {{ plan.uuid }}</span>
          </div>
          <div class="detail-badges-row">
            <BaseBadge size="sm" :color="getPlanStatusBadgeColor(plan.plan_status_lookup_value_id)">
              {{ getPlanStatusLabel(plan.plan_status_lookup_value_id) }}
            </BaseBadge>
            <BaseBadge size="sm" :color="plan.state === 'active' ? 'success' : 'gray'">
              {{ plan.state === 'active' ? 'Active' : 'Inactive' }}
            </BaseBadge>
          </div>
        </div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Period Type</span>
            <span class="detail-value">{{ getPlanPeriodTypeLabel(plan.period_type_lookup_value_id) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Coverage Window</span>
            <span class="detail-value">{{ formatDisplayDateRange(plan.period_start, plan.period_end) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Fiscal Year</span>
            <span class="detail-value">{{ plan.fiscal_year_id }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Owning Procurement Unit</span>
            <span class="detail-value">{{ plan.procurement_unit_name }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Entity</span>
            <span class="detail-value">{{ plan.entity_name }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Accounting Budget</span>
            <span class="detail-value">{{ plan.budget_name }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Document Reference</span>
            <span class="detail-value">{{ plan.document_id || '—' }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Version Estimated Total</span>
            <span class="detail-value">{{ formatCurrencyETB(totalEstimated, plan.currency_id) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Actual Receipt Value</span>
            <span class="detail-value">{{ formatCurrencyETB(totalActual, plan.currency_id) }}</span>
          </div>
        </div>
      </div>

      <!-- Planned Items Card (Active or Selected Version) -->
      <div class="clean-card version-lines-card">
        <div class="version-header-block">
          <div class="version-title-row">
            <div>
              <h3 class="section-title">
                Planned Items
                <span v-if="activeVersion" class="version-inline-tag">
                  (Version v{{ activeVersion.version_number }}{{ activeVersion.superseded_at === null ? ' • Current' : '' }})
                </span>
              </h3>
              <p class="section-subtitle">
                Planned items and downstream PR / PO / Receipt drawdown counters for the selected version.
              </p>
            </div>
            <BaseBadge
              v-if="activeVersion"
              size="sm"
              :color="getPlanVersionStatusBadgeColor(activeVersion.plan_version_status_lookup_value_id)"
            >
              v{{ activeVersion.version_number }} • {{ activeVersion.plan_version_status_lookup_value_id }}
            </BaseBadge>
          </div>
        </div>

        <div class="lines-table-wrap">
          <table class="erp-table">
            <thead>
              <tr>
                <th class="th-seq">#</th>
                <th>Item / Description</th>
                <th>Category</th>
                <th class="th-right">Planned Qty</th>
                <th class="th-right">Est. Amount</th>
                <th class="th-right">PR / PO / Recv</th>
                <th>Line Status</th>
                <th class="th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="versionLines.length === 0">
                <td :colspan="8" class="empty-lines-cell">No planned items in this version.</td>
              </tr>

              <tr v-for="line in versionLines" :key="line.id" class="erp-row">
                <td class="td-seq">{{ line.line_number }}</td>
                <td>
                  <div class="cell-stack">
                    <span class="cell-primary">{{ line.product_name }}</span>
                    <span class="cell-sub">{{ line.description }}</span>
                  </div>
                </td>
                <td>
                  <span class="cell-secondary">{{ line.category_name }}</span>
                </td>
                <td class="td-right">
                  <span class="cell-primary">
                    {{ line.planned_quantity.toLocaleString() }} {{ line.measurement_id || '' }}
                  </span>
                </td>
                <td class="td-right">
                  <span class="cell-primary">
                    {{ formatCurrencyETB(line.estimated_amount, plan.currency_id) }}
                  </span>
                </td>
                <td class="td-right">
                  <span class="cell-execution">
                    {{ line.requisitioned_quantity.toLocaleString() }} /
                    {{ line.ordered_quantity.toLocaleString() }} /
                    {{ line.received_quantity.toLocaleString() }}
                  </span>
                </td>
                <td>
                  <BaseBadge
                    size="sm"
                    :color="getPlanLineStatusBadgeColor(line.plan_line_status_lookup_value_id)"
                  >
                    {{ getPlanLineStatusLabel(line.plan_line_status_lookup_value_id) }}
                  </BaseBadge>
                </td>
                <td class="td-actions">
                  <BaseDropdownMenu :items="getLineActionItems(line)" minWidth="180px">
                    <template #trigger="{ toggle }">
                      <button
                        type="button"
                        class="btn-action-dots"
                        title="Line Decision"
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
        </div>
      </div>

      <!-- Collapsible Planning Notes Accordion Card (4px icon gap + header bottom border) -->
      <div class="clean-card accordion-card">
        <div
          class="card-accordion-header"
          :class="{ 'is-collapsed': !isNotesOpen }"
          @click="isNotesOpen = !isNotesOpen"
        >
          <span class="card-accordion-title">Planning Notes & Guidelines</span>
          <ChevronDown v-if="isNotesOpen" :size="16" class="header-chevron" />
          <ChevronRight v-else :size="16" class="header-chevron" />
        </div>
        <div v-show="isNotesOpen" class="card-accordion-body">
          <p class="detail-description">
            {{ plan.notes || 'No planning notes documented.' }}
          </p>
        </div>
      </div>

      <!-- Bottom Section: Activity Log (Figma 10679:31692) -->
      <div class="activity-log-section">
        <div class="activity-header-row">
          <h3 class="activity-section-title">Activity Log</h3>

          <div class="activity-header-actions">
            <!-- Filter Dropdown Menu -->
            <BaseDropdownMenu :items="activityFilterItems" minWidth="200px">
              <template #trigger="{ isOpen, toggle }">
                <AppButton
                  variant="secondary-gray"
                  size="md"
                  :iconOnly="true"
                  :active="isOpen || activityFilterStatus !== 'all'"
                  title="Filter activity"
                  @click="toggle"
                >
                  <Filter :size="16" />
                </AppButton>
              </template>
            </BaseDropdownMenu>

            <!-- 3-Dot More Dropdown Menu -->
            <BaseDropdownMenu :items="activityMoreItems" minWidth="220px">
              <template #trigger="{ isOpen, toggle }">
                <AppButton
                  variant="secondary-gray"
                  size="md"
                  :iconOnly="true"
                  :active="isOpen"
                  title="Activity actions"
                  @click="toggle"
                >
                  <MoreVertical :size="16" />
                </AppButton>
              </template>
            </BaseDropdownMenu>
          </div>
        </div>

        <!-- Timeline Body (Progress Track + Rows matching Figma 10679:31704) -->
        <div v-if="filteredActivityVersions.length === 0" class="activity-empty-state">
          No version activity matches the selected filters.
        </div>

        <div v-else class="activity-body-layout">
          <div class="activity-track-col">
            <template v-for="(ver, idx) in filteredActivityVersions" :key="`track-${ver.id}`">
              <span
                class="activity-dot"
                :class="{ 'activity-dot-primary': idx === 0 }"
              ></span>
              <span
                v-if="idx < filteredActivityVersions.length - 1"
                class="activity-line"
              ></span>
            </template>
          </div>

          <div class="activity-rows-col">
            <div
              v-for="(ver, idx) in filteredActivityVersions"
              :key="ver.id"
              class="activity-row"
            >
              <span class="activity-row-text">
                {{ ver.revised_by }}
                {{ ver.version_number === 0 ? 'Created Initial Baseline' : 'Revised' }}
                Version v{{ ver.version_number }}
                <template v-if="ver.reason"> ({{ ver.reason }})</template>
                — {{ formatDisplayDate(ver.revised_at) }}
              </span>

              <AppButton
                v-if="idx === 0 || ver.version_number > 0"
                variant="secondary-gray"
                size="sm"
                @click="openChangePreview(ver)"
              >
                See Change Preview
                <template #icon-right><ExternalLink :size="15" /></template>
              </AppButton>

              <AppButton
                v-if="String(ver.id) !== selectedVersionId"
                variant="secondary-gray"
                size="sm"
                @click="selectVersion(ver.id)"
              >
                View v{{ ver.version_number }} Lines
              </AppButton>
            </div>
          </div>
        </div>
      </div>
      </div>

      <!-- RIGHT COLUMN: Single-Approval Admin Decision Rail (Figma 10178:33832) -->
        <aside
          v-if="isPendingApproval"
          class="approval-rail"
          :class="{ 'is-collapsed': isFocusMode }"
        >
          <div v-if="isFocusMode" class="rail-card rail-card-collapsed">
            <button
              type="button"
              class="btn-sidebar-collapsed"
              title="Expand approval sidebar"
              aria-label="Expand approval sidebar"
              @click="toggleFocusMode"
            >
              <PanelLeft :size="20" class="btn-focus-icon" />
            </button>
          </div>

          <div v-else class="rail-card">
            <div class="focus-btn-row">
              <button
                type="button"
                class="btn-focus"
                title="Minimize sidebar to focus on plan dossier"
                @click="toggleFocusMode"
              >
                <PanelLeft :size="18" class="btn-focus-icon" />
                <span>Focus</span>
              </button>
            </div>

            <div class="rail-section">
              <div class="rail-title-block">
                <h3 class="rail-heading">Approver Decision</h3>
                <p class="rail-desc">
                  You are authorized as Admin to review and sign off on this submitted procurement plan. Enter optional remarks before submitting your decision.
                </p>
              </div>

              <div class="decision-form">
                <FormSelect
                  v-model="approvalResolution"
                  label="Resolution"
                  :options="approvalResolutionOptions"
                  placeholder="Select"
                  :error="approvalResolutionError"
                  required
                />

                <div class="rail-form-group">
                  <label class="rail-form-label">Remark</label>
                  <textarea
                    v-model="approvalRemark"
                    class="remark-textarea"
                    placeholder="Enter your decision reason..."
                    rows="3"
                  />
                </div>

                <AppButton
                  variant="primary"
                  size="md"
                  class="btn-submit-decision"
                  :loading="isSubmittingDecision"
                  :disabled="isSubmittingDecision"
                  @click="handleSubmitApprovalDecision"
                >
                  Submit Decision
                </AppButton>
              </div>
            </div>
          </div>
        </aside>
      </div>

      <!-- Change Preview Modal (Current vs. Previous Version Comparison) -->
      <div v-if="previewTargetVersion" class="preview-modal-backdrop" @click="closeChangePreview">
        <div class="preview-modal-card" @click.stop>
          <div class="preview-modal-header">
            <div>
              <h3 class="preview-modal-title">
                Change Preview — Version v{{ previewTargetVersion.version_number }}
                <span v-if="previewPreviousVersion" class="preview-modal-compare-tag">
                  compared with v{{ previewPreviousVersion.version_number }}
                </span>
              </h3>
              <p class="preview-modal-subtitle">
                {{ previewTargetVersion.revised_by }} • {{ formatDisplayDate(previewTargetVersion.revised_at) }}
                <span v-if="previewTargetVersion.reason"> • {{ previewTargetVersion.reason }}</span>
              </p>
            </div>
            <button type="button" class="preview-close-btn" @click="closeChangePreview">
              <X :size="18" />
            </button>
          </div>

          <div class="preview-summary-strip">
            <div class="preview-summary-item">
              <span class="preview-summary-label">Previous Baseline</span>
              <span class="preview-summary-val">
                {{ previewPreviousVersion ? `Version v${previewPreviousVersion.version_number}` : 'None (Initial Baseline)' }}
              </span>
            </div>
            <div class="preview-summary-item">
              <span class="preview-summary-label">Target Version</span>
              <span class="preview-summary-val">Version v{{ previewTargetVersion.version_number }}</span>
            </div>
            <div class="preview-summary-item">
              <span class="preview-summary-label">Net Estimate Delta</span>
              <span
                class="preview-summary-val"
                :class="{
                  'delta-positive': previewTotalDelta > 0,
                  'delta-negative': previewTotalDelta < 0
                }"
              >
                {{ previewTotalDelta >= 0 ? '+' : '' }}{{ formatCurrencyETB(previewTotalDelta, plan.currency_id) }}
              </span>
            </div>
          </div>

          <div class="preview-table-wrap">
            <table class="erp-table">
              <thead>
                <tr>
                  <th>Planned Item</th>
                  <th>Change</th>
                  <th class="th-right">Previous Qty / Price</th>
                  <th class="th-right">New Qty / Price</th>
                  <th class="th-right">Amount Delta</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="previewDiffRows.length === 0">
                  <td :colspan="5" class="empty-lines-cell">No planned items in this version.</td>
                </tr>
                <tr v-for="diff in previewDiffRows" :key="diff.key" class="erp-row">
                  <td>
                    <span class="cell-primary">{{ diff.itemName }}</span>
                  </td>
                  <td>
                    <BaseBadge
                      size="sm"
                      :color="
                        diff.changeType === 'Added'
                          ? 'success'
                          : diff.changeType === 'Modified'
                            ? 'warning'
                            : diff.changeType === 'Removed'
                              ? 'error'
                              : 'blue'
                      "
                    >
                      {{ diff.changeType }}
                    </BaseBadge>
                  </td>
                  <td class="td-right">
                    <span v-if="diff.prevQty !== null" class="cell-sub">
                      {{ diff.prevQty.toLocaleString() }} × {{ formatCurrencyETB(diff.prevPrice || 0, plan.currency_id) }}
                    </span>
                    <span v-else class="cell-sub">—</span>
                  </td>
                  <td class="td-right">
                    <span v-if="diff.currQty !== null" class="cell-primary">
                      {{ diff.currQty.toLocaleString() }} × {{ formatCurrencyETB(diff.currPrice || 0, plan.currency_id) }}
                    </span>
                    <span v-else class="cell-sub">—</span>
                  </td>
                  <td class="td-right">
                    <span
                      class="cell-primary"
                      :class="{
                        'delta-positive': diff.deltaAmount > 0,
                        'delta-negative': diff.deltaAmount < 0
                      }"
                    >
                      {{ diff.deltaAmount >= 0 ? '+' : '' }}{{ formatCurrencyETB(diff.deltaAmount, plan.currency_id) }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="preview-modal-footer">
            <AppButton variant="secondary-gray" size="sm" @click="closeChangePreview">
              Close
            </AppButton>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.plan-detail-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.detail-split-layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 360px;
  gap: 24px;
  align-items: start;
  width: 100%;
  transition: grid-template-columns 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.detail-split-layout.is-focus-mode {
  grid-template-columns: minmax(0, 1fr) 68px;
}

.dossier-column {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 20px;
  width: 100%;
}

.approval-rail {
  width: 100%;
  max-width: 360px;
  position: sticky;
  top: 20px;
}

.approval-rail.is-collapsed {
  max-width: 68px;
  width: 68px;
}

.rail-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.rail-card-collapsed {
  padding: 20px 16px;
  align-items: center;
  min-height: 460px;
}

.btn-sidebar-collapsed {
  width: 36px;
  height: 36px;
  background-color: #ffffff;
  border: 1px solid #d4d4d4;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: #404040;
}

.btn-sidebar-collapsed:hover {
  background-color: #fafafa;
}

.focus-btn-row {
  display: flex;
  justify-content: flex-start;
}

.btn-focus {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background-color: #ffffff;
  border: 1px solid #d4d4d4;
  border-radius: 8px;
  padding: 8px 14px;
  font-family: inherit;
  font-weight: 600;
  font-size: 14px;
  line-height: 20px;
  color: #404040;
  cursor: pointer;
}

.btn-focus:hover {
  background-color: #fafafa;
}

.btn-focus-icon {
  color: #404040;
  flex-shrink: 0;
}

.rail-section {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.rail-title-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.rail-heading {
  font-size: 20px;
  font-weight: 600;
  color: #404040;
  line-height: 28px;
  margin: 0;
}

.rail-desc {
  font-size: 14px;
  color: #737373;
  line-height: 20px;
  margin: 0;
}

.decision-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.rail-form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.rail-form-label {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
  line-height: 20px;
}

.remark-textarea {
  width: 100%;
  padding: 10px 14px;
  background-color: #ffffff;
  border: 1px solid #d4d4d4;
  border-radius: 8px;
  font-size: 14px;
  color: #404040;
  outline: none;
  resize: vertical;
  font-family: inherit;
  box-sizing: border-box;
}

.remark-textarea::placeholder {
  color: #737373;
}

.remark-textarea:focus {
  border-color: #0b529c;
}

.btn-submit-decision {
  width: 100%;
}

@media (max-width: 1100px) {
  .detail-split-layout,
  .detail-split-layout.is-focus-mode {
    grid-template-columns: 1fr;
  }
  .approval-rail,
  .approval-rail.is-collapsed {
    max-width: 100%;
    width: 100%;
    position: static;
  }
}

.clean-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
}

.empty-detail-card {
  padding: 48px 24px;
  text-align: center;
}

.empty-title {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.empty-sub {
  margin: 6px 0 0;
  font-size: 13.5px;
  color: #737373;
}

.detail-dossier-card {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.detail-header-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  padding-bottom: 16px;
  border-bottom: 1px solid #e5e5e5;
}

.detail-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: #404040;
}

.detail-code {
  display: inline-block;
  margin-top: 4px;
  font-size: 12.5px;
  color: #737373;
}

.detail-badges-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.detail-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 18px 24px;
}

.detail-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.detail-label {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
}

.detail-value {
  font-size: 14px;
  font-weight: 500;
  color: #404040;
}

/* Versions & Lines Card */
.version-lines-card {
  overflow: hidden;
}

.version-header-block {
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  border-bottom: 1px solid #e5e5e5;
}

.version-title-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
}

.section-title {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.section-subtitle {
  margin: 4px 0 0;
  font-size: 13px;
  color: #737373;
}

.version-meta-strip {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
  padding: 12px 16px;
  background-color: #fafafa;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
}

.meta-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.meta-label {
  font-size: 11.5px;
  color: #737373;
}

.meta-val {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.lines-table-wrap {
  width: 100%;
  overflow-x: auto;
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

.erp-table thead th.th-seq {
  padding-left: 24px;
  width: 56px;
}

.erp-table thead th.th-right {
  text-align: right;
}

.erp-table thead th.th-actions {
  text-align: center;
  padding-right: 24px;
  width: 80px;
}

.erp-row {
  height: 72px;
  border-bottom: 1px solid #e9eaeb;
}

.erp-row:last-child {
  border-bottom: none;
}

.erp-row:hover {
  background-color: #fafafa;
}

.erp-table tbody td {
  padding: 12px 16px;
  vertical-align: middle;
}

.erp-table tbody td.td-seq {
  padding-left: 24px;
  font-size: 13px;
  font-weight: 500;
  color: #737373;
}

.erp-table tbody td.td-right {
  text-align: right;
}

.erp-table tbody td.td-actions {
  text-align: center;
  padding-right: 24px;
}

.cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.align-end {
  align-items: flex-end;
}

.cell-primary {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
  font-variant-numeric: tabular-nums;
}

.cell-secondary {
  font-size: 13.5px;
  color: #404040;
}

.cell-sub {
  font-size: 12px;
  color: #737373;
}

.cell-decision-note {
  font-size: 12px;
  color: #0b529c;
}

.cell-execution {
  font-size: 13px;
  color: #404040;
  font-variant-numeric: tabular-nums;
}

.empty-lines-cell {
  padding: 36px 24px !important;
  text-align: center;
  color: #737373;
  font-size: 13.5px;
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

/* Collapsible Accordion Card (4px icon gap + header bottom border) */
.accordion-card {
  overflow: hidden;
}

.card-accordion-header {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 4px;
  padding: 16px 24px;
  cursor: pointer;
  user-select: none;
  background-color: #ffffff;
  border-bottom: 1px solid #e5e5e5;
  transition: background-color 0.15s ease;
}

.card-accordion-header.is-collapsed {
  border-bottom: none;
}

.card-accordion-header:hover {
  background-color: #fafafa;
}

.card-accordion-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.header-chevron {
  color: #737373;
  flex-shrink: 0;
}

.card-accordion-body {
  padding: 20px 24px 24px;
}

.detail-description {
  margin: 0;
  font-size: 14px;
  line-height: 1.6;
  color: #404040;
}

.version-inline-tag {
  font-size: 13.5px;
  font-weight: 500;
  color: #737373;
}

/* Recent Activity / Version Log (Figma 10679:31692) */
.activity-log-section {
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding: 8px 0 12px;
}

.activity-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  padding: 0 20px;
  min-height: 36px;
}

.activity-section-title {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: #404040;
}

.activity-header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.activity-empty-state {
  padding: 16px 24px;
  font-size: 14px;
  color: #737373;
}

.activity-body-layout {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 0 24px;
}

.activity-track-col {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 17px 2px 0;
  flex-shrink: 0;
}

.activity-dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background-color: #404040;
  flex-shrink: 0;
}

.activity-dot-primary {
  background-color: #0b529c;
}

.activity-line {
  width: 1px;
  height: 39px;
  background-color: #e5e5e5;
  flex-shrink: 0;
}

.activity-rows-col {
  display: flex;
  flex-direction: column;
  gap: 20px;
  flex: 1;
  min-width: 0;
}

.activity-row {
  display: flex;
  align-items: center;
  gap: 16px;
  min-height: 40px;
  flex-wrap: wrap;
}

.activity-row-text {
  font-size: 16px;
  font-weight: 400;
  line-height: 24px;
  color: #737373;
}

/* Change Preview Modal */
.preview-modal-backdrop {
  position: fixed;
  inset: 0;
  z-index: 120;
  background-color: rgba(15, 23, 42, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.preview-modal-card {
  width: 100%;
  max-width: 820px;
  max-height: 85vh;
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  box-shadow: 0 16px 40px rgba(10, 13, 18, 0.16);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.preview-modal-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  padding: 20px 24px;
  border-bottom: 1px solid #e5e5e5;
}

.preview-modal-title {
  margin: 0;
  font-size: 17px;
  font-weight: 600;
  color: #404040;
}

.preview-modal-compare-tag {
  font-size: 14px;
  font-weight: 500;
  color: #737373;
}

.preview-modal-subtitle {
  margin: 4px 0 0;
  font-size: 13px;
  color: #737373;
}

.preview-close-btn {
  width: 32px;
  height: 32px;
  border-radius: 9999px;
  border: none;
  background-color: #f5f5f5;
  color: #737373;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.preview-close-btn:hover {
  background-color: #e5e5e5;
  color: #404040;
}

.preview-summary-strip {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
  padding: 16px 24px;
  background-color: #fafafa;
  border-bottom: 1px solid #e5e5e5;
}

.preview-summary-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.preview-summary-label {
  font-size: 12px;
  color: #737373;
}

.preview-summary-val {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  font-variant-numeric: tabular-nums;
}

.delta-positive {
  color: #009966;
}

.delta-negative {
  color: #e7000b;
}

.preview-table-wrap {
  overflow: auto;
  flex: 1;
}

.preview-modal-footer {
  display: flex;
  justify-content: flex-end;
  padding: 14px 24px;
  background-color: #fafafa;
  border-top: 1px solid #e5e5e5;
}

@media (max-width: 960px) {
  .detail-grid-3,
  .version-meta-strip {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 640px) {
  .detail-grid-3,
  .version-meta-strip {
    grid-template-columns: 1fr;
  }
}
</style>
