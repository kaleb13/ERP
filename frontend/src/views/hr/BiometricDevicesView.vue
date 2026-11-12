<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  ShieldCheck, Fingerprint, Plus, Search,
  Filter, CheckCircle2, Radio, Wifi,
  RefreshCw
} from 'lucide-vue-next';;
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseBadge from '../../components/BaseBadge.vue';
import AppDataTable from '../../components/AppDataTable.vue';
import MetricCard from '../../components/MetricCard.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import QuickCreateModal from '../../components/QuickCreateModal.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormInput from '../../components/FormInput.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import { type ColumnDef } from '../../components/BaseTable.vue';

const router = useRouter();

// ─── Breadcrumb Navigation Standard (AGENTS.md Rule 3: Exact Sidebar Page Name Only) ───
const breadcrumbItems = [
  { label: 'Biometric Devices' }
];

// ─── Active Tab State (AGENTS.md Rule 1: UnderlineTabs Standard) ───
type TabKey = 'terminals' | 'enrollments';
const activeTab = ref<TabKey>('terminals');

// ─── Filter & Search State ───
const searchQuery = ref('');
const selectedEntityFilter = ref('all');
const selectedTypeFilter = ref('all');
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => { toastMessage.value = null; }, 3200);
};

// ─── Catalogues ───
const entityOptions = [
  { value: 'all', label: 'All Facilities & Branches' },
  { value: '3', label: 'Haleta Addis Ababa HQ' },
  { value: '7', label: 'Bole Commercial Branch' },
  { value: '9', label: 'Hawassa Industrial Plant' },
  { value: '12', label: 'Piazza Web Portal Kiosk' }
];

const deviceTypeOptions = [
  { value: 'all', label: 'All Hardware Protocols' },
  { value: 'biometric_face', label: 'Facial Biometric Recognition' },
  { value: 'biometric_fingerprint', label: 'Biometric Fingerprint Scanner' },
  { value: 'rfid_card', label: 'RFID Proximity Smart Card' },
  { value: 'mobile_gps', label: 'Mobile Geofence Gateway' },
  { value: 'web_portal', label: 'Web Kiosk Punch Station' }
];

const employeeSelectOptions = [
  { value: '14', label: 'Abebe Kebede (EMP-014 • Head of Retail)' },
  { value: '15', label: 'Sara Tefera (EMP-015 • Shift Supervisor)' },
  { value: '18', label: 'Dawit Yohannes (EMP-018 • Senior Cashier)' },
  { value: '22', label: 'Bethlehem Haile (EMP-022 • Inventory Controller)' },
  { value: '9',  label: 'Almaz Mengistu (EMP-009 • HR Operations Lead)' },
  { value: '7',  label: 'Tewodros Kassahun (EMP-007 • Security Guard)' },
  { value: '8',  label: 'Mulugeta Belete (EMP-008 • Night Guard Lead)' }
];

// ─── Types Conforming to HR Schema Designer 1.sql lines 1828–1874 ───
export interface AttendanceDeviceRecord {
  id: number;
  code: string;
  name: string;
  entity_id: number;
  entity_name: string;
  device_type: 'biometric_fingerprint' | 'biometric_face' | 'rfid_card' | 'mobile_gps' | 'web_portal';
  device_type_label: string;
  serial_number: string;
  ip_address: string;
  last_seen_at: string;
  is_online: boolean;
  enrolled_users_count: number;
  state: 'active' | 'inactive';
}

export interface EmployeeDeviceEnrollmentRecord {
  id: number;
  employee_id: number;
  employee_name: string;
  employee_code: string;
  employee_role: string;
  attendance_device_id: number | null;
  device_name: string;
  credential_type: 'rfid_card' | 'fingerprint_template' | 'face_template' | 'pin';
  credential_ref: string;
  enrolled_at: string;
  revoked_at: string | null;
  state: 'active' | 'inactive';
}

// ─── Dataset: AttendanceDevice (Schema lines 1828–1851) ───
const devices = ref<AttendanceDeviceRecord[]>([
  {
    id: 1,
    code: 'DEV-HQ-01',
    name: 'HQ Lobby Face Recognition Terminal',
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    device_type: 'biometric_face',
    device_type_label: 'Facial Biometric Recognition (ZK-8812)',
    serial_number: 'ZK-88121-AA',
    ip_address: '192.168.10.45',
    last_seen_at: 'Just now (Heartbeat OK)',
    is_online: true,
    enrolled_users_count: 142,
    state: 'active'
  },
  {
    id: 2,
    code: 'DEV-BOLE-01',
    name: 'Bole Fingerprint Biometric Scanner',
    entity_id: 7,
    entity_name: 'Bole Commercial Branch',
    device_type: 'biometric_fingerprint',
    device_type_label: 'Biometric Fingerprint Scanner (ZK-77015)',
    serial_number: 'ZK-77015-BC',
    ip_address: '192.168.20.12',
    last_seen_at: 'Just now (Heartbeat OK)',
    is_online: true,
    enrolled_users_count: 86,
    state: 'active'
  },
  {
    id: 3,
    code: 'DEV-HAW-01',
    name: 'Hawassa Industrial Gate Dual Reader',
    entity_id: 9,
    entity_name: 'Hawassa Industrial Plant',
    device_type: 'rfid_card',
    device_type_label: 'RFID Proximity & Biometric Dual (HID-3302)',
    serial_number: 'HID-3302-HW',
    ip_address: '10.0.4.18',
    last_seen_at: '2 mins ago',
    is_online: true,
    enrolled_users_count: 218,
    state: 'active'
  },
  {
    id: 4,
    code: 'DEV-MOB-01',
    name: 'Universal Field Mobile Geofence Gateway',
    entity_id: 3,
    entity_name: 'Haleta Addis Ababa HQ',
    device_type: 'mobile_gps',
    device_type_label: 'Mobile GPS & Geo-Fence API Gateway',
    serial_number: 'APP-GPS-GATEWAY',
    ip_address: 'api.haleta-cloud.internal',
    last_seen_at: 'Active (Realtime Webhook)',
    is_online: true,
    enrolled_users_count: 64,
    state: 'active'
  },
  {
    id: 5,
    code: 'DEV-PZA-01',
    name: 'Piazza Web Portal Punch Station',
    entity_id: 12,
    entity_name: 'Piazza Web Portal Kiosk',
    device_type: 'web_portal',
    device_type_label: 'Web Kiosk Punch Station (Port 8443)',
    serial_number: 'KIOSK-PZA-004',
    ip_address: '192.168.30.5',
    last_seen_at: '15 mins ago',
    is_online: true,
    enrolled_users_count: 32,
    state: 'active'
  }
]);

// ─── Dataset: EmployeeDeviceEnrollment (Schema lines 1852–1874) ───
const enrollments = ref<EmployeeDeviceEnrollmentRecord[]>([
  {
    id: 1,
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    employee_role: 'Head of Retail',
    attendance_device_id: 2,
    device_name: 'Bole Fingerprint Scanner (DEV-BOLE-01)',
    credential_type: 'fingerprint_template',
    credential_ref: 'Slot 00214',
    enrolled_at: '2024-06-02',
    revoked_at: null,
    state: 'active'
  },
  {
    id: 2,
    employee_id: 14,
    employee_name: 'Abebe Kebede',
    employee_code: 'EMP-014',
    employee_role: 'Head of Retail',
    attendance_device_id: null,
    device_name: 'All Devices (Roaming Card)',
    credential_type: 'rfid_card',
    credential_ref: '04A6-77-BC21',
    enrolled_at: '2024-06-02',
    revoked_at: null,
    state: 'active'
  },
  {
    id: 3,
    employee_id: 22,
    employee_name: 'Bethlehem Haile',
    employee_code: 'EMP-022',
    employee_role: 'Inventory Controller',
    attendance_device_id: 1,
    device_name: 'HQ Lobby Face Recognition Terminal (DEV-HQ-01)',
    credential_type: 'face_template',
    credential_ref: 'Face 00022',
    enrolled_at: '2021-09-16',
    revoked_at: null,
    state: 'active'
  },
  {
    id: 4,
    employee_id: 18,
    employee_name: 'Dawit Yohannes',
    employee_code: 'EMP-018',
    employee_role: 'Senior Cashier',
    attendance_device_id: 2,
    device_name: 'Bole Fingerprint Scanner (DEV-BOLE-01)',
    credential_type: 'fingerprint_template',
    credential_ref: 'Slot 00318',
    enrolled_at: '2025-02-18',
    revoked_at: null,
    state: 'active'
  },
  {
    id: 5,
    employee_id: 15,
    employee_name: 'Sara Tefera',
    employee_code: 'EMP-015',
    employee_role: 'Shift Supervisor',
    attendance_device_id: null,
    device_name: 'All Devices (Roaming Card)',
    credential_type: 'rfid_card',
    credential_ref: '04A6-77-90FF',
    enrolled_at: '2024-01-10',
    revoked_at: '2026-05-30',
    state: 'inactive'
  },
  {
    id: 6,
    employee_id: 9,
    employee_name: 'Almaz Mengistu',
    employee_code: 'EMP-009',
    employee_role: 'HR Operations Lead',
    attendance_device_id: 1,
    device_name: 'HQ Lobby Face Recognition Terminal (DEV-HQ-01)',
    credential_type: 'face_template',
    credential_ref: 'Face 00009',
    enrolled_at: '2023-04-12',
    revoked_at: null,
    state: 'active'
  },
  {
    id: 7,
    employee_id: 7,
    employee_name: 'Tewodros Kassahun',
    employee_code: 'EMP-007',
    employee_role: 'Security Guard',
    attendance_device_id: 3,
    device_name: 'Hawassa Industrial Gate Dual Reader (DEV-HAW-01)',
    credential_type: 'rfid_card',
    credential_ref: '04A6-88-HAW7',
    enrolled_at: '2025-08-01',
    revoked_at: null,
    state: 'active'
  }
]);

// ─── Metric Cards Computed (AGENTS.md Rule 2 Standard) ───
const metrics = computed(() => {
  const totalDevices = devices.value.length;
  const onlineDevices = devices.value.filter(d => d.is_online).length;
  const totalEnrollments = enrollments.value.filter(e => e.state === 'active').length;
  const roamingCards = enrollments.value.filter(e => e.attendance_device_id === null && e.state === 'active').length;

  return {
    totalDevices,
    onlineDevices,
    totalEnrollments,
    roamingCards
  };
});

// ─── Tabs Configuration (AGENTS.md Single Tab Standard: BaseTabs rounded) ───
const deviceTabs = computed<BaseTabItem<TabKey>[]>(() => [
  { id: 'terminals', label: 'Attendance Devices', count: devices.value.length, icon: ShieldCheck },
  { id: 'enrollments', label: 'Device Enrollments', count: enrollments.value.filter(e => e.state === 'active').length, icon: Fingerprint }
]);

// ─── Column Architecture (AGENTS.md Rule 9) ───
const terminalColumns = ref<ColumnDef[]>([
  { key: 'terminal', label: 'Device Name & Code', visible: true },
  { key: 'location', label: 'Assigned Location', visible: true },
  { key: 'hardware_type', label: 'Device Type', visible: true },
  { key: 'ip_address', label: 'IP Address', visible: true },
  { key: 'serial', label: 'Serial Number', visible: true },
  { key: 'heartbeat', label: 'Last Seen', visible: true },
  { key: 'enrolled', label: 'Enrolled Users', visible: true },
  { key: 'status', label: 'Status', visible: true },
  { key: 'actions', label: 'Actions', visible: true }
]);

const enrollmentColumns = ref<ColumnDef[]>([
  { key: 'employee', label: 'Employee', visible: true },
  { key: 'scope', label: 'Attendance Device', visible: true },
  { key: 'credential_type', label: 'Credential Type', visible: true },
  { key: 'credential_ref', label: 'Credential Reference', visible: true },
  { key: 'enrolled_at', label: 'Enrollment Date', visible: true },
  { key: 'state', label: 'State', visible: true },
  { key: 'actions', label: 'Actions', visible: true }
]);

const handleToggleTerminalCol = (key: string) => {
  const col = terminalColumns.value.find(c => c.key === key);
  if (col) col.visible = !col.visible;
};

const handleToggleEnrollmentCol = (key: string) => {
  const col = enrollmentColumns.value.find(c => c.key === key);
  if (col) col.visible = !col.visible;
};

// ─── Filtered Datasets ───
const filteredDevices = computed(() => {
  return devices.value.filter(dev => {
    const matchesSearch = !searchQuery.value ||
      dev.name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      dev.code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      dev.ip_address.toLowerCase().includes(searchQuery.value.toLowerCase());

    const matchesEntity = selectedEntityFilter.value === 'all' || String(dev.entity_id) === selectedEntityFilter.value;
    const matchesType = selectedTypeFilter.value === 'all' || dev.device_type === selectedTypeFilter.value;

    return matchesSearch && matchesEntity && matchesType;
  });
});

const filteredEnrollments = computed(() => {
  return enrollments.value.filter(enr => {
    const matchesSearch = !searchQuery.value ||
      enr.employee_name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      enr.employee_code.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      enr.credential_ref.toLowerCase().includes(searchQuery.value.toLowerCase());

    const matchesType = selectedTypeFilter.value === 'all' || enr.credential_type === selectedTypeFilter.value;

    return matchesSearch && matchesType;
  });
});

// ─── Row Selection for Enrollments Batch Action Bar ───
const selectedEnrollmentIds = ref<number[]>([]);

const handleToggleSelectAllEnrollments = (checked: boolean) => {
  selectedEnrollmentIds.value = checked ? filteredEnrollments.value.map(e => e.id) : [];
};

const handleToggleEnrollmentRow = (id: number) => {
  const idx = selectedEnrollmentIds.value.indexOf(id);
  if (idx > -1) selectedEnrollmentIds.value.splice(idx, 1);
  else selectedEnrollmentIds.value.push(id);
};

// ─── Batch Floating Bar Actions ───
const handleBatchRevoke = () => {
  const count = selectedEnrollmentIds.value.length;
  enrollments.value.forEach(enr => {
    if (selectedEnrollmentIds.value.includes(enr.id)) {
      enr.state = 'inactive';
      enr.revoked_at = new Date().toISOString().slice(0, 10);
    }
  });
  showToast(`Revoked ${count} staff credentials from terminals.`);
  selectedEnrollmentIds.value = [];
};

const handleBatchExportEnrollments = () => {
  showToast(`Exported ${selectedEnrollmentIds.value.length} credential records.`);
  selectedEnrollmentIds.value = [];
};

// ─── Register Device Modal (AttendanceDevice) ───
const showRegisterDeviceModal = ref(false);
const deviceForm = ref({
  code: '',
  name: '',
  entity_id: '7',
  device_type: 'biometric_fingerprint' as AttendanceDeviceRecord['device_type'],
  serial_number: '',
  ip_address: ''
});

const handleOpenRegisterDevice = () => {
  router.push('/hr/attendance-devices/create');
};

const handleExpandDeviceForm = () => {
  showRegisterDeviceModal.value = false;
  router.push('/hr/attendance-devices/create');
};

const handleSaveDevice = () => {
  if (!deviceForm.value.code || !deviceForm.value.name) {
    alert('Please provide a device code and terminal name.');
    return;
  }
  const entity = entityOptions.find(e => e.value === String(deviceForm.value.entity_id));
  const newDev: AttendanceDeviceRecord = {
    id: Date.now(),
    code: deviceForm.value.code.toUpperCase(),
    name: deviceForm.value.name,
    entity_id: Number(deviceForm.value.entity_id),
    entity_name: entity ? entity.label : 'Bole Commercial Branch',
    device_type: deviceForm.value.device_type,
    device_type_label: deviceTypeOptions.find(t => t.value === deviceForm.value.device_type)?.label || 'Biometric Scanner',
    serial_number: deviceForm.value.serial_number || 'ZK-GEN-01',
    ip_address: deviceForm.value.ip_address || '192.168.1.100',
    last_seen_at: 'Just now (Registered)',
    is_online: true,
    enrolled_users_count: 0,
    state: 'active'
  };

  devices.value.unshift(newDev);
  showRegisterDeviceModal.value = false;
  showToast(`Registered terminal ${newDev.code} successfully.`);
};

// ─── Enroll Credential Modal (EmployeeDeviceEnrollment) ───
const showEnrollCredentialModal = ref(false);
const enrollForm = ref({
  employee_id: '14',
  attendance_device_id: null as number | null,
  credential_type: 'rfid_card' as EmployeeDeviceEnrollmentRecord['credential_type'],
  credential_ref: ''
});

const handleOpenEnrollCredential = () => {
  enrollForm.value = {
    employee_id: '14',
    attendance_device_id: null,
    credential_type: 'rfid_card',
    credential_ref: ''
  };
  showEnrollCredentialModal.value = true;
};

const handleSaveEnrollment = () => {
  if (!enrollForm.value.credential_ref) {
    alert('Please enter a credential serial or slot ID.');
    return;
  }
  const emp = employeeSelectOptions.find(e => e.value === String(enrollForm.value.employee_id));
  const dev = devices.value.find(d => d.id === enrollForm.value.attendance_device_id);
  const newEnr: EmployeeDeviceEnrollmentRecord = {
    id: Date.now(),
    employee_id: Number(enrollForm.value.employee_id),
    employee_name: emp ? emp.label.split(' (')[0] : 'Employee',
    employee_code: emp ? emp.label.match(/EMP-\d+/)?.[0] || 'EMP' : 'EMP',
    employee_role: emp ? emp.label.split('• ')[1]?.replace(')', '') || 'Staff' : 'Staff',
    attendance_device_id: enrollForm.value.attendance_device_id,
    device_name: dev ? `${dev.name} (${dev.code})` : 'All Devices (Roaming Card)',
    credential_type: enrollForm.value.credential_type,
    credential_ref: enrollForm.value.credential_ref,
    enrolled_at: new Date().toISOString().slice(0, 10),
    revoked_at: null,
    state: 'active'
  };

  enrollments.value.unshift(newEnr);
  showEnrollCredentialModal.value = false;
  showToast(`Issued ${newEnr.credential_type.replace('_', ' ')} credential for ${newEnr.employee_name}.`);
};

const handleRevokeSingleEnrollment = (enr: EmployeeDeviceEnrollmentRecord) => {
  enr.state = 'inactive';
  enr.revoked_at = new Date().toISOString().slice(0, 10);
  showToast(`Revoked credential ${enr.credential_ref} for ${enr.employee_name}. Deleted from hardware.`);
};
</script>

<template>
  <div class="biometric-devices-page">
    <!-- Breadcrumb Standard (AGENTS.md Rule 3: Exact Sidebar Page Name Only) -->
    <div class="breadcrumb-container">
      <AppBreadcrumb :items="breadcrumbItems" />
    </div>

    <!-- Notification Toast -->
    <Transition name="toast-fade">
      <div v-if="toastMessage" class="toast-bar">
        <CheckCircle2 :size="15" />
        <span>{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- Top KPI / Metrics Cards Grid (AGENTS.md Rule 2 Standard) -->
    <div class="metrics-grid">
      <MetricCard
        label="Registered Terminals"
        :value="`${metrics.totalDevices}`"
        :subtext="`${metrics.onlineDevices} Online &amp; Broadcasting`"
        :icon="ShieldCheck"
        size="md"
        :show-menu="false"
      />

      <MetricCard
        label="Heartbeat Status"
        :value="metrics.onlineDevices === metrics.totalDevices ? '100% Online' : `${metrics.onlineDevices}/${metrics.totalDevices} Active`"
        subtext="Direct TCP / Cloud Push Gateway"
        :icon="Radio"
        size="md"
        :show-menu="false"
      />

      <MetricCard
        label="Staff Credentials Enrolled"
        :value="`${metrics.totalEnrollments}`"
        subtext="RFID cards &amp; biometric template slots"
        :icon="Fingerprint"
        size="md"
        :show-menu="false"
      />

      <MetricCard
        label="Roaming RFID Badges"
        :value="`${metrics.roamingCards}`"
        subtext="Authorized across all facility gates"
        :icon="Wifi"
        size="md"
        :show-menu="false"
      />
    </div>

    <!-- Master Unified Card Container -->
    <div class="devices-unified-card">
      <!-- Primary Tabs Standard (AGENTS.md Single Tab Standard: BaseTabs rounded) -->
      <div class="card-tabs-header">
        <BaseTabs
          v-model="activeTab"
          :tabs="deviceTabs"
          type="rounded"
          size="sm"
        />
      </div>

      <!-- Tab 1: Hardware Terminals & Gateways (AttendanceDevice) -->
      <div v-if="activeTab === 'terminals'" class="tab-content-area">
        <AppDataTable
          title="Attendance Devices"
          subtitle="Physical biometric timeclocks, card readers, and mobile gateways registered across organization facilities."
          :columns="terminalColumns"
          :show-view-action="false"
          @toggleColumn="handleToggleTerminalCol"
        >
          <!-- Table Toolbar Primary Action (AGENTS.md Rule 6: 8-10px radius) -->
          <template #actions>
            <AppButton variant="primary" size="sm" @click="handleOpenRegisterDevice">
  <template #icon-left><Plus :size="15" /></template>
  Register Device
</AppButton>
          </template>

          <!-- Table Filters Strip -->
          <template #filters>
            <div class="filter-controls-row">
              <div class="filter-search-box">
                <Search :size="14" class="search-icon" />
                <input
                  type="text"
                  v-model="searchQuery"
                  class="search-input"
                  placeholder=""
                />
              </div>

              <!-- Facility Filter -->
              <div class="filter-select-item">
                <select v-model="selectedEntityFilter" class="filter-select">
                  <option v-for="opt in entityOptions" :key="opt.value" :value="opt.value">
                    {{ opt.label }}
                  </option>
                </select>
              </div>

              <!-- Hardware Type Filter -->
              <div class="filter-select-item">
                <select v-model="selectedTypeFilter" class="filter-select">
                  <option v-for="opt in deviceTypeOptions" :key="opt.value" :value="opt.value">
                    {{ opt.label }}
                  </option>
                </select>
              </div>
            </div>
          </template>

          <!-- Table Body -->
          <template #default>
            <table class="erp-table">
              <thead>
                <tr>
                  <th v-if="terminalColumns.find(c => c.key === 'terminal')?.visible">Device Name</th>
                  <th v-if="terminalColumns.find(c => c.key === 'location')?.visible">Assigned Location</th>
                  <th v-if="terminalColumns.find(c => c.key === 'hardware_type')?.visible">Device Type</th>
                  <th v-if="terminalColumns.find(c => c.key === 'ip_address')?.visible">IP Address</th>
                  <th v-if="terminalColumns.find(c => c.key === 'serial')?.visible">Serial Number</th>
                  <th v-if="terminalColumns.find(c => c.key === 'heartbeat')?.visible">Last Seen</th>
                  <th v-if="terminalColumns.find(c => c.key === 'enrolled')?.visible">Enrolled Users</th>
                  <th v-if="terminalColumns.find(c => c.key === 'status')?.visible">Status</th>
                  <th v-if="terminalColumns.find(c => c.key === 'actions')?.visible" class="th-actions">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="dev in filteredDevices" :key="dev.id">
                  <!-- Name & Code (Rule 4: Name first, Code subtext) -->
                  <td v-if="terminalColumns.find(c => c.key === 'terminal')?.visible">
                    <div class="identity-info">
                      <span class="table-name-primary">{{ dev.name }}</span>
                      <span class="table-code-subtext">{{ dev.code }}</span>
                    </div>
                  </td>

                  <!-- Location -->
                  <td v-if="terminalColumns.find(c => c.key === 'location')?.visible">
                    <span class="td-tertiary">{{ dev.entity_name }}</span>
                  </td>

                  <!-- Protocol -->
                  <td v-if="terminalColumns.find(c => c.key === 'hardware_type')?.visible">
                    <span class="td-tertiary">{{ dev.device_type_label }}</span>
                  </td>

                  <!-- IP Address -->
                  <td v-if="terminalColumns.find(c => c.key === 'ip_address')?.visible">
                    <span class="td-tertiary font-mono">{{ dev.ip_address }}</span>
                  </td>

                  <!-- Serial Number -->
                  <td v-if="terminalColumns.find(c => c.key === 'serial')?.visible">
                    <span class="td-tertiary font-mono">{{ dev.serial_number }}</span>
                  </td>

                  <!-- Connection Heartbeat -->
                  <td v-if="terminalColumns.find(c => c.key === 'heartbeat')?.visible">
                    <div class="heartbeat-cell">
                      <span class="pulse-dot"></span>
                      <span class="heartbeat-text">{{ dev.last_seen_at }}</span>
                    </div>
                  </td>

                  <!-- Enrolled Users -->
                  <td v-if="terminalColumns.find(c => c.key === 'enrolled')?.visible">
                    <span class="td-tertiary font-medium">{{ dev.enrolled_users_count }} staff</span>
                  </td>

                  <!-- Status -->
                  <td v-if="terminalColumns.find(c => c.key === 'status')?.visible">
                    <BaseBadge type="pill-color" :color="dev.is_online ? 'success' : 'error'" :dot="true" size="sm">
                      {{ dev.is_online ? 'ONLINE' : 'OFFLINE' }}
                    </BaseBadge>
                  </td>

                  <!-- Actions -->
                  <td v-if="terminalColumns.find(c => c.key === 'actions')?.visible" class="td-actions">
                    <button
                      type="button"
                      class="btn-action-dots"
                      @click="showToast(`Pinging terminal ${dev.code}... Heartbeat verified.`)"
                      title="Ping Hardware Terminal"
                    >
                      <RefreshCw :size="14" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </template>
        </AppDataTable>
      </div>

      <!-- Tab 2: Staff Credential Enrollments (EmployeeDeviceEnrollment) -->
      <div v-else-if="activeTab === 'enrollments'" class="tab-content-area">
        <AppDataTable
          title="Device Enrollments"
          subtitle="Employee card serial numbers and biometric template slot mappings. Raw biometric templates remain securely on the device."
          :columns="enrollmentColumns"
          :show-view-action="false"
          @toggleColumn="handleToggleEnrollmentCol"
        >
          <!-- Table Toolbar Primary Action -->
          <template #actions>
            <button
              type="button"
              class="btn-primary-action"
              @click="handleOpenEnrollCredential"
            >
              <Plus :size="15" />
              <span>Enroll Credential</span>
            </button>
          </template>

          <!-- Table Filters Strip -->
          <template #filters>
            <div class="filter-controls-row">
              <div class="filter-search-box">
                <Search :size="14" class="search-icon" />
                <input
                  type="text"
                  v-model="searchQuery"
                  class="search-input"
                  placeholder=""
                />
              </div>

              <!-- Credential Type Filter -->
              <div class="filter-select-item">
                <select v-model="selectedTypeFilter" class="filter-select">
                  <option value="all">All Credential Types</option>
                  <option value="rfid_card">RFID Smart Card</option>
                  <option value="fingerprint_template">Fingerprint Template Slot</option>
                  <option value="face_template">Facial Biometric Template Slot</option>
                  <option value="pin">Security PIN</option>
                </select>
              </div>
            </div>
          </template>

          <!-- Table Body -->
          <template #default>
            <table class="erp-table">
              <thead>
                <tr>
                  <th class="th-checkbox">
                    <input
                      type="checkbox"
                      class="table-checkbox"
                      :checked="filteredEnrollments.length > 0 && selectedEnrollmentIds.length === filteredEnrollments.length"
                      @change="handleToggleSelectAllEnrollments(($event.target as HTMLInputElement).checked)"
                    />
                  </th>
                  <th v-if="enrollmentColumns.find(c => c.key === 'employee')?.visible">Employee</th>
                  <th v-if="enrollmentColumns.find(c => c.key === 'scope')?.visible">Attendance Device</th>
                  <th v-if="enrollmentColumns.find(c => c.key === 'credential_type')?.visible">Credential Type</th>
                  <th v-if="enrollmentColumns.find(c => c.key === 'credential_ref')?.visible">Credential Reference</th>
                  <th v-if="enrollmentColumns.find(c => c.key === 'enrolled_at')?.visible">Enrollment Date</th>
                  <th v-if="enrollmentColumns.find(c => c.key === 'state')?.visible">State</th>
                  <th v-if="enrollmentColumns.find(c => c.key === 'actions')?.visible" class="th-actions">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="enr in filteredEnrollments"
                  :key="enr.id"
                  :class="{ 'row-selected': selectedEnrollmentIds.includes(enr.id) }"
                >
                  <!-- Selection Checkbox -->
                  <td class="td-checkbox">
                    <input
                      type="checkbox"
                      class="table-checkbox"
                      :checked="selectedEnrollmentIds.includes(enr.id)"
                      @change="handleToggleEnrollmentRow(enr.id)"
                    />
                  </td>

                  <!-- Employee (Squircle avatar + Name primary + Code/Role subtext) -->
                  <td v-if="enrollmentColumns.find(c => c.key === 'employee')?.visible">
                    <div class="identity-cell">
                      <div class="avatar-squircle">
                        {{ enr.employee_name.split(' ').map(n => n[0]).join('') }}
                      </div>
                      <div class="identity-info">
                        <span class="table-name-primary">{{ enr.employee_name }}</span>
                        <span class="table-code-subtext">{{ enr.employee_code }} &bull; {{ enr.employee_role }}</span>
                      </div>
                    </div>
                  </td>

                  <!-- Device Scope -->
                  <td v-if="enrollmentColumns.find(c => c.key === 'scope')?.visible">
                    <span class="td-tertiary">{{ enr.device_name }}</span>
                  </td>

                  <!-- Credential Protocol -->
                  <td v-if="enrollmentColumns.find(c => c.key === 'credential_type')?.visible">
                    <span class="td-tertiary capitalize">{{ enr.credential_type.replace('_', ' ') }}</span>
                  </td>

                  <!-- Slot ID / Serial -->
                  <td v-if="enrollmentColumns.find(c => c.key === 'credential_ref')?.visible">
                    <span class="td-tertiary font-mono font-medium">{{ enr.credential_ref }}</span>
                  </td>

                  <!-- Enrolled Date -->
                  <td v-if="enrollmentColumns.find(c => c.key === 'enrolled_at')?.visible">
                    <span class="td-tertiary">{{ enr.enrolled_at }}</span>
                  </td>

                  <!-- State -->
                  <td v-if="enrollmentColumns.find(c => c.key === 'state')?.visible">
                    <BaseBadge type="pill-color" :color="enr.state === 'active' ? 'success' : 'error'" :dot="true" size="sm">
                      {{ enr.state.toUpperCase() }}
                    </BaseBadge>
                  </td>

                  <!-- Actions -->
                  <td v-if="enrollmentColumns.find(c => c.key === 'actions')?.visible" class="td-actions">
                    <button
                      v-if="enr.state === 'active'"
                      type="button"
                      class="btn-revoke"
                      title="Revoke Credential & Delete from Terminal"
                      @click="handleRevokeSingleEnrollment(enr)"
                    >
                      Revoke
                    </button>
                    <span v-else class="td-tertiary text-xs">Revoked</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </template>
        </AppDataTable>
      </div>
    </div>

    <!-- Quick Register Terminal Modal (AttendanceDevice) -->
    <QuickCreateModal
      :show="showRegisterDeviceModal"
      title="Register Attendance Hardware Device"
      :show-expand-button="true"
      @expand="handleExpandDeviceForm"
      @close="showRegisterDeviceModal = false"
      @save="handleSaveDevice"
    >
      <div class="quick-form-body">
        <FormInput
          v-model="deviceForm.code"
          label="Device Code"
          required
        />
        <FormInput
          v-model="deviceForm.name"
          label="Terminal Name"
          required
        />
        <FormSelect
          v-model="deviceForm.entity_id"
          label="Assigned Location / Branch"
          :options="entityOptions.filter(e => e.value !== 'all')"
          placeholder="Select"
          required
        />
        <FormSelect
          v-model="deviceForm.device_type"
          label="Device Hardware Type"
          :options="[
            { value: 'biometric_fingerprint', label: 'Biometric Fingerprint Terminal (ZK)' },
            { value: 'biometric_face', label: 'Facial Biometric Recognition Station' },
            { value: 'rfid_card', label: 'RFID Proximity Card Scanner' },
            { value: 'mobile_gps', label: 'Mobile Geofence Gateway' },
            { value: 'web_portal', label: 'Web Kiosk Punch Station' }
          ]"
          placeholder="Select"
          required
        />
        <div class="form-2col-row">
          <FormInput
            v-model="deviceForm.serial_number"
            label="Hardware Serial Number"
          />
          <FormInput
            v-model="deviceForm.ip_address"
            label="IP / Gateway Address"
          />
        </div>
      </div>
    </QuickCreateModal>

    <!-- Quick Enroll Employee Device Credential Modal (EmployeeDeviceEnrollment) -->
    <QuickCreateModal
      :show="showEnrollCredentialModal"
      title="Enroll Employee Device Credential"
      :show-expand-button="false"
      @close="showEnrollCredentialModal = false"
      @save="handleSaveEnrollment"
    >
      <div class="quick-form-body">
        <FormSelect
          v-model="enrollForm.employee_id"
          label="Employee"
          :options="employeeSelectOptions"
          placeholder="Select"
          required
        />
        <FormSelect
          v-model="enrollForm.attendance_device_id"
          label="Attendance Device"
          :options="[
            { value: null, label: 'All Devices (Roaming)' },
            ...devices.map(d => ({ value: d.id, label: `${d.name} (${d.code})` }))
          ]"
          placeholder="Select"
        />
        <FormSelect
          v-model="enrollForm.credential_type"
          label="Credential Type"
          :options="[
            { value: 'rfid_card', label: 'RFID Proximity Smart Card' },
            { value: 'fingerprint_template', label: 'Fingerprint Biometric Template' },
            { value: 'face_template', label: 'Facial Biometric Template' },
            { value: 'pin', label: 'Security PIN' }
          ]"
          placeholder="Select"
          required
        />
        <FormInput
          v-model="enrollForm.credential_ref"
          label="Credential Reference"
          hint="Physical card serial number or template slot index (e.g. 04A6-77-BC21 or 00214)."
          required
        />
      </div>
    </QuickCreateModal>

    <!-- Floating Batch Action Bar for Enrollments -->
    <TableFloatingBar
      v-if="activeTab === 'enrollments'"
      :show="selectedEnrollmentIds.length > 0"
      :selected-count="selectedEnrollmentIds.length"
      :total-count="filteredEnrollments.length"
      :show-duplicate="false"
      :show-edit="false"
      :show-delete="false"
      :show-change-status="false"
      @deactivate="handleBatchRevoke"
      @export="handleBatchExportEnrollments"
      @close="selectedEnrollmentIds = []"
      @select-all="handleToggleSelectAllEnrollments(true)"
    />
  </div>
</template>

<style scoped>
.biometric-devices-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  padding: 0;
  background-color: var(--alias-color-bg-canvas, #f8fafc);
  min-height: 100vh;
}

.breadcrumb-container {
  display: flex;
  align-items: center;
}

/* ─── Metrics Grid (AGENTS.md Rule 2) ─── */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

@media (max-width: 1024px) {
  .metrics-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 640px) {
  .metrics-grid {
    grid-template-columns: 1fr;
  }
}

/* ─── Unified Card Container ─── */
.devices-unified-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  overflow: hidden;
}

.card-tabs-header {
  padding: 16px 20px 12px 20px;
  background: #ffffff;
  border-bottom: 1px solid #E5E5E5;
}

.tab-content-area {
  padding: 0;
}

/* ─── Table Controls ─── */
.filter-controls-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.filter-search-box {
  position: relative;
  display: flex;
  align-items: center;
}

.search-icon {
  position: absolute;
  left: 10px;
  color: #94a3b8;
}

.search-input {
  height: 34px;
  padding: 0 12px 0 32px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  font-size: 13px;
  color: #404040;
  background: #ffffff;
  width: 220px;
}

.search-input:focus {
  outline: none;
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.filter-select {
  height: 34px;
  padding: 0 28px 0 10px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  font-size: 12.5px;
  color: #404040;
  background: #ffffff;
}

.filter-select:focus {
  outline: none;
  border-color: #0B529C;
}

/* ─── Table Styling (Rule 8 Standard) ─── */
.erp-table {
  width: 100%;
  border-collapse: collapse;
}

.erp-table th {
  height: 34px;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background: #fafafa;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.erp-table td {
  height: 38px;
  padding: 8px 16px;
  font-size: 13px;
  color: #737373; /* Rule 5: Tertiary color for all standard cells */
  border-bottom: 1px solid #f1f5f9;
}

.erp-table tr:hover {
  background-color: #f8fafc;
}

.row-selected {
  background-color: #f0f7ff !important;
}

.th-checkbox, .td-checkbox {
  width: 40px;
  text-align: center;
  padding: 8px 12px;
}

.table-checkbox {
  width: 15px;
  height: 15px;
  accent-color: #0B529C;
  cursor: pointer;
}

/* ─── Identity Cell (Rule 4: Name Primary, Code Subtext) ─── */
.identity-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.avatar-squircle {
  width: 30px;
  height: 30px;
  border-radius: 8px;
  background: #e0f2fe;
  color: #0369a1;
  font-size: 11px;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.identity-info {
  display: flex;
  flex-direction: column;
}

.table-name-primary {
  font-size: 13px;
  font-weight: 500;
  color: #404040; /* Rule 5: Secondary color for Name column */
}

.table-code-subtext {
  font-size: 11px;
  color: #737373;
}

.td-tertiary {
  color: #737373;
}

/* ─── Heartbeat Status ─── */
.heartbeat-cell {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.pulse-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background-color: #10b981;
  animation: pulse 1.8s infinite;
}

@keyframes pulse {
  0% { transform: scale(0.95); opacity: 0.8; }
  50% { transform: scale(1.15); opacity: 1; }
  100% { transform: scale(0.95); opacity: 0.8; }
}

.heartbeat-text {
  font-size: 12px;
  color: #059669;
  font-weight: 500;
}

/* ─── Status Pills ─── */
.status-pill {
  display: inline-block;
  padding: 2px 10px;
  font-size: 11px;
  font-weight: 600;
  border-radius: 9999px;
  letter-spacing: 0.02em;
}

.status-present { background-color: #ecfdf5; color: #059669; }
.status-absent { background-color: #fef2f2; color: #dc2626; }

/* ─── Action Buttons (Rule 6: 8-10px radius) ─── */
.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding: 0 14px;
  border-radius: 8px;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 12.5px;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary-action:hover {
  background-color: #09427d;
}

.btn-action-dots {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  background: transparent;
  border: none;
  color: #737373;
  cursor: pointer;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.btn-revoke {
  padding: 3px 10px;
  font-size: 11px;
  font-weight: 500;
  border-radius: 6px;
  background-color: #fef2f2;
  border: 1px solid #fecaca;
  color: #dc2626;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-revoke:hover {
  background-color: #fee2e2;
}

/* ─── Modals ─── */
.quick-form-body {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.form-2col-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

/* ─── Toast ─── */
.toast-bar {
  position: fixed;
  bottom: 24px;
  right: 24px;
  background-color: #0f172a;
  color: #ffffff;
  font-size: 13px;
  padding: 10px 16px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  gap: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 9999;
}

.toast-fade-enter-active,
.toast-fade-leave-active {
  transition: opacity 0.2s, transform 0.2s;
}

.toast-fade-enter-from,
.toast-fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
</style>
