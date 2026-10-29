<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  Repeat, ArrowLeft, Save, X, RotateCcw, CheckCircle2,
  Calendar, Layers, Clock, Coffee, Plus, Trash2, Info,
  AlertTriangle, Sparkles, Wand2
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import BaseTabs from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import FormTextarea from '../../components/FormTextarea.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';

const router = useRouter();
const route = useRoute();

// ─── Breadcrumbs ───
const breadcrumbItems = [
  { label: 'Shift Patterns', to: '/hr/shift-patterns' },
  { label: 'Create Shift Pattern' }
];

// ─── Tabs ───
const activeTab = ref('config');
const formTabs = computed(() => [
  { id: 'config', label: 'Pattern Blueprint' },
  { id: 'slots', label: `Cycle Slots Builder (${form.value.cycle_days} Days)` }
]);

// ─── Form State ───
const form = ref({
  code: '',
  name: '',
  cycle_days: 7,
  work_calendar_id: '1',
  entity_id: '',
  description: ''
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
  time: string;
}

const shiftDetailsMap: Record<string, ShiftMeta> = {
  'rest': { id: 'rest', code: 'REST', name: 'Rest / Off Day', hours: 0, time: 'No Shift (0h)' },
  '1': { id: '1', code: 'SH-OFF', name: 'Office Day', hours: 8.0, time: '08:30 – 17:30 (8.0h)' },
  '2': { id: '2', code: 'SH-MORN', name: 'Retail Morning', hours: 7.5, time: '07:00 – 15:00 (7.5h)' },
  '3': { id: '3', code: 'SH-EVE', name: 'Retail Evening', hours: 7.5, time: '14:30 – 22:30 (7.5h)' },
  '4': { id: '4', code: 'SH-NIGHT', name: 'Night Guard', hours: 7.25, time: '22:00 – 06:00 (7.25h)' },
  '5': { id: '5', code: 'SH-SPLIT', name: 'Shop Split', hours: 8.0, time: '09:00 – 20:00 (8.0h)' }
};

const slots = ref<SlotDraft[]>([]);
const isSaved = ref(false);
const isSubmitting = ref(false);

const availableShifts = [
  { value: 'rest', label: 'Rest / Off Day (0h)' },
  { value: '1', label: 'SH-OFF — Office Day (08:30–17:30, 8.00h)' },
  { value: '2', label: 'SH-MORN — Retail Morning (07:00–15:00, 7.50h)' },
  { value: '3', label: 'SH-EVE — Retail Evening (14:30–22:30, 7.50h)' },
  { value: '4', label: 'SH-NIGHT — Night Guard (22:00–06:00, 7.25h)' },
  { value: '5', label: 'SH-SPLIT — Shop Split (09:00–20:00, 8.00h)' }
];

const entityOptions = [
  { value: '', label: 'Platform Template (Universal / All Entities)' },
  { value: '3', label: 'Haleta Addis Ababa HQ' },
  { value: '7', label: 'Bole Commercial Branch' },
  { value: '9', label: 'Hawassa Industrial Plant' }
];

// ─── Initialize slots based on cycle_days ───
const rebuildSlots = (count: number) => {
  const currentSlots = slots.value;
  const newSlots: SlotDraft[] = [];
  for (let i = 1; i <= count; i++) {
    const existing = currentSlots.find(s => s.day_index === i);
    if (existing) {
      newSlots.push(existing);
    } else {
      // Default rest on last 1-2 days
      const isWeekend = i >= count - (count >= 6 ? 1 : 0);
      newSlots.push({
        day_index: i,
        shift_id: isWeekend ? 'rest' : '1'
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
  if (route.query.cycle_days) {
    form.value.cycle_days = Number(route.query.cycle_days) || 7;
  }
  if (route.query.work_calendar_id) {
    form.value.work_calendar_id = String(route.query.work_calendar_id);
  }
  if (route.query.entity_id !== undefined) {
    form.value.entity_id = String(route.query.entity_id);
  }
});

// ─── Analytics ───
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

const avgWeeklyHours = computed(() => {
  const cycle = Number(form.value.cycle_days) || 7;
  if (cycle <= 0) return 0;
  const weekly = (totalPlannedHours.value / cycle) * 7;
  return Number(weekly.toFixed(1));
});

// Ethiopian Labour Proclamation No. 1156/2019 Art. 61: max 48h / week
const isExceedingLegalLimit = computed(() => {
  return avgWeeklyHours.value > 48;
});

// ─── Fast Preset Handlers ───
const applyPreset = (presetKey: string) => {
  if (presetKey === 'office') {
    slots.value.forEach((s, idx) => {
      const dayMod = idx % 7;
      s.shift_id = (dayMod < 5) ? '1' : 'rest';
    });
  } else if (presetKey === 'retail-6') {
    slots.value.forEach((s, idx) => {
      const dayMod = idx % 7;
      s.shift_id = (dayMod < 6) ? '2' : 'rest';
    });
  } else if (presetKey === 'continuous-222') {
    slots.value.forEach((s, idx) => {
      const mod6 = idx % 6;
      if (mod6 < 2) s.shift_id = '2'; // Morn
      else if (mod6 < 4) s.shift_id = '3'; // Eve
      else s.shift_id = 'rest'; // Off
    });
  } else if (presetKey === 'all-rest') {
    slots.value.forEach(s => s.shift_id = 'rest');
  } else if (presetKey === 'all-office') {
    slots.value.forEach(s => s.shift_id = '1');
  }
};

const toggleSlotRest = (slot: SlotDraft) => {
  if (slot.shift_id === 'rest') {
    slot.shift_id = '1';
  } else {
    slot.shift_id = 'rest';
  }
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
  if (!form.value.name || !form.value.code) return;
  isSubmitting.value = true;
  setTimeout(() => {
    isSubmitting.value = false;
    isSaved.value = true;
    setTimeout(() => {
      router.push('/hr/shift-patterns');
    }, 800);
  }, 500);
};
</script>

<template>
  <div class="pattern-create-page">
    <!-- Top Nav Bar -->
    <div class="top-nav-bar">
      <div class="left-section">
        <AppBreadcrumb :items="breadcrumbItems" />
        <SaveStateBadge :is-saved="isSaved" />
      </div>

      <div class="right-actions">
        <button 
          type="button" 
          class="btn-secondary-action" 
          @click="handleClearForm"
        >
          <X :size="15" />
          <span>Clear Form</span>
        </button>

        <button 
          type="button" 
          class="btn-primary-action" 
          :disabled="isSubmitting"
          @click="handleSave"
        >
          <Save :size="15" />
          <span>{{ isSubmitting ? 'Saving...' : 'Save Pattern' }}</span>
        </button>
      </div>
    </div>

    <!-- Tabs -->
    <div class="tabs-wrapper">
      <BaseTabs 
        v-model="activeTab" 
        :tabs="formTabs" 
      />
    </div>

    <!-- Form Content Container -->
    <div class="creation-content-container">
      <div class="clean-card">
        <!-- TAB 1: DETAILS -->
        <div v-show="activeTab === 'config'" class="tab-pane">
          <div class="section-header-block">
            <h3 class="section-title">Pattern Blueprint</h3>
            <p class="section-desc">Specify repeating cycle duration, linked statutory work calendar, and organizational ownership.</p>
          </div>

          <div class="form-grid-2">
            <FormInput
              v-model="form.name"
              label="Pattern Name"
              required
            />

            <FormInput
              v-model="form.code"
              label="Pattern Code"
              required
            />
          </div>

          <div class="form-grid-3 mt-4">
            <FormSelect
              v-model="form.cycle_days"
              label="Cycle Length (Days)"
              placeholder="Select"
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
              label="Source Work Calendar"
              placeholder="Select"
              :options="[
                { value: '1', label: 'Office Calendar (CAL-OFFICE)' },
                { value: '2', label: 'Retail Calendar (CAL-RETAIL)' },
                { value: '3', label: 'Factory Continuous (CAL-FACTORY)' }
              ]"
            />

            <FormSelect
              v-model="form.entity_id"
              label="Owning Entity"
              placeholder="Select"
              :options="entityOptions"
            />
          </div>

          <div class="mt-6">
            <FormTextarea
              v-model="form.description"
              label="Operational Description & Rules"
              :rows="3"
            />
          </div>
        </div>

        <!-- TAB 2: SLOTS BUILDER -->
        <div v-show="activeTab === 'slots'" class="tab-pane">
          <!-- Section Header & Live Analytics -->
          <div class="section-header-block">
            <div class="slots-header-layout">
              <div>
                <h3 class="section-title">Day-by-Day Rotation Slots</h3>
                <p class="section-desc">Assign specific shifts or rest days to each consecutive day slot in the {{ form.cycle_days }}-day repeating cycle.</p>
              </div>

              <!-- Rota Analytics Bar -->
              <div class="rota-analytics-bar">
                <div class="analytics-stat">
                  <span class="stat-label">Cycle Span</span>
                  <span class="stat-val">{{ form.cycle_days }} Days</span>
                </div>
                <div class="stat-sep"></div>
                <div class="analytics-stat">
                  <span class="stat-label">Working Days</span>
                  <span class="stat-val text-blue-700">{{ workDaysCount }}</span>
                </div>
                <div class="stat-sep"></div>
                <div class="analytics-stat">
                  <span class="stat-label">Rest Days</span>
                  <span class="stat-val text-slate-600">{{ restDaysCount }}</span>
                </div>
                <div class="stat-sep"></div>
                <div class="analytics-stat">
                  <span class="stat-label">Cycle Hours</span>
                  <span class="stat-val">{{ totalPlannedHours }} hrs</span>
                </div>
                <div class="stat-sep"></div>
                <div class="analytics-stat">
                  <span class="stat-label">Weekly Average</span>
                  <span class="stat-val" :class="isExceedingLegalLimit ? 'text-amber-600 font-bold' : 'text-emerald-700'">
                    {{ avgWeeklyHours }} hrs/wk
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Statutory Workload Alert (Ethiopian Labour Proclamation No. 1156/2019 Art. 61) -->
          <div v-if="isExceedingLegalLimit" class="statutory-alert-banner">
            <AlertTriangle :size="18" class="text-amber-600 flex-shrink-0" />
            <div class="alert-content">
              <strong>Statutory Workload Warning:</strong>
              Average load is <strong>{{ avgWeeklyHours }} hrs/week</strong>, which exceeds the statutory maximum of <strong>48 hours/week</strong> stipulated under Ethiopian Labour Proclamation No. 1156/2019 (Art. 61). Regular overtime or compensatory rest approval will be required.
            </div>
          </div>

          <!-- Quick Presets Toolbar -->
          <div class="presets-toolbar">
            <div class="presets-label">
              <Sparkles :size="14" class="text-blue-600" />
              <span>Quick Presets:</span>
            </div>
            <div class="presets-buttons">
              <button 
                type="button" 
                class="btn-preset-pill" 
                @click="applyPreset('office')"
              >
                5-Day Office (5 Work, 2 Off)
              </button>
              <button 
                type="button" 
                class="btn-preset-pill" 
                @click="applyPreset('retail-6')"
              >
                6-Day Retail (6 Work, 1 Off)
              </button>
              <button 
                type="button" 
                class="btn-preset-pill" 
                @click="applyPreset('continuous-222')"
              >
                Continuous 2-2-2 (2 Morn, 2 Eve, 2 Off)
              </button>
              <button 
                type="button" 
                class="btn-preset-pill-muted" 
                @click="applyPreset('all-rest')"
              >
                Set All to Rest
              </button>
            </div>
          </div>

          <!-- Slot Matrix Card Grid -->
          <div class="slot-matrix-grid">
            <div 
              v-for="slot in slots" 
              :key="slot.day_index"
              class="slot-matrix-card"
              :class="{ 'card-is-rest': slot.shift_id === 'rest' }"
            >
              <!-- Card Top: Day Indicator + Fast Rest Toggle -->
              <div class="slot-card-header">
                <div class="day-number-pill" :class="slot.shift_id === 'rest' ? 'pill-rest' : 'pill-work'">
                  <span>Day {{ slot.day_index }}</span>
                </div>
                
                <button 
                  type="button" 
                  class="btn-card-toggle"
                  :title="slot.shift_id === 'rest' ? 'Assign working shift' : 'Set as rest day'"
                  @click="toggleSlotRest(slot)"
                >
                  <Coffee v-if="slot.shift_id !== 'rest'" :size="13" />
                  <Clock v-else :size="13" />
                  <span>{{ slot.shift_id === 'rest' ? 'Set Shift' : 'Rest' }}</span>
                </button>
              </div>

              <!-- Card Body: Shift Select -->
              <div class="slot-card-body">
                <label class="slot-field-label">Assigned Shift</label>
                <select 
                  v-model="slot.shift_id" 
                  class="slot-native-select"
                  :aria-label="`Day ${slot.day_index} Shift`"
                >
                  <option 
                    v-for="opt in availableShifts" 
                    :key="opt.value" 
                    :value="opt.value"
                  >
                    {{ opt.label }}
                  </option>
                </select>
              </div>

              <!-- Card Footer: Live Shift Hours & Timing -->
              <div class="slot-card-footer">
                <div v-if="slot.shift_id !== 'rest'" class="timing-strip work-strip">
                  <Clock :size="12" class="text-blue-600 flex-shrink-0" />
                  <span class="timing-text">{{ shiftDetailsMap[slot.shift_id]?.time || 'Scheduled Shift' }}</span>
                </div>
                <div v-else class="timing-strip rest-strip">
                  <Coffee :size="12" class="text-slate-400 flex-shrink-0" />
                  <span class="timing-text">Unpaid Rest Day (0h)</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.pattern-create-page {
  padding: 1.25rem 2rem 3rem 2rem;
  background-color: #f8fafc;
  min-height: 100vh;
}

.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.25rem;
}

.left-section {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.right-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  height: 38px;
  padding: 0 1rem;
  background-color: #ffffff;
  color: #404040;
  font-size: 13.5px;
  font-weight: 500;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-secondary-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  height: 38px;
  padding: 0 1.25rem;
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

.btn-primary-action:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.tabs-wrapper {
  margin-bottom: 1.25rem;
}

.clean-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 1.75rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.section-header-block {
  margin-bottom: 1.25rem;
}

.slots-header-layout {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1.5rem;
  flex-wrap: wrap;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0 0 4px 0;
}

.section-desc {
  font-size: 12.5px;
  color: #737373;
  margin: 0;
}

/* Rota Analytics Bar */
.rota-analytics-bar {
  display: flex;
  align-items: center;
  gap: 0.875rem;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 6px 14px;
  border-radius: 8px;
}

.analytics-stat {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.stat-label {
  font-size: 10.5px;
  font-weight: 500;
  color: #737373;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.stat-val {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.stat-sep {
  width: 1px;
  height: 24px;
  background-color: #e2e8f0;
}

/* Statutory Alert Banner */
.statutory-alert-banner {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  background-color: #fffbeb;
  border: 1px solid #fde68a;
  border-radius: 8px;
  padding: 0.75rem 1rem;
  margin-bottom: 1.25rem;
}

.alert-content {
  font-size: 12.5px;
  color: #92400e;
  line-height: 1.45;
}

/* Presets Toolbar */
.presets-toolbar {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1.25rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #f1f5f9;
  flex-wrap: wrap;
}

.presets-label {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  font-size: 12px;
  font-weight: 600;
  color: #404040;
}

.presets-buttons {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.btn-preset-pill {
  height: 28px;
  padding: 0 10px;
  background-color: #eff6ff;
  border: 1px solid #dbeafe;
  color: #0b529c;
  font-size: 11.5px;
  font-weight: 500;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-preset-pill:hover {
  background-color: #dbeafe;
  border-color: #bfdbfe;
}

.btn-preset-pill-muted {
  height: 28px;
  padding: 0 10px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  color: #64748b;
  font-size: 11.5px;
  font-weight: 500;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-preset-pill-muted:hover {
  background-color: #f1f5f9;
  color: #475569;
}

/* Slot Matrix Card Grid */
.slot-matrix-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(210px, 1fr));
  gap: 1rem;
}

.slot-matrix-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 0.875rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  transition: all 0.15s ease;
}

.slot-matrix-card:hover {
  border-color: #cbd5e1;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.03);
}

.slot-matrix-card.card-is-rest {
  background: #fafafa;
  border-style: dashed;
  border-color: #e2e8f0;
}

.slot-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.day-number-pill {
  font-size: 12px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 4px;
}

.pill-work {
  background: #eff6ff;
  color: #0b529c;
}

.pill-rest {
  background: #f1f5f9;
  color: #64748b;
}

.btn-card-toggle {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  height: 24px;
  padding: 0 8px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 500;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-card-toggle:hover {
  background-color: #f8fafc;
  color: #404040;
  border-color: #cbd5e1;
}

.slot-card-body {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.slot-field-label {
  font-size: 11px;
  font-weight: 500;
  color: #737373;
}

.slot-native-select {
  height: 34px;
  padding: 0 8px;
  font-size: 12px;
  color: #404040;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  outline: none;
  cursor: pointer;
  transition: border-color 0.15s ease;
  width: 100%;
}

.slot-native-select:focus {
  border-color: #0b529c;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.08);
}

.slot-card-footer {
  margin-top: auto;
  padding-top: 4px;
}

.timing-strip {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  font-size: 11px;
  padding: 4px 6px;
  border-radius: 4px;
}

.work-strip {
  background-color: #f0fdf4;
  color: #166534;
}

.rest-strip {
  background-color: #f8fafc;
  color: #64748b;
}

.timing-text {
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 1.25rem;
}

@media (max-width: 900px) {
  .form-grid-3 {
    grid-template-columns: 1fr;
  }
}
</style>
