<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Plus, Search, Filter, MoreVertical, 
  PanelLeftClose, PanelLeftOpen,
  CheckCircle2
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import { useToast } from '../../composables/useToast';

const router = useRouter();

// ─── Breadcrumbs ───
const breadcrumbItems = [
  { label: 'Shift Pattern' }
];

// ─── View State (Collapsed Master-Detail vs Expanded Focus) ───
// Figma Node 6106:153845 = Master-Detail (isFocused = false)
// Figma Node 6447:149773 = Full-Width Focus (isFocused = true)
const isFocused = ref(false);

// ─── Types ───
export interface ShiftPatternDayItem {
  id: number;
  day_index: number;
  shift_name?: string;
  start_time?: string;
  end_time?: string;
  is_rest: boolean;
}

export interface ShiftPatternRecord {
  id: number;
  code: string;
  name: string;
  badge: string;
  badge_type: 'global' | 'pending' | 'accepted';
  shift_days_label: string;
  cycle_days: number;
  work_calendar_name: string;
  entity_name: string;
  days: ShiftPatternDayItem[];
}

// ─── Mock Data exactly matching Figma Nodes 6106:153845 & 6447:149773 ───
const patterns = ref<ShiftPatternRecord[]>([
  {
    id: 1,
    code: 'PAT-OFF-5D',
    name: 'Office Regular',
    badge: 'Global',
    badge_type: 'global',
    shift_days_label: '5 Day of Shift',
    cycle_days: 7,
    work_calendar_name: 'Office Calendar (40h/wk)',
    entity_name: 'QMT Head Quarter',
    days: [
      { id: 101, day_index: 1, shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', is_rest: false },
      { id: 102, day_index: 2, shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', is_rest: false },
      { id: 103, day_index: 3, shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', is_rest: false },
      { id: 104, day_index: 4, shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', is_rest: false },
      { id: 105, day_index: 5, shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', is_rest: false },
      { id: 106, day_index: 6, is_rest: true },
      { id: 107, day_index: 7, is_rest: true }
    ]
  },
  {
    id: 2,
    code: 'PAT-RETAIL-6D',
    name: 'Retail 6 Day Rota',
    badge: 'Pending',
    badge_type: 'pending',
    shift_days_label: '6 Day of Shift',
    cycle_days: 7,
    work_calendar_name: 'Retail Calendar (48h/wk)',
    entity_name: 'Bole Commercial Branch',
    days: [
      { id: 201, day_index: 1, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 202, day_index: 2, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 203, day_index: 3, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 204, day_index: 4, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 205, day_index: 5, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 206, day_index: 6, shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 207, day_index: 7, is_rest: true }
    ]
  },
  {
    id: 3,
    code: 'PAT-GUARD-4C',
    name: 'Guard 4 Day Cycle',
    badge: 'Accepted',
    badge_type: 'accepted',
    shift_days_label: '4 Day of Shift',
    cycle_days: 4,
    work_calendar_name: 'Industrial Security Calendar',
    entity_name: 'Hawassa Industrial Plant',
    days: [
      { id: 301, day_index: 1, shift_name: 'Night Guard', start_time: '22:00', end_time: '06:00', is_rest: false },
      { id: 302, day_index: 2, shift_name: 'Night Guard', start_time: '22:00', end_time: '06:00', is_rest: false },
      { id: 303, day_index: 3, is_rest: true },
      { id: 304, day_index: 4, is_rest: true }
    ]
  }
]);

// ─── State ───
const selectedPatternId = ref<number>(patterns.value[0].id);
const searchQuery = ref('');
const { toast } = useToast();

const showToast = (msg: string) => {
  toast.success(msg);
};

const selectedPattern = computed(() => {
  return patterns.value.find(p => p.id === selectedPatternId.value) || patterns.value[0];
});

const filteredPatterns = computed(() => {
  if (!searchQuery.value) return patterns.value;
  const q = searchQuery.value.toLowerCase();
  return patterns.value.filter(p => 
    p.name.toLowerCase().includes(q) || 
    p.work_calendar_name.toLowerCase().includes(q)
  );
});

// ─── Cycle Statistics ───
const workingDaysCount = computed(() => {
  return selectedPattern.value.days.filter(d => !d.is_rest).length;
});

const restDaysCount = computed(() => {
  return selectedPattern.value.days.filter(d => d.is_rest).length;
});

// ─── Quick Create Modal ───
const showQuickCreate = ref(false);
const quickForm = ref({
  name: '',
  code: '',
  cycle_days: '7'
});

const handleSaveQuick = () => {
  if (!quickForm.value.name.trim()) {
    showToast('Please enter a pattern name');
    return;
  }
  const cycle = Number(quickForm.value.cycle_days) || 7;
  const newDays: ShiftPatternDayItem[] = Array.from({ length: cycle }, (_, i) => {
    const idx = i + 1;
    const isRest = idx > 5;
    return {
      id: Date.now() + i,
      day_index: idx,
      shift_name: isRest ? undefined : 'Office Day',
      start_time: isRest ? undefined : '08:30',
      end_time: isRest ? undefined : '17:30',
      is_rest: isRest
    };
  });

  const newPat: ShiftPatternRecord = {
    id: Date.now(),
    code: quickForm.value.code || `PAT-${Date.now().toString().slice(-4)}`,
    name: quickForm.value.name,
    badge: 'Global',
    badge_type: 'global',
    shift_days_label: `${cycle - 2} Day of Shift`,
    cycle_days: cycle,
    work_calendar_name: 'Office Calendar (40h/wk)',
    entity_name: 'QMT Head Quarter',
    days: newDays
  };

  patterns.value.unshift(newPat);
  selectedPatternId.value = newPat.id;
  showQuickCreate.value = false;
  showToast(`Shift Pattern "${newPat.name}" created.`);
};
</script>

<template>
  <div class="shift-patterns-page">
    <!-- Breadcrumb Standard -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- ─── TOP HEADER CARD (Figma Node 6106:153854 & 6447:149782) ─── -->
    <div class="patterns-top-card">
      <div class="header-text-block">
        <h2 class="page-title">Shift Pattern</h2>
        <p class="page-subtitle">
          Configure recurring rota sequences, multi-week cycles, and rest intervals across workforce divisions.
        </p>
      </div>

      <AppButton 
        variant="primary" 
        @click="router.push('/hr/shift-patterns/create')"
      >
        <template #icon-left><Plus :size="16" /></template>
        Create Pattern
      </AppButton>
    </div>

    <!-- ─── MASTER-DETAIL CONTAINER (Figma Node 6106:153859 & 6447:149787) ─── -->
    <div class="patterns-content-layout">
      <!-- ─── LEFT COLUMN: PATTERNS LIST (Hidden in Focus/Expanded View) ─── -->
      <div v-if="!isFocused" class="patterns-list-panel">
        <!-- Search & Filter Row (Figma Node 6106:153861) -->
        <div class="list-search-filter-row">
          <div class="search-input-box">
            <Search :size="18" class="search-icon" />
            <input 
              v-model="searchQuery" 
              type="text" 
              class="search-input"
              placeholder="Search Name..."
              aria-label="Search patterns"
            />
          </div>

          <button type="button" class="btn-filter" title="Filter patterns">
            <Filter :size="18" />
            <span>Filter</span>
          </button>
        </div>

        <!-- Patterns Stack (Figma Node 6106:153864) -->
        <div class="patterns-cards-stack">
          <div 
            v-for="pat in filteredPatterns" 
            :key="pat.id"
            class="pattern-item-card"
            :class="{ active: selectedPatternId === pat.id }"
            @click="selectedPatternId = pat.id"
          >
            <div class="pattern-item-top">
              <div class="pattern-item-title-row">
                <span class="pattern-name">{{ pat.name }}</span>
                <span 
                  class="badge-pill" 
                  :class="`badge-${pat.badge_type}`"
                >
                  {{ pat.badge }}
                </span>
              </div>

              <button 
                type="button" 
                class="btn-item-more"
                title="Options"
                @click.stop
              >
                <MoreVertical :size="18" />
              </button>
            </div>

            <span class="pattern-shift-subtitle">{{ pat.shift_days_label }}</span>
          </div>
        </div>
      </div>

      <!-- ─── RIGHT COLUMN: DETAIL CARD (Expands to Full Width in Focus View) ─── -->
      <div 
        class="pattern-detail-panel" 
        :class="{ 'panel-expanded': isFocused }"
      >
        <!-- Header: Pattern Name, Badge, Subtitle & Focus/List Button (Figma Node 6106:153890 & 6447:149818) -->
        <div class="detail-header-row">
          <div class="detail-title-col">
            <div class="detail-title-with-badge">
              <h3 class="detail-name">{{ selectedPattern.name }}</h3>
              <span 
                class="badge-pill" 
                :class="`badge-${selectedPattern.badge_type}`"
              >
                {{ selectedPattern.badge }}
              </span>
            </div>
            <p class="detail-subtitle">
              {{ selectedPattern.work_calendar_name }} - {{ selectedPattern.entity_name }}
            </p>
          </div>

          <!-- Focus / List View Mode Toggle Button (Figma Node 6106:153898 & 6447:150125) -->
          <button 
            type="button" 
            class="btn-toggle-focus"
            @click="isFocused = !isFocused"
            :title="isFocused ? 'Switch to Master-Detail List' : 'Focus Full Screen'"
          >
            <component 
              :is="isFocused ? PanelLeftOpen : PanelLeftClose" 
              :size="18" 
            />
            <span>{{ isFocused ? 'List' : 'Focus' }}</span>
          </button>
        </div>

        <!-- Metrics Strip (Figma Node 6106:153899 & 6447:149827) -->
        <div class="detail-metrics-strip">
          <div class="metric-segment">
            <span class="metric-num">{{ selectedPattern.cycle_days }} Days</span>
            <span class="metric-txt">Cycle Span</span>
          </div>

          <div class="metric-divider"></div>

          <div class="metric-segment">
            <span class="metric-num">{{ workingDaysCount }} Days</span>
            <span class="metric-txt">Active Work Days</span>
          </div>

          <div class="metric-divider"></div>

          <div class="metric-segment">
            <span class="metric-num">{{ selectedPattern.cycle_days }} Days</span>
            <span class="metric-txt">Cycle Span</span>
          </div>
        </div>

        <!-- Day-by-Day Rota Schedule (Figma Node 6106:153915 & 6447:149843) -->
        <div class="days-schedule-container">
          <div 
            v-for="day in selectedPattern.days" 
            :key="day.id"
            class="day-schedule-card"
          >
            <div class="day-schedule-content">
              <!-- If Work Day -->
              <template v-if="!day.is_rest">
                <span class="day-title">Day {{ day.day_index }} : {{ day.shift_name }}</span>
                <span class="day-time">{{ day.start_time }} - {{ day.end_time }}</span>
              </template>

              <!-- If Rest Day -->
              <template v-else>
                <span class="day-title-rest">Day {{ day.day_index }} : Rest Day</span>
                <span class="badge-unpaid-rest">Unpaid Rest</span>
              </template>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Create Modal -->
    <QuickCreateModal
      :show="showQuickCreate"
      title="Create Shift Pattern"
      save-label="Create Pattern"
      width="md"
      @save="handleSaveQuick"
      @cancel="showQuickCreate = false"
    >
      <div class="quick-modal-body">
        <FormInput
          label="Pattern Name"
          v-model="quickForm.name"
          placeholder="e.g. Retail Weekend Coverage"
          required
        />
        <FormInput
          label="Pattern Code"
          v-model="quickForm.code"
          placeholder="e.g. PAT-RETAIL-WK"
        />
        <FormSelect
          label="Cycle Length (Days)"
          v-model="quickForm.cycle_days"
          :options="[
            { value: '4', label: '4 Days' },
            { value: '6', label: '6 Days' },
            { value: '7', label: '7 Days' },
            { value: '14', label: '14 Days' }
          ]"
        />
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.shift-patterns-page {
  padding: 0;
  background-color: #fafafa;
  min-height: 100vh;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
}

/* ─── TOP HEADER CARD (Figma Node 6106:153854 & 6447:149782) ─── */
.patterns-top-card {
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 24px;
  gap: 20px;
}

.header-text-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.page-title {
  font-size: 20px;
  font-weight: 600;
  color: #404040;
  margin: 0;
  line-height: 30px;
}

.page-subtitle {
  font-size: 14px;
  font-weight: 400;
  color: #737373;
  margin: 0;
  line-height: 20px;
}

.btn-create-pattern {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background-color: #0B529C;
  border: 1px solid #0B529C;
  border-radius: 8px;
  color: #ffffff;
  font-size: 14px;
  font-weight: 600;
  line-height: 20px;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  cursor: pointer;
  transition: background-color 0.15s ease;
  white-space: nowrap;
}

.btn-create-pattern:hover {
  background-color: #09427d;
}

/* ─── CONTENT LAYOUT (Figma Node 6106:153859 & 6447:149787) ─── */
.patterns-content-layout {
  display: flex;
  align-items: flex-start;
  gap: 24px;
  width: 100%;
}

/* ─── LEFT COLUMN: PATTERNS LIST (Figma Node 6106:153860) ─── */
.patterns-list-panel {
  width: 383px;
  background: #ffffff;
  border: 1px solid #d4d4d4;
  border-radius: 16px;
  padding: 24px 0;
  display: flex;
  flex-direction: column;
  gap: 24px;
  flex-shrink: 0;
}

@media (max-width: 1024px) {
  .patterns-content-layout {
    flex-direction: column;
  }
  .patterns-list-panel {
    width: 100%;
  }
}

.list-search-filter-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 24px;
}

.search-input-box {
  position: relative;
  flex: 1;
}

.search-icon {
  position: absolute;
  left: 14px;
  top: 50%;
  transform: translateY(-50%);
  color: #717680;
  pointer-events: none;
}

.search-input {
  width: 100%;
  height: 44px;
  padding: 10px 14px 10px 42px;
  background: #ffffff;
  border: 1px solid #d5d7da;
  border-radius: 8px;
  font-size: 15px;
  color: #404040;
  outline: none;
  box-shadow: 0 1px 1px rgba(10, 13, 18, 0.05);
  transition: border-color 0.15s ease;
}

.search-input::placeholder {
  color: #717680;
}

.search-input:focus {
  border-color: #0B529C;
}

.btn-filter {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 44px;
  padding: 10px 18px;
  background: #ffffff;
  border: 1px solid #d9d9d9;
  border-radius: 8px;
  font-size: 15px;
  font-weight: 600;
  color: #414651;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  transition: background-color 0.15s ease;
}

.btn-filter:hover {
  background-color: #f5f5f5;
}

/* Patterns Stack */
.patterns-cards-stack {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 0 24px;
}

.pattern-item-card {
  background: #ffffff;
  border: 1px solid #d4d4d4;
  border-radius: 12px;
  padding: 14px 18px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.pattern-item-card:hover {
  background-color: #fafafa;
}

.pattern-item-card.active {
  background-color: #fafafa;
}

.pattern-item-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.pattern-item-title-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.pattern-name {
  font-size: 16px;
  font-weight: 600;
  color: #414651;
  line-height: 24px;
}

.btn-item-more {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  color: #737373;
  cursor: pointer;
  padding: 2px;
  border-radius: 4px;
}

.btn-item-more:hover {
  color: #404040;
}

.pattern-shift-subtitle {
  font-size: 14px;
  font-weight: 400;
  color: #737373;
  line-height: 20px;
}

/* Badges */
.badge-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 2px 8px;
  border-radius: 16px;
  font-size: 12px;
  font-weight: 500;
  line-height: 18px;
}

.badge-global {
  background: #d0fae5;
  color: #007a55;
}

.badge-pending {
  background: #fef3c6;
  color: #bb4d00;
}

.badge-accepted {
  background: #f0f9ff;
  color: #0069a8;
}

/* ─── RIGHT COLUMN: DETAIL CARD (Figma Node 6106:153889 & 6447:149817) ─── */
.pattern-detail-panel {
  flex: 1;
  background: #ffffff;
  border: 1px solid #e9eaeb;
  border-radius: 16px;
  box-shadow: 0 1px 3px rgba(10, 13, 18, 0.1), 0 1px 2px rgba(10, 13, 18, 0.06);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  transition: all 0.25s ease;
}

.panel-expanded {
  width: 100%;
}

.detail-header-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 16px 24px;
  border-bottom: 1px solid #d4d4d4;
  gap: 16px;
}

.detail-title-col {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.detail-title-with-badge {
  display: flex;
  align-items: center;
  gap: 6px;
}

.detail-name {
  font-size: 16px;
  font-weight: 600;
  color: #414651;
  line-height: 24px;
  margin: 0;
}

.detail-subtitle {
  font-size: 14px;
  font-weight: 400;
  color: #737373;
  line-height: 20px;
  margin: 0;
}

.btn-toggle-focus {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  background: #ffffff;
  border: 1px solid #d5d7da;
  border-radius: 8px;
  color: #414651;
  font-size: 14px;
  font-weight: 600;
  line-height: 20px;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  cursor: pointer;
  transition: background-color 0.15s ease;
  white-space: nowrap;
}

.btn-toggle-focus:hover {
  background-color: #f5f5f5;
}

/* Metrics Strip (Figma Node 6106:153899) */
.detail-metrics-strip {
  background: #fafafa;
  border-bottom: 1px solid #e5e5e5;
  padding: 8px 24px;
  display: flex;
  align-items: center;
  gap: 12px;
}

.metric-segment {
  display: flex;
  align-items: center;
  gap: 6px;
}

.metric-num {
  font-size: 16px;
  font-weight: 600;
  color: #737373;
  line-height: 24px;
}

.metric-txt {
  font-size: 14px;
  font-weight: 400;
  color: #737373;
  line-height: 20px;
}

.metric-divider {
  width: 1px;
  height: 20px;
  background-color: #d4d4d4;
}

/* Days Schedule Container (Figma Node 6106:153915) */
.days-schedule-container {
  padding: 16px 24px 24px 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.day-schedule-card {
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  padding: 16px;
  display: flex;
  align-items: center;
  background: #ffffff;
}

.day-schedule-content {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
}

.day-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  line-height: 24px;
}

.day-time {
  font-size: 14px;
  font-weight: 400;
  color: #737373;
  line-height: 20px;
}

.day-title-rest {
  font-size: 16px;
  font-weight: 600;
  color: #737373;
  line-height: 24px;
}

.badge-unpaid-rest {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 2px 8px;
  border-radius: 16px;
  background: #f5f5f5;
  color: #414651;
  font-size: 12px;
  font-weight: 500;
  line-height: 18px;
}

/* Quick Modal */
.quick-modal-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
</style>
