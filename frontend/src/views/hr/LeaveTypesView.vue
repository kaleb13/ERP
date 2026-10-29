<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Plus, MoreVertical, Eye, CheckCircle2, 
  Check, X, ShieldCheck, FileText, AlertCircle, Trash2
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import FormInput from '../../components/FormInput.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import { 
  leaveTypesData, 
  createLeaveType, 
  type LeaveTypeRecord 
} from './leavePolicyData';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'Leave Type' }
];

const leaveTypes = leaveTypesData;
const searchQuery = ref('');
const isQuickCreateOpen = ref(false);
const activeActionMenuId = ref<number | null>(null);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Quick Create Form State (<= 5 Required Fields per Rule 4) ───
const quickForm = ref({
  code: '',
  name: '',
  description: '',
  is_paid: true,
  requires_attachment: false,
  affects_attendance: true
});

const resetQuickForm = () => {
  quickForm.value = {
    code: '',
    name: '',
    description: '',
    is_paid: true,
    requires_attachment: false,
    affects_attendance: true
  };
};

// ─── Table Columns Architecture (AGENTS.md Rule 9) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Leave Type Name & Code', sortable: true },
  { key: 'is_paid', label: 'Compensation Type', sortable: true },
  { key: 'requires_attachment', label: 'Document Evidence', sortable: true },
  { key: 'affects_attendance', label: 'Affects Attendance', sortable: true },
  { key: 'state', label: 'State', sortable: true },
  { key: 'actions', label: '', width: '48px', align: 'center' }
]);

const filteredTypes = computed(() => {
  if (!searchQuery.value) return leaveTypes.value;
  const q = searchQuery.value.toLowerCase().trim();
  return leaveTypes.value.filter(t => 
    t.name.toLowerCase().includes(q) || 
    t.code.toLowerCase().includes(q) ||
    t.description.toLowerCase().includes(q)
  );
});

// ─── Selection for Batch Operations (AGENTS.md Rule 11) ───
const selectedIds = ref<number[]>([]);

const isAllSelected = computed(() => {
  return filteredTypes.value.length > 0 && selectedIds.value.length === filteredTypes.value.length;
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedIds.value = [];
  } else {
    selectedIds.value = filteredTypes.value.map(t => t.id);
  }
};

const toggleSelectRow = (id: number) => {
  const idx = selectedIds.value.indexOf(id);
  if (idx > -1) {
    selectedIds.value.splice(idx, 1);
  } else {
    selectedIds.value.push(id);
  }
};

const handleBatchDelete = () => {
  leaveTypes.value = leaveTypes.value.filter(t => !selectedIds.value.includes(t.id));
  showToast(`Deleted ${selectedIds.value.length} leave category(ies).`);
  selectedIds.value = [];
};

// ─── Create Handler ───
const handleQuickSave = () => {
  if (!quickForm.value.code.trim() || !quickForm.value.name.trim()) {
    alert('Please enter both leave code and name.');
    return;
  }

  const newRec = createLeaveType({
    code: quickForm.value.code,
    name: quickForm.value.name,
    description: quickForm.value.description,
    is_paid: quickForm.value.is_paid,
    requires_attachment: quickForm.value.requires_attachment,
    affects_attendance: quickForm.value.affects_attendance
  });

  showToast(`Leave category "${newRec.name}" created successfully.`);
  isQuickCreateOpen.value = false;
  resetQuickForm();
};

const handleDeleteType = (id: number) => {
  const idx = leaveTypes.value.findIndex(t => t.id === id);
  if (idx > -1) {
    const deleted = leaveTypes.value.splice(idx, 1)[0];
    showToast(`Leave type "${deleted.name}" removed.`);
  }
  activeActionMenuId.value = null;
};
</script>

<template>
  <div class="leave-types-page" @click="activeActionMenuId = null">
    <!-- Breadcrumb Standard (Rule 3: [Monitor] > Leave Type strictly) -->
    <div class="breadcrumb-bar">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Toast Notification -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- ─── Unified Data Table Card (AGENTS.md Rule 10) ─── -->
    <AppDataTable
      title="Leave Types"
      subtitle="Master catalog of statutory and enterprise leave categories governing paid compensation, documentation, and attendance impact."
      :total-records="filteredTypes.length"
      :columns="tableColumns"
      :data="filteredTypes"
      v-model:searchQuery="searchQuery"
      searchPlaceholder="Search leave categories by name, code, or description..."
    >
      <!-- Top-Right Actions Slot -->
      <template #actions>
        <button
          type="button"
          class="btn-primary-action"
          @click="isQuickCreateOpen = true"
        >
          <Plus :size="15" />
          <span>Add Leave Type</span>
        </button>
      </template>

      <!-- Data Table Body -->
      <template #default>
        <div class="table-responsive">
          <table class="erp-table">
            <thead>
              <tr>
                <th class="th-checkbox" width="40">
                  <input
                    type="checkbox"
                    :checked="isAllSelected"
                    @change="toggleSelectAll"
                    class="table-checkbox"
                    aria-label="Select all leave types"
                  />
                </th>
                <th v-for="col in tableColumns" :key="col.key" :style="{ width: col.width }">
                  {{ col.label }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in filteredTypes" :key="item.id" class="erp-row">
                <!-- Checkbox -->
                <td class="td-checkbox">
                  <input
                    type="checkbox"
                    :checked="selectedIds.includes(item.id)"
                    @change="toggleSelectRow(item.id)"
                    class="table-checkbox"
                    aria-label="Select row"
                  />
                </td>

                <!-- Name & Code (Rule 4: Zero standalone code, Rule 5: #404040 secondary) -->
                <td class="td-name-col">
                  <div class="name-column-wrap">
                    <span class="table-name-primary">{{ item.name }}</span>
                    <span class="table-code-subtext">{{ item.code }}</span>
                  </div>
                </td>

                <!-- Compensation Type (Rule 6: Plain text tertiary #737373) -->
                <td class="td-tertiary">
                  {{ item.is_paid ? 'Paid Rest Leave (100% Basic)' : 'Unpaid Absence' }}
                </td>

                <!-- Document Evidence (Rule 6: Plain text) -->
                <td class="td-tertiary">
                  {{ item.requires_attachment ? 'Medical Certificate / Note Required' : 'Self-Certified (No Attachment)' }}
                </td>

                <!-- Affects Attendance (Rule 6: Plain text) -->
                <td class="td-tertiary">
                  {{ item.affects_attendance ? 'Logs on_leave in AttendanceDay' : 'Independent of Daily Roster' }}
                </td>

                <!-- State Column (Rule 9: Status pill reserved for State) -->
                <td>
                  <span class="status-pill" :class="item.state === 'active' ? 'state-active' : 'state-inactive'">
                    {{ item.state === 'active' ? 'Active' : 'Inactive' }}
                  </span>
                </td>

                <!-- Row Action (⋮ 3-dots button) -->
                <td class="td-actions" @click.stop>
                  <div class="action-menu-wrapper">
                    <button
                      type="button"
                      class="btn-action-dots"
                      title="Actions"
                      @click="activeActionMenuId = activeActionMenuId === item.id ? null : item.id"
                    >
                      <MoreVertical :size="15" />
                    </button>

                    <Transition name="dropdown-fade">
                      <div v-if="activeActionMenuId === item.id" class="dropdown-action-menu">
                        <button 
                          type="button" 
                          class="dropdown-item" 
                          @click="item.state = item.state === 'active' ? 'inactive' : 'active'; activeActionMenuId = null; showToast(`Status updated to ${item.state}.`);"
                        >
                          <ShieldCheck :size="13" />
                          <span>{{ item.state === 'active' ? 'Deactivate Type' : 'Activate Type' }}</span>
                        </button>
                        <div class="dropdown-divider"></div>
                        <button 
                          type="button" 
                          class="dropdown-item text-danger" 
                          @click="handleDeleteType(item.id)"
                        >
                          <Trash2 :size="13" />
                          <span>Delete Type</span>
                        </button>
                      </div>
                    </Transition>
                  </div>
                </td>
              </tr>

              <!-- Empty State -->
              <tr v-if="filteredTypes.length === 0">
                <td colspan="7" class="empty-table-cell">
                  <div class="empty-state-wrap">
                    <AlertCircle :size="32" class="empty-icon" />
                    <p class="empty-title">No Leave Types Found</p>
                    <p class="empty-desc">Register standard leave categories (Annual, Sick, Maternity, etc.) in the catalog.</p>
                    <button class="btn-primary-action empty-btn" @click="isQuickCreateOpen = true">
                      <Plus :size="15" />
                      <span>Add Leave Type</span>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
    </AppDataTable>

    <!-- Floating Batch Action Bar (AGENTS.md Rule 11) -->
    <TableFloatingBar 
      :count="selectedIds.length" 
      @delete="handleBatchDelete" 
    />

    <!-- ─── QuickCreateModal (AGENTS.md Rule 4 for <= 5 Required Fields) ─── -->
    <QuickCreateModal
      v-model:show="isQuickCreateOpen"
      title="Add Leave Type"
      :showExpandButton="true"
      @save="handleQuickSave"
      @cancel="resetQuickForm"
      @expand="isQuickCreateOpen = false; router.push('/hr/leave-types/create');"
    >
      <div class="quick-form-stack">
        <!-- 1. Code & 2. Name -->
        <div class="form-row-2">
          <div class="form-group">
            <label class="form-label required-mark">Leave Type Code</label>
            <FormInput
              v-model="quickForm.code"
              placeholder=""
              @keyup.enter="handleQuickSave"
            />
          </div>

          <div class="form-group">
            <label class="form-label required-mark">Leave Type Name</label>
            <FormInput
              v-model="quickForm.name"
              placeholder=""
              @keyup.enter="handleQuickSave"
            />
          </div>
        </div>

        <!-- 3. Paid Leave Checkbox -->
        <div class="checkbox-wrapper">
          <FormCheckbox
            v-model="quickForm.is_paid"
            label="Paid Leave Compensation"
            description="When enabled, employee receives standard basic wage pay during authorized leave days."
          />
        </div>

        <!-- 4. Requires Attachment Checkbox -->
        <div class="checkbox-wrapper">
          <FormCheckbox
            v-model="quickForm.requires_attachment"
            label="Require Supporting Evidence"
            description="Employee must attach certified documentation (e.g., medical sick note, hospital certificate, summons) when submitting a request."
          />
        </div>

        <!-- 5. Affects Attendance Checkbox -->
        <div class="checkbox-wrapper">
          <FormCheckbox
            v-model="quickForm.affects_attendance"
            label="Record on_leave in Daily Attendance"
            description="Automatically stamps attendance rosters and biometric day logs with on_leave status to prevent unauthorized absence flags."
          />
        </div>
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.leave-types-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 20px 24px 80px;
  background-color: #f8fafc;
  min-height: 100vh;
}

.breadcrumb-bar {
  display: flex;
  align-items: center;
}

/* Primary Button in Table Toolbar (Rule 6: 8px-10px radius) */
.btn-primary-action {
  height: 38px;
  padding: 0 16px;
  background-color: #0B529C;
  border: none;
  color: #ffffff;
  font-size: 13px;
  font-weight: 500;
  border-radius: 8px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-primary-action:hover { 
  background-color: #083c72; 
}

/* ─── Table Cell Standards (AGENTS.md Rule 8 & 9) ─── */
.table-responsive {
  width: 100%;
  overflow-x: auto;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
}
.erp-table th {
  height: 34px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}
.erp-table td {
  height: 48px;
  padding: 8px 16px;
  font-size: 13px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.th-checkbox,
.td-checkbox {
  width: 40px;
  text-align: center;
  padding-left: 14px !important;
  padding-right: 8px !important;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  border-radius: 4px;
  border: 1px solid #cbd5e1;
  accent-color: #0B529C;
  cursor: pointer;
}

.name-column-wrap {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.table-name-primary {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}
.table-code-subtext {
  font-size: 11.5px;
  color: #737373;
}

.td-tertiary {
  color: #737373;
  font-size: 13px;
}

/* Status Pills */
.status-pill {
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
.td-actions {
  text-align: center;
  width: 48px;
}
.action-menu-wrapper {
  position: relative;
  display: inline-block;
}
.btn-action-dots {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: none;
  background-color: transparent;
  color: #737373;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background-color 0.12s ease;
}
.btn-action-dots:hover { 
  background-color: #f1f5f9; 
  color: #404040; 
}

.dropdown-action-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
  min-width: 160px;
  z-index: 50;
  padding: 4px;
}

.dropdown-item {
  width: 100%;
  height: 32px;
  padding: 0 10px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  border: none;
  border-radius: 6px;
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  text-align: left;
}
.dropdown-item:hover { 
  background-color: #f8fafc; 
}
.dropdown-item.text-danger {
  color: #dc2626;
}
.dropdown-item.text-danger:hover {
  background-color: #fef2f2;
}

.dropdown-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 4px 0;
}

/* Quick Create Modal Form */
.quick-form-stack {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.form-row-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}
.form-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}
.required-mark::after { content: ' *'; color: #dc2626; }
.checkbox-wrapper {
  padding-top: 2px;
}

/* Toast */
.toast-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #ecfdf5;
  color: #065f46;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 10px 14px;
  font-size: 13px;
  font-weight: 500;
  width: fit-content;
}
.toast-fade-enter-active, .toast-fade-leave-active { transition: opacity 0.25s, transform 0.25s; }
.toast-fade-enter-from, .toast-fade-leave-to { opacity: 0; transform: translateY(-8px); }
.dropdown-fade-enter-active, .dropdown-fade-leave-active { transition: opacity 0.15s, transform 0.15s; }
.dropdown-fade-enter-from, .dropdown-fade-leave-to { opacity: 0; transform: translateY(-4px); }

/* Empty State */
.empty-table-cell {
  padding: 48px 16px !important;
  text-align: center;
}
.empty-state-wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  max-width: 420px;
  margin: 0 auto;
}
.empty-icon {
  color: #94a3b8;
  margin-bottom: 6px;
}
.empty-title {
  font-size: 14.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}
.empty-desc {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}
.empty-btn {
  margin-top: 10px;
}
</style>
