<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  CalendarDays, Clock, MapPin, User, CheckCircle2, AlertCircle,
  ArrowRight, ArrowLeftRight, ChevronLeft, ChevronRight, Calendar,
  Coffee, ShieldCheck, Check, Sparkles, Building2
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';

const router = useRouter();

// ─── Breadcrumb (Rule 3: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'My Shifts' }
];

// Current Logged-in Employee Context
const currentUser = {
  id: 14,
  name: 'Abebe Kebede',
  code: 'EMP-014',
  role: 'Head of Retail',
  entity_id: 7,
  entity_name: 'Bole Commercial Branch',
  org_unit: 'Retail Operations',
  pattern_code: 'PAT-RETAIL-6D',
  pattern_name: 'Retail 6-Day Rota (6 Work, 1 Off)'
};

// ─── Week Calculations ───
function addDays(d: Date, n: number): Date {
  const r = new Date(d);
  r.setDate(r.getDate() + n);
  return r;
}

function toIso(d: Date): string {
  return d.toISOString().slice(0, 10);
}

// Current reference date: July 29, 2026 (Wednesday)
const todayIso = '2026-07-29';
const currentWeekStart = ref(new Date('2026-07-27T00:00:00'));

const weekDays = computed(() => {
  return Array.from({ length: 7 }, (_, i) => {
    const d = addDays(currentWeekStart.value, i);
    const iso = toIso(d);
    return {
      date: d,
      iso,
      dayName: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][i],
      dayShort: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
      dayNum: d.getDate(),
      monthShort: d.toLocaleDateString('en-US', { month: 'short' }),
      isToday: iso === todayIso,
      isWeekend: i >= 5
    };
  });
});

const weekLabel = computed(() => {
  const start = weekDays.value[0];
  const end = weekDays.value[6];
  return `${start.monthShort} ${start.dayNum} – ${end.monthShort} ${end.dayNum}, ${end.date.getFullYear()}`;
});

const handlePrevWeek = () => {
  currentWeekStart.value = addDays(currentWeekStart.value, -7);
};

const handleNextWeek = () => {
  currentWeekStart.value = addDays(currentWeekStart.value, 7);
};

const handleThisWeek = () => {
  currentWeekStart.value = new Date('2026-07-27T00:00:00');
};

// ─── Abebe's Shift Schedule Records ───
export interface PersonalShift {
  id: number;
  date: string;
  shift_name: string;
  shift_code: string;
  start_time: string;
  end_time: string;
  hours: number;
  break_minutes: number;
  color_class: string;
  is_rest: boolean;
  status: 'on_duty' | 'completed' | 'upcoming';
  punch_in?: string;
  punch_out?: string;
  supervisor: string;
  location: string;
  notes?: string;
}

const myShifts = ref<PersonalShift[]>([
  {
    id: 40011,
    date: '2026-07-27',
    shift_name: 'Retail Morning',
    shift_code: 'MORN',
    start_time: '07:00',
    end_time: '15:00',
    hours: 7.5,
    break_minutes: 30,
    color_class: 'tag-amber',
    is_rest: false,
    status: 'completed',
    punch_in: '06:58 AM',
    punch_out: '03:04 PM',
    supervisor: 'Sara Tefera',
    location: 'Bole Commercial Branch • Floor A'
  },
  {
    id: 40012,
    date: '2026-07-28',
    shift_name: 'Retail Morning',
    shift_code: 'MORN',
    start_time: '07:00',
    end_time: '15:00',
    hours: 7.5,
    break_minutes: 30,
    color_class: 'tag-amber',
    is_rest: false,
    status: 'completed',
    punch_in: '07:02 AM',
    punch_out: '03:00 PM',
    supervisor: 'Sara Tefera',
    location: 'Bole Commercial Branch • Floor A'
  },
  {
    id: 40013,
    date: '2026-07-29', // TODAY
    shift_name: 'Retail Evening',
    shift_code: 'EVE',
    start_time: '14:30',
    end_time: '22:30',
    hours: 7.5,
    break_minutes: 30,
    color_class: 'tag-purple',
    is_rest: false,
    status: 'on_duty',
    punch_in: '02:26 PM (On Time)',
    supervisor: 'Sara Tefera',
    location: 'Bole Commercial Branch • Main Counters',
    notes: 'Covering evening rota after mutual swap'
  },
  {
    id: 40014,
    date: '2026-07-30',
    shift_name: 'Retail Evening',
    shift_code: 'EVE',
    start_time: '14:30',
    end_time: '22:30',
    hours: 7.5,
    break_minutes: 30,
    color_class: 'tag-purple',
    is_rest: false,
    status: 'upcoming',
    supervisor: 'Sara Tefera',
    location: 'Bole Commercial Branch • Main Counters'
  },
  {
    id: 40015,
    date: '2026-07-31',
    shift_name: 'Rest Day (Off)',
    shift_code: 'OFF',
    start_time: '—',
    end_time: '—',
    hours: 0,
    break_minutes: 0,
    color_class: 'tag-slate',
    is_rest: true,
    status: 'upcoming',
    supervisor: '—',
    location: '—'
  },
  {
    id: 40016,
    date: '2026-08-01',
    shift_name: 'Retail Morning',
    shift_code: 'MORN',
    start_time: '07:00',
    end_time: '15:00',
    hours: 7.5,
    break_minutes: 30,
    color_class: 'tag-amber',
    is_rest: false,
    status: 'upcoming',
    supervisor: 'Sara Tefera',
    location: 'Bole Commercial Branch • Floor A'
  },
  {
    id: 40017,
    date: '2026-08-02',
    shift_name: 'Rest Day (Off)',
    shift_code: 'OFF',
    start_time: '—',
    end_time: '—',
    hours: 0,
    break_minutes: 0,
    color_class: 'tag-slate',
    is_rest: true,
    status: 'upcoming',
    supervisor: '—',
    location: '—'
  }
]);

// Today's Hero Shift
const todayShift = computed(() => {
  return myShifts.value.find(s => s.date === todayIso);
});

// Personal Summary Stats for Selected Week
const weekStats = computed(() => {
  const dates = weekDays.value.map(d => d.iso);
  const shiftsInWeek = myShifts.value.filter(s => dates.includes(s.date) && !s.is_rest);
  const totalHours = shiftsInWeek.reduce((acc, s) => acc + s.hours, 0);
  const restDays = 7 - shiftsInWeek.length;
  const completedCount = myShifts.value.filter(s => dates.includes(s.date) && s.status === 'completed').length;

  return {
    rosteredDays: shiftsInWeek.length,
    totalHours: totalHours.toFixed(1),
    restDays,
    completedCount
  };
});

// Navigate to Shift Swaps
const navigateToSwaps = () => {
  router.push('/hr/shift-swaps');
};
</script>

<template>
  <div class="my-shifts-page">
    <!-- Breadcrumb Standard (Rule 3) -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ─── TODAY'S SHIFT HERO CARD ─── -->
    <div v-if="todayShift && !todayShift.is_rest" class="hero-shift-card">
      <div class="hero-left">
        <div class="hero-badge-row">
          <span class="status-live-pill">
            <span class="pulse-dot"></span>
            <span>Current Assignment &bull; Today</span>
          </span>
          <span class="shift-category-tag" :class="todayShift.color_class">
            {{ todayShift.shift_name }} ({{ todayShift.hours }}h)
          </span>
        </div>

        <h2 class="hero-time-heading">
          {{ todayShift.start_time }} – {{ todayShift.end_time }}
        </h2>

        <div class="hero-meta-row">
          <div class="meta-item">
            <MapPin :size="14" class="meta-icon" />
            <span>{{ todayShift.location }}</span>
          </div>
          <div class="meta-item">
            <User :size="14" class="meta-icon" />
            <span>Supervisor: {{ todayShift.supervisor }}</span>
          </div>
          <div class="meta-item">
            <Coffee :size="14" class="meta-icon" />
            <span>{{ todayShift.break_minutes }} min break</span>
          </div>
        </div>

        <div v-if="todayShift.notes" class="hero-note-strip">
          <Sparkles :size="13" />
          <span>{{ todayShift.notes }}</span>
        </div>
      </div>

      <div class="hero-right">
        <div class="clock-status-box">
          <span class="cs-label">Punch Status</span>
          <span class="cs-time">{{ todayShift.punch_in }}</span>
          <span class="cs-state">On-Duty &bull; Verified</span>
        </div>

        <button type="button" class="btn-swap-hero" @click="navigateToSwaps">
          <ArrowLeftRight :size="14" />
          <span>Need a Cover? Swap Shift</span>
        </button>
      </div>
    </div>

    <!-- If Today is Rest Day -->
    <div v-else-if="todayShift && todayShift.is_rest" class="hero-rest-card">
      <div class="rest-icon-box">
        <Coffee :size="24" />
      </div>
      <div>
        <h2 class="rest-title">Scheduled Rest Day (Off)</h2>
        <p class="rest-sub">You have no shifts scheduled for today. Enjoy your day off!</p>
      </div>
      <button type="button" class="btn-swap-hero ml-auto" @click="navigateToSwaps">
        <ArrowLeftRight :size="14" />
        <span>View Shift Swaps</span>
      </button>
    </div>

    <!-- ─── PERSONAL METRICS STRIP ─── -->
    <div class="personal-metrics-bar">
      <div class="pm-block">
        <span class="pm-label">Rostered Working Days</span>
        <span class="pm-value">{{ weekStats.rosteredDays }} Days</span>
        <span class="pm-sub">{{ currentUser.pattern_code }} Schedule</span>
      </div>
      <div class="pm-divider"></div>

      <div class="pm-block">
        <span class="pm-label">Total Planned Hours</span>
        <span class="pm-value">{{ weekStats.totalHours }} hrs</span>
        <span class="pm-sub">Standard 48.0h Statutory Limit</span>
      </div>
      <div class="pm-divider"></div>

      <div class="pm-block">
        <span class="pm-label">Scheduled Rest Days</span>
        <span class="pm-value">{{ weekStats.restDays }} Days</span>
        <span class="pm-sub">Rest &amp; Recuperation</span>
      </div>
      <div class="pm-divider"></div>

      <div class="pm-block">
        <span class="pm-label">Completed Shifts</span>
        <span class="pm-value">{{ weekStats.completedCount }} / {{ weekStats.rosteredDays }}</span>
        <span class="pm-sub">Timesheet Verified</span>
      </div>
    </div>

    <!-- ─── WEEKLY TIMETABLE SCHEDULE CARD ─── -->
    <div class="clean-card">
      <div class="card-header-bar">
        <div>
          <div class="card-title">My Weekly Shift Timetable</div>
          <p class="card-subtitle">
            Your assigned working windows for {{ weekLabel }}. Shifts are generated from {{ currentUser.pattern_name }}.
          </p>
        </div>

        <!-- Week Navigator -->
        <div class="week-nav-group">
          <button type="button" class="btn-nav" @click="handlePrevWeek">
            <ChevronLeft :size="16" />
          </button>
          <span class="week-range-text">{{ weekLabel }}</span>
          <button type="button" class="btn-this-week" @click="handleThisWeek">This Week</button>
          <button type="button" class="btn-nav" @click="handleNextWeek">
            <ChevronRight :size="16" />
          </button>
        </div>
      </div>

      <!-- Schedule Cards Grid (7 Days) -->
      <div class="days-schedule-grid">
        <div
          v-for="day in weekDays"
          :key="day.iso"
          class="day-slot-card"
          :class="{
            'day-slot-today': day.isToday,
            'day-slot-weekend': day.isWeekend
          }"
        >
          <!-- Day Header -->
          <div class="day-slot-header">
            <div class="day-slot-titles">
              <span class="day-name-bold">{{ day.dayShort }}</span>
              <span class="day-date-sub">{{ day.monthShort }} {{ day.dayNum }}</span>
            </div>
            <span v-if="day.isToday" class="today-chip">Today</span>
          </div>

          <!-- Shift Content -->
          <div class="day-slot-body">
            <template v-if="myShifts.find(s => s.date === day.iso)">
              <div
                v-if="!myShifts.find(s => s.date === day.iso)!.is_rest"
                class="shift-pill-content"
                :class="myShifts.find(s => s.date === day.iso)!.color_class"
              >
                <div class="sp-top">
                  <span class="sp-name">{{ myShifts.find(s => s.date === day.iso)!.shift_name }}</span>
                  <span class="sp-hours">{{ myShifts.find(s => s.date === day.iso)!.hours }}h</span>
                </div>
                <div class="sp-times">
                  <Clock :size="12" />
                  <span>{{ myShifts.find(s => s.date === day.iso)!.start_time }} – {{ myShifts.find(s => s.date === day.iso)!.end_time }}</span>
                </div>
                <div class="sp-status">
                  <span v-if="myShifts.find(s => s.date === day.iso)!.status === 'completed'" class="status-done">
                    <CheckCircle2 :size="11" />
                    <span>Completed</span>
                  </span>
                  <span v-else-if="myShifts.find(s => s.date === day.iso)!.status === 'on_duty'" class="status-live">
                    <span class="pulse-dot-sm"></span>
                    <span>On Duty</span>
                  </span>
                  <span v-else class="status-upcoming">
                    Scheduled
                  </span>
                </div>
              </div>

              <!-- Rest Day Slot -->
              <div v-else class="rest-pill-content">
                <Coffee :size="16" class="rest-icon" />
                <span class="rest-label">Rest Day (Off)</span>
                <span class="rest-sub-text">0.0 planned hours</span>
              </div>
            </template>
            <template v-else>
              <div class="unassigned-slot">
                <span>No shift assigned</span>
              </div>
            </template>
          </div>

          <!-- Footer Action: Swap Request Button -->
          <div
            v-if="myShifts.find(s => s.date === day.iso) && !myShifts.find(s => s.date === day.iso)!.is_rest && myShifts.find(s => s.date === day.iso)!.status === 'upcoming'"
            class="day-slot-footer"
          >
            <button
              type="button"
              class="btn-slot-swap"
              @click="navigateToSwaps"
              title="Request a swap or trade for this shift"
            >
              <ArrowLeftRight :size="11" />
              <span>Request Swap</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.my-shifts-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 20px 24px 80px 24px;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

/* ─── Hero Shift Card ─── */
.hero-shift-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 24px 28px;
  background: linear-gradient(135deg, #0B529C 0%, #083b70 100%);
  color: #ffffff;
  border-radius: 12px;
  box-shadow: 0 4px 16px rgba(11, 82, 156, 0.15);
  gap: 24px;
  flex-wrap: wrap;
}

.hero-left {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex: 1;
}

.hero-badge-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.status-live-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 3px 10px;
  border-radius: 9999px;
  background-color: rgba(255, 255, 255, 0.15);
  font-size: 11.5px;
  font-weight: 500;
  color: #ffffff;
}

.pulse-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background-color: #22c55e;
  box-shadow: 0 0 8px #22c55e;
}

.shift-category-tag {
  font-size: 11.5px;
  font-weight: 600;
  padding: 3px 10px;
  border-radius: 9999px;
}

.shift-category-tag.tag-amber {
  background-color: #fef3c7;
  color: #92400e;
}

.shift-category-tag.tag-purple {
  background-color: #f3e8ff;
  color: #6b21a8;
}

.hero-time-heading {
  font-size: 28px;
  font-weight: 700;
  color: #ffffff;
  margin: 0;
  letter-spacing: -0.5px;
}

.hero-meta-row {
  display: flex;
  align-items: center;
  gap: 18px;
  font-size: 13px;
  color: rgba(255, 255, 255, 0.85);
  flex-wrap: wrap;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 6px;
}

.meta-icon {
  opacity: 0.8;
}

.hero-note-strip {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #93c5fd;
  margin-top: 4px;
}

.hero-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 12px;
}

.clock-status-box {
  background-color: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(8px);
  padding: 10px 16px;
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  border: 1px solid rgba(255, 255, 255, 0.15);
}

.cs-label {
  font-size: 11px;
  color: rgba(255, 255, 255, 0.7);
}

.cs-time {
  font-size: 14px;
  font-weight: 600;
  color: #ffffff;
}

.cs-state {
  font-size: 10.5px;
  color: #4ade80;
  font-weight: 500;
}

.btn-swap-hero {
  height: 36px;
  padding: 0 16px;
  display: flex;
  align-items: center;
  gap: 7px;
  background-color: #ffffff;
  color: #0B529C;
  border: none;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.15s, background-color 0.15s;
}

.btn-swap-hero:hover {
  background-color: #f8fafc;
  transform: translateY(-1px);
}

/* Hero Rest Day */
.hero-rest-card {
  display: flex;
  align-items: center;
  gap: 18px;
  padding: 20px 24px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
}

.rest-icon-box {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background-color: #f1f5f9;
  color: #64748b;
  display: flex;
  align-items: center;
  justify-content: center;
}

.rest-title {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.rest-sub {
  font-size: 13px;
  color: #737373;
  margin: 2px 0 0 0;
}

/* ─── Personal Metrics Bar ─── */
.personal-metrics-bar {
  display: flex;
  align-items: center;
  background-color: #ffffff;
  border: 1px solid #f1f5f9;
  border-radius: 10px;
  padding: 14px 24px;
}

.pm-block {
  display: flex;
  flex-direction: column;
  gap: 1px;
  flex: 1;
}

.pm-label {
  font-size: 12px;
  color: #737373;
  font-weight: 500;
}

.pm-value {
  font-size: 22px;
  font-weight: 600;
  color: #404040;
}

.pm-sub {
  font-size: 11.5px;
  color: #737373;
}

.pm-divider {
  width: 1px;
  height: 42px;
  background-color: #f1f5f9;
  margin: 0 16px;
}

/* ─── Timetable Clean Card ─── */
.clean-card {
  background-color: #ffffff;
  border: 1px solid #f1f5f9;
  border-radius: 10px;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-header-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}

.card-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
}

.card-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 2px 0 0 0;
}

.week-nav-group {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #f8fafc;
  padding: 4px 8px;
  border-radius: 8px;
  border: 1px solid #f1f5f9;
}

.btn-nav {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  color: #64748b;
  cursor: pointer;
}

.btn-nav:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.week-range-text {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
}

.btn-this-week {
  padding: 2px 8px;
  background: transparent;
  border: 1px solid #cbd5e1;
  border-radius: 4px;
  font-size: 11px;
  color: #475569;
  cursor: pointer;
}

.btn-this-week:hover {
  background-color: #ffffff;
}

/* ─── 7-Days Schedule Grid ─── */
.days-schedule-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 10px;
}

@media (max-width: 1024px) {
  .days-schedule-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 640px) {
  .days-schedule-grid {
    grid-template-columns: 1fr;
  }
}

.day-slot-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.day-slot-card:hover {
  border-color: #cbd5e1;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
}

.day-slot-today {
  border: 2px solid #0B529C;
  background-color: #fbfdff;
}

.day-slot-weekend {
  background-color: #fafafa;
}

.day-slot-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  background-color: #f8fafc;
  border-bottom: 1px solid #f1f5f9;
}

.day-slot-titles {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.day-name-bold {
  font-size: 13px;
  font-weight: 700;
  color: #404040;
}

.day-date-sub {
  font-size: 11px;
  color: #737373;
}

.today-chip {
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  background-color: #0B529C;
  color: #ffffff;
  padding: 2px 6px;
  border-radius: 4px;
}

.day-slot-body {
  padding: 12px 10px;
  flex: 1;
  display: flex;
  flex-direction: column;
}

/* Shift Pill Content */
.shift-pill-content {
  border-radius: 8px;
  padding: 8px 10px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.shift-pill-content.tag-amber {
  background-color: #fef3c7;
  color: #92400e;
}

.shift-pill-content.tag-purple {
  background-color: #f3e8ff;
  color: #6b21a8;
}

.sp-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.sp-name {
  font-size: 12px;
  font-weight: 700;
}

.sp-hours {
  font-size: 11px;
  font-weight: 600;
  opacity: 0.85;
}

.sp-times {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
}

.sp-status {
  margin-top: 4px;
  font-size: 10.5px;
  font-weight: 600;
}

.status-done {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  color: #059669;
}

.status-live {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  color: #2563eb;
}

.status-upcoming {
  color: #64748b;
  opacity: 0.8;
}

.pulse-dot-sm {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background-color: #2563eb;
}

/* Rest Pill */
.rest-pill-content {
  padding: 16px 8px;
  border-radius: 8px;
  background-color: #f1f5f9;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  text-align: center;
  color: #64748b;
}

.rest-icon {
  opacity: 0.6;
}

.rest-label {
  font-size: 12px;
  font-weight: 600;
}

.rest-sub-text {
  font-size: 10.5px;
  color: #94a3b8;
}

.unassigned-slot {
  padding: 16px 8px;
  text-align: center;
  font-size: 11.5px;
  color: #cbd5e1;
}

.day-slot-footer {
  padding: 6px 8px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  justify-content: center;
}

.btn-slot-swap {
  width: 100%;
  height: 26px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  background: transparent;
  border: 1px dashed #cbd5e1;
  border-radius: 6px;
  font-size: 11px;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-slot-swap:hover {
  background-color: #eff6ff;
  border-color: #93c5fd;
  color: #1d4ed8;
}
</style>
