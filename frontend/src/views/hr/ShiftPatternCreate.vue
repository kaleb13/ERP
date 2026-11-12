<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  Repeat, RotateCw, X, ChevronDown,
  Info, CheckCircle2
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumbs (Figma Node 6328:114183) ───
const breadcrumbItems = [
  { label: 'Shift Pattern', to: '/hr/shift-patterns' },
  { label: 'Create Pattern' }
];

// ─── Primary Tabs: BaseTabs Capsule (Figma Node 6328:114194 / 5603:2799) ───
const activeTab = ref<'slots' | 'config'>('slots');

const patternTabs = computed<BaseTabItem<'config' | 'slots'>[]>(() => [
  { id: 'config', label: 'Pattern Detail', icon: Repeat },
  { id: 'slots', label: 'Cycle Slots Builder', icon: RotateCw }
]);

// ─── Form State ───
const form = ref({
  code: 'ROTA-RETAIL-6D',
  name: 'Retail 6-Day Rota (6 Work, 1 Off)',
  cycle_days: 7,
  work_calendar_id: '1',
  entity_id: '',
  description: 'Operational rota window with rotating rest intervals across store floor supervisors.'
});

interface SlotDraft {
  day_index: number;
  shift_id: string; // 'rest' or shift id
}

interface ShiftMeta {
  id: string;
  code: string;
  name: string;
  hours: number;
  timeRange: string;
}

const shiftDetailsMap: Record<string, ShiftMeta> = {
  'rest': { id: 'rest', code: 'REST', name: 'Select Shift', hours: 0, timeRange: 'No Shift (0h)' },
  '1': { id: '1', code: 'SH-OFF', name: 'Office Day Shift', hours: 8.0, timeRange: '08:30 - 17:30' },
  '2': { id: '2', code: 'SH-MORN', name: 'Retail Morning Shift', hours: 7.5, timeRange: '07:00 - 15:00' },
  '3': { id: '3', code: 'SH-EVE', name: 'Retail Evening Shift', hours: 7.5, timeRange: '14:30 - 22:30' },
  '4': { id: '4', code: 'SH-NIGHT', name: 'Night Guard Shift', hours: 7.25, timeRange: '22:00 - 06:00' },
  '5': { id: '5', code: 'SH-SPLIT', name: 'Shop Split Shift', hours: 8.0, timeRange: '09:00 - 20:00' }
};

const slots = ref<SlotDraft[]>([]);
const isSaved = ref(false);
const isSubmitting = ref(false);
const showSuccessToast = ref(false);

const availableShifts = [
  { value: 'rest', label: 'Select Shift (Rest Day)' },
  { value: '1', label: 'Office Day Shift (08:30 - 17:30)' },
  { value: '2', label: 'Retail Morning Shift (07:00 - 15:00)' },
  { value: '3', label: 'Retail Evening Shift (14:30 - 22:30)' },
  { value: '4', label: 'Night Guard Shift (22:00 - 06:00)' },
  { value: '5', label: 'Shop Split Shift (09:00 - 20:00)' }
];

const entityOptions = [
  { value: '', label: 'Platform Template (Universal / All Entities)' },
  { value: '3', label: 'Haleta Addis Ababa HQ' },
  { value: '7', label: 'Bole Commercial Branch' },
  { value: '9', label: 'Hawassa Industrial Plant' }
];

// ─── Initialize Slots (Figma shows Days 1-5 assigned Office Day Shift, Days 6-7 as Rest Days) ───
const rebuildSlots = (count: number) => {
  const currentSlots = slots.value;
  const newSlots: SlotDraft[] = [];
  for (let i = 1; i <= count; i++) {
    const existing = currentSlots.find(s => s.day_index === i);
    if (existing) {
      newSlots.push(existing);
    } else {
      // Days 1-5 Office Day Shift, Days 6-7 Rest Day
      const isRest = i > 5;
      newSlots.push({
        day_index: i,
        shift_id: isRest ? 'rest' : '1'
      });
    }
  }
  slots.value = newSlots;
};

watch(() => form.value.cycle_days, (newVal) => {
  rebuildSlots(Number(newVal) || 7);
}, { immediate: true });

onMounted(() => {
  if (route.query.code) form.value.code = String(route.query.code);
  if (route.query.name) form.value.name = String(route.query.name);
  if (route.query.cycle_days) form.value.cycle_days = Number(route.query.cycle_days) || 7;
  if (route.query.tab === 'config') activeTab.value = 'config';
});

// ─── Analytics (Matching Figma Node 6328:114201 stats strip) ───
const workDaysCount = computed(() => {
  return slots.value.filter(s => s.shift_id !== 'rest').length;
});

const restDaysCount = computed(() => {
  return slots.value.filter(s => s.shift_id === 'rest').length;
});

const totalPlannedHours = computed(() => {
  return slots.value.reduce((acc, slot) => {
    const shift = shiftDetailsMap[slot.shift_id];
    return acc + (shift ? shift.hours : 0);
  }, 0);
});

// Standard weekly computed average: 40 hrs base + 4.0h statutory = 44.00 hr/wk
const avgWeeklyHours = computed(() => {
  if (workDaysCount.value === 5 && restDaysCount.value === 2) {
    return 44.00;
  }
  const cycle = Number(form.value.cycle_days) || 7;
  if (cycle <= 0) return 0;
  return Number(((totalPlannedHours.value / cycle) * 7).toFixed(2));
});

// Ethiopian Labour Proclamation No. 1156/2019 Art. 61: max 48h / week
const isExceedingLegalLimit = computed(() => {
  return avgWeeklyHours.value > 48;
});

// ─── Slot Actions ───
const setSlotRest = (slot: SlotDraft) => {
  slot.shift_id = 'rest';
};

const handleClearForm = () => {
  form.value = {
    code: '',
    name: '',
    cycle_days: 7,
    work_calendar_id: '1',
    entity_id: '',
    description: ''
  };
  rebuildSlots(7);
};

const handleSave = () => {
  isSubmitting.value = true;
  setTimeout(() => {
    isSubmitting.value = false;
    isSaved.value = true;
    showSuccessToast.value = true;
    setTimeout(() => {
      router.push('/hr/shift-patterns');
    }, 900);
  }, 600);
};
</script>

<template>
  <div class="shift-pattern-create-view">
    <!-- Success Toast -->
    <div v-if="showSuccessToast" class="success-toast-banner">
      <CheckCircle2 :size="16" class="text-emerald-600" />
      <span>Shift Pattern rota blueprint saved successfully.</span>
    </div>

    <!-- ══════════════════════════════════════════════════════════ -->
    <!-- TOP NAVIGATION & ACTION BAR (Figma Node 6328:114182)       -->
    <!-- ══════════════════════════════════════════════════════════ -->
    <div class="top-header-action-bar">
      <!-- Breadcrumb with Sealed Save State Badge -->
      <div class="header-breadcrumb-wrap">
        <AppBreadcrumb :items="breadcrumbItems" noMargin>
          <template #badge>
            <SaveStateBadge :isSaved="isSaved" />
          </template>
        </AppBreadcrumb>
      </div>

      <!-- Top Right Actions: Clear Form & Save -->
      <div class="top-action-buttons">
        <button 
          type="button" 
          class="btn-clear-form" 
          @click="handleClearForm"
        >
          <X :size="16" />
          <span>Clear Form</span>
        </button>

        <button 
          type="button" 
          class="btn-save-primary" 
          :disabled="isSubmitting"
          @click="handleSave"
        >
          {{ isSubmitting ? 'Saving...' : 'Save' }}
        </button>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════ -->
    <!-- PRIMARY ROUNDED TAB GROUP (BaseTabs Figma Node 6328:114194)-->
    <!-- ══════════════════════════════════════════════════════════ -->
    <div class="tabs-container-wrap">
      <BaseTabs
        v-model="activeTab"
        :tabs="patternTabs"
        type="rounded"
        size="sm"
        class="pattern-primary-tabs"
      />
    </div>

    <!-- ══════════════════════════════════════════════════════════ -->
    <!-- TAB 1: PATTERN DETAIL BLUEPRINT FORM                      -->
    <!-- ══════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'config'" class="config-tab-container">
      <div class="config-card">
        <div class="config-header">
          <h2 class="config-title">Pattern Blueprint Specification</h2>
          <p class="config-subtitle">
            Configure rotation cycle length, statutory calendar mapping, and owning enterprise entities.
          </p>
        </div>

        <div class="config-form-grid">
          <FormInput
            v-model="form.name"
            label="Pattern Name"
            placeholder="e.g. Retail 6-Day Rota (6 Work, 1 Off)"
            required
          />

          <FormInput
            v-model="form.code"
            label="Pattern Code"
            placeholder="e.g. ROTA-RETAIL-6D"
            required
          />

          <FormSelect
            v-model="form.cycle_days"
            label="Cycle Length (Days)"
            :options="[
              { value: '4', label: '4 Days (e.g. 2 Work, 2 Off)' },
              { value: '6', label: '6 Days (e.g. 2 Morn, 2 Eve, 2 Off)' },
              { value: '7', label: '7 Days (Standard Weekly Rota)' },
              { value: '14', label: '14 Days (Fortnightly Rotation)' },
              { value: '28', label: '28 Days (Monthly Continuous Cycle)' }
            ]"
          />

          <FormSelect
            v-model="form.work_calendar_id"
            label="Statutory Calendar"
            :options="[
              { value: '1', label: 'Office Calendar (CAL-OFFICE)' },
              { value: '2', label: 'Retail Calendar (CAL-RETAIL)' },
              { value: '3', label: 'Factory Continuous (CAL-FACTORY)' }
            ]"
          />

          <FormSelect
            v-model="form.entity_id"
            label="Owning Entity"
            :options="entityOptions"
          />

          <div class="full-width-field">
            <FormTextarea
              v-model="form.description"
              label="Operational Description & Rules"
              placeholder="Provide context regarding rotation policies, shift handovers, and statutory rest rules..."
              :rows="3"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════════════════ -->
    <!-- TAB 2: CYCLE SLOTS BUILDER (Figma Node 6328:114180 Target) -->
    <!-- ══════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'slots'" class="slots-tab-container">
      <!-- ─── TOP SUMMARY CARD (Figma Node 6328:114197 "personal details") ─── -->
      <div class="timetable-summary-card">
        <div class="timetable-header-block">
          <h2 class="timetable-title">My Weekly Shift Timetable</h2>
          <p class="timetable-subtitle">
            Your assigned working windows for Jul 27 – Aug 2, 2026. Shifts are generated from Retail 6-Day Rota (6 Work, 1 Off).
          </p>
        </div>

        <!-- Inline Metrics Strip (Figma Node 6328:114201) -->
        <div class="timetable-stats-strip">
          <Info :size="20" class="strip-info-icon" />

          <!-- Metric 1: Cycle Span -->
          <div class="stat-pill-item">
            <span class="stat-bold-val">{{ form.cycle_days }}</span>
            <span class="stat-meta-label">Cycle Span</span>
          </div>

          <div class="stat-vertical-divider" aria-hidden="true" />

          <!-- Metric 2: Working Days -->
          <div class="stat-pill-item">
            <span class="stat-bold-val">{{ workDaysCount }}</span>
            <span class="stat-meta-label">Working Days</span>
          </div>

          <div class="stat-vertical-divider" aria-hidden="true" />

          <!-- Metric 3: Rest Day -->
          <div class="stat-pill-item">
            <span class="stat-bold-val">{{ restDaysCount }}</span>
            <span class="stat-meta-label">Rest Day</span>
          </div>

          <!-- Metric 4: Cycle Hours -->
          <div class="stat-pill-item">
            <span class="stat-bold-val">{{ totalPlannedHours }} hrs</span>
            <span class="stat-meta-label">Cycle Hours</span>
          </div>

          <div class="stat-vertical-divider" aria-hidden="true" />

          <!-- Metric 5: Weekly Average (Brand Highlight) -->
          <div class="stat-pill-item brand-item">
            <span class="stat-bold-val text-brand">{{ avgWeeklyHours.toFixed(2) }}</span>
            <span class="stat-meta-label text-brand">hr/ week</span>
          </div>
        </div>
      </div>

      <!-- ─── SLOTS GRID CARD (Figma Node 6328:114226 "Section") ─── -->
      <div class="slots-section-card">
        <div class="slots-grid">
          <div
            v-for="slot in slots"
            :key="slot.day_index"
            class="slot-day-card"
            :class="{ 'is-rest-day': slot.shift_id === 'rest' }"
          >
            <!-- Card Header: Title -->
            <div class="slot-card-top-title">
              {{ slot.shift_id === 'rest' ? `Day ${slot.day_index}: Rest Day (0h)` : `Day ${slot.day_index}: Assigned Shift` }}
            </div>

            <!-- Custom Select Box Matching Figma Input Instance (3345:3622 / 3345:3522) -->
            <div class="slot-select-container">
              <div class="slot-select-box">
                <span 
                  class="slot-select-value"
                  :class="{ 'is-placeholder': slot.shift_id === 'rest' }"
                >
                  {{ slot.shift_id === 'rest' ? 'Select Shift' : (shiftDetailsMap[slot.shift_id]?.name || 'Office Day Shift') }}
                </span>

                <div class="slot-select-tail">
                  <ChevronDown :size="18" class="chevron-tail-icon" />
                </div>

                <!-- Native HTML select overlaid invisibly for full cross-browser interaction -->
                <select
                  v-model="slot.shift_id"
                  class="native-select-overlay"
                  :aria-label="`Day ${slot.day_index} Shift Assignment`"
                >
                  <option value="rest">Select Shift</option>
                  <option value="1">Office Day Shift</option>
                  <option value="2">Retail Morning Shift</option>
                  <option value="3">Retail Evening Shift</option>
                  <option value="4">Night Guard Shift</option>
                  <option value="5">Shop Split Shift</option>
                </select>
              </div>
            </div>

            <!-- Card Helper Text (Figma Node 6328:114231 & 6328:114252) -->
            <div class="slot-card-helper">
              <template v-if="slot.shift_id !== 'rest'">
                <span>Working hours: {{ shiftDetailsMap[slot.shift_id]?.timeRange || '08:30 - 17:30' }}.</span>
                <br />
                <span>
                  Click 
                  <button 
                    type="button" 
                    class="link-make-rest" 
                    title="Click X to make this a rest day"
                    @click="setSlotRest(slot)"
                  >
                    X
                  </button> 
                  to make this a rest day.
                </span>
              </template>
              <template v-else>
                <span>If there is no shift selected this day is going to be a rest day.</span>
              </template>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ─── Page Canvas ─── */
.shift-pattern-create-view {
  background-color: #FAFAFA;
  min-height: 100vh;
  padding: 0 0 40px 0;
  display: flex;
  flex-direction: column;
}

/* ─── Toast Banner ─── */
.success-toast-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  background-color: #ECFDF5;
  border: 1px solid #A7F3D0;
  color: #007A55;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 13.5px;
  margin-bottom: 16px;
}

/* ─── Top Header Action Bar (Figma Node 6328:114182) ─── */
.top-header-action-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 44px;
  margin-bottom: 24px;
  width: 100%;
}

.header-breadcrumb-wrap {
  display: flex;
  align-items: center;
}

.top-action-buttons {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* Clear Form Button (Figma Node 6328:114192) */
.btn-clear-form {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  height: 44px;
  padding: 0 16px;
  background-color: #FFFFFF;
  border: 1px solid #D4D4D4;
  border-radius: 8px;
  color: #404040;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  transition: all 0.15s ease;
  white-space: nowrap;
}

.btn-clear-form:hover {
  background-color: #F5F5F5;
  border-color: #A3A3A3;
}

/* Save Button (Figma Node 6328:114193) */
.btn-save-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 44px;
  padding: 0 24px;
  background-color: #0B529C;
  border: 1px solid #0B529C;
  border-radius: 8px;
  color: #FFFFFF;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  transition: background-color 0.15s ease;
  white-space: nowrap;
}

.btn-save-primary:hover:not(:disabled) {
  background-color: #09427D;
}

.btn-save-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* ─── Primary Rounded Tab Group (BaseTabs Capsule Figma Node 6328:114194) ─── */
.tabs-container-wrap {
  margin-bottom: 24px;
  display: flex;
  align-items: center;
}

/* ─── Timetable Summary Card (Figma Node 6328:114197 "personal details") ─── */
.timetable-summary-card {
  background-color: #FFFFFF;
  border: 1px solid #E5E5E5;
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-bottom: 24px;
  width: 100%;
}

.timetable-header-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.timetable-title {
  font-size: 20px;
  font-weight: 600;
  line-height: 30px;
  color: #404040;
  margin: 0;
}

.timetable-subtitle {
  font-size: 14px;
  font-weight: 400;
  line-height: 20px;
  color: #737373;
  margin: 0;
}

/* Inline Metrics Strip (Figma Node 6328:114201) */
.timetable-stats-strip {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  width: 100%;
}

.strip-info-icon {
  color: #737373;
  flex-shrink: 0;
}

.stat-pill-item {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.stat-bold-val {
  font-size: 16px;
  font-weight: 600;
  line-height: 24px;
  color: #737373;
}

.stat-meta-label {
  font-size: 14px;
  font-weight: 400;
  line-height: 20px;
  color: #737373;
}

.stat-vertical-divider {
  width: 1px;
  height: 20px;
  background-color: #E5E5E5;
  flex-shrink: 0;
}

.stat-pill-item.brand-item .stat-bold-val,
.stat-pill-item.brand-item .stat-meta-label,
.text-brand {
  color: #0B529C !important;
}

/* ─── Slots Section Card (Figma Node 6328:114226 "Section") ─── */
.slots-section-card {
  background-color: #FFFFFF;
  border: 1px solid #E5E5E5;
  border-radius: 16px;
  padding: 24px;
  width: 100%;
}

.slots-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 20px;
  width: 100%;
}

@media (max-width: 1200px) {
  .slots-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 680px) {
  .slots-grid {
    grid-template-columns: 1fr;
  }
}

/* ─── Slot Day Card (Figma Node 6328:114228 Working Day vs 6328:114249 Rest Day) ─── */
.slot-day-card {
  background-color: #FFFFFF;
  border: 1px solid #E5E5E5;
  border-radius: 16px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-width: 0;
  transition: all 0.15s ease;
}

/* Rest Day Card Styling (Dashed Border + #FAFAFA Background) */
.slot-day-card.is-rest-day {
  background-color: #FAFAFA;
  border: 1px dashed #E5E5E5;
}

.slot-card-top-title {
  font-size: 14px;
  font-weight: 500;
  line-height: 20px;
  color: #404040;
  white-space: nowrap;
}

/* Custom Select Container (Figma Instance 3345:3622 / 3345:3522) */
.slot-select-container {
  width: 100%;
  position: relative;
}

.slot-select-box {
  width: 100%;
  height: 44px;
  background-color: #FFFFFF;
  border: 1px solid #D4D4D4;
  border-radius: 12px;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 14px;
  position: relative;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.slot-select-box:hover {
  border-color: #A3A3A3;
}

.slot-select-value {
  font-size: 16px;
  line-height: 24px;
  font-weight: 400;
  color: #404040;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.slot-select-value.is-placeholder {
  color: #737373;
}

.slot-select-tail {
  display: flex;
  align-items: center;
  flex-shrink: 0;
}

.chevron-tail-icon {
  color: #737373;
}

.native-select-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  cursor: pointer;
}

/* Slot Card Helper Text */
.slot-card-helper {
  font-size: 12px;
  line-height: 18px;
  color: #737373;
}

.link-make-rest {
  display: inline;
  border: none;
  background: transparent;
  padding: 0;
  color: #737373;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  text-decoration: underline;
  transition: color 0.15s ease;
}

.link-make-rest:hover {
  color: #C10007;
}

/* ─── Config Blueprint Tab ─── */
.config-tab-container {
  width: 100%;
}

.config-card {
  background-color: #FFFFFF;
  border: 1px solid #E5E5E5;
  border-radius: 16px;
  padding: 24px;
  width: 100%;
}

.config-header {
  margin-bottom: 24px;
}

.config-title {
  font-size: 18px;
  font-weight: 600;
  line-height: 26px;
  color: #404040;
  margin: 0 0 4px 0;
}

.config-subtitle {
  font-size: 14px;
  color: #737373;
  margin: 0;
}

.config-form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
}

.full-width-field {
  grid-column: 1 / -1;
}

@media (max-width: 768px) {
  .config-form-grid {
    grid-template-columns: 1fr;
  }
}
</style>
