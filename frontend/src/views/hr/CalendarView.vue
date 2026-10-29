<script setup lang="ts">
import { ref, computed } from 'vue';
import {
  Calendar as CalendarIcon, Clock, ChevronLeft, ChevronRight,
  Sun, FileText, Check, X, ShieldCheck, Briefcase, Users, AlertCircle
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';

// ─── Breadcrumbs (Rule 3: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'Work Calendar' }
];

// ─── View Modes (Figma order: Day | Week | Month | List) ───
type CalendarViewMode = 'day' | 'week' | 'month' | 'list';
const currentView = ref<CalendarViewMode>('month');

const viewModes: { id: CalendarViewMode; label: string }[] = [
  { id: 'day', label: 'Day' },
  { id: 'week', label: 'Week' },
  { id: 'month', label: 'Month' },
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
    name: 'Office Calendar (40h HQ)',
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

// ─── Current Navigation Date State (Defaults to December 2027 per Figma) ───
const currentDate = ref(new Date(2027, 11, 17)); // Dec 17, 2027
const selectedDate = ref(new Date(2027, 11, 17));
const miniCalendarDate = ref(new Date(2027, 7, 1)); // August 2027 per Figma mini picker

// ─── Calendar Event Schema Model (Aligned with Holiday, WorkCalendarDay, Committee, & Shift) ───
export interface CalendarEvent {
  id: string;
  date: string; // YYYY-MM-DD
  title: string;
  category: 'holiday' | 'committee' | 'company_event' | 'shift_window';
  holidayType?: 'public' | 'religious' | 'company'; // HOLIDAY_TYPE lookup
  dayType?: 'working' | 'weekend' | 'holiday' | 'half_day'; // CALENDAR_DAY_TYPE lookup
  badgeLabel?: string;
  badgeVariant: 'purple' | 'green' | 'blue' | 'pink' | 'gray';
  time: string;
  startHour?: number; // 0-23 for hourly grid positioning
  durationHours?: number;
  isPaid?: boolean;
  otMultiplier?: string; // 2.5× for public holidays, 1.5× for normal OT
  description: string;
  location?: string;
}

// Master Schema Events (Reflecting Ethiopian statutory holidays, committees, and company events)
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
    date: '2027-12-14',
    title: 'Meskel',
    category: 'holiday',
    holidayType: 'religious',
    dayType: 'holiday',
    badgeVariant: 'gray',
    time: 'All Day',
    startHour: 8,
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
    date: '2027-12-19',
    title: 'Enkutatash Ethiopian New Year',
    category: 'holiday',
    holidayType: 'public',
    dayType: 'holiday',
    badgeVariant: 'green',
    time: 'All Day',
    startHour: 8,
    isPaid: true,
    otMultiplier: '2.5×',
    badgeLabel: 'Public Holiday',
    description: 'National statutory public holiday marking the Ethiopian New Year (Meskerem 1). Mandatory paid rest day.'
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
    description: 'Ethiopian Christmas, known as Genna, is a sacred celebration marked by fasting, midnight church services, traditional feasts, and family gatherings.'
  },
  {
    id: 'evt-10',
    date: '2028-01-03',
    title: 'Enkutatash Ethiopian New Year',
    category: 'holiday',
    holidayType: 'public',
    dayType: 'holiday',
    badgeVariant: 'green',
    time: 'All Day',
    startHour: 8,
    isPaid: true,
    otMultiplier: '2.5×',
    badgeLabel: 'Public Holiday',
    description: 'Statutory New Year observance and national holiday.'
  }
]);

// ─── Active Event Popover State (Figma Image 5) ───
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

// ─── Ethiopian Calendar Year Display ───
const ethiopianYearText = computed(() => {
  return currentDate.value.getFullYear();
});

// ─── Current Header Period Title ("December , 2027") ───
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

// ─── Selected Date Display for Left Sidebar ───
const selectedDateHeadline = computed(() => {
  const d = selectedDate.value;
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return `${days[d.getDay()]}, ${months[d.getMonth()]} ${d.getDate()}`;
});

// ─── Sidebar "Today's Event" List (Figma Left Column) ───
const todayEventsList = computed(() => {
  return [
    { title: 'Office Meeting', time: '11:30' },
    { title: 'Culture Day', time: '11:30' }
  ];
});

// ─── Mini Calendar Generator (Left Sidebar) ───
const miniMonthTitle = computed(() => {
  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return `${monthNames[miniCalendarDate.value.getMonth()]} ${miniCalendarDate.value.getFullYear()}`;
});

const miniMonthDays = computed(() => {
  const y = miniCalendarDate.value.getFullYear();
  const m = miniCalendarDate.value.getMonth();
  const firstDay = new Date(y, m, 1).getDay();
  const totalDays = new Date(y, m + 1, 0).getDate();
  const prevMonthDays = new Date(y, m, 0).getDate();

  const days: { day: number; isCurrentMonth: boolean; isSelected: boolean; date: Date }[] = [];

  for (let i = firstDay - 1; i >= 0; i--) {
    const d = new Date(y, m - 1, prevMonthDays - i);
    days.push({ day: d.getDate(), isCurrentMonth: false, isSelected: false, date: d });
  }

  for (let i = 1; i <= totalDays; i++) {
    const d = new Date(y, m, i);
    const isSelected = i === 17; // Day 17 is highlighted in orange per Figma
    days.push({ day: i, isCurrentMonth: true, isSelected, date: d });
  }

  while (days.length % 7 !== 0) {
    const nextDayNum = days.length - (firstDay + totalDays) + 1;
    const d = new Date(y, m + 1, nextDayNum);
    days.push({ day: nextDayNum, isCurrentMonth: false, isSelected: false, date: d });
  }

  return days;
});

// ─── Month Matrix Generator (5x7 Grid) ───
interface MonthCell {
  date: Date;
  dateStr: string;
  dayNum: number;
  label: string;
  isCurrentMonth: boolean;
  isDay16: boolean;
  isDay17: boolean;
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

  // Helper to determine day classification from calendar
  const getDayClassification = (d: Date, events: CalendarEvent[]): { dayType: 'working' | 'weekend' | 'holiday' | 'half_day'; plannedHours: number } => {
    const holiday = events.find(e => e.category === 'holiday');
    if (holiday) {
      return { dayType: 'holiday', plannedHours: 0 };
    }
    const dayOfWeek = d.getDay();
    if (cal.restDays.includes(dayOfWeek)) {
      return { dayType: 'weekend', plannedHours: 0 };
    }
    if (cal.halfDays.includes(dayOfWeek)) {
      return { dayType: 'half_day', plannedHours: 4.0 };
    }
    return { dayType: 'working', plannedHours: cal.dailyHours };
  };

  // Previous month trailing days
  for (let i = firstDay - 1; i >= 0; i--) {
    const d = new Date(y, m - 1, prevMonthDays - i);
    const dNum = d.getDate();
    const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(dNum).padStart(2, '0')}`;
    const monthShort = d.toLocaleString('en-US', { month: 'short' });
    const evs = masterEvents.value.filter(e => e.date === dateStr);
    const { dayType, plannedHours } = getDayClassification(d, evs);

    cells.push({
      date: d,
      dateStr,
      dayNum: dNum,
      label: dNum === prevMonthDays - i ? `${monthShort} ${dNum}` : `${dNum}`,
      isCurrentMonth: false,
      isDay16: false,
      isDay17: false,
      dayType,
      plannedHours,
      events: evs
    });
  }

  // Current month days
  for (let i = 1; i <= totalDays; i++) {
    const d = new Date(y, m, i);
    const dateStr = `${y}-${String(m + 1).padStart(2, '0')}-${String(i).padStart(2, '0')}`;
    const evs = masterEvents.value.filter(e => e.date === dateStr);
    const { dayType, plannedHours } = getDayClassification(d, evs);

    cells.push({
      date: d,
      dateStr,
      dayNum: i,
      label: i === 1 ? `Dec 1` : `${i}`,
      isCurrentMonth: true,
      isDay16: i === 16,
      isDay17: i === 17,
      dayType,
      plannedHours,
      events: evs
    });
  }

  // Next month leading days
  const remaining = 35 - cells.length > 0 ? 35 - cells.length : 42 - cells.length;
  for (let n = 1; n <= remaining; n++) {
    const d = new Date(y, m + 1, n);
    const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(n).padStart(2, '0')}`;
    const evs = masterEvents.value.filter(e => e.date === dateStr);
    const { dayType, plannedHours } = getDayClassification(d, evs);

    cells.push({
      date: d,
      dateStr,
      dayNum: n,
      label: n === 1 ? `Jan 1` : `${n}`,
      isCurrentMonth: false,
      isDay16: false,
      isDay17: false,
      dayType,
      plannedHours,
      events: evs
    });
  }

  return cells;
});

// ─── Week View Days Generator (Days 13 to 19 per Figma Image 1) ───
const weekDays = [
  { dayNum: 13, name: 'Sunday', dateStr: '2027-12-13', isCurrent: false },
  { dayNum: 14, name: 'Monday', dateStr: '2027-12-14', isCurrent: false },
  { dayNum: 15, name: 'Thursday', dateStr: '2027-12-15', isCurrent: false },
  { dayNum: 16, name: 'Wednesday', dateStr: '2027-12-16', isCurrent: false },
  { dayNum: 17, name: 'Tuesday', dateStr: '2027-12-17', isCurrent: true },
  { dayNum: 18, name: 'Friday', dateStr: '2027-12-18', isCurrent: false },
  { dayNum: 19, name: 'Saturday', dateStr: '2027-12-19', isCurrent: false }
];

const timeSlots = [
  '12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM',
  '6 AM', '7 AM', '8 AM', '9 AM', '10 AM', '11 AM',
  '12 PM', '1 PM', '2 PM', '3 PM', '4 PM', '5 PM',
  '6 PM', '7 PM', '8 PM', '9 PM', '10 PM', '11 PM'
];

// ─── List View Grouped Agenda Generator (Chronological & Schema-Aligned) ───
interface ListAgendaGroup {
  dateStr: string;
  dayNum: number;
  dayName: string;
  isToday: boolean;
  dayType: string;
  plannedHours: number;
  items: {
    id: string;
    time: string;
    title: string;
    category: string;
    dotVariant: 'amber' | 'blue' | 'green' | 'purple';
    badge: string;
    otMultiplier?: string;
    description: string;
  }[];
}

const listAgendaGroups = computed<ListAgendaGroup[]>(() => {
  return [
    {
      dateStr: '2027-12-13',
      dayNum: 13,
      dayName: 'Sunday',
      isToday: false,
      dayType: 'Weekend Rest Day',
      plannedHours: 0,
      items: [
        {
          id: 'l-1',
          time: '09:00 AM',
          title: 'Audit Committee Meeting',
          category: 'committee',
          dotVariant: 'blue',
          badge: 'Committee',
          description: 'Statutory audit and operational compliance review in the Executive Boardroom.'
        }
      ]
    },
    {
      dateStr: '2027-12-14',
      dayNum: 14,
      dayName: 'Monday',
      isToday: false,
      dayType: 'Public Holiday (Rest Day)',
      plannedHours: 0,
      items: [
        {
          id: 'l-2',
          time: 'All Day',
          title: 'Meskel (Finding of the True Cross)',
          category: 'holiday',
          dotVariant: 'green',
          badge: 'Religious Holiday',
          otMultiplier: '2.5×',
          description: 'Statutory public holiday. Paid day off under Ethiopian Labour Proclamation.'
        }
      ]
    },
    {
      dateStr: '2027-12-16',
      dayNum: 16,
      dayName: 'Wednesday',
      isToday: false,
      dayType: 'Working Day',
      plannedHours: 8.0,
      items: [
        {
          id: 'l-3',
          time: '10:00 AM',
          title: 'Safety & Health Committee',
          category: 'committee',
          dotVariant: 'blue',
          badge: 'Committee',
          description: 'Quarterly occupational safety and health workplace compliance inspection.'
        }
      ]
    },
    {
      dateStr: '2027-12-17',
      dayNum: 17,
      dayName: 'Thursday',
      isToday: true,
      dayType: 'Working Day',
      plannedHours: 8.0,
      items: [
        {
          id: 'l-4',
          time: '10:00 AM',
          title: 'Executive Committee Meeting',
          category: 'committee',
          dotVariant: 'amber',
          badge: 'Governance',
          description: 'Executive committee governance, headcount budget approval, and quarterly performance alignment.'
        },
        {
          id: 'l-5',
          time: '08:30 AM – 17:30 PM',
          title: 'Standard Office Shift (8.0h)',
          category: 'shift_window',
          dotVariant: 'amber',
          badge: 'Operating Window',
          description: 'Standard working hours with 60-min statutory lunch break from 12:30 to 13:30.'
        }
      ]
    },
    {
      dateStr: '2027-12-18',
      dayNum: 18,
      dayName: 'Friday',
      isToday: false,
      dayType: 'Working Day',
      plannedHours: 8.0,
      items: [
        {
          id: 'l-6',
          time: '11:30 AM',
          title: 'Executive Committee Briefing',
          category: 'committee',
          dotVariant: 'blue',
          badge: 'Committee',
          description: 'Strategy alignment and operational review.'
        },
        {
          id: 'l-7',
          time: '02:00 PM',
          title: 'Culture Day',
          category: 'company_event',
          dotVariant: 'purple',
          badge: 'Company Social',
          description: 'Corporate culture gathering and employee recognition ceremony.'
        }
      ]
    },
    {
      dateStr: '2027-12-19',
      dayNum: 19,
      dayName: 'Saturday',
      isToday: false,
      dayType: 'Weekend Rest Day',
      plannedHours: 0,
      items: [
        {
          id: 'l-8',
          time: 'All Day',
          title: 'Enkutatash Ethiopian New Year',
          category: 'holiday',
          dotVariant: 'green',
          badge: 'Public Holiday',
          otMultiplier: '2.5×',
          description: 'Statutory celebration marking the Ethiopian New Year. Paid rest day.'
        }
      ]
    },
    {
      dateStr: '2027-12-22',
      dayNum: 22,
      dayName: 'Wednesday',
      isToday: false,
      dayType: 'Public Holiday (Rest Day)',
      plannedHours: 0,
      items: [
        {
          id: 'l-9',
          time: 'All Day',
          title: 'Ye Gena Beal',
          category: 'holiday',
          dotVariant: 'purple',
          badge: 'Religious Holiday',
          otMultiplier: '2.5×',
          description: 'Ethiopian Christmas sacred celebration. Paid statutory holiday.'
        }
      ]
    }
  ];
});

// ─── Navigation Handlers ───
const handlePrevMonth = () => {
  const d = new Date(currentDate.value);
  d.setMonth(d.getMonth() - 1);
  currentDate.value = d;
  miniCalendarDate.value = new Date(d);
  handleClosePopover();
};

const handleNextMonth = () => {
  const d = new Date(currentDate.value);
  d.setMonth(d.getMonth() + 1);
  currentDate.value = d;
  miniCalendarDate.value = new Date(d);
  handleClosePopover();
};

const handleMiniPrev = () => {
  const d = new Date(miniCalendarDate.value);
  d.setMonth(d.getMonth() - 1);
  miniCalendarDate.value = d;
};

const handleMiniNext = () => {
  const d = new Date(miniCalendarDate.value);
  d.setMonth(d.getMonth() + 1);
  miniCalendarDate.value = d;
};

const jumpToToday = () => {
  currentDate.value = new Date(2027, 11, 17);
  selectedDate.value = new Date(2027, 11, 17);
  miniCalendarDate.value = new Date(2027, 7, 1);
  handleClosePopover();
};
</script>

<template>
  <div class="calendar-page-layout" @click="handleClosePopover">
    
    <!-- ─── Top Breadcrumb Navigation (Rule 3) ─── -->
    <div class="calendar-top-header">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ─── Top Company Calendar Card (Figma Exact Layout) ─── -->
    <div class="company-calendar-card">
      <div class="company-calendar-info">
        <h1 class="company-title">Company Calendar</h1>
        <p class="company-subtitle">
          Corporate operational schedules, statutory Ethiopian &amp; Gregorian holiday observances, and workforce shift windows across entities.
        </p>
        <div class="company-today-text" @click="jumpToToday">
          Today: Thursday, Sep 17, 2027
        </div>
      </div>

      <div class="company-calendar-selector">
        <label class="selector-label">Select Work Calendar</label>
        <div class="select-wrapper">
          <select v-model="selectedCalendarId" class="work-calendar-dropdown">
            <option v-for="cal in companyCalendars" :key="cal.id" :value="cal.id">
              {{ cal.name }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <!-- ─── Master Calendar Container ─── -->
    <div class="calendar-master-container">

      <!-- ─── Header Toolbar Bar ─── -->
      <div class="calendar-toolbar-row">
        <!-- Left: Today Button -->
        <button type="button" class="btn-today-pill" @click="jumpToToday">
          <CalendarIcon :size="16" class="icon-today" />
          <span>Today</span>
        </button>

        <!-- Center: Month Navigation Controls -->
        <div class="month-nav-group">
          <button type="button" class="btn-circle-nav" @click="handlePrevMonth" title="Previous Month">
            <ChevronLeft :size="18" />
          </button>
          <span class="nav-month-title">{{ currentMonthYear.monthName }} , {{ currentMonthYear.year }}</span>
          <button type="button" class="btn-circle-nav" @click="handleNextMonth" title="Next Month">
            <ChevronRight :size="18" />
          </button>
        </div>

        <!-- Right: View Mode Capsule Tabs (Day | Week | Month | List) -->
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

      <!-- ─── Split Body: Blue Sidebar + Viewport ─── -->
      <div class="calendar-split-body">

        <!-- ════════════════════════════════════════════
             LEFT BLUE HERO SIDEBAR (Figma Signature)
        ════════════════════════════════════════════ -->
        <aside class="blue-calendar-sidebar">
          
          <!-- Top Watermark & Year -->
          <div class="sidebar-top-section">
            <div class="sidebar-watermark-year">{{ ethiopianYearText }}</div>
            <div class="sidebar-eth-title">Ethiopian Calendar</div>
          </div>

          <!-- Headline Date -->
          <div class="sidebar-date-headline">
            {{ selectedDateHeadline }}
          </div>

          <!-- Mini Calendar Month Picker -->
          <div class="sidebar-mini-picker">
            <div class="mini-picker-header">
              <span class="mini-picker-title">{{ miniMonthTitle }} ⌵</span>
              <div class="mini-picker-arrows">
                <button type="button" class="mini-chevron" @click="handleMiniPrev">‹</button>
                <button type="button" class="mini-chevron" @click="handleMiniNext">›</button>
              </div>
            </div>

            <!-- Weekday Initials -->
            <div class="mini-week-row">
              <span>S</span><span>M</span><span>T</span><span>W</span><span>T</span><span>F</span><span>S</span>
            </div>

            <!-- Mini Grid -->
            <div class="mini-days-grid" :class="{ 'mini-days-grid--week-highlight': currentView === 'week' }">
              <div
                v-for="(mDay, idx) in miniMonthDays"
                :key="idx"
                class="mini-day-cell"
                :class="{
                  'mini-day-cell--inactive': !mDay.isCurrentMonth,
                  'mini-day-cell--selected': mDay.isSelected,
                  'mini-day-cell--week-band': currentView === 'week' && mDay.day >= 13 && mDay.day <= 19 && mDay.isCurrentMonth
                }"
              >
                <span>{{ mDay.day }}</span>
              </div>
            </div>
          </div>

          <!-- Today's Event Section -->
          <div class="sidebar-events-section">
            <div class="today-event-badge">Today's Event</div>
            <div class="today-events-list">
              <div v-for="(ev, idx) in todayEventsList" :key="idx" class="today-event-item">
                <div class="event-item-title">
                  <span class="bullet-arrow">›</span>
                  <span>{{ ev.title }}</span>
                </div>
                <div class="event-item-time">{{ ev.time }}</div>
              </div>
            </div>
          </div>

        </aside>

        <!-- ════════════════════════════════════════════
             RIGHT CALENDAR MAIN VIEWS
        ════════════════════════════════════════════ -->
        <main class="calendar-viewport-area">

          <!-- ──────────────────────────────────────────
               1. MONTH VIEW (Figma Image 2 & 5)
          ────────────────────────────────────────── -->
          <div v-if="currentView === 'month'" class="view-month-matrix">
            
            <!-- Weekday Header (7 Columns) -->
            <div class="month-weekday-header">
              <div class="weekday-header-col">Sunday</div>
              <div class="weekday-header-col">Monday</div>
              <div class="weekday-header-col">Thursday</div>
              <div class="weekday-header-col">Wednesday</div>
              <div class="weekday-header-col">Tuesday</div>
              <div class="weekday-header-col">Friday</div>
              <div class="weekday-header-col">Saturday</div>
            </div>

            <!-- 5x7 Month Grid Cells -->
            <div class="month-cells-grid">
              <div
                v-for="(cell, cIdx) in monthGrid"
                :key="cIdx"
                class="month-cell-box"
                :class="{ 'month-cell-box--other': !cell.isCurrentMonth }"
              >
                <!-- Cell Day Label / Circle Badge -->
                <div class="month-cell-header">
                  <span v-if="cell.isDay17" class="day-badge-solid-blue">17</span>
                  <span v-else-if="cell.isDay16" class="day-badge-light-blue">16</span>
                  <span v-else class="day-label-text">{{ cell.label }}</span>

                  <!-- Schema Planned Hours Indicator -->
                  <span v-if="cell.isCurrentMonth" class="day-hours-hint">
                    {{ cell.plannedHours > 0 ? `${cell.plannedHours}h` : 'Rest' }}
                  </span>
                </div>

                <!-- Events Chips Inside Cell -->
                <div class="month-cell-events">
                  
                  <!-- Schema Events Stack -->
                  <template v-for="ev in cell.events" :key="ev.id">
                    <div
                      class="event-pill"
                      :class="`event-pill--${ev.badgeVariant || 'green'}`"
                      @click="handleOpenPopover(ev, $event)"
                    >
                      <span v-if="ev.title === 'Ye Gena Beal'" class="pill-icon-lead">🪔</span>
                      <span class="pill-title-text">{{ ev.title }}</span>
                    </div>
                  </template>

                  <!-- Overflow Pill (+3) for Day 18 -->
                  <div v-if="cell.isCurrentMonth && cell.dayNum === 18" class="cell-overflow-indicator">
                    +3
                  </div>

                </div>
              </div>
            </div>

          </div>

          <!-- ──────────────────────────────────────────
               2. WEEK VIEW (Figma Image 1)
          ────────────────────────────────────────── -->
          <div v-else-if="currentView === 'week'" class="view-week-matrix">
            
            <!-- Week Header (Time Column + 7 Days) -->
            <div class="week-header-row">
              <div class="week-time-gutter"></div>
              <div
                v-for="wDay in weekDays"
                :key="wDay.dayNum"
                class="week-day-header-col"
                :class="{ 'week-day-header-col--active': wDay.isCurrent }"
              >
                <span class="w-day-num">{{ wDay.dayNum }}</span>
                <span class="w-day-name">{{ wDay.name }}</span>
              </div>
            </div>

            <!-- Hourly Scrollable Grid -->
            <div class="week-hourly-scroll">
              <div
                v-for="(timeLabel, tIdx) in timeSlots"
                :key="tIdx"
                class="week-time-row"
              >
                <!-- Left Hour Label -->
                <div class="hour-label-cell">{{ timeLabel }}</div>

                <!-- 7 Day Columns for this hour -->
                <div
                  v-for="wDay in weekDays"
                  :key="wDay.dayNum"
                  class="hour-slot-cell"
                >
                  <!-- Committee Meeting at 12 AM (Sunday 13 & Wednesday 16) -->
                  <div
                    v-if="tIdx === 0 && (wDay.dayNum === 13 || wDay.dayNum === 16)"
                    class="week-event-chip chip-gray"
                    @click="handleOpenPopover(masterEvents[0], $event)"
                  >
                    Committee Mee...
                  </div>

                  <!-- Culture Day at 1 AM (Saturday 19) -->
                  <div
                    v-if="tIdx === 1 && wDay.dayNum === 19"
                    class="week-event-chip chip-blue"
                    @click="handleOpenPopover(masterEvents[6], $event)"
                  >
                    Culture Day
                  </div>

                  <!-- Executive Committee Meeting at 3 AM (Tuesday 17) -->
                  <div
                    v-if="tIdx === 3 && wDay.dayNum === 17"
                    class="week-event-chip chip-pink"
                    @click="handleOpenPopover(masterEvents[3], $event)"
                  >
                    Executive Committee Meeting
                  </div>

                  <!-- Meskel at 8 AM (Monday 14) -->
                  <div
                    v-if="tIdx === 8 && wDay.dayNum === 14"
                    class="week-event-chip chip-gray"
                    @click="handleOpenPopover(masterEvents[1], $event)"
                  >
                    Meskel
                  </div>

                  <!-- Enkutatash Ethiopian New Year at 8 AM (Saturday 19) -->
                  <div
                    v-if="tIdx === 8 && wDay.dayNum === 19"
                    class="week-event-chip chip-green"
                    @click="handleOpenPopover(masterEvents[7], $event)"
                  >
                    Enkutatash Ethi...
                  </div>
                </div>
              </div>
            </div>

          </div>

          <!-- ──────────────────────────────────────────
               3. DAY VIEW (Figma Image 4)
          ────────────────────────────────────────── -->
          <div v-else-if="currentView === 'day'" class="view-day-matrix">
            
            <!-- Single Day Header with Schema Metadata -->
            <div class="day-header-bar">
              <div class="day-time-gutter"></div>
              <div class="day-header-title">
                <span class="day-title-num">17</span>
                <span class="day-title-name">Thursday</span>
                <span class="day-title-badge">Working Day • {{ selectedCalendar.dailyHours }}h Shift</span>
              </div>
            </div>

            <!-- 24-Hour Slots -->
            <div class="day-hourly-scroll">
              <div
                v-for="(timeLabel, tIdx) in timeSlots"
                :key="tIdx"
                class="day-time-row"
              >
                <!-- Left Hour Label -->
                <div class="hour-label-cell">{{ timeLabel }}</div>

                <!-- Main Day Slot Content -->
                <div class="day-slot-content">
                  <!-- Scheduled Event Banner at 2 AM (Per Figma Image 4) -->
                  <div
                    v-if="tIdx === 2"
                    class="day-banner-event"
                    @click="handleOpenPopover(masterEvents[7], $event)"
                  >
                    Enkutatash Ethiopian New Year
                  </div>

                  <!-- Executive Committee Meeting at 10 AM -->
                  <div
                    v-else-if="tIdx === 10"
                    class="day-banner-meeting"
                    @click="handleOpenPopover(masterEvents[3], $event)"
                  >
                    Executive Committee Meeting (10:00 AM – 12:30 PM) • Executive Boardroom
                  </div>

                  <!-- Standard Work Shift Window Indication -->
                  <div
                    v-else-if="tIdx === 8"
                    class="day-banner-shift-start"
                  >
                    Office Shift Starts (08:30) • Grace Period 15 min (08:45)
                  </div>

                  <!-- Lunch Break Indication -->
                  <div
                    v-else-if="tIdx === 12"
                    class="day-banner-break"
                  >
                    Statutory Lunch Break (12:30 – 13:30) • Unpaid 60 min
                  </div>
                </div>
              </div>
            </div>

          </div>

          <!-- ──────────────────────────────────────────
               4. LIST VIEW (Figma Image 3)
          ────────────────────────────────────────── -->
          <div v-else-if="currentView === 'list'" class="view-list-matrix">
            
            <!-- Chronological Schema-Driven Agenda Groups -->
            <div
              v-for="group in listAgendaGroups"
              :key="group.dateStr"
              class="list-date-group"
            >
              <!-- Group Header -->
              <div class="list-group-header">
                <span class="list-header-num">{{ group.dayNum }}</span>
                <span class="list-header-name">{{ group.dayName }}</span>
                <span class="list-header-daytype">{{ group.dayType }}</span>
                <span v-if="group.plannedHours > 0" class="list-header-hours">({{ group.plannedHours }}h planned)</span>
              </div>

              <!-- Events for this Date -->
              <div
                v-for="item in group.items"
                :key="item.id"
                class="list-event-row"
              >
                <span class="list-event-time">{{ item.time }}</span>
                <span class="list-dot" :class="`dot-${item.dotVariant}`">●</span>
                <div class="list-event-meta">
                  <span class="list-event-title">{{ item.title }}</span>
                  <span class="list-event-badge">{{ item.badge }}</span>
                  <span v-if="item.otMultiplier" class="list-ot-tag">Labour OT {{ item.otMultiplier }}</span>
                </div>
              </div>

              <!-- Extra Time Slot Dividers per Figma Image 3 -->
              <div v-if="group.dayNum === 20" class="list-time-slot-divider">7:30 PM</div>
              <div v-if="group.dayNum === 20" class="list-time-slot-divider">12:30 AM</div>
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
          <span class="badge-icon">🪔</span>
          <span>{{ activePopoverEvent.badgeLabel || 'Rest Day' }}</span>
        </span>
      </div>

      <div class="popover-meta-row">
        <Clock :size="14" class="popover-icon" />
        <span>
          {{ activePopoverEvent.dayType === 'holiday' ? 'Mon 12/22/2027 (Work is off on this day)' : activePopoverEvent.time }}
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
  padding: 16px 24px 36px 24px;
  background-color: #f8fafc;
  min-height: calc(100vh - 64px);
  box-sizing: border-box;
}

.calendar-top-header {
  margin-bottom: 12px;
}

/* ─── Top Company Calendar Card ─── */
.company-calendar-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 22px 26px;
  margin-bottom: 18px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}

.company-calendar-info {
  display: flex;
  flex-direction: column;
}

.company-title {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.company-subtitle {
  font-size: 13px;
  color: #737373;
  margin: 0 0 8px 0;
  max-width: 820px;
  line-height: 1.45;
}

.company-today-text {
  font-size: 13px;
  font-weight: 500;
  color: #0B529C;
  cursor: pointer;
  width: fit-content;
}

.company-today-text:hover {
  text-decoration: underline;
}

.company-calendar-selector {
  display: flex;
  flex-direction: column;
  min-width: 260px;
}

.selector-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 5px;
}

.select-wrapper {
  position: relative;
}

.work-calendar-dropdown {
  width: 100%;
  height: 38px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 0 12px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  cursor: pointer;
  outline: none;
  transition: border-color 0.15s ease;
}

.work-calendar-dropdown:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

/* ─── Master Calendar Container ─── */
.calendar-master-container {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 24px 28px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}

/* ─── Toolbar Header Row ─── */
.calendar-toolbar-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 22px;
}

.btn-today-pill {
  height: 40px;
  padding: 0 20px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #404040;
  font-size: 13.5px;
  font-weight: 500;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: all 0.15s ease;
}

.btn-today-pill:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
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
  border: 1px solid #e2e8f0;
  background: #ffffff;
  color: #404040;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}

.btn-circle-nav:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
}

.nav-month-title {
  font-size: 20px;
  font-weight: 600;
  color: #404040;
  letter-spacing: -0.01em;
}

/* ─── View Mode Capsule Tabs ─── */
.view-capsule-switcher {
  display: inline-flex;
  background: #f1f5f9;
  border-radius: 9999px;
  padding: 4px;
  gap: 4px;
}

.capsule-tab-item {
  border: none;
  background: transparent;
  color: #64748b;
  font-size: 13px;
  font-weight: 500;
  padding: 6px 16px;
  border-radius: 9999px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.capsule-tab-item:hover {
  color: #0f172a;
}

.capsule-tab-item--active {
  background: #ffffff;
  color: #0f172a;
  font-weight: 600;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

/* ─── Split Body: Sidebar + Main ─── */
.calendar-split-body {
  display: grid;
  grid-template-columns: 325px 1fr;
  gap: 22px;
  min-height: 639px;
  align-items: stretch;
}

/* ════════════════════════════════════════════
   LEFT BLUE HERO SIDEBAR
════════════════════════════════════════════ */
.blue-calendar-sidebar {
  width: 325px;
  background: #0B529C;
  border-radius: 14px;
  padding: 24px 20px;
  color: #ffffff;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  box-sizing: border-box;
}

.sidebar-top-section {
  position: relative;
}

.sidebar-watermark-year {
  font-size: 52px;
  font-weight: 700;
  line-height: 1;
  letter-spacing: -0.02em;
  color: #ffffff;
}

.sidebar-eth-title {
  font-size: 12.5px;
  color: rgba(255, 255, 255, 0.85);
  margin-top: 4px;
}

.sidebar-date-headline {
  font-size: 21px;
  font-weight: 600;
  color: #ffffff;
  margin: 18px 0 12px 0;
}

/* ─── Mini Calendar ─── */
.sidebar-mini-picker {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 10px;
  padding: 12px 14px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.mini-picker-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  font-weight: 500;
  color: #ffffff;
  margin-bottom: 8px;
}

.mini-picker-title {
  cursor: pointer;
}

.mini-picker-arrows {
  display: flex;
  gap: 10px;
}

.mini-chevron {
  background: transparent;
  border: none;
  color: #ffffff;
  font-size: 16px;
  cursor: pointer;
  line-height: 1;
  padding: 0 4px;
  opacity: 0.8;
}

.mini-chevron:hover {
  opacity: 1;
}

.mini-week-row {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  text-align: center;
  font-size: 11px;
  color: rgba(255, 255, 255, 0.7);
  margin-bottom: 6px;
  font-weight: 500;
}

.mini-days-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  row-gap: 4px;
  text-align: center;
  font-size: 12px;
}

.mini-day-cell {
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  border-radius: 50%;
  cursor: pointer;
  font-size: 11.5px;
}

.mini-day-cell--inactive {
  opacity: 0.35;
}

.mini-day-cell--selected {
  background-color: #f59e0b !important;
  color: #ffffff !important;
  font-weight: 600;
}

.mini-day-cell--week-band {
  background-color: rgba(255, 255, 255, 0.15);
  border-radius: 4px;
}

/* ─── Today's Events in Sidebar ─── */
.sidebar-events-section {
  margin-top: 18px;
}

.today-event-badge {
  display: inline-block;
  background: rgba(255, 255, 255, 0.18);
  border-radius: 9999px;
  padding: 4px 14px;
  font-size: 11px;
  font-weight: 500;
  color: #ffffff;
  margin-bottom: 12px;
}

.today-events-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.today-event-item {
  display: flex;
  flex-direction: column;
}

.event-item-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 500;
  color: #ffffff;
}

.bullet-arrow {
  font-size: 15px;
  line-height: 1;
}

.event-item-time {
  font-size: 11px;
  color: rgba(255, 255, 255, 0.7);
  margin-left: 14px;
}

/* ════════════════════════════════════════════
   RIGHT CALENDAR VIEWPORT
════════════════════════════════════════════ */
.calendar-viewport-area {
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  overflow: hidden;
  background: #ffffff;
  display: flex;
  flex-direction: column;
}

/* ─── 1. MONTH VIEW ─── */
.view-month-matrix {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.month-weekday-header {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  border-bottom: 1px solid #e2e8f0;
  background: #ffffff;
}

.weekday-header-col {
  padding: 12px 10px;
  text-align: center;
  font-size: 12.5px;
  color: #737373;
  font-weight: 500;
}

.month-cells-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  grid-template-rows: repeat(5, minmax(115px, 1fr));
  flex: 1;
}

.month-cell-box {
  border-right: 1px solid #e2e8f0;
  border-bottom: 1px solid #e2e8f0;
  padding: 8px 10px;
  display: flex;
  flex-direction: column;
  position: relative;
  background: #ffffff;
  min-height: 115px;
}

.month-cell-box:nth-child(7n) {
  border-right: none;
}

.month-cell-box--other .day-label-text {
  color: #94a3b8;
}

.month-cell-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.day-label-text {
  font-size: 12.5px;
  color: #404040;
  font-weight: 500;
}

.day-hours-hint {
  font-size: 10px;
  color: #94a3b8;
  font-weight: 500;
}

.day-badge-light-blue {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #e0f2fe;
  color: #0284c7;
  font-size: 12px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
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

.month-cell-events {
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
}

.event-pill {
  padding: 4px 8px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  transition: opacity 0.15s ease;
}

.event-pill:hover {
  opacity: 0.9;
}

.event-pill--purple {
  background: #f5f3ff;
  color: #7c3aed;
}

.event-pill--green {
  background: #ecfdf5;
  color: #059669;
}

.event-pill--blue {
  background: #eff6ff;
  color: #1d4ed8;
}

.event-pill--pink {
  background: #fdf2f8;
  color: #db2777;
}

.event-pill--gray {
  background: #f1f5f9;
  color: #404040;
}

.pill-icon-lead {
  font-size: 12px;
}

.pill-title-text {
  overflow: hidden;
  text-overflow: ellipsis;
}

.cell-overflow-indicator {
  font-size: 11px;
  font-weight: 600;
  color: #0284c7;
  text-align: right;
  margin-top: auto;
}

/* ─── 2. WEEK VIEW ─── */
.view-week-matrix {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.week-header-row {
  display: grid;
  grid-template-columns: 65px repeat(7, 1fr);
  border-bottom: 1px solid #e2e8f0;
  background: #ffffff;
}

.week-time-gutter {
  border-right: 1px solid #e2e8f0;
}

.week-day-header-col {
  padding: 10px 6px;
  text-align: center;
  border-right: 1px solid #e2e8f0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-size: 13px;
}

.week-day-header-col:last-child {
  border-right: none;
}

.w-day-num {
  font-weight: 600;
  color: #0B529C;
}

.w-day-name {
  color: #404040;
}

.week-day-header-col--active {
  background: #0B529C;
  color: #ffffff;
}

.week-day-header-col--active .w-day-num,
.week-day-header-col--active .w-day-name {
  color: #ffffff !important;
}

.week-hourly-scroll {
  flex: 1;
  max-height: 580px;
  overflow-y: auto;
}

.week-time-row {
  display: grid;
  grid-template-columns: 65px repeat(7, 1fr);
  min-height: 48px;
  border-bottom: 1px solid #f1f5f9;
}

.hour-label-cell {
  padding: 8px 8px;
  text-align: right;
  font-size: 11px;
  color: #737373;
  border-right: 1px solid #e2e8f0;
}

.hour-slot-cell {
  border-right: 1px solid #f1f5f9;
  padding: 4px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.hour-slot-cell:last-child {
  border-right: none;
}

.week-event-chip {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  cursor: pointer;
}

.chip-gray {
  background: #f1f5f9;
  color: #404040;
}

.chip-blue {
  background: #eff6ff;
  color: #1d4ed8;
}

.chip-pink {
  background: #fdf2f8;
  color: #db2777;
}

.chip-green {
  background: #ecfdf5;
  color: #059669;
}

/* ─── 3. DAY VIEW ─── */
.view-day-matrix {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.day-header-bar {
  display: grid;
  grid-template-columns: 65px 1fr;
  border-bottom: 1px solid #e2e8f0;
  padding: 12px 14px;
}

.day-header-title {
  display: flex;
  align-items: center;
  gap: 12px;
}

.day-title-num {
  font-size: 16px;
  font-weight: 700;
  color: #0B529C;
}

.day-title-name {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.day-title-badge {
  font-size: 12px;
  color: #0B529C;
  background: #eff6ff;
  padding: 3px 10px;
  border-radius: 6px;
  font-weight: 500;
}

.day-hourly-scroll {
  flex: 1;
  max-height: 580px;
  overflow-y: auto;
}

.day-time-row {
  display: grid;
  grid-template-columns: 65px 1fr;
  min-height: 50px;
  border-bottom: 1px solid #f1f5f9;
}

.day-slot-content {
  padding: 6px 14px;
  display: flex;
  align-items: center;
  gap: 10px;
}

.day-banner-event {
  width: 100%;
  background: #ecfdf5;
  border-left: 3px solid #10b981;
  color: #065f46;
  font-size: 13px;
  font-weight: 500;
  padding: 8px 14px;
  border-radius: 4px;
  cursor: pointer;
}

.day-banner-meeting {
  width: 100%;
  background: #fdf2f8;
  border-left: 3px solid #db2777;
  color: #9d174d;
  font-size: 13px;
  font-weight: 500;
  padding: 8px 14px;
  border-radius: 4px;
  cursor: pointer;
}

.day-banner-shift-start {
  width: 100%;
  background: #eff6ff;
  border-left: 3px solid #3b82f6;
  color: #1e40af;
  font-size: 12px;
  font-weight: 500;
  padding: 6px 12px;
  border-radius: 4px;
}

.day-banner-break {
  width: 100%;
  background: #f8fafc;
  border-left: 3px solid #94a3b8;
  color: #64748b;
  font-size: 12px;
  font-weight: 500;
  padding: 6px 12px;
  border-radius: 4px;
}

/* ─── 4. LIST VIEW ─── */
.view-list-matrix {
  display: flex;
  flex-direction: column;
  padding: 16px 20px;
  gap: 18px;
  height: 100%;
  overflow-y: auto;
}

.list-date-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.list-group-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding-bottom: 6px;
  border-bottom: 1px solid #e2e8f0;
}

.list-header-num {
  font-size: 15px;
  font-weight: 700;
  color: #0B529C;
}

.list-header-name {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.list-header-daytype {
  font-size: 12px;
  color: #737373;
  margin-left: 4px;
}

.list-header-hours {
  font-size: 11.5px;
  color: #94a3b8;
}

.list-event-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 0;
}

.list-event-time {
  font-size: 12px;
  color: #737373;
  min-width: 75px;
}

.list-dot {
  font-size: 11px;
}

.dot-amber { color: #f59e0b; }
.dot-blue { color: #0284c7; }
.dot-green { color: #10b981; }
.dot-purple { color: #7c3aed; }

.list-event-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.list-event-title {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.list-event-badge {
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 4px;
  background: #f1f5f9;
  color: #475569;
  font-weight: 500;
}

.list-ot-tag {
  font-size: 10.5px;
  padding: 2px 6px;
  border-radius: 4px;
  background: #ecfdf5;
  color: #059669;
  font-weight: 600;
}

.list-time-slot-divider {
  font-size: 11.5px;
  color: #94a3b8;
  padding-left: 87px;
  padding-top: 4px;
}

/* ════════════════════════════════════════════
   FLOATING EVENT POPOVER CARD
════════════════════════════════════════════ */
.event-details-popover {
  position: absolute;
  width: 330px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
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
  background: #f5f3ff;
  color: #7c3aed;
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
  color: #64748b;
  margin-top: 4px;
}

.popover-icon {
  color: #94a3b8;
  flex-shrink: 0;
}

.icon-desc {
  margin-top: 2px;
}

.popover-desc-text {
  margin: 0;
}
</style>
