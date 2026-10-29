<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Repeat, Plus, Search, Filter, ArrowUpDown, ChevronDown, 
  MoreVertical, Edit2, Trash2, Eye, Copy, Check, Calendar, 
  CheckCircle2, AlertCircle, X, Layers, ChevronRight,
  Maximize2, ArrowRight, Clock, Coffee, Shield, CalendarRange
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';

const router = useRouter();

// ─── Breadcrumbs (Rule: Exact Page Name from Sidebar Only, Zero Section Titles) ───
const breadcrumbItems = [
  { label: 'Shift Patterns' }
];

// ─── Types (HR_Schema_final-v4.sql lines 1364–1401) ───
export interface ShiftPatternDayItem {
  id: number;
  day_index: number;
  shift_id: number | null;
  shift_code?: string;
  shift_name?: string;
  start_time?: string;
  end_time?: string;
  is_rest: boolean;
}

export interface ShiftPatternRecord {
  id: number;
  uuid: string;
  code: string;
  name: string;
  description?: string;
  entity_id: number;
  entity_name: string;
  cycle_days: number;
  work_calendar_id: number;
  work_calendar_name: string;
  state: 'active' | 'inactive';
  days: ShiftPatternDayItem[];
}

// ─── Mock Data ───
const patterns = ref<ShiftPatternRecord[]>([
  {
    id: 1,
    uuid: 'pat-uuid-001',
    code: 'PAT-OFF-5D',
    name: 'Office Mon-Fri Regular',
    description: 'Standard five days on, two consecutive weekend rest days.',
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    cycle_days: 7,
    work_calendar_id: 1,
    work_calendar_name: 'Office Calendar (40h/wk)',
    state: 'active',
    days: [
      { id: 101, day_index: 1, shift_id: 1, shift_code: 'SH-OFF', shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', is_rest: false },
      { id: 102, day_index: 2, shift_id: 1, shift_code: 'SH-OFF', shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', is_rest: false },
      { id: 103, day_index: 3, shift_id: 1, shift_code: 'SH-OFF', shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', is_rest: false },
      { id: 104, day_index: 4, shift_id: 1, shift_code: 'SH-OFF', shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', is_rest: false },
      { id: 105, day_index: 5, shift_id: 1, shift_code: 'SH-OFF', shift_name: 'Office Day', start_time: '08:30', end_time: '17:30', is_rest: false },
      { id: 106, day_index: 6, shift_id: null, is_rest: true },
      { id: 107, day_index: 7, shift_id: null, is_rest: true }
    ]
  },
  {
    id: 2,
    uuid: 'pat-uuid-002',
    code: 'PAT-RETAIL-6D',
    name: 'Retail 6-Day Rota',
    description: 'Six working days with rolling Sunday rest for commercial storefronts.',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    cycle_days: 7,
    work_calendar_id: 2,
    work_calendar_name: 'Retail Calendar (48h/wk)',
    state: 'active',
    days: [
      { id: 201, day_index: 1, shift_id: 2, shift_code: 'SH-MORN', shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 202, day_index: 2, shift_id: 2, shift_code: 'SH-MORN', shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 203, day_index: 3, shift_id: 2, shift_code: 'SH-MORN', shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 204, day_index: 4, shift_id: 2, shift_code: 'SH-MORN', shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 205, day_index: 5, shift_id: 2, shift_code: 'SH-MORN', shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 206, day_index: 6, shift_id: 2, shift_code: 'SH-MORN', shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 207, day_index: 7, shift_id: null, is_rest: true }
    ]
  },
  {
    id: 3,
    uuid: 'pat-uuid-003',
    code: 'PAT-2M2E2O',
    name: '2 Morn 2 Eve 2 Off',
    description: 'High-efficiency 6-day continuous industrial rotation cycle.',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    cycle_days: 6,
    work_calendar_id: 2,
    work_calendar_name: 'Retail Calendar (48h/wk)',
    state: 'active',
    days: [
      { id: 301, day_index: 1, shift_id: 2, shift_code: 'SH-MORN', shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 302, day_index: 2, shift_id: 2, shift_code: 'SH-MORN', shift_name: 'Retail Morning', start_time: '07:00', end_time: '15:00', is_rest: false },
      { id: 303, day_index: 3, shift_id: 3, shift_code: 'SH-EVE', shift_name: 'Retail Evening', start_time: '14:30', end_time: '22:30', is_rest: false },
      { id: 304, day_index: 4, shift_id: 3, shift_code: 'SH-EVE', shift_name: 'Retail Evening', start_time: '14:30', end_time: '22:30', is_rest: false },
      { id: 305, day_index: 5, shift_id: null, is_rest: true },
      { id: 306, day_index: 6, shift_id: null, is_rest: true }
    ]
  },
  {
    id: 4,
    uuid: 'pat-uuid-004',
    code: 'PAT-GUARD-4C',
    name: 'Guard 4-Day Cycle',
    description: '12-hour alternating night guard rotation with 2 rest days.',
    entity_id: 9,
    entity_name: 'Hawassa Industrial Plant',
    cycle_days: 4,
    work_calendar_id: 1,
    work_calendar_name: 'Office Calendar (40h/wk)',
    state: 'active',
    days: [
      { id: 401, day_index: 1, shift_id: 4, shift_code: 'SH-NIGHT', shift_name: 'Night Guard', start_time: '22:00', end_time: '06:00', is_rest: false },
      { id: 402, day_index: 2, shift_id: 4, shift_code: 'SH-NIGHT', shift_name: 'Night Guard', start_time: '22:00', end_time: '06:00', is_rest: false },
      { id: 403, day_index: 3, shift_id: null, is_rest: true },
      { id: 404, day_index: 4, shift_id: null, is_rest: true }
    ]
  }
]);

// ─── State ───
const selectedPatternId = ref<number>(patterns.value[0].id);
const searchQuery = ref('');
const showQuickCreate = ref(false);
const isQuickSubmitting = ref(false);
const toastMessage = ref<string | null>(null);

const selectedPattern = computed(() => {
  return patterns.value.find(p => p.id === selectedPatternId.value) || patterns.value[0];
});

const filteredPatterns = computed(() => {
  if (!searchQuery.value) return patterns.value;
  const q = searchQuery.value.toLowerCase();
  return patterns.value.filter(p => 
    p.name.toLowerCase().includes(q) || 
    p.code.toLowerCase().includes(q) ||
    p.entity_name.toLowerCase().includes(q)
  );
});

// ─── Cycle Analytics ───
const workingDaysCount = computed(() => {
  return selectedPattern.value.days.filter(d => !d.is_rest).length;
});

const restDaysCount = computed(() => {
  return selectedPattern.value.days.filter(d => d.is_rest).length;
});

const totalCycleHours = computed(() => {
  return selectedPattern.value.days.reduce((acc, d) => {
    if (d.is_rest) return acc;
    return acc + 8.0;
  }, 0);
});

const avgWeeklyHours = computed(() => {
  const cycle = selectedPattern.value.cycle_days || 7;
  return Number(((totalCycleHours.value / cycle) * 7).toFixed(1));
});

// ─── Quick Create Form ───
const quickForm = ref({
  code: '',
  name: '',
  cycle_days: '7',
  work_calendar_id: '1',
  entity_id: ''
});

const handleOpenQuickCreate = () => {
  quickForm.value = {
    code: `PAT-${Math.floor(100 + Math.random() * 900)}`,
    name: '',
    cycle_days: '7',
    work_calendar_id: '1',
    entity_id: ''
  };
  showQuickCreate.value = true;
};

const handleExpandFullForm = () => {
  showQuickCreate.value = false;
  router.push({
    path: '/hr/shift-patterns/create',
    query: {
      code: quickForm.value.code,
      name: quickForm.value.name,
      cycle_days: quickForm.value.cycle_days,
      work_calendar_id: quickForm.value.work_calendar_id,
      entity_id: quickForm.value.entity_id
    }
  });
};

const handleSaveQuick = () => {
  if (!quickForm.value.name) return;
  isQuickSubmitting.value = true;
  setTimeout(() => {
    const cycleLen = Number(quickForm.value.cycle_days) || 7;
    const newDays: ShiftPatternDayItem[] = Array.from({ length: cycleLen }, (_, i) => {
      const idx = i + 1;
      const isWeekend = idx >= cycleLen - 1;
      return {
        id: Date.now() + i,
        day_index: idx,
        shift_id: isWeekend ? null : 1,
        shift_code: isWeekend ? undefined : 'SH-OFF',
        shift_name: isWeekend ? undefined : 'Office Day',
        start_time: isWeekend ? undefined : '08:30',
        end_time: isWeekend ? undefined : '17:30',
        is_rest: isWeekend
      };
    });

    const newRecord: ShiftPatternRecord = {
      id: Date.now(),
      uuid: `pat-uuid-${Date.now()}`,
      code: quickForm.value.code || 'PAT-NEW',
      name: quickForm.value.name,
      entity_id: Number(quickForm.value.entity_id) || 0,
      entity_name: quickForm.value.entity_id ? 'Haleta Addis Ababa HQ' : 'Platform Template (Universal)',
      cycle_days: cycleLen,
      work_calendar_id: Number(quickForm.value.work_calendar_id) || 1,
      work_calendar_name: 'Office Calendar (40h/wk)',
      state: 'active',
      days: newDays
    };

    patterns.value.unshift(newRecord);
    selectedPatternId.value = newRecord.id;
    isQuickSubmitting.value = false;
    showQuickCreate.value = false;
    toastMessage.value = `Shift Pattern "${quickForm.value.name}" created successfully.`;
    setTimeout(() => { toastMessage.value = null; }, 3500);
  }, 400);
};
</script>

<template>
  <div class="shift-patterns-page">
    <!-- Breadcrumb Standard -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Notification Toast -->
    <div v-if="toastMessage" class="action-toast">
      <CheckCircle2 :size="16" class="text-emerald-600" />
      <span>{{ toastMessage }}</span>
    </div>

    <!-- Master Header Bar -->
    <div class="patterns-top-bar">
      <div>
        <h2 class="page-title">Shift Patterns</h2>
        <p class="page-subtitle">Configure recurring rota sequences, multi-week cycles, and rest intervals across workforce divisions.</p>
      </div>
      <div class="top-actions">
        <button 
          type="button" 
          class="btn-primary-action" 
          @click="handleOpenQuickCreate"
        >
          <Plus :size="15" />
          <span>Create Pattern</span>
        </button>
      </div>
    </div>

    <!-- Master-Detail Split Grid -->
    <div class="patterns-layout-grid">
      <!-- LEFT COLUMN: PATTERNS LIST -->
      <div class="patterns-list-column">
        <div class="list-search-wrapper">
          <Search :size="15" class="search-icon" />
          <input 
            v-model="searchQuery" 
            type="text" 
            class="search-input"
            aria-label="Search patterns"
          />
        </div>

        <div class="patterns-cards-stack">
          <div 
            v-for="pat in filteredPatterns" 
            :key="pat.id"
            class="pattern-summary-card"
            :class="{ 'card-active': selectedPatternId === pat.id }"
            @click="selectedPatternId = pat.id"
          >
            <div class="card-top-row">
              <div class="icon-title-pair">
                <div class="pattern-icon-box" :class="{ 'icon-active': selectedPatternId === pat.id }">
                  <Repeat :size="16" />
                </div>
                <div>
                  <h4 class="pattern-name">{{ pat.name }}</h4>
                  <p class="pattern-code">{{ pat.code }}</p>
                </div>
              </div>
              <span class="cycle-pill">{{ pat.cycle_days }}-Day</span>
            </div>

            <!-- Mini Day Slots Strip -->
            <div class="mini-slots-strip">
              <span 
                v-for="day in pat.days" 
                :key="day.id"
                class="mini-slot-badge"
                :class="day.is_rest ? 'slot-rest' : 'slot-work'"
                :title="day.is_rest ? `Day ${day.day_index}: Rest Day` : `Day ${day.day_index}: ${day.shift_name}`"
              >
                {{ day.day_index }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- RIGHT COLUMN: DETAILED CYCLE BUILDER -->
      <div class="pattern-detail-column">
        <div class="detail-card">
          <!-- Detail Header Banner -->
          <div class="detail-header-banner">
            <div class="banner-content">
              <div class="banner-top">
                <span class="banner-code">{{ selectedPattern.code }}</span>
                <span class="banner-cycle-badge">{{ selectedPattern.cycle_days }}-Day Rota Cycle</span>
              </div>
              <h3 class="banner-title">{{ selectedPattern.name }}</h3>
              <p class="banner-desc">{{ selectedPattern.description }}</p>
              
              <div class="banner-meta-row">
                <span class="meta-item">
                  <CalendarRange :size="14" />
                  <span>{{ selectedPattern.work_calendar_name }}</span>
                </span>
                <span class="meta-item">
                  <Layers :size="14" />
                  <span>{{ selectedPattern.entity_name }}</span>
                </span>
              </div>
            </div>
          </div>

          <!-- Cycle Metrics Summary Strip -->
          <div class="cycle-metrics-bar">
            <div class="metric-item">
              <span class="m-label">Cycle Span:</span>
              <span class="m-val">{{ selectedPattern.cycle_days }} Days</span>
            </div>
            <div class="metric-divider"></div>
            <div class="metric-item">
              <span class="m-label">Active Work Days:</span>
              <span class="m-val text-blue-600">{{ workingDaysCount }} Days</span>
            </div>
            <div class="metric-divider"></div>
            <div class="metric-item">
              <span class="m-label">Rest Days:</span>
              <span class="m-val text-slate-600">{{ restDaysCount }} Days</span>
            </div>
            <div class="metric-divider"></div>
            <div class="metric-item">
              <span class="m-label">Cycle Planned Hours:</span>
              <span class="m-val">{{ totalCycleHours.toFixed(1) }} hrs</span>
            </div>
            <div class="metric-divider"></div>
            <div class="metric-item">
              <span class="m-label">Avg Weekly Load:</span>
              <span class="m-val" :class="avgWeeklyHours > 48 ? 'text-amber-600' : 'text-emerald-700'">
                {{ avgWeeklyHours }} hrs/wk
              </span>
            </div>
            <div class="metric-divider"></div>
            <div class="metric-item">
              <span class="m-label">State:</span>
              <span class="status-pill status-active">Active</span>
            </div>
          </div>

          <!-- Slots Builder Chain -->
          <div class="slots-chain-section">
            <div class="slots-header">
              <h4 class="slots-title">Cycle Slots Sequence</h4>
              <p class="slots-subtext">Day-by-day rotation schedule mapping shifts or designated rest windows.</p>
            </div>

            <div class="slots-timeline">
              <div 
                v-for="slot in selectedPattern.days" 
                :key="slot.id"
                class="slot-timeline-row"
                :class="{ 'row-rest': slot.is_rest }"
              >
                <!-- Day Index Circle -->
                <div class="day-index-box" :class="slot.is_rest ? 'index-rest' : 'index-work'">
                  <span>D{{ slot.day_index }}</span>
                </div>

                <!-- Shift Details Card -->
                <div class="slot-content-box">
                  <div class="slot-main-info">
                    <div v-if="!slot.is_rest" class="slot-shift-info">
                      <span class="shift-name-text">{{ slot.shift_name }}</span>
                      <span class="shift-timing-text">{{ slot.start_time }} – {{ slot.end_time }}</span>
                    </div>
                    <div v-else class="slot-rest-info">
                      <Coffee :size="14" class="text-slate-400" />
                      <span class="rest-title-text">Designated Rest Day (Off)</span>
                    </div>
                  </div>

                  <div class="slot-right-badge">
                    <span v-if="!slot.is_rest" class="work-badge">Working Shift</span>
                    <span v-else class="rest-badge">Unpaid Rest</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Create Modal (<= 5 Required Fields Standard) -->
    <QuickCreateModal
      :show="showQuickCreate"
      title="Create Shift Pattern"
      :is-submitting="isQuickSubmitting"
      @close="showQuickCreate = false"
      @save="handleSaveQuick"
      @expand="handleExpandFullForm"
    >
      <div class="quick-form-grid">
        <FormInput
          v-model="quickForm.name"
          label="Pattern Name"
          required
        />

        <FormInput
          v-model="quickForm.code"
          label="Pattern Code"
          required
        />

        <FormSelect
          v-model="quickForm.cycle_days"
          label="Cycle Length (Days)"
          placeholder="Select"
          :options="[
            { value: '4', label: '4-Day Cycle (e.g. 2 Work, 2 Off)' },
            { value: '6', label: '6-Day Cycle (e.g. 2 Morn, 2 Eve, 2 Off)' },
            { value: '7', label: '7-Day Weekly Cycle' },
            { value: '14', label: '14-Day Fortnightly Cycle' },
            { value: '28', label: '28-Day Monthly Cycle' }
          ]"
        />

        <FormSelect
          v-model="quickForm.work_calendar_id"
          label="Work Calendar Source"
          placeholder="Select"
          :options="[
            { value: '1', label: 'Office Calendar (CAL-OFFICE)' },
            { value: '2', label: 'Retail Calendar (CAL-RETAIL)' },
            { value: '3', label: 'Factory Continuous (CAL-FACTORY)' }
          ]"
        />

        <FormSelect
          v-model="quickForm.entity_id"
          label="Owning Entity"
          placeholder="Select"
          :options="[
            { value: '', label: 'Platform Template (Universal / All Entities)' },
            { value: '3', label: 'Haleta Addis Ababa HQ' },
            { value: '7', label: 'Bole Commercial Branch' },
            { value: '9', label: 'Hawassa Industrial Plant' }
          ]"
        />
      </div>
    </QuickCreateModal>
  </div>
</template>

<style scoped>
.shift-patterns-page {
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

/* Master Header Bar */
.patterns-top-bar {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 1.5rem;
}

.page-title {
  font-size: 20px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.page-subtitle {
  font-size: 13px;
  color: #737373;
  margin: 0;
}

.btn-primary-action {
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

.btn-primary-action:hover {
  background-color: #09427d;
}

/* Grid Layout */
.patterns-layout-grid {
  display: grid;
  grid-template-columns: 360px 1fr;
  gap: 1.5rem;
}

@media (max-width: 1024px) {
  .patterns-layout-grid {
    grid-template-columns: 1fr;
  }
}

/* Left Column */
.patterns-list-column {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.list-search-wrapper {
  position: relative;
  width: 100%;
}

.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
  pointer-events: none;
}

.search-input {
  width: 100%;
  height: 38px;
  padding: 0 12px 0 32px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  background: #ffffff;
  outline: none;
  transition: border-color 0.15s ease;
}

.search-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.patterns-cards-stack {
  display: flex;
  flex-direction: column;
  gap: 0.625rem;
}

.pattern-summary-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.pattern-summary-card:hover {
  border-color: #cbd5e1;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.pattern-summary-card.card-active {
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.15);
}

.card-top-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 0.5rem;
}

.icon-title-pair {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.pattern-icon-box {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background: #f1f5f9;
  color: #64748b;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: all 0.2s ease;
}

.pattern-icon-box.icon-active {
  background: #0B529C;
  color: #ffffff;
}

.pattern-name {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.pattern-code {
  font-size: 11.5px;
  color: #737373;
  margin: 2px 0 0 0;
}

.cycle-pill {
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 6px;
  background: #f1f5f9;
  color: #475569;
}

.mini-slots-strip {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-top: 0.75rem;
}

.mini-slot-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 600;
}

.slot-work {
  background: #e0f2fe;
  color: #0369a1;
}

.slot-rest {
  background: #f1f5f9;
  color: #94a3b8;
}

/* Right Column */
.pattern-detail-column {
  min-width: 0;
}

.detail-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.detail-header-banner {
  background: linear-gradient(135deg, #0B529C 0%, #1e3a8a 100%);
  padding: 1.5rem;
  color: #ffffff;
}

.banner-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.banner-code {
  font-size: 11.5px;
  font-weight: 600;
  letter-spacing: 0.05em;
  color: rgba(255, 255, 255, 0.8);
}

.banner-cycle-badge {
  font-size: 11.5px;
  font-weight: 600;
  padding: 3px 10px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(4px);
}

.banner-title {
  font-size: 18px;
  font-weight: 600;
  margin: 0.5rem 0 0.25rem 0;
  color: #ffffff;
}

.banner-desc {
  font-size: 12.5px;
  color: rgba(255, 255, 255, 0.85);
  margin: 0 0 1rem 0;
  line-height: 1.4;
}

.banner-meta-row {
  display: flex;
  flex-wrap: wrap;
  gap: 1.25rem;
  font-size: 12.5px;
  color: rgba(255, 255, 255, 0.9);
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

/* Metrics Bar */
.cycle-metrics-bar {
  display: flex;
  align-items: center;
  padding: 0.875rem 1.5rem;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  gap: 1.25rem;
  flex-wrap: wrap;
}

.metric-item {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  font-size: 12.5px;
}

.m-label {
  color: #737373;
}

.m-val {
  font-weight: 600;
  color: #404040;
}

.metric-divider {
  width: 1px;
  height: 16px;
  background: #cbd5e1;
}

.status-pill {
  display: inline-block;
  padding: 2px 8px;
  font-size: 11px;
  font-weight: 500;
  border-radius: 9999px;
}

.status-active {
  background-color: #ecfdf5;
  color: #059669;
}

/* Slots Chain */
.slots-chain-section {
  padding: 1.5rem;
}

.slots-header {
  margin-bottom: 1.25rem;
}

.slots-title {
  font-size: 14.5px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 2px 0;
}

.slots-subtext {
  font-size: 12px;
  color: #737373;
  margin: 0;
}

.slots-timeline {
  display: flex;
  flex-direction: column;
  gap: 0.625rem;
}

.slot-timeline-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.75rem 1rem;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
  transition: all 0.15s ease;
}

.slot-timeline-row:hover {
  border-color: #cbd5e1;
  background: #fafafa;
}

.slot-timeline-row.row-rest {
  background: #f8fafc;
}

.day-index-box {
  width: 34px;
  height: 34px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 700;
  flex-shrink: 0;
}

.index-work {
  background: #e0f2fe;
  color: #0284c7;
}

.index-rest {
  background: #f1f5f9;
  color: #94a3b8;
}

.slot-content-box {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.slot-shift-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.shift-name-text {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
}

.shift-timing-text {
  font-size: 12px;
  color: #737373;
}

.slot-rest-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.rest-title-text {
  font-size: 13px;
  font-weight: 500;
  color: #737373;
}

.work-badge {
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 4px;
  background: #ecfdf5;
  color: #059669;
}

.rest-badge {
  font-size: 11px;
  font-weight: 500;
  padding: 2px 8px;
  border-radius: 4px;
  background: #f1f5f9;
  color: #64748b;
}

/* Quick Modal */
.quick-form-grid {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
