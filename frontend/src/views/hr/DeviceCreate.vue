<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRouter } from 'vue-router';
import { 
  X, Save, MapPin, Navigation, CheckCircle2
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3 & 4) ───
const breadcrumbItems = [
  { label: 'Biometric Devices', to: '/hr/attendance-devices' },
  { label: 'Register Device' }
];

const isSaved = ref(false);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Branch Entity Preset Coordinates ───
const branchLocations: Record<number, { name: string; lat: number; lng: number; defaultRadius: number }> = {
  3: { name: 'Haleta Addis Ababa HQ', lat: 9.0105, lng: 38.7615, defaultRadius: 100 },
  7: { name: 'Bole Commercial Branch', lat: 8.9950, lng: 38.7885, defaultRadius: 150 },
  9: { name: 'Hawassa Industrial Plant', lat: 7.0504, lng: 38.4955, defaultRadius: 300 },
  12: { name: 'Piazza Web Portal Kiosk', lat: 9.0350, lng: 38.7510, defaultRadius: 50 }
};

const entityOptions = [
  { value: '3', label: 'Haleta Addis Ababa HQ' },
  { value: '7', label: 'Bole Commercial Branch' },
  { value: '9', label: 'Hawassa Industrial Plant' },
  { value: '12', label: 'Piazza Web Portal Kiosk' }
];

const deviceTypeOptions = [
  { value: 'biometric_fingerprint', label: 'Biometric Fingerprint Scanner' },
  { value: 'biometric_face', label: 'Facial Biometric Recognition Station' },
  { value: 'rfid_card', label: 'RFID Proximity Smart Card Reader' },
  { value: 'mobile_gps', label: 'Mobile GPS & Geo-Fence Gateway' },
  { value: 'web_portal', label: 'Web Kiosk Punch Terminal' }
];

// ─── Form State Strictly Conforming to AttendanceDevice Schema (Lines 1828–1842) ───
const form = ref({
  code: 'DEV-BOLE-02',
  name: '',
  entity_id: '7',
  device_type: 'biometric_fingerprint',
  serial_number: '',
  ip_address: '192.168.20.15',
  // geo_fence jsonb: { lat, lng, radius_m }
  geo_lat: 8.9950,
  geo_lng: 38.7885,
  geo_radius: 150
});

// Auto-generate suggested code when entity or device type changes
watch([() => form.value.entity_id, () => form.value.device_type], () => {
  const branchPrefixMap: Record<string, string> = {
    '3': 'HQ',
    '7': 'BOLE',
    '9': 'HAW',
    '12': 'PZA'
  };
  const typePrefix = form.value.device_type === 'mobile_gps' ? 'MOB' : 'DEV';
  const branchPrefix = branchPrefixMap[form.value.entity_id] || 'GEN';
  form.value.code = `${typePrefix}-${branchPrefix}-02`;
});

const isMobileGps = computed(() => form.value.device_type === 'mobile_gps');

// ─── 1-Click Location Autofill ───
const handleCopyFromBranch = () => {
  const preset = branchLocations[Number(form.value.entity_id)];
  if (preset) {
    form.value.geo_lat = preset.lat;
    form.value.geo_lng = preset.lng;
    form.value.geo_radius = preset.defaultRadius;
    showToast(`Loaded GPS coordinates for ${preset.name}`);
  }
};

const isFetchingGps = ref(false);
const handleUseCurrentLocation = () => {
  if (!navigator.geolocation) {
    alert('Geolocation is not supported by your browser.');
    return;
  }
  isFetchingGps.value = true;
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      form.value.geo_lat = Number(pos.coords.latitude.toFixed(6));
      form.value.geo_lng = Number(pos.coords.longitude.toFixed(6));
      isFetchingGps.value = false;
      showToast('Detected current GPS location.');
    },
    () => {
      isFetchingGps.value = false;
      alert('Unable to retrieve location. Please check browser permissions.');
    },
    { enableHighAccuracy: true, timeout: 8000 }
  );
};

// ─── Clear Form ───
const handleClearForm = () => {
  form.value = {
    code: 'DEV-BOLE-02',
    name: '',
    entity_id: '7',
    device_type: 'biometric_fingerprint',
    serial_number: '',
    ip_address: '192.168.20.15',
    geo_lat: 8.9950,
    geo_lng: 38.7885,
    geo_radius: 150
  };
  showToast('Form cleared.');
};

// ─── Save Device (Rule 4 Standard) ───
const executeSave = () => {
  if (!form.value.code) {
    alert('Please enter a device code.');
    return;
  }
  if (!form.value.name) {
    alert('Please enter a terminal name.');
    return;
  }

  isSaved.value = true;
  showToast(`Terminal ${form.value.code} registered.`);

  setTimeout(() => {
    router.push('/hr/attendance-devices');
  }, 800);
};

const radiusOptions = [50, 100, 150, 250, 500, 1000];
</script>

<template>
  <div class="device-create-page">
    <!-- ═══ TOP BAR NAVIGATION (AGENTS.md Rule 4 Standard) ═══ -->
    <div class="top-nav-bar">
      <AppBreadcrumb :items="breadcrumbItems" />

      <div class="top-actions-cluster">
        <span class="save-status-pill" :class="isSaved ? 'pill-saved' : 'pill-not-saved'">
          {{ isSaved ? 'Saved' : 'Not Saved' }}
        </span>

        <button type="button" class="btn-secondary-action" @click="handleClearForm">
          <X :size="14" />
          <span>Clear Form</span>
        </button>

        <button type="button" class="btn-primary-action" @click="executeSave">
          <Save :size="15" />
          <span>Save Terminal</span>
        </button>
      </div>
    </div>

    <!-- Notification Toast -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <div class="form-layout-container">
      <!-- ═══ CARD 1: GENERAL DEVICE IDENTIFIERS ═══ -->
      <div class="clean-card">
        <div class="card-header-bar">
          <div class="header-titles">
            <h2 class="card-title">Device Specification</h2>
            <p class="card-subtitle">
              Register physical biometric timeclocks, RFID badge terminals, or mobile GPS gateways.
            </p>
          </div>
        </div>

        <div class="card-body-grid">
          <!-- Row 1: Code + Name -->
          <div class="form-2col-row">
            <FormInput
              v-model="form.code"
              label="Device Code"
              required
            />

            <FormInput
              v-model="form.name"
              label="Terminal Name"
              required
            />
          </div>

          <!-- Row 2: Location + Hardware Protocol -->
          <div class="form-2col-row">
            <FormSelect
              v-model="form.entity_id"
              label="Assigned Location"
              :options="entityOptions"
              placeholder="Select"
              required
            />

            <FormSelect
              v-model="form.device_type"
              label="Device Type"
              :options="deviceTypeOptions"
              placeholder="Select"
              required
            />
          </div>
        </div>
      </div>

      <!-- ═══ CARD 2: NETWORK OR GEOFENCE CONFIGURATION ═══ -->
      
      <!-- MODE A: PHYSICAL TERMINAL (ip_address & serial_number) -->
      <div v-if="!isMobileGps" class="clean-card">
        <div class="card-header-bar">
          <div class="header-titles">
            <h2 class="card-title">Hardware &amp; Network Identification</h2>
            <p class="card-subtitle">
              Hardware identification for cloud sync workers and device logs.
            </p>
          </div>
        </div>

        <div class="card-body-grid">
          <div class="form-2col-row">
            <FormInput
              v-model="form.ip_address"
              label="IP Address"
            />

            <FormInput
              v-model="form.serial_number"
              label="Serial Number"
            />
          </div>
        </div>
      </div>

      <!-- MODE B: MOBILE GPS (geo_fence: { lat, lng, radius_m }) -->
      <div v-else class="clean-card geofence-card">
        <div class="card-header-bar">
          <div class="header-titles">
            <h2 class="card-title">Geographic Work Boundary</h2>
            <p class="card-subtitle">
              Define the branch location and maximum allowed distance for staff clocking in from their smartphones.
            </p>
          </div>
        </div>

        <div class="card-body-grid">
          <!-- Quick Autofill Shortcuts Bar -->
          <div class="quick-autofill-strip">
            <span class="strip-label">Quick Location:</span>
            <div class="strip-buttons">
              <button
                type="button"
                class="btn-quick-fill"
                @click="handleCopyFromBranch"
              >
                <MapPin :size="13" />
                <span>Copy from Selected Branch</span>
              </button>

              <button
                type="button"
                class="btn-quick-fill"
                :disabled="isFetchingGps"
                @click="handleUseCurrentLocation"
              >
                <Navigation :size="13" :class="{ 'spin-icon': isFetchingGps }" />
                <span>{{ isFetchingGps ? 'Locating...' : 'Use Current GPS' }}</span>
              </button>
            </div>
          </div>

          <!-- Coordinates & Radius Inputs -->
          <div class="form-3col-row">
            <FormInput
              v-model.number="form.geo_lat"
              type="number"
              step="0.000001"
              label="Latitude"
              required
            />

            <FormInput
              v-model.number="form.geo_lng"
              type="number"
              step="0.000001"
              label="Longitude"
              required
            />

            <div>
              <label class="form-custom-label">Allowed Distance: {{ form.geo_radius }} meters</label>
              <div class="radius-chips-row">
                <button
                  v-for="r in radiusOptions"
                  :key="r"
                  type="button"
                  class="radius-chip"
                  :class="{ 'chip-active': form.geo_radius === r }"
                  @click="form.geo_radius = r"
                >
                  {{ r >= 1000 ? `${r / 1000}km` : `${r}m` }}
                </button>
              </div>
            </div>
          </div>

          <!-- Visual Geofence Map -->
          <div class="map-visualizer-container">
            <div class="map-radar-viewport">
              <iframe
                class="osm-map-frame"
                :src="`https://www.openstreetmap.org/export/embed.html?bbox=${form.geo_lng - 0.008}%2C${form.geo_lat - 0.005}%2C${form.geo_lng + 0.008}%2C${form.geo_lat + 0.005}&layer=mapnik&marker=${form.geo_lat}%2C${form.geo_lng}`"
                loading="lazy"
                title="Geofence Map"
              ></iframe>

              <div class="geofence-radar-circle">
                <div class="radar-center-pin">
                  <MapPin :size="20" class="pin-svg" />
                </div>
                <div class="radar-distance-tag">
                  {{ form.geo_radius }}m Allowed Distance
                </div>
              </div>
            </div>

            <div class="map-footer-caption">
              <span class="caption-dot"></span>
              <span>Employees within <strong>{{ form.geo_radius }} meters</strong> of this location can clock in using the mobile app.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.device-create-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 20px 24px 80px 24px;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

/* ─── Top Bar Navigation ─── */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}

.top-actions-cluster {
  display: flex;
  align-items: center;
  gap: 10px;
}

.save-status-pill {
  padding: 3px 10px;
  font-size: 11.5px;
  font-weight: 500;
  border-radius: 9999px;
}

.pill-not-saved {
  background-color: #f1f5f9;
  color: #64748b;
}

.pill-saved {
  background-color: #ecfdf5;
  color: #059669;
}

.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 14px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-secondary-action:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
}

.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  font-size: 13px;
  font-weight: 500;
  color: #ffffff;
  background: #0B529C;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.15s ease;
}

.btn-primary-action:hover {
  background: #083c73;
}

/* ─── Form Container & Clean Cards ─── */
.form-layout-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-width: 900px;
}

.clean-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  overflow: hidden;
}

.card-header-bar {
  padding: 16px 20px;
  border-bottom: 1px solid #f1f5f9;
}

.card-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.card-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin-top: 3px;
}

.card-body-grid {
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-2col-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.form-3col-row {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 16px;
}

.form-custom-label {
  display: block;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}

/* ─── Geofence Quick Strip ─── */
.quick-autofill-strip {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 10px;
  padding: 10px 14px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.strip-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.strip-buttons {
  display: flex;
  gap: 8px;
}

.btn-quick-fill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 30px;
  padding: 0 10px;
  font-size: 12px;
  font-weight: 500;
  color: #0B529C;
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-quick-fill:hover {
  background: #f1f5f9;
  border-color: #94a3b8;
}

/* ─── Radius Chips ─── */
.radius-chips-row {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.radius-chip {
  height: 36px;
  padding: 0 10px;
  font-size: 12px;
  font-weight: 500;
  color: #404040;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.radius-chip:hover {
  border-color: #94a3b8;
}

.chip-active {
  background: #0B529C !important;
  color: #ffffff !important;
  border-color: #0B529C !important;
}

/* ─── Map Visualizer ─── */
.map-visualizer-container {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.map-radar-viewport {
  position: relative;
  width: 100%;
  height: 260px;
  background: #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #cbd5e1;
}

.osm-map-frame {
  width: 100%;
  height: 100%;
  border: none;
}

.geofence-radar-circle {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 140px;
  height: 140px;
  border-radius: 50%;
  background: rgba(11, 82, 156, 0.15);
  border: 2px dashed #0B529C;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  pointer-events: none;
}

.radar-center-pin {
  color: #dc2626;
  filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));
}

.radar-distance-tag {
  font-size: 11px;
  font-weight: 600;
  color: #0B529C;
  background: rgba(255, 255, 255, 0.9);
  padding: 2px 6px;
  border-radius: 4px;
  margin-top: 4px;
  white-space: nowrap;
}

.map-footer-caption {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #737373;
}

.caption-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #0B529C;
}

/* ─── Toast Bar ─── */
.toast-bar {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  color: #065f46;
  font-size: 13px;
  font-weight: 500;
}

.spin-icon {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

@media (max-width: 768px) {
  .form-2col-row, .form-3col-row {
    grid-template-columns: 1fr;
  }
}
</style>
