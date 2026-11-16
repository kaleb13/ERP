<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { Calendar, Plus, Edit2, Info } from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import UnderlineTabs from '../../components/UnderlineTabs.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import type { ColumnDef } from '../../components/BaseTable.vue';

const router = useRouter();

// ─── Breadcrumbs (Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'Work Calendar Setup' }
];

// ─── Schema Interfaces (HR_Schema_final-v4.sql lines 1271–1333) ───
export type CalendarDayType = 'working' | 'weekend' | 'holiday' | 'half_day';

export interface WorkCalendarRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  description?: string;
  entity_id: number | null;
  entity_name: string;
  fiscal_year_start_month: number; // 7 = July
  fiscal_year_start_day: number;   // 8 = Hamle 1
  week_start_day: number;          // 1 = Monday
  default_daily_hours: number;     // 8.00
  default_weekly_hours: number;    // 40.00 or 48.00
  payroll_days_per_month: number;  // 26.0 (statutory Ethiopian daily-rate divisor)
  is_default: boolean;
  is_system: boolean;
  state: 'active' | 'inactive';
}

export interface WorkCalendarWeekdayRecord {
  id: number;
  work_calendar_id: number;
  weekday: number; // ISO 1 = Mon .. 7 = Sun
  weekday_name: string;
  weekday_short: string;
  day_type: CalendarDayType;
  planned_hours: number;
  start_time: string;
  end_time: string;
}

export interface WorkCalendarDayRecord {
  id: number;
  work_calendar_id: number;
  date: string; // "YYYY-MM-DD"
  ethiopian_date_text: string;
  day_type: CalendarDayType;
  holiday_id?: number | null;
  holiday_name?: string | null;
  planned_hours: number;
  is_hand_edited: boolean;
}

// ─── Mock Data: WorkCalendar [REF] (Schema lines 1290–1296) ───
const calendars = ref<WorkCalendarRecord[]>([
  {
    id: 1,
    uuid: 'cal-uuid-001',
    code: 'CAL-OFFICE',
    name: 'Office Calendar',
    description: 'Standard 40-hour corporate headquarters working calendar with Saturday/Sunday rest.',
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    fiscal_year_start_month: 7,
    fiscal_year_start_day: 8,
    week_start_day: 1,
    default_daily_hours: 8.00,
    default_weekly_hours: 40.00,
    payroll_days_per_month: 26.0,
    is_default: true,
    is_system: false,
    state: 'active'
  },
  {
    id: 2,
    uuid: 'cal-uuid-002',
    code: 'CAL-RETAIL',
    name: 'Retail Calendar',
    description: '48-hour commercial branch calendar operating 6 working days (Mon–Sat) with Sunday rest.',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    fiscal_year_start_month: 7,
    fiscal_year_start_day: 8,
    week_start_day: 1,
    default_daily_hours: 8.00,
    default_weekly_hours: 48.00,
    payroll_days_per_month: 26.0,
    is_default: true,
    is_system: false,
    state: 'active'
  },
  {
    id: 3,
    uuid: 'cal-uuid-003',
    code: 'CAL-FACTORY',
    name: 'Factory Shift Calendar',
    description: 'Continuous industrial shift calendar operating across alternating production rosters.',
    entity_id: 9,
    entity_name: 'Hawassa Industrial Plant',
    fiscal_year_start_month: 7,
    fiscal_year_start_day: 8,
    week_start_day: 1,
    default_daily_hours: 8.00,
    default_weekly_hours: 48.00,
    payroll_days_per_month: 26.0,
    is_default: true,
    is_system: false,
    state: 'active'
  },
  {
    id: 4,
    uuid: 'cal-uuid-004',
    code: 'CAL-SHOP',
    name: 'Piazza Shop',
    description: 'Commercial shop calendar with split shift allowances.',
    entity_id: 12,
    entity_name: 'Piazza Boutique',
    fiscal_year_start_month: 7,
    fiscal_year_start_day: 8,
    week_start_day: 1,
    default_daily_hours: 8.00,
    default_weekly_hours: 48.00,
    payroll_days_per_month: 26.0,
    is_default: true,
    is_system: false,
    state: 'active'
  },
  {
    id: 5,
    uuid: 'cal-uuid-005',
    code: 'CAL-TPL-ETH',
    name: 'Ethiopia Template',
    description: 'Standard statutory benchmark calendar aligned to Ethiopian Proclamation No. 1156/2019.',
    entity_id: null,
    entity_name: 'Platform Template',
    fiscal_year_start_month: 7,
    fiscal_year_start_day: 8,
    week_start_day: 1,
    default_daily_hours: 8.00,
    default_weekly_hours: 48.00,
    payroll_days_per_month: 26.0,
    is_default: false,
    is_system: true,
    state: 'active'
  }
]);

// ─── Active Selected Calendar ───
const selectedCalendarId = ref<number>(1);
const selectedCalendar = computed(() => {
  return calendars.value.find(c => c.id === selectedCalendarId.value) || calendars.value[0];
});

const calendarSelectOptions = computed(() =>
  calendars.value.map(cal => ({
    value: cal.id,
    label: `${cal.name} (${cal.code})${cal.is_default ? ' · Default' : ''}`
  }))
);

const dayTypeOptions = [
  { value: 'working', label: 'Working Day' },
  { value: 'half_day', label: 'Half-Day' },
  { value: 'weekend', label: 'Weekend (Off)' }
];

// ─── Navigation Sub-Tabs (<UnderlineTabs>) ───
const activeSubTab = ref<'weekdays' | 'calendar_days' | 'all_calendars'>('weekdays');

const subTabs = computed(() => [
  { id: 'weekdays', label: 'Weekly Schedule (WorkCalendarWeekday)', count: 7 },
  { id: 'calendar_days', label: 'Calendar Days & Exceptions (WorkCalendarDay)', count: 31 },
  { id: 'all_calendars', label: 'All Calendars Directory (WorkCalendar)', count: calendars.value.length }
]);

// ─── Mock Data: WorkCalendarWeekday [LINE] (Schema lines 1307–1314) ───
const weekdaysMap = ref<Record<number, WorkCalendarWeekdayRecord[]>>({
  // CAL-OFFICE (40h: Mon-Fri 8h, Sat-Sun 0h)
  1: [
    { id: 11, work_calendar_id: 1, weekday: 1, weekday_name: 'Monday',    weekday_short: 'MON', day_type: 'working', planned_hours: 8.0, start_time: '08:30', end_time: '17:30' },
    { id: 12, work_calendar_id: 1, weekday: 2, weekday_name: 'Tuesday',   weekday_short: 'TUE', day_type: 'working', planned_hours: 8.0, start_time: '08:30', end_time: '17:30' },
    { id: 13, work_calendar_id: 1, weekday: 3, weekday_name: 'Wednesday', weekday_short: 'WED', day_type: 'working', planned_hours: 8.0, start_time: '08:30', end_time: '17:30' },
    { id: 14, work_calendar_id: 1, weekday: 4, weekday_name: 'Thursday',  weekday_short: 'THU', day_type: 'working', planned_hours: 8.0, start_time: '08:30', end_time: '17:30' },
    { id: 15, work_calendar_id: 1, weekday: 5, weekday_name: 'Friday',    weekday_short: 'FRI', day_type: 'working', planned_hours: 8.0, start_time: '08:30', end_time: '17:30' },
    { id: 16, work_calendar_id: 1, weekday: 6, weekday_name: 'Saturday',  weekday_short: 'SAT', day_type: 'weekend', planned_hours: 0.0, start_time: '',      end_time: '' },
    { id: 17, work_calendar_id: 1, weekday: 7, weekday_name: 'Sunday',    weekday_short: 'SUN', day_type: 'weekend', planned_hours: 0.0, start_time: '',      end_time: '' }
  ],
  // CAL-RETAIL (48h: Mon-Sat 8h, Sun 0h)
  2: [
    { id: 21, work_calendar_id: 2, weekday: 1, weekday_name: 'Monday',    weekday_short: 'MON', day_type: 'working', planned_hours: 8.0, start_time: '08:00', end_time: '17:00' },
    { id: 22, work_calendar_id: 2, weekday: 2, weekday_name: 'Tuesday',   weekday_short: 'TUE', day_type: 'working', planned_hours: 8.0, start_time: '08:00', end_time: '17:00' },
    { id: 23, work_calendar_id: 2, weekday: 3, weekday_name: 'Wednesday', weekday_short: 'WED', day_type: 'working', planned_hours: 8.0, start_time: '08:00', end_time: '17:00' },
    { id: 24, work_calendar_id: 2, weekday: 4, weekday_name: 'Thursday',  weekday_short: 'THU', day_type: 'working', planned_hours: 8.0, start_time: '08:00', end_time: '17:00' },
    { id: 25, work_calendar_id: 2, weekday: 5, weekday_name: 'Friday',    weekday_short: 'FRI', day_type: 'working', planned_hours: 8.0, start_time: '08:00', end_time: '17:00' },
    { id: 26, work_calendar_id: 2, weekday: 6, weekday_name: 'Saturday',  weekday_short: 'SAT', day_type: 'working', planned_hours: 8.0, start_time: '08:00', end_time: '17:00' },
    { id: 27, work_calendar_id: 2, weekday: 7, weekday_name: 'Sunday',    weekday_short: 'SUN', day_type: 'weekend', planned_hours: 0.0, start_time: '',      end_time: '' }
  ],
  // CAL-FACTORY (48h: Mon-Fri 8h, Sat half_day 4h, Sun weekend)
  3: [
    { id: 31, work_calendar_id: 3, weekday: 1, weekday_name: 'Monday',    weekday_short: 'MON', day_type: 'working', planned_hours: 8.0, start_time: '07:00', end_time: '15:30' },
    { id: 32, work_calendar_id: 3, weekday: 2, weekday_name: 'Tuesday',   weekday_short: 'TUE', day_type: 'working', planned_hours: 8.0, start_time: '07:00', end_time: '15:30' },
    { id: 33, work_calendar_id: 3, weekday: 3, weekday_name: 'Wednesday', weekday_short: 'WED', day_type: 'working', planned_hours: 8.0, start_time: '07:00', end_time: '15:30' },
    { id: 34, work_calendar_id: 3, weekday: 4, weekday_name: 'Thursday',  weekday_short: 'THU', day_type: 'working', planned_hours: 8.0, start_time: '07:00', end_time: '15:30' },
    { id: 35, work_calendar_id: 3, weekday: 5, weekday_name: 'Friday',    weekday_short: 'FRI', day_type: 'working', planned_hours: 8.0, start_time: '07:00', end_time: '15:30' },
    { id: 36, work_calendar_id: 3, weekday: 6, weekday_name: 'Saturday',  weekday_short: 'SAT', day_type: 'half_day', planned_hours: 4.0, start_time: '07:00', end_time: '11:00' },
    { id: 37, work_calendar_id: 3, weekday: 7, weekday_name: 'Sunday',    weekday_short: 'SUN', day_type: 'weekend', planned_hours: 0.0, start_time: '',      end_time: '' }
  ]
});

const currentWeekdays = computed(() => {
  return weekdaysMap.value[selectedCalendarId.value] || weekdaysMap.value[1];
});

// Update day type inline
const updateDayType = (weekdayItem: WorkCalendarWeekdayRecord, newType: CalendarDayType) => {
  weekdayItem.day_type = newType;
  if (newType === 'working') {
    weekdayItem.planned_hours = 8.0;
    weekdayItem.start_time = '08:30';
    weekdayItem.end_time = '17:30';
  } else if (newType === 'half_day') {
    weekdayItem.planned_hours = 4.0;
    weekdayItem.start_time = '08:30';
    weekdayItem.end_time = '12:30';
  } else {
    weekdayItem.planned_hours = 0.0;
    weekdayItem.start_time = '';
    weekdayItem.end_time = '';
  }
};

// ─── Mock Data: WorkCalendarDay [LINE] for July 2026 (Hamle 2018 E.C.) ───
// Schema lines 1326–1333: generated per year, then hand-edited
const calendarDays = ref<WorkCalendarDayRecord[]>([
  // Week 1 (July 1 to 5)
  { id: 9001, work_calendar_id: 1, date: '2026-07-01', ethiopian_date_text: 'ሰኔ 24', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9002, work_calendar_id: 1, date: '2026-07-02', ethiopian_date_text: 'ሰኔ 25', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9003, work_calendar_id: 1, date: '2026-07-03', ethiopian_date_text: 'ሰኔ 26', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9004, work_calendar_id: 1, date: '2026-07-04', ethiopian_date_text: 'ሰኔ 27', day_type: 'weekend', planned_hours: 0.0, is_hand_edited: false },
  { id: 9005, work_calendar_id: 1, date: '2026-07-05', ethiopian_date_text: 'ሰኔ 28', day_type: 'weekend', planned_hours: 0.0, is_hand_edited: false },

  // Week 2 (July 6 to 12) - July 8 = Hamle 1 (Ethiopian FY Start)
  { id: 9006, work_calendar_id: 1, date: '2026-07-06', ethiopian_date_text: 'ሰኔ 29', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9007, work_calendar_id: 1, date: '2026-07-07', ethiopian_date_text: 'ሰኔ 30', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9008, work_calendar_id: 1, date: '2026-07-08', ethiopian_date_text: 'ሐምሌ 01', day_type: 'working', planned_hours: 8.0, is_hand_edited: true, holiday_name: 'Ethiopian FY Start (Hamle 1)' },
  { id: 9009, work_calendar_id: 1, date: '2026-07-09', ethiopian_date_text: 'ሐምሌ 02', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9010, work_calendar_id: 1, date: '2026-07-10', ethiopian_date_text: 'ሐምሌ 03', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9011, work_calendar_id: 1, date: '2026-07-11', ethiopian_date_text: 'ሐምሌ 04', day_type: 'weekend', planned_hours: 0.0, is_hand_edited: false },
  { id: 9012, work_calendar_id: 1, date: '2026-07-12', ethiopian_date_text: 'ሐምሌ 05', day_type: 'weekend', planned_hours: 0.0, is_hand_edited: false },

  // Week 3 (July 13 to 19)
  { id: 9013, work_calendar_id: 1, date: '2026-07-13', ethiopian_date_text: 'ሐምሌ 06', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9014, work_calendar_id: 1, date: '2026-07-14', ethiopian_date_text: 'ሐምሌ 07', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9015, work_calendar_id: 1, date: '2026-07-15', ethiopian_date_text: 'ሐምሌ 08', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9016, work_calendar_id: 1, date: '2026-07-16', ethiopian_date_text: 'ሐምሌ 09', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9017, work_calendar_id: 1, date: '2026-07-17', ethiopian_date_text: 'ሐምሌ 10', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9018, work_calendar_id: 1, date: '2026-07-18', ethiopian_date_text: 'ሐምሌ 11', day_type: 'weekend', planned_hours: 0.0, is_hand_edited: false },
  { id: 9019, work_calendar_id: 1, date: '2026-07-19', ethiopian_date_text: 'ሐምሌ 12', day_type: 'weekend', planned_hours: 0.0, is_hand_edited: false },

  // Week 4 (July 20 to 26)
  { id: 9020, work_calendar_id: 1, date: '2026-07-20', ethiopian_date_text: 'ሐምሌ 13', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9021, work_calendar_id: 1, date: '2026-07-21', ethiopian_date_text: 'ሐምሌ 14', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9022, work_calendar_id: 1, date: '2026-07-22', ethiopian_date_text: 'ሐምሌ 15', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9023, work_calendar_id: 1, date: '2026-07-23', ethiopian_date_text: 'ሐምሌ 16', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9024, work_calendar_id: 1, date: '2026-07-24', ethiopian_date_text: 'ሐምሌ 17', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9025, work_calendar_id: 1, date: '2026-07-25', ethiopian_date_text: 'ሐምሌ 18', day_type: 'weekend', planned_hours: 0.0, is_hand_edited: false },
  { id: 9026, work_calendar_id: 1, date: '2026-07-26', ethiopian_date_text: 'ሐምሌ 19', day_type: 'weekend', planned_hours: 0.0, is_hand_edited: false },

  // Week 5 (July 27 to 31)
  { id: 9027, work_calendar_id: 1, date: '2026-07-27', ethiopian_date_text: 'ሐምሌ 20', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9028, work_calendar_id: 1, date: '2026-07-28', ethiopian_date_text: 'ሐምሌ 21', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9029, work_calendar_id: 1, date: '2026-07-29', ethiopian_date_text: 'ሐምሌ 22', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9030, work_calendar_id: 1, date: '2026-07-30', ethiopian_date_text: 'ሐምሌ 23', day_type: 'working', planned_hours: 8.0, is_hand_edited: false },
  { id: 9031, work_calendar_id: 1, date: '2026-07-31', ethiopian_date_text: 'ሐምሌ 24', day_type: 'holiday', planned_hours: 0.0, is_hand_edited: true, holiday_id: 5, holiday_name: 'Company Sports Day' }
]);

// ─── Interactive Date Override Modal (WorkCalendarDay hand-edit) ───
const showEditDayModal = ref(false);
const editingDay = ref<WorkCalendarDayRecord | null>(null);
const editDayForm = ref({
  day_type: 'working' as CalendarDayType,
  planned_hours: 8.0,
  holiday_name: ''
});

const openEditDayModal = (day: WorkCalendarDayRecord) => {
  editingDay.value = day;
  editDayForm.value = {
    day_type: day.day_type,
    planned_hours: day.planned_hours,
    holiday_name: day.holiday_name || ''
  };
  showEditDayModal.value = true;
};

const handleSaveDayOverride = () => {
  if (!editingDay.value) return;
  editingDay.value.day_type = editDayForm.value.day_type;
  editingDay.value.planned_hours = Number(editDayForm.value.planned_hours);
  editingDay.value.holiday_name = editDayForm.value.holiday_name || null;
  editingDay.value.is_hand_edited = true;
  showEditDayModal.value = false;
};

// ─── All Calendars Directory Table Columns ───
const tableColumns = ref<ColumnDef[]>([
  { key: 'name', label: 'Calendar Name', visible: true, sortable: true },
  { key: 'entity', label: 'Owning Entity', visible: true, sortable: true },
  { key: 'weekly_hours', label: 'Weekly Hours', visible: true, sortable: true },
  { key: 'payroll_days', label: 'Payroll Days/Mo', visible: true, sortable: true },
  { key: 'fy_start', label: 'FY Start', visible: true, sortable: false },
  { key: 'is_default', label: 'Default', visible: true, sortable: false },
  { key: 'state', label: 'State', visible: true, sortable: true },
  { key: 'actions', label: 'Actions', visible: true, sortable: false }
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

const searchQuery = ref('');
const currentPage = ref(1);
const perPage = ref(10);

const filteredCalendars = computed(() => {
  let list = calendars.value;
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase();
    list = list.filter(c => c.name.toLowerCase().includes(q) || c.code.toLowerCase().includes(q) || c.entity_name.toLowerCase().includes(q));
  }
  return list;
});
</script>

<template>
  <div class="work-calendars-page">
    <!-- Breadcrumb Standard (Exact Page Name Only) -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Master Unified Card -->
    <div class="main-calendar-card">
      <!-- Calendar Switcher & Policy Summary Header -->
      <div class="calendar-switcher-header">
        <div class="switcher-left-group">
          <!-- Calendar Selector Dropdown -->
          <div class="calendar-selector-box">
            <FormSelect
              v-model="selectedCalendarId"
              label="ACTIVE WORK CALENDAR"
              :options="calendarSelectOptions"
              placeholder="Select active calendar"
            />
          </div>

          <!-- Entity & Default Badges -->
          <div class="calendar-meta-tags">
            <span v-if="selectedCalendar.is_default" class="badge-default">Default Calendar</span>
            <span class="meta-entity-text">{{ selectedCalendar.entity_name }}</span>
          </div>
        </div>

        <!-- Right Side: Statutory Metrics & Primary Action -->
        <div class="switcher-right-group">
          <div class="policy-pill-group">
            <div class="policy-stat-item">
              <span class="p-label">Weekly Hours</span>
              <span class="p-value">{{ selectedCalendar.default_weekly_hours.toFixed(2) }} hrs</span>
            </div>
            <div class="policy-stat-divider"></div>
            <div class="policy-stat-item">
              <span class="p-label">Payroll Divisor</span>
              <span class="p-value text-blue-700">{{ selectedCalendar.payroll_days_per_month }} Days/mo</span>
            </div>
            <div class="policy-stat-divider"></div>
            <div class="policy-stat-item">
              <span class="p-label">FY Start</span>
              <span class="p-value">Hamle 1 (Jul 8)</span>
            </div>
          </div>

          <!-- Primary Create Calendar Action (AppButton Primary Pill) -->
          <AppButton 
            variant="primary"
            size="sm"
            @click="router.push('/hr/work-calendars/create')"
          >
            <template #icon-left>
              <Plus :size="15" />
            </template>
            Create Calendar
          </AppButton>
        </div>
      </div>

      <!-- Secondary Sub-Navigation Tabs (<UnderlineTabs>) -->
      <div class="tabs-subnav-row">
        <UnderlineTabs 
          v-model="activeSubTab" 
          :tabs="subTabs" 
        />
      </div>

      <!-- ============================================================== -->
      <!-- TAB 1: WEEKLY STANDARD HOURS (WorkCalendarWeekday [LINE])       -->
      <!-- ============================================================== -->
      <div v-show="activeSubTab === 'weekdays'" class="tab-view-container">
        <div class="section-lead-block">
          <h3 class="section-heading">Weekly Working Time Blueprint</h3>
          <p class="section-subtext">Baseline Monday-through-Sunday classification and planned hours applied when expanding calendar dates.</p>
        </div>

        <!-- 7-Day Horizontal Weekday Cards -->
        <div class="weekdays-7-grid">
          <div 
            v-for="wd in currentWeekdays" 
            :key="wd.weekday"
            class="weekday-day-card"
            :class="`type-${wd.day_type}`"
          >
            <div class="card-day-top">
              <span class="day-short-badge">{{ wd.weekday_short }}</span>
              <span class="day-full-name">{{ wd.weekday_name }}</span>
            </div>

            <!-- Day Type Selector -->
            <div class="day-type-selector-wrapper">
              <FormSelect
                :model-value="wd.day_type"
                :options="dayTypeOptions"
                variant="cell"
                @update:model-value="(val) => updateDayType(wd, val as CalendarDayType)"
              />
            </div>

            <!-- Planned Hours & Schedule Window -->
            <div class="card-hours-info">
              <span class="hours-huge">{{ wd.planned_hours.toFixed(2) }}<span class="hrs-unit">h</span></span>
              <span v-if="wd.start_time" class="window-sub">{{ wd.start_time }} – {{ wd.end_time }}</span>
              <span v-else class="window-sub text-slate-400">Scheduled Rest</span>
            </div>
          </div>
        </div>

        <!-- Statutory Notice Footer Strip -->
        <div class="statutory-notice-strip">
          <div class="statutory-left">
            <Info :size="15" class="text-blue-600 shrink-0" />
            <span class="notice-text">
              <strong>Statutory Daily Rate Formula:</strong> Ethiopian Labour Proclamation No. 1156/2019 stipulates dividing monthly basic wage by <strong>26.0 days</strong> to derive daily remuneration for absence deductions and proration.
            </span>
          </div>
          <div class="statutory-right">
            <span class="stat-calc-pill">Planned: {{ currentWeekdays.reduce((acc, d) => acc + d.planned_hours, 0) }}.00 hrs/wk</span>
          </div>
        </div>
      </div>

      <!-- ============================================================== -->
      <!-- TAB 2: CALENDAR DAYS & EXCEPTIONS (WorkCalendarDay [LINE])      -->
      <!-- ============================================================== -->
      <div v-show="activeSubTab === 'calendar_days'" class="tab-view-container">
        <!-- Month Navigation Bar -->
        <div class="month-controls-row">
          <div class="month-title-group">
            <h3 class="month-title">July 2026</h3>
            <span class="eth-month-tag">ሐምሌ 2018 E.C. (Ethiopian FY Start)</span>
          </div>

          <!-- Legend Filters -->
          <div class="calendar-legend-filters">
            <span class="legend-badge badge-work">
              <span class="dot dot-blue"></span> Working (22)
            </span>
            <span class="legend-badge badge-off">
              <span class="dot dot-slate"></span> Weekend (8)
            </span>
            <span class="legend-badge badge-hol">
              <span class="dot dot-amber"></span> Holidays (1)
            </span>
          </div>
        </div>

        <!-- 7-Column Minimalist Month Grid -->
        <div class="month-calendar-grid">
          <!-- Weekday Headers -->
          <div class="grid-header-cell">MON</div>
          <div class="grid-header-cell">TUE</div>
          <div class="grid-header-cell">WED</div>
          <div class="grid-header-cell">THU</div>
          <div class="grid-header-cell">FRI</div>
          <div class="grid-header-cell text-slate-500">SAT</div>
          <div class="grid-header-cell text-slate-500">SUN</div>

          <!-- Day Cells (WorkCalendarDay) -->
          <div 
            v-for="day in calendarDays" 
            :key="day.id"
            class="calendar-date-cell"
            :class="[
              `cell-${day.day_type}`,
              { 'cell-edited': day.is_hand_edited }
            ]"
            @click="openEditDayModal(day)"
            title="Click to hand-edit day classification"
          >
            <!-- Top Row: Gregorian Date + Ethiopian Date -->
            <div class="cell-top-numbers">
              <span class="gregorian-num">{{ new Date(day.date + 'T00:00:00').getDate() }}</span>
              <span class="ethiopian-num">{{ day.ethiopian_date_text }}</span>
            </div>

            <!-- Bottom Content: Hours & Holiday Pill -->
            <div class="cell-bottom-info">
              <template v-if="day.day_type === 'working'">
                <span class="hours-tag">{{ day.planned_hours }}h Work</span>
              </template>
              <template v-else-if="day.day_type === 'weekend'">
                <span class="weekend-tag">Off</span>
              </template>
              <template v-else-if="day.day_type === 'holiday'">
                <span class="holiday-pill" :title="day.holiday_name || 'Holiday'">
                  {{ day.holiday_name || 'Holiday' }}
                </span>
              </template>

              <!-- Hand Edited Indicator -->
              <span v-if="day.is_hand_edited" class="hand-edit-dot" title="Hand-edited date exception">• Edited</span>
            </div>
          </div>
        </div>
      </div>

      <!-- ============================================================== -->
      <!-- TAB 3: ALL WORK CALENDARS DIRECTORY (WorkCalendar [REF])        -->
      <!-- ============================================================== -->
      <div v-show="activeSubTab === 'all_calendars'" class="tab-view-container p-0">
        <AppDataTable
          title="Work Calendars"
          subtitle="Directory of organizational work calendars, weekly standard hours, and statutory payroll divisors."
          :columns="tableColumns"
          v-model:searchQuery="searchQuery"
          v-model:currentPage="currentPage"
          v-model:perPage="perPage"
          :totalEntries="filteredCalendars.length"
          :showPagination="true"
          @toggleColumn="handleToggleColumn"
        >
          <template #actions>
            <AppButton variant="primary" size="sm" @click="router.push('/hr/work-calendars/create')">
              <template #icon-left>
                <Plus :size="15" />
              </template>
              Create Calendar
            </AppButton>
          </template>

          <template #default>
            <div class="directory-table-responsive">
              <table class="erp-table">
                <thead>
                  <tr>
                    <th v-if="isColVisible('name')" class="th-name">Calendar Name</th>
                    <th v-if="isColVisible('entity')">Owning Entity</th>
                    <th v-if="isColVisible('weekly_hours')">Weekly Hours</th>
                    <th v-if="isColVisible('payroll_days')">Payroll Divisor</th>
                    <th v-if="isColVisible('fy_start')">Fiscal Year Start</th>
                    <th v-if="isColVisible('is_default')">Default</th>
                    <th v-if="isColVisible('state')">State</th>
                    <th class="th-actions">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <tr 
                    v-for="cal in filteredCalendars" 
                    :key="cal.id"
                    class="erp-table-row"
                    :class="{ 'row-active-calendar': selectedCalendarId === cal.id }"
                    @click="selectedCalendarId = cal.id; activeSubTab = 'weekdays'"
                  >
                    <!-- Name & Code -->
                    <td class="td-name">
                      <div class="name-cell-wrapper">
                        <span class="table-name-primary">{{ cal.name }}</span>
                        <span class="table-code-subtext">{{ cal.code }}</span>
                      </div>
                    </td>

                    <!-- Entity -->
                    <td class="td-tertiary">
                      <span class="plain-cell-text">{{ cal.entity_name }}</span>
                    </td>

                    <!-- Weekly Hours -->
                    <td class="td-tertiary">
                      <span class="font-medium text-slate-700">{{ cal.default_weekly_hours.toFixed(2) }} hrs/wk</span>
                    </td>

                    <!-- Payroll Divisor -->
                    <td class="td-tertiary">
                      <span class="plain-cell-text">{{ cal.payroll_days_per_month }} Days/mo</span>
                    </td>

                    <!-- FY Start -->
                    <td class="td-tertiary">
                      <span class="plain-cell-text">Hamle 1 (Jul 8)</span>
                    </td>

                    <!-- Default Pill -->
                    <td>
                      <span v-if="cal.is_default" class="badge-default-mini">Default</span>
                      <span v-else class="plain-cell-text">—</span>
                    </td>

                    <!-- State -->
                    <td>
                      <span class="status-pill status-active">Active</span>
                    </td>

                    <!-- Actions -->
                    <td class="td-actions" @click.stop>
                      <button 
                        type="button" 
                        class="btn-action-dots"
                        @click="router.push(`/hr/work-calendars/${cal.id}`)"
                        title="Edit Calendar"
                      >
                        <Edit2 :size="14" />
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </template>
        </AppDataTable>
      </div>
    </div>

    <!-- Hand-Edit Calendar Date Modal (WorkCalendarDay [LINE]) -->
    <QuickCreateModal
      :show="showEditDayModal"
      :title="`Edit Calendar Date — ${editingDay?.date}`"
      @close="showEditDayModal = false"
      @save="handleSaveDayOverride"
    >
      <div class="day-edit-form">
        <FormSelect
          v-model="editDayForm.day_type"
          label="Day Classification"
          placeholder="Select"
          :options="[
            { value: 'working', label: 'Working Day (Standard Hours)' },
            { value: 'weekend', label: 'Weekend / Rest Day (0 Hours)' },
            { value: 'holiday', label: 'Public / Company Holiday' },
            { value: 'half_day', label: 'Half-Day Working' }
          ]"
        />

        <FormInput
          v-model="editDayForm.planned_hours"
          label="Planned Working Hours"
          type="number"
          step="0.5"
          required
        />

        <FormInput
          v-if="editDayForm.day_type === 'holiday'"
          v-model="editDayForm.holiday_name"
          label="Holiday Title / Observance Reason"
        />
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.work-calendars-page {
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

/* Master Card */
.main-calendar-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

/* Calendar Switcher & Header Bar */
.calendar-switcher-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid #e2e8f0;
  background: #ffffff;
  gap: 1.5rem;
  flex-wrap: wrap;
}

.switcher-left-group {
  display: flex;
  align-items: center;
  gap: 1.25rem;
  flex-wrap: wrap;
}

.calendar-selector-box {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.selector-micro-label {
  font-size: 10.5px;
  font-weight: 700;
  letter-spacing: 0.05em;
  color: #737373;
}

.calendar-select-dropdown {
  height: 38px;
  padding: 0 12px;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  background-color: #f8fafc;
  outline: none;
  cursor: pointer;
  transition: all 0.15s ease;
}

.calendar-select-dropdown:focus {
  border-color: #0B529C;
  background-color: #ffffff;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.calendar-meta-tags {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.badge-default {
  font-size: 11px;
  font-weight: 600;
  padding: 3px 8px;
  border-radius: 6px;
  background-color: #ecfdf5;
  color: #059669;
}

.badge-default-mini {
  font-size: 11px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 4px;
  background-color: #ecfdf5;
  color: #059669;
}

.meta-entity-text {
  font-size: 12.5px;
  color: #737373;
}

.switcher-right-group {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
}

.policy-pill-group {
  display: flex;
  align-items: center;
  gap: 1rem;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 6px 14px;
  border-radius: 8px;
}

.policy-stat-item {
  display: flex;
  flex-direction: column;
}

.p-label {
  font-size: 10px;
  color: #737373;
  text-transform: uppercase;
}

.p-value {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
}

.policy-stat-divider {
  width: 1px;
  height: 24px;
  background: #e2e8f0;
}

.btn-create-calendar {
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

.btn-create-calendar:hover {
  background-color: #09427d;
}

/* Tabs Subnav */
.tabs-subnav-row {
  padding: 0 1.5rem;
  border-bottom: 1px solid #f1f5f9;
}

.tab-view-container {
  padding: 1.5rem;
}

.section-lead-block {
  margin-bottom: 1.25rem;
}

.section-heading {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 2px 0;
}

.section-subtext {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* 7-Day Weekday Cards */
.weekdays-7-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.875rem;
  margin-bottom: 1.25rem;
}

@media (max-width: 1100px) {
  .weekdays-7-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.weekday-day-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1rem 0.875rem;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 0.75rem;
  transition: all 0.15s ease;
}

.weekday-day-card:hover {
  border-color: #cbd5e1;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
}

.weekday-day-card.type-working {
  border-top: 3px solid #0B529C;
}

.weekday-day-card.type-weekend {
  border-top: 3px solid #94a3b8;
  background: #fafafa;
}

.weekday-day-card.type-half_day {
  border-top: 3px solid #f59e0b;
}

.card-day-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.day-short-badge {
  font-size: 11px;
  font-weight: 700;
  color: #737373;
}

.day-full-name {
  font-size: 11px;
  color: #94a3b8;
}

.day-type-inline-select {
  width: 100%;
  height: 28px;
  font-size: 11px;
  font-weight: 600;
  border-radius: 6px;
  padding: 0 6px;
  border: 1px solid #cbd5e1;
  background: #ffffff;
  outline: none;
  cursor: pointer;
}

.select-working {
  background-color: #f0f7ff;
  color: #0369a1;
  border-color: #bae6fd;
}

.select-weekend {
  background-color: #f1f5f9;
  color: #64748b;
  border-color: #e2e8f0;
}

.select-half_day {
  background-color: #fef3c7;
  color: #b45309;
  border-color: #fde68a;
}

.card-hours-info {
  display: flex;
  flex-direction: column;
}

.hours-huge {
  font-size: 20px;
  font-weight: 700;
  color: #404040;
}

.hrs-unit {
  font-size: 13px;
  font-weight: 500;
  color: #737373;
}

.window-sub {
  font-size: 11px;
  color: #737373;
}

/* Statutory Notice Strip */
.statutory-notice-strip {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #f0f7ff;
  border: 1px solid #bae6fd;
  border-radius: 8px;
  padding: 0.875rem 1.25rem;
  gap: 1rem;
}

.statutory-left {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.notice-text {
  font-size: 12.5px;
  color: #0369a1;
  line-height: 1.45;
}

.stat-calc-pill {
  font-size: 12px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 6px;
  background: #ffffff;
  color: #0B529C;
  border: 1px solid #bae6fd;
  white-space: nowrap;
}

/* Month Calendar View */
.month-controls-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.25rem;
}

.month-title-group {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.month-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.eth-month-tag {
  font-size: 12px;
  color: #0B529C;
  background: #eff6ff;
  padding: 2px 8px;
  border-radius: 4px;
  font-weight: 500;
}

.calendar-legend-filters {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.legend-badge {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 12px;
  color: #737373;
}

.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.dot-blue { background: #0B529C; }
.dot-slate { background: #94a3b8; }
.dot-amber { background: #f59e0b; }

.month-calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  overflow: hidden;
}

.grid-header-cell {
  background: #fafafa;
  padding: 8px;
  text-align: center;
  font-size: 11px;
  font-weight: 600;
  color: #737373;
  border-bottom: 1px solid #e2e8f0;
}

.calendar-date-cell {
  min-height: 82px;
  padding: 8px;
  border-right: 1px solid #f1f5f9;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  cursor: pointer;
  transition: all 0.15s ease;
}

.calendar-date-cell:nth-child(7n) {
  border-right: none;
}

.calendar-date-cell:hover {
  background-color: #f0f7ff;
}

.cell-working {
  background-color: #ffffff;
}

.cell-weekend {
  background-color: #fafafa;
}

.cell-holiday {
  background-color: #fffbeb;
}

.cell-top-numbers {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.gregorian-num {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.ethiopian-num {
  font-size: 10.5px;
  color: #94a3b8;
}

.cell-bottom-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.hours-tag {
  font-size: 10.5px;
  color: #0B529C;
  font-weight: 500;
}

.weekend-tag {
  font-size: 10.5px;
  color: #94a3b8;
}

.holiday-pill {
  font-size: 10px;
  font-weight: 600;
  background: #fef3c7;
  color: #b45309;
  padding: 1px 4px;
  border-radius: 3px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.hand-edit-dot {
  font-size: 9px;
  color: #0B529C;
  font-weight: 600;
}

/* Table */
.directory-table-responsive {
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

.erp-table-row {
  cursor: pointer;
}

.erp-table-row:hover {
  background-color: #f8fafc;
}

.row-active-calendar {
  background-color: #f0f7ff;
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

.th-actions, .td-actions {
  width: 50px;
  text-align: right;
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

.day-edit-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
