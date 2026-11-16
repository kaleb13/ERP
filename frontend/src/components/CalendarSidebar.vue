<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import {
  ChevronLeft,
  ChevronRight,
  ChevronDown
} from 'lucide-vue-next';
import ellipseDarkerUrl from '../assets/ellipse-darker.svg';
import ellipseLightUrl from '../assets/ellipse-light.svg';

export interface CalendarEventItem {
  id?: string;
  title: string;
  time?: string;
  category?: string;
  badgeVariant?: string;
  date?: string;
  [key: string]: any;
}

export interface DayCell {
  day: number;
  date: Date;
  dateStr: string;
  isCurrentMonth: boolean;
  isSelected: boolean;
  isToday: boolean;
}

export interface WeekRow {
  days: DayCell[];
  hasSelectedDay: boolean;
  hasToday: boolean;
}

const props = withDefaults(
  defineProps<{
    modelValue?: Date;
    viewMode?: 'week' | 'month' | 'day' | 'list';
    today?: Date;
    calendarType?: string;
    events?: CalendarEventItem[];
  }>(),
  {
    modelValue: () => new Date(2027, 11, 17),
    viewMode: 'month',
    today: () => new Date(2027, 11, 17),
    calendarType: 'Gregorian calendar',
    events: () => [
      { id: 'ev-1', title: 'Office Meeting', time: '11:30' },
      { id: 'ev-2', title: 'Culture Day', time: '11:30' }
    ]
  }
);

const emit = defineEmits<{
  (e: 'update:modelValue', value: Date): void;
  (e: 'update:viewMode', value: 'week' | 'month' | 'day' | 'list'): void;
  (e: 'dateSelect', date: Date): void;
  (e: 'monthChange', payload: { year: number; month: number }): void;
  (e: 'eventClick', event: CalendarEventItem): void;
}>();

// ─── Internal State ───
// Picker modes: 'days' (standard 7x5/6 date grid), 'months' (4x3 12-month selector), 'years' (4x3 12-year window)
type PickerMode = 'days' | 'months' | 'years';
const pickerMode = ref<PickerMode>('days');

// Currently navigated date inside sidebar
const viewingDate = ref(new Date(props.modelValue || props.today));

// 12-Year Window Range Start (for 'years' mode)
const yearRangeStart = ref(2018);

// Keep viewingDate in sync when modelValue updates externally
watch(
  () => props.modelValue,
  (newVal) => {
    if (newVal) {
      viewingDate.value = new Date(newVal);
      // Keep yearRangeStart in a 12-year window containing viewingDate
      const yr = newVal.getFullYear();
      yearRangeStart.value = Math.floor((yr - 2) / 12) * 12 + 2;
    }
  },
  { immediate: true }
);

// Format Helpers
const monthNamesShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const monthNamesFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];
const dayNamesShort = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// Year Headline & Watermark
const displayYear = computed(() => viewingDate.value.getFullYear());

// Active Date Headline (e.g. "Thu, Dec 17")
const selectedDateHeadline = computed(() => {
  const d = props.modelValue || props.today;
  return `${dayNamesShort[d.getDay()]}, ${monthNamesShort[d.getMonth()]} ${d.getDate()}`;
});

// Selection Row Pill Label
const currentSelectionPill = computed(() => {
  if (pickerMode.value === 'days') {
    return `${monthNamesFull[viewingDate.value.getMonth()]} ${viewingDate.value.getFullYear()}`;
  }
  if (pickerMode.value === 'months') {
    return `${viewingDate.value.getFullYear()}`;
  }
  return `${yearRangeStart.value} - ${yearRangeStart.value + 11}`;
});

// 12-Year Window Array
const yearWindowArray = computed(() => {
  const years: number[] = [];
  for (let i = 0; i < 12; i++) {
    years.push(yearRangeStart.value + i);
  }
  return years;
});

// Mini Calendar Days Matrix
const miniCalendarWeeks = computed<WeekRow[]>(() => {
  const y = viewingDate.value.getFullYear();
  const m = viewingDate.value.getMonth();
  const firstDay = new Date(y, m, 1).getDay();
  const totalDays = new Date(y, m + 1, 0).getDate();
  const prevMonthDays = new Date(y, m, 0).getDate();

  const selectedStr = (props.modelValue || props.today).toDateString();
  const todayStr = props.today.toDateString();

  const allDays: DayCell[] = [];

  // Trailing previous month days
  for (let i = firstDay - 1; i >= 0; i--) {
    const d = new Date(y, m - 1, prevMonthDays - i);
    const dStr = d.toDateString();
    allDays.push({
      day: d.getDate(),
      date: d,
      dateStr: `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`,
      isCurrentMonth: false,
      isSelected: dStr === selectedStr,
      isToday: dStr === todayStr
    });
  }

  // Current month days
  for (let i = 1; i <= totalDays; i++) {
    const d = new Date(y, m, i);
    const dStr = d.toDateString();
    allDays.push({
      day: i,
      date: d,
      dateStr: `${y}-${String(m + 1).padStart(2, '0')}-${String(i).padStart(2, '0')}`,
      isCurrentMonth: true,
      isSelected: dStr === selectedStr,
      isToday: dStr === todayStr
    });
  }

  // Leading next month days
  const targetTotal = allDays.length > 35 ? 42 : 35;
  let nextDayNum = 1;
  while (allDays.length < targetTotal) {
    const d = new Date(y, m + 1, nextDayNum);
    const dStr = d.toDateString();
    allDays.push({
      day: nextDayNum,
      date: d,
      dateStr: `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(nextDayNum).padStart(2, '0')}`,
      isCurrentMonth: false,
      isSelected: dStr === selectedStr,
      isToday: dStr === todayStr
    });
    nextDayNum++;
  }

  // Chunk into 7-day rows
  const weeks: WeekRow[] = [];
  for (let i = 0; i < allDays.length; i += 7) {
    const weekSlice = allDays.slice(i, i + 7);
    weeks.push({
      days: weekSlice,
      hasSelectedDay: weekSlice.some((d) => d.isSelected),
      hasToday: weekSlice.some((d) => d.isToday)
    });
  }

  return weeks;
});

// Filtered / Displayed Today's Events
const todaysEventsList = computed(() => {
  if (props.events && props.events.length > 0) {
    return props.events.slice(0, 3);
  }
  return [
    { id: 'default-1', title: 'Office Meeting', time: '11:30' },
    { id: 'default-2', title: 'Culture Day', time: '11:30' }
  ];
});

// ─── Actions & Handlers ───

// Toggle between 'days', 'months', 'years'
const handlePillClick = () => {
  if (pickerMode.value === 'days') {
    pickerMode.value = 'months';
  } else if (pickerMode.value === 'months') {
    pickerMode.value = 'years';
  } else {
    pickerMode.value = 'days';
  }
};

// Navigation Prev
const handlePrev = () => {
  if (pickerMode.value === 'days') {
    const d = new Date(viewingDate.value);
    d.setMonth(d.getMonth() - 1);
    viewingDate.value = d;
    emit('monthChange', { year: d.getFullYear(), month: d.getMonth() });
  } else if (pickerMode.value === 'months') {
    const d = new Date(viewingDate.value);
    d.setFullYear(d.getFullYear() - 1);
    viewingDate.value = d;
  } else if (pickerMode.value === 'years') {
    yearRangeStart.value -= 12;
  }
};

// Navigation Next
const handleNext = () => {
  if (pickerMode.value === 'days') {
    const d = new Date(viewingDate.value);
    d.setMonth(d.getMonth() + 1);
    viewingDate.value = d;
    emit('monthChange', { year: d.getFullYear(), month: d.getMonth() });
  } else if (pickerMode.value === 'months') {
    const d = new Date(viewingDate.value);
    d.setFullYear(d.getFullYear() + 1);
    viewingDate.value = d;
  } else if (pickerMode.value === 'years') {
    yearRangeStart.value += 12;
  }
};

// Date Cell Selection
const handleSelectDay = (cell: DayCell) => {
  const chosen = new Date(cell.date);
  emit('update:modelValue', chosen);
  emit('dateSelect', chosen);

  // If clicked a day outside current viewing month, update viewing month too
  if (!cell.isCurrentMonth) {
    viewingDate.value = new Date(chosen.getFullYear(), chosen.getMonth(), 1);
    emit('monthChange', { year: chosen.getFullYear(), month: chosen.getMonth() });
  }
};

// Month Selection (from 'months' mode)
const handleSelectMonth = (monthIndex: number) => {
  const d = new Date(viewingDate.value);
  d.setMonth(monthIndex);
  viewingDate.value = d;

  // Update selected date to keep the same day-of-month if possible
  const currentSelected = props.modelValue || props.today;
  const newSelected = new Date(d.getFullYear(), monthIndex, Math.min(currentSelected.getDate(), 28));
  emit('update:modelValue', newSelected);
  emit('monthChange', { year: d.getFullYear(), month: monthIndex });

  // Return to date view
  pickerMode.value = 'days';
};

// Year Selection (from 'years' mode)
const handleSelectYear = (year: number) => {
  const d = new Date(viewingDate.value);
  d.setFullYear(year);
  viewingDate.value = d;

  const currentSelected = props.modelValue || props.today;
  const newSelected = new Date(year, currentSelected.getMonth(), Math.min(currentSelected.getDate(), 28));
  emit('update:modelValue', newSelected);

  // Switch to months mode for that year
  pickerMode.value = 'months';
};
</script>

<template>
  <aside class="calendar-sidebar-root" aria-label="Calendar Date Filtering Section">
    
    <!-- ─── Atmospheric Decorative Background Ellipses (Figma 8832:36492 / 6328:120021) ─── -->
    <div class="sidebar-bg-effects" aria-hidden="true">
      <img :src="ellipseDarkerUrl" class="sidebar-ellipse-darker" alt="" />
      <img :src="ellipseLightUrl" class="sidebar-ellipse-light" alt="" />
    </div>

    <!-- ─── Giant Ghost Watermark Year (Figma 6328:120028) ─── -->
    <div class="sidebar-watermark-year" aria-hidden="true">
      {{ displayYear }}
    </div>

    <!-- ─── Header Section (Figma 6328:120024: 171px with hairline border) ─── -->
    <div class="sidebar-header-section">
      <h2 class="sidebar-year-headline">{{ displayYear }}</h2>
      <p class="sidebar-cal-type">{{ calendarType }}</p>
    </div>

    <!-- ─── Body Section of Sidebar (Figma 6328:120029) ─── -->
    <div class="sidebar-body-section">

      <!-- Active Headline Date (Figma 6328:120031 / 6328:120198) -->
      <div 
        class="sidebar-active-date"
        :class="{ 'sidebar-active-date--dimmed': pickerMode !== 'days' }"
      >
        {{ selectedDateHeadline }}
      </div>

      <!-- Month / Year / Range Selection & Control Arrows (Figma 6328:120032, 6328:120201, 6328:120278) -->
      <div class="sidebar-selection-row">
        <!-- Interactive Pill Button (Figma Building Blocks 6328:120345) -->
        <button 
          type="button" 
          class="sidebar-picker-toggle-pill"
          :class="`sidebar-picker-toggle-pill--${pickerMode}`"
          @click="handlePillClick"
          :title="pickerMode === 'days' ? 'Switch to Month selector' : pickerMode === 'months' ? 'Switch to Year selector' : 'Switch to Day grid'"
        >
          <span class="pill-label-text">{{ currentSelectionPill }}</span>
          <ChevronDown v-if="pickerMode !== 'years'" :size="13" class="pill-chevron-icon" />
        </button>

        <!-- Navigation Arrows (Figma 6328:120034) -->
        <div class="sidebar-nav-controls">
          <button 
            type="button" 
            class="sidebar-nav-arrow-btn" 
            @click="handlePrev" 
            :title="pickerMode === 'days' ? 'Previous Month' : pickerMode === 'months' ? 'Previous Year' : 'Previous 12 Years'"
          >
            <ChevronLeft :size="16" />
          </button>
          <button 
            type="button" 
            class="sidebar-nav-arrow-btn" 
            @click="handleNext" 
            :title="pickerMode === 'days' ? 'Next Month' : pickerMode === 'months' ? 'Next Year' : 'Next 12 Years'"
          >
            <ChevronRight :size="16" />
          </button>
        </div>
      </div>

      <!-- ═══════════════════════════════════════════════
           VIEW 1: DAYS MATRIX (Figma 6328:120038 / 6328:120125)
      ═══════════════════════════════════════════════ -->
      <div v-if="pickerMode === 'days'" class="sidebar-grid-container">
        
        <!-- Weekday Labels (S M T W T F S) -->
        <div class="sidebar-weekdays-row">
          <span class="sidebar-weekday-col">S</span>
          <span class="sidebar-weekday-col">M</span>
          <span class="sidebar-weekday-col">T</span>
          <span class="sidebar-weekday-col">W</span>
          <span class="sidebar-weekday-col">T</span>
          <span class="sidebar-weekday-col">F</span>
          <span class="sidebar-weekday-col">S</span>
        </div>

        <!-- 5-6 Rows of Weeks with Capsule Band in Week Mode (Figma 6328:120143 & 6328:120388) -->
        <div class="sidebar-weeks-list">
          <div
            v-for="(week, wIdx) in miniCalendarWeeks"
            :key="wIdx"
            class="sidebar-week-row"
            :class="{
              'sidebar-week-row--active-band': viewMode === 'week' && week.hasSelectedDay
            }"
          >
            <div
              v-for="cell in week.days"
              :key="cell.dateStr"
              class="sidebar-day-cell"
              @click="handleSelectDay(cell)"
            >
              <div
                class="sidebar-day-circle"
                :class="{
                  'sidebar-day-circle--muted': !cell.isCurrentMonth,
                  'sidebar-day-circle--selected': cell.isSelected,
                  'sidebar-day-circle--today-selected': cell.isSelected && cell.isToday,
                  'sidebar-day-circle--today-outline': cell.isToday && !cell.isSelected,
                  'sidebar-day-circle--in-band': viewMode === 'week' && week.hasSelectedDay && !cell.isSelected
                }"
              >
                <span>{{ cell.day }}</span>
              </div>
            </div>
          </div>
        </div>

      </div>

      <!-- ═══════════════════════════════════════════════
           VIEW 2: MONTH SELECT (Figma 6328:120188 / 6328:120207)
      ═══════════════════════════════════════════════ -->
      <div v-else-if="pickerMode === 'months'" class="sidebar-months-grid">
        <button
          v-for="(mName, mIdx) in monthNamesShort"
          :key="mIdx"
          type="button"
          class="sidebar-month-btn"
          :class="{
            'sidebar-month-btn--selected': viewingDate.getMonth() === mIdx
          }"
          @click="handleSelectMonth(mIdx)"
        >
          <span>{{ mName }}</span>
        </button>
      </div>

      <!-- ═══════════════════════════════════════════════
           VIEW 3: YEAR SELECT (Figma 6328:120265 / 6328:120286)
      ═══════════════════════════════════════════════ -->
      <div v-else-if="pickerMode === 'years'" class="sidebar-years-grid">
        <button
          v-for="yr in yearWindowArray"
          :key="yr"
          type="button"
          class="sidebar-year-btn"
          :class="{
            'sidebar-year-btn--selected': viewingDate.getFullYear() === yr
          }"
          @click="handleSelectYear(yr)"
        >
          <span>{{ yr }}</span>
        </button>
      </div>

      <!-- ─── Today's Events Section (Figma 6328:120102 / 5749:42930) ─── -->
      <div class="sidebar-todays-events">
        <div class="todays-event-badge">Today’s Event</div>
        <div class="todays-event-list">
          <div
            v-for="item in todaysEventsList"
            :key="item.id || item.title"
            class="todays-event-row"
            @click="emit('eventClick', item)"
          >
            <ChevronRight :size="14" class="event-chevron" />
            <div class="event-texts">
              <span class="event-name">{{ item.title }}</span>
              <span v-if="item.time" class="event-time">{{ item.time }}</span>
            </div>
          </div>
        </div>
      </div>

    </div>

  </aside>
</template>

<style scoped>
/* ─── Root Container (Figma 6328:120021: 325x639) ─── */
.calendar-sidebar-root {
  width: 325px;
  min-width: 325px;
  max-width: 325px;
  height: 639px;
  max-height: 639px;
  background-color: var(--alias-color-brand-default, #0B529C);
  border-top-left-radius: 20px;
  border-bottom-left-radius: 20px;
  color: #ffffff;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
  box-sizing: border-box;
  user-select: none;
}

/* ─── Atmospheric Decorative Background Effects (Figma 8832:36492 / 6328:120021) ─── */
.sidebar-bg-effects {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
  pointer-events: none;
  z-index: 1;
}

.sidebar-ellipse-darker {
  position: absolute;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 325px;
  height: 426px;
  pointer-events: none;
  mix-blend-mode: normal;
}

.sidebar-ellipse-light {
  position: absolute;
  top: 0;
  left: 0;
  width: 325px;
  height: 639px;
  pointer-events: none;
  mix-blend-mode: normal;
}

/* ─── Giant Background Watermark Year (Figma 6328:120028) ─── */
.sidebar-watermark-year {
  position: absolute;
  top: 34.36px;
  left: -38px;
  font-size: 165px;
  font-weight: 700;
  line-height: 110px;
  color: rgba(131, 191, 246, 0.1);
  pointer-events: none;
  user-select: none;
  z-index: 2;
  font-family: var(--font-family-primary, 'Inter', sans-serif);
}

/* ─── Header Section (Figma 6328:120024: 171px with hairline border) ─── */
.sidebar-header-section {
  height: 171px;
  min-height: 171px;
  max-height: 171px;
  border-bottom: 0.74px solid #83bff6;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
  z-index: 3;
  padding: 43px 8.8px 28px 17.7px;
  box-sizing: border-box;
}

.sidebar-year-headline {
  font-size: 60px;
  font-weight: 700;
  color: #ffffff;
  line-height: 40px;
  margin: 0;
  letter-spacing: 0;
}

.sidebar-cal-type {
  font-size: 12px;
  color: #bddbfa;
  margin: 10px 0 0 0;
  font-weight: 400;
  line-height: 18px;
}

/* ─── Body Section (Figma 6328:120029) ─── */
.sidebar-body-section {
  padding: 11px 8.84px 12px 8.84px;
  display: flex;
  flex-direction: column;
  height: calc(639px - 171px);
  box-sizing: border-box;
  position: relative;
  z-index: 3;
  flex: 1;
}

.sidebar-active-date {
  padding: 0 7px;
  font-size: 23.57px;
  font-weight: 400;
  color: #ffffff;
  line-height: 29.47px;
  margin-bottom: 4px;
  transition: opacity 0.2s ease;
}

.sidebar-active-date--dimmed {
  opacity: 0.34;
}

/* ─── Selection Row (Figma 6328:120032 / 6328:120201 / 6328:120278) ─── */
.sidebar-selection-row {
  padding: 2.95px 7px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
  min-height: 35.36px;
}

.sidebar-picker-toggle-pill {
  display: flex;
  align-items: center;
  gap: 5.9px;
  background: transparent;
  border: none;
  color: #e1eefd;
  cursor: pointer;
  padding: 6px 6px;
  border-radius: 73.66px;
  transition: background-color 0.15s ease, color 0.15s ease;
}

.sidebar-picker-toggle-pill:hover {
  background-color: rgba(17, 30, 52, 0.15);
  color: #ffffff;
}

.sidebar-picker-toggle-pill--days .pill-label-text {
  font-size: 10.31px;
  font-weight: 500;
  line-height: 14.73px;
  letter-spacing: 0.07px;
}

.sidebar-picker-toggle-pill--months .pill-label-text,
.sidebar-picker-toggle-pill--years .pill-label-text {
  font-size: 16px;
  font-weight: 400;
  line-height: 24px;
  color: #ffffff;
}

.pill-chevron-icon {
  color: currentColor;
  flex-shrink: 0;
}

.sidebar-nav-controls {
  display: flex;
  align-items: center;
  gap: 0;
}

.sidebar-nav-arrow-btn {
  width: 35.36px;
  height: 35.36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  cursor: pointer;
  background: transparent;
  border: none;
  transition: background-color 0.15s ease;
}

.sidebar-nav-arrow-btn:hover {
  background-color: rgba(255, 255, 255, 0.15);
}

/* ═══════════════════════════════════════════════
   VIEW 1: DAYS MATRIX (Figma 6328:120038)
═══════════════════════════════════════════════ */
.sidebar-grid-container {
  display: flex;
  flex-direction: column;
  width: 100%;
}

.sidebar-weekdays-row {
  display: flex;
  width: 100%;
  height: 35.36px;
  align-items: center;
  color: #ffffff;
}

.sidebar-weekday-col {
  flex: 1 0 0;
  min-width: 1px;
  text-align: center;
  font-size: 11.79px;
  line-height: 17.68px;
  font-weight: 400;
}

.sidebar-weeks-list {
  display: flex;
  flex-direction: column;
}

.sidebar-week-row {
  display: flex;
  width: 100%;
  height: 35.36px;
  align-items: center;
  border-radius: 9999px;
  transition: background-color 0.15s ease;
}

/* Week Active Pill Band in Week Mode (Figma 6328:120143 & 6328:120388) */
.sidebar-week-row--active-band {
  background-color: #e1eefd;
}

.sidebar-day-cell {
  flex: 1 0 0;
  min-width: 1px;
  height: 35.12px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.sidebar-day-circle {
  width: 29.47px;
  height: 29.47px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  font-size: 12px;
  line-height: 18px;
  box-sizing: border-box;
  transition: all 0.15s ease;
}

.sidebar-day-cell:hover .sidebar-day-circle:not(.sidebar-day-circle--selected):not(.sidebar-day-circle--today-selected) {
  background-color: rgba(35, 48, 88, 0.29);
}

.sidebar-day-circle--muted {
  color: rgba(255, 255, 255, 0.3) !important;
}

/* In active week capsule band (Figma 6328:120147) */
.sidebar-day-circle--in-band {
  color: #0B529C !important;
  font-weight: 500;
}

/* Active Selected Day (Figma 6328:120376 - Property 1=Selecte) */
.sidebar-day-circle--selected {
  background-color: #fba81c !important;
  color: #ffffff !important;
  font-weight: 600;
}

/* Today Selected Day (Figma 6328:120372 - Property 1=Today Selected) */
.sidebar-day-circle--today-selected {
  background-color: #fba81c !important;
  border: 2px solid #ffd230 !important;
  color: #ffffff !important;
  font-weight: 600;
}

/* Today Unselected Outline Day (Figma 6328:120380 - Property 1=Today) */
.sidebar-day-circle--today-outline {
  border: 2px solid #ffd230 !important;
  background-color: transparent !important;
  font-weight: 600;
}

.sidebar-day-circle--in-band.sidebar-day-circle--today-outline {
  color: #0B529C !important;
}

/* ═══════════════════════════════════════════════
   VIEW 2 & 3: MONTH & YEAR SELECT GRIDS (Figma 6328:120207 & 6328:120286)
═══════════════════════════════════════════════ */
.sidebar-months-grid,
.sidebar-years-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-template-rows: repeat(3, 1fr);
  height: 212.15px;
  width: 100%;
  box-sizing: border-box;
  padding: 0 4px;
  align-items: center;
}

.sidebar-month-btn,
.sidebar-year-btn {
  background: transparent;
  border: none;
  color: #ffffff;
  font-size: 16px;
  line-height: 24px;
  font-weight: 400;
  display: flex;
  align-items: center;
  justify-content: center;
  height: 48px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s ease;
  user-select: none;
}

.sidebar-month-btn:hover:not(.sidebar-month-btn--selected),
.sidebar-year-btn:hover:not(.sidebar-year-btn--selected) {
  background-color: rgba(35, 48, 88, 0.29);
}

.sidebar-month-btn--selected,
.sidebar-year-btn--selected {
  background-color: #fba81c !important;
  border: 2px solid #ffd230 !important;
  color: #ffffff !important;
  font-weight: 600;
}

/* ─── Today's Events in Sidebar (Figma 6328:120102 / 5749:42930) ─── */
.sidebar-todays-events {
  margin-top: auto;
  padding: 6px 15px 4px 15px;
}

.todays-event-badge {
  display: inline-block;
  background-color: #e1eefd;
  color: #0B529C;
  border-radius: 9999px;
  padding: 2px 8px;
  font-size: 12px;
  font-weight: 400;
  line-height: 18px;
  margin-bottom: 8px;
}

.todays-event-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.todays-event-row {
  display: flex;
  align-items: flex-start;
  gap: 4px;
  cursor: pointer;
  padding: 2px 4px;
  border-radius: 6px;
  transition: background-color 0.15s ease;
}

.todays-event-row:hover {
  background-color: rgba(255, 255, 255, 0.08);
}

.event-chevron {
  color: rgba(255, 255, 255, 0.5);
  flex-shrink: 0;
  margin-top: 3px;
}

.event-texts {
  display: flex;
  flex-direction: column;
}

.event-name {
  font-size: 14px;
  color: #ffffff;
  line-height: 20px;
  font-weight: 400;
}

.event-time {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.5);
  line-height: 18px;
}
</style>
