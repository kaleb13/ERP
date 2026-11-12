<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  X, Calendar, Clock, CalendarRange,
  Sliders, Plus, ChevronDown, CheckCircle2,
  AlertCircle, AlertTriangle, RotateCcw, Expand,
  ArrowDown, ArrowUp, Copy
} from 'lucide-vue-next';;
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import IconColumnSolid from '../../components/IconColumnSolid.vue';

const router = useRouter();
const route = useRoute();

const isEditMode = computed(() => !!route.params.id);
const isSaved = ref(false);

// ─── Top Tabs ───
type TabKey = 'settings' | 'weekly' | 'overrides' | 'matrix';
const activeTab = ref<TabKey>('settings');

const tabs: BaseTabItem<TabKey>[] = [
  { id: 'settings',  label: 'Calendar Settings',  icon: Sliders },
  { id: 'weekly',    label: 'Weekly Schedule',     icon: Clock },
  { id: 'overrides', label: 'Holiday Overrides',   icon: Calendar },
  { id: 'matrix',    label: 'Year Matrix',         icon: CalendarRange },
];

// ─── Toast ───
const toast = ref<{ msg: string; type: 'success' | 'error' } | null>(null);
const showToast = (msg: string, type: 'success' | 'error' = 'success') => {
  toast.value = { msg, type };
  setTimeout(() => { toast.value = null; }, 3500);
};

// ──────────────────────────────────────────────
// TAB 1: CALENDAR SETTINGS — WorkCalendar [REF]
// ──────────────────────────────────────────────
const form = ref({
  name: '',
  entity_id: '',
  fiscal_year_start_month: '7',
  fiscal_year_start_day: '8',
  week_start_day: '1',
  default_daily_hours: '8.00',
  default_weekly_hours: '40.00',
  payroll_days_per_month: '26.0',
  is_default: false,
});

const entityOptions = [
  { label: 'Haleta Addis Ababa HQ', value: '3' },
  { label: 'QMT Bole Branch',       value: '7' },
  { label: 'Bahir Dar Hub',         value: '9' },
  { label: 'Hawassa Industrial Unit', value: '12' },
  { label: 'Platform Template (System)', value: '0' },
];

const monthOptions = [
  { label: 'January (1)',   value: '1'  },
  { label: 'February (2)',  value: '2'  },
  { label: 'March (3)',     value: '3'  },
  { label: 'April (4)',     value: '4'  },
  { label: 'May (5)',       value: '5'  },
  { label: 'June (6)',      value: '6'  },
  { label: 'July (7)',      value: '7'  },
  { label: 'August (8)',    value: '8'  },
  { label: 'September (9)', value: '9'  },
  { label: 'October (10)',  value: '10' },
  { label: 'November (11)', value: '11' },
  { label: 'December (12)', value: '12' },
];

const weekStartOptions = [
  { label: 'Monday (ISO 1)',   value: '1' },
  { label: 'Sunday (ISO 7)',   value: '7' },
  { label: 'Saturday (ISO 6)', value: '6' },
];

// Auto-sync weekly hours when daily hours change
watch(() => form.value.default_daily_hours, (val) => {
  const daily = parseFloat(val);
  const workDays = weekdayRows.value.filter(r => r.day_type === 'working').length;
  const halfDays = weekdayRows.value.filter(r => r.day_type === 'half_day').length;
  if (!isNaN(daily) && workDays > 0) {
    form.value.default_weekly_hours = (daily * workDays + (daily / 2) * halfDays).toFixed(2);
  }
});

// ──────────────────────────────────────────────
// TAB 2: WEEKLY SCHEDULE — WorkCalendarWeekday [LINE]
// ──────────────────────────────────────────────
type DayType = 'working' | 'half_day' | 'weekend';

interface WeekdayRow {
  weekday: number;
  name: string;
  short: string;
  day_type: DayType;
  planned_hours: number;
}

const weekdayRows = ref<WeekdayRow[]>([
  { weekday: 1, name: 'Monday',    short: 'Mon', day_type: 'working', planned_hours: 8.0 },
  { weekday: 2, name: 'Tuesday',   short: 'Tue', day_type: 'working', planned_hours: 8.0 },
  { weekday: 3, name: 'Wednesday', short: 'Wed', day_type: 'working', planned_hours: 8.0 },
  { weekday: 4, name: 'Thursday',  short: 'Thu', day_type: 'working', planned_hours: 8.0 },
  { weekday: 5, name: 'Friday',    short: 'Fri', day_type: 'working', planned_hours: 8.0 },
  { weekday: 6, name: 'Saturday',  short: 'Sat', day_type: 'weekend', planned_hours: 0.0 },
  { weekday: 7, name: 'Sunday',    short: 'Sun', day_type: 'weekend', planned_hours: 0.0 },
]);

const dayTypeOptions = [
  { label: 'Working Day', value: 'working' },
  { label: 'Half Day',    value: 'half_day' },
  { label: 'Weekend / Rest', value: 'weekend' },
];

// When day_type changes, auto-set planned_hours
const onDayTypeChange = (row: WeekdayRow) => {
  if (row.day_type === 'working')  { row.planned_hours = parseFloat(form.value.default_daily_hours) || 8; }
  if (row.day_type === 'half_day') { row.planned_hours = (parseFloat(form.value.default_daily_hours) || 8) / 2; }
  if (row.day_type === 'weekend')  { row.planned_hours = 0; }
  recalcWeeklyHours();
};

const recalcWeeklyHours = () => {
  const total = weekdayRows.value.reduce((sum, r) => sum + r.planned_hours, 0);
  form.value.default_weekly_hours = total.toFixed(2);
};

const weeklyTotals = computed(() => {
  const workDays   = weekdayRows.value.filter(r => r.day_type === 'working').length;
  const halfDays   = weekdayRows.value.filter(r => r.day_type === 'half_day').length;
  const restDays   = weekdayRows.value.filter(r => r.day_type === 'weekend').length;
  const totalHours = weekdayRows.value.reduce((s, r) => s + r.planned_hours, 0);
  return { workDays, halfDays, restDays, totalHours };
});

// Quick presets
const applyPreset = (preset: '5day' | '6day' | '5half') => {
  weekdayRows.value.forEach(r => {
    if (preset === '5day') {
      r.day_type = r.weekday <= 5 ? 'working' : 'weekend';
      r.planned_hours = r.weekday <= 5 ? 8 : 0;
    } else if (preset === '6day') {
      r.day_type = r.weekday <= 6 ? 'working' : 'weekend';
      r.planned_hours = r.weekday <= 6 ? 8 : 0;
    } else if (preset === '5half') {
      if (r.weekday <= 5)      { r.day_type = 'working';  r.planned_hours = 8; }
      else if (r.weekday === 6){ r.day_type = 'half_day'; r.planned_hours = 4; }
      else                     { r.day_type = 'weekend';  r.planned_hours = 0; }
    }
  });
  recalcWeeklyHours();
};

// ──────────────────────────────────────────────
// TAB 3: HOLIDAY RECONCILIATION & OVERRIDES — WorkCalendarDay [LINE]
// ──────────────────────────────────────────────
type HolidayType = 'public' | 'religious' | 'company';
type CalDayType  = 'holiday' | 'half_day' | 'working' | 'weekend';

interface MasterHoliday {
  id: number;
  code: string;
  name: string;
  amharic_name: string;
  holiday_type: HolidayType;
  date: string; // YYYY-MM-DD
  ethiopian_date_text: string;
  is_recurring: boolean;
  is_paid: boolean;
  entity_id: number | null;
}

// Master holidays catalog for Fiscal Year 2026/27 (Hamle 2018 - Sene 2019 E.C.)
// Derived from HR_Schema_final-v4.sql lines 1246-1270
const masterHolidays: MasterHoliday[] = [
  {
    id: 1,
    code: 'ENKUTATASH',
    name: 'Ethiopian New Year (Enkutatash)',
    amharic_name: 'እንቁጣጣሽ (አዲስ ዓመት)',
    holiday_type: 'public',
    date: '2026-09-11',
    ethiopian_date_text: 'መስከረም 01, 2019 E.C.',
    is_recurring: true,
    is_paid: true,
    entity_id: null,
  },
  {
    id: 2,
    code: 'MESKEL',
    name: 'Finding of the True Cross (Meskel)',
    amharic_name: 'የመስቀል ደመራ በዓል',
    holiday_type: 'religious',
    date: '2026-09-27',
    ethiopian_date_text: 'መስከረም 17, 2019 E.C.',
    is_recurring: true,
    is_paid: true,
    entity_id: null,
  },
  {
    id: 3,
    code: 'HLT-DAY',
    name: 'Haleta Foundation Day',
    amharic_name: 'የሐሌታ መሥራች ቀን',
    holiday_type: 'company',
    date: '2026-11-05',
    ethiopian_date_text: 'ጥቅምት 26, 2019 E.C.',
    is_recurring: true,
    is_paid: true,
    entity_id: 1,
  },
  {
    id: 4,
    code: 'GENNA',
    name: 'Ethiopian Christmas (Genna)',
    amharic_name: 'የገና በዓል',
    holiday_type: 'religious',
    date: '2027-01-07',
    ethiopian_date_text: 'ታኅሣሥ 29, 2019 E.C.',
    is_recurring: true,
    is_paid: true,
    entity_id: null,
  },
  {
    id: 5,
    code: 'TIMKET',
    name: 'Epiphany (Timket)',
    amharic_name: 'የጥምቀት በዓል',
    holiday_type: 'religious',
    date: '2027-01-19',
    ethiopian_date_text: 'ጥር 11, 2019 E.C.',
    is_recurring: true,
    is_paid: true,
    entity_id: null,
  },
  {
    id: 6,
    code: 'ADWA',
    name: 'Adwa Victory Day',
    amharic_name: 'የዓድዋ ድል በዓል',
    holiday_type: 'public',
    date: '2027-03-02',
    ethiopian_date_text: 'የካቲት 23, 2019 E.C.',
    is_recurring: true,
    is_paid: true,
    entity_id: null,
  },
  {
    id: 7,
    code: 'EID-FITR',
    name: 'Eid al-Fitr',
    amharic_name: 'ኢድ አል-ፊጥር (ረመዳን)',
    holiday_type: 'religious',
    date: '2027-03-10',
    ethiopian_date_text: 'መጋቢት 01, 2019 E.C.',
    is_recurring: false,
    is_paid: true,
    entity_id: null,
  },
  {
    id: 8,
    code: 'FASIKA',
    name: 'Ethiopian Easter (Fasika)',
    amharic_name: 'የትንሣኤ በዓል (ፋሲካ)',
    holiday_type: 'religious',
    date: '2027-04-12',
    ethiopian_date_text: 'ሚያዝያ 04, 2019 E.C.',
    is_recurring: false,
    is_paid: true,
    entity_id: null,
  },
  {
    id: 9,
    code: 'PATRIOTS',
    name: "Patriots' Victory Day",
    amharic_name: 'የአርበኞች ቀን',
    holiday_type: 'public',
    date: '2027-05-05',
    ethiopian_date_text: 'ሚያዝያ 27, 2019 E.C.',
    is_recurring: true,
    is_paid: true,
    entity_id: null,
  },
  {
    id: 10,
    code: 'EID-ADHA',
    name: 'Eid al-Adha (Arafa)',
    amharic_name: 'ኢድ አል-አድሃ (አረፋ)',
    holiday_type: 'religious',
    date: '2027-05-17',
    ethiopian_date_text: 'ግንቦት 09, 2019 E.C.',
    is_recurring: false,
    is_paid: true,
    entity_id: null,
  },
  {
    id: 11,
    code: 'DERG-DOWN',
    name: 'Downfall of Derg Day',
    amharic_name: 'የደርግ ውድቀት ቀን',
    holiday_type: 'public',
    date: '2027-05-28',
    ethiopian_date_text: 'ግንቦት 20, 2019 E.C.',
    is_recurring: true,
    is_paid: true,
    entity_id: null,
  },
];

interface HolidayReconciliationRow {
  holiday_id: number;
  code: string;
  name: string;
  amharic_name: string;
  holiday_type: HolidayType;
  date: string;
  ethiopian_date_text: string;
  is_paid: boolean;
  is_active: boolean;
  day_type: CalDayType;
  planned_hours: number;
  rollover_to_next_day: boolean;
}

// Initialized from Master Holidays
const holidayRows = ref<HolidayReconciliationRow[]>(
  masterHolidays.map(h => ({
    holiday_id: h.id,
    code: h.code,
    name: h.name,
    amharic_name: h.amharic_name,
    holiday_type: h.holiday_type,
    date: h.date,
    ethiopian_date_text: h.ethiopian_date_text,
    is_paid: h.is_paid,
    is_active: true,
    day_type: 'holiday',
    planned_hours: 0,
    rollover_to_next_day: false,
  }))
);

// Dynamic Weekday Inspector against Tab 2's Weekly Rhythm
const getDayOfWeekDetails = (dateStr: string) => {
  const d = new Date(dateStr + 'T00:00:00');
  const jsDay = d.getDay(); // 0=Sun, 1=Mon, ..., 6=Sat
  const isoDay = jsDay === 0 ? 7 : jsDay;
  const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const dayName = dayNames[isoDay - 1];

  const wd = weekdayRows.value.find(r => r.weekday === isoDay);
  const baselineType: DayType = wd ? wd.day_type : (isoDay >= 6 ? 'weekend' : 'working');
  const baselineHours = wd ? wd.planned_hours : (baselineType === 'working' ? 8 : 0);
  const isWorkingConflict = baselineType === 'working' || baselineType === 'half_day';

  return { isoDay, dayName, baselineType, baselineHours, isWorkingConflict };
};

// Next available working day finder for weekend rollover
const getSubstituteDate = (dateStr: string) => {
  const d = new Date(dateStr + 'T00:00:00');
  for (let i = 1; i <= 4; i++) {
    d.setDate(d.getDate() + 1);
    const jsDay = d.getDay();
    const isoDay = jsDay === 0 ? 7 : jsDay;
    const wd = weekdayRows.value.find(r => r.weekday === isoDay);
    if (wd && wd.day_type === 'working') {
      const y = d.getFullYear();
      const m = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return {
        dateStr: `${y}-${m}-${day}`,
        dayName: dayNames[isoDay - 1]
      };
    }
  }
  return null;
};

const onHolidayDayTypeChange = (row: HolidayReconciliationRow) => {
  if (row.day_type === 'holiday') {
    row.planned_hours = 0;
  } else if (row.day_type === 'half_day') {
    row.planned_hours = (parseFloat(form.value.default_daily_hours) || 8) / 2;
  } else if (row.day_type === 'working') {
    row.planned_hours = parseFloat(form.value.default_daily_hours) || 8;
  } else if (row.day_type === 'weekend') {
    row.planned_hours = 0;
  }
};

// ─── Custom Day Overrides (non-statutory company closures or bridge days) ───
interface CustomDayOverride {
  id: number;
  date: string;
  name: string;
  day_type: CalDayType;
  planned_hours: number;
  reason: string;
}

const customOverrides = ref<CustomDayOverride[]>([]);
const selectedCustomIds = ref<number[]>([]);
const showRowModal = ref(false);
const activeRowData = ref<CustomDayOverride | null>(null);
const activeRowIndex = ref<number>(0);

const isAllCustomSelected = computed(() => {
  return customOverrides.value.length > 0 && selectedCustomIds.value.length === customOverrides.value.length;
});

const toggleSelectAllCustom = () => {
  if (isAllCustomSelected.value) {
    selectedCustomIds.value = [];
  } else {
    selectedCustomIds.value = customOverrides.value.map(c => c.id);
  }
};

const handleBatchDeleteCustom = () => {
  customOverrides.value = customOverrides.value.filter(c => !selectedCustomIds.value.includes(c.id));
  selectedCustomIds.value = [];
  showToast('Selected custom overrides deleted.');
};

const addCustomOverrideRow = () => {
  const newRow: CustomDayOverride = {
    id: Date.now(),
    date: new Date().toISOString().split('T')[0],
    name: '',
    day_type: 'holiday',
    planned_hours: 0,
    reason: '',
  };
  customOverrides.value.push(newRow);
};

const removeCustomOverride = (id: number) => {
  customOverrides.value = customOverrides.value.filter(c => c.id !== id);
  selectedCustomIds.value = selectedCustomIds.value.filter(itemId => itemId !== id);
  showToast('Custom override removed.');
};

const onCustomRowDayTypeChange = (row: CustomDayOverride) => {
  if (row.day_type === 'holiday' || row.day_type === 'weekend') {
    row.planned_hours = 0;
  } else if (row.day_type === 'half_day') {
    row.planned_hours = (parseFloat(form.value.default_daily_hours) || 8) / 2;
  } else if (row.day_type === 'working') {
    row.planned_hours = parseFloat(form.value.default_daily_hours) || 8;
  }
};

const openRowModal = (row: CustomDayOverride, idx: number) => {
  activeRowData.value = row;
  activeRowIndex.value = idx;
  showRowModal.value = true;
};

const closeRowModal = () => {
  showRowModal.value = false;
  activeRowData.value = null;
};

const isFirstRow = computed(() => activeRowIndex.value <= 0);
const isLastRow = computed(() => activeRowIndex.value >= customOverrides.value.length - 1);

const deleteModalRow = () => {
  if (activeRowData.value) {
    const id = activeRowData.value.id;
    customOverrides.value = customOverrides.value.filter(c => c.id !== id);
    selectedCustomIds.value = selectedCustomIds.value.filter(itemId => itemId !== id);
    closeRowModal();
    showToast('Custom day override deleted.');
  }
};

const moveRowDown = () => {
  const idx = activeRowIndex.value;
  if (idx < customOverrides.value.length - 1) {
    const list = [...customOverrides.value];
    const temp = list[idx];
    list[idx] = list[idx + 1];
    list[idx + 1] = temp;
    customOverrides.value = list;
    activeRowIndex.value = idx + 1;
    activeRowData.value = customOverrides.value[idx + 1];
  }
};

const moveRowUp = () => {
  const idx = activeRowIndex.value;
  if (idx > 0) {
    const list = [...customOverrides.value];
    const temp = list[idx];
    list[idx] = list[idx - 1];
    list[idx - 1] = temp;
    customOverrides.value = list;
    activeRowIndex.value = idx - 1;
    activeRowData.value = customOverrides.value[idx - 1];
  }
};

const duplicateModalRow = () => {
  if (activeRowData.value) {
    const clone: CustomDayOverride = {
      ...JSON.parse(JSON.stringify(activeRowData.value)),
      id: Date.now(),
      name: activeRowData.value.name ? `${activeRowData.value.name} (Copy)` : 'Copy'
    };
    customOverrides.value.splice(activeRowIndex.value + 1, 0, clone);
    activeRowIndex.value = activeRowIndex.value + 1;
    activeRowData.value = clone;
    showToast('Row duplicated.');
  }
};

const insertAboveModalRow = () => {
  const newRow: CustomDayOverride = {
    id: Date.now(),
    date: new Date().toISOString().split('T')[0],
    name: '',
    day_type: 'holiday',
    planned_hours: 0,
    reason: '',
  };
  customOverrides.value.splice(activeRowIndex.value, 0, newRow);
  activeRowData.value = newRow;
  showToast('Row inserted above.');
};

const insertBelowModalRow = () => {
  const newRow: CustomDayOverride = {
    id: Date.now(),
    date: new Date().toISOString().split('T')[0],
    name: '',
    day_type: 'holiday',
    planned_hours: 0,
    reason: '',
  };
  customOverrides.value.splice(activeRowIndex.value + 1, 0, newRow);
  activeRowIndex.value = activeRowIndex.value + 1;
  activeRowData.value = newRow;
  showToast('Row inserted below.');
};

// Metrics for Holiday Reconciliation Tab
const holidayStats = computed(() => {
  let workingConflicts = 0;
  let weekendAlignments = 0;
  let activeObservances = 0;
  let rolledOver = 0;

  holidayRows.value.forEach(h => {
    if (h.is_active) activeObservances++;
    const info = getDayOfWeekDetails(h.date);
    if (info.isWorkingConflict) workingConflicts++;
    else weekendAlignments++;
    if (h.rollover_to_next_day) rolledOver++;
  });

  return {
    total: holidayRows.value.length,
    workingConflicts,
    weekendAlignments,
    activeObservances,
    rolledOver,
    customCount: customOverrides.value.length,
  };
});

const calDayTypeOptions = [
  { label: 'Public Holiday (0h)',  value: 'holiday'  },
  { label: 'Half Day (reduced h)', value: 'half_day' },
  { label: 'Working Day',          value: 'working'  },
  { label: 'Weekend / Rest',       value: 'weekend'  },
];

const holidayTypeOptions = [
  { label: 'Public Statutory', value: 'public'    },
  { label: 'Religious',        value: 'religious' },
  { label: 'Company',          value: 'company'   },
];

const formatDate = (str: string) => {
  if (!str) return '—';
  const d = new Date(str + 'T00:00:00');
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
};

// ──────────────────────────────────────────────
// TAB 4: YEAR MATRIX (synchronized visual summary)
// ──────────────────────────────────────────────
const fyYear = 2026;
const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

const fyMonths = computed(() => {
  // Ethiopian FY starts July 2026 → June 2027 (12 months)
  const result = [];
  for (let i = 0; i < 12; i++) {
    const m = ((6 + i) % 12) + 1;       // 7,8,9,...,12,1,...,6
    const y = (6 + i) >= 12 ? fyYear + 1 : fyYear;
    const daysInMonth = new Date(y, m, 0).getDate();

    let workDays = 0, weekendDays = 0, holidayDays = 0;
    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = `${y}-${String(m).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
      const jsDay = new Date(y, m - 1, d).getDay(); // 0=Sun..6=Sat
      const isoDay = jsDay === 0 ? 7 : jsDay;
      const weekdayRow = weekdayRows.value.find(r => r.weekday === isoDay);

      // 1. Custom Overrides take highest priority
      const customMatch = customOverrides.value.find(c => c.date === dateStr);
      if (customMatch) {
        if (customMatch.day_type === 'holiday') holidayDays++;
        else if (customMatch.day_type === 'weekend') weekendDays++;
        else workDays++;
        continue;
      }

      // 2. Active Master Holiday Overrides
      const holidayMatch = holidayRows.value.find(r => r.is_active && r.date === dateStr);
      if (holidayMatch) {
        if (holidayMatch.day_type === 'holiday') holidayDays++;
        else if (holidayMatch.day_type === 'weekend') weekendDays++;
        else workDays++;
        continue;
      }

      // 3. Weekend rollover substitute date
      const rolloverMatch = holidayRows.value.find(r => {
        if (!r.is_active || !r.rollover_to_next_day) return false;
        const sub = getSubstituteDate(r.date);
        return sub && sub.dateStr === dateStr;
      });
      if (rolloverMatch) {
        holidayDays++;
        continue;
      }

      // 4. Default to weekly rhythm
      if (weekdayRow?.day_type === 'weekend') {
        weekendDays++;
      } else {
        workDays++;
      }
    }
    result.push({ m, y, monthName: monthNames[m - 1], daysInMonth, workDays, weekendDays, holidayDays });
  }
  return result;
});

const annualTotals = computed(() => fyMonths.value.reduce(
  (acc, mo) => ({
    work:    acc.work    + mo.workDays,
    weekend: acc.weekend + mo.weekendDays,
    holiday: acc.holiday + mo.holidayDays,
  }), { work: 0, weekend: 0, holiday: 0 }
));

// ──────────────────────────────────────────────
// SAVE & CLEAR
// ──────────────────────────────────────────────
const handleSave = () => {
  if (!form.value.name.trim()) {
    showToast('Calendar name is required.', 'error');
    activeTab.value = 'settings';
    return;
  }
  if (!form.value.entity_id) {
    showToast('Please select an entity.', 'error');
    activeTab.value = 'settings';
    return;
  }
  isSaved.value = true;
  showToast('Work calendar saved successfully.');
};

const handleClear = () => {
  form.value = {
    name: '', entity_id: '', fiscal_year_start_month: '7', fiscal_year_start_day: '8',
    week_start_day: '1', default_daily_hours: '8.00', default_weekly_hours: '40.00',
    payroll_days_per_month: '26.0', is_default: false,
  };
  isSaved.value = false;
  showToast('Form cleared.');
};

onMounted(() => {
  if (isEditMode.value) {
    // In real app, fetch calendar by id; here we pre-fill with sample data
    form.value.name = 'Office Calendar';
    form.value.entity_id = '3';
    isSaved.value = true;
  }
});
</script>

<template>
  <div class="wc-create-page">

    <!-- ─── Top Navigation Bar ─── -->
    <div class="top-nav-bar">
      <div class="nav-left">
        <AppBreadcrumb
          :items="[
            { label: 'Work Calendar Setup', to: '/hr/work-calendars' },
            { label: isEditMode ? 'Edit Work Calendar' : 'Create Work Calendar' }
          ]"
        >
          <template #badge>
            <SaveStateBadge :is-saved="isSaved" />
          </template>
        </AppBreadcrumb>
      </div>
      <div class="nav-actions">
        <AppButton 
          variant="outline" 
          size="sm" 
          @click="handleClear"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>
        <AppButton 
          variant="primary" 
          size="sm" 
          @click="handleSave"
        >
          Save
        </AppButton>
      </div>
    </div>

    <!-- ─── Toast ─── -->
    <Transition name="toast-fade">
      <div v-if="toast" class="toast-bar" :class="toast.type === 'error' ? 'toast-error' : 'toast-success'">
        <CheckCircle2 v-if="toast.type === 'success'" :size="15" />
        <AlertCircle  v-else :size="15" />
        <span>{{ toast.msg }}</span>
      </div>
    </Transition>

    <!-- ─── Top Tabs ─── -->
    <div class="tabs-row">
      <BaseTabs v-model="activeTab" :tabs="tabs" size="md" />
    </div>

    <!-- ══════════════════════════════════════════
         TAB 1 — CALENDAR SETTINGS
    ══════════════════════════════════════════ -->
    <div v-if="activeTab === 'settings'" class="tab-body">
      <div class="clean-card">
        <div class="card-section-title">Calendar Details</div>

        <!-- Identity & Scope -->
        <div class="form-section-riser">
          <span class="riser-label">Identity &amp; Scope</span>
          <div class="riser-line"></div>
        </div>
        <div class="form-grid-3">
          <div class="col-span-2">
            <FormInput
              label="Calendar Name"
              v-model="form.name"
              required
            />
          </div>
          <FormSelect
            label="Entity"
            v-model="form.entity_id"
            :options="entityOptions"
            required
          />
        </div>

        <!-- Fiscal Year Configuration -->
        <div class="form-section-riser" style="margin-top: 22px;">
          <span class="riser-label">Fiscal Year Configuration</span>
          <div class="riser-line"></div>
        </div>
        <div class="form-grid-3">
          <FormSelect
            label="FY Start Month"
            v-model="form.fiscal_year_start_month"
            :options="monthOptions"
            :hint="'Ethiopian FY opens on Hamle 1 (Jul 8). Adjust only if your entity runs a different fiscal cycle.'"
          />
          <FormInput
            label="FY Start Day (Gregorian)"
            type="number"
            v-model="form.fiscal_year_start_day"
            :min="1"
            :max="31"
            :hint="'Day-of-month when Hamle 1 falls — typically 8, or 9 in an Ethiopian leap year.'"
          />
          <FormSelect
            label="Week Start Day"
            v-model="form.week_start_day"
            :options="weekStartOptions"
          />
        </div>

        <!-- Working Hour Ceilings -->
        <div class="form-section-riser" style="margin-top: 22px;">
          <span class="riser-label">Working Hour Ceilings</span>
          <div class="riser-line"></div>
        </div>
        <div class="form-grid-3">
          <FormInput
            label="Default Daily Hours"
            type="number"
            v-model="form.default_daily_hours"
            :min="1"
            :max="24"
            :step="0.5"
          />
          <FormInput
            label="Default Weekly Hours"
            type="number"
            v-model="form.default_weekly_hours"
            :min="1"
            :max="168"
            :step="0.5"
            :hint="'Auto-calculated from the Weekly Schedule tab. Retail/factory often use 48 hrs.'"
          />
          <FormInput
            label="Payroll Days per Month"
            type="number"
            v-model="form.payroll_days_per_month"
            :min="1"
            :max="31"
            :step="0.5"
            :hint="'Divisor for daily-rate calculations — absence deductions and pro-rated salary. Standard is 26.'"
          />
        </div>

        <!-- Flags -->
        <div class="form-section-riser" style="margin-top: 22px;">
          <span class="riser-label">Calendar Flags</span>
          <div class="riser-line"></div>
        </div>
        <div class="flags-row">
          <FormCheckbox
            label="Set as Entity Default Calendar"
            description="Only one calendar per entity can be the default. Setting this will replace the current default for the selected entity."
            v-model="form.is_default"
          />
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════
         TAB 2 — WEEKLY SCHEDULE
    ══════════════════════════════════════════ -->
    <div v-else-if="activeTab === 'weekly'" class="tab-body">
      <div class="clean-card">
        <div class="weekly-card-header">
          <div>
            <div class="card-section-title">Baseline Weekly Rhythm</div>
            <p class="card-section-sub">Define the 7-day repeating pattern that populates all calendar dates for this fiscal year.</p>
          </div>
          <!-- Preset buttons -->
          <div class="preset-chips">
            <span class="preset-label-txt">Presets:</span>
            <AppButton variant="outline" size="xs" @click="applyPreset('5day')">5-Day / 40 hrs</AppButton>
            <AppButton variant="outline" size="xs" @click="applyPreset('6day')">6-Day / 48 hrs</AppButton>
            <AppButton variant="outline" size="xs" @click="applyPreset('5half')">5.5-Day / 44 hrs</AppButton>
          </div>
        </div>

        <!-- Summary banner -->
        <div class="weekly-summary-bar">
          <div class="ws-stat">
            <span class="ws-num">{{ weeklyTotals.workDays }}</span>
            <span class="ws-unit">work day{{ weeklyTotals.workDays !== 1 ? 's' : '' }}</span>
          </div>
          <div class="ws-divider"></div>
          <div class="ws-stat" v-if="weeklyTotals.halfDays > 0">
            <span class="ws-num">{{ weeklyTotals.halfDays }}</span>
            <span class="ws-unit">half day{{ weeklyTotals.halfDays !== 1 ? 's' : '' }}</span>
          </div>
          <div class="ws-divider" v-if="weeklyTotals.halfDays > 0"></div>
          <div class="ws-stat">
            <span class="ws-num">{{ weeklyTotals.restDays }}</span>
            <span class="ws-unit">rest day{{ weeklyTotals.restDays !== 1 ? 's' : '' }}</span>
          </div>
          <div class="ws-divider"></div>
          <div class="ws-stat ws-stat--highlight">
            <span class="ws-num">{{ weeklyTotals.totalHours.toFixed(2) }}</span>
            <span class="ws-unit">hrs / week</span>
          </div>
        </div>

        <!-- 7-day visual cards -->
        <div class="weekday-cards-grid">
          <div
            v-for="row in weekdayRows"
            :key="row.weekday"
            class="weekday-card"
            :class="{
              'wdc-working':  row.day_type === 'working',
              'wdc-halfday':  row.day_type === 'half_day',
              'wdc-weekend':  row.day_type === 'weekend',
            }"
          >
            <div class="wdc-header">
              <span class="wdc-short">{{ row.short }}</span>
              <span class="wdc-full">{{ row.name }}</span>
            </div>
            <div class="wdc-hours">
              <span class="wdc-hrs-num">{{ row.planned_hours.toFixed(1) }}</span>
              <span class="wdc-hrs-unit">hrs</span>
            </div>
            <div class="wdc-controls">
              <select
                class="wdc-select"
                v-model="row.day_type"
                @change="onDayTypeChange(row)"
              >
                <option value="working">Working</option>
                <option value="half_day">Half Day</option>
                <option value="weekend">Weekend</option>
              </select>
            </div>
            <div class="wdc-pill-wrap">
              <span
                class="wdc-pill"
                :class="{
                  'pill-working':  row.day_type === 'working',
                  'pill-halfday':  row.day_type === 'half_day',
                  'pill-weekend':  row.day_type === 'weekend',
                }"
              >
                {{ row.day_type === 'working' ? 'Standard' : (row.day_type === 'half_day' ? 'Half Day' : 'Rest') }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════
         TAB 3 — HOLIDAY RECONCILIATION & OVERRIDES
    ══════════════════════════════════════════ -->
    <div v-else-if="activeTab === 'overrides'" class="tab-body">
      <div class="clean-card">
        <!-- Card Header (Zero Add Buttons in Card Header as per Rule 11.2) -->
        <div class="overrides-card-header">
          <div>
            <div class="card-section-title">Holiday Reconciliation &amp; Day Overrides</div>
            <p class="card-section-sub">
              Holidays from the master catalog are automatically cross-checked against your Weekly Schedule.
              Observances landing on working days are flagged and defaulted to 0 hours.
            </p>
          </div>
        </div>

        <!-- Reconciliation Summary Strip -->
        <div class="reconciliation-summary-bar">
          <div class="rs-stat">
            <span class="rs-num">{{ holidayStats.total }}</span>
            <span class="rs-unit">Master Holidays</span>
          </div>
          <div class="rs-divider"></div>
          <div class="rs-stat rs-stat--conflict">
            <span class="rs-num">{{ holidayStats.workingConflicts }}</span>
            <span class="rs-unit">Working Conflicts (Overridden)</span>
          </div>
          <div class="rs-divider"></div>
          <div class="rs-stat rs-stat--aligned">
            <span class="rs-num">{{ holidayStats.weekendAlignments }}</span>
            <span class="rs-unit">Rest Day Aligned</span>
          </div>
          <div class="rs-divider"></div>
          <div class="rs-stat" v-if="holidayStats.rolledOver > 0">
            <span class="rs-num" style="color: #0284c7;">{{ holidayStats.rolledOver }}</span>
            <span class="rs-unit">Monday Rollovers</span>
          </div>
          <div class="rs-divider" v-if="holidayStats.rolledOver > 0"></div>
          <div class="rs-stat">
            <span class="rs-num">{{ holidayStats.customCount }}</span>
            <span class="rs-unit">Custom Overrides</span>
          </div>
        </div>

        <!-- Section 1: Master Holiday Reconciliation Table -->
        <div class="overrides-table-section">
          <div class="section-subheading">
            <span>Statutory &amp; Company Holidays (Fiscal Year 2026/27)</span>
          </div>

          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr>
                  <th class="child-th-no">#</th>
                  <th>Observance &amp; Type</th>
                  <th>Gregorian Date</th>
                  <th>Ethiopian Date (E.C.)</th>
                  <th>Day of Week</th>
                  <th>Weekly Baseline</th>
                  <th>Conflict Status</th>
                  <th>Override Classification</th>
                  <th>Planned Hrs</th>
                  <th>Weekend Rollover</th>
                  <th style="width: 70px; text-align: center;">Observed</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="(row, idx) in holidayRows"
                  :key="row.holiday_id"
                  :class="{ 'row-inactive': !row.is_active }"
                >
                  <td class="child-td-no">{{ idx + 1 }}</td>
                  <td>
                    <div class="cell-observance">
                      <span class="td-name">{{ row.name }}</span>
                      <span class="td-sub-code">{{ row.code }} &bull; {{ row.holiday_type }}</span>
                    </div>
                  </td>
                  <td>
                    <span class="td-tertiary">{{ formatDate(row.date) }}</span>
                  </td>
                  <td>
                    <span class="td-tertiary">{{ row.ethiopian_date_text }}</span>
                  </td>
                  <td>
                    <span class="td-dayname">{{ getDayOfWeekDetails(row.date).dayName }}</span>
                  </td>
                  <td>
                    <span
                      class="baseline-badge"
                      :class="getDayOfWeekDetails(row.date).baselineType === 'working' ? 'base-working' : 'base-weekend'"
                    >
                      {{ getDayOfWeekDetails(row.date).baselineType === 'working' ? `Working (${getDayOfWeekDetails(row.date).baselineHours.toFixed(1)}h)` : 'Rest Day (0h)' }}
                    </span>
                  </td>
                  <td>
                    <span
                      v-if="getDayOfWeekDetails(row.date).isWorkingConflict"
                      class="conflict-pill conflict-pill--warn"
                      title="Falls on a scheduled working day; override sets planned hours to 0"
                    >
                      <AlertTriangle :size="12" />
                      <span>Working Conflict</span>
                    </span>
                    <span
                      v-else
                      class="conflict-pill conflict-pill--ok"
                      title="Falls on scheduled rest day; no working hours impacted"
                    >
                      <CheckCircle2 :size="12" />
                      <span>Rest Aligned</span>
                    </span>
                  </td>
                  <td>
                    <select
                      class="cell-select"
                      v-model="row.day_type"
                      :disabled="!row.is_active"
                      @change="onHolidayDayTypeChange(row)"
                    >
                      <option value="holiday">Public Holiday (0h)</option>
                      <option value="half_day">Half Day (4h)</option>
                      <option value="working">Working Day (8h)</option>
                      <option value="weekend">Rest / Weekend (0h)</option>
                    </select>
                  </td>
                  <td>
                    <span class="td-hours-val">{{ row.planned_hours.toFixed(1) }} h</span>
                  </td>
                  <td>
                    <!-- Weekend rollover action -->
                    <div v-if="!getDayOfWeekDetails(row.date).isWorkingConflict">
                      <button
                        v-if="!row.rollover_to_next_day"
                        type="button"
                        class="btn-rollover"
                        :disabled="!row.is_active"
                        @click="row.rollover_to_next_day = true"
                        title="Grant substitute holiday on the next scheduled working day"
                      >
                        <RotateCcw :size="11" />
                        <span>Roll to Mon</span>
                      </button>
                      <div v-else class="rollover-active-chip">
                        <span>Mon Sub (0h)</span>
                        <button
                          type="button"
                          class="btn-chip-remove"
                          @click="row.rollover_to_next_day = false"
                          title="Cancel Monday substitute"
                        >
                          ✕
                        </button>
                      </div>
                    </div>
                    <span v-else class="td-tertiary">—</span>
                  </td>
                  <td style="text-align: center;">
                    <input
                      type="checkbox"
                      class="holiday-checkbox"
                      v-model="row.is_active"
                      title="Toggle calendar observance"
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Section 2: Custom Day Overrides Table -->
        <div class="custom-overrides-container">
          <div class="custom-header">
            <div>
              <div class="section-subheading" style="margin-bottom: 2px;">
                <span>Custom Day Overrides (Ad-Hoc &amp; Local Closures)</span>
              </div>
              <p class="custom-sub">
                Entity-specific non-statutory dates such as annual inventory shutdowns, factory maintenance, or government-decreed bridge days.
              </p>
            </div>
          </div>

          <!-- Empty State -->
          <div v-if="customOverrides.length === 0" class="custom-empty-box">
            <Calendar :size="24" class="custom-empty-icon" />
            <div class="custom-empty-text">No custom day overrides added yet.</div>
            <div class="custom-empty-sub">
              Add a row below if this calendar requires special company closures, bridge days, or maintenance shutdowns.
            </div>
            <button type="button" class="btn-empty-action" @click="addCustomOverrideRow">
              <Plus :size="13" />
              <span>Add Row</span>
            </button>
          </div>

          <!-- Custom Overrides Dynamic Child Sub-table (Academic Qualification Standard) -->
          <div v-else class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr>
                  <th class="child-th-check">
                    <input 
                      type="checkbox" 
                      :checked="isAllCustomSelected" 
                      @change="toggleSelectAllCustom" 
                      class="table-checkbox"
                    />
                  </th>
                  <th class="child-th-no">#</th>
                  <th style="min-width: 150px;">Date <span class="required-star">*</span></th>
                  <th style="min-width: 220px;">Override Name / Reason <span class="required-star">*</span></th>
                  <th style="min-width: 170px;">Classification <span class="required-star">*</span></th>
                  <th style="min-width: 120px;">Planned Hours</th>
                  <th class="child-th-col-icon">
                    <IconColumnSolid :size="13" class="col-icon-solid" />
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(cRow, cIdx) in customOverrides" :key="cRow.id">
                  <td class="child-td-check">
                    <input 
                      type="checkbox" 
                      :value="cRow.id" 
                      v-model="selectedCustomIds" 
                      class="table-checkbox"
                    />
                  </td>
                  <td class="child-td-no">{{ cIdx + 1 }}</td>
                  <td>
                    <input 
                      type="date" 
                      v-model="cRow.date" 
                      class="child-inline-input" 
                    />
                  </td>
                  <td>
                    <input 
                      type="text" 
                      v-model="cRow.name" 
                      class="child-inline-input" 
                      placeholder="e.g. Annual Plant Maintenance" 
                    />
                  </td>
                  <td>
                    <select 
                      v-model="cRow.day_type" 
                      class="child-inline-select" 
                      @change="onCustomRowDayTypeChange(cRow)"
                    >
                      <option v-for="opt in calDayTypeOptions" :key="opt.value" :value="opt.value">
                        {{ opt.label }}
                      </option>
                    </select>
                  </td>
                  <td>
                    <input 
                      type="number" 
                      v-model.number="cRow.planned_hours" 
                      class="child-inline-input font-mono" 
                      min="0" 
                      max="24" 
                      step="0.5" 
                    />
                  </td>
                  <td class="child-td-action">
                    <button
                      type="button"
                      class="btn-row-expand"
                      @click="openRowModal(cRow, cIdx)"
                      title="Expand Row Details"
                    >
                      <Expand :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Exactly ONE Add Row Button Directly Beneath Table (Rule 11.2 Standard) -->
          <button 
            type="button" 
            class="btn-add-row" 
            @click="addCustomOverrideRow"
          >
            <Plus :size="13" />
            <span>Add Row</span>
          </button>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════
         TAB 4 — YEAR MATRIX
    ══════════════════════════════════════════ -->
    <div v-else-if="activeTab === 'matrix'" class="tab-body">
      <div class="clean-card">
        <div class="matrix-card-header">
          <div>
            <div class="card-section-title">Fiscal Year 2026/27 — 12-Month Overview</div>
            <p class="card-section-sub">Annual breakdown automatically generated from your Weekly Schedule and Holiday Overrides.</p>
          </div>
          <div class="matrix-annual-totals">
            <div class="mat-stat">
              <span class="mat-num">{{ annualTotals.work }}</span>
              <span class="mat-lbl">Working Days</span>
            </div>
            <div class="mat-stat mat-stat--holiday">
              <span class="mat-num">{{ annualTotals.holiday }}</span>
              <span class="mat-lbl">Holidays</span>
            </div>
            <div class="mat-stat mat-stat--rest">
              <span class="mat-num">{{ annualTotals.weekend }}</span>
              <span class="mat-lbl">Rest Days</span>
            </div>
            <div class="mat-stat mat-stat--hours">
              <span class="mat-num">{{ (annualTotals.work * parseFloat(form.default_daily_hours || '8')).toFixed(0) }}</span>
              <span class="mat-lbl">Total Hours</span>
            </div>
          </div>
        </div>

        <!-- 12-month mini cards -->
        <div class="year-matrix-grid">
          <div
            v-for="mo in fyMonths"
            :key="`${mo.y}-${mo.m}`"
            class="mini-month-card"
          >
            <div class="mmc-header">
              <span class="mmc-name">{{ mo.monthName }}</span>
              <span class="mmc-year">{{ mo.y }}</span>
            </div>

            <!-- Stacked bar -->
            <div class="mmc-bar-track">
              <div
                class="mmc-bar mmc-bar--work"
                :style="{ width: `${(mo.workDays / mo.daysInMonth) * 100}%` }"
                :title="`${mo.workDays} working`"
              ></div>
              <div
                class="mmc-bar mmc-bar--holiday"
                :style="{ width: `${(mo.holidayDays / mo.daysInMonth) * 100}%` }"
                :title="`${mo.holidayDays} holiday`"
              ></div>
              <div
                class="mmc-bar mmc-bar--rest"
                :style="{ width: `${(mo.weekendDays / mo.daysInMonth) * 100}%` }"
                :title="`${mo.weekendDays} rest`"
              ></div>
            </div>

            <div class="mmc-stats">
              <div class="mmc-stat">
                <span class="mmc-dot mmc-dot--work"></span>
                <span>{{ mo.workDays }} Work</span>
              </div>
              <div class="mmc-stat" v-if="mo.holidayDays > 0">
                <span class="mmc-dot mmc-dot--holiday"></span>
                <span>{{ mo.holidayDays }} Holiday</span>
              </div>
              <div class="mmc-stat">
                <span class="mmc-dot mmc-dot--rest"></span>
                <span>{{ mo.weekendDays }} Rest</span>
              </div>
            </div>

            <div class="mmc-hours">
              {{ (mo.workDays * parseFloat(form.default_daily_hours || '8')).toFixed(0) }} hrs
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Floating Batch Action Bar (Rule 11.3) -->
    <TableFloatingBar 
      :show="selectedCustomIds.length > 0"
      :selected-count="selectedCustomIds.length"
      :total-count="customOverrides.length"
      @delete="handleBatchDeleteCustom" 
      @close="selectedCustomIds = []" 
    />

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- EXPAND ROW MODAL (Academic Qualification Standard)             -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <div v-if="showRowModal && activeRowData" class="row-modal-overlay" @click="closeRowModal">
        <div class="row-modal-container" @click.stop>
          <!-- Header -->
          <div class="row-modal-header">
            <h3 class="row-modal-title">Custom Day Override (Row {{ activeRowIndex + 1 }})</h3>
            <button type="button" class="btn-modal-close" @click="closeRowModal" title="Close">
              <X :size="16" />
            </button>
          </div>

          <!-- Body -->
          <div class="row-modal-body">
            <div class="modal-grid-2">
              <div class="modal-form-group">
                <label class="modal-form-label">Effective Date <span class="required-star">*</span></label>
                <input type="date" v-model="activeRowData.date" class="modal-form-input" />
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Day Classification <span class="required-star">*</span></label>
                <div class="modal-select-wrap">
                  <select v-model="activeRowData.day_type" class="modal-form-select" @change="onCustomRowDayTypeChange(activeRowData)">
                    <option v-for="opt in calDayTypeOptions" :key="opt.value" :value="opt.value">
                      {{ opt.label }}
                    </option>
                  </select>
                  <ChevronDown :size="14" class="modal-select-chevron" />
                </div>
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Override Name / Label <span class="required-star">*</span></label>
                <input type="text" v-model="activeRowData.name" class="modal-form-input" placeholder="e.g. Annual Plant Maintenance" />
              </div>

              <div class="modal-form-group">
                <label class="modal-form-label">Planned Work Hours</label>
                <input type="number" v-model.number="activeRowData.planned_hours" class="modal-form-input font-mono" min="0" max="24" step="0.5" />
              </div>

              <div class="modal-form-group col-span-2">
                <label class="modal-form-label">Administrative Reason / Authority Note</label>
                <input type="text" v-model="activeRowData.reason" class="modal-form-input" placeholder="e.g. Approved under Ministry circular or corporate maintenance directive" />
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
                <Copy :size="14" />
                <span>Duplicate Row</span>
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-action" 
                @click="insertAboveModalRow"
              >
                <Plus :size="14" />
                <span>Insert Above</span>
              </button>
              <button 
                type="button" 
                class="btn-modal-ctrl-action" 
                @click="insertBelowModalRow"
              >
                <Plus :size="14" />
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
/* ─── Page Layout ─── */
.wc-create-page {
  padding: 0;
  background-color: #f8fafc;
  min-height: calc(100vh - 60px);
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  font-family: 'Inter', sans-serif;
}

/* ─── Top Nav Bar ─── */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
  flex-wrap: wrap;
  gap: 12px;
}
.nav-left {
  display: flex;
  align-items: center;
  gap: 0;
}
.nav-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-clear {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-clear:hover { background-color: #f8fafc; border-color: #cbd5e1; }
.btn-save {
  height: 38px;
  padding: 0 22px;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 13.5px;
  font-weight: 500;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.15s ease;
}
.btn-save:hover { background-color: #09437f; }

/* ─── Toast ─── */
.toast-bar {
  position: fixed;
  top: 22px;
  right: 24px;
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 11px 18px;
  border-radius: 10px;
  font-size: 13.5px;
  font-weight: 500;
  z-index: 9999;
  box-shadow: 0 8px 24px rgba(0,0,0,0.10);
}
.toast-success { background: #ffffff; border: 1px solid #d1fae5; color: #059669; }
.toast-error   { background: #ffffff; border: 1px solid #fee2e2; color: #dc2626; }
.toast-fade-enter-active, .toast-fade-leave-active { transition: opacity 0.25s ease; }
.toast-fade-enter-from, .toast-fade-leave-to { opacity: 0; }

/* ─── Tabs Row ─── */
.tabs-row {
  background: transparent;
  padding: 0;
}

/* ─── Tab Body ─── */
.tab-body { display: flex; flex-direction: column; gap: 14px; }

/* ─── Clean Card ─── */
.clean-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 22px 24px 28px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.03);
}

/* ─── Card Section Title ─── */
.card-section-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  display: block;
  margin-bottom: 16px;
}
.card-section-sub {
  font-size: 12.5px;
  color: #737373;
  margin-top: -10px;
  margin-bottom: 18px;
  line-height: 1.45;
}

/* ─── Section Risers ─── */
.form-section-riser {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 14px;
}
.riser-label {
  font-size: 11.5px;
  font-weight: 600;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  white-space: nowrap;
}
.riser-line {
  flex: 1;
  height: 1px;
  background-color: #e2e8f0;
}

/* ─── Form Grids ─── */
.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
  margin-bottom: 4px;
}
.col-span-2 { grid-column: span 2; }
.col-span-3 { grid-column: span 3; }

/* ─── Flags Row ─── */
.flags-row {
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-width: 560px;
}

/* ─────────────────
   TAB 2: WEEKLY
───────────────── */
.weekly-card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 16px;
}
.preset-chips {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.preset-label-txt {
  font-size: 12px;
  font-weight: 500;
  color: #737373;
}
.btn-preset {
  display: inline-flex;
  align-items: center;
  height: 30px;
  padding: 0 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #fafafa;
  font-size: 12px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.12s ease;
}
.btn-preset:hover { background-color: #f0f7ff; border-color: #0B529C; color: #0B529C; }

/* Weekly summary banner */
.weekly-summary-bar {
  display: flex;
  align-items: center;
  gap: 0;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 20px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}
.ws-stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 0 20px;
}
.ws-stat--highlight .ws-num { color: #0B529C; }
.ws-num  { font-size: 22px; font-weight: 700; color: #404040; line-height: 1.2; }
.ws-unit { font-size: 11.5px; color: #737373; font-weight: 500; }
.ws-divider {
  width: 1px;
  height: 36px;
  background-color: #e2e8f0;
}

/* 7-day cards grid */
.weekday-cards-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 10px;
}
@media (max-width: 900px) {
  .weekday-cards-grid { grid-template-columns: repeat(4, 1fr); }
}

.weekday-card {
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  background-color: #ffffff;
  transition: border-color 0.15s ease;
}
.wdc-working  { background-color: #f0fdf4; border-color: #bbf7d0; }
.wdc-halfday  { background-color: #fffbeb; border-color: #fde68a; }
.wdc-weekend  { background-color: #fafbfc; border-color: #e2e8f0; }

.wdc-header {
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.wdc-short { font-size: 12px; font-weight: 700; color: #404040; text-transform: uppercase; letter-spacing: 0.04em; }
.wdc-full  { font-size: 11px; color: #737373; }

.wdc-hours {
  display: flex;
  align-items: baseline;
  gap: 3px;
}
.wdc-hrs-num  { font-size: 20px; font-weight: 700; color: #404040; line-height: 1; }
.wdc-hrs-unit { font-size: 11px; color: #737373; }

.wdc-controls { margin-top: 2px; }
.wdc-select {
  width: 100%;
  height: 30px;
  padding: 0 8px;
  font-size: 12px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  background-color: #ffffff;
  color: #404040;
  cursor: pointer;
  outline: none;
}
.wdc-select:focus { border-color: #0B529C; }

.wdc-pill-wrap { display: flex; }
.wdc-pill {
  display: inline-flex;
  padding: 2px 9px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 600;
}
.pill-working { background-color: #dcfce7; color: #15803d; }
.pill-halfday { background-color: #fef3c7; color: #b45309; }
.pill-weekend { background-color: #f1f5f9; color: #64748b; }

/* ──────────────────────────────────────────────
   TAB 3: HOLIDAY RECONCILIATION & OVERRIDES
────────────────────────────────────────────── */
.overrides-card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 16px;
}
.btn-add-custom-override {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.12s ease;
}
.btn-add-custom-override:hover {
  background-color: #f0f7ff;
  border-color: #0B529C;
  color: #0B529C;
}

/* Summary metrics strip */
.reconciliation-summary-bar {
  display: flex;
  align-items: center;
  gap: 0;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 20px;
  margin-bottom: 22px;
  flex-wrap: wrap;
}
.rs-stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 0 18px;
}
.rs-num {
  font-size: 20px;
  font-weight: 700;
  color: #404040;
  line-height: 1.2;
}
.rs-unit {
  font-size: 11.5px;
  color: #737373;
  font-weight: 500;
}
.rs-divider {
  width: 1px;
  height: 32px;
  background-color: #e2e8f0;
}
.rs-stat--conflict .rs-num { color: #d97706; }
.rs-stat--aligned .rs-num  { color: #059669; }

/* Subheading */
.overrides-table-section { margin-bottom: 24px; }
.section-subheading {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin-bottom: 10px;
}

/* Child Table */
.child-table-wrapper {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  margin-bottom: 16px;
}
.child-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}
.child-table thead th {
  height: 34px;
  padding: 0 12px;
  font-size: 11.5px;
  font-weight: 500;
  color: #737373;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  text-align: left;
  white-space: nowrap;
}
.child-table tbody td {
  height: 42px;
  padding: 0 12px;
  font-size: 13px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}
.child-table tbody tr:last-child td { border-bottom: none; }
.child-table tbody tr:hover td { background-color: #fafcff; }
.row-inactive td { opacity: 0.55; background-color: #fcfcfc; }

.child-th-no, .child-td-no {
  width: 36px;
  text-align: center;
  color: #737373;
}
.child-th-col-icon, .child-td-action {
  width: 44px;
  text-align: center;
}
.td-tertiary { color: #737373; }
.td-name { font-weight: 500; color: #404040; font-size: 13px; }

/* Cell Observance */
.cell-observance {
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.td-sub-code {
  font-size: 11px;
  color: #737373;
  text-transform: capitalize;
}
.td-dayname {
  font-weight: 500;
  color: #404040;
}

/* Baseline badges */
.baseline-badge {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 500;
  white-space: nowrap;
}
.base-working { background-color: #f0fdf4; color: #166534; border: 1px solid #dcfce7; }
.base-weekend { background-color: #f8fafc; color: #64748b; border: 1px solid #e2e8f0; }

/* Conflict pills */
.conflict-pill {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 2px 9px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 600;
  white-space: nowrap;
}
.conflict-pill--warn { background-color: #fef3c7; color: #b45309; }
.conflict-pill--ok   { background-color: #e0f2fe; color: #0369a1; }

/* Cell select */
.cell-select {
  height: 28px;
  padding: 0 8px;
  font-size: 12px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  background-color: #ffffff;
  color: #404040;
  cursor: pointer;
  outline: none;
}
.cell-select:focus { border-color: #0B529C; }
.td-hours-val {
  font-weight: 600;
  color: #404040;
}

/* Weekend rollover buttons */
.btn-rollover {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  height: 26px;
  padding: 0 10px;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  background-color: #ffffff;
  font-size: 11px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.12s ease;
  white-space: nowrap;
}
.btn-rollover:hover:not(:disabled) {
  background-color: #eff6ff;
  border-color: #0B529C;
  color: #0B529C;
}
.btn-rollover:disabled { opacity: 0.5; cursor: not-allowed; }

.rollover-active-chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 26px;
  padding: 0 8px;
  background-color: #e0f2fe;
  color: #0284c7;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  white-space: nowrap;
}
.btn-chip-remove {
  border: none;
  background: transparent;
  color: #0284c7;
  cursor: pointer;
  font-size: 10px;
  padding: 0 2px;
}
.btn-chip-remove:hover { color: #dc2626; }

.holiday-checkbox {
  width: 15px;
  height: 15px;
  accent-color: #0B529C;
  cursor: pointer;
}

/* Status pills for custom table */
.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
  white-space: nowrap;
}
.pill-holiday { background-color: #f3e8ff; color: #7c3aed; }
.pill-halfday { background-color: #fef3c7; color: #b45309; }
.pill-working { background-color: #dcfce7; color: #059669; }
.pill-weekend { background-color: #f1f5f9; color: #64748b; }

.btn-row-delete {
  width: 26px; height: 26px;
  border: none; background: transparent;
  color: #94a3b8; border-radius: 5px; cursor: pointer;
  display: inline-flex; align-items: center; justify-content: center;
  transition: all 0.12s ease;
}
.btn-row-delete:hover { color: #ef4444; background-color: #fff5f5; }

/* Custom Day Overrides Section */
.custom-overrides-container {
  margin-top: 10px;
  padding-top: 18px;
  border-top: 1px solid #f1f5f9;
}
.custom-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 12px;
}
.custom-sub {
  font-size: 12px;
  color: #737373;
  margin-top: 2px;
  line-height: 1.4;
}
.btn-add-custom-sm {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 30px;
  padding: 0 12px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  background-color: #ffffff;
  font-size: 12px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.12s ease;
}
.btn-add-custom-sm:hover {
  background-color: #f0f7ff;
  border-color: #0B529C;
  color: #0B529C;
}

.custom-empty-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 28px 20px;
  background-color: #fafbfc;
  border: 1px dashed #cbd5e1;
  border-radius: 10px;
  text-align: center;
}
.custom-empty-icon { color: #94a3b8; margin-bottom: 8px; }
.custom-empty-text { font-size: 13px; font-weight: 600; color: #404040; margin-bottom: 4px; }
.custom-empty-sub  { font-size: 12px; color: #737373; max-width: 460px; margin-bottom: 14px; line-height: 1.4; }
.btn-empty-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.12s ease;
}
.btn-empty-action:hover {
  background-color: #f0f7ff;
  border-color: #0B529C;
  color: #0B529C;
}

/* ═════════════════════════════════════════════════════════════════════ */
/* DYNAMIC SUB-TABLE INLINE INPUTS & ROW CONTROLS                        */
/* ═════════════════════════════════════════════════════════════════════ */
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
  color: #0f172a;
  background-color: #f1f5f9;
}

/* The ONE Add Row button directly below table */
.btn-add-row {
  height: 32px;
  padding: 0 14px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-add-row:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

/* ═════════════════════════════════════════════════════════════════════ */
/* EXPAND ROW MODAL SYSTEM (Academic Qualification Standard)             */
/* ═════════════════════════════════════════════════════════════════════ */
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

/* Modal Footer */
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
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  color: #404040;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-modal-ctrl-icon:hover:not(:disabled) {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}
.btn-modal-ctrl-icon:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.btn-modal-ctrl-action {
  height: 34px;
  padding: 0 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  color: #404040;
  font-size: 12.5px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-modal-ctrl-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

/* ─────────────────
   TAB 4: MATRIX
───────────────── */
.matrix-card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 16px;
  margin-bottom: 22px;
}
.matrix-annual-totals {
  display: flex;
  align-items: center;
  gap: 24px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 12px 20px;
}
.mat-stat { display: flex; flex-direction: column; align-items: center; gap: 2px; }
.mat-num  { font-size: 20px; font-weight: 700; color: #404040; }
.mat-lbl  { font-size: 11px; font-weight: 500; color: #737373; white-space: nowrap; }
.mat-stat--holiday .mat-num { color: #7c3aed; }
.mat-stat--rest .mat-num    { color: #64748b; }
.mat-stat--hours .mat-num   { color: #0B529C; }

.year-matrix-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}
@media (max-width: 1024px) { .year-matrix-grid { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 700px)  { .year-matrix-grid { grid-template-columns: repeat(2, 1fr); } }

.mini-month-card {
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 14px 12px;
  background-color: #ffffff;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.mmc-header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
}
.mmc-name { font-size: 13px; font-weight: 600; color: #404040; }
.mmc-year { font-size: 11px; color: #737373; }

/* Stacked bar */
.mmc-bar-track {
  display: flex;
  height: 6px;
  border-radius: 4px;
  overflow: hidden;
  background-color: #f1f5f9;
}
.mmc-bar { height: 100%; transition: width 0.3s ease; }
.mmc-bar--work    { background-color: #059669; }
.mmc-bar--holiday { background-color: #7c3aed; }
.mmc-bar--rest    { background-color: #94a3b8; }

.mmc-stats {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 10px;
}
.mmc-stat {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11.5px;
  color: #737373;
}
.mmc-dot {
  width: 7px; height: 7px;
  border-radius: 50%;
  flex-shrink: 0;
}
.mmc-dot--work    { background-color: #059669; }
.mmc-dot--holiday { background-color: #7c3aed; }
.mmc-dot--rest    { background-color: #94a3b8; }

.mmc-hours {
  font-size: 12px;
  font-weight: 600;
  color: #0B529C;
  border-top: 1px solid #f1f5f9;
  padding-top: 8px;
}
</style>
