<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  Users, UserCheck, Plus, Calendar,
  ChevronDown, CheckCircle2, Expand, X,
  ArrowDown, ArrowUp, Copy
} from 'lucide-vue-next';;
import IconColumnSolid from '../../components/IconColumnSolid.vue';
import BaseTabs, { type TabItem } from '../../components/BaseTabs.vue';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import AppButton from '../../components/AppButton.vue';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumb Navigation Standard (Rule 3 & Rule 4) ───
const breadcrumbItems: BreadcrumbItem[] = [
  { label: 'Committees', to: '/hr/committees' },
  { label: 'Create Committee' }
];

// ─── Save State ───
const isSaved = ref(false);
const quickActionToast = ref<string | null>(null);

const showToast = (message: string) => {
  quickActionToast.value = message;
  setTimeout(() => { quickActionToast.value = null; }, 3500);
};

// ─── Tabs (BaseTabs Capsule Standard - Rule 1 & Rule 4) ───
type TabId = 'details' | 'members';
const activeTab = ref<TabId>('details');

const tabs = computed<TabItem[]>(() => [
  { id: 'details', label: 'Committee Details', icon: Users },
  { id: 'members', label: `Appointed Members (${members.value.length})`, icon: UserCheck }
]);

// ─── Options & Catalogs (HR Schema Designer 1.sql lines 462–493) ───
export type CommitteeRole = 'chair' | 'member' | 'secretary' | 'treasurer' | 'observer';

const entityOptions = [
  { value: 1, label: 'QMT Business Group (HQ)' },
  { value: 3, label: 'Haleta Addis Ababa HQ' },
  { value: 7, label: 'Haleta Grand Hotel & Suites' },
  { value: 9, label: 'Haleta East Regional Office' }
];

const committeeRoleOptions = [
  { value: 'chair', label: 'Chair / Chairperson' },
  { value: 'member', label: 'Committee Member' },
  { value: 'secretary', label: 'Committee Secretary' },
  { value: 'treasurer', label: 'Treasurer' },
  { value: 'observer', label: 'Observer' }
];

const availableEmployees = [
  { id: 7, code: 'EMP-007', name: 'Abebe Kebede', position: 'Head of Legal & Governance' },
  { id: 14, code: 'EMP-014', name: 'Sara Tadesse', position: 'Senior HR Specialist' },
  { id: 22, code: 'EMP-022', name: 'Dawit Alemu', position: 'Internal Audit Lead' },
  { id: 31, code: 'EMP-031', name: 'Bethlehem Haile', position: 'Senior Finance Officer' },
  { id: 44, code: 'EMP-044', name: 'Yonas Bekele', position: 'Operations Supervisor' },
  { id: 56, code: 'EMP-056', name: 'Marta Getachew', position: 'EHS & Safety Officer' },
  { id: 62, code: 'EMP-062', name: 'Tewodros Kassahun', position: 'Inventory Controller' }
];

const employeeOptions = computed(() =>
  availableEmployees.map((emp) => ({
    value: emp.id,
    label: `${emp.name} (${emp.code}) — ${emp.position}`
  }))
);

// ─── Form State: Committee (Header [DIST]) ───
const form = ref({
  name: '',
  code: '',
  entity_id: 3,
  start_date: new Date().toISOString().split('T')[0],
  end_date: '',
  description: ''
});

// ─── Line Items: CommitteeMember [LINE] (Rule 11: Dynamic Sub-Table Standard) ───
export interface CommitteeMemberDraft {
  id: number;
  employee_id: number;
  role: CommitteeRole;
  start_date: string;
  end_date: string;
}

const members = ref<CommitteeMemberDraft[]>([
  {
    id: 1,
    employee_id: 7,
    role: 'chair',
    start_date: '2026-01-10',
    end_date: ''
  },
  {
    id: 2,
    employee_id: 14,
    role: 'member',
    start_date: '2026-01-10',
    end_date: ''
  }
]);

const selectedMemberIds = ref<number[]>([]);

// ─── Inline Child Row Operations (Rule 11) ───
const handleAddMemberRow = () => {
  const existingEmpIds = members.value.map(m => m.employee_id);
  const nextEmp = availableEmployees.find(e => !existingEmpIds.includes(e.id)) || availableEmployees[0];
  members.value.push({
    id: Date.now(),
    employee_id: nextEmp.id,
    role: members.value.length === 0 ? 'chair' : 'member',
    start_date: form.value.start_date || new Date().toISOString().split('T')[0],
    end_date: form.value.end_date || '',
    notes: ''
  });
  showToast('New committee member row added. Select employee and role.');
};

const handleRemoveMemberRow = (id: number) => {
  members.value = members.value.filter(m => m.id !== id);
  selectedMemberIds.value = selectedMemberIds.value.filter(sid => sid !== id);
  showToast('Member removed from draft roster.');
};

const handleBatchDeleteMembers = () => {
  members.value = members.value.filter(m => !selectedMemberIds.value.includes(m.id));
  selectedMemberIds.value = [];
  showToast('Selected members removed from draft roster.');
};

const toggleSelectAllMembers = () => {
  if (selectedMemberIds.value.length === members.value.length) {
    selectedMemberIds.value = [];
  } else {
    selectedMemberIds.value = members.value.map(m => m.id);
  }
};

const toggleSelectMember = (id: number) => {
  const idx = selectedMemberIds.value.indexOf(id);
  if (idx > -1) selectedMemberIds.value.splice(idx, 1);
  else selectedMemberIds.value.push(id);
};

// ─── Modal State: Expand Row Modal (Haleta ERP Standard: Employee & Academic Qualification) ───
const showRowModal = ref(false);
const activeRowData = ref<CommitteeMemberDraft | null>(null);
const activeRowIndex = ref<number>(-1);

const openRowModal = (row: CommitteeMemberDraft, idx: number) => {
  activeRowData.value = row;
  activeRowIndex.value = idx;
  showRowModal.value = true;
};

const closeRowModal = () => {
  showRowModal.value = false;
  activeRowData.value = null;
  activeRowIndex.value = -1;
};

const isFirstRow = computed(() => activeRowIndex.value <= 0);
const isLastRow = computed(() => activeRowIndex.value >= members.value.length - 1);

const createBlankMemberRow = (): CommitteeMemberDraft => {
  const existingEmpIds = members.value.map(m => m.employee_id);
  const nextEmp = availableEmployees.find(e => !existingEmpIds.includes(e.id)) || availableEmployees[0];
  return {
    id: Date.now() + Math.floor(Math.random() * 1000),
    employee_id: nextEmp.id,
    role: 'member',
    start_date: form.value.start_date || new Date().toISOString().split('T')[0],
    end_date: form.value.end_date || ''
  };
};

const deleteModalRow = () => {
  if (activeRowIndex.value < 0 || activeRowIndex.value >= members.value.length) return;
  const removed = members.value[activeRowIndex.value];
  members.value.splice(activeRowIndex.value, 1);
  selectedMemberIds.value = selectedMemberIds.value.filter(id => id !== removed.id);
  showToast('Member row deleted.');
  if (members.value.length === 0) {
    closeRowModal();
  } else {
    if (activeRowIndex.value >= members.value.length) {
      activeRowIndex.value = members.value.length - 1;
    }
    activeRowData.value = members.value[activeRowIndex.value];
  }
};

const moveRowDown = () => {
  if (activeRowIndex.value >= members.value.length - 1) return;
  const curr = members.value[activeRowIndex.value];
  const next = members.value[activeRowIndex.value + 1];
  members.value[activeRowIndex.value] = next;
  members.value[activeRowIndex.value + 1] = curr;
  activeRowIndex.value++;
  activeRowData.value = members.value[activeRowIndex.value];
};

const moveRowUp = () => {
  if (activeRowIndex.value <= 0) return;
  const curr = members.value[activeRowIndex.value];
  const prev = members.value[activeRowIndex.value - 1];
  members.value[activeRowIndex.value] = prev;
  members.value[activeRowIndex.value - 1] = curr;
  activeRowIndex.value--;
  activeRowData.value = members.value[activeRowIndex.value];
};

const duplicateModalRow = () => {
  if (!activeRowData.value) return;
  const clone = JSON.parse(JSON.stringify(activeRowData.value));
  clone.id = Date.now() + Math.floor(Math.random() * 1000);
  members.value.splice(activeRowIndex.value + 1, 0, clone);
  activeRowIndex.value++;
  activeRowData.value = members.value[activeRowIndex.value];
  showToast('Member row duplicated.');
};

const insertRowAbove = () => {
  const newRow = createBlankMemberRow();
  members.value.splice(activeRowIndex.value, 0, newRow);
  activeRowData.value = members.value[activeRowIndex.value];
  showToast('New member row inserted above.');
};

const insertRowBelow = () => {
  const newRow = createBlankMemberRow();
  members.value.splice(activeRowIndex.value + 1, 0, newRow);
  activeRowIndex.value++;
  activeRowData.value = members.value[activeRowIndex.value];
  showToast('New member row inserted below.');
};

// ─── Query Parameter Hydration (Preserve typed fields from Quick Modal) ───
onMounted(() => {
  if (route.query.name) form.value.name = String(route.query.name);
  if (route.query.code) form.value.code = String(route.query.code);
  if (route.query.entity_id) form.value.entity_id = Number(route.query.entity_id);
  if (route.query.start_date) form.value.start_date = String(route.query.start_date);
  if (route.query.end_date) form.value.end_date = String(route.query.end_date);
  if (route.query.description) form.value.description = String(route.query.description);
});

// ─── Form Actions ───
const handleClearForm = () => {
  form.value = {
    name: '',
    code: '',
    entity_id: 3,
    start_date: new Date().toISOString().split('T')[0],
    end_date: '',
    description: ''
  };
  members.value = [];
  selectedMemberIds.value = [];
  isSaved.value = false;
  showToast('Form cleared.');
};

const handleSaveCommittee = () => {
  if (!form.value.name.trim()) {
    showToast('Please enter a Committee Name.');
    activeTab.value = 'details';
    return;
  }
  if (!form.value.start_date) {
    showToast('Please specify the Constituted Date.');
    activeTab.value = 'details';
    return;
  }

  isSaved.value = true;
  showToast(`Committee "${form.value.name}" and ${members.value.length} appointed members saved successfully.`);
  setTimeout(() => {
    router.push('/hr/committees');
  }, 1200);
};
</script>

<template>
  <div class="committee-create-page">
    <!-- ═══ TOP BAR: Breadcrumb + Save State + Action Buttons (Rule 3 & Rule 4) ═══ -->
    <div class="top-nav-bar">
      <!-- Breadcrumbs + Save Status Pill Badge (Rule 3, 4 & 5) -->
      <div class="top-nav-left">
        <AppBreadcrumb :items="breadcrumbItems">
          <template #badge>
            <SaveStateBadge :isSaved="isSaved" />
          </template>
        </AppBreadcrumb>
      </div>

      <!-- Top Right Action Buttons (Rule 4: Clear Form + Save) -->
      <div class="top-actions-cluster">
        <AppButton 
          variant="outline" 
          size="sm" 
          @click="handleClearForm"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <AppButton 
          variant="primary" 
          size="sm" 
          @click="handleSaveCommittee"
        >
          Save
        </AppButton>
      </div>
    </div>

    <!-- Toast Notification Banner -->
    <div v-if="quickActionToast" class="toast-banner">
      <CheckCircle2 :size="15" class="text-emerald-600" />
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- ═══ TOP TABS: <BaseTabs /> (Rule 1: Primary Tab Standard) ═══ -->
    <div class="tabs-header-wrap">
      <BaseTabs 
        v-model="activeTab" 
        :tabs="tabs" 
      />
    </div>

    <!-- ══════════════════════════════════════════════════════════ -->
    <!-- TAB 1: COMMITTEE DETAILS (Master Record [DIST])            -->
    <!-- ══════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'details'" class="form-content-section">
      <div class="master-card">
        <div class="card-section-header">
          <h2 class="card-section-title">Committee Information</h2>
          <p class="card-section-desc">
            Define panel constitution, terms of reference, owning enterprise branch, and duration.
          </p>
        </div>

        <div class="form-grid-3">
          <!-- Committee Name (Required) -->
          <div class="field-item">
            <FormInput 
              label="Committee Name" 
              v-model="form.name" 
              required 
            />
          </div>

          <!-- Committee Code (Auto or Custom) -->
          <div class="field-item">
            <FormInput 
              label="Committee Code" 
              v-model="form.code" 
              hint="Leave blank to auto-generate (e.g. CMT-DISC, CMT-GRV)."
            />
          </div>

          <!-- Owning Entity (Required) -->
          <div class="field-item">
            <FormSelect 
              label="Owning Entity" 
              v-model="form.entity_id" 
              :options="entityOptions" 
              placeholder="Select Owning Entity"
              required 
            />
          </div>

          <!-- Constituted Date (GC Calendar Badge) -->
          <div class="field-item">
            <div class="gc-date-field">
              <label class="gc-field-label">Constituted Date <span class="required-star">*</span></label>
              <div class="gc-date-input-wrap">
                <Calendar :size="14" class="gc-cal-icon" />
                <input
                  type="date"
                  v-model="form.start_date"
                  class="gc-date-input"
                  required
                />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>
          </div>

          <!-- Dissolution Date (Optional for standing panels) -->
          <div class="field-item">
            <div class="gc-date-field">
              <label class="gc-field-label">Dissolution Date (Optional)</label>
              <div class="gc-date-input-wrap">
                <Calendar :size="14" class="gc-cal-icon" />
                <input
                  type="date"
                  v-model="form.end_date"
                  class="gc-date-input"
                />
                <span class="gc-pill-tag">GC</span>
              </div>
              <p class="gc-hint-text">Leave blank for standing / permanent panel.</p>
            </div>
          </div>

          <!-- Panel Classification / Duration helper badge -->
          <div class="field-item">
            <label class="gc-field-label">Panel Classification</label>
            <div class="classification-readout-pill">
              <span class="classification-tag" :class="form.end_date ? 'tag-adhoc' : 'tag-standing'">
                {{ form.end_date ? 'Ad-Hoc Panel (Term Limited)' : 'Standing Committee (Permanent)' }}
              </span>
            </div>
          </div>

          <!-- Mandate & Terms of Reference -->
          <div class="field-item field-item-span3">
            <FormTextarea 
              label="Mandate & Terms of Reference" 
              v-model="form.description" 
              :rows="4" 
            />
          </div>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════ -->
    <!-- TAB 2: COMMITTEE MEMBERS (Rule 11: Dynamic Sub-Table)      -->
    <!-- ══════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'members'" class="form-content-section">
      <div class="master-card">
        <div class="card-section-title">Appointed Members</div>
        <p class="card-plain-desc">
          Panel members and statutory governance assignments for this committee.
        </p>

        <!-- Dynamic Child Sub-Table (Canonical Haleta ERP Standard: Rule 11) -->
        <div class="child-table-wrapper">
          <table class="child-table">
            <thead>
              <tr class="child-table-header">
                <th class="child-th child-th-check">
                  <input 
                    type="checkbox" 
                    :checked="members.length > 0 && selectedMemberIds.length === members.length"
                    @change="toggleSelectAllMembers"
                    class="table-checkbox"
                    aria-label="Select all members"
                  />
                </th>
                <th class="child-th child-th-no">No.</th>
                <th class="child-th" style="min-width: 260px;">Appointed Staff Member</th>
                <th class="child-th" style="min-width: 190px;">Committee Role</th>
                <th class="child-th" style="min-width: 145px;">Appointment Date</th>
                <th class="child-th" style="min-width: 145px;">Dissolution / End Date</th>
                <th class="child-th child-th-col-icon">
                  <IconColumnSolid :size="13" class="col-icon-solid" />
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="members.length === 0">
                <td colspan="7" class="child-td-empty">No Row</td>
              </tr>
              <tr 
                v-for="(row, idx) in members" 
                :key="row.id"
                class="child-tr"
                :class="{ 'child-row-selected': selectedMemberIds.includes(row.id) }"
              >
                <!-- Row Checkbox -->
                <td class="child-td child-td-check">
                  <input 
                    type="checkbox" 
                    :checked="selectedMemberIds.includes(row.id)" 
                    @change="toggleSelectMember(row.id)" 
                    class="table-checkbox" 
                  />
                </td>

                <!-- Sequential No. -->
                <td class="child-td child-td-no">{{ idx + 1 }}</td>

                <!-- Employee Inline Select -->
                <td class="child-td">
                  <FormSelect
                    v-model="row.employee_id"
                    :options="employeeOptions"
                    variant="cell"
                    placeholder="Select Staff"
                  />
                </td>

                <!-- Committee Role Inline Select -->
                <td class="child-td">
                  <FormSelect
                    v-model="row.role"
                    :options="committeeRoleOptions"
                    variant="cell"
                    placeholder="Select Role"
                  />
                </td>

                <!-- Appointment Date Inline Input -->
                <td class="child-td">
                  <input 
                    type="date" 
                    v-model="row.start_date" 
                    class="child-inline-input font-mono"
                    required
                  />
                </td>

                <!-- Dissolution / End Date Inline Input -->
                <td class="child-td">
                  <input 
                    type="date" 
                    v-model="row.end_date" 
                    class="child-inline-input font-mono"
                  />
                </td>

                <!-- Expand Row Action Column (Rule 11.2) -->
                <td class="child-td child-td-col-icon">
                  <button 
                    type="button" 
                    class="btn-row-expand" 
                    @click="openRowModal(row, idx)" 
                    title="Expand Row Details"
                  >
                    <Expand :size="14" />
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Add Row Button Directly Below Table (Rule 11.2 Standard) -->
        <button 
          type="button" 
          class="btn-add-row" 
          @click="handleAddMemberRow"
        >
          <Plus :size="13" />
          <span>Add Row</span>
        </button>
      </div>
    </div>

    <!-- Floating Batch Action Bar (Rule 11.3) -->
    <TableFloatingBar 
      :show="selectedMemberIds.length > 0"
      :selected-count="selectedMemberIds.length"
      :total-count="members.length"
      @delete="handleBatchDeleteMembers" 
      @close="selectedMemberIds = []" 
    />

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- EXPAND ROW MODAL (Matching Employee Academic Qualification)   -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <div v-if="showRowModal && activeRowData" class="row-modal-overlay" @click="closeRowModal">
        <div class="row-modal-container" @click.stop>
          <!-- Header -->
          <div class="row-modal-header">
            <h3 class="row-modal-title">Committee Member (Row {{ activeRowIndex + 1 }})</h3>
            <button type="button" class="btn-modal-close" @click="closeRowModal" title="Close">
              <X :size="16" />
            </button>
          </div>

          <!-- Body -->
          <div class="row-modal-body">
            <div class="modal-grid-2">
              <!-- Employee (Col 1) -->
              <div class="modal-form-group">
                <FormSelect
                  v-model="activeRowData.employee_id"
                  label="Appointed Staff Member"
                  required
                  :options="employeeOptions"
                  placeholder="Select Staff"
                />
              </div>

              <!-- Role (Col 2) -->
              <div class="modal-form-group">
                <FormSelect
                  v-model="activeRowData.role"
                  label="Governance Role"
                  required
                  :options="committeeRoleOptions"
                  placeholder="Select Role"
                />
              </div>

              <!-- Appointment Date (Col 1) -->
              <div class="modal-form-group">
                <label class="modal-form-label">Appointment Date <span class="required-star">*</span></label>
                <div class="gc-date-input-wrap">
                  <Calendar :size="14" class="gc-cal-icon" />
                  <input 
                    type="date" 
                    v-model="activeRowData.start_date" 
                    class="gc-date-input font-mono" 
                    required 
                  />
                  <span class="gc-pill-tag">GC</span>
                </div>
              </div>

              <!-- Dissolution Date (Col 2) -->
              <div class="modal-form-group">
                <label class="modal-form-label">Dissolution Date</label>
                <div class="gc-date-input-wrap">
                  <Calendar :size="14" class="gc-cal-icon" />
                  <input 
                    type="date" 
                    v-model="activeRowData.end_date" 
                    class="gc-date-input font-mono" 
                  />
                  <span class="gc-pill-tag">GC</span>
                </div>
                <p class="modal-form-hint">Leave blank for standing committee tenure.</p>
              </div>
            </div>
          </div>

          <!-- Footer (The Canonical Haleta ERP Row Controls Footer) -->
          <div class="row-modal-footer">
            <button type="button" class="btn-modal-delete" @click="deleteModalRow">
              Delete
            </button>
            <div class="row-modal-actions-right">
              <button 
                type="button" 
                class="btn-modal-ctrl-icon" 
                :disabled="isLastRow" 
                @click="moveRowDown" 
                title="Move Down"
              >
                <ArrowDown :size="15" />
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-icon" 
                :disabled="isFirstRow" 
                @click="moveRowUp" 
                title="Move Up"
              >
                <ArrowUp :size="15" />
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-action" 
                @click="duplicateModalRow"
              >
                <Copy :size="13" />
                <span>Duplicate Row</span>
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-action" 
                @click="insertRowAbove"
              >
                <Plus :size="13" />
                <span>Insert Above</span>
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-action" 
                @click="insertRowBelow"
              >
                <Plus :size="13" />
                <span>Insert Below</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.committee-create-page {
  padding: 0;
  background-color: #f8fafc;
  min-height: calc(100vh - 60px);
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
}

/* ─── Top Bar Navigation (Rule 29: Zero-Background Standard) ─── */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  background: transparent;
  border: none;
  border-radius: 0;
  padding: 0;
  box-shadow: none;
  margin-bottom: 20px;
}

.top-nav-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.top-nav-left :deep(.breadcrumb-nav) {
  margin-bottom: 0;
}

.top-actions-cluster {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-clear-form {
  display: flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #ffffff;
  color: #404040;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-clear-form:hover {
  background-color: #f8fafc;
  border-color: #94a3b8;
}

.btn-save-primary {
  height: 38px;
  padding: 0 22px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-save-primary:hover {
  background-color: #094380;
}

/* Toast */
.toast-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  color: #065f46;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
}

/* ─── Tabs Header ─── */
.tabs-header-wrap {
  display: flex;
  align-items: center;
}

/* ─── Content Master Card ─── */
.master-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.card-section-header {
  display: flex;
  flex-direction: column;
  gap: 4px;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 14px;
}

.card-section-header-split {
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 14px;
}

.card-section-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.card-section-desc {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.field-item {
  display: flex;
  flex-direction: column;
}

.field-item-span3 {
  grid-column: span 3;
}

/* GC Date Picker Field */
.gc-date-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.gc-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.required-star {
  color: #ef4444;
}

.gc-date-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.gc-cal-icon {
  position: absolute;
  left: 10px;
  color: #94a3b8;
  pointer-events: none;
}

.gc-date-input {
  width: 100%;
  height: 38px;
  padding: 0 42px 0 32px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  color: #404040;
  outline: none;
}

.gc-date-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.gc-pill-tag {
  position: absolute;
  right: 8px;
  background-color: #f1f5f9;
  color: #64748b;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 4px;
  pointer-events: none;
}

.gc-hint-text {
  font-size: 11.5px;
  color: #737373;
  margin: 4px 0 0;
}

.classification-readout-pill {
  display: flex;
  align-items: center;
  height: 38px;
}

.classification-tag {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
}

.tag-standing {
  background-color: #eff6ff;
  color: #1d4ed8;
}

.tag-adhoc {
  background-color: #fef3c7;
  color: #b45309;
}

/* ─── Dynamic Child Sub-Table Standards (Rule 11) ─── */
.child-table-wrapper {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  overflow: hidden;
  background: #ffffff;
  margin-top: 12px;
}

.child-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.child-table-header {
  background-color: #f8fafc;
  border-bottom: 1px solid #e5e7eb;
}

.child-th {
  padding: 8px 12px;
  font-size: 12px;
  font-weight: 500;
  color: #404040;
  border-right: 1px solid #e5e7eb;
  white-space: nowrap;
  user-select: none;
}
.child-th:last-child {
  border-right: none;
}

.child-th-check {
  width: 44px;
  text-align: center;
}

.child-th-no {
  width: 48px;
  text-align: center;
}

.child-th-col-icon {
  width: 68px;
  text-align: center;
}

.col-icon-svg {
  color: #94a3b8;
  margin: 0 auto;
}

.child-td-empty {
  padding: 34px 16px;
  text-align: center;
  font-size: 13px;
  font-weight: 500;
  color: #737373;
  background-color: #ffffff;
}

.child-tr {
  border-bottom: 1px solid #f1f5f9;
  transition: background-color 0.1s ease;
}
.child-tr:last-child {
  border-bottom: none;
}
.child-tr:hover {
  background-color: #fbfcfd;
}
.child-row-selected {
  background-color: #eff6ff !important;
}

.child-td {
  padding: 4px 8px;
  font-size: 12.5px;
  color: #404040;
  border-right: 1px solid #e5e7eb;
  vertical-align: middle;
}
.child-td:last-child {
  border-right: none;
}

.child-td-check {
  width: 44px;
  text-align: center;
}

.child-td-no {
  width: 48px;
  text-align: center;
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
}

.child-td-col-icon {
  width: 68px;
  text-align: center;
}

.table-checkbox {
  appearance: none;
  -webkit-appearance: none;
  width: 16px;
  height: 16px;
  min-width: 16px;
  min-height: 16px;
  border-radius: 4px;
  border: 1.5px solid #cbd5e1;
  background-color: #ffffff;
  cursor: pointer;
  display: inline-grid;
  place-content: center;
  position: relative;
  vertical-align: middle;
  outline: none;
  margin: 0 auto;
  transition: all 0.15s ease;
}

.table-checkbox:hover:not(:checked) {
  border-color: #94a3b8;
  background-color: #f8fafc;
}

.table-checkbox:checked {
  background-color: #0B529C;
  border-color: #0B529C;
  background-image: url("data:image/svg+xml,%3csvg viewBox='0 0 16 16' fill='none' stroke='white' stroke-width='2.6' stroke-linecap='round' stroke-linejoin='round' xmlns='http://www.w3.org/2000/svg'%3e%3cpolyline points='3.5 8.5 6.5 11.5 12.5 5.5'/%3e%3c/svg%3e");
  background-position: center;
  background-repeat: no-repeat;
  background-size: 75% 75%;
}

.child-inline-select {
  width: 100%;
  height: 30px;
  border: 1px solid transparent;
  border-radius: 4px;
  padding: 0 6px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  outline: none;
  cursor: pointer;
  transition: all 0.15s ease;
}
.child-inline-select:hover {
  background-color: #f8fafc;
  border-color: #e2e8f0;
}
.child-inline-select:focus {
  background-color: #ffffff;
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.08);
}

.child-inline-input {
  width: 100%;
  height: 30px;
  border: 1px solid transparent;
  border-radius: 4px;
  padding: 0 8px;
  font-size: 12.5px;
  color: #404040;
  background: transparent;
  outline: none;
  transition: all 0.15s ease;
}
.child-inline-input:hover {
  background-color: #f8fafc;
  border-color: #e2e8f0;
}
.child-inline-input:focus {
  background-color: #ffffff;
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.08);
}

.row-actions-group {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

.btn-row-expand {
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  padding: 4px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: all 0.15s ease;
}
.btn-row-expand:hover {
  color: #0B529C;
  background-color: #f1f5f9;
}

.btn-row-remove {
  border: none;
  background: transparent;
  color: #94a3b8;
  cursor: pointer;
  padding: 4px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: all 0.15s ease;
}
.btn-row-remove:hover {
  color: #ef4444;
  background-color: #fee2e2;
}

.btn-add-row {
  height: 34px;
  padding: 0 16px;
  display: inline-flex;
  align-items: center;
  gap: 7px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  margin-top: 12px;
  transition: all 0.15s ease;
}
.btn-add-row:hover {
  background-color: #f8fafc;
  border-color: #0B529C;
  color: #0B529C;
}

/* ─── Expand Row Modal System (Matching EmployeeCreate.vue & Academic Qualification Standard) ─── */
.row-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(2px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
}

.row-modal-container {
  background-color: #ffffff;
  border-radius: 16px;
  width: 100%;
  max-width: 720px;
  max-height: 88vh;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: modalFadeIn 0.15s ease-out;
}

@keyframes modalFadeIn {
  from {
    opacity: 0;
    transform: scale(0.97);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.row-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px 16px;
  background-color: #ffffff;
}

.row-modal-title {
  margin: 0;
  font-size: 16.5px;
  font-weight: 600;
  color: #404040;
}

.btn-modal-close {
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  padding: 6px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}
.btn-modal-close:hover {
  color: #0f172a;
  background-color: #f1f5f9;
}

.row-modal-body {
  padding: 8px 24px 24px;
  overflow-y: auto;
  flex: 1;
}

.modal-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.modal-form-group {
  display: flex;
  flex-direction: column;
}

.modal-form-group.col-span-2 {
  grid-column: span 2 / span 2;
}

.modal-form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}

.modal-form-hint {
  font-size: 11.5px;
  color: #737373;
  line-height: 1.45;
  margin-top: 4px;
}

.modal-select-wrap {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}

.modal-select-wrap .modal-form-select {
  width: 100%;
  appearance: none;
  -webkit-appearance: none;
  padding-right: 32px;
}

.modal-select-chevron {
  position: absolute;
  right: 12px;
  color: #737373;
  pointer-events: none;
}

.modal-form-input {
  height: 38px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  transition: all 0.15s ease;
}
.modal-form-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.modal-form-select {
  height: 38px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  cursor: pointer;
  transition: all 0.15s ease;
}
.modal-form-select:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.modal-form-textarea {
  padding: 8px 12px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  outline: none;
  resize: vertical;
  min-height: 72px;
  font-family: inherit;
  transition: all 0.15s ease;
}
.modal-form-textarea:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.row-modal-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 24px;
  background-color: #f8fafc;
  border-top: 1px solid #f1f5f9;
}

.btn-modal-delete {
  background-color: #ef4444;
  color: #ffffff;
  border: none;
  border-radius: 8px;
  padding: 8px 18px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-modal-delete:hover {
  background-color: #dc2626;
}

.row-modal-actions-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-modal-ctrl-icon {
  width: 34px;
  height: 34px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-modal-ctrl-icon:hover:not(:disabled) {
  background-color: #f1f5f9;
  color: #0f172a;
}
.btn-modal-ctrl-icon:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.btn-modal-ctrl-action {
  height: 34px;
  padding: 0 12px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-modal-ctrl-action:hover {
  background-color: #f1f5f9;
  color: #0f172a;
  border-color: #cbd5e1;
}
</style>
