<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  MoreVertical, X, Calendar, CalendarDays, List, 
  ChevronDown, Code, Table, Link2, 
  Image, Undo2, Redo2, Check, Save,
  FileText, UploadCloud, Trash2, CheckCircle2,
  Strikethrough, Underline, Palette
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect, { type SelectOption } from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3) ───
const breadcrumbItems = [
  { label: 'Leave Requests', to: '/hr/leave-requests' },
  { label: 'Create Leave Request' }
];

// ─── Top Tabs: <BaseTabs /> Capsule Standard (Rule 1) ───
type TabKey = 'details' | 'schedule';
const activeTab = ref<TabKey>('details');

const tabs: BaseTabItem<TabKey>[] = [
  { id: 'details', label: 'Leave Detail', icon: CalendarDays },
  { id: 'schedule', label: 'Day Breakdown Schedule', icon: List }
];

// ─── Entities (LeaveRequest.entity_id FK Entity) ───
const entityOptions: SelectOption[] = [
  { value: 3, label: 'Haleta Corporate Headquarters' },
  { value: 7, label: 'Bole Branch & Regional Office' },
  { value: 9, label: 'Bahir Dar Regional Hub' },
  { value: 12, label: 'Piazza Commercial Center' }
];

// ─── Employees Directory Dataset ───
export interface EmployeeInfo {
  id: number;
  code: string;
  name: string;
  position: string;
  entity_id: number;
  avatar: string;
}

const employeesList: EmployeeInfo[] = [
  { 
    id: 22, 
    code: 'EMP-00124', 
    name: 'Almaz Kebede', 
    position: 'Senior Accountant', 
    entity_id: 3, 
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=120&h=120&q=80' 
  },
  { 
    id: 14, 
    code: 'EMP-00014', 
    name: 'Abebe Kebede', 
    position: 'Senior Cashier', 
    entity_id: 7, 
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=120&h=120&q=80' 
  },
  { 
    id: 31, 
    code: 'EMP-00031', 
    name: 'Dawit Yohannes', 
    position: 'Logistics Officer', 
    entity_id: 9, 
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=120&h=120&q=80' 
  },
  { 
    id: 44, 
    code: 'EMP-00044', 
    name: 'Kassahun Belay', 
    position: 'Branch Head', 
    entity_id: 3, 
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=120&h=120&q=80' 
  },
  { 
    id: 7, 
    code: 'EMP-00007', 
    name: 'Marta Tadesse', 
    position: 'Branch Manager', 
    entity_id: 3, 
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80' 
  }
];

const employeeOptions = computed<SelectOption[]>(() => {
  return employeesList.map(e => ({
    value: e.id,
    label: `${e.name} (${e.code})`
  }));
});

// ─── Covering Colleagues (LeaveRequest.handover_employee_id) ───
const colleagueOptions = computed<SelectOption[]>(() => {
  return employeesList
    .filter(e => e.id !== form.value.employee_id)
    .map(e => ({
      value: e.id,
      label: `${e.name} (${e.position})`
    }));
});

// ─── Leave Types (LeaveType [REF] Schema) ───
const leaveTypeOptions: SelectOption[] = [
  { value: 1, label: 'Annual Leave' },
  { value: 2, label: 'Sick Leave' },
  { value: 3, label: 'Maternity Leave' },
  { value: 4, label: 'Paternity Leave' },
  { value: 5, label: 'Bereavement Leave' },
  { value: 6, label: 'Unpaid Leave' }
];

// ─── Balances Dataset (LeaveBalance Schema lines 1662–1687) ───
export interface LeaveBalanceInfo {
  leave_type_id: number;
  leave_type_code: string;
  leave_type_name: string;
  entitled_days: number;
  taken_days: number;
  pending_days: number;
  available_days: number;
  color_theme: string;
}

const balancesByEmployee: Record<number, Record<number, LeaveBalanceInfo>> = {
  22: {
    1: { leave_type_id: 1, leave_type_code: 'ANNUAL', leave_type_name: 'Annual Leave', entitled_days: 18.0, taken_days: 2.5, pending_days: 0.0, available_days: 15.5, color_theme: '#0B529C' },
    2: { leave_type_id: 2, leave_type_code: 'SICK', leave_type_name: 'Sick Leave', entitled_days: 30.0, taken_days: 0.0, pending_days: 0.0, available_days: 30.0, color_theme: '#10B981' },
    3: { leave_type_id: 3, leave_type_code: 'MATERNITY', leave_type_name: 'Maternity Leave', entitled_days: 120.0, taken_days: 0.0, pending_days: 0.0, available_days: 120.0, color_theme: '#8B5CF6' },
    4: { leave_type_id: 4, leave_type_code: 'PATERNITY', leave_type_name: 'Paternity Leave', entitled_days: 5.0, taken_days: 0.0, pending_days: 0.0, available_days: 5.0, color_theme: '#0284C7' },
    5: { leave_type_id: 5, leave_type_code: 'BEREAVEMENT', leave_type_name: 'Bereavement Leave', entitled_days: 3.0, taken_days: 0.0, pending_days: 0.0, available_days: 3.0, color_theme: '#64748B' },
    6: { leave_type_id: 6, leave_type_code: 'UNPAID', leave_type_name: 'Unpaid Leave', entitled_days: 0.0, taken_days: 0.0, pending_days: 0.0, available_days: 0.0, color_theme: '#94A3B8' }
  },
  14: {
    1: { leave_type_id: 1, leave_type_code: 'ANNUAL', leave_type_name: 'Annual Leave', entitled_days: 18.0, taken_days: 0.0, pending_days: 2.0, available_days: 16.0, color_theme: '#0B529C' },
    2: { leave_type_id: 2, leave_type_code: 'SICK', leave_type_name: 'Sick Leave', entitled_days: 30.0, taken_days: 0.0, pending_days: 0.0, available_days: 30.0, color_theme: '#10B981' },
    3: { leave_type_id: 3, leave_type_code: 'MATERNITY', leave_type_name: 'Maternity Leave', entitled_days: 120.0, taken_days: 0.0, pending_days: 0.0, available_days: 120.0, color_theme: '#8B5CF6' },
    4: { leave_type_id: 4, leave_type_code: 'PATERNITY', leave_type_name: 'Paternity Leave', entitled_days: 5.0, taken_days: 0.0, pending_days: 0.0, available_days: 5.0, color_theme: '#0284C7' },
    5: { leave_type_id: 5, leave_type_code: 'BEREAVEMENT', leave_type_name: 'Bereavement Leave', entitled_days: 3.0, taken_days: 0.0, pending_days: 0.0, available_days: 3.0, color_theme: '#64748B' },
    6: { leave_type_id: 6, leave_type_code: 'UNPAID', leave_type_name: 'Unpaid Leave', entitled_days: 0.0, taken_days: 0.0, pending_days: 0.0, available_days: 0.0, color_theme: '#94A3B8' }
  }
};

// ─── LeaveRequestDay Sub-Schedule Item (HR_Schema lines 1742–1760) ───
export interface ScheduleDayItem {
  no: number;
  date: string;
  formatted_date: string;
  day_of_week: string;
  portion: 'full' | 'first_half' | 'second_half';
  day_value: number;
}

// ─── Master Form State ───
const form = ref({
  entity_id: 3,
  employee_id: 22,
  leave_type_id: 1,
  start_date: '2026-09-01',
  end_date: '2026-09-02',
  handover_employee_id: 14 as number | null,
  is_half_day: false,
  reason: '',
  attachments: [] as { name: string; size: string }[],
  schedule: [] as ScheduleDayItem[]
});

// Accordion toggle for Reason & Attachments
const isReasonOpen = ref(true);

// Popover state for Tab 2 Shift Portion dropdown
const activePortionRowIdx = ref<number | null>(null);

// Selected employee profile
const selectedEmployee = computed<EmployeeInfo>(() => {
  return employeesList.find(e => e.id === form.value.employee_id) || employeesList[0];
});

// Selected employee active leave balance
const activeLeaveBalance = computed<LeaveBalanceInfo>(() => {
  const empBalances = balancesByEmployee[form.value.employee_id] || balancesByEmployee[22];
  return empBalances[form.value.leave_type_id] || empBalances[1];
});

// Sync from route query params when arriving from QuickCreateModal Expand
onMounted(() => {
  if (route.query.entity_id) form.value.entity_id = Number(route.query.entity_id);
  if (route.query.employee_id) form.value.employee_id = Number(route.query.employee_id);
  if (route.query.leave_type_id) form.value.leave_type_id = Number(route.query.leave_type_id);
  if (route.query.start_date) form.value.start_date = String(route.query.start_date);
  if (route.query.end_date) form.value.end_date = String(route.query.end_date);
  if (route.query.handover_employee_id) form.value.handover_employee_id = Number(route.query.handover_employee_id);
  if (route.query.is_half_day) form.value.is_half_day = route.query.is_half_day === '1';
  if (route.query.reason) form.value.reason = String(route.query.reason);
  rebuildSchedule();
});

// Rebuild day-by-day schedule when dates or half-day flag change
const rebuildSchedule = () => {
  if (!form.value.start_date || !form.value.end_date) {
    form.value.schedule = [];
    return;
  }
  const start = new Date(form.value.start_date);
  const end = new Date(form.value.end_date);
  if (isNaN(start.getTime()) || isNaN(end.getTime()) || end < start) {
    form.value.schedule = [];
    return;
  }

  const list: ScheduleDayItem[] = [];
  const curr = new Date(start);
  let count = 0;
  while (curr <= end && count < 60) {
    const dayStr = curr.toISOString().slice(0, 10);
    const formatted = curr.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    const dayName = curr.toLocaleDateString('en-US', { weekday: 'long' });
    const defaultPortion: 'full' | 'first_half' | 'second_half' = form.value.is_half_day ? 'first_half' : 'full';
    
    list.push({
      no: count + 1,
      date: dayStr,
      formatted_date: formatted,
      day_of_week: dayName,
      portion: defaultPortion,
      day_value: defaultPortion === 'full' ? 1.0 : 0.5
    });
    curr.setDate(curr.getDate() + 1);
    count++;
    if (form.value.is_half_day) break;
  }
  form.value.schedule = list;
};

watch(() => [form.value.start_date, form.value.end_date, form.value.is_half_day], () => {
  rebuildSchedule();
});

// Shift Portion Popover Actions
const togglePortionPopover = (idx: number) => {
  if (activePortionRowIdx.value === idx) {
    activePortionRowIdx.value = null;
  } else {
    activePortionRowIdx.value = idx;
  }
};

const selectPortion = (item: ScheduleDayItem, portion: 'full' | 'first_half' | 'second_half') => {
  item.portion = portion;
  item.day_value = portion === 'full' ? 1.0 : 0.5;
  activePortionRowIdx.value = null;
};

const getPortionLabel = (portion: 'full' | 'first_half' | 'second_half') => {
  switch (portion) {
    case 'full': return 'Full Day';
    case 'first_half': return 'First Half Day';
    case 'second_half': return 'Second Half Day';
  }
};

// Total requested days dynamically computed
const computedRequestedDays = computed(() => {
  if (form.value.schedule.length === 0) return 0;
  return form.value.schedule.reduce((sum, d) => sum + d.day_value, 0);
});

// Top bar state
const isSaved = ref(false);
const showMoreDropdown = ref(false);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

const handleClearForm = () => {
  form.value = {
    entity_id: 3,
    employee_id: 22,
    leave_type_id: 1,
    start_date: new Date().toISOString().slice(0, 10),
    end_date: new Date().toISOString().slice(0, 10),
    handover_employee_id: 14,
    is_half_day: false,
    reason: '',
    attachments: [],
    schedule: []
  };
  rebuildSchedule();
  showToast('Form cleared.');
};

const handleSaveDraft = () => {
  showMoreDropdown.value = false;
  showToast('Leave request saved as Draft.');
  isSaved.value = true;
};

const handleSubmit = () => {
  if (!form.value.start_date || !form.value.end_date) {
    showToast('Please select valid start and end dates.');
    return;
  }
  if (computedRequestedDays.value <= 0) {
    showToast('At least one day must be included in the request.');
    return;
  }
  isSaved.value = true;
  showToast('Leave request submitted successfully.');
  setTimeout(() => {
    router.push('/hr/leave-requests');
  }, 1000);
};

const handleFileUpload = (e: Event) => {
  const target = e.target as HTMLInputElement;
  if (target.files && target.files.length > 0) {
    const file = target.files[0];
    form.value.attachments.push({
      name: file.name,
      size: `${(file.size / 1024).toFixed(0)} KB`
    });
    showToast(`Attached ${file.name}`);
  }
};

const removeAttachment = (idx: number) => {
  form.value.attachments.splice(idx, 1);
};
</script>

<template>
  <div class="leave-create-page" @click="showMoreDropdown = false; activePortionRowIdx = null">
    <!-- ─── TOP BAR: Breadcrumb + Not Saved Badge + Action Buttons ─── -->
    <div class="top-nav-bar">
      <div class="breadcrumb-group">
        <AppBreadcrumb :items="breadcrumbItems" />
        <span :class="isSaved ? 'badge-saved' : 'badge-not-saved'">
          {{ isSaved ? 'Saved' : 'Not Saved' }}
        </span>
      </div>

      <div class="actions-group">
        <!-- Dynamic 3-Dots More Menu [ ⋮ ] (Draft Support per Rule 4) -->
        <div class="more-menu-wrapper" @click.stop>
          <button 
            type="button" 
            class="btn-more-options" 
            title="More actions"
            @click="showMoreDropdown = !showMoreDropdown"
          >
            <MoreVertical :size="16" />
          </button>

          <Transition name="dropdown-fade">
            <div v-if="showMoreDropdown" class="more-dropdown-menu">
              <button type="button" class="more-menu-item" @click="handleSaveDraft">
                <FileText :size="14" />
                <span>Save as Draft</span>
              </button>
            </div>
          </Transition>
        </div>

        <!-- Clear Form Secondary Button -->
        <button type="button" class="btn-clear-form" @click="handleClearForm">
          <X :size="14" />
          <span>Clear Form</span>
        </button>

        <!-- Save Primary Button -->
        <button type="button" class="btn-save-primary" @click="handleSubmit">
          <Save :size="14" />
          <span>Save</span>
        </button>
      </div>
    </div>

    <!-- Toast Notification -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- ─── TOP TABS: <BaseTabs /> Capsule Standard (Rule 1) ─── -->
    <div class="tabs-container">
      <BaseTabs 
        v-model="activeTab" 
        :tabs="tabs" 
      />
    </div>

    <!-- ─── TAB 1: LEAVE DETAIL ─── -->
    <div v-show="activeTab === 'details'" class="tab-content-stack">
      <!-- ════ MASTER FORM CARD (Card 1) ════ -->
      <div class="clean-card">
        <!-- Row 1: Select Entity * | Select Employee * (2-Column Grid) -->
        <div class="form-grid-2col">
          <FormSelect
            v-model="form.entity_id"
            label="Select Entity"
            :options="entityOptions"
            placeholder="Select Entity"
            :required="true"
          />

          <FormSelect
            v-model="form.employee_id"
            label="Select Employee"
            :options="employeeOptions"
            placeholder="Select Employee"
            :required="true"
          />
        </div>

        <!-- Row 2: Leave Type * | Start Date * | End Date * (3-Column Grid) -->
        <div class="form-grid-3col">
          <FormSelect
            v-model="form.leave_type_id"
            label="Leave Type"
            :options="leaveTypeOptions"
            placeholder="Select Type"
            :required="true"
          />

          <FormInput
            v-model="form.start_date"
            type="date"
            label="Start Date"
            :required="true"
            :icon="Calendar"
          >
            <template #suffix>
              <span class="gc-badge">GC</span>
            </template>
          </FormInput>

          <FormInput
            v-model="form.end_date"
            type="date"
            label="End Date"
            :required="true"
            :icon="Calendar"
          >
            <template #suffix>
              <span class="gc-badge">GC</span>
            </template>
          </FormInput>
        </div>

        <!-- Row 3: Hand Over Employee * (Left-aligned column) -->
        <div class="form-grid-2col">
          <FormSelect
            v-model="form.handover_employee_id"
            label="Hand Over Employee"
            :options="colleagueOptions"
            placeholder="Select Employee"
            :required="true"
          />
        </div>

        <!-- Half Day Checkbox Strip -->
        <div class="checkbox-row-wrapper">
          <FormCheckbox
            v-model="form.is_half_day"
            label="Half day Leave"
            description="Indicate whether this request applies only to morning or afternoon operational shift portion."
          />
        </div>

        <!-- ─── EMPLOYEE CARD: Active Leave Information & Balances ─── -->
        <div class="employee-leave-card">
          <!-- Left: Circular Avatar + Identity -->
          <div class="elc-identity-col">
            <img 
              :src="selectedEmployee.avatar" 
              :alt="selectedEmployee.name"
              class="elc-avatar-img"
            />
            <div class="elc-text-block">
              <span class="elc-name">{{ selectedEmployee.name }}</span>
              <div class="elc-meta-line">
                <span class="elc-code">{{ selectedEmployee.code }}</span>
                <span class="elc-sep">-</span>
                <span class="elc-role-pill">{{ selectedEmployee.position }}</span>
              </div>
            </div>
          </div>

          <!-- Right: Leave Balance Information necessary for leave request -->
          <div class="elc-metrics-col">
            <div class="elc-stat-box highlight-box">
              <span class="elc-stat-label">Available Balance</span>
              <span class="elc-stat-val text-brand-blue">{{ activeLeaveBalance.available_days.toFixed(1) }} Days</span>
            </div>

            <div class="elc-stat-divider"></div>

            <div class="elc-stat-box">
              <span class="elc-stat-label">Entitled</span>
              <span class="elc-stat-val">{{ activeLeaveBalance.entitled_days.toFixed(1) }} d</span>
            </div>

            <div class="elc-stat-box">
              <span class="elc-stat-label">Taken</span>
              <span class="elc-stat-val">{{ activeLeaveBalance.taken_days.toFixed(1) }} d</span>
            </div>

            <div class="elc-stat-box">
              <span class="elc-stat-label">In Review</span>
              <span class="elc-stat-val">{{ activeLeaveBalance.pending_days.toFixed(1) }} d</span>
            </div>
          </div>
        </div>
      </div>

      <!-- ════ CARD 2: ACCORDION - LEAVE DESCRIPTION / REASON ════ -->
      <div class="clean-card accordion-card">
        <!-- Accordion Header -->
        <div class="accordion-header" @click="isReasonOpen = !isReasonOpen">
          <div class="accordion-title-wrap">
            <span class="accordion-title-text">Leave Description / Reason</span>
            <ChevronDown :size="16" class="accordion-arrow" :class="{ 'rotate-180': isReasonOpen }" />
          </div>
        </div>

        <!-- Accordion Body -->
        <div v-show="isReasonOpen" class="accordion-body-content">
          <!-- Section 1: Supporting Document Required * -->
          <div class="evidence-block">
            <label class="field-title-label">
              Supporting Document Required <span class="required-asterisk">*</span>
            </label>

            <!-- File Upload Dropzone -->
            <div class="file-upload-dropzone" @click="$refs.fileInput.click()">
              <input 
                ref="fileInput" 
                type="file" 
                class="hidden-file-input" 
                @change="handleFileUpload" 
              />
              <UploadCloud :size="24" class="upload-icon-sky" />
              <div class="upload-prompt-text">
                <span class="text-blue-link">Click to upload</span> or drag and drop
              </div>
              <span class="upload-subtext">Picture files up to 10MB</span>
            </div>

            <!-- Uploaded Files Stack -->
            <div v-if="form.attachments.length > 0" class="attachments-list-stack">
              <div v-for="(att, idx) in form.attachments" :key="idx" class="attachment-item-row">
                <div class="att-meta">
                  <FileText :size="15" class="text-blue-600" />
                  <span class="att-name">{{ att.name }}</span>
                  <span class="att-size">({{ att.size }})</span>
                </div>
                <button type="button" class="btn-remove-att" @click="removeAttachment(idx)">
                  <Trash2 :size="14" />
                </button>
              </div>
            </div>
          </div>

          <!-- Section 2: Rich Text WYSIWYG Editor -->
          <div class="wysiwyg-editor-box">
            <!-- Toolbar -->
            <div class="wysiwyg-toolbar">
              <div class="toolbar-left-group">
                <button type="button" class="tb-select-btn">
                  <span>Paragraph</span>
                  <ChevronDown :size="12" />
                </button>
                <button type="button" class="tb-select-btn">
                  <span>Font Type</span>
                  <ChevronDown :size="12" />
                </button>
                <button type="button" class="tb-select-btn">
                  <List :size="13" />
                  <ChevronDown :size="11" />
                </button>

                <div class="tb-divider"></div>

                <button type="button" class="tb-btn" title="Bold"><b>B</b></button>
                <button type="button" class="tb-btn" title="Italic"><i>I</i></button>
                <button type="button" class="tb-btn" title="Underline"><Underline :size="13" /></button>
                <button type="button" class="tb-btn" title="Strikethrough"><Strikethrough :size="13" /></button>
                <button type="button" class="tb-btn" title="Code"><Code :size="13" /></button>
                <button type="button" class="tb-btn" title="Table"><Table :size="13" /></button>
                
                <div class="tb-divider"></div>

                <button type="button" class="tb-btn" title="Color"><Palette :size="13" /></button>
                <button type="button" class="tb-btn" title="Link"><Link2 :size="13" /></button>
                <button type="button" class="tb-btn" title="Image"><Image :size="13" /></button>
              </div>

              <div class="toolbar-right-group">
                <button type="button" class="tb-btn" title="Undo"><Undo2 :size="13" /></button>
                <button type="button" class="tb-btn" title="Redo"><Redo2 :size="13" /></button>
              </div>
            </div>

            <!-- Textarea Area -->
            <textarea 
              v-model="form.reason" 
              class="wysiwyg-textarea" 
              rows="5"
            />

            <!-- Editor Footer Counter -->
            <div class="wysiwyg-footer">
              <span class="char-counter-text">{{ form.reason.length }} / 5,000 Characters</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ─── TAB 2: DAY BREAKDOWN SCHEDULE (Image 2) ─── -->
    <div v-show="activeTab === 'schedule'" class="tab-content-stack">
      <div class="clean-card">
        <div class="schedule-header-box">
          <h4 class="schedule-title">Daily Breakdown Schedule (LeaveRequestDay)</h4>
          <p class="schedule-subtitle">Configure day-by-day portions and attendance debit values for each requested day.</p>
        </div>

        <div class="table-responsive-wrapper">
          <table class="schedule-table">
            <thead>
              <tr>
                <th style="width: 60px;">No.</th>
                <th style="width: 240px;">Date</th>
                <th style="width: 240px;">Day of the Week</th>
                <th>Shift Portion</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(day, idx) in form.schedule" :key="day.date">
                <td class="td-tertiary">{{ day.no }}</td>
                <td class="td-date-bold">{{ day.formatted_date }}</td>
                <td class="td-tertiary">{{ day.day_of_week }}</td>
                <td class="td-portion-cell" @click.stop>
                  <!-- Interactive Shift Portion Selector -->
                  <div class="portion-trigger-wrapper">
                    <button 
                      type="button" 
                      class="btn-portion-trigger"
                      @click="togglePortionPopover(idx)"
                    >
                      <span>{{ getPortionLabel(day.portion) }}</span>
                    </button>

                    <!-- Popover Dropdown matching Image 2 -->
                    <Transition name="popover-fade">
                      <div v-if="activePortionRowIdx === idx" class="portion-popover-menu">
                        <button 
                          type="button" 
                          class="portion-menu-option" 
                          :class="{ 'is-selected': day.portion === 'full' }"
                          @click="selectPortion(day, 'full')"
                        >
                          <span>Full Day</span>
                          <Check v-if="day.portion === 'full'" :size="14" class="portion-check-icon" />
                        </button>
                        <button 
                          type="button" 
                          class="portion-menu-option" 
                          :class="{ 'is-selected': day.portion === 'first_half' }"
                          @click="selectPortion(day, 'first_half')"
                        >
                          <span>First Half Day</span>
                          <Check v-if="day.portion === 'first_half'" :size="14" class="portion-check-icon" />
                        </button>
                        <button 
                          type="button" 
                          class="portion-menu-option" 
                          :class="{ 'is-selected': day.portion === 'second_half' }"
                          @click="selectPortion(day, 'second_half')"
                        >
                          <span>Second Half Day</span>
                          <Check v-if="day.portion === 'second_half'" :size="14" class="portion-check-icon" />
                        </button>
                      </div>
                    </Transition>
                  </div>
                </td>
              </tr>
              <tr v-if="form.schedule.length === 0">
                <td colspan="4" class="empty-state-row">
                  Select valid start and end dates to generate attendance schedule days.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.leave-create-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 20px 24px 80px 24px;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

/* Top Nav Bar */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 2px;
}

.breadcrumb-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.badge-not-saved {
  background-color: #fef3c7;
  color: #d97706;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 4px;
}

.badge-saved {
  background-color: #ecfdf5;
  color: #059669;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 4px;
}

.actions-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.more-menu-wrapper {
  position: relative;
}

.btn-more-options {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-more-options:hover {
  background-color: #f8fafc;
}

.more-dropdown-menu {
  position: absolute;
  top: 40px;
  right: 0;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  padding: 4px;
  min-width: 150px;
  z-index: 50;
}

.more-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 12px;
  border: none;
  background: transparent;
  font-size: 12.5px;
  color: #404040;
  cursor: pointer;
  border-radius: 6px;
  text-align: left;
}

.more-menu-item:hover {
  background-color: #f1f5f9;
}

.btn-clear-form {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding: 0 14px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  color: #404040;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-clear-form:hover {
  background-color: #f8fafc;
}

.btn-save-primary {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding: 0 18px;
  border-radius: 8px;
  border: none;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-save-primary:hover {
  background-color: #094380;
}

/* Toast */
.toast-bar {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background-color: #0B529C;
  color: #ffffff;
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  box-shadow: 0 4px 12px rgba(11, 82, 156, 0.2);
  align-self: flex-start;
}

/* Tabs */
.tabs-container {
  display: flex;
}

/* Content Stack */
.tab-content-stack {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* Clean Master Card */
.clean-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 22px 24px;
  display: flex;
  flex-direction: column;
  gap: 18px;
}

/* Form Grids */
.form-grid-2col {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 18px;
}

.form-grid-3col {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 18px;
}

@media (max-width: 900px) {
  .form-grid-3col, .form-grid-2col {
    grid-template-columns: 1fr;
  }
}

/* GC Badge inside Date inputs */
.gc-badge {
  font-size: 11px;
  font-weight: 600;
  color: #737373;
  background-color: #f1f5f9;
  border: 1px solid #e2e8f0;
  padding: 2px 6px;
  border-radius: 4px;
}

.checkbox-row-wrapper {
  padding-top: 2px;
}

/* ─── EMPLOYEE LEAVE CARD (Image 1 Bottom) ─── */
.employee-leave-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: #fafafa;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 18px;
  margin-top: 4px;
}

.elc-identity-col {
  display: flex;
  align-items: center;
  gap: 12px;
}

.elc-avatar-img {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  object-fit: cover;
  border: 1px solid #e2e8f0;
}

.elc-text-block {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.elc-name {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.elc-meta-line {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #737373;
}

.elc-sep {
  color: #cbd5e1;
}

.elc-role-pill {
  font-weight: 500;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  padding: 1px 8px;
  border-radius: 4px;
  font-size: 11.5px;
}

.elc-metrics-col {
  display: flex;
  align-items: center;
  gap: 16px;
}

.elc-stat-box {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
}

.elc-stat-label {
  font-size: 11px;
  color: #737373;
}

.elc-stat-val {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.highlight-box {
  align-items: flex-end;
}

.text-brand-blue {
  color: #0B529C !important;
  font-size: 13.5px;
}

.elc-stat-divider {
  width: 1px;
  height: 24px;
  background-color: #e2e8f0;
}

/* ─── CARD 2: ACCORDION SECTION ─── */
.accordion-card {
  padding: 0;
  overflow: hidden;
}

.accordion-header {
  padding: 16px 20px;
  cursor: pointer;
  user-select: none;
  background-color: #ffffff;
  transition: background-color 0.15s;
}

.accordion-header:hover {
  background-color: #f8fafc;
}

.accordion-title-wrap {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.accordion-title-text {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.accordion-arrow {
  color: #737373;
  transition: transform 0.2s;
}

.rotate-180 {
  transform: rotate(180deg);
}

.accordion-body-content {
  padding: 0 20px 20px 20px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Evidence Dropzone */
.evidence-block {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-title-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.required-asterisk {
  color: #ef4444;
}

.file-upload-dropzone {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 24px 16px;
  border: 1px dashed #cbd5e1;
  border-radius: 8px;
  background-color: #fafafa;
  cursor: pointer;
  transition: all 0.15s;
}

.file-upload-dropzone:hover {
  background-color: #f0f7ff;
  border-color: #0B529C;
}

.hidden-file-input {
  display: none;
}

.upload-icon-sky {
  color: #64748b;
}

.upload-prompt-text {
  font-size: 12.5px;
  color: #404040;
}

.text-blue-link {
  color: #0B529C;
  font-weight: 500;
}

.upload-subtext {
  font-size: 11px;
  color: #737373;
}

.attachments-list-stack {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-top: 4px;
}

.attachment-item-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
}

.att-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
}

.att-name {
  font-weight: 500;
  color: #0B529C;
}

.att-size {
  color: #94a3b8;
  font-size: 11px;
}

.btn-remove-att {
  background: transparent;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 2px;
}

.btn-remove-att:hover {
  color: #ef4444;
}

/* WYSIWYG Editor */
.wysiwyg-editor-box {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
}

.wysiwyg-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  background-color: #ffffff;
  border-bottom: 1px solid #e2e8f0;
}

.toolbar-left-group {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.toolbar-right-group {
  display: flex;
  align-items: center;
  gap: 4px;
}

.tb-select-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  height: 28px;
  padding: 0 8px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  border-radius: 4px;
  font-size: 12px;
  color: #404040;
  cursor: pointer;
}

.tb-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  background: transparent;
  border: none;
  border-radius: 4px;
  color: #475569;
  cursor: pointer;
  font-size: 12px;
}

.tb-btn:hover {
  background-color: #f1f5f9;
}

.tb-divider {
  width: 1px;
  height: 16px;
  background-color: #e2e8f0;
  margin: 0 2px;
}

.wysiwyg-textarea {
  width: 100%;
  border: none;
  outline: none;
  padding: 12px 14px;
  font-size: 13px;
  color: #404040;
  font-family: inherit;
  resize: vertical;
  min-height: 120px;
}

.wysiwyg-footer {
  display: flex;
  justify-content: flex-start;
  padding: 6px 14px;
  background-color: #ffffff;
}

.char-counter-text {
  font-size: 11.5px;
  color: #737373;
}

/* ─── TAB 2: DAILY BREAKDOWN SCHEDULE (Image 2) ─── */
.schedule-header-box {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.schedule-title {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.schedule-subtitle {
  margin: 0;
  font-size: 12px;
  color: #737373;
}

.table-responsive-wrapper {
  overflow-x: auto;
}

.schedule-table {
  width: 100%;
  border-collapse: collapse;
}

.schedule-table th {
  background-color: #fafafa;
  color: #737373;
  font-size: 12px;
  font-weight: 500;
  padding: 10px 14px;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

.schedule-table td {
  padding: 10px 14px;
  font-size: 13px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.td-date-bold {
  font-weight: 600;
  color: #404040;
}

.td-tertiary {
  color: #737373;
}

.td-portion-cell {
  position: relative;
}

.portion-trigger-wrapper {
  position: relative;
  display: inline-block;
  min-width: 140px;
}

.btn-portion-trigger {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  height: 32px;
  padding: 0 10px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  border-radius: 6px;
  font-size: 12.5px;
  color: #404040;
  cursor: pointer;
  text-align: left;
}

.btn-portion-trigger:hover {
  border-color: #cbd5e1;
}

/* Popover Menu matching Image 2 */
.portion-popover-menu {
  position: absolute;
  top: 36px;
  left: 0;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  padding: 4px;
  min-width: 160px;
  z-index: 50;
}

.portion-menu-option {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 8px 12px;
  border: none;
  background: transparent;
  font-size: 12.5px;
  color: #404040;
  cursor: pointer;
  border-radius: 6px;
  text-align: left;
}

.portion-menu-option:hover {
  background-color: #f1f5f9;
}

.portion-menu-option.is-selected {
  font-weight: 500;
}

.portion-check-icon {
  color: #0B529C;
}

.empty-state-row {
  text-align: center;
  padding: 24px;
  color: #737373;
  font-size: 12.5px;
}
</style>
