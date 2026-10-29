<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  CalendarDays, Plus, Search, Filter, ArrowUpDown, ChevronDown, 
  MoreVertical, Edit2, Trash2, Eye, Copy, Check, Calendar, 
  CheckCircle2, AlertCircle, X, Layers, ChevronRight,
  Maximize2, ArrowRight, ShieldCheck, DollarSign, Gift, Building2,
  LayoutGrid, List
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import UnderlineTabs from '../../components/UnderlineTabs.vue';

const router = useRouter();

// ─── Breadcrumbs ───
const breadcrumbItems = [
  { label: 'Holidays' }
];

// ─── Types (HR_Schema_final-v4.sql lines 1246–1270) ───
export type HolidayType = 'public' | 'religious' | 'company';

export interface HolidayRecord {
  id: number;
  uuid: string;
  code: string;
  name: { en: string; am?: string };
  holiday_type: HolidayType;
  holiday_type_label: string;
  entity_id: number | null;
  entity_name: string;
  date: string; // "YYYY-MM-DD"
  ethiopian_date_text: string;
  is_recurring: boolean;
  is_paid: boolean;
  is_system: boolean;
  state: 'active' | 'inactive';
}

// ─── Table Columns ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Holiday Name', visible: true, sortable: true },
  { key: 'date', label: 'Gregorian Date', visible: true, sortable: true },
  { key: 'eth_date', label: 'Ethiopian Date (E.C.)', visible: true, sortable: false },
  { key: 'holiday_type', label: 'Classification', visible: true, sortable: true },
  { key: 'is_paid', label: 'Paid / OT Impact', visible: true, sortable: true },
  { key: 'recurring', label: 'Recurrence', visible: true, sortable: false },
  { key: 'scope', label: 'Observance Scope', visible: false, sortable: true },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
]);

// ─── Mock Data Aligned with HR_Schema_final-v4.sql lines 1263–1269 ───
const holidays = ref<HolidayRecord[]>([
  {
    id: 1,
    uuid: 'hol-uuid-001',
    code: 'GENNA',
    name: { en: 'Ethiopian Christmas (Genna)', am: 'የገና በዓል' },
    holiday_type: 'religious',
    holiday_type_label: 'Religious Holiday',
    entity_id: null,
    entity_name: 'National (All Entities)',
    date: '2026-01-07',
    ethiopian_date_text: 'ታኅሣሥ 29, 2018 E.C.',
    is_recurring: true,
    is_paid: true,
    is_system: true,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'hol-uuid-002',
    code: 'FASIKA',
    name: { en: 'Ethiopian Easter (Fasika)', am: 'የትንሣኤ በዓል (ፋሲካ)' },
    holiday_type: 'religious',
    holiday_type_label: 'Religious Holiday',
    entity_id: null,
    entity_name: 'National (All Entities)',
    date: '2026-04-12',
    ethiopian_date_text: 'ሚያዝያ 04, 2018 E.C.',
    is_recurring: false,
    is_paid: true,
    is_system: true,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'hol-uuid-003',
    code: 'ENKUTATASH',
    name: { en: 'Ethiopian New Year (Enkutatash)', am: 'እንቁጣጣሽ (አዲስ ዓመት)' },
    holiday_type: 'public',
    holiday_type_label: 'Public Holiday',
    entity_id: null,
    entity_name: 'National (All Entities)',
    date: '2026-09-11',
    ethiopian_date_text: 'መስከረም 01, 2019 E.C.',
    is_recurring: true,
    is_paid: true,
    is_system: true,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'hol-uuid-004',
    code: 'MESKEL',
    name: { en: 'Finding of the True Cross (Meskel)', am: 'የመስቀል ደመራ በዓል' },
    holiday_type: 'religious',
    holiday_type_label: 'Religious Holiday',
    entity_id: null,
    entity_name: 'National (All Entities)',
    date: '2026-09-27',
    ethiopian_date_text: 'መስከረም 17, 2019 E.C.',
    is_recurring: true,
    is_paid: true,
    is_system: true,
    state: 'active'
  },
  {
    id: 5,
    uuid: 'hol-uuid-005',
    code: 'HLT-DAY',
    name: { en: 'Haleta Foundation Day', am: 'የሐሌታ መሥራች ቀን' },
    holiday_type: 'company',
    holiday_type_label: 'Company Holiday',
    entity_id: 1,
    entity_name: 'Haleta Corporate Group',
    date: '2026-11-05',
    ethiopian_date_text: 'ጥቅምት 26, 2019 E.C.',
    is_recurring: true,
    is_paid: true,
    is_system: false,
    state: 'active'
  }
]);

// ─── State ───
const activeTab = ref('all');
const viewMode = ref<'table' | 'cards'>('table');
const searchQuery = ref('');
const selectedRowIds = ref<number[]>([]);
const activeActionMenuId = ref<number | null>(null);
const showQuickCreate = ref(false);
const isQuickSubmitting = ref(false);
const toastMessage = ref<string | null>(null);

// ─── Filter Tabs ───
const categoryTabs = computed(() => [
  { id: 'all', label: 'All Holidays', count: holidays.value.length },
  { id: 'public', label: 'Public', count: holidays.value.filter(h => h.holiday_type === 'public').length },
  { id: 'religious', label: 'Religious', count: holidays.value.filter(h => h.holiday_type === 'religious').length },
  { id: 'company', label: 'Company', count: holidays.value.filter(h => h.holiday_type === 'company').length }
]);

const filteredHolidays = computed(() => {
  return holidays.value.filter(h => {
    const matchesTab = activeTab.value === 'all' || h.holiday_type === activeTab.value;
    const matchesSearch = searchQuery.value === '' || 
      h.name.en.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      h.code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      (h.name.am && h.name.am.includes(searchQuery.value));
    return matchesTab && matchesSearch;
  });
});

// ─── Quick Create Form ───
const quickForm = ref({
  code: '',
  name_en: '',
  name_am: '',
  holiday_type: 'public',
  date: '2026-09-11',
  is_paid: true,
  is_recurring: true
});

const handleOpenQuickCreate = () => {
  quickForm.value = {
    code: `HOL-${Math.floor(100 + Math.random() * 900)}`,
    name_en: '',
    name_am: '',
    holiday_type: 'public',
    date: '2026-09-11',
    is_paid: true,
    is_recurring: true
  };
  showQuickCreate.value = true;
};

const handleExpandFullForm = () => {
  showQuickCreate.value = false;
  router.push({
    path: '/hr/holidays/create',
    query: {
      code: quickForm.value.code,
      name: quickForm.value.name_en,
      holiday_type: quickForm.value.holiday_type,
      date: quickForm.value.date
    }
  });
};

const handleSaveQuick = () => {
  if (!quickForm.value.name_en || !quickForm.value.code) return;
  isQuickSubmitting.value = true;
  setTimeout(() => {
    const newRecord: HolidayRecord = {
      id: Date.now(),
      uuid: `hol-uuid-${Date.now()}`,
      code: quickForm.value.code,
      name: { en: quickForm.value.name_en, am: quickForm.value.name_am },
      holiday_type: quickForm.value.holiday_type as HolidayType,
      holiday_type_label: quickForm.value.holiday_type.charAt(0).toUpperCase() + quickForm.value.holiday_type.slice(1) + ' Holiday',
      entity_id: null,
      entity_name: 'National (All Entities)',
      date: quickForm.value.date,
      ethiopian_date_text: '2019 E.C.',
      is_recurring: quickForm.value.is_recurring,
      is_paid: quickForm.value.is_paid,
      is_system: false,
      state: 'active'
    };
    holidays.value.unshift(newRecord);
    isQuickSubmitting.value = false;
    showQuickCreate.value = false;
    toastMessage.value = `Holiday "${quickForm.value.name_en}" saved successfully.`;
    setTimeout(() => { toastMessage.value = null; }, 3500);
  }, 400);
};

const handleToggleColumn = ({ key, visible }: { key: string; visible: boolean }) => {
  const col = tableColumns.value.find(c => c.key === key);
  if (col) col.visible = visible;
};

const handleSelectAll = (checked: boolean) => {
  selectedRowIds.value = checked ? filteredHolidays.value.map(h => h.id) : [];
};

const handleToggleRow = (id: number) => {
  const idx = selectedRowIds.value.indexOf(id);
  if (idx > -1) selectedRowIds.value.splice(idx, 1);
  else selectedRowIds.value.push(id);
};

const handleBatchDelete = () => {
  holidays.value = holidays.value.filter(h => !selectedRowIds.value.includes(h.id));
  toastMessage.value = `${selectedRowIds.value.length} holidays deleted.`;
  selectedRowIds.value = [];
  setTimeout(() => { toastMessage.value = null; }, 3000);
};
</script>

<template>
  <div class="holidays-page">
    <!-- Breadcrumb Standard -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Notification Toast -->
    <div v-if="toastMessage" class="action-toast">
      <CheckCircle2 :size="16" class="text-emerald-600" />
      <span>{{ toastMessage }}</span>
    </div>

    <!-- Unified Table Card Layout -->
    <AppDataTable
      title="Holidays"
      subtitle="Manage national statutory holidays, religious feasts, and regional/company observances that dictate calendar day types and payroll overtime multipliers."
      :columns="tableColumns"
      :data="filteredHolidays"
      @toggleColumn="handleToggleColumn"
    >
      <!-- Toolbar Actions -->
      <template #actions>
        <div class="toolbar-actions">
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
              title="Calendar Date Cards View"
            >
              <LayoutGrid :size="16" />
            </button>
          </div>

          <button 
            type="button" 
            class="btn-create-holiday" 
            @click="handleOpenQuickCreate"
          >
            <Plus :size="15" />
            <span>Create Holiday</span>
          </button>
        </div>
      </template>

      <!-- Category Filter Tabs inside Table Card -->
      <template #pre-table>
        <div class="table-subnav">
          <UnderlineTabs 
            v-model="activeTab" 
            :tabs="categoryTabs"
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
                  <input 
                    type="checkbox" 
                    class="erp-checkbox"
                    :checked="selectedRowIds.length === filteredHolidays.length && filteredHolidays.length > 0"
                    @change="handleSelectAll(($event.target as HTMLInputElement).checked)"
                  />
                </th>
                <th v-if="tableColumns.find(c => c.key === 'name')?.visible" class="th-name">Holiday Name</th>
                <th v-if="tableColumns.find(c => c.key === 'date')?.visible">Gregorian Date</th>
                <th v-if="tableColumns.find(c => c.key === 'eth_date')?.visible">Ethiopian Date (E.C.)</th>
                <th v-if="tableColumns.find(c => c.key === 'holiday_type')?.visible">Classification</th>
                <th v-if="tableColumns.find(c => c.key === 'is_paid')?.visible">Paid / OT Impact</th>
                <th v-if="tableColumns.find(c => c.key === 'recurring')?.visible">Recurrence</th>
                <th v-if="tableColumns.find(c => c.key === 'scope')?.visible">Observance Scope</th>
                <th v-if="tableColumns.find(c => c.key === 'state')?.visible">State</th>
                <th class="th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="hol in filteredHolidays" 
                :key="hol.id"
                class="erp-table-row"
                :class="{ 'row-selected': selectedRowIds.includes(hol.id) }"
              >
                <!-- Checkbox -->
                <td class="td-checkbox">
                  <input 
                    type="checkbox" 
                    class="erp-checkbox"
                    :checked="selectedRowIds.includes(hol.id)"
                    @change="handleToggleRow(hol.id)"
                  />
                </td>

                <!-- Name & Code (Name-First Rule) -->
                <td v-if="tableColumns.find(c => c.key === 'name')?.visible" class="td-name">
                  <div class="name-cell-wrapper">
                    <span class="table-name-primary">{{ hol.name.en }}</span>
                    <span class="table-code-subtext">{{ hol.code }} <template v-if="hol.name.am">· {{ hol.name.am }}</template></span>
                  </div>
                </td>

                <!-- Gregorian Date -->
                <td v-if="tableColumns.find(c => c.key === 'date')?.visible" class="td-tertiary">
                  <span class="font-medium text-slate-700">
                    {{ new Date(hol.date + 'T00:00:00').toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) }}
                  </span>
                </td>

                <!-- Ethiopian Date -->
                <td v-if="tableColumns.find(c => c.key === 'eth_date')?.visible" class="td-tertiary">
                  <span class="ethiopian-calendar-tag">{{ hol.ethiopian_date_text }}</span>
                </td>

                <!-- Classification -->
                <td v-if="tableColumns.find(c => c.key === 'holiday_type')?.visible" class="td-tertiary">
                  <span class="plain-cell-text capitalize">{{ hol.holiday_type_label }}</span>
                </td>

                <!-- Paid Status -->
                <td v-if="tableColumns.find(c => c.key === 'is_paid')?.visible" class="td-tertiary">
                  <span v-if="hol.is_paid" class="paid-indicator">Paid (2.5x OT)</span>
                  <span v-else class="plain-cell-text">Unpaid</span>
                </td>

                <!-- Recurrence -->
                <td v-if="tableColumns.find(c => c.key === 'recurring')?.visible" class="td-tertiary">
                  <span class="plain-cell-text">{{ hol.is_recurring ? 'Annual Recurring' : 'Movable Feast' }}</span>
                </td>

                <!-- Scope -->
                <td v-if="tableColumns.find(c => c.key === 'scope')?.visible" class="td-tertiary">
                  <span class="plain-cell-text">{{ hol.entity_name }}</span>
                </td>

                <!-- State -->
                <td v-if="tableColumns.find(c => c.key === 'state')?.visible">
                  <span class="status-pill" :class="hol.state === 'active' ? 'status-active' : 'status-inactive'">
                    {{ hol.state === 'active' ? 'Active' : 'Inactive' }}
                  </span>
                </td>

                <!-- Actions -->
                <td class="td-actions">
                  <div class="action-menu-relative">
                    <button 
                      type="button" 
                      class="btn-action-dots" 
                      @click="activeActionMenuId = activeActionMenuId === hol.id ? null : hol.id"
                      aria-label="Actions"
                    >
                      <MoreVertical :size="15" />
                    </button>
                    <div v-if="activeActionMenuId === hol.id" class="action-dropdown">
                      <button type="button" class="action-item" @click="activeActionMenuId = null">
                        <Edit2 :size="14" />
                        <span>Edit Holiday</span>
                      </button>
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

      <!-- CARDS VIEW WITH DATE-SQUARE CARDS -->
      <template v-else #default>
        <div class="holidays-cards-grid">
          <div 
            v-for="hol in filteredHolidays" 
            :key="hol.id"
            class="holiday-card-item"
          >
            <!-- Date Square Block -->
            <div class="date-square-block">
              <span class="date-month">{{ new Date(hol.date + 'T00:00:00').toLocaleDateString('en-US', { month: 'short' }) }}</span>
              <span class="date-day">{{ new Date(hol.date + 'T00:00:00').getDate() }}</span>
              <span class="date-year">{{ new Date(hol.date + 'T00:00:00').getFullYear() }}</span>
            </div>

            <!-- Holiday Details Content -->
            <div class="holiday-card-details">
              <div class="card-names-group">
                <h4 class="card-en-name">{{ hol.name.en }}</h4>
                <p v-if="hol.name.am" class="card-am-name">{{ hol.name.am }}</p>
                <p class="card-code-sub">{{ hol.code }} · {{ hol.ethiopian_date_text }}</p>
              </div>

              <div class="card-badges-strip">
                <span class="tag-type capitalize">{{ hol.holiday_type }}</span>
                <span v-if="hol.is_paid" class="tag-paid">Paid Holiday</span>
                <span v-if="hol.is_recurring" class="tag-recurring">Annual</span>
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
      title="Create Holiday"
      :is-submitting="isQuickSubmitting"
      @close="showQuickCreate = false"
      @save="handleSaveQuick"
      @expand="handleExpandFullForm"
    >
      <div class="quick-form-grid">
        <FormInput
          v-model="quickForm.name_en"
          label="Holiday Name (English)"
          required
        />

        <FormInput
          v-model="quickForm.name_am"
          label="Holiday Name (Amharic)"
        />

        <FormInput
          v-model="quickForm.code"
          label="Holiday Business Code"
          required
        />

        <div class="form-pair">
          <FormInput
            v-model="quickForm.date"
            label="Date of Observance"
            type="date"
            required
          />

          <FormSelect
            v-model="quickForm.holiday_type"
            label="Classification"
            placeholder="Select"
            :options="[
              { value: 'public', label: 'Public Statutory Holiday' },
              { value: 'religious', label: 'Religious Feast Observance' },
              { value: 'company', label: 'Company Holiday' }
            ]"
          />
        </div>

        <FormCheckbox
          v-model="quickForm.is_paid"
          label="Paid Statutory Holiday"
          description="Designate as paid holiday to enforce statutory overtime multiplier (2.5x) for any hours worked."
        />
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.holidays-page {
  padding: 1.25rem 2rem 3rem 2rem;
  background-color: #f8fafc;
  min-height: 100vh;
}

.breadcrumb-container {
  margin-bottom: 1.25rem;
}

.action-toast {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  display: flex;
  align-items: center;
  gap: 0.625rem;
  background: #ffffff;
  color: #404040;
  padding: 0.75rem 1.25rem;
  border-radius: 8px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
  border: 1px solid #e2e8f0;
  font-size: 13.5px;
  font-weight: 500;
  z-index: 9999;
}

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

.btn-create-holiday {
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

.btn-create-holiday:hover {
  background-color: #09427d;
}

.table-subnav {
  padding: 0 1.25rem 0.5rem 1.25rem;
  border-bottom: 1px solid #f1f5f9;
}

/* Table */
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
  background-color: #f8fafc;
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

.ethiopian-calendar-tag {
  font-size: 12px;
  font-weight: 500;
  color: #0B529C;
  background: #f0f7ff;
  padding: 2px 8px;
  border-radius: 4px;
}

.paid-indicator {
  font-size: 12px;
  font-weight: 600;
  color: #059669;
}

.status-pill {
  display: inline-block;
  padding: 2px 10px;
  font-size: 11.5px;
  font-weight: 500;
  border-radius: 9999px;
}

.status-active {
  background-color: #ecfdf5;
  color: #059669;
}

.status-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

/* Actions */
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
  background-color: #f1f5f9;
  color: #404040;
}

.action-dropdown {
  position: absolute;
  top: 100%;
  right: 0;
  width: 140px;
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
  background-color: #f8fafc;
}

/* Date-Square Cards Grid */
.holidays-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 1.25rem;
  padding: 1.25rem;
}

.holiday-card-item {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.25rem;
  display: flex;
  align-items: center;
  gap: 1.25rem;
  transition: all 0.2s ease;
}

.holiday-card-item:hover {
  border-color: #cbd5e1;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.04);
}

.date-square-block {
  width: 68px;
  height: 68px;
  border-radius: 10px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.date-month {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  color: #0B529C;
}

.date-day {
  font-size: 20px;
  font-weight: 700;
  line-height: 1.1;
  color: #404040;
}

.date-year {
  font-size: 10px;
  color: #94a3b8;
}

.holiday-card-details {
  flex: 1;
  min-width: 0;
}

.card-en-name {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.card-am-name {
  font-size: 12px;
  color: #64748b;
  margin: 2px 0 0 0;
}

.card-code-sub {
  font-size: 11px;
  color: #94a3b8;
  margin: 2px 0 0 0;
}

.card-badges-strip {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  margin-top: 0.5rem;
  flex-wrap: wrap;
}

.tag-type {
  font-size: 10.5px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 4px;
  background: #f1f5f9;
  color: #475569;
}

.tag-paid {
  font-size: 10.5px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 4px;
  background: #ecfdf5;
  color: #059669;
}

.tag-recurring {
  font-size: 10.5px;
  font-weight: 500;
  padding: 2px 6px;
  border-radius: 4px;
  background: #f8fafc;
  color: #64748b;
  border: 1px solid #e2e8f0;
}

.quick-form-grid {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.form-pair {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.75rem;
}
</style>
