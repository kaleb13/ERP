<script setup lang="ts">
import { ref, computed } from 'vue';
import {
  Calendar as CalendarIcon, Clock, ChevronLeft, ChevronRight, ChevronDown,
  Monitor, FileText, ShieldCheck, Briefcase
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import CalendarSidebar from '../../components/CalendarSidebar.vue';
import FormSelect from '../../components/FormSelect.vue';

// ─── Breadcrumbs (Aligned with Figma 6328:119446: Monitor icon > Work Calendar) ───
const breadcrumbItems = [
  { label: 'Work Calendar' }
];

// ─── View Modes (Figma Tab Rounded Group: Month | Week | List) ───
// By default, the calendar opens in Month view as requested
type CalendarViewMode = 'week' | 'month' | 'list';
const currentView = ref<CalendarViewMode>('month');

const viewModes: { id: CalendarViewMode; label: string }[] = [
  { id: 'month', label: 'Month' },
  { id: 'week', label: 'Week' },
  { id: 'list', label: 'List' }
];

// ─── Work Calendars (HR_Schema_final-v4.sql Section 4, lines 1271–1297) ───
export interface CompanyCalendar {
  id: number;
  code: string;
  name: string;
  entityName: string;
  dailyHours: number;
  weeklyHours: number;
  payrollDaysPerMonth: number;
  restDays: number[]; // 0 = Sunday, 6 = Saturday
  halfDays: number[];
  shiftStart: string;
  shiftEnd: string;
  breakMinutes: number;
  graceInMinutes: number;
  graceOutMinutes: number;
}

const companyCalendars: CompanyCalendar[] = [
  {
    id: 1,
    code: 'CAL-OFFICE',
    name: 'Office Calendar',
    entityName: 'Haleta Addis Ababa HQ',
    dailyHours: 8.0,
    weeklyHours: 40.0,
    payrollDaysPerMonth: 26.0,
    restDays: [0, 6], // Saturday & Sunday rest
    halfDays: [],
    shiftStart: '08:30',
    shiftEnd: '17:30',
    breakMinutes: 60,
    graceInMinutes: 15,
    graceOutMinutes: 10
  },
  {
    id: 2,
    code: 'CAL-RETAIL',
    name: 'Retail Calendar (48h Branch)',
    entityName: 'Bole Commercial Branch',
    dailyHours: 8.0,
    weeklyHours: 48.0,
    payrollDaysPerMonth: 26.0,
    restDays: [0], // Sunday rest, Mon-Sat full working
    halfDays: [],
    shiftStart: '08:00',
    shiftEnd: '17:00',
    breakMinutes: 60,
    graceInMinutes: 10,
    graceOutMinutes: 10
  },
  {
    id: 3,
    code: 'CAL-FACTORY',
    name: 'Plant Production Calendar (48h Plant)',
    entityName: 'Hawassa Industrial Plant',
    dailyHours: 8.0,
    weeklyHours: 48.0,
    payrollDaysPerMonth: 26.0,
    restDays: [0], // Sunday rest
    halfDays: [6], // Saturday half day (4.0h)
    shiftStart: '07:00',
    shiftEnd: '15:30',
    breakMinutes: 30,
    graceInMinutes: 10,
    graceOutMinutes: 10
  }
];

const selectedCalendarId = ref<number>(1);
const selectedCalendar = computed(() => {
  return companyCalendars.find(c => c.id === selectedCalendarId.value) || companyCalendars[0];
});

const calendarOptions = computed(() =>
  companyCalendars.map(cal => ({
    value: cal.id,
    label: cal.name
  }))
);

// ─── Current Navigation Date State (Defaults to December 2027 per Figma) ───
const todayDate = new Date(2027, 11, 17); // Statutory demo today: Dec 17, 2027
const currentDate = ref(new Date(2027, 11, 17)); // Dec 17, 2027
const selectedDate = ref(new Date(2027, 11, 17));

// ─── Calendar Event Schema Model ───
export interface CalendarEvent {
  id: string;
  date: string; // YYYY-MM-DD
  title: string;
  category: 'holiday' | 'committee' | 'company_event' | 'shift_window';
  holidayType?: 'public' | 'religious' | 'company';
  dayType?: 'working' | 'weekend' | 'holiday' | 'half_day';
  badgeLabel?: string;
  badgeVariant: 'purple' | 'green' | 'blue' | 'pink' | 'gray';
  time: string;
  startHour?: number;
  durationHours?: number;
  isPaid?: boolean;
  otMultiplier?: string;
  description: string;
  location?: string;
}

// Master Schema Events (Statutory Ethiopian public holidays, committees, and company events)
const masterEvents = ref<CalendarEvent[]>([
  {
    id: 'evt-1',
    date: '2027-12-13',
    title: 'Audit Committee Meeting',
    category: 'committee',
    badgeVariant: 'gray',
    time: '09:00 AM – 11:00 AM',
    startHour: 9,
    durationHours: 2,
    badgeLabel: 'Committee',
    description: 'Statutory audit and operational compliance committee review session (Committee ID: 5).',
    location: 'Executive Boardroom, HQ'
  },
  {
    id: 'evt-2',
    date: '2027-12-17',
    title: 'Meskel Beal',
    category: 'holiday',
    holidayType: 'religious',
    dayType: 'holiday',
    badgeVariant: 'blue',
    time: 'All Day',
    startHour: 0,
    isPaid: true,
    otMultiplier: '2.5×',
    badgeLabel: 'Religious Holiday',
    description: 'Finding of the True Cross religious public holiday. Statutory paid day off with 2.5× overtime multiplier per Ethiopian Labour Proclamation.'
  },
  {
    id: 'evt-3',
    date: '2027-12-16',
    title: 'Safety & Health Committee',
    category: 'committee',
    badgeVariant: 'gray',
    time: '10:00 AM – 11:30 AM',
    startHour: 10,
    durationHours: 1.5,
    badgeLabel: 'Committee',
    description: 'Quarterly occupational safety and health workplace compliance inspection (Committee ID: 4).',
    location: 'Conference Room B'
  },
  {
    id: 'evt-4',
    date: '2027-12-17',
    title: 'Executive Committee Meeting',
    category: 'committee',
    badgeVariant: 'pink',
    time: '10:00 AM – 12:30 PM',
    startHour: 10,
    durationHours: 2.5,
    badgeLabel: 'Executive Panel',
    description: 'Executive committee governance, headcount budget approval, and quarterly performance alignment.',
    location: 'Executive Boardroom, HQ'
  },
  {
    id: 'evt-5',
    date: '2027-12-18',
    title: 'Executive Committee Briefing',
    category: 'committee',
    badgeVariant: 'green',
    time: '11:30 AM – 01:00 PM',
    startHour: 11,
    durationHours: 1.5,
    badgeLabel: 'Governance',
    description: 'Operational review and succession coverage report evaluation.',
    location: 'Executive Suite'
  },
  {
    id: 'evt-6',
    date: '2027-12-18',
    title: 'Culture Day',
    category: 'company_event',
    badgeVariant: 'purple',
    time: '02:00 PM – 05:00 PM',
    startHour: 14,
    durationHours: 3,
    badgeLabel: 'Company Social',
    description: 'Haleta corporate culture gathering, traditional coffee ceremony, and employee recognition ceremony.',
    location: 'Main Auditorium'
  },
  {
    id: 'evt-7',
    date: '2027-12-19',
    title: 'Culture Day',
    category: 'company_event',
    badgeVariant: 'blue',
    time: '01:00 PM – 04:00 PM',
    startHour: 13,
    durationHours: 3,
    badgeLabel: 'Company Social',
    description: 'Company-wide staff celebration and cultural exchange festival.',
    location: 'Campus Grounds'
  },
  {
    id: 'evt-8',
    date: '2027-12-14',
    title: 'Enkutatash (New year)',
    category: 'holiday',
    holidayType: 'public',
    dayType: 'holiday',
    badgeVariant: 'gray',
    time: 'All Day',
    startHour: 0,
    isPaid: true,
    otMultiplier: '2.5×',
    badgeLabel: 'Public Holiday',
    description: 'National statutory public holiday marking the Ethiopian New Year. Mandatory paid rest day.'
  },
  {
    id: 'evt-9',
    date: '2027-12-22',
    title: 'Ye Gena Beal',
    category: 'holiday',
    holidayType: 'religious',
    dayType: 'holiday',
    badgeVariant: 'purple',
    time: 'All Day',
    startHour: 8,
    isPaid: true,
    otMultiplier: '2.5×',
    badgeLabel: 'Rest Day',
    description: 'Ethiopian Christmas sacred celebration marked by church services and traditional feasts.'
  }
]);

// ─── Active Event Popover State ───
const activePopoverEvent = ref<CalendarEvent | null>(null);
const popoverPosition = ref<{ top: number; left: number }>({ top: 0, left: 0 });

const handleOpenPopover = (ev: CalendarEvent, eventTarget: MouseEvent) => {
  eventTarget.stopPropagation();
  const rect = (eventTarget.currentTarget as HTMLElement).getBoundingClientRect();
  popoverPosition.value = {
    top: rect.bottom + window.scrollY + 6,
    left: Math.max(16, rect.left + window.scrollX - 40)
  };
  activePopoverEvent.value = ev;
};

const handleClosePopover = () => {
  activePopoverEvent.value = null;
};

// ─── Header Period Title ("December , 2027") ───
const currentMonthYear = computed(() => {
  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return {
    monthName: monthNames[currentDate.value.getMonth()],
    year: currentDate.value.getFullYear()
  };
});

// ─── Sidebar Handlers ───
const onSidebarMonthChange = ({ year, month }: { year: number; month: number }) => {
  currentDate.value = new Date(year, month, 1);
};

// ─── Week View Days Headers (Dynamically generated for the week containing selectedDate) ───
export interface WeekHeaderCol {
  date: Date;
  dayNum: number;
  name: string;
  dateStr: string;
  isActive: boolean;
  isTinted: boolean;
  isLast?: boolean;
}

const weekHeaderCols = computed<WeekHeaderCol[]>(() => {
  const current = new Date(selectedDate.value);
  const dayOfWeek = current.getDay(); // 0 is Sunday
  const sunday = new Date(current);
  sunday.setDate(current.getDate() - dayOfWeek);

  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const cols: WeekHeaderCol[] = [];

  for (let i = 0; i < 7; i++) {
    const d = new Date(sunday);
    d.setDate(sunday.getDate() + i);
    const dayNum = d.getDate();
    const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(dayNum).padStart(2, '0')}`;
    const isActive = d.toDateString() === selectedDate.value.toDateString();
    cols.push({
      date: d,
      dayNum,
      name: dayNames[i],
      dateStr,
      isActive,
      isTinted: i < 4,
      isLast: i === 6
    });
  }
  return cols;
});

// Hourly slots: 12 AM to 11 PM
const timeSlots = [
  '12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM',
  '6 AM', '7 AM', '8 AM', '9 AM', '10 AM', '11 AM',
  '12 PM', '1 PM', '2 PM', '3 PM', '4 PM', '5 PM',
  '6 PM', '7 PM', '8 PM', '9 PM', '10 PM', '11 PM'
];

// Helper to get events for a specific day column and hour slot
const getEventsForSlot = (dateStr: string, hourIdx: number): CalendarEvent[] => {
  return masterEvents.value.filter(e => {
    if (e.date !== dateStr) return false;
    if (e.time === 'All Day' || e.startHour === 0) {
      return hourIdx === 0;
    }
    return e.startHour === hourIdx;
  });
};

const getEventBannerClass = (ev: CalendarEvent): string => {
  if (ev.title.includes('Enkutatash')) return 'week-event-banner--enkutatash';
  if (ev.title.includes('Meskel')) return 'week-event-banner--meskel';
  if (ev.category === 'committee' && ev.badgeVariant === 'pink') return 'week-event-banner--executive';
  if (ev.category === 'committee') return 'week-event-banner--committee';
  if (ev.category === 'company_event') return 'week-event-banner--culture';
  return 'week-event-banner--meskel';
};

// ─── Month Matrix Generator (5x7 Grid) ───
interface MonthCell {
  date: Date;
  dateStr: string;
  dayNum: number;
  label: string;
  isCurrentMonth: boolean;
  isSelected: boolean;
  isToday: boolean;
  dayType: 'working' | 'weekend' | 'holiday' | 'half_day';
  plannedHours: number;
  events: CalendarEvent[];
}

const monthGrid = computed(() => {
  const y = currentDate.value.getFullYear();
  const m = currentDate.value.getMonth();
  const firstDay = new Date(y, m, 1).getDay();
  const totalDays = new Date(y, m + 1, 0).getDate();
  const prevMonthDays = new Date(y, m, 0).getDate();
  const cal = selectedCalendar.value;

  const cells: MonthCell[] = [];

  const getDayClassification = (d: Date, events: CalendarEvent[]): { dayType: 'working' | 'weekend' | 'holiday' | 'half_day'; plannedHours: number } => {
    const holiday = events.find(e => e.category === 'holiday');
    if (holiday) return { dayType: 'holiday', plannedHours: 0 };
    const dayOfWeek = d.getDay();
    if (cal.restDays.includes(dayOfWeek)) return { dayType: 'weekend', plannedHours: 0 };
    if (cal.halfDays.includes(dayOfWeek)) return { dayType: 'half_day', plannedHours: 4.0 };
    return { dayType: 'working', plannedHours: cal.dailyHours };
  };

  for (let i = firstDay - 1; i >= 0; i--) {
    const d = new Date(y, m - 1, prevMonthDays - i);
    const dNum = d.getDate();
    const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(dNum).padStart(2, '0')}`;
    const monthShort = d.toLocaleString('en-US', { month: 'short' });
    const evs = masterEvents.value.filter(e => e.date === dateStr);
    const { dayType, plannedHours } = getDayClassification(d, evs);
    const isSelected = d.toDateString() === selectedDate.value.toDateString();
    const isToday = d.toDateString() === todayDate.toDateString();

    cells.push({
      date: d,
      dateStr,
      dayNum: dNum,
      label: dNum === prevMonthDays - i ? `${monthShort} ${dNum}` : `${dNum}`,
      isCurrentMonth: false,
      isSelected,
      isToday,
      dayType,
      plannedHours,
      events: evs
    });
  }

  for (let i = 1; i <= totalDays; i++) {
    const d = new Date(y, m, i);
    const dateStr = `${y}-${String(m + 1).padStart(2, '0')}-${String(i).padStart(2, '0')}`;
    const evs = masterEvents.value.filter(e => e.date === dateStr);
    const { dayType, plannedHours } = getDayClassification(d, evs);
    const isSelected = d.toDateString() === selectedDate.value.toDateString();
    const isToday = d.toDateString() === todayDate.toDateString();

    cells.push({
      date: d,
      dateStr,
      dayNum: i,
      label: i === 1 ? `Dec 1` : `${i}`,
      isCurrentMonth: true,
      isSelected,
      isToday,
      dayType,
      plannedHours,
      events: evs
    });
  }

  const remaining = 35 - cells.length > 0 ? 35 - cells.length : 42 - cells.length;
  for (let n = 1; n <= remaining; n++) {
    const d = new Date(y, m + 1, n);
    const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(n).padStart(2, '0')}`;
    const evs = masterEvents.value.filter(e => e.date === dateStr);
    const { dayType, plannedHours } = getDayClassification(d, evs);
    const isSelected = d.toDateString() === selectedDate.value.toDateString();
    const isToday = d.toDateString() === todayDate.toDateString();

    cells.push({
      date: d,
      dateStr,
      dayNum: n,
      label: n === 1 ? `Jan 1` : `${n}`,
      isCurrentMonth: false,
      isSelected,
      isToday,
      dayType,
      plannedHours,
      events: evs
    });
  }

  return cells;
});

// ─── List View Grouped Agenda (Figma 6328:119971 Structured Table List) ───
export interface ListAgendaItem {
  id: string;
  time: string;
  title: string;
  category: string;
  dotVariant: 'amber' | 'blue' | 'green' | 'purple';
  badge: string;
  originalEvent: CalendarEvent;
}

export interface ListAgendaGroup {
  dateStr: string;
  dayNum: number;
  dayName: string;
  date: Date;
  isSelected: boolean;
  dayType?: string;
  items: ListAgendaItem[];
}

const listAgendaGroups = computed<ListAgendaGroup[]>(() => {
  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const groupsMap = new Map<string, ListAgendaGroup>();

  // Sort events chronologically
  const sorted = [...masterEvents.value].sort((a, b) => a.date.localeCompare(b.date) || a.startHour - b.startHour);

  for (const ev of sorted) {
    if (!groupsMap.has(ev.date)) {
      const parts = ev.date.split('-').map(Number);
      const d = new Date(parts[0], parts[1] - 1, parts[2]);
      const isSelected = d.toDateString() === selectedDate.value.toDateString();
      groupsMap.set(ev.date, {
        dateStr: ev.date,
        dayNum: parts[2],
        dayName: dayNames[d.getDay()],
        date: d,
        isSelected,
        dayType: ev.badgeLabel || (ev.category === 'holiday' ? 'Public Holiday' : ''),
        items: []
      });
    }

    const group = groupsMap.get(ev.date)!;
    let dotVariant: 'amber' | 'blue' | 'green' | 'purple' = 'blue';
    if (ev.category === 'holiday') dotVariant = 'green';
    else if (ev.badgeVariant === 'amber' || ev.badgeVariant === 'pink') dotVariant = 'amber';
    else if (ev.badgeVariant === 'purple') dotVariant = 'purple';

    group.items.push({
      id: ev.id,
      time: ev.time,
      title: ev.title,
      category: ev.category,
      dotVariant,
      badge: ev.badgeLabel || '',
      originalEvent: ev
    });
  }

  return Array.from(groupsMap.values());
});

// ─── Navigation Handlers ───
const handlePrevMonth = () => {
  const d = new Date(currentDate.value);
  d.setMonth(d.getMonth() - 1);
  currentDate.value = d;
  selectedDate.value = new Date(d.getFullYear(), d.getMonth(), Math.min(selectedDate.value.getDate(), 28));
  handleClosePopover();
};

const handleNextMonth = () => {
  const d = new Date(currentDate.value);
  d.setMonth(d.getMonth() + 1);
  currentDate.value = d;
  selectedDate.value = new Date(d.getFullYear(), d.getMonth(), Math.min(selectedDate.value.getDate(), 28));
  handleClosePopover();
};

const jumpToToday = () => {
  currentDate.value = new Date(todayDate);
  selectedDate.value = new Date(todayDate);
  handleClosePopover();
};

const selectDate = (d: Date) => {
  selectedDate.value = new Date(d);
  if (d.getMonth() !== currentDate.value.getMonth() || d.getFullYear() !== currentDate.value.getFullYear()) {
    currentDate.value = new Date(d.getFullYear(), d.getMonth(), 1);
  }
};
</script>

<template>
  <div class="calendar-page-layout" @click="handleClosePopover">
    
    <!-- ─── Top Breadcrumb Navigation (Figma 6328:119446: Monitor icon > Work Calendar) ─── -->
    <div class="calendar-top-header">
      <AppBreadcrumb :items="breadcrumbItems" :home-icon="Monitor" />
    </div>

    <!-- ─── Top Company Calendar Card (Figma 6328:119454: 1300x124) ─── -->
    <div class="company-calendar-card">
      <div class="company-calendar-info">
        <h1 class="company-title">Company Calendar</h1>
        <p class="company-subtitle">
          Corporate operational schedules, statutory Ethiopian &amp; Gregorian holiday observances, and workforce shift windows across entities.
        </p>
        <button type="button" class="company-today-text" @click="jumpToToday">
          Today: Thursday, Sep 17, 2027
        </button>
      </div>

      <div class="company-calendar-selector">
        <FormSelect
          v-model="selectedCalendarId"
          label="Select Work Calendar"
          :options="calendarOptions"
          placeholder="Select Work Calendar"
        />
      </div>
    </div>

    <!-- ─── Master Calendar Container (Figma 6328:119465) ─── -->
    <div class="calendar-master-container">

      <!-- ─── Header Toolbar Row (Figma 6328:119466: 1300x88) ─── -->
      <div class="calendar-toolbar-row">
        <!-- Left: Today Button (Figma 6328:119469: 102x40) -->
        <button type="button" class="btn-today-pill" @click="jumpToToday">
          <CalendarIcon :size="18" class="icon-calendar" />
          <span>Today</span>
        </button>

        <!-- Center & Right: Navigation Arrows + Month/Year + Tab Switcher -->
        <div class="header-right-controls">
          <!-- Arrows & Title (Figma 6328:119471: 277x40) -->
          <div class="month-nav-group">
            <button type="button" class="btn-circle-nav" @click="handlePrevMonth" title="Previous Month">
              <ChevronLeft :size="18" />
            </button>
            <span class="nav-month-title">{{ currentMonthYear.monthName }} , {{ currentMonthYear.year }}</span>
            <button type="button" class="btn-circle-nav" @click="handleNextMonth" title="Next Month">
              <ChevronRight :size="18" />
            </button>
          </div>

          <!-- View Mode Capsule Tabs (Figma 6328:119475: 195x40 Week | Month | List) -->
          <div class="view-capsule-switcher">
            <button
              v-for="mode in viewModes"
              :key="mode.id"
              type="button"
              class="capsule-tab-item"
              :class="{ 'capsule-tab-item--active': currentView === mode.id }"
              @click="currentView = mode.id"
            >
              {{ mode.label }}
            </button>
          </div>
        </div>
      </div>

      <!-- ─── Unified Calendar Container (Figma 6328:119479: 1229x639 with 0 gap) ─── -->
      <div class="calendar-split-body">

        <!-- ════════════════════════════════════════════
             LEFT BLUE HERO SIDEBAR (Figma 6328:119480 / 6328:120020)
        ════════════════════════════════════════════ -->
        <CalendarSidebar
          v-model="selectedDate"
          :view-mode="currentView"
          :today="todayDate"
          :events="masterEvents"
          @month-change="onSidebarMonthChange"
          @date-select="selectDate"
        />

        <!-- ════════════════════════════════════════════
             RIGHT CALENDAR MAIN VIEWS (Figma Frame 332: 904x639)
        ════════════════════════════════════════════ -->
        <main class="calendar-viewport-area">

          <!-- ──────────────────────────────────────────
               1. WEEK VIEW (Figma 6328:119481 & Frame 329/330)
          ────────────────────────────────────────── -->
          <div v-if="currentView === 'week'" class="calendar-week-grid">
            
            <!-- Week Hourly Body Grid with Sticky Day Header (Figma Frame 329/330) -->
            <div class="week-hourly-grid-body">
              <!-- Week Days Header Row (Sticky Top) -->
              <div class="week-days-header-row">
                <!-- Col 0: Gutter (38px) -->
                <div class="week-header-gutter"></div>

                <!-- 7 Day Columns -->
                <div
                  v-for="col in weekHeaderCols"
                  :key="col.dateStr"
                  class="week-day-header-cell"
                  :class="{
                    'week-day-header-cell--active': col.isActive,
                    'week-day-header-cell--tinted': col.isTinted,
                    'week-day-header-cell--last': col.isLast
                  }"
                  @click="selectDate(col.date)"
                >
                  <span class="col-day-num">{{ col.dayNum }}</span>
                  <span class="col-day-name">{{ col.name }}</span>
                </div>
              </div>

              <!-- Hourly Rows -->
              <div
                v-for="(timeLabel, tIdx) in timeSlots"
                :key="tIdx"
                class="week-hourly-row"
              >
                <!-- Time gutter label (38px width) -->
                <div class="week-time-label-cell">{{ timeLabel }}</div>

                <!-- 7 Day cells -->
                <div
                  v-for="col in weekHeaderCols"
                  :key="col.dateStr"
                  class="week-hour-slot-cell"
                  :class="{
                    'week-hour-slot-cell--active-col': col.isActive,
                    'week-hour-slot-cell--monday-col': col.name === 'Monday'
                  }"
                  @click="selectDate(col.date)"
                >
                  <div
                    v-for="ev in getEventsForSlot(col.dateStr, tIdx)"
                    :key="ev.id"
                    class="week-event-banner"
                    :class="getEventBannerClass(ev)"
                    @click.stop="handleOpenPopover(ev, $event)"
                  >
                    {{ ev.title }}
                  </div>
                </div>
              </div>
            </div>

          </div>

          <!-- ──────────────────────────────────────────
               2. MONTH VIEW (5x7 Matrix Grid)
          ────────────────────────────────────────── -->
          <div v-else-if="currentView === 'month'" class="view-month-matrix">
            <!-- Weekday Header (7 Columns) -->
            <div class="month-weekday-header">
              <div class="weekday-header-col">Sunday</div>
              <div class="weekday-header-col">Monday</div>
              <div class="weekday-header-col">Tuesday</div>
              <div class="weekday-header-col">Wednesday</div>
              <div class="weekday-header-col">Thursday</div>
              <div class="weekday-header-col">Friday</div>
              <div class="weekday-header-col">Saturday</div>
            </div>

            <!-- 5x7 Month Grid Cells -->
            <div class="month-cells-grid">
              <div
                v-for="(cell, cIdx) in monthGrid"
                :key="cIdx"
                class="month-cell-box"
                :class="{
                  'month-cell-box--other': !cell.isCurrentMonth,
                  'month-cell-box--selected': cell.isSelected,
                  'month-cell-box--today': cell.isToday
                }"
                @click="selectDate(cell.date)"
              >
                <!-- Cell Day Label / Circle Badge -->
                <div class="month-cell-header">
                  <span v-if="cell.isSelected" class="day-badge-solid-blue">{{ cell.dayNum }}</span>
                  <span v-else-if="cell.isToday" class="day-badge-today-blue">{{ cell.dayNum }}</span>
                  <span v-else class="day-label-text">{{ cell.label }}</span>

                  <span v-if="cell.isCurrentMonth" class="day-hours-hint">
                    {{ cell.plannedHours > 0 ? `${cell.plannedHours}h` : 'Rest' }}
                  </span>
                </div>

                <!-- Events Chips Inside Cell -->
                <div class="month-cell-events">
                  <template v-for="ev in cell.events" :key="ev.id">
                    <div
                      class="event-pill"
                      :class="`event-pill--${ev.badgeVariant || 'green'}`"
                      @click.stop="handleOpenPopover(ev, $event)"
                    >
                      <span class="pill-title-text">{{ ev.title }}</span>
                    </div>
                  </template>
                </div>
              </div>
            </div>
          </div>

          <!-- ──────────────────────────────────────────
               3. LIST VIEW (Figma 6328:119971: 904x639 Table List)
          ────────────────────────────────────────── -->
          <div v-else-if="currentView === 'list'" class="view-list-container">
            <div
              v-for="group in listAgendaGroups"
              :key="group.dateStr"
              class="list-date-group-card"
            >
              <!-- 44px Day Header Row (Figma 6328:119972) -->
              <div
                class="list-table-header-row"
                :class="{ 'list-table-header-row--active': group.isSelected }"
                @click="selectDate(group.date)"
              >
                <div class="list-header-content">
                  <span class="list-header-day-num">{{ group.dayNum }}</span>
                  <span class="list-header-day-name">{{ group.dayName }}</span>
                  <span v-if="group.dayType" class="list-header-day-type">{{ group.dayType }}</span>
                </div>
              </div>

              <!-- 30px Event Rows (Figma 6328:119974) -->
              <div
                v-for="item in group.items"
                :key="item.id"
                class="list-table-event-row"
                @click="handleOpenPopover(item.originalEvent, $event)"
              >
                <!-- 23px Gutter -->
                <div class="list-row-gutter"></div>
                <!-- Event Content Cell with Dot & Title -->
                <div class="list-row-content">
                  <div class="list-event-badge-item">
                    <span class="list-event-dot" :class="`list-event-dot--${item.dotVariant}`"></span>
                    <span class="list-event-title-text">{{ item.title }}</span>
                  </div>
                </div>
              </div>
            </div>

            <div v-if="listAgendaGroups.length === 0" class="list-empty-state">
              <p>No events scheduled for the selected period.</p>
            </div>
          </div>

        </main>

      </div>

    </div>

    <!-- ════════════════════════════════════════════
         FLOATING EVENT POPOVER CARD (Figma Image 5)
    ════════════════════════════════════════════ -->
    <div
      v-if="activePopoverEvent"
      class="event-details-popover"
      :style="{ top: `${popoverPosition.top}px`, left: `${popoverPosition.left}px` }"
      @click.stop
    >
      <div class="popover-header-row">
        <h4 class="popover-title">{{ activePopoverEvent.title }}</h4>
        <span class="popover-badge">
          <span>{{ activePopoverEvent.badgeLabel || 'Rest Day' }}</span>
        </span>
      </div>

      <div class="popover-meta-row">
        <Clock :size="14" class="popover-icon" />
        <span>
          {{ activePopoverEvent.dayType === 'holiday' ? 'Tue 12/17/2027 (Work is off on this day)' : activePopoverEvent.time }}
        </span>
      </div>

      <div v-if="activePopoverEvent.otMultiplier" class="popover-ot-row">
        <ShieldCheck :size="14" class="popover-icon text-success" />
        <span>Statutory Paid Holiday • Ethiopian Labour Proclamation Overtime Rate: <strong>{{ activePopoverEvent.otMultiplier }}</strong></span>
      </div>

      <div class="popover-desc-row">
        <FileText :size="14" class="popover-icon icon-desc" />
        <p class="popover-desc-text">
          {{ activePopoverEvent.description }}
        </p>
      </div>

      <div v-if="activePopoverEvent.location" class="popover-location-row">
        <Briefcase :size="14" class="popover-icon" />
        <span>Location: {{ activePopoverEvent.location }}</span>
      </div>
    </div>

  </div>
</template>

<style scoped>
/* ─── Page Outer Layout ─── */
.calendar-page-layout {
  padding: 0;
  background-color: #fafafa;
  min-height: calc(100vh - 64px);
  box-sizing: border-box;
}

.calendar-top-header {
  margin-bottom: 16px;
}

/* ─── Top Company Calendar Card (Figma 6328:119454: 1300x124) ─── */
.company-calendar-card {
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0px 1px 2px 0px rgba(10, 13, 18, 0.05);
}

.company-calendar-info {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.company-title {
  font-size: 16px;
  font-weight: 600;
  color: #414651;
  line-height: 24px;
  margin: 0 0 4px 0;
}

.company-subtitle {
  font-size: 14px;
  color: #737373;
  line-height: 20px;
  margin: 0 0 6px 0;
  max-width: 880px;
}

.company-today-text {
  font-size: 12px;
  font-weight: 500;
  color: #0B529C;
  line-height: 18px;
  background: none;
  border: none;
  padding: 0;
  cursor: pointer;
  width: fit-content;
  text-align: left;
}

.company-today-text:hover {
  text-decoration: underline;
}

.company-calendar-selector {
  display: flex;
  flex-direction: column;
  width: 343px;
  border-left: 1px solid #e5e5e5;
  padding-left: 24px;
  box-sizing: border-box;
  justify-content: center;
}

/* ─── Master Calendar Container (Figma 6328:119465) ─── */
.calendar-master-container {
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px 32px 32px 32px;
  box-shadow: 0px 1px 2px 0px rgba(10, 13, 18, 0.05);
}

/* ─── Header Toolbar Row (Figma 6328:119466: 1300x88) ─── */
.calendar-toolbar-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  height: 40px;
}

.btn-today-pill {
  height: 40px;
  padding: 0 16px;
  background: #ffffff;
  border: 1px solid #d9d9d9;
  border-radius: 8px;
  color: #414651;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  box-shadow: 0px 1px 2px 0px rgba(10, 13, 18, 0.05);
  transition: all 0.15s ease;
}

.btn-today-pill:hover {
  background: #fafafa;
  border-color: #bfbfbf;
}

.icon-calendar {
  color: #414651;
}

.header-right-controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 747px;
}

.month-nav-group {
  display: flex;
  align-items: center;
  gap: 16px;
}

.btn-circle-nav {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 1px solid #d9d9d9;
  background: #ffffff;
  color: #404040;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0px 1px 2px 0px rgba(10, 13, 18, 0.05);
  transition: all 0.15s ease;
}

.btn-circle-nav:hover {
  background: #fafafa;
  border-color: #bfbfbf;
}

.nav-month-title {
  font-size: 20px;
  font-weight: 500;
  color: #404040;
  line-height: 30px;
}

/* ─── View Mode Capsule Tabs (Figma 6328:119475: 195x40) ─── */
.view-capsule-switcher {
  display: inline-flex;
  background: #f5f5f5;
  border: 1px solid #e5e5e5;
  border-radius: 9999px;
  padding: 4px;
  gap: 4px;
}

.capsule-tab-item {
  border: none;
  background: transparent;
  color: #737373;
  font-size: 14px;
  font-weight: 600;
  padding: 6px 14px;
  border-radius: 9999px;
  cursor: pointer;
  line-height: 20px;
  transition: all 0.15s ease;
}

.capsule-tab-item:hover {
  color: #404040;
}

.capsule-tab-item--active {
  background: #ffffff;
  color: #404040;
  box-shadow: 0px 1px 1px rgba(10, 13, 18, 0.05);
}

/* ════════════════════════════════════════════
   UNIFIED CALENDAR CONTAINER (Figma 6328:119479: 1229x639)
════════════════════════════════════════════ */
.calendar-split-body {
  display: flex;
  width: 100%;
  height: 639px;
  max-height: 639px;
  border: 1px solid #e5e5e5;
  border-radius: 20px;
  overflow: hidden;
  background: #ffffff;
  box-sizing: border-box;
}

/* ════════════════════════════════════════════
   RIGHT CALENDAR MAIN VIEWS (Figma Frame 332: 904x639)
════════════════════════════════════════════ */
.calendar-viewport-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  height: 639px;
  max-height: 639px;
  overflow: hidden;
  background: #ffffff;
  box-sizing: border-box;
}

/* ─── 1. WEEK VIEW (Figma 6328:119481 & Frame 329/330) ─── */
.calendar-week-grid {
  display: flex;
  flex-direction: column;
  height: 639px;
  max-height: 639px;
  overflow: hidden;
  background: #ffffff;
}

.week-hourly-grid-body {
  height: 639px;
  max-height: 639px;
  overflow-y: auto;
  overflow-x: hidden;
  flex: 1;
  position: relative;
  scrollbar-width: thin;
  scrollbar-color: #d4d4d4 transparent;
}

.week-hourly-grid-body::-webkit-scrollbar {
  width: 6px;
}

.week-hourly-grid-body::-webkit-scrollbar-track {
  background: transparent;
}

.week-hourly-grid-body::-webkit-scrollbar-thumb {
  background: #d4d4d4;
  border-radius: 9999px;
}

.week-hourly-grid-body::-webkit-scrollbar-thumb:hover {
  background: #a3a3a3;
}

.week-days-header-row {
  position: sticky;
  top: 0;
  z-index: 10;
  height: 44px;
  min-height: 44px;
  display: grid;
  grid-template-columns: 38px repeat(7, minmax(0, 1fr));
  border-bottom: 1px solid #e5e5e5;
  background: #ffffff;
  box-sizing: border-box;
  width: 100%;
}

.week-days-header-row * {
  box-sizing: border-box;
}

.week-header-gutter {
  border-right: 1px solid #e5e5e5;
  background: #ffffff;
  box-sizing: border-box;
}

.week-day-header-cell {
  border-right: 1px solid #e5e5e5;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 500;
  line-height: 18px;
  cursor: pointer;
  box-sizing: border-box;
  transition: all 0.15s ease;
  min-width: 0;
}

.week-day-header-cell:hover:not(.week-day-header-cell--active) {
  background-color: #f5f5f5;
}

.week-day-header-cell--tinted {
  background-color: #fafafa;
}

.week-day-header-cell--last {
  border-right: none;
}

.col-day-num {
  color: #0B529C;
  font-weight: 600;
}

.col-day-name {
  color: #737373;
}

/* Active Day Header (Figma 6328:119487) */
.week-day-header-cell--active {
  background-color: #0B529C !important;
  border-right-color: #83bff6;
}

.week-day-header-cell--active .col-day-num,
.week-day-header-cell--active .col-day-name {
  color: #ffffff !important;
}

.week-hourly-row {
  display: grid;
  grid-template-columns: 38px repeat(7, minmax(0, 1fr));
  height: 30px;
  min-height: 30px;
  border-bottom: 1px solid #e5e5e5;
  box-sizing: border-box;
  width: 100%;
}

.week-hourly-row * {
  box-sizing: border-box;
}

.week-time-label-cell {
  border-right: 1px solid #e5e5e5;
  font-size: 10px;
  color: #737373;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ffffff;
  user-select: none;
  box-sizing: border-box;
}

.week-hour-slot-cell {
  border-right: 1px solid #e5e5e5;
  padding: 2px 4px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  position: relative;
  overflow: hidden;
  cursor: pointer;
  box-sizing: border-box;
  min-width: 0;
}

.week-hour-slot-cell:last-child {
  border-right: none;
}

.week-hour-slot-cell--monday-col {
  background-color: #fafafa;
}

.week-hour-slot-cell--active-col {
  background-color: #f1f7fe;
}

/* Event Banners inside Week Grid Slots */
.week-event-banner {
  border-radius: 8px;
  font-size: 12px;
  font-weight: 500;
  line-height: 18px;
  cursor: pointer;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  transition: opacity 0.15s ease;
}

.week-event-banner:hover {
  opacity: 0.85;
}

.week-event-banner--enkutatash {
  background-color: #f5f5f5;
  color: #a1a1a1;
  padding: 2px 8px;
  text-align: center;
}

.week-event-banner--meskel {
  background-color: #f1f7fe;
  color: #0B529C;
  padding: 6px 8px;
}

.week-event-banner--committee {
  background-color: #f5f5f5;
  color: #404040;
  padding: 4px 8px;
}

.week-event-banner--executive {
  background-color: #fdf2f8;
  color: #db2777;
  padding: 4px 8px;
}

.week-event-banner--culture {
  background-color: #eff6ff;
  color: #1d4ed8;
  padding: 4px 8px;
}

/* ─── 2. MONTH VIEW ─── */
.view-month-matrix {
  display: flex;
  flex-direction: column;
  height: 639px;
  max-height: 639px;
  overflow: hidden;
}

.month-weekday-header {
  height: 44px;
  min-height: 44px;
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  border-bottom: 1px solid #e5e5e5;
  background: #fafafa;
  flex-shrink: 0;
}

.weekday-header-col {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  color: #737373;
  font-weight: 500;
  border-right: 1px solid #e5e5e5;
}

.weekday-header-col:last-child {
  border-right: none;
}

.month-cells-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  grid-template-rows: repeat(5, 1fr);
  height: 595px;
  flex: 1;
  overflow: hidden;
}

.month-cell-box {
  border-right: 1px solid #e5e5e5;
  border-bottom: 1px solid #e5e5e5;
  padding: 6px 8px;
  display: flex;
  flex-direction: column;
  position: relative;
  background: #ffffff;
  cursor: pointer;
  overflow: hidden;
  transition: background-color 0.15s ease;
}

.month-cell-box:hover {
  background-color: #fafafa;
}

.month-cell-box--selected {
  background-color: #f1f7fe !important;
}

.month-cell-box--today:not(.month-cell-box--selected) {
  background-color: #f8fafc;
}

.month-cell-box:nth-child(7n) {
  border-right: none;
}

.month-cell-box--other .day-label-text {
  color: #a1a1a1;
}

.month-cell-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.day-label-text {
  font-size: 12.5px;
  color: #404040;
  font-weight: 500;
}

.day-hours-hint {
  font-size: 10px;
  color: #a1a1a1;
  font-weight: 500;
}

.day-badge-solid-blue {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #0B529C;
  color: #ffffff;
  font-size: 12px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
}

.day-badge-today-blue {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  border: 2px solid #0B529C;
  color: #0B529C;
  font-size: 12px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
}

.month-cell-events {
  display: flex;
  flex-direction: column;
  gap: 3px;
  flex: 1;
  overflow: hidden;
}

.event-pill {
  padding: 3px 6px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.event-pill--purple { background: #f5f3ff; color: #7c3aed; }
.event-pill--green { background: #ecfdf5; color: #059669; }
.event-pill--blue { background: #f1f7fe; color: #0B529C; }
.event-pill--pink { background: #fdf2f8; color: #db2777; }
.event-pill--gray { background: #f5f5f5; color: #404040; }

.pill-title-text {
  overflow: hidden;
  text-overflow: ellipsis;
}

/* ─── 3. LIST VIEW (Figma 6328:119971) ─── */
.view-list-container {
  display: flex;
  flex-direction: column;
  height: 639px;
  max-height: 639px;
  overflow-y: auto;
  background: #ffffff;
}

.list-date-group-card {
  display: flex;
  flex-direction: column;
}

.list-table-header-row {
  height: 44px;
  min-height: 44px;
  background-color: #fafafa;
  border-bottom: 1px solid #e5e5e5;
  border-top: 1px solid #e5e5e5;
  display: flex;
  align-items: center;
  padding: 0 24px;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.list-table-header-row:hover {
  background-color: #f5f5f5;
}

.list-table-header-row--active {
  background-color: #f1f7fe !important;
}

.list-header-content {
  display: flex;
  align-items: center;
  gap: 6px;
}

.list-header-day-num {
  font-size: 16px;
  font-weight: 600;
  color: #0B529C;
  line-height: 24px;
}

.list-header-day-name {
  font-size: 16px;
  font-weight: 500;
  color: #737373;
  line-height: 24px;
}

.list-header-day-type {
  font-size: 12px;
  color: #a1a1a1;
  margin-left: 8px;
}

.list-table-event-row {
  display: flex;
  height: 30px;
  min-height: 30px;
  border-bottom: 1px solid #e5e5e5;
  cursor: pointer;
  background: #ffffff;
  transition: background-color 0.15s ease;
}

.list-table-event-row:hover {
  background-color: #fafafa;
}

.list-row-gutter {
  width: 23px;
  flex-shrink: 0;
  height: 100%;
  border-right: 1px solid #e5e5e5;
  background: #ffffff;
}

.list-row-content {
  flex: 1;
  display: flex;
  align-items: center;
  padding: 0 12px;
  height: 100%;
}

.list-event-badge-item {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.list-event-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.list-event-dot--blue {
  background-color: #0B529C;
}

.list-event-dot--green {
  background-color: #009966;
}

.list-event-dot--amber {
  background-color: #E17100;
}

.list-event-dot--purple {
  background-color: #8200DB;
}

.list-event-title-text {
  font-size: 12px;
  font-weight: 500;
  color: #404040;
  line-height: 18px;
}

.list-empty-state {
  padding: 48px 24px;
  text-align: center;
  color: #737373;
  font-size: 14px;
}

/* ════════════════════════════════════════════
   FLOATING EVENT POPOVER CARD
════════════════════════════════════════════ */
.event-details-popover {
  position: absolute;
  width: 330px;
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.04);
  padding: 16px 18px;
  z-index: 100;
}

.popover-header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.popover-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.popover-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  background: #f1f7fe;
  color: #0B529C;
  border-radius: 9999px;
  padding: 3px 10px;
  font-size: 11.5px;
  font-weight: 500;
}

.popover-meta-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #737373;
  margin-bottom: 8px;
}

.popover-ot-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 11.5px;
  color: #065f46;
  background: #ecfdf5;
  padding: 6px 10px;
  border-radius: 6px;
  margin-bottom: 8px;
}

.popover-desc-row {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  font-size: 11.5px;
  color: #737373;
  line-height: 1.5;
  margin-bottom: 6px;
}

.popover-location-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 11.5px;
  color: #737373;
  margin-top: 4px;
}

.popover-icon {
  color: #a1a1a1;
  flex-shrink: 0;
}

.icon-desc {
  margin-top: 2px;
}

.popover-desc-text {
  margin: 0;
}

.icon-tertiary {
  color: #737373;
}
</style>
