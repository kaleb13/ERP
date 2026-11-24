<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  Plus, ArrowUpDown, MoreVertical, Eye, Edit2, Trash2,
  Route, GitPullRequest, ShieldCheck, Building2, Globe, FileText, ShoppingCart,
  ChevronDown, ChevronRight, Check, UserCheck, AlertCircle, Ban, Clock
} from 'lucide-vue-next';
import { useToast } from '../../composables/useToast';
import { formatDisplayDate, formatDisplayDateRange } from '../../utils/dateFormat';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef, type SortOption } from '../../components/BaseTable.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormCheckboxCard from '../../components/FormCheckboxCard.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import BaseBadge, { type BadgeColor } from '../../components/BaseBadge.vue';
import BaseAvatar from '../../components/BaseAvatar.vue';
import MetricCard from '../../components/MetricCard.vue';

// ─── Approval Routes Data & Store ───
import {
  approvalRoutesStore,
  type ProcurementApprovalRouteRecord,
  documentTypeOptions,
  workflowOptions,
  priorityOptions as approvalPriorityOptions,
  categoryScopeOptions as approvalCategoryOptions,
  formatCurrency as formatApprovalCurrency,
  getWorkflowLabel,
  getCategoryLabel as getApprovalCategoryLabel,
  getMethodLabel as getApprovalMethodLabel,
  getUnitLabel as getApprovalUnitLabel
} from './procurementApprovalRouteData';

// ─── Assignment Rules Data & Store ───
import {
  assignmentRulesStore,
  type ProcurementAssignmentRuleRecord,
  unitOptions as assignmentUnitOptions,
  buyerOptions,
  originOptions,
  categoryScopeOptions as assignmentCategoryOptions,
  requestingEntityOptions,
  priorityOptions as assignmentPriorityOptions,
  formatCurrency as formatAssignmentCurrency,
  getBuyerName,
  getBuyerAvatar,
  getCategoryName as getAssignmentCategoryName,
  getOriginLabel,
  getEntityName,
  getMethodName
} from './procurementAssignmentRuleData';

// ─── Approval Delegations Data & Store ───
import {
  approvalDelegationsStore,
  type ApprovalDelegationRecord,
  delegationTypeOptions,
  delegationStatusOptions,
  delegationDocTypeOptions,
  delegatorUserOptions,
  delegateUserOptions,
  formatDelegationCurrency,
  getDelegationTypeLabel,
  getDelegationStatusLabel,
  getDelegationTypeBadgeColor,
  getDelegationStatusBadgeColor
} from './procurementApprovalDelegationData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

// ─── Unified Tab State ───
type RoutingTabKey = 'approval' | 'assignment' | 'delegations';
const activeTab = ref<RoutingTabKey>(
  route.query.tab === 'delegations'
    ? 'delegations'
    : route.query.tab === 'assignment'
      ? 'assignment'
      : 'approval'
);

watch(
  () => route.query.tab,
  (newTab) => {
    if (newTab === 'assignment' || newTab === 'approval' || newTab === 'delegations') {
      activeTab.value = newTab;
    }
  }
);

watch(activeTab, (tab) => {
  router.replace({ query: { ...route.query, tab } });
  inspectingApprovalRoute.value = null;
  inspectingAssignmentRule.value = null;
  inspectingDelegation.value = null;
  selectedApprovalRowIds.value = [];
  selectedAssignmentRowIds.value = [];
  selectedDelegationRowIds.value = [];
  activeActionMenuId.value = null;
});

const routingTabs = computed<BaseTabItem<RoutingTabKey>[]>(() => [
  {
    id: 'approval',
    label: 'Approval Routes',
    icon: Route
  },
  {
    id: 'assignment',
    label: 'Assignment Rules',
    icon: GitPullRequest
  },
  {
    id: 'delegations',
    label: 'Approval Delegations',
    icon: UserCheck
  }
]);

// ═════════════════════════════════════════════════════════════════
// TAB 1: APPROVAL ROUTES STATE & PIPELINE
// ═════════════════════════════════════════════════════════════════
const searchApproval = ref('');
const filterDocType = ref('');
const filterApprovalWorkflow = ref('');
const filterApprovalPriority = ref('');
const filterApprovalCategory = ref('');
const filterApprovalState = ref('');
const sortApproval = ref('priority');
const sortApprovalOrder = ref<'asc' | 'desc'>('asc');
const currentApprovalPage = ref(1);
const perApprovalPage = ref(10);
const selectedApprovalRowIds = ref<number[]>([]);
const inspectingApprovalRoute = ref<ProcurementApprovalRouteRecord | null>(null);
const isApprovalNotesOpen = ref(false);

const approvalTableColumns = ref<ColumnDef[]>([
  { key: 'document_type', label: 'Document Type', visible: true, sortable: true, hideable: false },
  { key: 'workflow', label: 'Approval Workflow', visible: true, sortable: true },
  { key: 'floor_amount', label: 'Floor Amount', visible: false, sortable: true },
  { key: 'ceiling_amount', label: 'Ceiling Amount', visible: true, sortable: true },
  { key: 'priority', label: 'Priority', visible: true, sortable: true },
  { key: 'scope_summary', label: 'Scope Rules', visible: false, sortable: false },
  { key: 'validity', label: 'Validity Period', visible: false, sortable: false },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const approvalSortOptions: SortOption[] = [
  { key: 'priority', label: 'Priority (Highest First)' },
  { key: 'document_type', label: 'Document Type' },
  { key: 'workflow', label: 'Workflow' },
  { key: 'floor_amount', label: 'Floor Amount' },
  { key: 'ceiling_amount', label: 'Ceiling Amount' },
  { key: 'state', label: 'State' }
];

const isApprovalColVisible = (key: string) => {
  const col = approvalTableColumns.value.find((c) => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleApprovalColumn = (colKey: string) => {
  const col = approvalTableColumns.value.find((c) => c.key === colKey);
  if (col && col.hideable !== false) {
    col.visible = !col.visible;
  }
};

const activeApprovalFilterCount = computed(() => {
  let count = 0;
  if (filterDocType.value) count++;
  if (filterApprovalWorkflow.value) count++;
  if (filterApprovalPriority.value) count++;
  if (filterApprovalCategory.value) count++;
  if (filterApprovalState.value) count++;
  return count;
});

const resetApprovalFilters = () => {
  filterDocType.value = '';
  filterApprovalWorkflow.value = '';
  filterApprovalPriority.value = '';
  filterApprovalCategory.value = '';
  filterApprovalState.value = '';
  currentApprovalPage.value = 1;
};

const filteredApprovalRoutes = computed(() => {
  let rows = [...approvalRoutesStore.value];

  if (searchApproval.value.trim()) {
    const q = searchApproval.value.toLowerCase().trim();
    rows = rows.filter((r) =>
      r.document_type_id.toLowerCase().includes(q) ||
      r.document_type_name.toLowerCase().includes(q) ||
      r.workflow_name.toLowerCase().includes(q) ||
      (r.notes && r.notes.toLowerCase().includes(q)) ||
      (r.category_name && r.category_name.toLowerCase().includes(q))
    );
  }

  if (filterDocType.value) {
    rows = rows.filter((r) => r.document_type_id === filterDocType.value);
  }
  if (filterApprovalWorkflow.value) {
    rows = rows.filter((r) => String(r.workflow_id) === filterApprovalWorkflow.value);
  }
  if (filterApprovalPriority.value) {
    rows = rows.filter((r) => String(r.priority) === filterApprovalPriority.value);
  }
  if (filterApprovalCategory.value) {
    rows = rows.filter((r) => String(r.procurement_category_id) === filterApprovalCategory.value);
  }
  if (filterApprovalState.value) {
    rows = rows.filter((r) => r.state === filterApprovalState.value);
  }

  rows.sort((a, b) => {
    let valA: string | number = '';
    let valB: string | number = '';
    switch (sortApproval.value) {
      case 'priority':
        valA = a.priority;
        valB = b.priority;
        break;
      case 'document_type':
        valA = a.document_type_id;
        valB = b.document_type_id;
        break;
      case 'workflow':
        valA = a.workflow_name.toLowerCase();
        valB = b.workflow_name.toLowerCase();
        break;
      case 'floor_amount':
        valA = a.minimum_amount;
        valB = b.minimum_amount;
        break;
      case 'ceiling_amount':
        valA = a.maximum_amount ?? Number.MAX_SAFE_INTEGER;
        valB = b.maximum_amount ?? Number.MAX_SAFE_INTEGER;
        break;
      case 'state':
        valA = a.state;
        valB = b.state;
        break;
    }
    if (valA < valB) return sortApprovalOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortApprovalOrder.value === 'asc' ? 1 : -1;
    return 0;
  });

  return rows;
});

const paginatedApprovalRoutes = computed(() => {
  const start = (currentApprovalPage.value - 1) * perApprovalPage.value;
  return filteredApprovalRoutes.value.slice(start, start + perApprovalPage.value);
});

const handleSortApprovalColumn = (colKey: string) => {
  if (sortApproval.value === colKey) {
    sortApprovalOrder.value = sortApprovalOrder.value === 'asc' ? 'desc' : 'asc';
  } else {
    sortApproval.value = colKey;
    sortApprovalOrder.value = 'asc';
  }
};

const isAllApprovalSelected = computed(() => {
  if (paginatedApprovalRoutes.value.length === 0) return false;
  return paginatedApprovalRoutes.value.every((r) => selectedApprovalRowIds.value.includes(r.id));
});

const isPartialApprovalSelected = computed(() => {
  const count = paginatedApprovalRoutes.value.filter((r) => selectedApprovalRowIds.value.includes(r.id)).length;
  return count > 0 && count < paginatedApprovalRoutes.value.length;
});

const toggleSelectAllApproval = () => {
  if (!isAllApprovalSelected.value) {
    const pageIds = paginatedApprovalRoutes.value.map((r) => r.id);
    selectedApprovalRowIds.value = Array.from(new Set([...selectedApprovalRowIds.value, ...pageIds]));
  } else {
    const pageIds = new Set(paginatedApprovalRoutes.value.map((r) => r.id));
    selectedApprovalRowIds.value = selectedApprovalRowIds.value.filter((id) => !pageIds.has(id));
  }
};

const toggleSelectApprovalRow = (id: number) => {
  const idx = selectedApprovalRowIds.value.indexOf(id);
  if (idx > -1) {
    selectedApprovalRowIds.value.splice(idx, 1);
  } else {
    selectedApprovalRowIds.value.push(id);
  }
};

// ═════════════════════════════════════════════════════════════════
// TAB 2: ASSIGNMENT RULES STATE & PIPELINE
// ═════════════════════════════════════════════════════════════════
const searchAssignment = ref('');
const filterAssignmentUnit = ref('');
const filterAssignmentBuyer = ref('');
const filterAssignmentCategory = ref('');
const filterAssignmentOrigin = ref('');
const filterAssignmentEntity = ref('');
const filterAssignmentState = ref('');
const sortAssignment = ref('priority');
const sortAssignmentOrder = ref<'asc' | 'desc'>('asc');
const currentAssignmentPage = ref(1);
const perAssignmentPage = ref(10);
const selectedAssignmentRowIds = ref<number[]>([]);
const inspectingAssignmentRule = ref<ProcurementAssignmentRuleRecord | null>(null);
const isAssignmentNotesOpen = ref(false);

const assignmentTableColumns = ref<ColumnDef[]>([
  { key: 'assigned_unit', label: 'Buying Desk', visible: true, sortable: true, hideable: false },
  { key: 'default_buyer', label: 'Default Buyer', visible: true, sortable: true },
  { key: 'category', label: 'Spend Category', visible: true, sortable: true },
  { key: 'origin', label: 'Sourcing Origin', visible: false, sortable: true },
  { key: 'floor_amount', label: 'Floor Amount', visible: false, sortable: true },
  { key: 'ceiling_amount', label: 'Ceiling Amount', visible: true, sortable: true },
  { key: 'requesting_entity', label: 'Requesting Branch', visible: false, sortable: true },
  { key: 'priority', label: 'Priority', visible: true, sortable: true },
  { key: 'validity', label: 'Validity Period', visible: false, sortable: false },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const assignmentSortOptions: SortOption[] = [
  { key: 'priority', label: 'Priority (Highest First)' },
  { key: 'assigned_unit', label: 'Buying Desk' },
  { key: 'default_buyer', label: 'Default Buyer' },
  { key: 'floor_amount', label: 'Floor Amount' },
  { key: 'ceiling_amount', label: 'Ceiling Amount' },
  { key: 'state', label: 'State' }
];

const isAssignmentColVisible = (key: string) => {
  const col = assignmentTableColumns.value.find((c) => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleAssignmentColumn = (colKey: string) => {
  const col = assignmentTableColumns.value.find((c) => c.key === colKey);
  if (col && col.hideable !== false) {
    col.visible = !col.visible;
  }
};

const activeAssignmentFilterCount = computed(() => {
  let count = 0;
  if (filterAssignmentUnit.value) count++;
  if (filterAssignmentBuyer.value) count++;
  if (filterAssignmentCategory.value) count++;
  if (filterAssignmentOrigin.value) count++;
  if (filterAssignmentEntity.value) count++;
  if (filterAssignmentState.value) count++;
  return count;
});

const resetAssignmentFilters = () => {
  filterAssignmentUnit.value = '';
  filterAssignmentBuyer.value = '';
  filterAssignmentCategory.value = '';
  filterAssignmentOrigin.value = '';
  filterAssignmentEntity.value = '';
  filterAssignmentState.value = '';
  currentAssignmentPage.value = 1;
};

const filteredAssignmentRules = computed(() => {
  let rows = [...assignmentRulesStore.value];

  if (searchAssignment.value.trim()) {
    const q = searchAssignment.value.toLowerCase().trim();
    rows = rows.filter((r) =>
      r.unit_name.toLowerCase().includes(q) ||
      (r.buyer_name && r.buyer_name.toLowerCase().includes(q)) ||
      (r.category_name && r.category_name.toLowerCase().includes(q)) ||
      (r.requesting_entity_name && r.requesting_entity_name.toLowerCase().includes(q)) ||
      (r.notes && r.notes.toLowerCase().includes(q))
    );
  }

  if (filterAssignmentUnit.value) {
    rows = rows.filter((r) => String(r.procurement_unit_id) === filterAssignmentUnit.value);
  }
  if (filterAssignmentBuyer.value) {
    rows = rows.filter((r) => String(r.default_buyer_employee_id) === filterAssignmentBuyer.value);
  }
  if (filterAssignmentCategory.value) {
    rows = rows.filter((r) => String(r.procurement_category_id) === filterAssignmentCategory.value);
  }
  if (filterAssignmentOrigin.value) {
    rows = rows.filter((r) => r.origin_lookup_value_id === filterAssignmentOrigin.value);
  }
  if (filterAssignmentEntity.value) {
    rows = rows.filter((r) => String(r.requesting_entity_id) === filterAssignmentEntity.value);
  }
  if (filterAssignmentState.value) {
    rows = rows.filter((r) => r.state === filterAssignmentState.value);
  }

  rows.sort((a, b) => {
    let valA: string | number = '';
    let valB: string | number = '';
    switch (sortAssignment.value) {
      case 'priority':
        valA = a.priority;
        valB = b.priority;
        break;
      case 'assigned_unit':
        valA = a.unit_name.toLowerCase();
        valB = b.unit_name.toLowerCase();
        break;
      case 'default_buyer':
        valA = (a.buyer_name || '').toLowerCase();
        valB = (b.buyer_name || '').toLowerCase();
        break;
      case 'floor_amount':
        valA = a.minimum_amount;
        valB = b.minimum_amount;
        break;
      case 'ceiling_amount':
        valA = a.maximum_amount ?? Number.MAX_SAFE_INTEGER;
        valB = b.maximum_amount ?? Number.MAX_SAFE_INTEGER;
        break;
      case 'state':
        valA = a.state;
        valB = b.state;
        break;
    }
    if (valA < valB) return sortAssignmentOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortAssignmentOrder.value === 'asc' ? 1 : -1;
    return 0;
  });

  return rows;
});

const paginatedAssignmentRules = computed(() => {
  const start = (currentAssignmentPage.value - 1) * perAssignmentPage.value;
  return filteredAssignmentRules.value.slice(start, start + perAssignmentPage.value);
});

const handleSortAssignmentColumn = (colKey: string) => {
  if (sortAssignment.value === colKey) {
    sortAssignmentOrder.value = sortAssignmentOrder.value === 'asc' ? 'desc' : 'asc';
  } else {
    sortAssignment.value = colKey;
    sortAssignmentOrder.value = 'asc';
  }
};

const isAllAssignmentSelected = computed(() => {
  if (paginatedAssignmentRules.value.length === 0) return false;
  return paginatedAssignmentRules.value.every((r) => selectedAssignmentRowIds.value.includes(r.id));
});

const isPartialAssignmentSelected = computed(() => {
  const count = paginatedAssignmentRules.value.filter((r) => selectedAssignmentRowIds.value.includes(r.id)).length;
  return count > 0 && count < paginatedAssignmentRules.value.length;
});

const toggleSelectAllAssignment = () => {
  if (!isAllAssignmentSelected.value) {
    const pageIds = paginatedAssignmentRules.value.map((r) => r.id);
    selectedAssignmentRowIds.value = Array.from(new Set([...selectedAssignmentRowIds.value, ...pageIds]));
  } else {
    const pageIds = new Set(paginatedAssignmentRules.value.map((r) => r.id));
    selectedAssignmentRowIds.value = selectedAssignmentRowIds.value.filter((id) => !pageIds.has(id));
  }
};

const toggleSelectAssignmentRow = (id: number) => {
  const idx = selectedAssignmentRowIds.value.indexOf(id);
  if (idx > -1) {
    selectedAssignmentRowIds.value.splice(idx, 1);
  } else {
    selectedAssignmentRowIds.value.push(id);
  }
};

// ═════════════════════════════════════════════════════════════════
// TAB 3: APPROVAL DELEGATIONS STATE & PIPELINE
// ═════════════════════════════════════════════════════════════════
const searchDelegation = ref('');
const filterDelegator = ref('');
const filterDelegate = ref('');
const filterDelegationDocType = ref('');
const filterDelegationType = ref('');
const filterDelegationStatus = ref('');
const sortDelegation = ref('valid_from');
const sortDelegationOrder = ref<'asc' | 'desc'>('desc');
const currentDelegationPage = ref(1);
const perDelegationPage = ref(10);
const selectedDelegationRowIds = ref<number[]>([]);
const inspectingDelegation = ref<ApprovalDelegationRecord | null>(null);
const isDelegationNotesOpen = ref(false);

const delegationTableColumns = ref<ColumnDef[]>([
  { key: 'delegator_name', label: 'Absent Approver', visible: true, sortable: true, hideable: false },
  { key: 'delegate_name', label: 'Acting Delegate', visible: true, sortable: true },
  { key: 'document_type_id', label: 'Scope', visible: true, sortable: true },
  { key: 'maximum_amount', label: 'Ceiling Amount', visible: true, sortable: true },
  { key: 'valid_from', label: 'Effective Period', visible: true, sortable: true },
  { key: 'type_lookup_value_id', label: 'Delegation Reason', visible: true, sortable: true },
  { key: 'delegation_status_lookup_value_id', label: 'Status', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

const delegationSortOptions: SortOption[] = [
  { key: 'valid_from', label: 'Effective Start Date' },
  { key: 'delegator_name', label: 'Absent Approver' },
  { key: 'delegate_name', label: 'Acting Delegate' },
  { key: 'maximum_amount', label: 'Ceiling Amount' },
  { key: 'delegation_status_lookup_value_id', label: 'Status' }
];

const isDelegationColVisible = (key: string) => {
  const col = delegationTableColumns.value.find((c) => c.key === key);
  return col ? col.visible !== false : true;
};

const handleToggleDelegationColumn = (colKey: string) => {
  const col = delegationTableColumns.value.find((c) => c.key === colKey);
  if (col && col.hideable !== false) {
    col.visible = !col.visible;
  }
};

const activeDelegationFilterCount = computed(() => {
  let count = 0;
  if (filterDelegator.value) count++;
  if (filterDelegate.value) count++;
  if (filterDelegationDocType.value) count++;
  if (filterDelegationType.value) count++;
  if (filterDelegationStatus.value) count++;
  return count;
});

const resetDelegationFilters = () => {
  filterDelegator.value = '';
  filterDelegate.value = '';
  filterDelegationDocType.value = '';
  filterDelegationType.value = '';
  filterDelegationStatus.value = '';
  currentDelegationPage.value = 1;
};

const filteredDelegations = computed(() => {
  let rows = [...approvalDelegationsStore.value];

  if (searchDelegation.value.trim()) {
    const q = searchDelegation.value.toLowerCase().trim();
    rows = rows.filter((r) =>
      r.delegator_name.toLowerCase().includes(q) ||
      r.delegate_name.toLowerCase().includes(q) ||
      (r.document_type_id && r.document_type_id.toLowerCase().includes(q)) ||
      (r.type_label && r.type_label.toLowerCase().includes(q)) ||
      (r.note && r.note.toLowerCase().includes(q))
    );
  }

  if (filterDelegator.value) {
    rows = rows.filter((r) => String(r.delegator_user_id) === filterDelegator.value);
  }
  if (filterDelegate.value) {
    rows = rows.filter((r) => String(r.delegate_user_id) === filterDelegate.value);
  }
  if (filterDelegationDocType.value) {
    rows = rows.filter((r) => r.document_type_id === filterDelegationDocType.value);
  }
  if (filterDelegationType.value) {
    rows = rows.filter((r) => r.type_lookup_value_id === filterDelegationType.value);
  }
  if (filterDelegationStatus.value) {
    rows = rows.filter((r) => r.delegation_status_lookup_value_id === filterDelegationStatus.value);
  }

  rows.sort((a, b) => {
    let valA: string | number = '';
    let valB: string | number = '';
    switch (sortDelegation.value) {
      case 'valid_from':
        valA = a.valid_from;
        valB = b.valid_from;
        break;
      case 'delegator_name':
        valA = a.delegator_name.toLowerCase();
        valB = b.delegator_name.toLowerCase();
        break;
      case 'delegate_name':
        valA = a.delegate_name.toLowerCase();
        valB = b.delegate_name.toLowerCase();
        break;
      case 'maximum_amount':
        valA = a.maximum_amount ?? Number.MAX_SAFE_INTEGER;
        valB = b.maximum_amount ?? Number.MAX_SAFE_INTEGER;
        break;
      case 'delegation_status_lookup_value_id':
        valA = a.delegation_status_lookup_value_id;
        valB = b.delegation_status_lookup_value_id;
        break;
    }
    if (valA < valB) return sortDelegationOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortDelegationOrder.value === 'asc' ? 1 : -1;
    return 0;
  });

  return rows;
});

const paginatedDelegations = computed(() => {
  const start = (currentDelegationPage.value - 1) * perDelegationPage.value;
  return filteredDelegations.value.slice(start, start + perDelegationPage.value);
});

const handleSortDelegationColumn = (colKey: string) => {
  if (sortDelegation.value === colKey) {
    sortDelegationOrder.value = sortDelegationOrder.value === 'asc' ? 'desc' : 'asc';
  } else {
    sortDelegation.value = colKey;
    sortDelegationOrder.value = 'asc';
  }
};

const isAllDelegationSelected = computed(() => {
  if (paginatedDelegations.value.length === 0) return false;
  return paginatedDelegations.value.every((r) => selectedDelegationRowIds.value.includes(r.id));
});

const isPartialDelegationSelected = computed(() => {
  const count = paginatedDelegations.value.filter((r) => selectedDelegationRowIds.value.includes(r.id)).length;
  return count > 0 && count < paginatedDelegations.value.length;
});

const toggleSelectAllDelegation = () => {
  if (!isAllDelegationSelected.value) {
    const pageIds = paginatedDelegations.value.map((r) => r.id);
    selectedDelegationRowIds.value = Array.from(new Set([...selectedDelegationRowIds.value, ...pageIds]));
  } else {
    const pageIds = new Set(paginatedDelegations.value.map((r) => r.id));
    selectedDelegationRowIds.value = selectedDelegationRowIds.value.filter((id) => !pageIds.has(id));
  }
};

const toggleSelectDelegationRow = (id: number) => {
  const idx = selectedDelegationRowIds.value.indexOf(id);
  if (idx > -1) {
    selectedDelegationRowIds.value.splice(idx, 1);
  } else {
    selectedDelegationRowIds.value.push(id);
  }
};

// ═════════════════════════════════════════════════════════════════
// SHARED BREADCRUMB NAVIGATION STANDARD (AGENTS.md Rule 3)
// ═════════════════════════════════════════════════════════════════
const breadcrumbItems = computed<BreadcrumbItem[]>(() => {
  if (inspectingApprovalRoute.value) {
    return [
      {
        label: 'Approval & Assignment Rules',
        to: '/procurement/routing-rules?tab=approval',
        onClick: () => {
          inspectingApprovalRoute.value = null;
        }
      },
      { label: `${inspectingApprovalRoute.value.document_type_id} — ${inspectingApprovalRoute.value.workflow_name}` }
    ];
  }
  if (inspectingAssignmentRule.value) {
    return [
      {
        label: 'Approval & Assignment Rules',
        to: '/procurement/routing-rules?tab=assignment',
        onClick: () => {
          inspectingAssignmentRule.value = null;
        }
      },
      { label: `${inspectingAssignmentRule.value.unit_name} — Rule #${inspectingAssignmentRule.value.id}` }
    ];
  }
  if (inspectingDelegation.value) {
    return [
      {
        label: 'Approval & Assignment Rules',
        to: '/procurement/routing-rules?tab=delegations',
        onClick: () => {
          inspectingDelegation.value = null;
        }
      },
      { label: `${inspectingDelegation.value.delegator_name} → ${inspectingDelegation.value.delegate_name}` }
    ];
  }
  return [{ label: 'Approval & Assignment Rules' }];
});

// ═════════════════════════════════════════════════════════════════
// SHARED ROW ACTION KEBAB MENU DISMISSAL
// ═════════════════════════════════════════════════════════════════
const activeActionMenuId = ref<number | null>(null);

const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenu = () => {
  activeActionMenuId.value = null;
};

const handleDocumentClick = (e: MouseEvent) => {
  const target = e.target as HTMLElement | null;
  if (!target?.closest('.action-menu-container')) {
    activeActionMenuId.value = null;
  }
};

onMounted(() => {
  document.addEventListener('click', handleDocumentClick);
});

onUnmounted(() => {
  document.removeEventListener('click', handleDocumentClick);
});

const activeSelectedCount = computed(() => {
  if (activeTab.value === 'approval') return selectedApprovalRowIds.value.length;
  if (activeTab.value === 'assignment') return selectedAssignmentRowIds.value.length;
  return selectedDelegationRowIds.value.length;
});

// Priority badge color helper
const getPriorityBadgeColor = (p: number): BadgeColor => {
  if (p === 1) return 'indigo';
  if (p === 2) return 'blue';
  if (p === 3) return 'purple';
  return 'gray';
};

// ─── Single Row Handlers (Approval) ───
const openApprovalDetail = (item: ProcurementApprovalRouteRecord) => {
  inspectingApprovalRoute.value = item;
  isApprovalNotesOpen.value = false;
  closeActionMenu();
};

const handleToggleApprovalState = (item: ProcurementApprovalRouteRecord) => {
  item.state = item.state === 'active' ? 'inactive' : 'active';
  toast.success('Route State Updated', `Approval Route #${item.id} is now ${item.state === 'active' ? 'Active' : 'Inactive'}.`);
  closeActionMenu();
};

const handleDeleteApproval = (item: ProcurementApprovalRouteRecord) => {
  const idx = approvalRoutesStore.value.findIndex((r) => r.id === item.id);
  if (idx !== -1) {
    approvalRoutesStore.value.splice(idx, 1);
    selectedApprovalRowIds.value = selectedApprovalRowIds.value.filter((id) => id !== item.id);
    if (inspectingApprovalRoute.value?.id === item.id) inspectingApprovalRoute.value = null;
    toast.success('Approval Route Deleted', `Route #${item.id} has been removed.`);
  }
  closeActionMenu();
};

// ─── Single Row Handlers (Assignment) ───
const openAssignmentDetail = (item: ProcurementAssignmentRuleRecord) => {
  inspectingAssignmentRule.value = item;
  isAssignmentNotesOpen.value = false;
  closeActionMenu();
};

const handleToggleAssignmentState = (item: ProcurementAssignmentRuleRecord) => {
  item.state = item.state === 'active' ? 'inactive' : 'active';
  toast.success('Rule State Updated', `Assignment Rule #${item.id} is now ${item.state === 'active' ? 'Active' : 'Inactive'}.`);
  closeActionMenu();
};

const handleDeleteAssignment = (item: ProcurementAssignmentRuleRecord) => {
  const idx = assignmentRulesStore.value.findIndex((r) => r.id === item.id);
  if (idx !== -1) {
    assignmentRulesStore.value.splice(idx, 1);
    selectedAssignmentRowIds.value = selectedAssignmentRowIds.value.filter((id) => id !== item.id);
    if (inspectingAssignmentRule.value?.id === item.id) inspectingAssignmentRule.value = null;
    toast.success('Assignment Rule Deleted', `Rule #${item.id} has been removed.`);
  }
  closeActionMenu();
};

// ─── Single Row Handlers (Delegation) ───
const openDelegationDetail = (item: ApprovalDelegationRecord) => {
  inspectingDelegation.value = item;
  isDelegationNotesOpen.value = false;
  closeActionMenu();
};

const handleToggleDelegationStatus = (item: ApprovalDelegationRecord) => {
  item.delegation_status_lookup_value_id = item.delegation_status_lookup_value_id === 'active' ? 'revoked' : 'active';
  item.status_label = item.delegation_status_lookup_value_id === 'active' ? 'Active' : 'Revoked';
  toast.success('Delegation Status Updated', `Delegation #${item.id} is now ${item.status_label}.`);
  closeActionMenu();
};

const handleDeleteDelegation = (item: ApprovalDelegationRecord) => {
  const idx = approvalDelegationsStore.value.findIndex((r) => r.id === item.id);
  if (idx !== -1) {
    approvalDelegationsStore.value.splice(idx, 1);
    selectedDelegationRowIds.value = selectedDelegationRowIds.value.filter((id) => id !== item.id);
    if (inspectingDelegation.value?.id === item.id) inspectingDelegation.value = null;
    toast.success('Approval Delegation Deleted', `Delegation #${item.id} has been removed.`);
  }
  closeActionMenu();
};

// ─── Bulk Floating Bar Handlers ───
const handleBulkActivate = () => {
  if (activeTab.value === 'approval') {
    approvalRoutesStore.value.forEach((r) => {
      if (selectedApprovalRowIds.value.includes(r.id)) r.state = 'active';
    });
    toast.success('Bulk Update', `Activated ${selectedApprovalRowIds.value.length} approval routes.`);
    selectedApprovalRowIds.value = [];
  } else if (activeTab.value === 'assignment') {
    assignmentRulesStore.value.forEach((r) => {
      if (selectedAssignmentRowIds.value.includes(r.id)) r.state = 'active';
    });
    toast.success('Bulk Update', `Activated ${selectedAssignmentRowIds.value.length} assignment rules.`);
    selectedAssignmentRowIds.value = [];
  } else {
    approvalDelegationsStore.value.forEach((r) => {
      if (selectedDelegationRowIds.value.includes(r.id)) {
        r.delegation_status_lookup_value_id = 'active';
        r.status_label = 'Active';
      }
    });
    toast.success('Bulk Update', `Activated ${selectedDelegationRowIds.value.length} approval delegations.`);
    selectedDelegationRowIds.value = [];
  }
};

const handleBulkDeactivate = () => {
  if (activeTab.value === 'approval') {
    approvalRoutesStore.value.forEach((r) => {
      if (selectedApprovalRowIds.value.includes(r.id)) r.state = 'inactive';
    });
    toast.success('Bulk Update', `Deactivated ${selectedApprovalRowIds.value.length} approval routes.`);
    selectedApprovalRowIds.value = [];
  } else if (activeTab.value === 'assignment') {
    assignmentRulesStore.value.forEach((r) => {
      if (selectedAssignmentRowIds.value.includes(r.id)) r.state = 'inactive';
    });
    toast.success('Bulk Update', `Deactivated ${selectedAssignmentRowIds.value.length} assignment rules.`);
    selectedAssignmentRowIds.value = [];
  } else {
    approvalDelegationsStore.value.forEach((r) => {
      if (selectedDelegationRowIds.value.includes(r.id)) {
        r.delegation_status_lookup_value_id = 'revoked';
        r.status_label = 'Revoked';
      }
    });
    toast.success('Bulk Update', `Revoked ${selectedDelegationRowIds.value.length} approval delegations.`);
    selectedDelegationRowIds.value = [];
  }
};

const handleBulkDelete = () => {
  if (activeTab.value === 'approval') {
    approvalRoutesStore.value = approvalRoutesStore.value.filter(
      (r) => !selectedApprovalRowIds.value.includes(r.id)
    );
    toast.success('Bulk Delete', `Deleted ${selectedApprovalRowIds.value.length} approval routes.`);
    selectedApprovalRowIds.value = [];
  } else if (activeTab.value === 'assignment') {
    assignmentRulesStore.value = assignmentRulesStore.value.filter(
      (r) => !selectedAssignmentRowIds.value.includes(r.id)
    );
    toast.success('Bulk Delete', `Deleted ${selectedAssignmentRowIds.value.length} assignment rules.`);
    selectedAssignmentRowIds.value = [];
  } else {
    approvalDelegationsStore.value = approvalDelegationsStore.value.filter(
      (r) => !selectedDelegationRowIds.value.includes(r.id)
    );
    toast.success('Bulk Delete', `Deleted ${selectedDelegationRowIds.value.length} approval delegations.`);
    selectedDelegationRowIds.value = [];
  }
};

// ─── Quick Create Modal: Approval Route (<= 5 Required Schema Fields) ───
const showApprovalQuickModal = ref(false);
const approvalQuickErrors = ref<{
  document_type_id?: string;
  workflow_id?: string;
  minimum_amount?: string;
  maximum_amount?: string;
  effective_from?: string;
}>({});
const approvalQuickForm = ref({
  document_type_id: '',
  workflow_id: '',
  priority: '1',
  minimum_amount: 0,
  maximum_amount: null as number | null,
  is_unlimited: true,
  effective_from: new Date().toISOString().split('T')[0]
});

const approvalQuickWorkflowOptions = computed(() => {
  if (!approvalQuickForm.value.document_type_id) return workflowOptions;
  const filtered = workflowOptions.filter(
    (w) => w.docType === approvalQuickForm.value.document_type_id
  );
  return filtered.length > 0 ? filtered : workflowOptions;
});

watch(
  () => approvalQuickForm.value.is_unlimited,
  (val) => {
    if (val) {
      approvalQuickForm.value.maximum_amount = null;
      approvalQuickErrors.value.maximum_amount = undefined;
    }
  }
);

watch(
  approvalQuickForm,
  () => {
    if (approvalQuickForm.value.document_type_id) {
      approvalQuickErrors.value.document_type_id = undefined;
    }
    if (approvalQuickForm.value.workflow_id) {
      approvalQuickErrors.value.workflow_id = undefined;
    }
    if (approvalQuickForm.value.minimum_amount >= 0) {
      approvalQuickErrors.value.minimum_amount = undefined;
    }
    if (approvalQuickForm.value.effective_from) {
      approvalQuickErrors.value.effective_from = undefined;
    }
  },
  { deep: true }
);

const openApprovalQuickModal = () => {
  approvalQuickErrors.value = {};
  approvalQuickForm.value = {
    document_type_id: '',
    workflow_id: '',
    priority: '1',
    minimum_amount: 0,
    maximum_amount: null,
    is_unlimited: true,
    effective_from: new Date().toISOString().split('T')[0]
  };
  showApprovalQuickModal.value = true;
};

const handleExpandApprovalForm = () => {
  const query: Record<string, string> = {
    is_unlimited: approvalQuickForm.value.is_unlimited ? '1' : '0'
  };
  if (approvalQuickForm.value.document_type_id) {
    query.document_type_id = approvalQuickForm.value.document_type_id;
  }
  if (approvalQuickForm.value.workflow_id) {
    query.workflow_id = approvalQuickForm.value.workflow_id;
  }
  if (approvalQuickForm.value.priority) {
    query.priority = String(approvalQuickForm.value.priority);
  }
  if (approvalQuickForm.value.minimum_amount !== null && approvalQuickForm.value.minimum_amount !== undefined) {
    query.minimum_amount = String(approvalQuickForm.value.minimum_amount);
  }
  if (!approvalQuickForm.value.is_unlimited && approvalQuickForm.value.maximum_amount !== null) {
    query.maximum_amount = String(approvalQuickForm.value.maximum_amount);
  }
  if (approvalQuickForm.value.effective_from) {
    query.effective_from = approvalQuickForm.value.effective_from;
  }
  showApprovalQuickModal.value = false;
  router.push({ path: '/procurement/approval-routes/create', query });
};

const handleQuickSaveApprovalRoute = () => {
  const errors: typeof approvalQuickErrors.value = {};
  const missing: string[] = [];

  if (!approvalQuickForm.value.document_type_id) {
    errors.document_type_id = 'Document Type is required.';
    missing.push('Document Type');
  }
  if (!approvalQuickForm.value.workflow_id) {
    errors.workflow_id = 'Target Workflow is required.';
    missing.push('Target Workflow');
  }
  if (approvalQuickForm.value.minimum_amount < 0) {
    errors.minimum_amount = 'Minimum floor cannot be negative.';
    missing.push('Valid Floor Amount');
  }
  if (!approvalQuickForm.value.is_unlimited) {
    if (
      approvalQuickForm.value.maximum_amount === null ||
      approvalQuickForm.value.maximum_amount < approvalQuickForm.value.minimum_amount
    ) {
      errors.maximum_amount = 'Ceiling must be greater than or equal to floor amount.';
      missing.push('Valid Ceiling Amount');
    }
  }
  if (!approvalQuickForm.value.effective_from) {
    errors.effective_from = 'Effective From date is required.';
    missing.push('Effective From');
  }

  approvalQuickErrors.value = errors;
  if (missing.length > 0) {
    toast.error('Please fill in required fields', `Review: ${missing.join(', ')}.`);
    return;
  }

  const docType = documentTypeOptions.find((d) => d.value === approvalQuickForm.value.document_type_id);
  const wf = workflowOptions.find((w) => w.value === approvalQuickForm.value.workflow_id);
  const nextId = Math.max(0, ...approvalRoutesStore.value.map((r) => r.id)) + 1;

  approvalRoutesStore.value.unshift({
    id: nextId,
    uuid: `par-${String(nextId).padStart(4, '0')}-quick`,
    document_type_id: approvalQuickForm.value.document_type_id,
    document_type_name: docType?.label ?? approvalQuickForm.value.document_type_id,
    workflow_id: Number(approvalQuickForm.value.workflow_id),
    workflow_name: wf?.label ?? `Workflow #${approvalQuickForm.value.workflow_id}`,
    minimum_amount: Number(approvalQuickForm.value.minimum_amount),
    maximum_amount: approvalQuickForm.value.is_unlimited
      ? null
      : Number(approvalQuickForm.value.maximum_amount),
    currency_code: 'ETB',
    priority: Number(approvalQuickForm.value.priority) || 1,
    procurement_category_id: null,
    purchase_method_id: null,
    procurement_unit_id: null,
    effective_from: approvalQuickForm.value.effective_from,
    effective_to: null,
    entity_id: 2,
    notes: '',
    state: 'active'
  });

  showApprovalQuickModal.value = false;
  toast.success(
    'Approval route created',
    `Route for ${docType?.code ?? approvalQuickForm.value.document_type_id} saved successfully.`
  );
};

// ─── Quick Create Modal: Assignment Rule ───
const showAssignmentQuickModal = ref(false);
const assignmentQuickErrors = ref<{
  procurement_unit_id?: string;
  minimum_amount?: string;
  maximum_amount?: string;
  effective_from?: string;
}>({});
const assignmentQuickForm = ref({
  procurement_unit_id: '',
  default_buyer_employee_id: '',
  procurement_category_id: '',
  priority: '1',
  minimum_amount: 0,
  maximum_amount: null as number | null,
  is_unlimited: false,
  effective_from: new Date().toISOString().split('T')[0]
});

watch(
  assignmentQuickForm,
  () => {
    if (assignmentQuickForm.value.procurement_unit_id) {
      assignmentQuickErrors.value.procurement_unit_id = undefined;
    }
    if (assignmentQuickForm.value.minimum_amount >= 0) {
      assignmentQuickErrors.value.minimum_amount = undefined;
    }
    if (assignmentQuickForm.value.is_unlimited || assignmentQuickForm.value.maximum_amount !== null) {
      assignmentQuickErrors.value.maximum_amount = undefined;
    }
    if (assignmentQuickForm.value.effective_from) {
      assignmentQuickErrors.value.effective_from = undefined;
    }
  },
  { deep: true }
);

const openAssignmentQuickModal = () => {
  assignmentQuickErrors.value = {};
  assignmentQuickForm.value = {
    procurement_unit_id: '',
    default_buyer_employee_id: '',
    procurement_category_id: '',
    priority: '1',
    minimum_amount: 0,
    maximum_amount: null,
    is_unlimited: false,
    effective_from: new Date().toISOString().split('T')[0]
  };
  showAssignmentQuickModal.value = true;
};

const handleExpandAssignmentForm = () => {
  const query: Record<string, string> = {};
  if (assignmentQuickForm.value.procurement_unit_id) {
    query.procurement_unit_id = assignmentQuickForm.value.procurement_unit_id;
  }
  if (assignmentQuickForm.value.default_buyer_employee_id) {
    query.default_buyer_employee_id = assignmentQuickForm.value.default_buyer_employee_id;
  }
  if (assignmentQuickForm.value.procurement_category_id) {
    query.procurement_category_id = assignmentQuickForm.value.procurement_category_id;
  }
  if (assignmentQuickForm.value.priority) {
    query.priority = assignmentQuickForm.value.priority;
  }
  if (assignmentQuickForm.value.minimum_amount !== undefined) {
    query.minimum_amount = String(assignmentQuickForm.value.minimum_amount);
  }
  if (!assignmentQuickForm.value.is_unlimited && assignmentQuickForm.value.maximum_amount !== null) {
    query.maximum_amount = String(assignmentQuickForm.value.maximum_amount);
  }
  query.is_unlimited = assignmentQuickForm.value.is_unlimited ? '1' : '0';
  if (assignmentQuickForm.value.effective_from) {
    query.effective_from = assignmentQuickForm.value.effective_from;
  }
  showAssignmentQuickModal.value = false;
  router.push({ path: '/procurement/assignment-rules/create', query });
};

const handleQuickSaveAssignmentRule = () => {
  const errors: typeof assignmentQuickErrors.value = {};
  const missing: string[] = [];

  if (!assignmentQuickForm.value.procurement_unit_id) {
    errors.procurement_unit_id = 'Assigned Buying Desk is required.';
    missing.push('Assigned Buying Desk');
  }
  if (assignmentQuickForm.value.minimum_amount < 0) {
    errors.minimum_amount = 'Minimum floor cannot be negative.';
    missing.push('Minimum Floor Amount');
  }
  if (!assignmentQuickForm.value.is_unlimited && assignmentQuickForm.value.maximum_amount !== null) {
    if (assignmentQuickForm.value.maximum_amount < assignmentQuickForm.value.minimum_amount) {
      errors.maximum_amount = 'Maximum ceiling must exceed floor amount.';
      missing.push('Maximum Ceiling Amount');
    }
  }
  if (!assignmentQuickForm.value.effective_from) {
    errors.effective_from = 'Effective From date is required.';
    missing.push('Effective From');
  }

  assignmentQuickErrors.value = errors;
  if (missing.length > 0) {
    toast.error('Please fill in required fields', `Review: ${missing.join(', ')}.`);
    return;
  }

  const unitId = Number(assignmentQuickForm.value.procurement_unit_id);
  const unitOption = assignmentUnitOptions.find((u) => Number(u.value) === unitId);
  const buyerId = assignmentQuickForm.value.default_buyer_employee_id
    ? Number(assignmentQuickForm.value.default_buyer_employee_id)
    : null;
  const categoryId = assignmentQuickForm.value.procurement_category_id
    ? Number(assignmentQuickForm.value.procurement_category_id)
    : null;
  const ceiling = assignmentQuickForm.value.is_unlimited ? null : assignmentQuickForm.value.maximum_amount;
  const nextId = Math.max(0, ...assignmentRulesStore.value.map((r) => r.id)) + 1;

  assignmentRulesStore.value.unshift({
    id: nextId,
    uuid: `par-assign-${String(nextId).padStart(4, '0')}-quick`,
    procurement_unit_id: unitId,
    unit_name: unitOption?.label ?? `Unit #${unitId}`,
    default_buyer_employee_id: buyerId,
    buyer_name: buyerId ? getBuyerName(buyerId) : undefined,
    buyer_avatar: buyerId ? getBuyerAvatar(buyerId) : undefined,
    procurement_category_id: categoryId,
    category_name: categoryId ? getAssignmentCategoryName(categoryId) : undefined,
    purchase_method_id: null,
    origin_lookup_value_id: null,
    requesting_entity_id: null,
    minimum_amount: Number(assignmentQuickForm.value.minimum_amount),
    maximum_amount: ceiling,
    currency_code: 'ETB',
    priority: Number(assignmentQuickForm.value.priority) || 1,
    effective_from: assignmentQuickForm.value.effective_from,
    effective_to: null,
    entity_id: 2,
    notes: '',
    state: 'active'
  });

  showAssignmentQuickModal.value = false;
  toast.success(
    'Assignment rule created',
    `Requisitions routed to ${unitOption?.label ?? 'selected unit'}.`
  );
};

// ─── Quick Create Modal: Approval Delegation (<= 5 Essential Fields) ───
const showDelegationQuickModal = ref(false);
const delegationQuickErrors = ref<{
  delegator_user_id?: string;
  delegate_user_id?: string;
  valid_from?: string;
  valid_to?: string;
  maximum_amount?: string;
}>({});
const delegationQuickForm = ref({
  delegator_user_id: '',
  delegate_user_id: '',
  type_lookup_value_id: 'planned_leave' as any,
  document_type_id: '',
  is_full_authority: true,
  maximum_amount: null as number | null,
  valid_from: new Date().toISOString().split('T')[0],
  valid_to: ''
});

watch(
  delegationQuickForm,
  () => {
    if (delegationQuickForm.value.delegator_user_id) delegationQuickErrors.value.delegator_user_id = undefined;
    if (delegationQuickForm.value.delegate_user_id) delegationQuickErrors.value.delegate_user_id = undefined;
    if (delegationQuickForm.value.valid_from) delegationQuickErrors.value.valid_from = undefined;
    if (delegationQuickForm.value.valid_to) delegationQuickErrors.value.valid_to = undefined;
    if (delegationQuickForm.value.is_full_authority || delegationQuickForm.value.maximum_amount !== null) {
      delegationQuickErrors.value.maximum_amount = undefined;
    }
  },
  { deep: true }
);

const openDelegationQuickModal = () => {
  delegationQuickErrors.value = {};
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 7);
  delegationQuickForm.value = {
    delegator_user_id: '',
    delegate_user_id: '',
    type_lookup_value_id: 'planned_leave',
    document_type_id: '',
    is_full_authority: true,
    maximum_amount: null,
    valid_from: new Date().toISOString().split('T')[0],
    valid_to: tomorrow.toISOString().split('T')[0]
  };
  showDelegationQuickModal.value = true;
};

const handleExpandDelegationForm = () => {
  const query: Record<string, string> = {};
  if (delegationQuickForm.value.delegator_user_id) query.delegator_user_id = delegationQuickForm.value.delegator_user_id;
  if (delegationQuickForm.value.delegate_user_id) query.delegate_user_id = delegationQuickForm.value.delegate_user_id;
  if (delegationQuickForm.value.type_lookup_value_id) query.type_lookup_value_id = delegationQuickForm.value.type_lookup_value_id;
  if (delegationQuickForm.value.document_type_id) query.document_type_id = delegationQuickForm.value.document_type_id;
  query.is_full_authority = delegationQuickForm.value.is_full_authority ? '1' : '0';
  if (!delegationQuickForm.value.is_full_authority && delegationQuickForm.value.maximum_amount !== null) {
    query.maximum_amount = String(delegationQuickForm.value.maximum_amount);
  }
  if (delegationQuickForm.value.valid_from) query.valid_from = delegationQuickForm.value.valid_from;
  if (delegationQuickForm.value.valid_to) query.valid_to = delegationQuickForm.value.valid_to;
  showDelegationQuickModal.value = false;
  router.push({ path: '/procurement/delegations/create', query });
};

const handleQuickSaveDelegation = () => {
  const errors: typeof delegationQuickErrors.value = {};
  const missing: string[] = [];

  if (!delegationQuickForm.value.delegator_user_id) {
    errors.delegator_user_id = 'Absent Approver is required.';
    missing.push('Absent Approver');
  }
  if (!delegationQuickForm.value.delegate_user_id) {
    errors.delegate_user_id = 'Acting Delegate is required.';
    missing.push('Acting Delegate');
  } else if (delegationQuickForm.value.delegator_user_id && delegationQuickForm.value.delegator_user_id === delegationQuickForm.value.delegate_user_id) {
    errors.delegate_user_id = 'Delegate cannot be the same user.';
    missing.push('Valid Acting Delegate');
  }
  if (!delegationQuickForm.value.valid_from) {
    errors.valid_from = 'Start date is required.';
    missing.push('Start Date');
  }
  if (!delegationQuickForm.value.valid_to) {
    errors.valid_to = 'End date is required.';
    missing.push('End Date');
  } else if (delegationQuickForm.value.valid_from && delegationQuickForm.value.valid_to < delegationQuickForm.value.valid_from) {
    errors.valid_to = 'End date cannot precede start date.';
    missing.push('Valid End Date');
  }
  if (!delegationQuickForm.value.is_full_authority && (delegationQuickForm.value.maximum_amount === null || delegationQuickForm.value.maximum_amount <= 0)) {
    errors.maximum_amount = 'Please enter a valid ceiling amount.';
    missing.push('Valid Ceiling Amount');
  }

  delegationQuickErrors.value = errors;
  if (missing.length > 0) {
    toast.error('Please fill in required fields', `Review: ${missing.join(', ')}.`);
    return;
  }

  const delegator = delegatorUserOptions.find((u) => u.value === Number(delegationQuickForm.value.delegator_user_id));
  const delegate = delegateUserOptions.find((u) => u.value === Number(delegationQuickForm.value.delegate_user_id));
  const typeOpt = delegationTypeOptions.find((t) => t.value === delegationQuickForm.value.type_lookup_value_id);
  const nextId = Math.max(0, ...approvalDelegationsStore.value.map((d) => d.id)) + 1;

  approvalDelegationsStore.value.unshift({
    id: nextId,
    uuid: `del-${String(nextId).padStart(4, '0')}-quick`,
    delegator_user_id: Number(delegationQuickForm.value.delegator_user_id),
    delegator_name: delegator?.label.split(' — ')[0] ?? `User #${delegationQuickForm.value.delegator_user_id}`,
    delegator_role: delegator?.role || 'Approver',
    delegator_title: delegator?.role || 'Approver',
    delegator_avatar: delegator?.avatar,
    delegate_user_id: Number(delegationQuickForm.value.delegate_user_id),
    delegate_name: delegate?.label.split(' — ')[0] ?? `User #${delegationQuickForm.value.delegate_user_id}`,
    delegate_role: delegate?.role || 'Delegate',
    delegate_title: delegate?.role || 'Delegate',
    delegate_avatar: delegate?.avatar,
    document_type_id: delegationQuickForm.value.document_type_id || null,
    document_type_name: delegationQuickForm.value.document_type_id || 'All Documents',
    maximum_amount: delegationQuickForm.value.is_full_authority ? null : Number(delegationQuickForm.value.maximum_amount),
    currency_code: 'ETB',
    valid_from: delegationQuickForm.value.valid_from,
    valid_to: delegationQuickForm.value.valid_to,
    type_lookup_value_id: delegationQuickForm.value.type_lookup_value_id,
    type_label: typeOpt?.label ?? delegationQuickForm.value.type_lookup_value_id,
    delegation_status_lookup_value_id: 'active',
    status_label: 'Active',
    document_id: null,
    note: '',
    tenant_id: 1,
    entity_id: 2,
    user_id: 10,
    state: 'active'
  });

  showDelegationQuickModal.value = false;
  toast.success('Delegation Created', `Approval authority delegated to ${delegate?.label.split(' — ')[0]}.`);
};
</script>

<template>
  <div class="routing-rules-view">
    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- BREADCRUMB ROW (AGENTS.md: Zero Background Card Standard)      -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div class="breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- INSPECTION DOSSIER CARD: APPROVAL ROUTE                        -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-if="inspectingApprovalRoute" class="detail-view-wrapper">
      <div class="detail-card">
        <div class="detail-header-row">
          <div>
            <h2 class="detail-title">{{ inspectingApprovalRoute.document_type_name }}</h2>
            <span class="detail-code">UUID: {{ inspectingApprovalRoute.uuid }}</span>
          </div>
          <div class="detail-badges">
            <BaseBadge size="sm" :color="getPriorityBadgeColor(inspectingApprovalRoute.priority)">
              Priority {{ inspectingApprovalRoute.priority }} ({{ inspectingApprovalRoute.priority === 1 ? 'Highest' : 'Standard' }})
            </BaseBadge>
            <BaseBadge
              size="sm"
              :color="inspectingApprovalRoute.state === 'active' ? 'success' : 'gray'"
            >
              {{ inspectingApprovalRoute.state === 'active' ? 'Active' : 'Inactive' }}
            </BaseBadge>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Assigned Approval Workflow</span>
            <span class="detail-value text-bold">{{ inspectingApprovalRoute.workflow_name }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Precedence Priority</span>
            <span class="detail-value">Priority {{ inspectingApprovalRoute.priority }} (Lowest wins on tie)</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Owning Legal Entity</span>
            <span class="detail-value">Haleta General Hospital (Entity #{{ inspectingApprovalRoute.entity_id }})</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Minimum Floor Amount</span>
            <span class="detail-value text-bold">{{ formatApprovalCurrency(inspectingApprovalRoute.minimum_amount) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Maximum Ceiling Amount</span>
            <span class="detail-value text-bold">
              {{ inspectingApprovalRoute.maximum_amount !== null ? formatApprovalCurrency(inspectingApprovalRoute.maximum_amount) : 'Unlimited (Open Ceiling)' }}
            </span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Operating Currency</span>
            <span class="detail-value">{{ inspectingApprovalRoute.currency_code }}</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Spend Category Scope</span>
            <span class="detail-value">{{ getApprovalCategoryLabel(inspectingApprovalRoute.procurement_category_id) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Purchase Method Scope</span>
            <span class="detail-value">{{ getApprovalMethodLabel(inspectingApprovalRoute.purchase_method_id) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Buying Desk Scope</span>
            <span class="detail-value">{{ getApprovalUnitLabel(inspectingApprovalRoute.procurement_unit_id) }}</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Effective From</span>
            <span class="detail-value">{{ formatDisplayDate(inspectingApprovalRoute.effective_from) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Effective To</span>
            <span class="detail-value">{{ formatDisplayDate(inspectingApprovalRoute.effective_to, 'Open-ended (No expiry)') }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Route Identification ID</span>
            <span class="detail-value">#{{ inspectingApprovalRoute.id }}</span>
          </div>
        </div>
      </div>

      <div class="clean-card accordion-card">
        <div
          class="card-accordion-header"
          :class="{ 'is-collapsed': !isApprovalNotesOpen }"
          @click="isApprovalNotesOpen = !isApprovalNotesOpen"
        >
          <span>Policy Notes & Operational Rationale</span>
          <ChevronDown v-if="isApprovalNotesOpen" :size="16" class="header-chevron" />
          <ChevronRight v-else :size="16" class="header-chevron" />
        </div>
        <div v-show="isApprovalNotesOpen" class="card-accordion-body">
          <p class="detail-description">{{ inspectingApprovalRoute.notes || 'No specific routing rationale documented.' }}</p>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- INSPECTION DOSSIER CARD: ASSIGNMENT RULE                       -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-else-if="inspectingAssignmentRule" class="detail-view-wrapper">
      <div class="detail-card">
        <div class="detail-header-row">
          <div>
            <h2 class="detail-title">{{ inspectingAssignmentRule.unit_name }}</h2>
            <span class="detail-code">UUID: {{ inspectingAssignmentRule.uuid }}</span>
          </div>
          <div class="detail-badges">
            <BaseBadge size="sm" :color="getPriorityBadgeColor(inspectingAssignmentRule.priority)">
              Priority {{ inspectingAssignmentRule.priority }} ({{ inspectingAssignmentRule.priority === 1 ? 'Highest' : 'Standard' }})
            </BaseBadge>
            <BaseBadge
              size="sm"
              :color="inspectingAssignmentRule.state === 'active' ? 'success' : 'gray'"
            >
              {{ inspectingAssignmentRule.state === 'active' ? 'Active' : 'Inactive' }}
            </BaseBadge>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Assigned Buying Desk</span>
            <span class="detail-value text-bold">{{ inspectingAssignmentRule.unit_name }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Default Assigned Buyer</span>
            <div class="buyer-profile-inline">
              <BaseAvatar
                v-if="inspectingAssignmentRule.default_buyer_employee_id"
                :src="inspectingAssignmentRule.buyer_avatar"
                :name="inspectingAssignmentRule.buyer_name || 'Buyer'"
                size="sm"
              />
              <span class="detail-value" :class="{ 'text-bold': inspectingAssignmentRule.default_buyer_employee_id }">
                {{ inspectingAssignmentRule.buyer_name || 'Unassigned (Desk Lead Dispatches)' }}
              </span>
            </div>
          </div>
          <div class="detail-field">
            <span class="detail-label">Precedence Priority</span>
            <span class="detail-value">Priority {{ inspectingAssignmentRule.priority }} (Lowest wins on tie)</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Spend Category Scope</span>
            <span class="detail-value">{{ getAssignmentCategoryName(inspectingAssignmentRule.procurement_category_id) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Sourcing Origin</span>
            <span class="detail-value">{{ getOriginLabel(inspectingAssignmentRule.origin_lookup_value_id) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Requesting Branch / Entity</span>
            <span class="detail-value">{{ inspectingAssignmentRule.requesting_entity_name || 'All Branches (Enterprise)' }}</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Minimum Floor Value</span>
            <span class="detail-value text-bold">{{ formatAssignmentCurrency(inspectingAssignmentRule.minimum_amount) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Maximum Ceiling Value</span>
            <span class="detail-value text-bold">
              {{ inspectingAssignmentRule.maximum_amount !== null ? formatAssignmentCurrency(inspectingAssignmentRule.maximum_amount) : 'Unlimited (Open Ceiling)' }}
            </span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Purchase Method Restriction</span>
            <span class="detail-value">{{ getMethodName(inspectingAssignmentRule.purchase_method_id) }}</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Effective From</span>
            <span class="detail-value">{{ formatDisplayDate(inspectingAssignmentRule.effective_from) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Effective To</span>
            <span class="detail-value">{{ formatDisplayDate(inspectingAssignmentRule.effective_to, 'Open-ended (No expiry)') }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Rule Identification ID</span>
            <span class="detail-value">#{{ inspectingAssignmentRule.id }}</span>
          </div>
        </div>
      </div>

      <div class="clean-card accordion-card">
        <div
          class="card-accordion-header"
          :class="{ 'is-collapsed': !isAssignmentNotesOpen }"
          @click="isAssignmentNotesOpen = !isAssignmentNotesOpen"
        >
          <span>Sourcing Guidelines & Operational Memo</span>
          <ChevronDown v-if="isAssignmentNotesOpen" :size="16" class="header-chevron" />
          <ChevronRight v-else :size="16" class="header-chevron" />
        </div>
        <div v-show="isAssignmentNotesOpen" class="card-accordion-body">
          <p class="detail-description">{{ inspectingAssignmentRule.notes || 'No specific sourcing guidelines documented.' }}</p>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- INSPECTION DOSSIER CARD: APPROVAL DELEGATION                   -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-else-if="inspectingDelegation" class="detail-view-wrapper">
      <div class="detail-card">
        <div class="detail-header-row">
          <div>
            <h2 class="detail-title">{{ inspectingDelegation.delegator_name }} → {{ inspectingDelegation.delegate_name }}</h2>
            <span class="detail-code">UUID: {{ inspectingDelegation.uuid }}</span>
          </div>
          <div class="detail-badges">
            <BaseBadge size="sm" :color="getDelegationTypeBadgeColor(inspectingDelegation.type_lookup_value_id)">
              {{ getDelegationTypeLabel(inspectingDelegation.type_lookup_value_id) }}
            </BaseBadge>
            <BaseBadge
              size="sm"
              :color="getDelegationStatusBadgeColor(inspectingDelegation.delegation_status_lookup_value_id)"
            >
              {{ getDelegationStatusLabel(inspectingDelegation.delegation_status_lookup_value_id) }}
            </BaseBadge>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Absent Approver</span>
            <div class="buyer-profile-inline">
              <BaseAvatar
                :src="inspectingDelegation.delegator_avatar"
                :name="inspectingDelegation.delegator_name"
                size="sm"
              />
              <div class="name-cell-stack">
                <span class="detail-value text-bold">{{ inspectingDelegation.delegator_name }}</span>
                <span class="detail-code">{{ inspectingDelegation.delegator_role || inspectingDelegation.delegator_title || 'Approver' }}</span>
              </div>
            </div>
          </div>
          <div class="detail-field">
            <span class="detail-label">Acting Delegate</span>
            <div class="buyer-profile-inline">
              <BaseAvatar
                :src="inspectingDelegation.delegate_avatar"
                :name="inspectingDelegation.delegate_name"
                size="sm"
              />
              <div class="name-cell-stack">
                <span class="detail-value text-bold">{{ inspectingDelegation.delegate_name }}</span>
                <span class="detail-code">{{ inspectingDelegation.delegate_role || inspectingDelegation.delegate_title || 'Delegate' }}</span>
              </div>
            </div>
          </div>
          <div class="detail-field">
            <span class="detail-label">Owning Legal Entity</span>
            <span class="detail-value">Haleta General Hospital (Entity #{{ inspectingDelegation.entity_id }})</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Document Scope</span>
            <span class="detail-value text-bold">
              {{ inspectingDelegation.document_type_id ? `${inspectingDelegation.document_type_id} Documents Only` : 'All Procurement Documents (Universal)' }}
            </span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Delegated Monetary Ceiling</span>
            <span class="detail-value text-bold">
              {{ formatDelegationCurrency(inspectingDelegation.maximum_amount) }}
            </span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Operating Currency</span>
            <span class="detail-value">ETB (Ethiopian Birr)</span>
          </div>
        </div>

        <div class="detail-divider"></div>

        <div class="detail-grid-3">
          <div class="detail-field">
            <span class="detail-label">Effective From</span>
            <span class="detail-value">{{ formatDisplayDate(inspectingDelegation.valid_from) }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Effective To</span>
            <span class="detail-value">{{ formatDisplayDate(inspectingDelegation.valid_to, 'Open-ended') }}</span>
          </div>
          <div class="detail-field">
            <span class="detail-label">Delegation Identification ID</span>
            <span class="detail-value">#{{ inspectingDelegation.id }}</span>
          </div>
        </div>
      </div>

      <div class="clean-card accordion-card">
        <div
          class="card-accordion-header"
          :class="{ 'is-collapsed': !isDelegationNotesOpen }"
          @click="isDelegationNotesOpen = !isDelegationNotesOpen"
        >
          <span>Handover Notes & Audit Memo</span>
          <ChevronDown v-if="isDelegationNotesOpen" :size="16" class="header-chevron" />
          <ChevronRight v-else :size="16" class="header-chevron" />
        </div>
        <div v-show="isDelegationNotesOpen" class="card-accordion-body">
          <p class="detail-description">{{ inspectingDelegation.note || 'No specific handover notes or memo documented.' }}</p>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- UNIFIED DIRECTORY VIEW: TABS + METRICS + APPDATATABLE          -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <template v-else>
      <!-- CARD 1: TOP SUMMARY CARD (White section containing MetricCards & Tabs per Attendance standard) -->
      <div class="routing-top-card">
        <!-- Top 4 Summary KPI Metric Cards (Figma 10178:31133 Standard - Persistent across all 3 tabs) -->
        <div class="metrics-grid">
          <MetricCard
            label="TOTAL APPROVAL ROUTES"
            :value="approvalRoutesStore.length"
            subtext="Configured approval ladders"
            :icon="Route"
            :show-menu="false"
          />
          <MetricCard
            label="TOTAL ASSIGNMENT RULES"
            :value="assignmentRulesStore.length"
            subtext="Buyer dispatch policies"
            :icon="GitPullRequest"
            :show-menu="false"
          />
          <MetricCard
            label="ACTIVE DELEGATIONS"
            :value="approvalDelegationsStore.filter((d) => d.delegation_status_lookup_value_id === 'active').length"
            subtext="Live authority handovers"
            :icon="UserCheck"
            :show-menu="false"
          />
          <MetricCard
            label="PENDING APPROVAL"
            :value="approvalDelegationsStore.filter((d) => d.delegation_status_lookup_value_id === 'pending_approval').length"
            subtext="Awaiting authority sign-off"
            :icon="Clock"
            :show-menu="false"
          />
        </div>

        <!-- Primary BaseTabs Capsule Bar inside the white section -->
        <div class="top-card-tabs-wrapper">
          <BaseTabs
            v-model="activeTab"
            :tabs="routingTabs"
            type="rounded"
            size="sm"
          />
        </div>
      </div>

      <!-- ──────────────────────────────────────────────────────────── -->
      <!-- TAB 1: APPROVAL ROUTES TABLE                                 -->
      <!-- ──────────────────────────────────────────────────────────── -->
      <div v-if="activeTab === 'approval'" class="tab-content-wrapper">
        <AppDataTable
          title="Approval Routes"
          subtitle="Financial governance matrix deciding who approves procurement documents based on value bands and document type."
          v-model:searchQuery="searchApproval"
          searchPlaceholder="Search routes, workflows, notes..."
          :showSearch="true"
          :showFilter="true"
          :showFullscreen="true"
          :filterCount="activeApprovalFilterCount"
          :showSort="true"
          :sortOptions="approvalSortOptions"
          v-model:currentSort="sortApproval"
          v-model:sortOrder="sortApprovalOrder"
          :showColumns="true"
          :columns="approvalTableColumns"
          :totalEntries="filteredApprovalRoutes.length"
          :showPagination="true"
          v-model:currentPage="currentApprovalPage"
          v-model:perPage="perApprovalPage"
          @toggleColumn="handleToggleApprovalColumn"
          @resetFilter="resetApprovalFilters"
        >
          <!-- Primary Action inside Toolbar: Quick Create Modal (<= 5 Required Fields) -->
          <template #actions>
            <AppButton variant="primary" size="sm" @click="openApprovalQuickModal">
              <template #icon-left>
                <Plus :size="15" />
              </template>
              Create Approval Route
            </AppButton>
          </template>

          <!-- Filter Popover Panel -->
          <template #filter-panel>
            <div class="filter-panel-grid">
              <FormSelect
                label="Document Type"
                v-model="filterDocType"
                :options="[{ value: '', label: 'All Document Types' }, ...documentTypeOptions]"
                placeholder="Select Type"
              />
              <FormSelect
                label="Workflow"
                v-model="filterApprovalWorkflow"
                :options="[{ value: '', label: 'All Workflows' }, ...workflowOptions]"
                placeholder="Select Workflow"
              />
              <FormSelect
                label="Priority"
                v-model="filterApprovalPriority"
                :options="[{ value: '', label: 'All Priorities' }, ...approvalPriorityOptions]"
                placeholder="Select Priority"
              />
              <FormSelect
                label="Category Scope"
                v-model="filterApprovalCategory"
                :options="approvalCategoryOptions"
                placeholder="Select Scope"
              />
              <FormSelect
                label="State"
                v-model="filterApprovalState"
                :options="[
                  { value: '', label: 'All States' },
                  { value: 'active', label: 'Active' },
                  { value: 'inactive', label: 'Inactive' }
                ]"
                placeholder="Select State"
              />
            </div>
            <div v-if="activeApprovalFilterCount > 0" class="filter-panel-footer">
              <AppButton variant="outline" size="sm" @click="resetApprovalFilters">
                Reset Filters
              </AppButton>
            </div>
          </template>

          <!-- Table Content -->
          <table class="erp-table">
            <thead>
              <tr>
                <th
                  v-if="isApprovalColVisible('document_type')"
                  class="sortable"
                  @click="handleSortApprovalColumn('document_type')"
                >
                  <div class="th-content name-header-content">
                    <FormCheckbox
                      :model-value="isAllApprovalSelected"
                      :indeterminate="isPartialApprovalSelected"
                      size="md"
                      @click.stop
                      @update:model-value="toggleSelectAllApproval"
                    >
                      <span class="sr-only">Select all routes on this page</span>
                    </FormCheckbox>
                    <span>Document Type</span>
                    <ArrowUpDown v-if="sortApproval === 'document_type'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isApprovalColVisible('workflow')"
                  class="sortable"
                  @click="handleSortApprovalColumn('workflow')"
                >
                  <div class="th-content">
                    <span>Approval Workflow</span>
                    <ArrowUpDown v-if="sortApproval === 'workflow'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isApprovalColVisible('floor_amount')"
                  class="sortable"
                  @click="handleSortApprovalColumn('floor_amount')"
                >
                  <div class="th-content">
                    <span>Floor Amount</span>
                    <ArrowUpDown v-if="sortApproval === 'floor_amount'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isApprovalColVisible('ceiling_amount')"
                  class="sortable"
                  @click="handleSortApprovalColumn('ceiling_amount')"
                >
                  <div class="th-content">
                    <span>Ceiling Amount</span>
                    <ArrowUpDown v-if="sortApproval === 'ceiling_amount'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isApprovalColVisible('priority')"
                  class="sortable"
                  @click="handleSortApprovalColumn('priority')"
                >
                  <div class="th-content">
                    <span>Priority</span>
                    <ArrowUpDown v-if="sortApproval === 'priority'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th v-if="isApprovalColVisible('scope_summary')">
                  <div class="th-content"><span>Scope Rules</span></div>
                </th>

                <th v-if="isApprovalColVisible('validity')">
                  <div class="th-content"><span>Validity</span></div>
                </th>

                <th
                  v-if="isApprovalColVisible('state')"
                  class="sortable"
                  @click="handleSortApprovalColumn('state')"
                >
                  <div class="th-content">
                    <span>State</span>
                    <ArrowUpDown v-if="sortApproval === 'state'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th v-if="isApprovalColVisible('actions')" class="col-actions">Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr v-if="paginatedApprovalRoutes.length === 0">
                <td :colspan="approvalTableColumns.filter(c => c.visible !== false).length" class="empty-state-cell">
                  <div class="empty-state-container">
                    <Route :size="32" class="empty-state-icon" />
                    <p class="empty-state-title">No approval routes found</p>
                    <p class="empty-state-subtext">Adjust your search or filters, or create a new route policy.</p>
                  </div>
                </td>
              </tr>

              <tr
                v-for="item in paginatedApprovalRoutes"
                :key="item.id"
                class="erp-row"
                :class="{ 'row-selected': selectedApprovalRowIds.includes(item.id) }"
                @click="openApprovalDetail(item)"
              >
                <!-- Identity Column -->
                <td v-if="isApprovalColVisible('document_type')" class="td-name">
                  <div class="name-cell-content">
                    <FormCheckbox
                      :model-value="selectedApprovalRowIds.includes(item.id)"
                      size="md"
                      @click.stop
                      @update:model-value="() => toggleSelectApprovalRow(item.id)"
                    >
                      <span class="sr-only">Select route #{{ item.id }}</span>
                    </FormCheckbox>
                    <div class="name-cell-stack">
                      <span class="table-name-primary">{{ item.document_type_name }}</span>
                      <span class="table-code-subtext">{{ item.document_type_id }} · #{{ item.id }}</span>
                    </div>
                  </div>
                </td>

                <td v-if="isApprovalColVisible('workflow')">
                  <span class="table-workflow-text">{{ item.workflow_name }}</span>
                </td>

                <td v-if="isApprovalColVisible('floor_amount')">
                  <span class="td-amount-bold">{{ formatApprovalCurrency(item.minimum_amount) }}</span>
                </td>

                <td v-if="isApprovalColVisible('ceiling_amount')">
                  <span v-if="item.maximum_amount !== null" class="td-amount-bold">
                    {{ formatApprovalCurrency(item.maximum_amount) }}
                  </span>
                  <BaseBadge v-else size="sm" color="blue">
                    Unlimited
                  </BaseBadge>
                </td>

                <td v-if="isApprovalColVisible('priority')">
                  <BaseBadge size="sm" :color="getPriorityBadgeColor(item.priority)">
                    Priority {{ item.priority }}
                  </BaseBadge>
                </td>

                <td v-if="isApprovalColVisible('scope_summary')">
                  <div class="scope-badges-cell">
                    <span v-if="!item.procurement_category_id && !item.purchase_method_id && !item.procurement_unit_id" class="scope-text-global">
                      Global Scope (All)
                    </span>
                    <template v-else>
                      <span v-if="item.category_name" class="scope-pill">Cat: {{ item.category_name }}</span>
                      <span v-if="item.method_name" class="scope-pill">Method: {{ item.method_name }}</span>
                      <span v-if="item.unit_name" class="scope-pill">Desk: {{ item.unit_name }}</span>
                    </template>
                  </div>
                </td>

                <td v-if="isApprovalColVisible('validity')">
                  <span class="tertiary-plain-text">
                    {{ formatDisplayDateRange(item.effective_from, item.effective_to, 'Open') }}
                  </span>
                </td>

                <td v-if="isApprovalColVisible('state')">
                  <BaseBadge
                    size="sm"
                    :color="item.state === 'active' ? 'success' : 'gray'"
                  >
                    {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                  </BaseBadge>
                </td>

                <td v-if="isApprovalColVisible('actions')" class="col-actions" @click.stop>
                  <div class="action-menu-container">
                    <button
                      type="button"
                      class="btn-action-dots"
                      @click.stop="toggleActionMenu(item.id)"
                      aria-label="Actions"
                    >
                      <MoreVertical :size="14" />
                    </button>

                    <div v-if="activeActionMenuId === item.id" class="action-dropdown-menu">
                      <button type="button" class="dropdown-menu-item" @click="openApprovalDetail(item)">
                        <Eye :size="14" class="menu-item-icon" />
                        <span>View Details</span>
                      </button>
                      <button
                        type="button"
                        class="dropdown-menu-item"
                        @click="() => { closeActionMenu(); router.push({ path: '/procurement/approval-routes/create', query: { editId: item.id } }); }"
                      >
                        <Edit2 :size="14" class="menu-item-icon" />
                        <span>Edit Route</span>
                      </button>
                      <div class="dropdown-divider"></div>
                      <button type="button" class="dropdown-menu-item" @click="handleToggleApprovalState(item)">
                        <Check :size="14" class="menu-item-icon" />
                        <span>{{ item.state === 'active' ? 'Deactivate Route' : 'Activate Route' }}</span>
                      </button>
                      <div class="dropdown-divider"></div>
                      <button type="button" class="dropdown-menu-item text-danger" @click="handleDeleteApproval(item)">
                        <Trash2 :size="14" class="menu-item-icon" />
                        <span>Delete Route</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </AppDataTable>
      </div>

      <!-- ──────────────────────────────────────────────────────────── -->
      <!-- TAB 2: ASSIGNMENT RULES TABLE                                -->
      <!-- ──────────────────────────────────────────────────────────── -->
      <div v-else-if="activeTab === 'assignment'" class="tab-content-wrapper">
        <AppDataTable
          title="Assignment Rules"
          subtitle="Operational demand dispatch rules assigning approved requisitions to designated buying desks and buyers."
          v-model:searchQuery="searchAssignment"
          searchPlaceholder="Search desks, buyers, categories..."
          :showSearch="true"
          :showFilter="true"
          :showFullscreen="true"
          :filterCount="activeAssignmentFilterCount"
          :showSort="true"
          :sortOptions="assignmentSortOptions"
          v-model:currentSort="sortAssignment"
          v-model:sortOrder="sortAssignmentOrder"
          :showColumns="true"
          :columns="assignmentTableColumns"
          :totalEntries="filteredAssignmentRules.length"
          :showPagination="true"
          v-model:currentPage="currentAssignmentPage"
          v-model:perPage="perAssignmentPage"
          @toggleColumn="handleToggleAssignmentColumn"
          @resetFilter="resetAssignmentFilters"
        >
          <!-- Primary Action inside Toolbar: Quick Create Modal (3 Required Fields) -->
          <template #actions>
            <AppButton variant="primary" size="sm" @click="openAssignmentQuickModal">
              <template #icon-left>
                <Plus :size="15" />
              </template>
              Create Assignment Rule
            </AppButton>
          </template>

          <!-- Filter Popover Panel -->
          <template #filter-panel>
            <div class="filter-panel-grid">
              <FormSelect
                label="Buying Desk"
                v-model="filterAssignmentUnit"
                :options="[{ value: '', label: 'All Buying Desks' }, ...assignmentUnitOptions]"
                placeholder="Select Desk"
              />
              <FormSelect
                label="Default Buyer"
                v-model="filterAssignmentBuyer"
                :options="[{ value: '', label: 'All Buyers' }, ...buyerOptions]"
                placeholder="Select Buyer"
              />
              <FormSelect
                label="Spend Category"
                v-model="filterAssignmentCategory"
                :options="assignmentCategoryOptions"
                placeholder="Select Category"
              />
              <FormSelect
                label="Sourcing Origin"
                v-model="filterAssignmentOrigin"
                :options="originOptions"
                placeholder="Select Origin"
              />
              <FormSelect
                label="Requesting Branch"
                v-model="filterAssignmentEntity"
                :options="requestingEntityOptions"
                placeholder="Select Entity"
              />
              <FormSelect
                label="State"
                v-model="filterAssignmentState"
                :options="[
                  { value: '', label: 'All States' },
                  { value: 'active', label: 'Active' },
                  { value: 'inactive', label: 'Inactive' }
                ]"
                placeholder="Select State"
              />
            </div>
            <div v-if="activeAssignmentFilterCount > 0" class="filter-panel-footer">
              <AppButton variant="outline" size="sm" @click="resetAssignmentFilters">
                Reset Filters
              </AppButton>
            </div>
          </template>

          <!-- Table Content -->
          <table class="erp-table">
            <thead>
              <tr>
                <th
                  v-if="isAssignmentColVisible('assigned_unit')"
                  class="sortable"
                  @click="handleSortAssignmentColumn('assigned_unit')"
                >
                  <div class="th-content name-header-content">
                    <FormCheckbox
                      :model-value="isAllAssignmentSelected"
                      :indeterminate="isPartialAssignmentSelected"
                      size="md"
                      @click.stop
                      @update:model-value="toggleSelectAllAssignment"
                    >
                      <span class="sr-only">Select all rules on this page</span>
                    </FormCheckbox>
                    <span>Assigned Buying Desk</span>
                    <ArrowUpDown v-if="sortAssignment === 'assigned_unit'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isAssignmentColVisible('default_buyer')"
                  class="sortable"
                  @click="handleSortAssignmentColumn('default_buyer')"
                >
                  <div class="th-content">
                    <span>Default Buyer</span>
                    <ArrowUpDown v-if="sortAssignment === 'default_buyer'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isAssignmentColVisible('category')"
                  class="sortable"
                  @click="handleSortAssignmentColumn('category')"
                >
                  <div class="th-content">
                    <span>Spend Category</span>
                    <ArrowUpDown v-if="sortAssignment === 'category'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isAssignmentColVisible('origin')"
                  class="sortable"
                  @click="handleSortAssignmentColumn('origin')"
                >
                  <div class="th-content">
                    <span>Origin</span>
                    <ArrowUpDown v-if="sortAssignment === 'origin'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isAssignmentColVisible('floor_amount')"
                  class="sortable"
                  @click="handleSortAssignmentColumn('floor_amount')"
                >
                  <div class="th-content">
                    <span>Floor Amount</span>
                    <ArrowUpDown v-if="sortAssignment === 'floor_amount'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isAssignmentColVisible('ceiling_amount')"
                  class="sortable"
                  @click="handleSortAssignmentColumn('ceiling_amount')"
                >
                  <div class="th-content">
                    <span>Ceiling Amount</span>
                    <ArrowUpDown v-if="sortAssignment === 'ceiling_amount'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isAssignmentColVisible('requesting_entity')"
                  class="sortable"
                  @click="handleSortAssignmentColumn('requesting_entity')"
                >
                  <div class="th-content">
                    <span>Requesting Branch</span>
                    <ArrowUpDown v-if="sortAssignment === 'requesting_entity'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isAssignmentColVisible('priority')"
                  class="sortable"
                  @click="handleSortAssignmentColumn('priority')"
                >
                  <div class="th-content">
                    <span>Priority</span>
                    <ArrowUpDown v-if="sortAssignment === 'priority'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th v-if="isAssignmentColVisible('validity')">
                  <div class="th-content"><span>Validity</span></div>
                </th>

                <th
                  v-if="isAssignmentColVisible('state')"
                  class="sortable"
                  @click="handleSortAssignmentColumn('state')"
                >
                  <div class="th-content">
                    <span>State</span>
                    <ArrowUpDown v-if="sortAssignment === 'state'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th v-if="isAssignmentColVisible('actions')" class="col-actions">Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr v-if="paginatedAssignmentRules.length === 0">
                <td :colspan="assignmentTableColumns.filter(c => c.visible !== false).length" class="empty-state-cell">
                  <div class="empty-state-container">
                    <GitPullRequest :size="32" class="empty-state-icon" />
                    <p class="empty-state-title">No assignment rules found</p>
                    <p class="empty-state-subtext">Adjust your search or filters, or create a new assignment rule.</p>
                  </div>
                </td>
              </tr>

              <tr
                v-for="item in paginatedAssignmentRules"
                :key="item.id"
                class="erp-row"
                :class="{ 'row-selected': selectedAssignmentRowIds.includes(item.id) }"
                @click="openAssignmentDetail(item)"
              >
                <!-- Identity Column -->
                <td v-if="isAssignmentColVisible('assigned_unit')" class="td-name">
                  <div class="name-cell-content">
                    <FormCheckbox
                      :model-value="selectedAssignmentRowIds.includes(item.id)"
                      size="md"
                      @click.stop
                      @update:model-value="() => toggleSelectAssignmentRow(item.id)"
                    >
                      <span class="sr-only">Select rule #{{ item.id }}</span>
                    </FormCheckbox>
                    <div class="name-cell-stack">
                      <span class="table-name-primary">{{ item.unit_name }}</span>
                      <span class="table-code-subtext">Rule #{{ item.id }} · {{ item.uuid.slice(0, 12) }}...</span>
                    </div>
                  </div>
                </td>

                <td v-if="isAssignmentColVisible('default_buyer')">
                  <div v-if="item.default_buyer_employee_id" class="buyer-table-cell">
                    <BaseAvatar
                      :src="item.buyer_avatar"
                      :name="item.buyer_name || 'Buyer'"
                      size="xs"
                    />
                    <span class="table-buyer-name">{{ item.buyer_name }}</span>
                  </div>
                  <span v-else class="tertiary-italic">Unassigned (Desk Lead)</span>
                </td>

                <td v-if="isAssignmentColVisible('category')">
                  <span :class="item.category_name ? 'table-category-text' : 'tertiary-plain-text'">
                    {{ item.category_name || 'All Categories (Global)' }}
                  </span>
                </td>

                <td v-if="isAssignmentColVisible('origin')">
                  <BaseBadge
                    v-if="item.origin_lookup_value_id === 'foreign'"
                    size="sm"
                    color="blue"
                  >
                    Foreign / Import
                  </BaseBadge>
                  <BaseBadge
                    v-else-if="item.origin_lookup_value_id === 'local'"
                    size="sm"
                    color="indigo"
                  >
                    Local Market
                  </BaseBadge>
                  <span v-else class="tertiary-plain-text">All Origins</span>
                </td>

                <td v-if="isAssignmentColVisible('floor_amount')">
                  <span class="td-amount-bold">{{ formatAssignmentCurrency(item.minimum_amount) }}</span>
                </td>

                <td v-if="isAssignmentColVisible('ceiling_amount')">
                  <span v-if="item.maximum_amount !== null" class="td-amount-bold">
                    {{ formatAssignmentCurrency(item.maximum_amount) }}
                  </span>
                  <BaseBadge v-else size="sm" color="blue">
                    Unlimited
                  </BaseBadge>
                </td>

                <td v-if="isAssignmentColVisible('requesting_entity')">
                  <span class="tertiary-plain-text">
                    {{ item.requesting_entity_name || 'All Branches (Enterprise)' }}
                  </span>
                </td>

                <td v-if="isAssignmentColVisible('priority')">
                  <BaseBadge size="sm" :color="getPriorityBadgeColor(item.priority)">
                    Priority {{ item.priority }}
                  </BaseBadge>
                </td>

                <td v-if="isAssignmentColVisible('validity')">
                  <span class="tertiary-plain-text">
                    {{ formatDisplayDateRange(item.effective_from, item.effective_to, 'Open') }}
                  </span>
                </td>

                <td v-if="isAssignmentColVisible('state')">
                  <BaseBadge
                    size="sm"
                    :color="item.state === 'active' ? 'success' : 'gray'"
                  >
                    {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                  </BaseBadge>
                </td>

                <td v-if="isAssignmentColVisible('actions')" class="col-actions" @click.stop>
                  <div class="action-menu-container">
                    <button
                      type="button"
                      class="btn-action-dots"
                      @click.stop="toggleActionMenu(item.id)"
                      aria-label="Actions"
                    >
                      <MoreVertical :size="14" />
                    </button>

                    <div v-if="activeActionMenuId === item.id" class="action-dropdown-menu">
                      <button type="button" class="dropdown-menu-item" @click="openAssignmentDetail(item)">
                        <Eye :size="14" class="menu-item-icon" />
                        <span>View Details</span>
                      </button>
                      <button
                        type="button"
                        class="dropdown-menu-item"
                        @click="() => { closeActionMenu(); router.push({ path: '/procurement/assignment-rules/create', query: { editId: item.id } }); }"
                      >
                        <Edit2 :size="14" class="menu-item-icon" />
                        <span>Edit Rule</span>
                      </button>
                      <div class="dropdown-divider"></div>
                      <button type="button" class="dropdown-menu-item" @click="handleToggleAssignmentState(item)">
                        <Check :size="14" class="menu-item-icon" />
                        <span>{{ item.state === 'active' ? 'Deactivate Rule' : 'Activate Rule' }}</span>
                      </button>
                      <div class="dropdown-divider"></div>
                      <button type="button" class="dropdown-menu-item text-danger" @click="handleDeleteAssignment(item)">
                        <Trash2 :size="14" class="menu-item-icon" />
                        <span>Delete Rule</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </AppDataTable>
      </div>

      <!-- ──────────────────────────────────────────────────────────── -->
      <!-- TAB 3: APPROVAL DELEGATIONS TABLE                            -->
      <!-- ──────────────────────────────────────────────────────────── -->
      <div v-else-if="activeTab === 'delegations'" class="tab-content-wrapper">
        <AppDataTable
          title="Approval Delegations"
          subtitle="Temporary transfer of financial approval authority during absence, leave, or vacancies."
          v-model:searchQuery="searchDelegation"
          searchPlaceholder="Search approvers, delegates, scope, notes..."
          :showSearch="true"
          :showFilter="true"
          :showFullscreen="true"
          :filterCount="activeDelegationFilterCount"
          :showSort="true"
          :sortOptions="delegationSortOptions"
          v-model:currentSort="sortDelegation"
          v-model:sortOrder="sortDelegationOrder"
          :showColumns="true"
          :columns="delegationTableColumns"
          :totalEntries="filteredDelegations.length"
          :showPagination="true"
          v-model:currentPage="currentDelegationPage"
          v-model:perPage="perDelegationPage"
          @toggleColumn="handleToggleDelegationColumn"
          @resetFilter="resetDelegationFilters"
        >
          <!-- Primary Action inside Toolbar: Quick Create Modal (<= 5 Required Fields) -->
          <template #actions>
            <AppButton variant="primary" size="sm" @click="openDelegationQuickModal">
              <template #icon-left>
                <Plus :size="15" />
              </template>
              Create Delegation
            </AppButton>
          </template>

          <!-- Filter Popover Panel -->
          <template #filter-panel>
            <div class="filter-panel-grid">
              <FormSelect
                label="Absent Approver"
                v-model="filterDelegator"
                :options="[{ value: '', label: 'All Absent Approvers' }, ...delegatorUserOptions]"
                placeholder="Select Approver"
              />
              <FormSelect
                label="Acting Delegate"
                v-model="filterDelegate"
                :options="[{ value: '', label: 'All Acting Delegates' }, ...delegateUserOptions]"
                placeholder="Select Delegate"
              />
              <FormSelect
                label="Document Scope"
                v-model="filterDelegationDocType"
                :options="delegationDocTypeOptions"
                placeholder="Select Scope"
              />
              <FormSelect
                label="Delegation Reason"
                v-model="filterDelegationType"
                :options="[{ value: '', label: 'All Reasons' }, ...delegationTypeOptions]"
                placeholder="Select Reason"
              />
              <FormSelect
                label="Delegation Status"
                v-model="filterDelegationStatus"
                :options="[{ value: '', label: 'All Statuses' }, ...delegationStatusOptions]"
                placeholder="Select Status"
              />
            </div>
            <div v-if="activeDelegationFilterCount > 0" class="filter-panel-footer">
              <AppButton variant="outline" size="sm" @click="resetDelegationFilters">
                Reset Filters
              </AppButton>
            </div>
          </template>

          <!-- Table Content -->
          <table class="erp-table">
            <thead>
              <tr>
                <th
                  v-if="isDelegationColVisible('delegator_name')"
                  class="sortable"
                  @click="handleSortDelegationColumn('delegator_name')"
                >
                  <div class="th-content name-header-content">
                    <FormCheckbox
                      :model-value="isAllDelegationSelected"
                      :indeterminate="isPartialDelegationSelected"
                      size="md"
                      @click.stop
                      @update:model-value="toggleSelectAllDelegation"
                    >
                      <span class="sr-only">Select all delegations on this page</span>
                    </FormCheckbox>
                    <span>Absent Approver</span>
                    <ArrowUpDown v-if="sortDelegation === 'delegator_name'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isDelegationColVisible('delegate_name')"
                  class="sortable"
                  @click="handleSortDelegationColumn('delegate_name')"
                >
                  <div class="th-content">
                    <span>Acting Delegate</span>
                    <ArrowUpDown v-if="sortDelegation === 'delegate_name'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isDelegationColVisible('document_type_id')"
                  class="sortable"
                  @click="handleSortDelegationColumn('document_type_id')"
                >
                  <div class="th-content">
                    <span>Document Scope</span>
                    <ArrowUpDown v-if="sortDelegation === 'document_type_id'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isDelegationColVisible('maximum_amount')"
                  class="sortable"
                  @click="handleSortDelegationColumn('maximum_amount')"
                >
                  <div class="th-content">
                    <span>Ceiling Amount</span>
                    <ArrowUpDown v-if="sortDelegation === 'maximum_amount'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isDelegationColVisible('valid_from')"
                  class="sortable"
                  @click="handleSortDelegationColumn('valid_from')"
                >
                  <div class="th-content">
                    <span>Effective Period</span>
                    <ArrowUpDown v-if="sortDelegation === 'valid_from'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isDelegationColVisible('type_lookup_value_id')"
                  class="sortable"
                  @click="handleSortDelegationColumn('type_lookup_value_id')"
                >
                  <div class="th-content">
                    <span>Delegation Reason</span>
                    <ArrowUpDown v-if="sortDelegation === 'type_lookup_value_id'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th
                  v-if="isDelegationColVisible('delegation_status_lookup_value_id')"
                  class="sortable"
                  @click="handleSortDelegationColumn('delegation_status_lookup_value_id')"
                >
                  <div class="th-content">
                    <span>Status</span>
                    <ArrowUpDown v-if="sortDelegation === 'delegation_status_lookup_value_id'" :size="12" class="sort-icon active-sort" />
                  </div>
                </th>

                <th v-if="isDelegationColVisible('actions')" class="col-actions">Actions</th>
              </tr>
            </thead>

            <tbody>
              <tr v-if="paginatedDelegations.length === 0">
                <td :colspan="delegationTableColumns.filter(c => c.visible !== false).length" class="empty-state-cell">
                  <div class="empty-state-container">
                    <UserCheck :size="32" class="empty-state-icon" />
                    <p class="empty-state-title">No approval delegations found</p>
                    <p class="empty-state-subtext">Adjust your search or filters, or create an authority handover.</p>
                  </div>
                </td>
              </tr>

              <tr
                v-for="item in paginatedDelegations"
                :key="item.id"
                class="erp-row"
                :class="{ 'row-selected': selectedDelegationRowIds.includes(item.id) }"
                @click="openDelegationDetail(item)"
              >
                <!-- Absent Approver (Identity Column with lead checkbox) -->
                <td v-if="isDelegationColVisible('delegator_name')" class="td-name">
                  <div class="name-cell-content">
                    <FormCheckbox
                      :model-value="selectedDelegationRowIds.includes(item.id)"
                      size="md"
                      @click.stop
                      @update:model-value="() => toggleSelectDelegationRow(item.id)"
                    >
                      <span class="sr-only">Select delegation #{{ item.id }}</span>
                    </FormCheckbox>
                    <BaseAvatar
                      :src="item.delegator_avatar"
                      :name="item.delegator_name"
                      size="xs"
                    />
                    <div class="name-cell-stack">
                      <span class="table-name-primary">{{ item.delegator_name }}</span>
                      <span class="table-code-subtext">{{ item.delegator_role || item.delegator_title || 'Approver' }}</span>
                    </div>
                  </div>
                </td>

                <!-- Acting Delegate -->
                <td v-if="isDelegationColVisible('delegate_name')">
                  <div class="buyer-table-cell">
                    <BaseAvatar
                      :src="item.delegate_avatar"
                      :name="item.delegate_name"
                      size="xs"
                    />
                    <div class="name-cell-stack">
                      <span class="table-buyer-name">{{ item.delegate_name }}</span>
                      <span class="table-code-subtext">{{ item.delegate_role || item.delegate_title || 'Delegate' }}</span>
                    </div>
                  </div>
                </td>

                <!-- Scope -->
                <td v-if="isDelegationColVisible('document_type_id')">
                  <BaseBadge
                    v-if="item.document_type_id"
                    size="sm"
                    color="indigo"
                  >
                    {{ item.document_type_id }}
                  </BaseBadge>
                  <span v-else class="tertiary-plain-text">All Documents</span>
                </td>

                <!-- Ceiling Amount -->
                <td v-if="isDelegationColVisible('maximum_amount')">
                  <span v-if="item.maximum_amount !== null" class="td-amount-bold">
                    {{ formatDelegationCurrency(item.maximum_amount) }}
                  </span>
                  <BaseBadge v-else size="sm" color="blue">
                    Full Authority
                  </BaseBadge>
                </td>

                <!-- Validity Period -->
                <td v-if="isDelegationColVisible('valid_from')">
                  <span class="tertiary-plain-text">
                    {{ formatDisplayDateRange(item.valid_from, item.valid_to, 'Open') }}
                  </span>
                </td>

                <!-- Reason / Type -->
                <td v-if="isDelegationColVisible('type_lookup_value_id')">
                  <span class="table-reason-text">
                    {{ getDelegationTypeLabel(item.type_lookup_value_id) }}
                  </span>
                </td>

                <!-- Status -->
                <td v-if="isDelegationColVisible('delegation_status_lookup_value_id')">
                  <BaseBadge
                    size="sm"
                    :color="getDelegationStatusBadgeColor(item.delegation_status_lookup_value_id)"
                  >
                    {{ getDelegationStatusLabel(item.delegation_status_lookup_value_id) }}
                  </BaseBadge>
                </td>

                <!-- Actions -->
                <td v-if="isDelegationColVisible('actions')" class="col-actions" @click.stop>
                  <div class="action-menu-container">
                    <button
                      type="button"
                      class="btn-action-dots"
                      @click.stop="toggleActionMenu(item.id)"
                      aria-label="Actions"
                    >
                      <MoreVertical :size="14" />
                    </button>

                    <div v-if="activeActionMenuId === item.id" class="action-dropdown-menu">
                      <button type="button" class="dropdown-menu-item" @click="openDelegationDetail(item)">
                        <Eye :size="14" class="menu-item-icon" />
                        <span>View Details</span>
                      </button>
                      <button
                        type="button"
                        class="dropdown-menu-item"
                        @click="() => { closeActionMenu(); router.push({ path: '/procurement/delegations/create', query: { editId: item.id } }); }"
                      >
                        <Edit2 :size="14" class="menu-item-icon" />
                        <span>Edit Delegation</span>
                      </button>
                      <div class="dropdown-divider"></div>
                      <button type="button" class="dropdown-menu-item" @click="handleToggleDelegationStatus(item)">
                        <Check :size="14" class="menu-item-icon" />
                        <span>{{ item.delegation_status_lookup_value_id === 'active' ? 'Revoke Delegation' : 'Activate Delegation' }}</span>
                      </button>
                      <div class="dropdown-divider"></div>
                      <button type="button" class="dropdown-menu-item text-danger" @click="handleDeleteDelegation(item)">
                        <Trash2 :size="14" class="menu-item-icon" />
                        <span>Delete Delegation</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </AppDataTable>
      </div>
    </template>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- BULK ACTIONS FLOATING BAR (Rule 17)                            -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <TableFloatingBar
      :selectedCount="activeSelectedCount"
      @clear="() => { selectedApprovalRowIds = []; selectedAssignmentRowIds = []; selectedDelegationRowIds = []; }"
    >
      <AppButton variant="secondary-gray" size="sm" @click="handleBulkActivate">
        Activate Selected
      </AppButton>
      <AppButton variant="secondary-gray" size="sm" @click="handleBulkDeactivate">
        Deactivate Selected
      </AppButton>
      <AppButton variant="danger" size="sm" @click="handleBulkDelete">
        Delete Selected
      </AppButton>
    </TableFloatingBar>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- QUICK CREATE MODAL: APPROVAL ROUTE (<= 5 Required Fields)      -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <QuickCreateModal
      v-model:show="showApprovalQuickModal"
      title="Create Approval Route"
      width="md"
      @expand="handleExpandApprovalForm"
      @save="handleQuickSaveApprovalRoute"
    >
      <div class="quick-modal-form">
        <div class="modal-grid-2">
          <FormSelect
            v-model="approvalQuickForm.document_type_id"
            label="Document Type"
            :options="documentTypeOptions"
            placeholder="Select Type"
            :error="approvalQuickErrors.document_type_id"
            required
          />
          <FormSelect
            v-model="approvalQuickForm.workflow_id"
            label="Target Workflow"
            :options="approvalQuickWorkflowOptions"
            placeholder="Select Workflow"
            :error="approvalQuickErrors.workflow_id"
            required
          />
        </div>

        <div class="modal-grid-2">
          <FormInput
            v-model.number="approvalQuickForm.minimum_amount"
            type="number"
            label="Minimum Floor Amount (ETB)"
            :error="approvalQuickErrors.minimum_amount"
            required
          />
          <FormSelect
            v-model="approvalQuickForm.priority"
            label="Precedence Priority"
            :options="approvalPriorityOptions"
            placeholder="Select Priority"
            required
          />
        </div>

        <FormInput
          v-model="approvalQuickForm.effective_from"
          type="date"
          label="Effective From"
          :error="approvalQuickErrors.effective_from"
          required
        />

        <FormCheckboxCard
          v-model="approvalQuickForm.is_unlimited"
          :expand-when-checked="false"
          label="Unlimited / Open Ceiling"
          description="No upper limit above the minimum floor amount."
        >
          <FormInput
            v-model.number="approvalQuickForm.maximum_amount"
            type="number"
            label="Maximum Ceiling Amount (ETB)"
            :error="approvalQuickErrors.maximum_amount"
            placeholder="Enter Ceiling"
            required
          />
        </FormCheckboxCard>
      </div>
    </QuickCreateModal>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- QUICK CREATE MODAL: ASSIGNMENT RULE                            -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <QuickCreateModal
      v-model:show="showAssignmentQuickModal"
      title="Create Assignment Rule"
      width="md"
      @expand="handleExpandAssignmentForm"
      @save="handleQuickSaveAssignmentRule"
    >
      <div class="quick-modal-form">
        <div class="modal-grid-2">
          <FormSelect
            v-model="assignmentQuickForm.procurement_unit_id"
            label="Assigned Buying Desk"
            :options="assignmentUnitOptions"
            placeholder="Select Buying Desk"
            :error="assignmentQuickErrors.procurement_unit_id"
            required
          />
          <FormSelect
            v-model="assignmentQuickForm.default_buyer_employee_id"
            label="Default Assigned Buyer"
            :options="[{ value: '', label: 'Unit Lead Assigns' }, ...buyerOptions]"
            placeholder="Select Buyer"
          />
        </div>

        <div class="modal-grid-2">
          <FormSelect
            v-model="assignmentQuickForm.procurement_category_id"
            label="Spend Category"
            :options="[{ value: '', label: 'All Categories' }, ...assignmentCategoryOptions]"
            placeholder="Select Category"
          />
          <FormSelect
            v-model="assignmentQuickForm.priority"
            label="Precedence Priority"
            :options="approvalPriorityOptions"
            placeholder="Select Priority"
            required
          />
        </div>

        <div class="modal-grid-2">
          <FormInput
            v-model.number="assignmentQuickForm.minimum_amount"
            type="number"
            label="Minimum Floor Amount (ETB)"
            :error="assignmentQuickErrors.minimum_amount"
            required
          />
          <FormInput
            v-model="assignmentQuickForm.effective_from"
            type="date"
            label="Effective From"
            :error="assignmentQuickErrors.effective_from"
            required
          />
        </div>

        <FormCheckboxCard
          v-model="assignmentQuickForm.is_unlimited"
          :expand-when-checked="false"
          label="Unlimited / Open Ceiling"
          description="Rule applies to all demand values exceeding the minimum floor without upper limit."
        >
          <FormInput
            v-model.number="assignmentQuickForm.maximum_amount"
            type="number"
            label="Maximum Ceiling Amount (ETB)"
            :error="assignmentQuickErrors.maximum_amount"
            placeholder="Enter maximum ceiling amount"
            required
          />
        </FormCheckboxCard>
      </div>
    </QuickCreateModal>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- QUICK CREATE MODAL: APPROVAL DELEGATION                         -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <QuickCreateModal
      v-model:show="showDelegationQuickModal"
      title="Create Approval Delegation"
      width="md"
      @expand="handleExpandDelegationForm"
      @save="handleQuickSaveDelegation"
    >
      <div class="quick-modal-form">
        <div class="modal-grid-2">
          <FormSelect
            v-model="delegationQuickForm.delegator_user_id"
            label="Absent Approver"
            :options="delegatorUserOptions"
            placeholder="Select Approver"
            :error="delegationQuickErrors.delegator_user_id"
            required
          />
          <FormSelect
            v-model="delegationQuickForm.delegate_user_id"
            label="Acting Delegate"
            :options="delegateUserOptions"
            placeholder="Select Delegate"
            :error="delegationQuickErrors.delegate_user_id"
            required
          />
        </div>

        <div class="modal-grid-2">
          <FormSelect
            v-model="delegationQuickForm.type_lookup_value_id"
            label="Delegation Reason"
            :options="delegationTypeOptions"
            placeholder="Select Reason"
            required
          />
          <FormSelect
            v-model="delegationQuickForm.document_type_id"
            label="Document Scope"
            :options="delegationDocTypeOptions"
            placeholder="Select Scope (Optional)"
          />
        </div>

        <div class="modal-grid-2">
          <FormInput
            v-model="delegationQuickForm.valid_from"
            type="date"
            label="Effective From"
            :error="delegationQuickErrors.valid_from"
            required
          />
          <FormInput
            v-model="delegationQuickForm.valid_to"
            type="date"
            label="Effective To"
            :error="delegationQuickErrors.valid_to"
            required
          />
        </div>

        <FormCheckboxCard
          v-model="delegationQuickForm.is_full_authority"
          :expand-when-checked="false"
          label="Full Authority (No Monetary Ceiling)"
          description="Acting delegate retains complete approval threshold of the absent approver."
        >
          <FormInput
            v-model.number="delegationQuickForm.maximum_amount"
            type="number"
            label="Maximum Authority Ceiling (ETB)"
            :error="delegationQuickErrors.maximum_amount"
            placeholder="Enter ceiling amount in ETB"
            required
          />
        </FormCheckboxCard>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.routing-rules-view {
  display: flex;
  flex-direction: column;
  gap: 20px;
  width: 100%;
}

/* Breadcrumb Header Row on Transparent Canvas */
.breadcrumb-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: transparent;
  padding: 0;
  margin: 0;
}

/* Unified Top Card (Attendance Standard: Metric Cards + Tabs in One White Section) */
.routing-top-card {
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
}

/* 4 KPI Metrics Grid (Figma 10178:31133 Standard) */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px;
}

/* BaseTabs Capsule Styling inside Top Card (Attendance View Standard) */
.top-card-tabs-wrapper {
  display: flex;
  align-items: center;
  width: 100%;
}

.tabs-container {
  display: flex;
  align-items: center;
  width: 100%;
}

.tab-content-wrapper {
  display: flex;
  flex-direction: column;
  gap: 16px;
  width: 100%;
}

/* Filter Popover Panel Styles */
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

/* ERP Table Standards */
.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
  font-size: 13px;
}

.erp-table thead tr {
  background-color: #fafafa;
  border-bottom: 1px solid #e5e5e5;
}

.erp-table th {
  padding: 12px 16px;
  font-size: 12px;
  font-weight: 600;
  color: #737373;
  letter-spacing: 0.02em;
  user-select: none;
}

.erp-table th.sortable {
  cursor: pointer;
}

.erp-table th.sortable:hover {
  color: #404040;
}

.th-content {
  display: flex;
  align-items: center;
  gap: 6px;
}

.name-header-content {
  gap: 12px;
}

.sort-icon {
  color: #a3a3a3;
}

.active-sort {
  color: #0b529c;
}

.erp-row {
  border-bottom: 1px solid #e5e5e5;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.erp-row:hover {
  background-color: #fafafa;
}

.erp-row.row-selected {
  background-color: #f0f7ff;
}

.erp-table td {
  padding: 14px 16px;
  vertical-align: middle;
}

/* Identity / Lead Cell */
.td-name {
  min-width: 220px;
}

.name-cell-content {
  display: flex;
  align-items: center;
  gap: 12px;
}

.name-cell-stack {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-name-primary {
  font-weight: 600;
  color: #404040;
  font-size: 13px;
}

.table-code-subtext {
  font-size: 11px;
  color: #737373;
  font-family: monospace;
}

.table-workflow-text {
  color: #404040;
  font-size: 13px;
  font-weight: 500;
  max-width: 280px;
  display: inline-block;
  line-height: 1.3;
}

.buyer-table-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.table-buyer-name {
  color: #404040;
  font-weight: 500;
  font-size: 13px;
}

.table-category-text {
  color: #404040;
  font-size: 13px;
  font-weight: 500;
}

.table-reason-text {
  color: #404040;
  font-size: 13px;
  font-weight: 500;
  white-space: nowrap;
}

.td-amount-bold {
  font-weight: 600;
  color: #404040;
  font-size: 13px;
  white-space: nowrap;
}

.tertiary-plain-text {
  color: #737373;
  font-size: 13px;
}

.tertiary-italic {
  color: #737373;
  font-size: 12px;
  font-style: italic;
}

/* Scope Rule Pill Badges */
.scope-badges-cell {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  align-items: center;
}

.scope-text-global {
  font-size: 12px;
  color: #737373;
  font-style: italic;
}

.scope-pill {
  font-size: 11px;
  background-color: #f5f5f5;
  color: #404040;
  padding: 2px 6px;
  border-radius: 4px;
  border: 1px solid #e5e5e5;
  white-space: nowrap;
}

/* Actions Column & Kebab Menu */
.col-actions {
  text-align: right;
  width: 60px;
}

.action-menu-container {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 6px;
  border-radius: 6px;
  color: #737373;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.action-dropdown-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
  z-index: 100;
  min-width: 180px;
  padding: 4px;
}

.dropdown-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 12px;
  background: transparent;
  border: none;
  text-align: left;
  font-size: 13px;
  color: #404040;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.12s ease;
}

.dropdown-menu-item:hover {
  background-color: #f5f5f5;
}

.dropdown-menu-item.text-danger {
  color: #e7000b;
}

.dropdown-menu-item.text-danger:hover {
  background-color: #fee2e2;
}

.menu-item-icon {
  color: #737373;
}

.dropdown-menu-item.text-danger .menu-item-icon {
  color: #e7000b;
}

.dropdown-divider {
  height: 1px;
  background-color: #e5e5e5;
  margin: 4px 0;
}

/* Empty State */
.empty-state-cell {
  padding: 60px 16px;
  text-align: center;
}

.empty-state-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.empty-state-icon {
  color: #a3a3a3;
}

.empty-state-title {
  font-weight: 600;
  color: #404040;
  font-size: 14px;
  margin: 0;
}

.empty-state-subtext {
  font-size: 13px;
  color: #737373;
  margin: 0;
}

/* Inspection Dossier Styles */
.detail-view-wrapper {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.detail-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.detail-header-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
}

.detail-title {
  font-size: 20px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.detail-code {
  font-size: 12px;
  color: #737373;
  font-family: monospace;
}

.detail-badges {
  display: flex;
  align-items: center;
  gap: 8px;
}

.detail-divider {
  height: 1px;
  background-color: #e5e5e5;
  width: 100%;
}

.detail-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
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
  color: #404040;
}

.detail-value.text-bold {
  font-weight: 600;
}

.buyer-profile-inline {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* Accordion Description Card */
.clean-card.accordion-card {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  overflow: hidden;
}

.card-accordion-header {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 4px;
  padding: 16px 24px;
  font-size: 14px;
  font-weight: 600;
  color: #404040;
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

.card-accordion-divider {
  display: none;
}

.card-accordion-body {
  padding: 20px 24px 24px;
  background-color: #ffffff;
}

.detail-description {
  font-size: 14px;
  line-height: 1.6;
  color: #404040;
  margin: 0;
}

.quick-modal-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
  align-items: start;
}

.modal-checkbox-align {
  padding-top: 22px;
}

@media (max-width: 640px) {
  .modal-grid-2 {
    grid-template-columns: 1fr;
  }

  .modal-checkbox-align {
    padding-top: 0;
  }
}
</style>
