<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRouter } from 'vue-router';
import {
  Monitor, ChevronRight, Search, Filter, ArrowUpDown, ChevronDown, Maximize,
  Download, Eye, Check, X, ShieldAlert, Sparkles, AlertTriangle, RefreshCw,
  FileText, Clock, User, Shield, Key, Building2, Database, Box, ShoppingBag,
  ShoppingCart, Lock, Unlock, UserCheck, RotateCcw, ArrowRight, CornerDownRight,
  Bot, HelpCircle, FileSpreadsheet, FileCode, CheckCircle2, XCircle, Sliders,
  MoreVertical, TrendingUp
} from 'lucide-vue-next';
import BaseTabs from '../components/BaseTabs.vue';
import MetricCard from '../components/MetricCard.vue';
import BasePagination from '../components/BasePagination.vue';
import BaseButton from '../components/BaseButton.vue';

const router = useRouter();

// Active Tab (`BaseTabs`)
type TabId = 'all' | 'security' | 'master_data' | 'transactions' | 'sessions';
const activeTab = ref<TabId>('all');

const tabs: { id: TabId; label: string }[] = [
  { id: 'all', label: 'All Audit Logs' },
  { id: 'security', label: 'Security & Access' },
  { id: 'master_data', label: 'Master Data Changes' },
  { id: 'transactions', label: 'Transactions & Documents' },
  { id: 'sessions', label: 'Session Activity' }
];

// Controls & Filter State
const searchQuery = ref('');
const dateFilter = ref<string>('All');
const userFilter = ref<string>('All');
const moduleFilter = ref<string>('All');
const entityFilter = ref<string>('All');
const entityTypeFilter = ref<string>('All');
const recordTypeFilter = ref<string>('All');
const actionFilter = ref<string>('All');
const statusFilter = ref<string>('All');
const riskFilter = ref<string>('All');
const ipFilter = ref<string>('');
const sessionIdFilter = ref<string>('');

const showFilterSection = ref(false);
const showSortDropdown = ref(false);
const showExportDropdown = ref(false);

const activeFilterCount = computed(() => {
  let count = 0;
  if (userFilter.value !== 'All') count++;
  if (moduleFilter.value !== 'All') count++;
  if (entityFilter.value !== 'All') count++;
  if (actionFilter.value !== 'All') count++;
  if (riskFilter.value !== 'All') count++;
  if (statusFilter.value !== 'All') count++;
  if (ipFilter.value.trim() !== '') count++;
  if (sessionIdFilter.value.trim() !== '') count++;
  return count;
});

const sortBy = ref<'timestamp' | 'risk' | 'action' | 'user'>('timestamp');
const sortOrder = ref<'asc' | 'desc'>('desc');

const toggleSort = (field: 'timestamp' | 'risk' | 'action' | 'user') => {
  if (sortBy.value === field) {
    sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
  } else {
    sortBy.value = field;
    sortOrder.value = 'desc';
  }
  showSortDropdown.value = false;
};

// Selection State
const selectedLogIds = ref<number[]>([]);
const selectAll = ref(false);

const toggleSelectAll = () => {
  if (selectAll.value) {
    selectedLogIds.value = filteredLogs.value.map(l => l.id);
  } else {
    selectedLogIds.value = [];
  }
};

const isLogSelected = (id: number) => selectedLogIds.value.includes(id);

const toggleLogSelection = (id: number) => {
  if (isLogSelected(id)) {
    selectedLogIds.value = selectedLogIds.value.filter(i => i !== id);
  } else {
    selectedLogIds.value.push(id);
  }
};

// Side Drawer State for Log Details & Before vs After
const selectedLog = ref<any | null>(null);
const isDrawerOpen = ref(false);

const openLogDetails = (log: any) => {
  selectedLog.value = log;
  isDrawerOpen.value = true;
};

const closeDrawer = () => {
  isDrawerOpen.value = false;
  selectedLog.value = null;
};

// Toast Notifications
const toastMessage = ref<string | null>(null);
const toastType = ref<'success' | 'info' | 'warning'>('success');

const showToast = (msg: string, type: 'success' | 'info' | 'warning' = 'success') => {
  toastMessage.value = msg;
  toastType.value = type;
  setTimeout(() => {
    toastMessage.value = null;
  }, 3500);
};

// Revert / Undo action simulation
const handleUndoAction = (log: any) => {
  if (!log.undoAvailable) {
    showToast('This action cannot be undone automatically.', 'warning');
    return;
  }
  if (confirm(`Are you sure you want to revert action "${log.action}" on record "${log.recordName}"?`)) {
    log.isUndone = true;
    showToast(`Successfully reverted changes for record #${log.recordId}!`, 'success');
  }
};

// Export Functionality
const handleExport = (format: 'Excel' | 'CSV' | 'PDF') => {
  showExportDropdown.value = false;
  showToast(`Exporting ${filteredLogs.value.length} audit logs as ${format}...`, 'info');
};

// AI Search Assistant Drawer
const isAiAssistantOpen = ref(false);
const aiQueryInput = ref('');
const aiResponse = ref<string | null>(null);
const isAiThinking = ref(false);

const presetAiQueries = [
  "Show me every product deleted by John last week",
  "Who changed the price of Coca-Cola?",
  "List all failed login attempts today",
  "Show high risk permission changes in System Config",
  "Show recent inventory adjustments in Bole Branch"
];

const executeAiQuery = (queryText: string) => {
  aiQueryInput.value = queryText;
  isAiThinking.value = true;
  aiResponse.value = null;

  setTimeout(() => {
    isAiThinking.value = false;
    const q = queryText.toLowerCase();

    if (q.includes('deleted') || q.includes('john')) {
      searchQuery.value = 'John';
      actionFilter.value = 'Delete';
      aiResponse.value = `Found 1 deleted record by John Doe (Inventory Officer). Filter applied for Action: Delete & User: John.`;
    } else if (q.includes('price') || q.includes('coca-cola')) {
      searchQuery.value = 'Coca-Cola';
      aiResponse.value = `Found 1 price update event: Marta Tadesse updated Coca-Cola 500ml Unit Price from $120.00 to $150.00 on Aug 06, 2026.`;
    } else if (q.includes('failed login') || q.includes('failed')) {
      actionFilter.value = 'Failed Login';
      aiResponse.value = `Found 2 failed login attempts from IP 192.168.1.104 targeting admin account. Status set to Failed Login.`;
    } else if (q.includes('permission') || q.includes('permission changes')) {
      moduleFilter.value = 'System Configuration';
      recordTypeFilter.value = 'Permissions';
      aiResponse.value = `Found permission modification by Abebe Kebede: Granted "Delete User" permission to Branch Manager role.`;
    } else {
      searchQuery.value = queryText;
      aiResponse.value = `Filtered audit log trail matching query: "${queryText}". Showing ${filteredLogs.value.length} matching events.`;
    }
  }, 600);
};

// Audit Log Seed Data covering all requested ERP master tables & actions
const logs = ref([
  {
    id: 101,
    timestamp: '2026-08-06 09:35:14',
    timeRelative: '7m ago',
    userId: 1,
    userName: 'Abebe Kebede',
    userEmail: 'abebe@haleta.com',
    userRole: 'Admin',
    userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    module: 'Inventory',
    entity: 'Bole Road Branch',
    entityType: 'Branch',
    action: 'Update',
    riskLevel: 'Medium',
    recordType: 'Products',
    recordId: 'PRD-9042',
    recordName: 'Coca-Cola 500ml Plastic Bottle',
    documentNumber: 'DOC-INV-2026-0091',
    parentRecord: 'PRD-GRP-BEVERAGE',
    workflowStep: 'Price Review',
    approvalLevel: 'Level 2 - Manager Approved',
    description: 'Updated product unit price and category stock status',
    result: 'Success',
    ipAddress: '192.168.1.45',
    device: 'Chrome 127 / macOS Sonoma',
    sessionId: 'SESS-8942-0806',
    undoAvailable: true,
    isUndone: false,
    diff: [
      { field: 'Price', before: '$120.00', after: '$150.00', isChanged: true, isSensitive: false },
      { field: 'Status', before: 'Active', after: 'Inactive', isChanged: true, isSensitive: false },
      { field: 'Brand', before: 'ABC Soft Drinks', after: 'XYZ Beverages', isChanged: true, isSensitive: false },
      { field: 'Min Order Qty', before: '50 Units', after: '50 Units', isChanged: false, isSensitive: false },
      { field: 'Tax Rate', before: '15%', after: '15%', isChanged: false, isSensitive: false }
    ],
    sessionHistory: [
      { id: 101, action: 'Update', record: 'Coca-Cola 500ml', time: '09:35 AM' },
      { id: 98, action: 'View', record: 'Products List', time: '09:30 AM' },
      { id: 95, action: 'Login', record: 'User Session', time: '09:15 AM' }
    ],
    relatedEvents: [
      { id: 101, action: 'Update', user: 'Abebe Kebede', time: '2026-08-06 09:35:14' },
      { id: 45, action: 'Create', user: 'Dawit Haile', time: '2026-07-20 14:10:00' }
    ]
  },
  {
    id: 102,
    timestamp: '2026-08-06 09:20:05',
    timeRelative: '22m ago',
    userId: 2,
    userName: 'Kidst Tesfaye',
    userEmail: 'kidist21@gmail.com',
    userRole: 'Product Manager',
    userAvatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    module: 'System Configuration',
    entity: 'Haleta Corporate HQ',
    entityType: 'Organization',
    action: 'Permission Granted',
    riskLevel: 'High',
    recordType: 'Permissions',
    recordId: 'PERM-0082',
    recordName: 'Delete User & Revoke Role',
    documentNumber: 'DOC-SYS-2026-004',
    parentRecord: 'ROLE-BRANCH-MGR',
    workflowStep: 'Access Policy Assignment',
    approvalLevel: 'Level 3 - Director Signoff',
    description: 'Granted elevated delete permission to Branch Manager role',
    result: 'Success',
    ipAddress: '192.168.1.88',
    device: 'Firefox 128 / Windows 11',
    sessionId: 'SESS-7120-0806',
    undoAvailable: true,
    isUndone: false,
    diff: [
      { field: 'Permission Name', before: 'Delete User', after: 'Delete User & Revoke Role', isChanged: true, isSensitive: false },
      { field: 'Target Role', before: 'Admin Only', after: 'Branch Manager', isChanged: true, isSensitive: false },
      { field: 'API Secret Key', before: '••••••••', after: '••••••••', isChanged: false, isSensitive: true }
    ],
    sessionHistory: [
      { id: 102, action: 'Permission Granted', record: 'Delete User', time: '09:20 AM' },
      { id: 99, action: 'Role Changed', record: 'Branch Manager', time: '09:12 AM' }
    ],
    relatedEvents: [
      { id: 102, action: 'Permission Granted', user: 'Kidst Tesfaye', time: '2026-08-06 09:20:05' }
    ]
  },
  {
    id: 103,
    timestamp: '2026-08-06 08:50:33',
    timeRelative: '52m ago',
    userId: 4,
    userName: 'John Doe',
    userEmail: 'john@haleta.com',
    userRole: 'Inventory Officer',
    userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    module: 'Inventory',
    entity: 'Bole Road Branch',
    entityType: 'Branch',
    action: 'Delete',
    riskLevel: 'Critical',
    recordType: 'Product Groups',
    recordId: 'PRD-GRP-901',
    recordName: 'Discontinued Electronics Line',
    documentNumber: 'DOC-INV-2026-0082',
    parentRecord: 'MAIN-CAT-HARDWARE',
    workflowStep: 'Catalog Maintenance',
    approvalLevel: 'Level 1 - Self Approved',
    description: 'Deleted master product group and detached related attributes',
    result: 'Success',
    ipAddress: '192.168.1.102',
    device: 'Safari 17 / macOS Sonoma',
    sessionId: 'SESS-3341-0806',
    undoAvailable: true,
    isUndone: false,
    diff: [
      { field: 'Group Name', before: 'Discontinued Electronics Line', after: '[DELETED]', isChanged: true, isSensitive: false },
      { field: 'State', before: 'Active', after: 'Purged', isChanged: true, isSensitive: false }
    ],
    sessionHistory: [
      { id: 103, action: 'Delete', record: 'Discontinued Electronics Line', time: '08:50 AM' }
    ],
    relatedEvents: [
      { id: 103, action: 'Delete', user: 'John Doe', time: '2026-08-06 08:50:33' }
    ]
  },
  {
    id: 104,
    timestamp: '2026-08-06 08:15:00',
    timeRelative: '1h 27m ago',
    userId: 0,
    userName: 'Unknown User',
    userEmail: 'unauthorized@external.com',
    userRole: 'Guest / External',
    userAvatar: '',
    module: 'Security',
    entity: 'Global Portal',
    entityType: 'Business Group',
    action: 'Failed Login',
    riskLevel: 'Critical',
    recordType: 'Users',
    recordId: 'USR-AUTH-000',
    recordName: 'Admin Portal Login Attempt',
    documentNumber: 'SEC-LOG-2026-091',
    parentRecord: 'N/A',
    workflowStep: 'Authentication Challenge',
    approvalLevel: 'Blocked',
    description: 'Repeated invalid password attempt from unverified IP address',
    result: 'Failed',
    ipAddress: '192.168.1.104',
    device: 'Unknown / Linux Curl Script',
    sessionId: 'SESS-FAIL-9912',
    undoAvailable: false,
    isUndone: false,
    diff: [
      { field: 'Authentication Result', before: 'Pending', after: 'Invalid Credentials (3/3)', isChanged: true, isSensitive: false },
      { field: 'Submitted Password', before: '••••••••', after: '••••••••', isChanged: true, isSensitive: true }
    ],
    sessionHistory: [],
    relatedEvents: []
  },
  {
    id: 105,
    timestamp: '2026-08-06 07:40:19',
    timeRelative: '2h ago',
    userId: 3,
    userName: 'Mihret Abera',
    userEmail: 'mihret18@gmail.com',
    userRole: 'Branch Manager',
    userAvatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
    module: 'Sales',
    entity: 'Piazza Shop #02',
    entityType: 'Shop',
    action: 'Approve',
    riskLevel: 'Low',
    recordType: 'Promotions',
    recordId: 'PROMO-2026-SUMMER',
    recordName: '15% Off Summer Back-To-School Sale',
    documentNumber: 'DOC-SLS-2026-0412',
    parentRecord: 'PROMO-RULE-DISCOUNT',
    workflowStep: 'Final Executive Approval',
    approvalLevel: 'Level 2 - Manager Approved',
    description: 'Approved seasonal discount rule and activated price list adjustments',
    result: 'Success',
    ipAddress: '192.168.1.61',
    device: 'Chrome 126 / Windows 10',
    sessionId: 'SESS-6012-0806',
    undoAvailable: true,
    isUndone: false,
    diff: [
      { field: 'Approval Status', before: 'Pending Review', after: 'Approved', isChanged: true, isSensitive: false },
      { field: 'Effective Date', before: '2026-08-10', after: '2026-08-06', isChanged: true, isSensitive: false }
    ],
    sessionHistory: [],
    relatedEvents: []
  },
  {
    id: 106,
    timestamp: '2026-08-05 17:30:10',
    timeRelative: 'Yesterday',
    userId: 5,
    userName: 'Tigist Alemu',
    userEmail: 'tigist@haleta.com',
    userRole: 'Accountant',
    userAvatar: 'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?w=150&auto=format&fit=crop&q=80',
    module: 'Subscriptions',
    entity: 'Haleta Enterprise Group',
    entityType: 'Business Group',
    action: 'Post',
    riskLevel: 'Low',
    recordType: 'Subscription Invoices',
    recordId: 'INV-SUB-2026-08',
    recordName: 'Enterprise SaaS Monthly Billing Invoice',
    documentNumber: 'DOC-FIN-2026-9041',
    parentRecord: 'SUB-PLAN-ENT-01',
    workflowStep: 'Ledger Post',
    approvalLevel: 'Level 1 - Self Approved',
    description: 'Posted subscription invoice to General Ledger account #4010',
    result: 'Success',
    ipAddress: '192.168.1.15',
    device: 'Edge 127 / Windows 11',
    sessionId: 'SESS-4412-0805',
    undoAvailable: true,
    isUndone: false,
    diff: [
      { field: 'Invoice Status', before: 'Draft', after: 'Posted', isChanged: true, isSensitive: false },
      { field: 'Total Amount', before: '$2,450.00', after: '$2,450.00', isChanged: false, isSensitive: false }
    ],
    sessionHistory: [],
    relatedEvents: []
  }
]);

// Filtering & Sorting Computed Property
const filteredLogs = computed(() => {
  let list = [...logs.value];
  const q = searchQuery.value.toLowerCase().trim();

  // Tab filter mapping
  if (activeTab.value === 'security') {
    list = list.filter(l => ['Security', 'System Configuration'].includes(l.module) || ['Login', 'Failed Login', 'Logout', 'Password Reset', 'Permission Granted', 'Role Changed'].includes(l.action));
  } else if (activeTab.value === 'master_data') {
    list = list.filter(l => ['Products', 'Product Groups', 'Permissions', 'Lookup Types', 'Custom Fields', 'Users', 'Roles', 'Brands'].includes(l.recordType));
  } else if (activeTab.value === 'transactions') {
    list = list.filter(l => ['Inventory', 'Sales', 'Subscriptions', 'Buying'].includes(l.module) && ['Create', 'Update', 'Approve', 'Post', 'Reverse'].includes(l.action));
  } else if (activeTab.value === 'sessions') {
    list = list.filter(l => ['Login', 'Logout', 'Failed Login'].includes(l.action));
  }

  // Keyword Search across multiple fields
  if (q) {
    list = list.filter(l =>
      l.description.toLowerCase().includes(q) ||
      l.userName.toLowerCase().includes(q) ||
      l.userRole.toLowerCase().includes(q) ||
      l.recordName.toLowerCase().includes(q) ||
      l.recordId.toLowerCase().includes(q) ||
      l.module.toLowerCase().includes(q) ||
      l.entity.toLowerCase().includes(q) ||
      l.action.toLowerCase().includes(q) ||
      l.ipAddress.includes(q) ||
      l.sessionId.toLowerCase().includes(q)
    );
  }

  // Dropdown filters
  if (userFilter.value !== 'All') {
    list = list.filter(l => l.userName === userFilter.value);
  }

  if (moduleFilter.value !== 'All') {
    list = list.filter(l => l.module === moduleFilter.value);
  }

  if (entityFilter.value !== 'All') {
    list = list.filter(l => l.entity === entityFilter.value);
  }

  if (actionFilter.value !== 'All') {
    list = list.filter(l => l.action === actionFilter.value);
  }

  if (statusFilter.value !== 'All') {
    list = list.filter(l => l.result === statusFilter.value);
  }

  if (riskFilter.value !== 'All') {
    list = list.filter(l => l.riskLevel === riskFilter.value);
  }

  if (ipFilter.value.trim()) {
    list = list.filter(l => l.ipAddress.includes(ipFilter.value.trim()));
  }

  if (sessionIdFilter.value.trim()) {
    list = list.filter(l => l.sessionId.toLowerCase().includes(sessionIdFilter.value.trim().toLowerCase()));
  }

  // Sorting
  list.sort((a, b) => {
    if (sortBy.value === 'timestamp') {
      const timeA = new Date(a.timestamp).getTime();
      const timeB = new Date(b.timestamp).getTime();
      return sortOrder.value === 'asc' ? timeA - timeB : timeB - timeA;
    } else if (sortBy.value === 'risk') {
      const riskWeight: Record<string, number> = { Critical: 4, High: 3, Medium: 2, Low: 1 };
      const wA = riskWeight[a.riskLevel] || 0;
      const wB = riskWeight[b.riskLevel] || 0;
      return sortOrder.value === 'asc' ? wA - wB : wB - wA;
    } else if (sortBy.value === 'action') {
      return sortOrder.value === 'asc' ? a.action.localeCompare(b.action) : b.action.localeCompare(a.action);
    } else if (sortBy.value === 'user') {
      return sortOrder.value === 'asc' ? a.userName.localeCompare(b.userName) : b.userName.localeCompare(a.userName);
    }
    return 0;
  });

  return list;
});

// Pagination State
const currentPage = ref(1);
const perPage = ref(10);

const totalPages = computed(() => Math.ceil(filteredLogs.value.length / perPage.value) || 1);

const paginatedLogs = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredLogs.value.slice(start, start + perPage.value);
});

// Helper for initials fallback
const getInitials = (name: string) => {
  if (!name || name === 'Unknown User') return 'UN';
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
};

// Reset filters
const resetAllFilters = () => {
  searchQuery.value = '';
  dateFilter.value = 'All';
  userFilter.value = 'All';
  moduleFilter.value = 'All';
  entityFilter.value = 'All';
  entityTypeFilter.value = 'All';
  recordTypeFilter.value = 'All';
  actionFilter.value = 'All';
  statusFilter.value = 'All';
  riskFilter.value = 'All';
  ipFilter.value = '';
  sessionIdFilter.value = '';
  showFilterDropdown.value = false;
  showToast('Filters reset to default view.', 'info');
};

// Close popovers on click outside
if (typeof window !== 'undefined') {
  window.addEventListener('click', () => {
    showFilterDropdown.value = false;
    showSortDropdown.value = false;
    showExportDropdown.value = false;
  });
}
</script>

<template>
  <div class="audit-logs-page">

    <!-- Toast Notification -->
    <div v-if="toastMessage" :class="['toast-notification', `toast-${toastType}`]">
      <CheckCircle2 v-if="toastType === 'success'" :size="16" />
      <AlertTriangle v-else-if="toastType === 'warning'" :size="16" />
      <Sparkles v-else :size="16" />
      <span>{{ toastMessage }}</span>
    </div>

    <!-- Top Breadcrumbs (Desktop icon > Audit Log) -->
    <div class="breadcrumb-nav">
      <router-link to="/dashboard" class="breadcrumb-icon-link" title="Dashboard">
        <Monitor :size="15" />
      </router-link>
      <ChevronRight :size="12" class="breadcrumb-divider" />
      <span class="breadcrumb-current">Audit Log</span>
    </div>

    <!-- TOP SECTION CARD: Page Header, Metrics & Tabs -->
    <div class="header-section-card">
      <div class="page-title-header">
        <div class="title-left">
          <h1 class="main-title">Audit Logs & Security Ledger</h1>
          <p class="main-subtitle">
            System-wide immutable activity trail, field-level change history, and compliance tracking.
          </p>
        </div>

        <!-- Metric Cards Grid (Using Centralized MetricCard Component) -->
        <div class="metrics-grid">
          <MetricCard
            label="TOTAL AUDIT EVENTS"
            value="1,482"
            subtext="vs previous month"
            trend="+12.3%"
            trendType="up"
          />
          <MetricCard
            label="HIGH & CRITICAL RISK"
            value="14"
            subtext="Requires immediate review"
          />
          <MetricCard
            label="FAILED LOGINS"
            value="3"
            subtext="Blocked IP attempts"
          />
          <MetricCard
            label="REVERSIBLE ACTIONS"
            value="428"
            subtext="Can be restored / undone"
          />
        </div>
      </div>

      <!-- Pill Tab Switcher (`BaseTabs`) -->
      <div class="tabs-toolbar-wrapper">
        <BaseTabs v-model="activeTab" :tabs="tabs" size="md" />
      </div>
    </div>

    <!-- BOTTOM SECTION CARD: Table Title, Toolbar, Inline Filters, Table & Pagination -->
    <div class="table-section-card">

      <!-- Table Title & Description Header -->
      <div class="table-header-title-block">
        <h2 class="table-block-title">Audit Trail</h2>
        <p class="table-block-subtitle">Detailed timeline of system changes, security events, and user activities.</p>
      </div>

      <!-- Action Controls Toolbar -->
      <div class="toolbar-wrapper">
        <div class="toolbar-left">
          <!-- Search input -->
          <div class="search-box">
            <Search :size="16" class="search-box-icon" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search keyword, user, record ID, IP..."
              class="search-box-input"
            />
            <button v-if="searchQuery" @click="searchQuery = ''" class="clear-search-btn">
              <X :size="13" />
            </button>
          </div>

          <!-- Filter toggle button -->
          <button 
            class="toolbar-btn" 
            :class="{ 'btn-active': activeFilterCount > 0 || showFilterSection }"
            @click.stop="showFilterSection = !showFilterSection; showSortDropdown = false; showExportDropdown = false;"
          >
            <Filter :size="15" />
            <span>Filter</span>
            <span v-if="activeFilterCount > 0" class="filter-count-badge">{{ activeFilterCount }}</span>
            <ChevronDown :size="12" class="ml-1 opacity-60" :class="{ 'rotate-180': showFilterSection }" />
          </button>

          <!-- Sort button with dropdown -->
          <div class="relative-dropdown">
            <button 
              class="toolbar-btn" 
              @click.stop="showSortDropdown = !showSortDropdown; showExportDropdown = false;"
            >
              <ArrowUpDown :size="15" />
              <span>Sort</span>
              <ChevronDown :size="12" class="ml-1 opacity-60" />
            </button>

            <div v-if="showSortDropdown" class="dropdown-popover sort-popover" @click.stop>
              <button class="sort-option" @click="toggleSort('timestamp')">
                <span>Date & Time</span>
                <span v-if="sortBy === 'timestamp'" class="sort-indicator">{{ sortOrder === 'desc' ? 'Newest' : 'Oldest' }}</span>
              </button>
              <button class="sort-option" @click="toggleSort('risk')">
                <span>Risk Level</span>
                <span v-if="sortBy === 'risk'" class="sort-indicator">{{ sortOrder === 'desc' ? 'Highest' : 'Lowest' }}</span>
              </button>
              <button class="sort-option" @click="toggleSort('action')">
                <span>Action</span>
                <span v-if="sortBy === 'action'" class="sort-indicator">{{ sortOrder === 'asc' ? 'A-Z' : 'Z-A' }}</span>
              </button>
              <button class="sort-option" @click="toggleSort('user')">
                <span>User</span>
                <span v-if="sortBy === 'user'" class="sort-indicator">{{ sortOrder === 'asc' ? 'A-Z' : 'Z-A' }}</span>
              </button>
            </div>
          </div>
        </div>

        <div class="toolbar-right">
          <!-- Export Dropdown Button -->
          <div class="relative-dropdown">
            <BaseButton
              variant="secondary"
              @click.stop="showExportDropdown = !showExportDropdown; showSortDropdown = false;"
            >
              <template #icon-left><Download :size="15" /></template>
              <span>Export</span>
              <template #icon-right><ChevronDown :size="12" class="ml-1 opacity-60" /></template>
            </BaseButton>

            <div v-if="showExportDropdown" class="dropdown-popover export-popover" @click.stop>
              <button class="export-option" @click="handleExport('Excel')">
                <FileSpreadsheet :size="16" class="text-emerald-600" />
                <span>Export as Excel (.xlsx)</span>
              </button>
              <button class="export-option" @click="handleExport('CSV')">
                <FileCode :size="16" class="text-blue-600" />
                <span>Export as CSV (.csv)</span>
              </button>
              <button class="export-option" @click="handleExport('PDF')">
                <FileText :size="16" class="text-rose-600" />
                <span>Export as PDF Document</span>
              </button>
            </div>
          </div>

          <!-- Primary User Button System Standard -->
          <BaseButton 
            variant="primary" 
            @click="showToast('System audit trail synced to immutable ledger.', 'success')"
          >
            <template #icon-left><RefreshCw :size="15" /></template>
            <span>Sync Ledger</span>
          </BaseButton>
        </div>
      </div>

      <!-- INLINE EXPANDABLE FILTER SECTION (DESIGN SPEC) -->
      <div v-if="showFilterSection" class="inline-filter-section">
        <div class="filter-grid-4">
          <!-- User -->
          <div class="filter-field">
            <label class="field-label">User</label>
            <select v-model="userFilter" class="filter-select">
              <option value="All">All Users</option>
              <option value="Abebe Kebede">Abebe Kebede (Admin)</option>
              <option value="Kidst Tesfaye">Kidst Tesfaye (Product Mgr)</option>
              <option value="John Doe">John Doe (Inventory Officer)</option>
              <option value="Mihret Abera">Mihret Abera (Branch Mgr)</option>
              <option value="Tigist Alemu">Tigist Alemu (Accountant)</option>
            </select>
          </div>

          <!-- Module -->
          <div class="filter-field">
            <label class="field-label">Module</label>
            <select v-model="moduleFilter" class="filter-select">
              <option value="All">All Modules</option>
              <option value="Inventory">Inventory</option>
              <option value="Sales">Sales</option>
              <option value="Buying">Buying</option>
              <option value="System Configuration">System Configuration</option>
              <option value="Subscriptions">Subscriptions</option>
              <option value="Security">Security</option>
            </select>
          </div>

          <!-- Entity -->
          <div class="filter-field">
            <label class="field-label">Entity</label>
            <select v-model="entityFilter" class="filter-select">
              <option value="All">All Entities</option>
              <option value="Haleta Corporate HQ">Haleta Corporate HQ</option>
              <option value="Bole Road Branch">Bole Road Branch</option>
              <option value="Piazza Shop #02">Piazza Shop #02</option>
              <option value="Global Portal">Global Portal</option>
            </select>
          </div>

          <!-- Action -->
          <div class="filter-field">
            <label class="field-label">Action</label>
            <select v-model="actionFilter" class="filter-select">
              <option value="All">All Actions</option>
              <option value="Login">Login</option>
              <option value="Failed Login">Failed Login</option>
              <option value="Create">Create</option>
              <option value="Update">Update</option>
              <option value="Delete">Delete</option>
              <option value="Approve">Approve</option>
              <option value="Permission Granted">Permission Granted</option>
              <option value="Post">Post Invoice</option>
            </select>
          </div>

          <!-- Risk Level -->
          <div class="filter-field">
            <label class="field-label">Risk Level</label>
            <select v-model="riskFilter" class="filter-select">
              <option value="All">All Risk Levels</option>
              <option value="Low">Low Risk</option>
              <option value="Medium">Medium Risk</option>
              <option value="High">High Risk</option>
              <option value="Critical">Critical Risk</option>
            </select>
          </div>

          <!-- Status -->
          <div class="filter-field">
            <label class="field-label">Status Result</label>
            <select v-model="statusFilter" class="filter-select">
              <option value="All">All Results</option>
              <option value="Success">Success Only</option>
              <option value="Failed">Failed Only</option>
            </select>
          </div>

          <!-- IP Address -->
          <div class="filter-field">
            <label class="field-label">IP Address</label>
            <input v-model="ipFilter" type="text" class="filter-input" />
          </div>

          <!-- Session ID -->
          <div class="filter-field">
            <label class="field-label">Session ID</label>
            <input v-model="sessionIdFilter" type="text" class="filter-input" />
          </div>
        </div>

        <div class="filter-footer-row">
          <button class="btn-reset-filter-link" @click="resetAllFilters">
            <X :size="14" />
            <span>Reset Filter</span>
          </button>
        </div>
      </div>

      <!-- TIMELINE TABLE -->
      <div class="table-container">
        <table class="erp-table">
          <thead>
            <tr>
              <th class="col-checkbox">
                <input 
                  type="checkbox" 
                  v-model="selectAll" 
                  @change="toggleSelectAll" 
                  class="custom-checkbox"
                />
              </th>
              <th class="col-no">No.</th>
              <th class="col-time">Timestamp</th>
              <th class="col-user">User & Role</th>
              <th class="col-module">Module</th>
              <th class="col-entity">Entity</th>
              <th class="col-action">Action</th>
              <th class="col-record">Record & Type</th>
              <th class="col-desc">Description</th>
              <th class="col-result">Result</th>
              <th class="col-ip">IP Address</th>
              <th class="col-actions text-right">Details</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="(log, idx) in paginatedLogs" 
              :key="log.id"
              :class="{ 'row-selected': isLogSelected(log.id), 'row-undone': log.isUndone }"
              @click="openLogDetails(log)"
              class="clickable-row"
            >
              <!-- Checkbox -->
              <td class="col-checkbox" @click.stop>
                <input 
                  type="checkbox" 
                  :checked="isLogSelected(log.id)" 
                  @change="toggleLogSelection(log.id)"
                  class="custom-checkbox"
                />
              </td>

              <!-- No. -->
              <td class="col-no text-slate-400 font-medium">
                {{ (currentPage - 1) * perPage + idx + 1 }}
              </td>

              <!-- Timestamp -->
              <td class="col-time">
                <div class="time-stack">
                  <span class="time-main">{{ log.timestamp.split(' ')[1] }}</span>
                  <span class="time-date">{{ log.timestamp.split(' ')[0] }}</span>
                </div>
              </td>

              <!-- User & Role -->
              <td class="col-user">
                <div class="user-cell">
                  <img v-if="log.userAvatar" :src="log.userAvatar" :alt="log.userName" class="user-avatar" />
                  <div v-else class="user-avatar-fallback">{{ getInitials(log.userName) }}</div>
                  <div class="user-text-stack">
                    <span class="user-name">{{ log.userName }}</span>
                    <span class="user-role">{{ log.userRole }}</span>
                  </div>
                </div>
              </td>

              <!-- Module -->
              <td class="col-module">
                <span class="module-chip">{{ log.module }}</span>
              </td>

              <!-- Entity -->
              <td class="col-entity text-slate-700">
                <div class="entity-stack">
                  <span class="entity-name">{{ log.entity }}</span>
                  <span class="entity-type">{{ log.entityType }}</span>
                </div>
              </td>

              <!-- Action & Risk Level -->
              <td class="col-action">
                <div class="action-stack">
                  <span 
                    :class="[
                      'action-pill',
                      log.action === 'Create' ? 'action-create' : '',
                      log.action === 'Update' ? 'action-update' : '',
                      log.action === 'Delete' ? 'action-delete' : '',
                      log.action === 'Failed Login' ? 'action-failed-login' : '',
                      log.action === 'Permission Granted' ? 'action-perm' : '',
                      log.action === 'Approve' ? 'action-approve' : '',
                      log.action === 'Post' ? 'action-post' : ''
                    ]"
                  >
                    {{ log.action }}
                  </span>
                  <span 
                    :class="[
                      'risk-badge',
                      log.riskLevel === 'Critical' ? 'risk-critical' : '',
                      log.riskLevel === 'High' ? 'risk-high' : '',
                      log.riskLevel === 'Medium' ? 'risk-medium' : 'risk-low'
                    ]"
                  >
                    {{ log.riskLevel }} Risk
                  </span>
                </div>
              </td>

              <!-- Record & Record Type -->
              <td class="col-record">
                <div class="record-stack">
                  <span class="record-name">{{ log.recordName }}</span>
                  <span class="record-id-type">{{ log.recordType }} &bull; {{ log.recordId }}</span>
                </div>
              </td>

              <!-- Description -->
              <td class="col-desc text-slate-600 text-xs">
                <span class="desc-text">{{ log.description }}</span>
                <span v-if="log.isUndone" class="undone-badge">Reverted</span>
              </td>

              <!-- Result -->
              <td class="col-result">
                <span :class="['result-pill', log.result === 'Success' ? 'result-success' : 'result-failed']">
                  <span class="dot"></span>
                  {{ log.result }}
                </span>
              </td>

              <!-- IP Address -->
              <td class="col-ip text-slate-500 font-mono text-xs">
                {{ log.ipAddress }}
              </td>

              <!-- Details Button -->
              <td class="col-actions text-right" @click.stop>
                <button class="btn-details" @click="openLogDetails(log)">
                  <Eye :size="14" />
                  <span>Inspect</span>
                </button>
              </td>
            </tr>

            <!-- Empty Search Results -->
            <tr v-if="filteredLogs.length === 0">
              <td colspan="12" class="empty-table-state">
                <ShieldAlert :size="32" class="text-slate-300 mb-2" />
                <p class="font-medium text-slate-700">No audit log events match your search criteria</p>
                <p class="text-xs text-slate-400 mt-1">Try resetting search filters or keywords</p>
                <button @click="resetAllFilters" class="btn-secondary-reset mt-3">Reset Filters</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination Footer -->
      <BasePagination
        v-model:currentPage="currentPage"
        v-model:perPage="perPage"
        :totalEntries="filteredLogs.length"
        :perPageOptions="[1, 5, 10, 25, 50, 100]"
      />

    </div>

    <!-- SIDE DRAWER: BEFORE VS AFTER COMPARISON & LOG DETAILS -->
    <div v-if="isDrawerOpen && selectedLog" class="drawer-overlay" @click="closeDrawer">
      <div class="drawer-panel" @click.stop>
        
        <!-- Drawer Header -->
        <div class="drawer-header">
          <div class="drawer-title-stack">
            <div class="drawer-badge-row">
              <span class="action-pill action-update">{{ selectedLog.action }}</span>
              <span :class="['risk-badge', selectedLog.riskLevel === 'Critical' ? 'risk-critical' : selectedLog.riskLevel === 'High' ? 'risk-high' : 'risk-medium']">
                {{ selectedLog.riskLevel }} Risk
              </span>
              <span :class="['result-pill', selectedLog.result === 'Success' ? 'result-success' : 'result-failed']">
                {{ selectedLog.result }}
              </span>
            </div>
            <h2 class="drawer-record-name">{{ selectedLog.recordName }}</h2>
            <p class="drawer-subtitle">{{ selectedLog.recordType }} &bull; ID: {{ selectedLog.recordId }}</p>
          </div>
          <button class="drawer-close-btn" @click="closeDrawer">
            <X :size="18" />
          </button>
        </div>

        <!-- Drawer Body -->
        <div class="drawer-body">

          <!-- Action Reversion / Undo Card -->
          <div class="undo-banner-card">
            <div class="undo-banner-left">
              <RotateCcw :size="18" class="text-blue-600" />
              <div>
                <span class="undo-title">Undo Availability: {{ selectedLog.undoAvailable ? 'Reversible' : 'Not Reversible' }}</span>
                <p class="undo-sub">
                  {{ selectedLog.isUndone ? 'This change has already been reverted.' : selectedLog.undoAvailable ? 'You can revert state to before this change.' : 'System security logs cannot be undone.' }}
                </p>
              </div>
            </div>
            <button 
              v-if="selectedLog.undoAvailable" 
              :disabled="selectedLog.isUndone"
              @click="handleUndoAction(selectedLog)" 
              class="btn-revert-action"
            >
              {{ selectedLog.isUndone ? 'Reverted' : 'Revert Action (Undo)' }}
            </button>
          </div>

          <!-- BEFORE VS AFTER COMPARISON SECTION -->
          <div class="section-container">
            <h3 class="section-title">
              <Sliders :size="15" />
              <span>Before vs After Comparison</span>
            </h3>
            <p class="section-hint">Only fields that were modified during this transaction are highlighted below.</p>

            <div class="diff-comparison-table-wrapper">
              <table class="diff-table">
                <thead>
                  <tr>
                    <th>Field Name</th>
                    <th>Before Change</th>
                    <th class="text-center">&rarr;</th>
                    <th>After Change</th>
                  </tr>
                </thead>
                <tbody>
                  <tr 
                    v-for="d in selectedLog.diff" 
                    :key="d.field"
                    :class="{ 'diff-row-changed': d.isChanged }"
                  >
                    <td class="field-cell font-semibold">
                      {{ d.field }}
                      <span v-if="d.isSensitive" class="sensitive-tag" title="Sensitive Field Masked">Sensitive</span>
                    </td>
                    <td class="before-cell">
                      <span class="value-badge before-value">{{ d.before }}</span>
                    </td>
                    <td class="arrow-cell text-center text-slate-400">&rarr;</td>
                    <td class="after-cell">
                      <span :class="['value-badge', d.isChanged ? 'after-value-highlight' : 'after-value']">
                        {{ d.after }}
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- RELATED INFORMATION GRID -->
          <div class="section-container">
            <h3 class="section-title">
              <FileText :size="15" />
              <span>Related Information & Context</span>
            </h3>

            <div class="info-grid">
              <div class="info-item">
                <span class="info-label">User</span>
                <span class="info-val font-semibold">{{ selectedLog.userName }} ({{ selectedLog.userEmail }})</span>
              </div>
              <div class="info-item">
                <span class="info-label">User Role</span>
                <span class="info-val">{{ selectedLog.userRole }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Entity</span>
                <span class="info-val">{{ selectedLog.entity }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Entity Type</span>
                <span class="info-val">{{ selectedLog.entityType }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Module</span>
                <span class="info-val">{{ selectedLog.module }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Document Number</span>
                <span class="info-val font-mono">{{ selectedLog.documentNumber }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Record ID</span>
                <span class="info-val font-mono">{{ selectedLog.recordId }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Parent Record</span>
                <span class="info-val font-mono">{{ selectedLog.parentRecord }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Workflow Step</span>
                <span class="info-val">{{ selectedLog.workflowStep }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Approval Level</span>
                <span class="info-val">{{ selectedLog.approvalLevel }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Session ID</span>
                <span class="info-val font-mono">{{ selectedLog.sessionId }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Device & Browser</span>
                <span class="info-val">{{ selectedLog.device }}</span>
              </div>
            </div>
          </div>

          <!-- SESSION HISTORY SECTION -->
          <div class="section-container" v-if="selectedLog.sessionHistory && selectedLog.sessionHistory.length > 0">
            <h3 class="section-title">
              <Clock :size="15" />
              <span>Session History (Session: {{ selectedLog.sessionId }})</span>
            </h3>

            <div class="session-timeline">
              <div v-for="s in selectedLog.sessionHistory" :key="s.id" class="session-step">
                <span class="session-time">{{ s.time }}</span>
                <span class="session-action">{{ s.action }}</span>
                <span class="session-target">&bull; {{ s.record }}</span>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>

    <!-- FLOATING AI AUDIT ASSISTANT ICON & DRAWER -->
    <div class="ai-widget-wrapper">
      <!-- Floating Icon Button -->
      <button 
        class="floating-ai-btn" 
        @click="isAiAssistantOpen = !isAiAssistantOpen"
        title="Open AI Audit Assistant"
      >
        <Sparkles :size="20" class="sparkle-anim" />
        <span class="ai-btn-badge">AI</span>
      </button>

      <!-- AI Assistant Drawer Popover -->
      <div v-if="isAiAssistantOpen" class="ai-assistant-card">
        <div class="ai-card-header">
          <div class="ai-header-left">
            <Bot :size="18" class="text-blue-600" />
            <span class="ai-card-title">AI Audit Search Assistant</span>
          </div>
          <button class="ai-close-btn" @click="isAiAssistantOpen = false">
            <X :size="16" />
          </button>
        </div>

        <div class="ai-card-body">
          <p class="ai-prompt-instruction">
            Ask questions in natural language to search system audit trails instantly:
          </p>

          <!-- Preset Prompt Chips -->
          <div class="ai-chips">
            <button 
              v-for="chip in presetAiQueries" 
              :key="chip"
              class="ai-chip-btn"
              @click="executeAiQuery(chip)"
            >
              {{ chip }}
            </button>
          </div>

          <!-- AI Response Area -->
          <div v-if="isAiThinking" class="ai-response-box ai-thinking">
            <Sparkles :size="16" class="animate-spin text-blue-600" />
            <span>Analyzing audit logs...</span>
          </div>

          <div v-else-if="aiResponse" class="ai-response-box">
            <div class="ai-response-header">
              <CheckCircle2 :size="16" class="text-emerald-600" />
              <span class="font-semibold text-slate-800">AI Audit Synthesis</span>
            </div>
            <p class="ai-response-text">{{ aiResponse }}</p>
          </div>

          <!-- Input Bar -->
          <div class="ai-input-wrap">
            <input 
              v-model="aiQueryInput"
              type="text"
              placeholder="e.g. Who changed the price of Coca-Cola?"
              class="ai-search-input"
              @keyup.enter="executeAiQuery(aiQueryInput)"
            />
            <button @click="executeAiQuery(aiQueryInput)" class="ai-submit-btn">
              <ArrowRight :size="15" />
            </button>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>
.audit-logs-page {
  animation: fadeIn 0.25s ease-out;
  display: flex;
  flex-direction: column;
  gap: 12px;
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  color: #0f172a;
  position: relative;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(6px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Toast notification */
.toast-notification {
  position: fixed;
  top: 20px;
  right: 24px;
  z-index: 10000;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 18px;
  border-radius: 10px;
  font-size: 13.5px;
  font-weight: 500;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
  animation: slideInRight 0.2s ease-out;
}
@keyframes slideInRight {
  from { transform: translateX(50px); opacity: 0; }
  to { transform: translateX(0); opacity: 1; }
}
.toast-success { background-color: #064e3b; color: #ffffff; }
.toast-warning { background-color: #78350f; color: #ffffff; }
.toast-info { background-color: #1e3a8a; color: #ffffff; }

/* Breadcrumb */
.breadcrumb-nav {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #64748b;
  margin-bottom: 2px;
}
.breadcrumb-icon-link {
  color: #64748b;
  display: flex;
  align-items: center;
  padding: 2px;
  border-radius: 4px;
}
.breadcrumb-icon-link:hover { color: #0f172a; background-color: #f1f5f9; }
.breadcrumb-divider { color: #94a3b8; }
.breadcrumb-item { color: #64748b; }
.breadcrumb-current { color: #1e293b; font-weight: 600; }

/* Top Header Section Card */
.header-section-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02), 0 1px 2px rgba(0, 0, 0, 0.03);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* Bottom Table Section Card */
.table-section-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02), 0 1px 2px rgba(0, 0, 0, 0.03);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.table-header-title-block {
  padding: 20px 28px 12px 28px;
}
.table-block-title {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
  margin: 0 0 2px 0;
  letter-spacing: -0.01em;
}
.table-block-subtitle {
  font-size: 13px;
  color: #64748b;
  margin: 0;
}

/* Header & Metric Cards */
.page-title-header {
  padding: 24px 28px 16px 28px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.main-title {
  font-size: 22px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: -0.02em;
  margin: 0 0 4px 0;
}
.main-subtitle {
  font-size: 13.5px;
  color: #64748b;
  margin: 0;
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-top: 4px;
}

.metric-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 10px;
  transition: all 0.15s ease;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}

.metric-card:hover {
  border-color: #cbd5e1;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.04);
}

.metric-card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.metric-label-uppercase {
  font-size: 11.5px;
  font-weight: 700;
  color: #64748b;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.btn-more-options {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 2px;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 0.15s ease;
}

.btn-more-options:hover {
  color: #0f172a;
  background-color: #f1f5f9;
}

.metric-card-body {
  display: flex;
  align-items: baseline;
}

.metric-value-large {
  font-size: 26px;
  font-weight: 800;
  color: #0f172a;
  letter-spacing: -0.02em;
  line-height: 1.1;
}

.metric-card-bottom {
  display: flex;
  align-items: center;
  gap: 8px;
}

.metric-subtext {
  font-size: 12px;
  color: #64748b;
}

.trend-badge {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 700;
}

.trend-up {
  background-color: #dcfce7;
  color: #15803d;
}

/* Tabs Toolbar */
.tabs-toolbar-wrapper {
  padding: 0 28px 12px 28px;
}

/* Controls Toolbar */
.toolbar-wrapper {
  padding: 12px 28px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-top: 1px solid #f1f5f9;
  border-bottom: 1px solid #f1f5f9;
  background-color: #ffffff;
  gap: 12px;
}
.toolbar-left, .toolbar-right { display: flex; align-items: center; gap: 10px; }

.search-box {
  position: relative;
  display: flex;
  align-items: center;
}
.search-box-icon { position: absolute; left: 12px; color: #94a3b8; pointer-events: none; }
.search-box-input {
  padding: 8px 32px 8px 36px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13px;
  width: 320px;
  outline: none;
  background-color: #fafafa;
  transition: all 0.15s ease;
}
.search-box-input:focus { border-color: #0B529C; background-color: #ffffff; box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.12); }
.clear-search-btn {
  position: absolute;
  right: 10px;
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
}

.relative-dropdown { position: relative; }
.toolbar-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background-color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  color: #475569;
  cursor: pointer;
  transition: all 0.15s ease;
}
.toolbar-btn:hover { background-color: #f8fafc; color: #0f172a; border-color: #cbd5e1; }
.toolbar-btn.btn-active { border-color: #0B529C; color: #0B529C; background-color: #eff6ff; font-weight: 600; }

.filter-count-badge {
  background-color: #e2e8f0;
  color: #0f172a;
  font-size: 11px;
  font-weight: 700;
  padding: 1px 7px;
  border-radius: 10px;
  margin-left: 4px;
}
.toolbar-btn.btn-active .filter-count-badge {
  background-color: #0B529C;
  color: #ffffff;
}

/* INLINE EXPANDABLE FILTER SECTION (DESIGN SPEC) */
.inline-filter-section {
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  padding: 16px 28px;
  display: flex;
  flex-direction: column;
  gap: 14px;
  animation: slideDown 0.15s ease-out;
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}

.filter-grid-4 {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 14px 16px;
}

.filter-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  font-size: 12px;
  font-weight: 600;
  color: #475569;
}

.filter-select, .filter-input {
  padding: 8px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  background-color: #ffffff;
  color: #0f172a;
  outline: none;
  transition: all 0.15s ease;
  width: 100%;
}

.filter-select:focus, .filter-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.12);
}

.filter-footer-row {
  display: flex;
  align-items: center;
  margin-top: 2px;
}

.btn-reset-filter-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: none;
  border: none;
  color: #0B529C;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  padding: 4px 0;
  transition: color 0.15s ease;
}

.btn-reset-filter-link:hover {
  color: #09427d;
  text-decoration: underline;
}

.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-primary-action:hover { background-color: #09427d; box-shadow: 0 4px 12px rgba(11, 82, 156, 0.25); }

/* Popovers */
.dropdown-popover {
  position: absolute;
  top: calc(100% + 6px);
  left: 0;
  z-index: 100;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
  padding: 16px;
  animation: fadeIn 0.15s ease-out;
}
.filter-popover { width: 440px; }
.popover-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.popover-title { font-size: 13px; font-weight: 700; color: #0f172a; }
.btn-text-reset { background: none; border: none; font-size: 12px; color: #0B529C; cursor: pointer; font-weight: 600; }
.filter-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; }
.filter-field { display: flex; flex-direction: column; gap: 4px; }
.field-label { font-size: 11.5px; font-weight: 600; color: #64748b; }
.filter-select, .filter-input {
  padding: 7px 10px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  outline: none;
  color: #0f172a;
}

.sort-popover, .export-popover { width: 220px; right: 0; left: auto; padding: 6px; }
.sort-option, .export-option {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 8px 12px;
  border: none;
  background: none;
  font-size: 13px;
  color: #334155;
  border-radius: 8px;
  cursor: pointer;
  text-align: left;
}
.sort-option:hover, .export-option:hover { background-color: #f1f5f9; color: #0f172a; }
.sort-indicator { margin-left: auto; font-size: 11px; font-weight: 700; color: #0B529C; }

/* Table Container */
.table-container { width: 100%; overflow-x: auto; }
.erp-table { width: 100%; border-collapse: collapse; text-align: left; font-size: 13px; }
.erp-table th {
  padding: 8px 14px;
  background-color: #fafafa;
  color: #737373;
  font-weight: 500;
  font-size: 12px;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
  height: 34px;
}
.erp-table td {
  padding: 8px 14px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
  color: #404040;
  height: 38px;
}
.clickable-row { cursor: pointer; transition: background 0.15s ease; }
.clickable-row:hover { background-color: #f8fafc; }
.row-selected { background-color: #eff6ff !important; }
.row-undone { opacity: 0.6; background-color: #fef2f2; }

.custom-checkbox { width: 16px; height: 16px; accent-color: #0B529C; cursor: pointer; }

.time-stack, .user-text-stack, .entity-stack, .action-stack, .record-stack { display: flex; flex-direction: column; }
.time-main { font-weight: 500; color: #737373; font-size: 12.5px; }
.time-date { font-size: 11px; color: #737373; }

.user-cell { display: flex; align-items: center; gap: 10px; }
.user-avatar { width: 30px; height: 30px; border-radius: 50%; object-fit: cover; }
.user-avatar-fallback {
  width: 30px; height: 30px; border-radius: 50%; background-color: #0B529C;
  color: #ffffff; font-size: 11px; font-weight: 700; display: flex; align-items: center; justify-content: center;
}
.user-name { font-weight: 600; color: #262626; line-height: 1.2; font-size: 13.5px; }
.user-role { font-size: 11.5px; color: #737373; }

.module-chip {
  display: inline-block;
  padding: 3px 8px;
  border-radius: 6px;
  background-color: #f5f5f5;
  color: #737373;
  font-size: 11.5px;
  font-weight: 500;
}
.entity-name { font-weight: 500; color: #737373; }
.entity-type { font-size: 11px; color: #737373; }

.action-pill {
  display: inline-block;
  padding: 3px 8px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 700;
  width: fit-content;
}
.action-create { background-color: #ecfdf5; color: #047857; }
.action-update { background-color: #eff6ff; color: #1d4ed8; }
.action-delete { background-color: #fef2f2; color: #b91c1c; }
.action-failed-login { background-color: #fff1f2; color: #e11d48; }
.action-perm { background-color: #f5f3ff; color: #6d28d9; }
.action-approve { background-color: #eef2ff; color: #4338ca; }
.action-post { background-color: #fff7ed; color: #c2410c; }

.risk-badge {
  font-size: 10.5px;
  font-weight: 700;
  padding: 1px 6px;
  border-radius: 4px;
  margin-top: 2px;
  width: fit-content;
}
.risk-low { background-color: #f1f5f9; color: #475569; }
.risk-medium { background-color: #fef3c7; color: #b45309; }
.risk-high { background-color: #ffedd5; color: #c2410c; }
.risk-critical { background-color: #ffe4e6; color: #be123c; }

.record-name { font-weight: 600; color: #0f172a; }
.record-id-type { font-size: 11px; color: #64748b; }

.desc-text { line-height: 1.3; }
.undone-badge { display: inline-block; margin-left: 6px; padding: 1px 5px; background: #fee2e2; color: #991b1b; font-size: 10px; font-weight: 700; border-radius: 4px; }

.result-pill {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 8px;
  border-radius: 12px;
  font-size: 11.5px;
  font-weight: 600;
}
.result-pill .dot { width: 6px; height: 6px; border-radius: 50%; }
.result-success { background-color: #ecfdf5; color: #047857; }
.result-success .dot { background-color: #10b981; }
.result-failed { background-color: #fef2f2; color: #b91c1c; }
.result-failed .dot { background-color: #ef4444; }

.btn-details {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 6px 10px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-details:hover { background-color: #f1f5f9; color: #0f172a; border-color: #cbd5e1; }

.empty-table-state { padding: 40px; text-align: center; }
.btn-secondary-reset {
  padding: 6px 14px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  font-size: 12.5px;
  font-weight: 600;
  cursor: pointer;
}

/* Pagination Footer */
.table-pagination-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 28px;
  border-top: 1px solid #f1f5f9;
  font-size: 13px;
  color: #64748b;
}
.per-page-selector { display: flex; align-items: center; gap: 8px; }
.per-page-select { padding: 4px 8px; border: 1px solid #e2e8f0; border-radius: 6px; font-size: 12.5px; outline: none; }
.pagination-controls { display: flex; align-items: center; gap: 4px; }
.page-nav-btn {
  padding: 6px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
  font-size: 12.5px;
  cursor: pointer;
}
.page-nav-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.page-num-btn {
  width: 32px;
  height: 32px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
  font-size: 12.5px;
  font-weight: 600;
  cursor: pointer;
}
.page-num-btn.page-active { background-color: #0B529C; color: #ffffff; border-color: #0B529C; }

/* Side Drawer Overlay & Panel */
.drawer-overlay {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(2px);
  z-index: 9999;
  display: flex;
  justify-content: flex-end;
}
.drawer-panel {
  width: 600px;
  height: 100vh;
  background-color: #ffffff;
  box-shadow: -10px 0 30px rgba(0, 0, 0, 0.15);
  display: flex;
  flex-direction: column;
  animation: slideDrawer 0.25s ease-out;
}
@keyframes slideDrawer {
  from { transform: translateX(100%); }
  to { transform: translateX(0); }
}

.drawer-header {
  padding: 20px 24px;
  border-bottom: 1px solid #e2e8f0;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  background-color: #fafafa;
}
.drawer-badge-row { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
.drawer-record-name { font-size: 18px; font-weight: 700; color: #0f172a; margin: 0 0 2px 0; }
.drawer-subtitle { font-size: 12.5px; color: #64748b; margin: 0; }
.drawer-close-btn { background: none; border: none; color: #64748b; cursor: pointer; padding: 4px; border-radius: 6px; }
.drawer-close-btn:hover { background-color: #f1f5f9; color: #0f172a; }

.drawer-body { flex: 1; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 20px; }

.undo-banner-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 18px;
  border: 1px solid #bfdbfe;
  border-radius: 12px;
  background-color: #eff6ff;
}
.undo-banner-left { display: flex; align-items: center; gap: 12px; }
.undo-title { font-size: 13.5px; font-weight: 700; color: #1e3a8a; display: block; }
.undo-sub { font-size: 12px; color: #3b82f6; margin: 0; }
.btn-revert-action {
  padding: 8px 14px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
}
.btn-revert-action:disabled { background-color: #94a3b8; cursor: not-allowed; }

.section-container { display: flex; flex-direction: column; gap: 8px; }
.section-title { font-size: 14px; font-weight: 700; color: #0f172a; display: flex; align-items: center; gap: 8px; margin: 0; }
.section-hint { font-size: 12px; color: #64748b; margin: 0; }

.diff-comparison-table-wrapper { border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden; }
.diff-table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
.diff-table th { background-color: #f8fafc; padding: 10px 12px; border-bottom: 1px solid #e2e8f0; font-weight: 600; color: #475569; text-align: left; }
.diff-table td { padding: 10px 12px; border-bottom: 1px solid #f1f5f9; }
.diff-row-changed { background-color: #fffbeb; }
.sensitive-tag { font-size: 9.5px; font-weight: 700; color: #be123c; background: #ffe4e6; padding: 1px 4px; border-radius: 4px; margin-left: 6px; }

.value-badge { display: inline-block; padding: 3px 8px; border-radius: 6px; font-size: 12px; }
.before-value { background-color: #f1f5f9; color: #475569; text-decoration: line-through; }
.after-value { background-color: #f1f5f9; color: #0f172a; }
.after-value-highlight { background-color: #dcfce7; color: #15803d; font-weight: 700; border: 1px solid #86efac; }

.info-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; background-color: #fafafa; padding: 14px; border: 1px solid #e2e8f0; border-radius: 10px; }
.info-item { display: flex; flex-direction: column; gap: 2px; }
.info-label { font-size: 11px; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.03em; }
.info-val { font-size: 12.5px; color: #0f172a; }

.session-timeline { display: flex; flex-direction: column; gap: 8px; padding-left: 8px; border-left: 2px solid #e2e8f0; }
.session-step { display: flex; align-items: center; gap: 8px; font-size: 12.5px; color: #334155; }
.session-time { font-size: 11.5px; font-weight: 700; color: #64748b; min-width: 60px; }
.session-action { font-weight: 600; color: #0B529C; }

/* Floating AI Assistant Widget */
.ai-widget-wrapper {
  position: fixed;
  bottom: 28px;
  right: 28px;
  z-index: 9900;
}
.floating-ai-btn {
  position: relative;
  width: 52px;
  height: 52px;
  border-radius: 50%;
  background: linear-gradient(135deg, #2563eb 0%, #7c3aed 100%);
  color: #ffffff;
  border: none;
  box-shadow: 0 10px 25px -5px rgba(37, 99, 235, 0.4);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}
.floating-ai-btn:hover {
  transform: scale(1.08);
  box-shadow: 0 14px 30px -5px rgba(37, 99, 235, 0.5);
}
.sparkle-anim { animation: pulse 2s infinite; }
@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }

.ai-btn-badge {
  position: absolute;
  top: -2px;
  right: -2px;
  background-color: #10b981;
  color: #ffffff;
  font-size: 9px;
  font-weight: 800;
  padding: 1px 5px;
  border-radius: 10px;
  border: 2px solid #ffffff;
}

.ai-assistant-card {
  position: absolute;
  bottom: 64px;
  right: 0;
  width: 380px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  box-shadow: 0 20px 40px -10px rgba(0, 0, 0, 0.2);
  overflow: hidden;
  animation: popupFade 0.2s ease-out;
}
@keyframes popupFade {
  from { opacity: 0; transform: translateY(10px) scale(0.96); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

.ai-card-header {
  padding: 14px 16px;
  background: linear-gradient(135deg, #eff6ff 0%, #f5f3ff 100%);
  border-bottom: 1px solid #e2e8f0;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.ai-header-left { display: flex; align-items: center; gap: 8px; }
.ai-card-title { font-size: 13.5px; font-weight: 700; color: #0f172a; }
.ai-close-btn { background: none; border: none; color: #64748b; cursor: pointer; }

.ai-card-body { padding: 16px; display: flex; flex-direction: column; gap: 12px; }
.ai-prompt-instruction { font-size: 12px; color: #64748b; margin: 0; }

.ai-chips { display: flex; flex-direction: column; gap: 6px; }
.ai-chip-btn {
  text-align: left;
  padding: 8px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #fafafa;
  font-size: 12px;
  color: #334155;
  cursor: pointer;
  transition: all 0.15s ease;
}
.ai-chip-btn:hover { background-color: #eff6ff; border-color: #bfdbfe; color: #1d4ed8; }

.ai-response-box {
  padding: 12px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 12.5px;
}
.ai-thinking { display: flex; align-items: center; gap: 8px; color: #2563eb; }
.ai-response-header { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; }
.ai-response-text { margin: 0; color: #334155; line-height: 1.4; }

.ai-input-wrap { display: flex; gap: 6px; }
.ai-search-input {
  flex: 1;
  padding: 8px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  outline: none;
}
.ai-search-input:focus { border-color: #2563eb; }
.ai-submit-btn {
  padding: 8px 12px;
  background-color: #2563eb;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  cursor: pointer;
}
</style>
