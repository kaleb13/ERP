<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Plus, Search, Filter, MoreVertical,
  CheckCircle2, Eye, Check, X,
  ShieldAlert
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import { useToast } from '../../composables/useToast';

const router = useRouter();

// ─── Breadcrumb (Image 3: "[Monitor] > Employee Movement") ───
const breadcrumbItems = [
  { label: 'Employee Movement' }
];

// ─── Table Columns (Matching Figma 6624:99272) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'select', label: '', width: '40px', sortable: false, visible: true },
  { key: 'name', label: 'Name', sortable: true, visible: true },
  { key: 'movement_type', label: 'Movement Type', sortable: true, visible: true },
  { key: 'transition', label: 'Transition Detail', sortable: false, visible: true },
  { key: 'effective_date', label: 'Effective Date', sortable: true, visible: true },
  { key: 'status', label: 'Status', sortable: true, visible: true },
  { key: 'actions', label: 'Actions', width: '60px', sortable: false, visible: true }
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

// ─── Datasets Aligned with Image 3 ───
export interface MovementDirectoryRecord {
  id: number;
  code: string;
  employee_id: number;
  name: string;
  emp_code: string;
  avatar: string;
  movement_type: string;
  from_position: string;
  to_position: string;
  effective_date: string;
  status: 'pending' | 'approved' | 'rejected' | 'effected';
  require_guarantee_refresh?: boolean;
}

const movements = ref<MovementDirectoryRecord[]>([
  {
    id: 1,
    code: 'MOV-2026-0012',
    employee_id: 12,
    name: 'Abebe Kebede',
    emp_code: 'EMP 0012',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    movement_type: 'Lateral Transfer',
    from_position: 'Inventory Controller',
    to_position: 'Inventory Controller',
    effective_date: 'Jul 8, 2026',
    status: 'rejected',
    require_guarantee_refresh: false
  },
  {
    id: 2,
    code: 'MOV-2026-0018',
    employee_id: 18,
    name: 'Kidst Tesfaye',
    emp_code: 'EMP 0018',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    movement_type: 'Promotion',
    from_position: 'HQ Security',
    to_position: 'Plant Security Guard',
    effective_date: 'Jul 8, 2026',
    status: 'pending'
  },
  {
    id: 3,
    code: 'MOV-2026-0812',
    employee_id: 812,
    name: 'Mihret Abera',
    emp_code: 'EMP 0812',
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
    movement_type: 'Hire',
    from_position: 'Inventory Controller',
    to_position: 'Inventory Controller',
    effective_date: 'Jul 8, 2026',
    status: 'effected'
  },
  {
    id: 4,
    code: 'MOV-2026-0124',
    employee_id: 124,
    name: 'Almaz Kebede',
    emp_code: 'EMP 00124',
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    movement_type: 'Promotion',
    from_position: 'Junior Accountant',
    to_position: 'Senior Accountant',
    effective_date: 'Oct 12, 2026',
    status: 'pending',
    require_guarantee_refresh: true
  }
]);

// ─── Filter & Search State ───
const searchQuery = ref('');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const { toast } = useToast();

const getStatusColor = (status: string): 'success' | 'indigo' | 'error' | 'warning' | 'blue' => {
  switch (status) {
    case 'approved': return 'success';
    case 'effected': return 'indigo';
    case 'rejected': return 'error';
    case 'pending': return 'warning';
    default: return 'blue';
  }
};

const showToast = (msg: string) => {
  toast.success(msg);
};

const filteredMovements = computed(() => {
  if (!searchQuery.value) return movements.value;
  const q = searchQuery.value.toLowerCase().trim();
  return movements.value.filter(m => 
    m.name.toLowerCase().includes(q) ||
    m.emp_code.toLowerCase().includes(q) ||
    m.movement_type.toLowerCase().includes(q) ||
    m.to_position.toLowerCase().includes(q)
  );
});

// Selection Logic
const isAllSelected = computed(() => {
  return (
    filteredMovements.value.length > 0 &&
    filteredMovements.value.every(m => selectedRowIds.value.includes(m.id))
  );
});

const handleToggleSelectAll = (checked: boolean) => {
  if (checked) {
    selectedRowIds.value = filteredMovements.value.map(m => m.id);
  } else {
    selectedRowIds.value = [];
  }
};

const handleToggleRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) {
    selectedRowIds.value.splice(idx, 1);
  } else {
    selectedRowIds.value.push(id);
  }
};

const handleNavigateCreate = () => {
  router.push('/hr/movements/create');
};

const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const closeActionMenus = () => {
  activeActionMenuId.value = null;
};

// Row Actions
const handleInspectDetails = (id: number) => {
  activeActionMenuId.value = null;
  router.push(`/hr/movements/${id}`);
};

const handleApprove = (record: MovementDirectoryRecord) => {
  record.status = 'approved';
  activeActionMenuId.value = null;
  showToast(`Movement ${record.code} approved.`);
};

const handleReject = (record: MovementDirectoryRecord) => {
  record.status = 'rejected';
  activeActionMenuId.value = null;
  showToast(`Movement ${record.code} rejected.`);
};

// Batch Actions
const handleBatchDelete = () => {
  movements.value = movements.value.filter(m => !selectedRowIds.value.includes(m.id));
  showToast(`Removed ${selectedRowIds.value.length} records.`);
  selectedRowIds.value = [];
};
</script>

<template>
  <div class="movement-directory-page" @click="closeActionMenus">
    <!-- Breadcrumb Standard (Image 3: "[Monitor] > Employee Movement") -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Master Unified Table Card (Matching Figma 6624:99272) -->
    <AppDataTable
      title="Employee Movement"
      subtitle="Manage lifecycle employee promotions, lateral transfers, grade step increments, secondments, and active employment assignments across facilities."
      :columns="tableColumns"
      v-model:searchQuery="searchQuery"
      :totalEntries="filteredMovements.length"
      @toggleColumn="handleToggleColumn"
    >
      <template #actions>
        <AppButton variant="primary" size="sm" @click="handleNavigateCreate">
  <template #icon-left><Plus :size="15" /></template>
  Create Movement
</AppButton>
      </template>

      <template #default>
        <div class="table-responsive-wrapper">
          <table class="erp-table">
            <thead>
              <tr>
                <th v-if="isColVisible('select')" class="th-checkbox">
                  <input
                    type="checkbox"
                    class="table-checkbox"
                    :checked="isAllSelected"
                    @change="handleToggleSelectAll(($event.target as HTMLInputElement).checked)"
                  />
                </th>
                <th v-if="isColVisible('name')">Name</th>
                <th v-if="isColVisible('movement_type')">Movement Type</th>
                <th v-if="isColVisible('transition')">Transition Detail</th>
                <th v-if="isColVisible('effective_date')">Effective Date</th>
                <th v-if="isColVisible('status')">Status</th>
                <th v-if="isColVisible('actions')" class="th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="item in filteredMovements"
                :key="item.id"
                class="table-row-hover"
                @click="handleInspectDetails(item.id)"
              >
                <!-- Checkbox -->
                <td v-if="isColVisible('select')" class="td-checkbox" @click.stop>
                  <input
                    type="checkbox"
                    class="table-checkbox"
                    :checked="selectedRowIds.includes(item.id)"
                    @change="handleToggleRow(item.id)"
                  />
                </td>

                <!-- Name (Avatar + Bold Name + EMP code subtext underneath) -->
                <td v-if="isColVisible('name')">
                  <div class="name-cell-group">
                    <img :src="item.avatar" :alt="item.name" class="table-avatar-img" />
                    <div class="name-meta-col">
                      <span class="table-emp-name">{{ item.name }}</span>
                      <span class="table-emp-code">{{ item.emp_code }}</span>
                    </div>
                  </div>
                </td>

                <!-- Movement Type (Tertiary color #737373) -->
                <td v-if="isColVisible('movement_type')" class="td-tertiary">
                  <div class="movement-type-cell">
                    <span>{{ item.movement_type }}</span>
                    <span v-if="item.require_guarantee_refresh" class="table-surety-badge" title="Financial Surety / Guarantor Refresh Required">
                      <ShieldAlert :size="10" />
                      <span>Surety Req.</span>
                    </span>
                  </div>
                </td>

                <!-- Transition Detail: e.g. Inventory Controller ➔ Inventory Controller -->
                <td v-if="isColVisible('transition')" class="td-tertiary">
                  <span class="transition-detail-text">
                    {{ item.from_position }} &rarr; {{ item.to_position }}
                  </span>
                </td>

                <!-- Effective Date -->
                <td v-if="isColVisible('effective_date')" class="td-tertiary">
                  {{ item.effective_date }}
                </td>

                <!-- Status (Status Pill: Rejected, Pending, Effected, Approved) -->
                <td v-if="isColVisible('status')">
                  <BaseBadge :color="getStatusColor(item.status)">
                    {{ item.status.charAt(0).toUpperCase() + item.status.slice(1) }}
                  </BaseBadge>
                </td>

                <!-- Actions (⋮ 3-dots popup) -->
                <td v-if="isColVisible('actions')" class="td-actions" @click.stop>
                  <div class="action-dropdown-wrapper">
                    <button
                      type="button"
                      class="btn-action-dots"
                      title="Actions"
                      @click="toggleActionMenu(item.id)"
                    >
                      <MoreVertical :size="15" />
                    </button>

                    <div v-if="activeActionMenuId === item.id" class="action-popup-menu">
                      <button type="button" class="popup-item" @click="handleInspectDetails(item.id)">
                        <Eye :size="13" />
                        <span>View Details</span>
                      </button>
                      <button 
                        v-if="item.status === 'pending'" 
                        type="button" 
                        class="popup-item item-approve" 
                        @click="handleApprove(item)"
                      >
                        <Check :size="13" />
                        <span>Approve</span>
                      </button>
                      <button 
                        v-if="item.status === 'pending'" 
                        type="button" 
                        class="popup-item item-reject" 
                        @click="handleReject(item)"
                      >
                        <X :size="13" />
                        <span>Reject</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>

              <!-- Empty State -->
              <tr v-if="filteredMovements.length === 0">
                <td colspan="7" class="empty-state-cell">
                  <span class="empty-text">No movement records found matching your search.</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
    </AppDataTable>

    <!-- Floating Batch Action Bar -->
    <TableFloatingBar
      :show="selectedRowIds.length > 0"
      :selected-count="selectedRowIds.length"
      :total-count="filteredMovements.length"
      @delete="handleBatchDelete"
      @close="selectedRowIds = []"
    />
  </div>
</template>

<style scoped>
.movement-directory-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

/* Master Unified Table Card (Matching Image 3) */
.master-table-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}

.card-title-row {
  padding: 20px 24px 14px 24px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.table-card-title {
  margin: 0;
  font-size: 17px;
  font-weight: 600;
  color: #404040;
}

.table-card-subtitle {
  margin: 0;
  font-size: 12.5px;
  color: #737373;
  line-height: 1.45;
}

/* Toolbar Row */
.table-toolbar-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px 16px 24px;
  gap: 16px;
}

@media (max-width: 900px) {
  .table-toolbar-row {
    flex-direction: column;
    align-items: stretch;
  }
}

.search-input-wrapper {
  position: relative;
  width: 280px;
}

@media (max-width: 900px) {
  .search-input-wrapper {
    width: 100%;
  }
}

.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
}

.search-text-input {
  width: 100%;
  height: 36px;
  padding: 0 12px 0 32px;
  font-size: 13px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  transition: border-color 0.15s;
}

.search-text-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.toolbar-actions-block {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.btn-toolbar-secondary {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-toolbar-secondary:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.btn-toolbar-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-toolbar-icon:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.btn-create-primary {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 16px;
  background-color: #0B529C;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-create-primary:hover {
  background-color: #094380;
}

/* Table */
.table-responsive-wrapper {
  width: 100%;
  overflow-x: auto;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  height: 38px;
  padding: 8px 18px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  border-top: 1px solid #f1f5f9;
  border-bottom: 1px solid #e2e8f0;
  text-align: left;
}

.erp-table td {
  height: 44px;
  padding: 10px 18px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
}

.table-row-hover:hover {
  background-color: #f8fafc;
  cursor: pointer;
}

.th-checkbox, .td-checkbox {
  width: 44px;
  text-align: center;
  padding: 8px 12px !important;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  border-radius: 4px;
  accent-color: #0B529C;
  cursor: pointer;
}

/* Name Cell */
.name-cell-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.table-avatar-img {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}

.name-meta-col {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.table-emp-name {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.table-emp-code {
  font-size: 11px;
  color: #737373;
}

.td-tertiary {
  color: #737373 !important;
}

.transition-detail-text {
  color: #737373;
}

.movement-type-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.table-surety-badge {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  font-size: 10px;
  font-weight: 600;
  background-color: #fffbeb;
  color: #b45309;
  border: 1px solid #fde68a;
  padding: 1px 6px;
  border-radius: 4px;
}

/* Actions */
.th-actions, .td-actions {
  text-align: right;
  width: 60px;
}

.action-dropdown-wrapper {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  background: transparent;
  border: none;
  border-radius: 6px;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.action-popup-menu {
  position: absolute;
  top: 32px;
  right: 0;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  min-width: 140px;
  z-index: 50;
  padding: 4px;
}

.popup-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 12px;
  background: none;
  border: none;
  font-size: 12.5px;
  color: #404040;
  cursor: pointer;
  border-radius: 6px;
  text-align: left;
}

.popup-item:hover {
  background-color: #f1f5f9;
}

.item-approve { color: #059669; }
.item-approve:hover { background-color: #ecfdf5; }

.item-reject { color: #dc2626; }
.item-reject:hover { background-color: #fef2f2; }

/* Empty state */
.empty-state-cell {
  text-align: center;
  padding: 36px !important;
}

.empty-text {
  font-size: 13px;
  color: #737373;
}

/* Pagination Footer (Matching Image 3) */
.table-pagination-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  border-top: 1px solid #f1f5f9;
  font-size: 12.5px;
  color: #737373;
}

@media (max-width: 768px) {
  .table-pagination-footer {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }
}

.pagination-controls-right {
  display: flex;
  align-items: center;
  gap: 18px;
}

.per-page-selector {
  display: flex;
  align-items: center;
  gap: 8px;
}

.per-page-box {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12.5px;
  color: #404040;
  cursor: pointer;
}

.pagination-nav-buttons {
  display: flex;
  align-items: center;
  gap: 4px;
}

.btn-page-step {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  height: 32px;
  padding: 0 10px;
  background: transparent;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12.5px;
  color: #404040;
  cursor: pointer;
}

.btn-page-step:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-page-number {
  min-width: 30px;
  height: 32px;
  padding: 0 6px;
  background: transparent;
  border: none;
  border-radius: 6px;
  font-size: 12.5px;
  color: #404040;
  cursor: pointer;
}

.btn-page-number.active {
  background-color: #0B529C;
  color: #ffffff;
  font-weight: 600;
}

.page-ellipsis {
  padding: 0 4px;
  color: #94a3b8;
}
</style>
