<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  X, Building2, Briefcase, Users,
  Calendar, DollarSign, FileText, MoreVertical,
  CheckCircle2, AlertCircle, Plus, Trash2,
  Maximize2, Percent, Layers
} from 'lucide-vue-next';;

import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormRichText from '../../components/FormRichText.vue';

import {
  clientAssignmentsData,
  createClientAssignment,
  updateClientAssignment,
  type ClientAssignmentRecord,
  type ClientAssignmentState,
  type PayslipCostAllocationRecord
} from './clientAssignmentData';

import { serviceAgreementsData } from './serviceAgreementData';

const router = useRouter();
const route = useRoute();

// ─── EDIT MODE DETECTION ──────────────────────────────────────────────────
const editId = computed(() => {
  if (route.params.id) return Number(route.params.id);
  if (route.query.id) return Number(route.query.id);
  return null;
});

const isEditMode = computed(() => editId.value !== null);

// ─── BREADCRUMBS (Rule 3 & 4: Exact Sidebar Page Name > Sub-page) ─────────
const breadcrumbItems = computed(() => [
  { label: 'Client Assignments', to: '/hr/client-assignments' },
  { label: isEditMode.value ? 'Edit Client Assignment' : 'Create Client Assignment' }
]);

// ─── SAVE STATE & TOAST ───────────────────────────────────────────────────
const isSaved = ref(false);
const toastMessage = ref<string | null>(null);

const showToast = (msg: string) => {
  toastMessage.value = msg;
  setTimeout(() => {
    toastMessage.value = null;
  }, 3200);
};

// ─── TAB NAVIGATION (Rule 1 & Rule 4: BaseTabs for 1:N relations) ─────────
const activeTab = ref<'details' | 'allocations'>('details');

const formTabs = computed<BaseTabItem<'details' | 'allocations'>[]>(() => [
  { id: 'details', label: 'Assignment Details' },
  {
    id: 'allocations',
    label: 'Payslip Cost Allocations',
    count: costAllocations.value.length
  }
]);

// ─── MORE MENU DROPDOWN (Rule 4: Draft state support) ─────────────────────
const isMoreMenuOpen = ref(false);
const toggleMoreMenu = () => {
  isMoreMenuOpen.value = !isMoreMenuOpen.value;
};
const closeMoreMenu = () => {
  isMoreMenuOpen.value = false;
};

// ─── FORM DATA MODEL (Strict 1:1 Schema Mapping) ──────────────────────────
const formData = ref<{
  employee_id: number;
  hr_service_agreement_id: number;
  client_branch_entity_id: number | null;
  client_organization_unit_id: number | null;
  client_position_id: number | null;
  client_role_title: string;
  duty_station_admin_unit_id: number | null;
  start_date: string;
  end_date: string;
  assignment_state_lookup_value_id: ClientAssignmentState;
  notes: string;
}>({
  employee_id: 61,
  hr_service_agreement_id: 3,
  client_branch_entity_id: 7,
  client_organization_unit_id: 14,
  client_position_id: 24,
  client_role_title: '',
  duty_station_admin_unit_id: 315,
  start_date: new Date().toISOString().substring(0, 10),
  end_date: '',
  assignment_state_lookup_value_id: 'active',
  notes: ''
});

// ─── PAYSLIP COST ALLOCATION MODEL (1:N Dynamic Sub-Table) ────────────────
export interface EditableAllocationLine {
  id: number;
  uuid?: string;
  target_type: 'entity' | 'org_unit' | 'client_assignment';
  target_entity_id: number | null;
  target_entity_name?: string | null;
  organization_unit_id: number | null;
  organization_unit_name?: string | null;
  client_assignment_id: number | null;
  split_type: 'percent' | 'amount';
  percent: number | null;
  amount: number | null;
  order: number;
  state: 'active' | 'inactive';
  notes?: string;
}

const costAllocations = ref<EditableAllocationLine[]>([
  {
    id: 1,
    target_type: 'client_assignment',
    target_entity_id: null,
    target_entity_name: null,
    organization_unit_id: null,
    organization_unit_name: null,
    client_assignment_id: null,
    split_type: 'percent',
    percent: 100.0,
    amount: null,
    order: 1,
    state: 'active',
    notes: 'Default 100% cost allocation to this client assignment'
  }
]);

const selectedAllocIds = ref<number[]>([]);
const allocationBasis = ref<'percent' | 'amount'>('percent');

// ─── OPTIONS CATALOGS (From HR Schema Designer 1.sql) ─────────────────────
const employeeOptions = [
  { value: 61, label: 'Abebe Kebede Wolde (EMP-0061)' },
  { value: 62, label: 'Almaz Tefera Desta (EMP-0062)' },
  { value: 63, label: 'Dawit Tadesse Mengistu (EMP-0063)' },
  { value: 22, label: 'Hana Mesfin Tadesse (EMP-0022)' },
  { value: 14, label: 'Solomon Bekele Worku (EMP-0014)' }
];

const agreementOptions = computed(() => {
  return serviceAgreementsData.value.map(a => ({
    value: a.id,
    label: `${a.code} — ${a.client_party_name} (${a.agreement_type_lookup_value_id})`
  }));
});

// Selected agreement helper
const selectedAgreement = computed(() => {
  return serviceAgreementsData.value.find(a => a.id === formData.value.hr_service_agreement_id);
});

// Whether client is an internal Haleta tenant
const isTenantClient = computed(() => {
  return !!(selectedAgreement.value && selectedAgreement.value.client_entity_id);
});

// Internal Client Branch Options (Entity granularity)
const clientBranchOptions = [
  { value: 7, label: 'Bole Branch (Entity #7)' },
  { value: 9, label: 'Bahir Dar Branch (Entity #9)' },
  { value: 12, label: 'Piazza Shop (Entity #12)' },
  { value: 1, label: 'Corporate Headquarters (Entity #1)' }
];

// Internal Client Org Unit Options
const clientOrgUnitOptions = [
  { value: 14, label: 'Store Frontline Operations' },
  { value: 10, label: 'Retail Customer Care' },
  { value: 11, label: 'Inventory & Stock Control' },
  { value: 18, label: 'Project X Field Operations' }
];

// Internal Client Job Position Options
const clientPositionOptions = [
  { value: 24, label: 'Senior POS Cashier (POS-0024)' },
  { value: 25, label: 'Retail Customer Attendant (POS-0025)' },
  { value: 26, label: 'Shift Supervisor (POS-0026)' }
];

// Physical Duty Station AdminUnit Options (Rule 13: Exact Location)
const adminUnitOptions = [
  { value: 315, label: 'Bole Sub-City, Addis Ababa (AdminUnit #315)' },
  { value: 305, label: 'Kirkos Sub-City, Addis Ababa (AdminUnit #305)' },
  { value: 401, label: 'Bahir Dar Central, Amhara (AdminUnit #401)' },
  { value: 320, label: 'Debre Birhan Industrial Park, Amhara (AdminUnit #320)' }
];

const stateOptions = [
  { value: 'active', label: 'Active Placement' },
  { value: 'completed', label: 'Completed Placement' },
  { value: 'recalled', label: 'Recalled to Employing Provider' },
  { value: 'terminated', label: 'Terminated Placement' }
];

// ─── PAIRED TARGET SELECTION: TYPE (LEFT) & DESTINATION (RIGHT) ───────────
const handleTargetTypeChange = (row: EditableAllocationLine) => {
  if (row.target_type === 'entity') {
    row.target_entity_id = clientBranchOptions[0]?.value || 7;
    row.target_entity_name = clientBranchOptions[0]?.label || 'Bole Branch (Entity #7)';
    row.organization_unit_id = null;
    row.organization_unit_name = null;
    row.client_assignment_id = null;
  } else if (row.target_type === 'org_unit') {
    row.organization_unit_id = clientOrgUnitOptions[0]?.value || 14;
    row.organization_unit_name = clientOrgUnitOptions[0]?.label || 'Store Frontline Operations';
    row.target_entity_id = null;
    row.target_entity_name = null;
    row.client_assignment_id = null;
  } else {
    row.target_type = 'client_assignment';
    row.target_entity_id = null;
    row.target_entity_name = null;
    row.organization_unit_id = null;
    row.organization_unit_name = null;
    row.client_assignment_id = editId.value || 46;
  }
};

const handleBranchChange = (row: EditableAllocationLine, entityId: number) => {
  row.target_entity_id = entityId;
  const branch = clientBranchOptions.find(b => b.value === entityId);
  row.target_entity_name = branch ? branch.label : null;
};

const handleUnitChange = (row: EditableAllocationLine, unitId: number) => {
  row.organization_unit_id = unitId;
  const unit = clientOrgUnitOptions.find(u => u.value === unitId);
  row.organization_unit_name = unit ? unit.label : null;
};

// ─── ALLOCATION BALANCE METRICS & VALIDATION ───────────────────────────────
const totalPercent = computed(() => {
  return costAllocations.value
    .filter(a => a.split_type === 'percent' && a.state === 'active')
    .reduce((sum, a) => sum + (Number(a.percent) || 0), 0);
});

const totalAmount = computed(() => {
  return costAllocations.value
    .filter(a => a.split_type === 'amount' && a.state === 'active')
    .reduce((sum, a) => sum + (Number(a.amount) || 0), 0);
});

const isPercentBalanced = computed(() => {
  if (costAllocations.value.length === 0) return true;
  if (allocationBasis.value !== 'percent') return true;
  return Math.abs(totalPercent.value - 100.0) < 0.01;
});

// Selection handling
const isAllAllocSelected = computed(() => {
  return (
    costAllocations.value.length > 0 &&
    selectedAllocIds.value.length === costAllocations.value.length
  );
});

const toggleSelectAllAlloc = () => {
  if (isAllAllocSelected.value) {
    selectedAllocIds.value = [];
  } else {
    selectedAllocIds.value = costAllocations.value.map(a => a.id);
  }
};

const toggleAllocSelection = (id: number) => {
  const idx = selectedAllocIds.value.indexOf(id);
  if (idx >= 0) {
    selectedAllocIds.value.splice(idx, 1);
  } else {
    selectedAllocIds.value.push(id);
  }
};

// Add row handler (Rule 11)
const addCostAllocationRow = () => {
  const nextId =
    costAllocations.value.length > 0
      ? Math.max(...costAllocations.value.map(a => a.id)) + 1
      : 1;
  const nextOrder = costAllocations.value.length + 1;
  const currentTotal = totalPercent.value;
  const remainingPercent = Math.max(0, parseFloat((100.0 - currentTotal).toFixed(4)));

  costAllocations.value.push({
    id: nextId,
    target_type: 'entity',
    target_entity_id: 7,
    target_entity_name: 'Bole Branch (Entity #7)',
    organization_unit_id: null,
    organization_unit_name: null,
    client_assignment_id: null,
    split_type: allocationBasis.value,
    percent: allocationBasis.value === 'percent' ? remainingPercent : null,
    amount: allocationBasis.value === 'amount' ? 0 : null,
    order: nextOrder,
    state: 'active',
    notes: ''
  });
};

// Remove row handler
const removeCostAllocationRow = (id: number) => {
  const idx = costAllocations.value.findIndex(a => a.id === id);
  if (idx !== -1) {
    costAllocations.value.splice(idx, 1);
    costAllocations.value.forEach((row, i) => {
      row.order = i + 1;
    });
    const selIdx = selectedAllocIds.value.indexOf(id);
    if (selIdx >= 0) {
      selectedAllocIds.value.splice(selIdx, 1);
    }
  }
};

// Batch delete handler
const handleBatchDeleteAllocations = () => {
  if (confirm(`Remove ${selectedAllocIds.value.length} selected allocation line(s)?`)) {
    costAllocations.value = costAllocations.value.filter(
      a => !selectedAllocIds.value.includes(a.id)
    );
    costAllocations.value.forEach((row, i) => {
      row.order = i + 1;
    });
    selectedAllocIds.value = [];
  }
};

// Switch global allocation basis
const setAllocationBasis = (basis: 'percent' | 'amount') => {
  allocationBasis.value = basis;
  costAllocations.value.forEach(row => {
    row.split_type = basis;
    if (basis === 'percent') {
      if (row.percent === null) row.percent = 100.0 / Math.max(1, costAllocations.value.length);
      row.amount = null;
    } else {
      if (row.amount === null) row.amount = 0;
      row.percent = null;
    }
  });
};

// ─── EXPAND ROW MODAL STATE (Rule 11) ─────────────────────────────────────
const showAllocModal = ref(false);
const activeAllocRow = ref<EditableAllocationLine | null>(null);

const openAllocModal = (row: EditableAllocationLine) => {
  activeAllocRow.value = JSON.parse(JSON.stringify(row));
  showAllocModal.value = true;
};

const closeAllocModal = () => {
  showAllocModal.value = false;
  activeAllocRow.value = null;
};

const saveAllocModal = () => {
  if (activeAllocRow.value) {
    const idx = costAllocations.value.findIndex(a => a.id === activeAllocRow.value!.id);
    if (idx !== -1) {
      if (activeAllocRow.value.target_type === 'entity') {
        const branch = clientBranchOptions.find(
          b => b.value === activeAllocRow.value!.target_entity_id
        );
        activeAllocRow.value.target_entity_name = branch ? branch.label : null;
        activeAllocRow.value.organization_unit_id = null;
        activeAllocRow.value.organization_unit_name = null;
        activeAllocRow.value.client_assignment_id = null;
      } else if (activeAllocRow.value.target_type === 'org_unit') {
        const unit = clientOrgUnitOptions.find(
          u => u.value === activeAllocRow.value!.organization_unit_id
        );
        activeAllocRow.value.organization_unit_name = unit ? unit.label : null;
        activeAllocRow.value.target_entity_id = null;
        activeAllocRow.value.target_entity_name = null;
        activeAllocRow.value.client_assignment_id = null;
      } else {
        activeAllocRow.value.target_entity_id = null;
        activeAllocRow.value.target_entity_name = null;
        activeAllocRow.value.organization_unit_id = null;
        activeAllocRow.value.organization_unit_name = null;
      }

      costAllocations.value[idx] = { ...activeAllocRow.value };
    }
  }
  closeAllocModal();
};

// ─── INITIALIZATION / EDIT PREFILL ────────────────────────────────────────
onMounted(() => {
  if (route.query.agreement_id) {
    formData.value.hr_service_agreement_id = Number(route.query.agreement_id);
  }

  if (editId.value) {
    const existing = clientAssignmentsData.value.find(a => a.id === editId.value);
    if (existing) {
      formData.value = {
        employee_id: existing.employee_id,
        hr_service_agreement_id: existing.hr_service_agreement_id,
        client_branch_entity_id: existing.client_branch_entity_id,
        client_organization_unit_id: existing.client_organization_unit_id,
        client_position_id: existing.client_position_id,
        client_role_title: existing.client_role_title || '',
        duty_station_admin_unit_id: existing.duty_station_admin_unit_id,
        start_date: existing.start_date,
        end_date: existing.end_date || '',
        assignment_state_lookup_value_id: existing.assignment_state_lookup_value_id,
        notes: existing.notes || ''
      };

      if (existing.cost_allocations && existing.cost_allocations.length > 0) {
        costAllocations.value = existing.cost_allocations.map(ca => ({
          id: ca.id,
          uuid: ca.uuid,
          target_type: ca.target_entity_id
            ? 'entity'
            : ca.organization_unit_id
            ? 'org_unit'
            : 'client_assignment',
          target_entity_id: ca.target_entity_id,
          target_entity_name: ca.target_entity_name,
          organization_unit_id: ca.organization_unit_id,
          organization_unit_name: ca.organization_unit_name,
          client_assignment_id: ca.client_assignment_id,
          split_type: ca.amount !== null && ca.amount !== undefined ? 'amount' : 'percent',
          percent: ca.percent !== null ? ca.percent : 100.0,
          amount: ca.amount,
          order: ca.order || 1,
          state: ca.state || 'active',
          notes: ''
        }));
        if (costAllocations.value.some(r => r.split_type === 'amount')) {
          allocationBasis.value = 'amount';
        }
      }

      isSaved.value = true;
    }
  }
});

// ─── SAVE HANDLER (Rule 27: Plain text "Save", zero icon) ─────────────────
const handleSave = (stateOverride?: ClientAssignmentState) => {
  if (!formData.value.employee_id || !formData.value.hr_service_agreement_id) {
    alert('Please select both the Leased Employee and the Governing Service Agreement.');
    return;
  }
  if (!formData.value.start_date) {
    alert('Please specify the placement start date.');
    return;
  }

  // Schema rule validation: if percentage rows exist, verify balance
  if (allocationBasis.value === 'percent' && costAllocations.value.length > 0 && !isPercentBalanced.value) {
    if (
      !confirm(
        `Warning: Total cost allocation percentages sum to ${totalPercent.value.toFixed(
          2
        )}%, which does not equal 100.00%. Do you wish to proceed anyway?`
      )
    ) {
      activeTab.value = 'allocations';
      return;
    }
  }

  const finalState = stateOverride || formData.value.assignment_state_lookup_value_id;
  const ag = selectedAgreement.value;
  const emp = employeeOptions.find(e => e.value === formData.value.employee_id);
  const branch = clientBranchOptions.find(b => b.value === formData.value.client_branch_entity_id);
  const unit = clientOrgUnitOptions.find(u => u.value === formData.value.client_organization_unit_id);
  const pos = clientPositionOptions.find(p => p.value === formData.value.client_position_id);
  const adminUnit = adminUnitOptions.find(a => a.value === formData.value.duty_station_admin_unit_id);

  // Map allocations back to authoritative schema line format
  const mappedAllocations: PayslipCostAllocationRecord[] = costAllocations.value.map((a, idx) => ({
    id: a.id || Math.floor(Math.random() * 1000) + 100,
    uuid: a.uuid || `pca-uuid-${idx + 1}`,
    tenant_id: 1,
    entity_id: 20,
    payslip_id: 7780,
    payslip_number: 'PAY-2026-ALLOC',
    target_entity_id: a.target_type === 'entity' ? a.target_entity_id : null,
    target_entity_name: a.target_type === 'entity' ? a.target_entity_name || null : null,
    organization_unit_id: a.target_type === 'org_unit' ? a.organization_unit_id : null,
    organization_unit_name: a.target_type === 'org_unit' ? a.organization_unit_name || null : null,
    client_assignment_id: a.target_type === 'client_assignment' ? editId.value || 46 : null,
    percent: a.split_type === 'percent' ? Number(a.percent) : null,
    amount: a.split_type === 'amount' ? Number(a.amount) : null,
    order: idx + 1,
    state: a.state
  }));

  if (isEditMode.value && editId.value) {
    updateClientAssignment(editId.value, {
      employee_id: formData.value.employee_id,
      employee_code: emp ? emp.label.split('(')[1].replace(')', '') : 'EMP-0061',
      employee_name: emp ? emp.label.split(' (')[0] : 'Employee',
      hr_service_agreement_id: formData.value.hr_service_agreement_id,
      hr_service_agreement_code: ag ? ag.code : 'HSA-2026-0003',
      client_party_id: ag ? ag.client_party_id : 940,
      client_party_name: ag ? ag.client_party_name : 'Client Organization',
      is_tenant_client: isTenantClient.value,
      client_branch_entity_id: isTenantClient.value ? formData.value.client_branch_entity_id : null,
      client_branch_name: isTenantClient.value && branch ? branch.label : null,
      client_organization_unit_id: isTenantClient.value
        ? formData.value.client_organization_unit_id
        : null,
      client_organization_unit_name: isTenantClient.value && unit ? unit.label : null,
      client_position_id: isTenantClient.value ? formData.value.client_position_id : null,
      client_position_name: isTenantClient.value && pos ? pos.label.split(' (')[0] : null,
      client_role_title: !isTenantClient.value ? formData.value.client_role_title.trim() : null,
      duty_station_admin_unit_id: formData.value.duty_station_admin_unit_id,
      duty_station_name: adminUnit ? adminUnit.label : null,
      start_date: formData.value.start_date,
      end_date: formData.value.end_date || null,
      assignment_state_lookup_value_id: finalState,
      notes: formData.value.notes.trim() || null,
      cost_allocations: mappedAllocations
    });
    isSaved.value = true;
    showToast('Client Assignment updated successfully.');
  } else {
    createClientAssignment({
      tenant_id: 1,
      employee_id: formData.value.employee_id,
      employee_code: emp ? emp.label.split('(')[1].replace(')', '') : 'EMP-0061',
      employee_name: emp ? emp.label.split(' (')[0] : 'Employee',
      hr_service_agreement_id: formData.value.hr_service_agreement_id,
      hr_service_agreement_code: ag ? ag.code : 'HSA-2026-0003',
      client_party_id: ag ? ag.client_party_id : 940,
      client_party_name: ag ? ag.client_party_name : 'Client Organization',
      is_tenant_client: isTenantClient.value,
      client_branch_entity_id: isTenantClient.value ? formData.value.client_branch_entity_id : null,
      client_branch_name: isTenantClient.value && branch ? branch.label : null,
      client_organization_unit_id: isTenantClient.value
        ? formData.value.client_organization_unit_id
        : null,
      client_organization_unit_name: isTenantClient.value && unit ? unit.label : null,
      client_position_id: isTenantClient.value ? formData.value.client_position_id : null,
      client_position_name: isTenantClient.value && pos ? pos.label.split(' (')[0] : null,
      client_role_title: !isTenantClient.value ? formData.value.client_role_title.trim() : null,
      duty_station_admin_unit_id: formData.value.duty_station_admin_unit_id,
      duty_station_name: adminUnit ? adminUnit.label : null,
      start_date: formData.value.start_date,
      end_date: formData.value.end_date || null,
      assignment_state_lookup_value_id: finalState,
      notes: formData.value.notes.trim() || null,
      cost_allocations: mappedAllocations,
      user_id: 7,
      state: 'active'
    });
    isSaved.value = true;
    showToast('Client Assignment created successfully.');
  }

  setTimeout(() => {
    router.push('/hr/client-assignments');
  }, 900);
};

const handleSaveDraft = () => {
  closeMoreMenu();
  handleSave('draft');
};

const handleClear = () => {
  if (confirm('Are you sure you want to clear this client assignment form?')) {
    formData.value = {
      employee_id: 61,
      hr_service_agreement_id: 3,
      client_branch_entity_id: 7,
      client_organization_unit_id: 14,
      client_position_id: 24,
      client_role_title: '',
      duty_station_admin_unit_id: 315,
      start_date: new Date().toISOString().substring(0, 10),
      end_date: '',
      assignment_state_lookup_value_id: 'active',
      notes: ''
    };
    costAllocations.value = [
      {
        id: 1,
        target_type: 'client_assignment',
        target_entity_id: null,
        target_entity_name: null,
        organization_unit_id: null,
        organization_unit_name: null,
        client_assignment_id: null,
        split_type: 'percent',
        percent: 100.0,
        amount: null,
        order: 1,
        state: 'active',
        notes: 'Default assignment allocation'
      }
    ];
    isSaved.value = false;
  }
};
</script>

<template>
  <div class="client-assignment-create-page" @click="closeMoreMenu">
    <!-- Toast Notification -->
    <transition name="toast">
      <div v-if="toastMessage" class="toast-popup">
        <CheckCircle2 :size="16" class="toast-icon" />
        <span>{{ toastMessage }}</span>
      </div>
    </transition>

    <!-- Top Action Bar (Rule 4) -->
    <div class="top-action-bar">
      <div class="left-nav-meta">
        <AppBreadcrumb :items="breadcrumbItems">
          <template #badge>
            <SaveStateBadge :saved="isSaved" />
          </template>
        </AppBreadcrumb>
      </div>

      <div class="right-actions-cluster" @click.stop>
        <!-- 3-Dots More Menu for Draft State (Rule 4) -->
        <div class="relative-more-dropdown">
          <AppButton
            variant="outline"
            size="sm"
            iconOnly
            title="More Options"
            @click="toggleMoreMenu"
          >
            <MoreVertical :size="16" />
          </AppButton>

          <div v-if="isMoreMenuOpen" class="more-dropdown-menu">
            <button
              type="button"
              class="dropdown-action-btn"
              @click="handleSaveDraft"
            >
              <FileText :size="14" />
              <span>Save as Draft</span>
            </button>
          </div>
        </div>

        <!-- Clear Form Secondary Button -->
        <AppButton
          variant="outline"
          size="sm"
          @click="handleClear"
        >
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>

        <!-- Save Primary Button (Rule 27: Plain text "Save", zero icon) -->
        <AppButton
          variant="primary"
          size="sm"
          @click="() => handleSave()"
        >
          Save
        </AppButton>
      </div>
    </div>

    <!-- Capsule Tabs: Placement Details vs Payslip Cost Allocations (Rule 1 & Rule 4) -->
    <div class="form-tabs-container">
      <BaseTabs v-model="activeTab" :tabs="formTabs" />
    </div>

    <!-- Tab 1: Placement Details -->
    <div v-if="activeTab === 'details'" class="form-cards-layout">
      <!-- Card 1: Worker & Umbrella Contract -->
      <div class="creation-card">
        <div class="card-header">
          <Users :size="18" class="card-header-icon" />
          <div class="card-header-text">
            <h3 class="card-title">Leased Worker & Governing HR Service Agreement</h3>
            <p class="card-subtitle">
              Select the employed personnel to deploy and link the corresponding umbrella contract carrying client terms.
            </p>
          </div>
        </div>

        <div class="form-grid-2">
          <!-- Leased Employee -->
          <FormSelect
            v-model="formData.employee_id"
            label="Leased Personnel / Worker"
            :options="employeeOptions"
            required
          />

          <!-- Service Agreement (Agreement sync) -->
          <FormSelect
            v-model="formData.hr_service_agreement_id"
            label="Governing HR Service Agreement"
            :options="agreementOptions"
            hint="Carries commercial client organization, payroll responsibility, and service fee models."
            required
          />
        </div>

        <!-- Selected Agreement Context Callout -->
        <div v-if="selectedAgreement" class="agreement-info-box">
          <div class="info-tag-row">
            <span class="info-tag-label">Client Party:</span>
            <span class="info-tag-value font-medium">{{ selectedAgreement.client_party_name }}</span>
            <span class="info-tag-sep">•</span>
            <span class="info-tag-label">Tenancy Architecture:</span>
            <span class="info-tag-badge" :class="isTenantClient ? 'badge-tenant' : 'badge-external'">
              {{ isTenantClient ? 'Internal Haleta Tenant Structure' : 'External Commercial Counterparty' }}
            </span>
          </div>
        </div>
      </div>

      <!-- Card 2: Client Structure & Seat (Dynamic: Internal Tenant vs External Client) -->
      <!-- Internal Tenant Structure (Entity Branch + Org Unit + Job Position) -->
      <div v-if="isTenantClient" class="creation-card">
        <div class="card-header">
          <Building2 :size="18" class="card-header-icon" />
          <div class="card-header-text">
            <h3 class="card-title">Client Internal Organization Seat (Tenant Structure)</h3>
            <p class="card-subtitle">
              Because the client is modeled as an internal tenant in Haleta ERP, assign the worker into the client's actual branch, unit, and position.
            </p>
          </div>
        </div>

        <div class="form-grid-3">
          <!-- Client Branch Entity -->
          <FormSelect
            v-model="formData.client_branch_entity_id"
            label="Client Branch Entity (Branch Granularity)"
            :options="clientBranchOptions"
            required
          />

          <!-- Client Org Unit -->
          <FormSelect
            v-model="formData.client_organization_unit_id"
            label="Client Organization Unit"
            :options="clientOrgUnitOptions"
            required
          />

          <!-- Client Job Position -->
          <FormSelect
            v-model="formData.client_position_id"
            label="Client Job Position Seat"
            :options="clientPositionOptions"
            required
          />
        </div>
      </div>

      <!-- External Client Structure (Verbatim Role Title + Physical Duty Station AdminUnit) -->
      <div v-else class="creation-card">
        <div class="card-header">
          <Briefcase :size="18" class="card-header-icon" />
          <div class="card-header-text">
            <h3 class="card-title">External Client Role & Physical Duty Station</h3>
            <p class="card-subtitle">
              External clients do not have internal organizational units modeled in the database; record verbatim job title and physical location.
            </p>
          </div>
        </div>

        <div class="form-grid-2">
          <!-- External Role Title -->
          <FormInput
            v-model="formData.client_role_title"
            label="Client-Facing Role Title (Verbatim)"
            required
          />

          <!-- Duty Station AdminUnit (Rule 13: Exact Location) -->
          <FormSelect
            v-model="formData.duty_station_admin_unit_id"
            label="Physical Duty Station (Exact Location)"
            :options="adminUnitOptions"
            required
          />
        </div>
      </div>

      <!-- Card 3: Placement Timeline & Operational State -->
      <div class="creation-card">
        <div class="card-header">
          <Calendar :size="18" class="card-header-icon" />
          <div class="card-header-text">
            <h3 class="card-title">Placement Duration Timeline & Operational State</h3>
            <p class="card-subtitle">
              Specify the placement start date, scheduled conclusion date, and operational state.
            </p>
          </div>
        </div>

        <div class="form-grid-3">
          <FormInput
            v-model="formData.start_date"
            type="date"
            label="Effective Start Date"
            required
          />

          <FormInput
            v-model="formData.end_date"
            type="date"
            label="Concluding Date"
            hint="Leave blank if ongoing or open-ended placement."
          />

          <FormSelect
            v-model="formData.assignment_state_lookup_value_id"
            label="Placement Operational State"
            :options="stateOptions"
            required
          />
        </div>
      </div>

      <!-- Card 4: Administrative Notes -->
      <div class="creation-card">
        <div class="card-header">
          <FileText :size="18" class="card-header-icon" />
          <div class="card-header-text">
            <h3 class="card-title">Administrative Instructions & Notes</h3>
            <p class="card-subtitle">
              Record specific operational directives, project codes, or statutory compliance remarks.
            </p>
          </div>
        </div>

        <!-- Standardized Rich Text Component -->
        <FormRichText
          v-model="formData.notes"
          placeholder="Record specific operational directives, project codes, or statutory compliance remarks..."
          :max-length="5000"
        />
      </div>
    </div>

    <!-- Tab 2: Payslip Cost Allocations (Dynamic Child Sub-Table, Rule 11) -->
    <div v-else-if="activeTab === 'allocations'" class="form-cards-layout">
      <!-- Allocations Overview Card & Control Strip -->
      <div class="creation-card">
        <div class="alloc-header-cluster">
          <div class="card-header">
            <DollarSign :size="18" class="card-header-icon" />
            <div class="card-header-text">
              <h3 class="card-title">Payslip Cost Allocation Splits (Share of Employer Cost)</h3>
              <p class="card-subtitle">
                Configure one row per share of employer gross payslip cost, split across branch entities, org units, or client projects. (Schema note: exactly ONE target set per row; no rows = 100% to this client assignment entity).
              </p>
            </div>
          </div>

          <!-- Basis Mode Selector & Balance Status -->
          <div class="alloc-summary-bar">
            <!-- Mode Switcher -->
            <div class="alloc-mode-pills">
              <button
                type="button"
                class="mode-pill-btn"
                :class="{ active: allocationBasis === 'percent' }"
                @click="setAllocationBasis('percent')"
              >
                <Percent :size="13" />
                <span>Percentage Share (%)</span>
              </button>
              <button
                type="button"
                class="mode-pill-btn"
                :class="{ active: allocationBasis === 'amount' }"
                @click="setAllocationBasis('amount')"
              >
                <DollarSign :size="13" />
                <span>Fixed Currency (ETB)</span>
              </button>
            </div>

            <!-- Balance Indicator Meter -->
            <div v-if="allocationBasis === 'percent'" class="balance-status-container">
              <div
                v-if="costAllocations.length === 0 || isPercentBalanced"
                class="balance-pill balanced"
              >
                <CheckCircle2 :size="14" />
                <span>Balanced: 100.00% Allocated</span>
              </div>
              <div
                v-else-if="totalPercent < 100"
                class="balance-pill warning"
              >
                <AlertCircle :size="14" />
                <span>Unallocated: {{ (100.0 - totalPercent).toFixed(2) }}% remaining (Current: {{ totalPercent.toFixed(2) }}%)</span>
              </div>
              <div
                v-else
                class="balance-pill error"
              >
                <AlertCircle :size="14" />
                <span>Over-allocated: {{ totalPercent.toFixed(2) }}% (Exceeds 100% by {{ (totalPercent - 100.0).toFixed(2) }}%)</span>
              </div>
            </div>

            <div v-else class="balance-status-container">
              <div class="balance-pill neutral">
                <Layers :size="14" />
                <span>Total Fixed Employer Cost: ETB {{ totalAmount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Dynamic Child Sub-Table (Rule 11) -->
        <div class="child-subtable-block">
          <div class="child-table-wrapper">
            <table class="child-table">
              <thead>
                <tr>
                  <!-- Checkbox Column -->
                  <th class="child-th child-th-check">
                    <input
                      type="checkbox"
                      :checked="isAllAllocSelected"
                      class="custom-checkbox"
                      @change="toggleSelectAllAlloc"
                    />
                  </th>
                  <!-- Sequential No Column -->
                  <th class="child-th child-th-no">#</th>
                  <!-- 1. Left: Target Type Selection -->
                  <th class="child-th child-th-type">Target Type</th>
                  <!-- 2. Right: Cascading Destination Selection -->
                  <th class="child-th child-th-dest">Target Destination</th>
                  <!-- Split Value Column -->
                  <th class="child-th child-th-val">
                    {{ allocationBasis === 'percent' ? 'Split Percentage (%)' : 'Fixed Amount (ETB)' }}
                  </th>
                  <!-- Priority / Order -->
                  <th class="child-th child-th-order">Order</th>
                  <!-- State Column -->
                  <th class="child-th child-th-state">State</th>
                  <!-- Row Actions -->
                  <th class="child-th child-th-actions">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="(row, idx) in costAllocations"
                  :key="row.id"
                  class="child-table-row"
                  :class="{ 'row-selected': selectedAllocIds.includes(row.id) }"
                >
                  <!-- Selection Checkbox -->
                  <td class="child-td child-td-check">
                    <input
                      type="checkbox"
                      :checked="selectedAllocIds.includes(row.id)"
                      class="custom-checkbox"
                      @change="toggleAllocSelection(row.id)"
                    />
                  </td>

                  <!-- Sequential Row Index -->
                  <td class="child-td child-td-no">
                    <span class="row-index-text">{{ idx + 1 }}</span>
                  </td>

                  <!-- 1. Left: Target Type Dropdown -->
                  <td class="child-td child-td-type">
                    <FormSelect
                      v-model="row.target_type"
                      :options="[
                        { value: 'client_assignment', label: 'Client Assignment' },
                        { value: 'entity', label: 'Branch / Entity' },
                        { value: 'org_unit', label: 'Organization Unit' }
                      ]"
                      variant="cell"
                      placeholder="Select Type"
                      @update:model-value="() => handleTargetTypeChange(row)"
                    />
                  </td>

                  <!-- 2. Right: Filtered Target Destination Dropdown -->
                  <td class="child-td child-td-dest">
                    <!-- Case A: Client Assignment Direct -->
                    <div v-if="row.target_type === 'client_assignment'" class="static-dest-pill">
                      <span>This Client Assignment (Direct)</span>
                    </div>

                    <!-- Case B: Branch / Entity Options -->
                    <FormSelect
                      v-else-if="row.target_type === 'entity'"
                      :model-value="row.target_entity_id"
                      :options="clientBranchOptions"
                      variant="cell"
                      placeholder="Select Branch"
                      @update:model-value="(val) => handleBranchChange(row, Number(val))"
                    />

                    <!-- Case C: Organization Unit Options -->
                    <FormSelect
                      v-else-if="row.target_type === 'org_unit'"
                      :model-value="row.organization_unit_id"
                      :options="clientOrgUnitOptions"
                      variant="cell"
                      placeholder="Select Unit"
                      @update:model-value="(val) => handleUnitChange(row, Number(val))"
                    />
                  </td>

                  <!-- Split Value Input (Percentage or Amount) -->
                  <td class="child-td child-td-val">
                    <div class="input-with-suffix">
                      <input
                        v-if="row.split_type === 'percent'"
                        v-model.number="row.percent"
                        type="number"
                        step="0.01"
                        min="0"
                        max="100"
                        class="child-inline-input text-right"
                      />
                      <input
                        v-else
                        v-model.number="row.amount"
                        type="number"
                        step="0.01"
                        min="0"
                        class="child-inline-input text-right"
                      />
                      <span class="input-unit-suffix">{{ row.split_type === 'percent' ? '%' : 'ETB' }}</span>
                    </div>
                  </td>

                  <!-- Sequence Order -->
                  <td class="child-td child-td-order">
                    <input
                      v-model.number="row.order"
                      type="number"
                      min="1"
                      class="child-inline-input text-center w-16"
                    />
                  </td>

                  <!-- State Selector -->
                  <td class="child-td child-td-state">
                    <FormSelect
                      v-model="row.state"
                      :options="[
                        { value: 'active', label: 'Active' },
                        { value: 'inactive', label: 'Inactive' }
                      ]"
                      variant="cell"
                      placeholder="Select State"
                    />
                  </td>

                  <!-- Row Actions Group (Rule 11: Expand modal + Remove) -->
                  <td class="child-td child-td-actions">
                    <div class="row-actions-group">
                      <button
                        type="button"
                        class="btn-row-expand"
                        title="Expand Details"
                        @click="openAllocModal(row)"
                      >
                        <Maximize2 :size="13" />
                      </button>
                      <button
                        type="button"
                        class="btn-row-remove"
                        title="Remove Line"
                        @click="removeCostAllocationRow(row.id)"
                      >
                        <Trash2 :size="13" />
                      </button>
                    </div>
                  </td>
                </tr>

                <!-- Empty State -->
                <tr v-if="costAllocations.length === 0">
                  <td colspan="8" class="child-td-empty">
                    <div class="empty-alloc-msg">
                      <Layers :size="24" class="empty-alloc-icon" />
                      <p class="empty-alloc-title">No explicit cost allocation splits configured</p>
                      <p class="empty-alloc-desc">
                        Under Section 19 schema rules, 100% of payslip employer cost will default directly to this client assignment entity.
                      </p>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Bottom Add Row Action Bar (Rule 11: .btn-add-row) -->
          <div class="add-row-action-bar">
            <button
              type="button"
              class="btn-add-row"
              @click="addCostAllocationRow"
            >
              <Plus :size="13" />
              <span>Add Allocation Line</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Floating Batch Action Bar (Rule 11) -->
    <TableFloatingBar
      :show="selectedAllocIds.length > 0"
      :selected-count="selectedAllocIds.length"
      @delete="handleBatchDeleteAllocations"
      @close="selectedAllocIds = []"
    />

    <!-- EXPAND ROW MODAL (Standard Haleta ERP Pattern) -->
    <div
      v-if="showAllocModal && activeAllocRow"
      class="row-modal-overlay"
      @click="closeAllocModal"
    >
      <div class="row-modal-container" @click.stop>
        <div class="row-modal-header">
          <div class="row-modal-header-text">
            <h3 class="row-modal-title">Edit Payslip Cost Allocation Line</h3>
            <p class="row-modal-subtitle">
              Inspect or adjust the destination bucket and accounting share for line order #{{ activeAllocRow.order }}.
            </p>
          </div>
          <button type="button" class="btn-modal-close" @click="closeAllocModal">
            <X :size="16" />
          </button>
        </div>

        <div class="row-modal-body">
          <div class="modal-form-grid">
            <!-- Target Destination Type -->
            <div class="modal-form-group">
              <FormSelect
                v-model="activeAllocRow.target_type"
                label="Target Bucket Destination Type"
                :options="[
                  { value: 'client_assignment', label: 'Client Assignment (This Placement Direct)' },
                  { value: 'entity', label: 'Client Branch Entity (Target Branch Granularity)' },
                  { value: 'org_unit', label: 'Client Organization Unit (Unit Granularity)' }
                ]"
                placeholder="Select Destination Type"
              />
            </div>

            <!-- Target Branch Entity (if target_type === 'entity') -->
            <div v-if="activeAllocRow.target_type === 'entity'" class="modal-form-group">
              <FormSelect
                v-model="activeAllocRow.target_entity_id"
                label="Target Client Branch Entity"
                :options="clientBranchOptions"
                placeholder="Select Branch"
              />
            </div>

            <!-- Target Org Unit (if target_type === 'org_unit') -->
            <div v-if="activeAllocRow.target_type === 'org_unit'" class="modal-form-group">
              <FormSelect
                v-model="activeAllocRow.organization_unit_id"
                label="Target Organization Unit"
                :options="clientOrgUnitOptions"
                placeholder="Select Organization Unit"
              />
            </div>

            <!-- Allocation Share / Amount -->
            <div class="modal-form-grid-2">
              <div class="modal-form-group">
                <FormSelect
                  v-model="activeAllocRow.split_type"
                  label="Share Basis"
                  :options="[
                    { value: 'percent', label: 'Percentage (%)' },
                    { value: 'amount', label: 'Fixed Amount (ETB)' }
                  ]"
                  placeholder="Select Basis"
                />
              </div>

              <div class="modal-form-group">
                <label class="modal-label">
                  {{ activeAllocRow.split_type === 'percent' ? 'Split Percentage (%)' : 'Fixed Amount (ETB)' }}
                </label>
                <input
                  v-if="activeAllocRow.split_type === 'percent'"
                  v-model.number="activeAllocRow.percent"
                  type="number"
                  step="0.01"
                  min="0"
                  max="100"
                  class="modal-input"
                />
                <input
                  v-else
                  v-model.number="activeAllocRow.amount"
                  type="number"
                  step="0.01"
                  min="0"
                  class="modal-input"
                />
              </div>
            </div>

            <div class="modal-form-grid-2">
              <div class="modal-form-group">
                <label class="modal-label">Evaluation Order</label>
                <input
                  v-model.number="activeAllocRow.order"
                  type="number"
                  min="1"
                  class="modal-input"
                />
              </div>

              <div class="modal-form-group">
                <FormSelect
                  v-model="activeAllocRow.state"
                  label="State"
                  :options="[
                    { value: 'active', label: 'Active' },
                    { value: 'inactive', label: 'Inactive' }
                  ]"
                  placeholder="Select State"
                />
              </div>
            </div>
          </div>
        </div>

        <div class="row-modal-footer">
          <AppButton variant="outline" size="sm" @click="closeAllocModal">
            Cancel
          </AppButton>
          <AppButton variant="primary" size="sm" @click="saveAllocModal">
            Apply Changes
          </AppButton>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.client-assignment-create-page {
  padding: 0;
  background-color: #f8fafc;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
}

/* Toast */
.toast-popup {
  position: fixed;
  top: 24px;
  right: 28px;
  z-index: 1000;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 18px;
  background-color: #0b529c;
  color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.15);
  font-size: 13.5px;
  font-weight: 500;
}

.toast-enter-active,
.toast-leave-active {
  transition: all 0.25s ease;
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

/* Top Action Bar (Rule 4) */
.top-action-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding-bottom: 2px;
}

.left-nav-meta {
  display: flex;
  align-items: center;
  gap: 14px;
}

.right-actions-cluster {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* More Dots Menu (Rule 4) */
.relative-more-dropdown {
  position: relative;
}

.btn-more-dots {
  width: 36px;
  height: 36px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-more-dots:hover {
  background-color: #f1f5f9;
  border-color: #cbd5e1;
}

.more-dropdown-menu {
  position: absolute;
  left: 0;
  top: calc(100% + 4px);
  width: 170px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  padding: 4px;
  z-index: 50;
  display: flex;
  flex-direction: column;
}

.dropdown-action-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  border: none;
  background: transparent;
  border-radius: 6px;
  font-size: 13px;
  color: #404040;
  cursor: pointer;
  text-align: left;
}

.dropdown-action-btn:hover {
  background-color: #f1f5f9;
  color: #0b529c;
}

/* Secondary Button (Clear Form) */
.btn-secondary-clear {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-secondary-clear:hover {
  background-color: #fef2f2;
  border-color: #fecaca;
  color: #dc2626;
}

/* Primary Button (Rule 27: strictly plain text "Save", zero icon) */
.btn-primary-save {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 36px;
  padding: 0 24px;
  background-color: #0b529c;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
  transition: background-color 0.15s;
}

.btn-primary-save:hover {
  background-color: #083e77;
}

/* Form Tabs Container */
.form-tabs-container {
  display: flex;
  margin-bottom: 2px;
}

/* Cards Layout */
.form-cards-layout {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.creation-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.card-header {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.card-header-icon {
  color: #0b529c;
  margin-top: 2px;
  flex-shrink: 0;
}

.card-header-text {
  display: flex;
  flex-direction: column;
  gap: 3px;
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
  margin: 0;
  line-height: 1.45;
}

/* Callout Box */
.agreement-info-box {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 14px;
}

.info-tag-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12.5px;
}

.info-tag-label {
  color: #737373;
}

.info-tag-value {
  color: #404040;
}

.info-tag-sep {
  color: #cbd5e1;
}

.info-tag-badge {
  padding: 2px 8px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 500;
}

.badge-tenant {
  background-color: #eff6ff;
  color: #0b529c;
}

.badge-external {
  background-color: #ecfdf5;
  color: #059669;
}

/* Grids */
.form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

@media (max-width: 1024px) {
  .form-grid-2,
  .form-grid-3 {
    grid-template-columns: 1fr;
  }
}

/* Rich Editor Wrapper */
.rich-editor-wrapper {
  display: flex;
  flex-direction: column;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  background-color: #ffffff;
}

.editor-toolbar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px 10px;
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.editor-tool-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  border-radius: 4px;
  color: #64748b;
  cursor: pointer;
  transition: all 0.12s;
}

.editor-tool-btn:hover {
  background-color: #e2e8f0;
  color: #404040;
}

.toolbar-sep {
  width: 1px;
  height: 16px;
  background-color: #cbd5e1;
  margin: 0 4px;
}

.editor-textarea {
  width: 100%;
  padding: 12px 14px;
  border: none;
  font-size: 13.5px;
  font-family: inherit;
  color: #404040;
  line-height: 1.5;
  resize: vertical;
  outline: none;
}

.editor-footer {
  display: flex;
  justify-content: flex-end;
  padding: 6px 12px;
  background-color: #f8fafc;
  border-top: 1px solid #f1f5f9;
}

.char-counter {
  font-size: 11.5px;
  color: #737373;
}

/* ─── ALLOCATION TAB SPECIFIC STYLES ─────────────────────────────────────── */
.alloc-header-cluster {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.alloc-summary-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 12px 16px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  flex-wrap: wrap;
}

.alloc-mode-pills {
  display: flex;
  align-items: center;
  gap: 6px;
  background-color: #ffffff;
  padding: 3px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.mode-pill-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 28px;
  padding: 0 12px;
  border: none;
  background: transparent;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s;
}

.mode-pill-btn.active {
  background-color: #0b529c;
  color: #ffffff;
}

.balance-status-container {
  display: flex;
  align-items: center;
}

.balance-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px;
  border-radius: 9999px;
  font-size: 12px;
  font-weight: 500;
}

.balance-pill.balanced {
  background-color: #ecfdf5;
  color: #059669;
}

.balance-pill.warning {
  background-color: #fffbeb;
  color: #d97706;
}

.balance-pill.error {
  background-color: #fef2f2;
  color: #dc2626;
}

.balance-pill.neutral {
  background-color: #eff6ff;
  color: #0b529c;
}

/* Child Sub-Table Styles (Rule 11) */
.child-subtable-block {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.child-table-wrapper {
  overflow-x: auto;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
}

.child-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.child-th {
  height: 34px;
  padding: 6px 12px;
  background-color: #f8fafc;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.child-td {
  padding: 8px 12px;
  border-bottom: 1px solid #f1f5f9;
  color: #404040;
  vertical-align: middle;
}

.child-table-row:hover {
  background-color: #f8fafc;
}

.child-table-row.row-selected {
  background-color: #f0f7ff;
}

.child-th-check,
.child-td-check {
  width: 40px;
  text-align: center;
}

.child-th-no,
.child-td-no {
  width: 44px;
  text-align: center;
}

.child-th-type {
  width: 170px;
}

.child-th-dest {
  min-width: 240px;
}

.static-dest-pill {
  display: inline-flex;
  align-items: center;
  height: 32px;
  padding: 0 10px;
  background-color: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 12.5px;
  color: #404040;
  font-weight: 500;
  width: 100%;
  box-sizing: border-box;
}

.child-th-val {
  width: 170px;
}

.child-th-order {
  width: 90px;
  text-align: center;
}

.child-th-state {
  width: 120px;
}

.child-th-actions,
.child-td-actions {
  width: 90px;
  text-align: center;
}

.row-index-text {
  font-size: 12px;
  color: #737373;
  font-weight: 500;
}

.custom-checkbox {
  width: 16px;
  height: 16px;
  cursor: pointer;
  accent-color: #0b529c;
  border-radius: 4px;
}

.child-inline-select,
.child-inline-input {
  height: 32px;
  padding: 0 10px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  font-size: 13px;
  color: #404040;
  background-color: #ffffff;
  outline: none;
  width: 100%;
  box-sizing: border-box;
}

.child-inline-select:focus,
.child-inline-input:focus {
  border-color: #0b529c;
}

.input-with-suffix {
  position: relative;
  display: flex;
  align-items: center;
}

.input-with-suffix .child-inline-input {
  padding-right: 32px;
}

.input-unit-suffix {
  position: absolute;
  right: 10px;
  font-size: 11.5px;
  font-weight: 500;
  color: #94a3b8;
  pointer-events: none;
}

.text-right {
  text-align: right;
}

.text-center {
  text-align: center;
}

.w-16 {
  width: 64px !important;
}

.w-24 {
  width: 96px !important;
}

.row-actions-group {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

.btn-row-expand,
.btn-row-remove {
  width: 26px;
  height: 26px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  border-radius: 4px;
  cursor: pointer;
  color: #94a3b8;
  transition: all 0.12s;
}

.btn-row-expand:hover {
  background-color: #e0f2fe;
  color: #0284c7;
}

.btn-row-remove:hover {
  background-color: #fee2e2;
  color: #ef4444;
}

.child-td-empty {
  text-align: center;
  padding: 32px 16px;
}

.empty-alloc-msg {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.empty-alloc-icon {
  color: #94a3b8;
}

.empty-alloc-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.empty-alloc-desc {
  font-size: 12px;
  color: #737373;
  margin: 0;
  max-width: 480px;
}

.add-row-action-bar {
  margin-top: 4px;
}

.btn-add-row {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 14px;
  border: 1px dashed #cbd5e1;
  background-color: #ffffff;
  color: #404040;
  border-radius: 6px;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-add-row:hover {
  border-color: #0b529c;
  color: #0b529c;
  background-color: #f0f7ff;
}

/* ─── EXPAND ROW MODAL ───────────────────────────────────────────────────── */
.row-modal-overlay {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 16px;
}

.row-modal-container {
  width: 100%;
  max-width: 520px;
  background-color: #ffffff;
  border-radius: 10px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.row-modal-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 18px 22px;
  border-bottom: 1px solid #f1f5f9;
}

.row-modal-header-text {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.row-modal-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.row-modal-subtitle {
  font-size: 12px;
  color: #737373;
  margin: 0;
}

.btn-modal-close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: none;
  background: transparent;
  color: #94a3b8;
  border-radius: 6px;
  cursor: pointer;
}

.btn-modal-close:hover {
  background-color: #f1f5f9;
  color: #404040;
}

.row-modal-body {
  padding: 20px 22px;
}

.modal-form-grid {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.modal-form-grid-2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.modal-form-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.modal-label {
  font-size: 12px;
  font-weight: 500;
  color: #404040;
}

.modal-select,
.modal-input {
  height: 38px;
  padding: 0 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  color: #404040;
  background-color: #ffffff;
  outline: none;
}

.modal-select:focus,
.modal-input:focus {
  border-color: #0b529c;
}

.row-modal-footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 22px;
  background-color: #f8fafc;
  border-top: 1px solid #f1f5f9;
}

.btn-modal-cancel {
  height: 34px;
  padding: 0 16px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  color: #404040;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-modal-cancel:hover {
  background-color: #f1f5f9;
}

.btn-modal-save {
  height: 34px;
  padding: 0 18px;
  border: none;
  background-color: #0b529c;
  color: #ffffff;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-modal-save:hover {
  background-color: #083e77;
}
</style>
