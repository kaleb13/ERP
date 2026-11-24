<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Clock, Plus, Filter, MoreVertical,
  Edit2, Trash2, Copy, CheckCircle2,
  Moon, LayoutGrid, List
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import BaseTabs from '../../components/BaseTabs.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import { useToast } from '../../composables/useToast';

const router = useRouter();

// ─── Lookups & Types (HR_Schema_final-v4.sql lines 1241 & 1334–1363) ───
export type RowState = 'active' | 'inactive';
export type ShiftCategory = 'fixed' | 'rotating' | 'split' | 'night' | 'flexible';

export interface WorkShiftRecord {
  id: number;
  uuid: string;
  code: string;
  name: { en: string; am?: string };
  description?: string;
  entity_id: number | null;
  entity_name: string;
  category: ShiftCategory;
  category_label: string;
  start_time: string; // "08:30"
  end_time: string;   // "17:30"
  is_overnight: boolean;
  break_minutes: number;
  grace_in_minutes: number;
  grace_out_minutes: number;
  night_hours_from?: string | null;
  night_hours_to?: string | null;
  state: RowState;
}

// ─── Breadcrumbs (Rule: Exact Page Name from Sidebar Only, Zero Section Titles) ───
const breadcrumbItems = [
  { label: 'Work Shifts' }
];

// ─── State Management ───
const activeTab = ref('all');
const viewMode = ref<'table' | 'cards'>('table');
const searchQuery = ref('');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const showQuickCreate = ref(false);
const { toast } = useToast();

// ─── Table Columns (Strict Single-Information & Name-First Hierarchy) ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Shift Name', visible: true, sortable: true },
  { key: 'category', label: 'Category', visible: true, sortable: true },
  { key: 'window', label: 'Working Window', visible: true, sortable: false },
  { key: 'duration', label: 'Net Work Hours', visible: true, sortable: true },
  { key: 'grace', label: 'Grace Tolerances', visible: true, sortable: false },
  { key: 'night_work', label: 'Night Window', visible: true, sortable: false },
  { key: 'entity', label: 'Owning Entity', visible: false, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Mock Data Aligned with HR_Schema_final-v4.sql lines 1356–1362 ───
const shifts = ref<WorkShiftRecord[]>([
  {
    id: 1,
    uuid: 'sh-uuid-001',
    code: 'SH-OFF',
    name: { en: 'Office Day', am: 'መደበኛ የቢሮ ፈረቃ' },
    description: 'Standard 8-hour administrative day shift with 1 hour lunch break.',
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    category: 'fixed',
    category_label: 'Fixed',
    start_time: '08:30',
    end_time: '17:30',
    is_overnight: false,
    break_minutes: 60,
    grace_in_minutes: 15,
    grace_out_minutes: 10,
    night_hours_from: null,
    night_hours_to: null,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'sh-uuid-002',
    code: 'SH-MORN',
    name: { en: 'Retail Morning', am: 'የጠዋት የሽያጭ ፈረቃ' },
    description: 'Early customer service and store opening shift.',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    category: 'rotating',
    category_label: 'Rotating',
    start_time: '07:00',
    end_time: '15:00',
    is_overnight: false,
    break_minutes: 30,
    grace_in_minutes: 10,
    grace_out_minutes: 10,
    night_hours_from: null,
    night_hours_to: null,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'sh-uuid-003',
    code: 'SH-EVE',
    name: { en: 'Retail Evening', am: 'የምሽት የሽያጭ ፈረቃ' },
    description: 'Afternoon to night retail rotation with handover.',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    category: 'rotating',
    category_label: 'Rotating',
    start_time: '14:30',
    end_time: '22:30',
    is_overnight: false,
    break_minutes: 30,
    grace_in_minutes: 10,
    grace_out_minutes: 10,
    night_hours_from: '22:00',
    night_hours_to: '22:30',
    state: 'active'
  },
  {
    id: 4,
    uuid: 'sh-uuid-004',
    code: 'SH-NIGHT',
    name: { en: 'Night Guard & Facilities', am: 'የሌሊት ጥበቃ እና ደህንነት' },
    description: 'Full overnight security and plant monitoring shift.',
    entity_id: 9,
    entity_name: 'Hawassa Industrial Plant',
    category: 'night',
    category_label: 'Night',
    start_time: '22:00',
    end_time: '06:00',
    is_overnight: true,
    break_minutes: 45,
    grace_in_minutes: 15,
    grace_out_minutes: 15,
    night_hours_from: '22:00',
    night_hours_to: '06:00',
    state: 'active'
  },
  {
    id: 5,
    uuid: 'sh-uuid-005',
    code: 'SH-SPLIT',
    name: { en: 'Piazza Shop Split', am: 'የተከፈለ የስራ ሰዓት ፈረቃ' },
    description: 'Split schedule for peak morning and late evening rush hours.',
    entity_id: 12,
    entity_name: 'Piazza Boutique',
    category: 'split',
    category_label: 'Split',
    start_time: '09:00',
    end_time: '20:00',
    is_overnight: false,
    break_minutes: 180,
    grace_in_minutes: 10,
    grace_out_minutes: 10,
    night_hours_from: null,
    night_hours_to: null,
    state: 'active'
  }
]);

// ─── Filter Tabs ───
const categoryTabs = computed(() => [
  { id: 'all', label: 'All Shifts', count: shifts.value.length },
  { id: 'fixed', label: 'Fixed', count: shifts.value.filter(s => s.category === 'fixed').length },
  { id: 'rotating', label: 'Rotating', count: shifts.value.filter(s => s.category === 'rotating').length },
  { id: 'night', label: 'Night', count: shifts.value.filter(s => s.category === 'night').length },
  { id: 'split', label: 'Split', count: shifts.value.filter(s => s.category === 'split').length }
]);

const filteredShifts = computed(() => {
  return shifts.value.filter(s => {
    const matchesTab = activeTab.value === 'all' || s.category === activeTab.value;
    const matchesSearch = searchQuery.value === '' || 
      s.name.en.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      s.code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      (s.name.am && s.name.am.includes(searchQuery.value));
    return matchesTab && matchesSearch;
  });
});

// ─── Duration & Time Mathematics ───
function calculateMinutes(start: string, end: string, isOvernight: boolean): number {
  const [sh, sm] = start.split(':').map(Number);
  const [eh, em] = end.split(':').map(Number);
  let startTotal = sh * 60 + sm;
  let endTotal = eh * 60 + em;
  if (isOvernight || endTotal <= startTotal) {
    endTotal += 24 * 60;
  }
  return endTotal - startTotal;
}

function formatDuration(mins: number): string {
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  if (m === 0) return `${h}.00 hrs`;
  return `${h}h ${m}m`;
}

function timeToDegrees(time: string): number {
  const [h, m] = time.split(':').map(Number);
  return (((h % 24) + m / 60) / 24) * 360;
}

// ─── Quick Create State ───
const quickForm = ref({
  code: '',
  name: '',
  category: 'fixed',
  start_time: '08:30',
  end_time: '17:30',
  break_minutes: '60',
  is_overnight: false
});

const isQuickSubmitting = ref(false);

const handleOpenQuickCreate = () => {
  quickForm.value = {
    code: `SH-${Math.floor(100 + Math.random() * 900)}`,
    name: '',
    category: 'fixed',
    start_time: '08:30',
    end_time: '17:30',
    break_minutes: '60',
    is_overnight: false
  };
  showQuickCreate.value = true;
};

const handleExpandFullForm = () => {
  showQuickCreate.value = false;
  router.push({
    path: '/hr/shifts/create',
    query: {
      code: quickForm.value.code,
      name: quickForm.value.name,
      category: quickForm.value.category,
      start_time: quickForm.value.start_time,
      end_time: quickForm.value.end_time
    }
  });
};

const handleSaveQuickShift = () => {
  if (!quickForm.value.name) return;
  isQuickSubmitting.value = true;
  setTimeout(() => {
    shifts.value.unshift({
      id: Date.now(),
      uuid: `sh-uuid-${Date.now()}`,
      code: quickForm.value.code || 'SH-NEW',
      name: { en: quickForm.value.name },
      entity_id: 3,
      entity_name: 'Haleta Addis Ababa HQ',
      category: quickForm.value.category as ShiftCategory,
      category_label: quickForm.value.category.charAt(0).toUpperCase() + quickForm.value.category.slice(1),
      start_time: quickForm.value.start_time,
      end_time: quickForm.value.end_time,
      is_overnight: quickForm.value.is_overnight,
      break_minutes: Number(quickForm.value.break_minutes) || 60,
      grace_in_minutes: 15,
      grace_out_minutes: 10,
      night_hours_from: null,
      night_hours_to: null,
      state: 'active'
    });
    isQuickSubmitting.value = false;
    showQuickCreate.value = false;
    toast.success(`Work Shift "${quickForm.value.name}" created successfully.`);
  }, 400);
};

// ─── Actions Menu Handlers ───
const toggleActionMenu = (id: number) => {
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const handleToggleColumn = (colKey: string | { key: string; visible: boolean }) => {
  const k = typeof colKey === 'string' ? colKey : colKey.key;
  const col = tableColumns.value.find(c => c.key === k);
  if (col) col.visible = typeof colKey === 'string' ? !col.visible : colKey.visible;
};

const isColVisible = (key: string) => {
  const col = tableColumns.value.find(c => c.key === key);
  return col ? col.visible !== false : true;
};

const handleSelectAll = (checked: boolean) => {
  selectedRowIds.value = checked ? filteredShifts.value.map(s => s.id) : [];
};

const handleToggleRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) selectedRowIds.value.splice(idx, 1);
  else selectedRowIds.value.push(id);
};

const handleBatchDelete = () => {
  shifts.value = shifts.value.filter(s => !selectedRowIds.value.includes(s.id));
  toast.success(`${selectedRowIds.value.length} shifts deleted.`);
  selectedRowIds.value = [];
};
</script>

<template>
  <div class="work-shifts-page">
    <!-- Breadcrumb Standard (Exact Page Name Only) -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Unified Table Card Layout -->
    <AppDataTable
      title="Work Shifts"
      subtitle="Define labour time windows, shift rotations, break deductions, and statutory night-work intervals."
      :columns="tableColumns"
      :totalEntries="filteredShifts.length"
      v-model:searchQuery="searchQuery"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Custom Toolbar Actions -->
      <template #actions>
        <div class="toolbar-actions">
          <!-- View Switcher -->
          <div class="view-mode-toggle">
            <button 
              type="button" 
              class="btn-toggle-view" 
              :class="{ active: viewMode === 'table' }"
              @click="viewMode = 'table'"
              title="Dense Table View"
            >
              <List :size="16" />
            </button>
            <button 
              type="button" 
              class="btn-toggle-view" 
              :class="{ active: viewMode === 'cards' }"
              @click="viewMode = 'cards'"
              title="24-Hour Dial Cards View"
            >
              <LayoutGrid :size="16" />
            </button>
          </div>

          <!-- Primary Create Action (Well-rounded rectangle, NOT pill) -->
          <AppButton variant="primary" size="sm" @click="handleOpenQuickCreate">
  <template #icon-left><Plus :size="15" /></template>
  Create Shift
</AppButton>
        </div>
      </template>

      <!-- Category Filter Tabs inside Table Card -->
      <template #pre-table>
        <div class="table-subnav">
          <BaseTabs 
            v-model="activeTab" 
            :tabs="categoryTabs"
            type="rounded"
          />
        </div>
      </template>

      <!-- TABLE VIEW -->
      <template v-if="viewMode === 'table'" #default>
        <div class="erp-table-responsive">
          <table class="erp-table">
            <thead>
              <tr>
                <th class="th-checkbox">
                  <FormCheckbox 
                    :model-value="selectedRowIds.length === filteredShifts.length && filteredShifts.length > 0"
                    :indeterminate="selectedRowIds.length > 0 && selectedRowIds.length < filteredShifts.length"
                    size="sm"
                    @change="(val) => handleSelectAll(Boolean(val))"
                    aria-label="Select all rows"
                  />
                </th>
                <th v-if="isColVisible('name')" class="th-name">Shift Name</th>
                <th v-if="isColVisible('category')">Category</th>
                <th v-if="isColVisible('window')">Working Window</th>
                <th v-if="isColVisible('duration')">Net Work Hours</th>
                <th v-if="isColVisible('grace')">Grace Tolerances</th>
                <th v-if="isColVisible('night_work')">Night Window</th>
                <th v-if="isColVisible('entity')">Owning Entity</th>
                <th v-if="isColVisible('state')">State</th>
                <th class="th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="shift in filteredShifts" 
                :key="shift.id"
                class="erp-table-row"
                :class="{ 'row-selected': selectedRowIds.includes(shift.id) }"
              >
                <!-- Checkbox -->
                <td class="td-checkbox" @click.stop>
                  <FormCheckbox 
                    :model-value="selectedRowIds.includes(shift.id)"
                    size="sm"
                    @change="() => handleToggleRow(shift.id)"
                    aria-label="Select row"
                  />
                </td>

                <!-- Name & Code (Name-First Rule) -->
                <td v-if="isColVisible('name')" class="td-name">
                  <div class="name-cell-wrapper">
                    <span class="table-name-primary">{{ shift.name.en }}</span>
                    <span class="table-code-subtext">{{ shift.code }}</span>
                  </div>
                </td>

                <!-- Category -->
                <td v-if="isColVisible('category')" class="td-tertiary">
                  <span class="plain-cell-text capitalize">{{ shift.category_label }}</span>
                </td>

                <!-- Working Window -->
                <td v-if="isColVisible('window')" class="td-tertiary">
                  <div class="window-cell">
                    <span class="font-medium text-slate-700">{{ shift.start_time }} – {{ shift.end_time }}</span>
                    <span v-if="shift.is_overnight" class="overnight-badge">+1 Day</span>
                  </div>
                </td>

                <!-- Net Work Hours -->
                <td v-if="isColVisible('duration')" class="td-tertiary">
                  <div class="duration-cell">
                    <span class="font-medium text-slate-700">{{ formatDuration(calculateMinutes(shift.start_time, shift.end_time, shift.is_overnight) - shift.break_minutes) }}</span>
                    <span class="break-subtext">({{ shift.break_minutes }}m break)</span>
                  </div>
                </td>

                <!-- Grace Tolerances -->
                <td v-if="isColVisible('grace')" class="td-tertiary">
                  <span class="plain-cell-text">{{ shift.grace_in_minutes }}m in / {{ shift.grace_out_minutes }}m out</span>
                </td>

                <!-- Night Window -->
                <td v-if="isColVisible('night_work')" class="td-tertiary">
                  <span v-if="shift.night_hours_from" class="night-cell-text">
                    {{ shift.night_hours_from }} – {{ shift.night_hours_to }}
                  </span>
                  <span v-else class="plain-cell-text">—</span>
                </td>

                <!-- Owning Entity -->
                <td v-if="isColVisible('entity')" class="td-tertiary">
                  <span class="plain-cell-text">{{ shift.entity_name }}</span>
                </td>

                <!-- State -->
                <td v-if="tableColumns.find(c => c.key === 'state')?.visible">
                  <BaseBadge 
                    :color="shift.state === 'active' ? 'success' : 'gray'"
                    size="sm"
                  >
                    {{ shift.state === 'active' ? 'Active' : 'Inactive' }}
                  </BaseBadge>
                </td>

                <!-- Actions Menu -->
                <td class="td-actions">
                  <div class="action-menu-relative">
                    <button 
                      type="button" 
                      class="btn-action-dots" 
                      @click="toggleActionMenu(shift.id)"
                      aria-label="Actions"
                    >
                      <MoreVertical :size="15" />
                    </button>
                    <div v-if="activeActionMenuId === shift.id" class="action-dropdown">
                      <button type="button" class="action-item" @click="activeActionMenuId = null">
                        <Edit2 :size="14" />
                        <span>Edit Shift</span>
                      </button>
                      <button type="button" class="action-item" @click="activeActionMenuId = null">
                        <Copy :size="14" />
                        <span>Duplicate</span>
                      </button>
                      <div class="action-divider"></div>
                      <button type="button" class="action-item text-red-600" @click="activeActionMenuId = null">
                        <Trash2 :size="14" />
                        <span>Delete</span>
                      </button>
                    </div>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>

      <!-- CARDS VIEW WITH 24-HOUR CIRCULAR DIALS -->
      <template v-else #default>
        <div class="shifts-cards-grid">
          <div 
            v-for="shift in filteredShifts" 
            :key="shift.id"
            class="shift-card-item"
          >
            <!-- Card Header -->
            <div class="shift-card-header">
              <div class="shift-card-title-group">
                <h4 class="shift-card-title">{{ shift.name.en }}</h4>
                <p class="shift-card-code">{{ shift.code }} · {{ shift.entity_name }}</p>
              </div>
              <span class="category-pill">{{ shift.category_label }}</span>
            </div>

            <!-- Card Body: 24h Circular Dial & Time Details -->
            <div class="shift-card-body">
              <!-- SVG 24-Hour Circular Dial -->
              <div class="dial-container">
                <svg viewBox="0 0 100 100" class="dial-svg">
                  <!-- Base Clock Track (24 hours) -->
                  <circle cx="50" cy="50" r="40" fill="none" stroke="#e2e8f0" stroke-width="7" />
                  
                  <!-- Night Work Sector Reference (22:00 to 06:00 = 8h / 33.3% of circle) -->
                  <circle 
                    cx="50" cy="50" r="40" 
                    fill="none" 
                    stroke="#ede9fe" 
                    stroke-width="7" 
                    stroke-dasharray="69.8 181.5"
                    stroke-dashoffset="-230.3"
                  />

                  <!-- Shift Working Arc Sweep -->
                  <circle
                    cx="50" cy="50" r="40"
                    fill="none"
                    stroke="#0B529C"
                    stroke-width="7"
                    stroke-linecap="round"
                    :stroke-dasharray="`${(calculateMinutes(shift.start_time, shift.end_time, shift.is_overnight) / 1440) * 251.3} 251.3`"
                    :stroke-dashoffset="`${-((timeToDegrees(shift.start_time) / 360) * 251.3)}`"
                  />
                </svg>
                <!-- Center Clock Indicator -->
                <div class="dial-center">
                  <Clock :size="16" class="text-slate-500" />
                </div>
              </div>

              <!-- Time Breakdown -->
              <div class="shift-times-breakdown">
                <div class="window-row">
                  <span class="window-range">{{ shift.start_time }} – {{ shift.end_time }}</span>
                  <span v-if="shift.is_overnight" class="overnight-tag">Overnight</span>
                </div>
                <div class="metric-row">
                  <span class="metric-label">Total Window:</span>
                  <span class="metric-val">{{ formatDuration(calculateMinutes(shift.start_time, shift.end_time, shift.is_overnight)) }}</span>
                </div>
                <div class="metric-row">
                  <span class="metric-label">Unpaid Break:</span>
                  <span class="metric-val">{{ shift.break_minutes }} min</span>
                </div>
                <div class="metric-row highlight">
                  <span class="metric-label">Net Working:</span>
                  <span class="metric-val">{{ formatDuration(calculateMinutes(shift.start_time, shift.end_time, shift.is_overnight) - shift.break_minutes) }}</span>
                </div>
              </div>
            </div>

            <!-- Card Footer: Grace & Night Work Details -->
            <div class="shift-card-footer">
              <div class="grace-badge">
                <span class="grace-lbl">Grace In:</span>
                <span class="grace-val">{{ shift.grace_in_minutes }}m</span>
              </div>
              <div class="grace-badge">
                <span class="grace-lbl">Grace Out:</span>
                <span class="grace-val">{{ shift.grace_out_minutes }}m</span>
              </div>
              <div v-if="shift.night_hours_from" class="night-badge">
                <Moon :size="12" class="text-indigo-600" />
                <span>Night OT Window</span>
              </div>
            </div>
          </div>
        </div>
      </template>
    </AppDataTable>

    <!-- Floating Batch Action Bar -->
    <TableFloatingBar 
      :count="selectedRowIds.length" 
      @delete="handleBatchDelete" 
    />

    <!-- Quick Create Modal (<= 5 Required Fields Standard) -->
    <QuickCreateModal
      :show="showQuickCreate"
      title="Create Work Shift"
      :is-submitting="isQuickSubmitting"
      @close="showQuickCreate = false"
      @save="handleSaveQuickShift"
      @expand="handleExpandFullForm"
    >
      <div class="quick-form-grid">
        <FormInput
          v-model="quickForm.name"
          label="Shift Name"
          required
        />

        <FormInput
          v-model="quickForm.code"
          label="Shift Code"
          required
        />

        <FormSelect
          v-model="quickForm.category"
          label="Shift Category"
          placeholder="Select"
          :options="[
            { value: 'fixed', label: 'Fixed (Standard Day)' },
            { value: 'rotating', label: 'Rotating (Morning / Evening)' },
            { value: 'night', label: 'Night (Graveyard / Guard)' },
            { value: 'split', label: 'Split Shift' },
            { value: 'flexible', label: 'Flexible Window' }
          ]"
        />

        <div class="time-inputs-pair">
          <FormInput
            v-model="quickForm.start_time"
            label="Start Time"
            type="time"
            required
          />
          <FormInput
            v-model="quickForm.end_time"
            label="End Time"
            type="time"
            required
          />
        </div>

        <FormInput
          v-model="quickForm.break_minutes"
          label="Unpaid Break (Minutes)"
          type="number"
        />
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.work-shifts-page {
  padding: 0;
  background-color: #fafafa;
  min-height: 100vh;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

/* Toolbar Actions */
.toolbar-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.view-mode-toggle {
  display: flex;
  background: #f1f5f9;
  padding: 2px;
  border-radius: 8px;
}

.btn-toggle-view {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 6px;
  color: #737373;
  border: none;
  background: transparent;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-toggle-view.active {
  background: #ffffff;
  color: #0B529C;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}

.btn-create-shift {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  height: 38px;
  padding: 0 1rem;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 13.5px;
  font-weight: 500;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.btn-create-shift:hover {
  background-color: #09427d;
}

.table-subnav {
  padding: 0 1.25rem 0.5rem 1.25rem;
  border-bottom: 1px solid #f1f5f9;
}

/* ERP Table Layout */
.erp-table-responsive {
  width: 100%;
  overflow-x: auto;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  background-color: #fafafa;
  font-size: 12px;
  font-weight: 600;
  color: #737373;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.erp-table td {
  height: 48px;
  padding: 8px 16px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
}

.erp-table-row:hover {
  background-color: #fafafa;
}

.row-selected {
  background-color: #f0f7ff;
}

.th-checkbox, .td-checkbox {
  width: 44px;
  padding-left: 1.25rem !important;
}

.erp-checkbox {
  width: 16px;
  height: 16px;
  border-radius: 4px;
  border: 1.5px solid #cbd5e1;
  accent-color: #0B529C;
  cursor: pointer;
}

/* Name-First Column */
.name-cell-wrapper {
  display: flex;
  flex-direction: column;
}

.table-name-primary {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.table-code-subtext {
  font-size: 11px;
  color: #737373;
  margin-top: 1px;
}

.td-tertiary {
  color: #737373;
}

.plain-cell-text {
  font-size: 13px;
  color: #737373;
}

.window-cell {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.overnight-badge {
  font-size: 10px;
  font-weight: 600;
  padding: 1px 6px;
  border-radius: 4px;
  background-color: #ede9fe;
  color: #6d28d9;
}

.duration-cell {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.break-subtext {
  font-size: 11.5px;
  color: #94a3b8;
}

.night-cell-text {
  font-size: 12.5px;
  font-weight: 500;
  color: #4f46e5;
}

/* Actions Menu */
.th-actions, .td-actions {
  width: 56px;
  text-align: right;
}

.action-menu-relative {
  position: relative;
  display: inline-block;
}

.btn-action-dots {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f5f5f5;
  color: #404040;
}

.action-dropdown {
  position: absolute;
  top: 100%;
  right: 0;
  width: 150px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  padding: 4px;
  z-index: 50;
}

.action-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  width: 100%;
  padding: 7px 10px;
  font-size: 12.5px;
  color: #404040;
  border: none;
  background: transparent;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
}

.action-item:hover {
  background-color: #fafafa;
}

.action-divider {
  height: 1px;
  background: #f1f5f9;
  margin: 4px 0;
}

/* 24-Hour Circular Dial Cards Grid */
.shifts-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 1.25rem;
  padding: 1.25rem;
}

.shift-card-item {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  transition: box-shadow 0.2s ease, border-color 0.2s ease;
}

.shift-card-item:hover {
  border-color: #cbd5e1;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.04);
}

.shift-card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 0.75rem;
}

.shift-card-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.shift-card-code {
  font-size: 11.5px;
  color: #737373;
  margin: 2px 0 0 0;
}

.category-pill {
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  background: #f1f5f9;
  color: #737373;
  border-radius: 6px;
}

.shift-card-body {
  display: flex;
  align-items: center;
  gap: 1.25rem;
}

.dial-container {
  position: relative;
  width: 80px;
  height: 80px;
  flex-shrink: 0;
}

.dial-svg {
  width: 100%;
  height: 100%;
  transform: rotate(-90deg);
}

.dial-center {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.shift-times-breakdown {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.window-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.25rem;
}

.window-range {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.overnight-tag {
  font-size: 10px;
  font-weight: 600;
  padding: 1px 6px;
  border-radius: 4px;
  background-color: #ede9fe;
  color: #6d28d9;
}

.metric-row {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #737373;
}

.metric-row.highlight {
  font-weight: 600;
  color: #0B529C;
  border-top: 1px dashed #e2e8f0;
  padding-top: 4px;
  margin-top: 2px;
}

.shift-card-footer {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding-top: 0.75rem;
  border-top: 1px solid #f1f5f9;
  flex-wrap: wrap;
}

.grace-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  background: #f8fafc;
  padding: 3px 8px;
  border-radius: 6px;
  font-size: 11px;
}

.grace-lbl {
  color: #737373;
}

.grace-val {
  font-weight: 600;
  color: #404040;
}

.night-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  background: #ede9fe;
  color: #5b21b6;
  padding: 3px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 500;
}

/* Quick Create Modal Grid */
.quick-form-grid {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.time-inputs-pair {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.75rem;
}
</style>
