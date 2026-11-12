<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, Search, Filter, MoreVertical,
  Clock, CheckCircle2, FileText, X,
  Send, ShieldCheck, Layers, Edit
} from 'lucide-vue-next';;

import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import MetricCard from '../../components/MetricCard.vue';
import UnderlineTabs, { type UnderlineTabItem } from '../../components/UnderlineTabs.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';

import {
  announcementsData,
  acknowledgmentsData,
  createAnnouncement,
  updateAnnouncementState,
  deleteAnnouncement,
  getAnnouncementAcknowledgmentStats,
  type AnnouncementRecord,
  type AnnouncementAudience,
  type AnnouncementState
} from './announcementData';

const router = useRouter();

// ─── BREADCRUMBS (Rule 3: Exact Sidebar Page Name Only) ───────────────────
const breadcrumbs = [
  { label: 'Announcements' }
];

// ─── KPI METRICS (Rule 2) ─────────────────────────────────────────────────
const totalAnnouncements = computed(() => announcementsData.value.length);
const activeBroadcasts = computed(() => announcementsData.value.filter(a => a.announcement_state === 'published').length);
const scheduledNotices = computed(() => announcementsData.value.filter(a => a.announcement_state === 'scheduled').length);

const overallAckRate = computed(() => {
  const ackRequiring = announcementsData.value.filter(a => a.requires_acknowledgment);
  if (ackRequiring.length === 0) return 100;
  let totalTargeted = 0;
  let totalAcked = 0;
  for (const a of ackRequiring) {
    const stats = getAnnouncementAcknowledgmentStats(a.id);
    totalTargeted += stats.total;
    totalAcked += stats.confirmed;
  }
  return totalTargeted > 0 ? Math.round((totalAcked / totalTargeted) * 100) : 0;
});

// ─── FILTER TABS & INTERACTIVE METRICS ────────────────────────────────────
type TabId = 'all' | 'published' | 'scheduled' | 'draft' | 'archived';
const activeTab = ref<TabId>('all');
const onlyAckRequired = ref(false);

const handleFilterAll = () => {
  activeTab.value = 'all';
  onlyAckRequired.value = false;
};

const handleFilterPublished = () => {
  if (activeTab.value === 'published' && !onlyAckRequired.value) {
    activeTab.value = 'all';
  } else {
    activeTab.value = 'published';
    onlyAckRequired.value = false;
  }
};

const handleFilterAck = () => {
  onlyAckRequired.value = !onlyAckRequired.value;
  activeTab.value = 'all';
};

const handleFilterScheduled = () => {
  if (activeTab.value === 'scheduled' && !onlyAckRequired.value) {
    activeTab.value = 'all';
  } else {
    activeTab.value = 'scheduled';
    onlyAckRequired.value = false;
  }
};

const statusTabs = computed<UnderlineTabItem<TabId>[]>(() => [
  { id: 'all', label: 'All Announcements', count: announcementsData.value.length },
  { id: 'published', label: 'Published & Live', count: announcementsData.value.filter(a => a.announcement_state === 'published').length, badgeVariant: 'success' },
  { id: 'scheduled', label: 'Scheduled', count: announcementsData.value.filter(a => a.announcement_state === 'scheduled').length, badgeVariant: 'primary' },
  { id: 'draft', label: 'Draft', count: announcementsData.value.filter(a => a.announcement_state === 'draft').length },
  { id: 'archived', label: 'Archived', count: announcementsData.value.filter(a => a.announcement_state === 'archived').length }
]);

// ─── SEARCH & FILTERING ──────────────────────────────────────────────────
const searchQuery = ref('');

const filteredAnnouncements = computed(() => {
  return announcementsData.value.filter(a => {
    // Ack required filter
    if (onlyAckRequired.value && !a.requires_acknowledgment) {
      return false;
    }
    // Tab filter
    if (activeTab.value !== 'all' && a.announcement_state !== activeTab.value) {
      return false;
    }
    // Search filter
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase();
      const matchTitle = a.title.toLowerCase().includes(q);
      const matchCode = a.code.toLowerCase().includes(q);
      const matchAudience = a.target_summary.toLowerCase().includes(q);
      const matchPublisher = (a.published_by_name || '').toLowerCase().includes(q);
      if (!matchTitle && !matchCode && !matchAudience && !matchPublisher) return false;
    }
    return true;
  });
});

// ─── SELECTION ───────────────────────────────────────────────────────────
const selectedIds = ref<number[]>([]);
const isAllSelected = computed(() => {
  return (
    filteredAnnouncements.value.length > 0 &&
    filteredAnnouncements.value.every(a => selectedIds.value.includes(a.id))
  );
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedIds.value = [];
  } else {
    selectedIds.value = filteredAnnouncements.value.map(a => a.id);
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

// ─── TABLE COLUMNS (Rule 9: Atomic columns, Name first, Code subtext) ────
const tableColumns = ref<ColumnDef[]>([
  { key: 'title', label: 'Notice Title', sortable: true, visible: true },
  { key: 'audience', label: 'Audience Scope', sortable: true, visible: true },
  { key: 'publish_window', label: 'Publish Window', sortable: true, visible: true },
  { key: 'acknowledgment', label: 'Compliance Acknowledgment', sortable: false, visible: true },
  { key: 'status', label: 'Status', sortable: true, visible: true },
  { key: 'targets', label: 'Audience Targets', visible: false },
  { key: 'published_by', label: 'Published By', visible: false },
  { key: 'state', label: 'State', visible: false },
  { key: 'actions', label: 'Actions', width: '60px', sortable: false, visible: true }
]);

const handleToggleColumn = (colKey: string) => {
  const col = tableColumns.value.find(c => c.key === colKey);
  if (col) col.visible = !col.visible;
};

const isColumnVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible : true;
};

const formatAudienceScope = (aud: AnnouncementAudience) => {
  switch (aud) {
    case 'all': return 'All Staff';
    case 'organization_unit': return 'Organization Unit';
    case 'position': return 'Job Position';
    case 'grade': return 'Job Grade';
    case 'employee_list': return 'Employee List';
    default: return aud;
  }
};

// Universal Date Formatting Standard (Rule 22: MMM D, YYYY)
const formatDate = (dateStr: string | null | undefined) => {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
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

// Navigate directly to dedicated announcement creation page (AGENTS.md Rule 4: > 5 fields standard)
const handleCreateAnnouncement = () => {
  router.push('/hr/announcements/create');
};

// Navigate to edit announcement on dedicated full page
const navigateToEdit = (id: number) => {
  closeActionMenu();
  router.push({
    path: '/hr/announcements/create',
    query: { id: id.toString() }
  });
};

// ─── ACKNOWLEDGMENT PROGRESS MODAL ───────────────────────────────────────
const isAckModalOpen = ref(false);
const activeAckAnnouncement = ref<AnnouncementRecord | null>(null);
const ackSearchQuery = ref('');
const ackFilterStatus = ref<'all' | 'confirmed' | 'pending'>('all');

const openAckModal = (announcement: AnnouncementRecord) => {
  activeAckAnnouncement.value = announcement;
  ackSearchQuery.value = '';
  ackFilterStatus.value = 'all';
  isAckModalOpen.value = true;
  closeActionMenu();
};

const ackListForActiveAnnouncement = computed(() => {
  if (!activeAckAnnouncement.value) return [];
  const list = acknowledgmentsData.value.filter(a => a.announcement_id === activeAckAnnouncement.value!.id);
  return list.filter(item => {
    if (ackFilterStatus.value === 'confirmed' && item.acknowledged_at === null) return false;
    if (ackFilterStatus.value === 'pending' && item.acknowledged_at !== null) return false;
    if (ackSearchQuery.value.trim()) {
      const q = ackSearchQuery.value.toLowerCase();
      return (
        item.employee_name.toLowerCase().includes(q) ||
        item.employee_code.toLowerCase().includes(q) ||
        item.department.toLowerCase().includes(q)
      );
    }
    return true;
  });
});

const ackStatsForActiveAnnouncement = computed(() => {
  if (!activeAckAnnouncement.value) return { total: 0, confirmed: 0, pending: 0, rate: 0 };
  return getAnnouncementAcknowledgmentStats(activeAckAnnouncement.value.id);
});

// Quick status actions
const handlePublishNow = (id: number) => {
  updateAnnouncementState(id, 'published');
  closeActionMenu();
};

const handleArchive = (id: number) => {
  updateAnnouncementState(id, 'archived');
  closeActionMenu();
};

const handleDelete = (id: number) => {
  if (confirm('Are you sure you want to delete this announcement notice?')) {
    deleteAnnouncement(id);
    closeActionMenu();
  }
};
</script>

<template>
  <div class="announcements-page" @click="closeActionMenu">
    <!-- Breadcrumbs (Rule 3: Exact Sidebar Page Name Only) -->
    <AppBreadcrumb :items="breadcrumbs" />

    <!-- 4 KPI Metrics Cards (Rule 2 - Interactive Click-to-Filter) -->
    <div class="metrics-grid">
      <div
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'all' && !onlyAckRequired }"
        @click="handleFilterAll"
      >
        <MetricCard
          label="TOTAL ANNOUNCEMENTS"
          :value="totalAnnouncements"
          subtext="All corporate notices on record"
          :show-menu="false"
        />
      </div>

      <div
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'published' && !onlyAckRequired }"
        @click="handleFilterPublished"
      >
        <MetricCard
          label="ACTIVE BROADCASTS"
          :value="activeBroadcasts"
          subtext="Live on employee dashboards"
          :show-menu="false"
        />
      </div>

      <div
        class="metric-interactive"
        :class="{ 'metric-active': onlyAckRequired }"
        @click="handleFilterAck"
      >
        <MetricCard
          label="COMPLIANCE ACKNOWLEDGMENT"
          :value="overallAckRate + '%'"
          subtext="Policy compliance confirmed"
          :show-menu="false"
        />
      </div>

      <div
        class="metric-interactive"
        :class="{ 'metric-active': activeTab === 'scheduled' && !onlyAckRequired }"
        @click="handleFilterScheduled"
      >
        <MetricCard
          label="SCHEDULED NOTICES"
          :value="scheduledNotices"
          subtext="Queued for automated release"
          :show-menu="false"
        />
      </div>
    </div>

    <!-- Main Data Table Card Container (Rule 10) -->
    <div class="announcements-table-card">
      <AppDataTable
        title="Announcements & Notices"
        subtitle="Manage company-wide bulletins, statutory policy circulars, and mandatory employee acknowledgment tracking."
        v-model:searchQuery="searchQuery"
        :columns="tableColumns"
        :totalEntries="filteredAnnouncements.length"
        @toggleColumn="handleToggleColumn"
      >
        <!-- Primary Action Inside Table Toolbar Header Slot (Rule 10) -->
        <template #actions>
          <AppButton variant="primary" size="sm" @click="handleCreateAnnouncement">
  <template #icon-left><Plus :size="15" /></template>
  Create Announcement
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
                <th v-if="isColumnVisible('title')">Notice Title</th>
                <th v-if="isColumnVisible('audience')">Audience Scope</th>
                <th v-if="isColumnVisible('targets')">Audience Targets</th>
                <th v-if="isColumnVisible('publish_window')">Publish Window</th>
                <th v-if="isColumnVisible('acknowledgment')">Requires Acknowledgment</th>
                <th v-if="isColumnVisible('published_by')">Published By</th>
                <th v-if="isColumnVisible('status')">Status</th>
                <th v-if="isColumnVisible('state')">State</th>
                <th v-if="isColumnVisible('actions')" class="th-actions"></th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="item in filteredAnnouncements"
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

                <!-- Title & Code (Rule 4: Zero standalone code column, Name/Title first) -->
                <td v-if="isColumnVisible('title')" class="td-title">
                  <div class="title-cell-wrapper" @click="navigateToEdit(item.id)">
                    <span class="table-name-primary">{{ item.title }}</span>
                    <span class="table-code-subtext">{{ item.code }}</span>
                  </div>
                </td>

                <!-- Audience Scope (Rule 5: Tertiary color) -->
                <td v-if="isColumnVisible('audience')" class="td-audience">
                  <span class="tertiary-text">{{ formatAudienceScope(item.audience) }}</span>
                </td>

                <!-- Audience Targets (AnnouncementTarget [LINE] summary) -->
                <td v-if="isColumnVisible('targets')" class="td-targets">
                  <span class="tertiary-text">{{ item.audience === 'all' ? '— (All Active Staff)' : item.target_summary }}</span>
                </td>

                <!-- Publish Window (Rule 22: Universal MMM D, YYYY) -->
                <td v-if="isColumnVisible('publish_window')" class="td-window">
                  <span class="tertiary-text">
                    {{ formatDate(item.publish_from) }}
                    {{ item.publish_to ? '– ' + formatDate(item.publish_to) : '(Permanent)' }}
                  </span>
                </td>

                <!-- Compliance Acknowledgment Progress -->
                <td v-if="isColumnVisible('acknowledgment')" class="td-ack">
                  <div v-if="item.requires_acknowledgment" class="ack-progress-box" @click.stop="openAckModal(item)">
                    <div class="ack-pill-rate">
                      <span class="rate-number">{{ getAnnouncementAcknowledgmentStats(item.id).rate }}%</span>
                      <span class="rate-sub">({{ getAnnouncementAcknowledgmentStats(item.id).confirmed }}/{{ getAnnouncementAcknowledgmentStats(item.id).total }})</span>
                    </div>
                    <div class="mini-progress-bar">
                      <div class="progress-fill" :style="{ width: getAnnouncementAcknowledgmentStats(item.id).rate + '%' }"></div>
                    </div>
                  </div>
                  <span v-else class="tertiary-text">No</span>
                </td>

                <!-- Published By (FK Employee) -->
                <td v-if="isColumnVisible('published_by')" class="td-publisher">
                  <span class="tertiary-text">{{ item.published_by_name || '—' }}</span>
                </td>

                <!-- Status (Lifecycle state) -->
                <td v-if="isColumnVisible('status')">
                  <span
                    class="status-pill"
                    :class="`status-${item.announcement_state}`"
                  >
                    {{ item.announcement_state.charAt(0).toUpperCase() + item.announcement_state.slice(1) }}
                  </span>
                </td>

                <!-- State (Rule 9: Active / Inactive) -->
                <td v-if="isColumnVisible('state')">
                  <span
                    class="state-pill"
                    :class="`state-${item.state}`"
                  >
                    {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                  </span>
                </td>

                <!-- Actions Menu (3-dots) -->
                <td v-if="isColumnVisible('actions')" class="td-actions">
                  <div class="action-dropdown-wrapper">
                    <button
                      class="btn-action-dots"
                      title="More actions"
                      @click="toggleActionMenu(item.id, $event)"
                    >
                      <MoreVertical :size="15" />
                    </button>

                    <!-- Popup Dropdown Menu -->
                    <div
                      v-if="openActionMenuId === item.id"
                      class="action-menu-popup"
                      @click.stop
                    >
                      <button class="menu-item" @click="navigateToEdit(item.id)">
                        <Edit :size="14" />
                        <span>Edit Full Announcement</span>
                      </button>

                      <button
                        v-if="item.requires_acknowledgment"
                        class="menu-item"
                        @click="openAckModal(item)"
                      >
                        <ShieldCheck :size="14" />
                        <span>Compliance Progress</span>
                      </button>

                      <button
                        v-if="item.announcement_state !== 'published'"
                        class="menu-item"
                        @click="handlePublishNow(item.id)"
                      >
                        <Send :size="14" />
                        <span>Publish Now</span>
                      </button>

                      <button
                        v-if="item.announcement_state !== 'archived'"
                        class="menu-item"
                        @click="handleArchive(item.id)"
                      >
                        <Layers :size="14" />
                        <span>Archive Notice</span>
                      </button>

                      <div class="menu-divider"></div>

                      <button class="menu-item danger" @click="handleDelete(item.id)">
                        <X :size="14" />
                        <span>Delete Notice</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>

              <!-- Empty state -->
              <tr v-if="filteredAnnouncements.length === 0">
                <td colspan="9" class="td-empty">
                  <div class="empty-state-content">
                    <FileText :size="38" class="empty-icon" />
                    <p class="empty-title">No announcements found</p>
                    <p class="empty-desc">No notices match your current search or status filter.</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </template>
      </AppDataTable>
    </div>

    <!-- ─── COMPLIANCE ACKNOWLEDGMENT PROGRESS MODAL ────────────────────── -->
    <div v-if="isAckModalOpen" class="modal-backdrop" @click="isAckModalOpen = false">
      <div class="ack-modal-dialog" @click.stop>
        <div class="modal-header">
          <div>
            <h3 class="modal-title">Compliance Acknowledgment Tracking</h3>
            <p class="modal-sub">
              {{ activeAckAnnouncement?.code }} — {{ activeAckAnnouncement?.title }}
            </p>
          </div>
          <button class="btn-close-modal" @click="isAckModalOpen = false">
            <X :size="18" />
          </button>
        </div>

        <!-- Summary Statistics Row -->
        <div class="ack-metrics-row">
          <div class="ack-stat-card">
            <span class="stat-num">{{ ackStatsForActiveAnnouncement.rate }}%</span>
            <span class="stat-lbl">Compliance Rate</span>
          </div>
          <div class="ack-stat-card">
            <span class="stat-num">{{ ackStatsForActiveAnnouncement.confirmed }}</span>
            <span class="stat-lbl">Acknowledged</span>
          </div>
          <div class="ack-stat-card">
            <span class="stat-num">{{ ackStatsForActiveAnnouncement.pending }}</span>
            <span class="stat-lbl">Pending Read</span>
          </div>
          <div class="ack-stat-card">
            <span class="stat-num">{{ activeAckAnnouncement?.acknowledgment_deadline || 'None' }}</span>
            <span class="stat-lbl">Statutory Deadline</span>
          </div>
        </div>

        <!-- Filter bar -->
        <div class="modal-filter-toolbar">
          <div class="modal-search-box">
            <Search :size="14" class="search-icon" />
            <input
              v-model="ackSearchQuery"
              type="text"
              class="modal-search-input"
            />
          </div>

          <div class="modal-filter-buttons">
            <button
              class="btn-filter-pill"
              :class="{ active: ackFilterStatus === 'all' }"
              @click="ackFilterStatus = 'all'"
            >
              All ({{ acknowledgmentsData.filter(a => a.announcement_id === activeAckAnnouncement?.id).length }})
            </button>
            <button
              class="btn-filter-pill"
              :class="{ active: ackFilterStatus === 'confirmed' }"
              @click="ackFilterStatus = 'confirmed'"
            >
              Confirmed
            </button>
            <button
              class="btn-filter-pill"
              :class="{ active: ackFilterStatus === 'pending' }"
              @click="ackFilterStatus = 'pending'"
            >
              Pending
            </button>
          </div>
        </div>

        <!-- Employees List Table -->
        <div class="ack-table-wrapper">
          <table class="erp-table ack-table">
            <thead>
              <tr>
                <th>Employee</th>
                <th>Department & Position</th>
                <th>Compliance Status</th>
                <th class="th-actions">Action</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="ack in ackListForActiveAnnouncement" :key="ack.id">
                <td class="ack-emp-cell">
                  <img :src="ack.employee_avatar" alt="" class="ack-avatar" />
                  <div>
                    <span class="ack-emp-name">{{ ack.employee_name }}</span>
                    <span class="ack-emp-code">{{ ack.employee_code }}</span>
                  </div>
                </td>
                <td>
                  <span class="tertiary-text">{{ ack.department }}</span>
                  <div class="sub-role">{{ ack.position }}</div>
                </td>
                <td>
                  <div v-if="ack.acknowledged_at" class="ack-status-tag confirmed">
                    <CheckCircle2 :size="13" />
                    <span>Read on {{ formatDate(ack.acknowledged_at) }}</span>
                  </div>
                  <div v-else class="ack-status-tag pending">
                    <Clock :size="13" />
                    <span>Pending Read</span>
                  </div>
                </td>
                <td class="td-actions">
                  <button
                    v-if="!ack.acknowledged_at"
                    class="btn-nudge-staff"
                    title="Send reminder email/SMS"
                    @click="alert(`Reminder notification sent to ${ack.employee_name}.`)"
                  >
                    <Send :size="12" />
                    <span>Nudge</span>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="modal-footer">
          <AppButton variant="outline" size="sm" @click="isAckModalOpen = false">
            Close
          </AppButton>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Page Layout */
.announcements-page {
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
}

/* 4 Metrics Grid (Rule 2) */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.metric-interactive {
  cursor: pointer;
  border-radius: 10px;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.metric-interactive:hover {
  transform: translateY(-2px);
}

.metric-interactive.metric-active {
  box-shadow: 0 0 0 2px #0B529C;
  border-radius: 10px;
}

@media (max-width: 1024px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* Main Table Card (Rule 10) */
.announcements-table-card {
  background: #ffffff;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.table-tabs-wrapper {
  padding: 0 16px;
  border-bottom: 1px solid #f1f5f9;
}

/* Toolbar Buttons */
.btn-primary-create {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 38px;
  padding: 0 16px;
  background-color: #0b529c;
  color: #ffffff;
  font-size: 13.5px;
  font-weight: 500;
  border-radius: 8px; /* Rule 6: 8-10px */
  border: none;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary-create:hover {
  background-color: #09427d;
}

/* Table Design (Rules 8, 9) */
.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  height: 34px;
  padding: 6px 16px;
  background-color: #fafafa;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.erp-table td {
  height: 44px;
  padding: 8px 16px;
  font-size: 13px;
  color: #404040; /* Rule 7: Primary Dark */
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.erp-table-row:hover {
  background-color: #f8fafc;
}

.erp-table-row.row-selected {
  background-color: #eff6ff;
}

.th-checkbox,
.td-checkbox {
  width: 36px;
  padding: 0 0 0 16px !important;
  text-align: center;
}

.table-checkbox {
  width: 16px;
  height: 16px;
  accent-color: #0b529c;
  cursor: pointer;
}

/* Title & Code Column (Rule 4, 5) */
.title-cell-wrapper {
  display: flex;
  flex-direction: column;
  gap: 2px;
  cursor: pointer;
}

.table-name-primary {
  color: #404040; /* Rule 5: Secondary color for Name */
  font-size: 13.5px;
  font-weight: 500;
  line-height: 1.3;
}

.title-cell-wrapper:hover .table-name-primary {
  color: #0b529c;
}

.table-code-subtext {
  color: #737373; /* Rule 5: Tertiary color */
  font-size: 11.5px;
  display: flex;
  align-items: center;
  gap: 6px;
}

.attachment-chip {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  color: #0284c7;
  background-color: #f0f9ff;
  padding: 1px 6px;
  border-radius: 4px;
  font-size: 10.5px;
}

.tertiary-text {
  color: #737373; /* Rule 5 */
  font-size: 12.5px;
}

/* Compliance Progress Box */
.ack-progress-box {
  display: flex;
  flex-direction: column;
  gap: 4px;
  width: 140px;
  cursor: pointer;
}

.ack-pill-rate {
  display: flex;
  align-items: baseline;
  gap: 4px;
}

.rate-number {
  color: #0b529c;
  font-weight: 600;
  font-size: 12.5px;
}

.rate-sub {
  color: #737373;
  font-size: 11px;
}

.mini-progress-bar {
  height: 4px;
  background-color: #e2e8f0;
  border-radius: 9999px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background-color: #0b529c;
  border-radius: 9999px;
}

/* Status & State Pills (Rule 9) */
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
}

.status-published {
  background-color: #ecfdf5;
  color: #059669;
}

.status-scheduled {
  background-color: #eff6ff;
  color: #0284c7;
}

.status-draft {
  background-color: #f1f5f9;
  color: #64748b;
}

.status-archived {
  background-color: #f8fafc;
  color: #94a3b8;
}

.state-pill {
  display: inline-flex;
  align-items: center;
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

/* Actions Menu */
.th-actions,
.td-actions {
  width: 48px;
  text-align: right;
  padding-right: 16px !important;
}

.action-dropdown-wrapper {
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
  color: #737373;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.action-menu-popup {
  position: absolute;
  top: 100%;
  right: 0;
  z-index: 50;
  min-width: 180px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  padding: 4px;
  display: flex;
  flex-direction: column;
}

.menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.12s;
}

.menu-item:hover {
  background-color: #f8fafc;
  color: #0b529c;
}

.menu-item.danger {
  color: #dc2626;
}

.menu-item.danger:hover {
  background-color: #fef2f2;
}

.menu-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 4px 0;
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
  margin-bottom: 4px;
}

.empty-title {
  font-size: 14.5px;
  font-weight: 500;
  color: #404040;
  margin: 0;
}

.empty-desc {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* ─── QUICK CREATE MODAL FORM CONTENT ─────────────────────────────────── */
.quick-form-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.quick-ack-wrap {
  padding-top: 4px;
}

/* ─── ACKNOWLEDGMENT TRACKING MODAL ────────────────────────────────────── */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.5);
  backdrop-filter: blur(2px);
  z-index: 150;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.ack-modal-dialog {
  background: #ffffff;
  border-radius: 14px;
  width: 100%;
  max-width: 760px;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
  overflow: hidden;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  border-bottom: 1px solid #e2e8f0;
}

.modal-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.modal-sub {
  font-size: 12px;
  color: #737373;
  margin: 2px 0 0;
}

.btn-close-modal {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 6px;
  color: #64748b;
  cursor: pointer;
}

.ack-metrics-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  padding: 16px 24px;
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.ack-stat-card {
  display: flex;
  flex-direction: column;
}

.stat-num {
  font-size: 18px;
  font-weight: 700;
  color: #0b529c;
}

.stat-lbl {
  font-size: 11.5px;
  color: #737373;
}

.modal-filter-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 24px;
  border-bottom: 1px solid #f1f5f9;
}

.modal-search-box {
  position: relative;
  display: flex;
  align-items: center;
}

.modal-search-input {
  height: 32px;
  padding: 0 10px 0 30px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12.5px;
  outline: none;
}

.modal-search-box .search-icon {
  position: absolute;
  left: 8px;
  color: #94a3b8;
}

.modal-filter-buttons {
  display: flex;
  gap: 6px;
}

.btn-filter-pill {
  padding: 4px 10px;
  font-size: 11.5px;
  color: #64748b;
  background-color: #f1f5f9;
  border: none;
  border-radius: 9999px;
  cursor: pointer;
}

.btn-filter-pill.active {
  background-color: #0b529c;
  color: #ffffff;
}

.ack-table-wrapper {
  flex: 1;
  overflow-y: auto;
  max-height: 340px;
}

.ack-table th {
  font-size: 11.5px;
}

.ack-emp-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.ack-avatar {
  width: 28px;
  height: 28px;
  border-radius: 9999px;
  object-fit: cover;
}

.ack-emp-name {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  display: block;
}

.ack-emp-code {
  font-size: 11px;
  color: #737373;
  display: block;
}

.sub-role {
  font-size: 11px;
  color: #94a3b8;
}

.ack-status-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 500;
  padding: 2px 8px;
  border-radius: 9999px;
}

.ack-status-tag.confirmed {
  background-color: #ecfdf5;
  color: #059669;
}

.ack-status-tag.pending {
  background-color: #fffbeb;
  color: #d97706;
}

.btn-nudge-staff {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 8px;
  background-color: #f1f5f9;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  font-size: 11px;
  color: #404040;
  cursor: pointer;
}

.btn-nudge-staff:hover {
  background-color: #e2e8f0;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  padding: 12px 24px;
  border-top: 1px solid #e2e8f0;
}

.btn-secondary-action {
  height: 36px;
  padding: 0 16px;
  background-color: #ffffff;
  color: #404040;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-secondary-action:hover {
  background-color: #f8fafc;
}
</style>
