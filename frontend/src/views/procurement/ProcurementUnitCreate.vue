<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  X, Users, Building2
} from 'lucide-vue-next';
import AppBreadcrumb, { type BreadcrumbItem } from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import BaseTabs, { type BaseTabItem } from '../../components/BaseTabs.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';
import DynamicSubTable, { type DynamicTableColumn } from '../../components/DynamicSubTable.vue';
import { useToast } from '../../composables/useToast';
import {
  procurementUnitsStore,
  unitMembersStore,
  type ProcurementUnitMode,
  type ProcurementUnitRole,
  type GovernanceStatus,
  type ProcurementUnitMemberRecord,
  unitModeOptions,
  unitRoleOptions,
  employeeOptions,
  departmentOptions,
  locationOptions,
  currencyOptions,
  costCenterOptions,
  entityOptions,
  governanceStatusOptions,
  generateUnitCode
} from './procurementUnitData';

const router = useRouter();
const route = useRoute();
const { toast } = useToast();

const editingId = computed(() => (route.query.editId ? Number(route.query.editId) : null));
const isSaved = ref(false);
const fieldErrors = ref<{
  name?: string;
  mode?: string;
  entity_id?: string;
  authority_ceiling?: string;
  status?: string;
}>({});

// ─── Tab Navigation (AGENTS.md & creation-ux.instructions.md Standard) ───
type TabId = 'details' | 'members';
const activeTab = ref<TabId>('details');

const tabs = computed<BaseTabItem<TabId>[]>(() => [
  { id: 'details', label: 'Unit Details', icon: Building2 },
  { id: 'members', label: 'Unit Members', icon: Users, count: membersList.value.length }
]);

const form = ref({
  name: '',
  mode: '' as ProcurementUnitMode | '',
  authority_ceiling: '' as string | number,
  currency_code: 'ETB',
  buys_for_descendants: false,
  entity_id: '2',
  default_location_id: '',
  cost_center_dimension_id: '',
  status: 'acceptForAll' as GovernanceStatus
});

const newMemberFactory = () => {
  return {
    id: Date.now() + Math.random(),
    member_employee_id: '1',
    role: 'buyer' as ProcurementUnitRole,
    organization_unit_id: '2',
    valid_from: new Date().toISOString().split('T')[0],
    valid_to: ''
  };
};

// ─── Unit Members Sub-Table List (ProcurementUnitMember [LINE]) ───
// Rule: Dynamic tables must never start with an empty state; initialize with at least 1 default row
const membersList = ref<Array<{
  id: number;
  member_employee_id: string;
  role: ProcurementUnitRole;
  organization_unit_id: string;
  valid_from: string;
  valid_to: string;
}>>([newMemberFactory()]);

// ─── Sub-Table Column Definitions (Figma 5104:71792 specification) ───
const memberTableColumns: DynamicTableColumn[] = [
  { key: 'employee', label: 'Employee / Person', minWidth: '220px', type: 'custom' },
  { key: 'role', label: 'Assigned Role', minWidth: '180px', type: 'custom' },
  { key: 'department', label: 'Department Served', minWidth: '200px', type: 'custom' },
  { key: 'valid_from', label: 'Valid From', minWidth: '140px', type: 'custom' },
  { key: 'valid_to', label: 'Valid To', minWidth: '140px', type: 'custom' }
];

// ─── Breadcrumbs (AGENTS.md Rule 3: Sealed Badge Standard) ───
const breadcrumbItems = computed<BreadcrumbItem[]>(() => [
  { label: 'Procurement Units', to: '/procurement/units' },
  { label: editingId.value ? 'Edit Procurement Unit' : 'Create Procurement Unit' }
]);

watch(
  form,
  () => {
    isSaved.value = false;
    if (form.value.name.trim()) fieldErrors.value.name = undefined;
    if (form.value.mode) fieldErrors.value.mode = undefined;
    if (form.value.entity_id) fieldErrors.value.entity_id = undefined;
    if (
      form.value.authority_ceiling === '' ||
      (Number.isFinite(Number(form.value.authority_ceiling)) && Number(form.value.authority_ceiling) >= 0)
    ) {
      fieldErrors.value.authority_ceiling = undefined;
    }
    if (governanceStatusOptions.some((option) => option.value === form.value.status)) {
      fieldErrors.value.status = undefined;
    }
  },
  { deep: true }
);

watch(
  membersList,
  () => {
    isSaved.value = false;
  },
  { deep: true }
);

onMounted(() => {
  if (editingId.value) {
    const existing = procurementUnitsStore.value.find((u) => u.id === editingId.value);
    if (existing) {
      form.value = {
        name: existing.name,
        mode: existing.mode,
        authority_ceiling: existing.authority_ceiling !== null ? existing.authority_ceiling : '',
        currency_code: existing.currency_code || 'ETB',
        buys_for_descendants: existing.buys_for_descendants,
        entity_id: String(existing.entity_id),
        default_location_id: existing.default_location_id ? String(existing.default_location_id) : '',
        cost_center_dimension_id: existing.cost_center_dimension_id || '',
        status: existing.status
      };

      // Populate existing members for this unit
      const existingMembers = unitMembersStore.value.filter(
        (m) => m.procurement_unit_id === existing.id
      );
      membersList.value = existingMembers.map((m) => ({
        id: m.id,
        member_employee_id: String(m.member_employee_id),
        role: m.role,
        organization_unit_id: m.organization_unit_id ? String(m.organization_unit_id) : '',
        valid_from: m.valid_from,
        valid_to: m.valid_to || ''
      }));

      isSaved.value = true;
    }
    return;
  }

  // Quick form hydration if passed from query
  if (route.query.name) form.value.name = String(route.query.name);
  if (route.query.mode) form.value.mode = String(route.query.mode) as ProcurementUnitMode;
  if (route.query.authority_ceiling) form.value.authority_ceiling = String(route.query.authority_ceiling);
  if (route.query.currency_code) form.value.currency_code = String(route.query.currency_code);
  if (route.query.buys_for_descendants) form.value.buys_for_descendants = route.query.buys_for_descendants === '1';
  if (route.query.entity_id) form.value.entity_id = String(route.query.entity_id);
  if (route.query.default_location_id) form.value.default_location_id = String(route.query.default_location_id);
  if (route.query.cost_center_dimension_id) form.value.cost_center_dimension_id = String(route.query.cost_center_dimension_id);
  if (route.query.status) form.value.status = String(route.query.status) as GovernanceStatus;
  if (route.query.tab) activeTab.value = String(route.query.tab) as TabId;

});

const clearForm = () => {
  fieldErrors.value = {};
  form.value = {
    name: '',
    mode: '',
    authority_ceiling: '',
    currency_code: 'ETB',
    buys_for_descendants: false,
    entity_id: '2',
    default_location_id: '',
    cost_center_dimension_id: '',
    status: 'acceptForAll'
  };
  membersList.value = [newMemberFactory()];
  activeTab.value = 'details';
  isSaved.value = false;
};

const handleSave = () => {
  const errors: typeof fieldErrors.value = {};
  const missingLabels: string[] = [];

  if (!form.value.name.trim()) {
    errors.name = 'Unit Name is required.';
    missingLabels.push('Unit Name');
  }
  if (!unitModeOptions.some((option) => option.value === form.value.mode)) {
    errors.mode = 'Unit Mode is required.';
    missingLabels.push('Unit Mode');
  }
  if (!entityOptions.some((option) => option.value === form.value.entity_id)) {
    errors.entity_id = 'Owning Entity is required.';
    missingLabels.push('Owning Entity');
  }
  if (!governanceStatusOptions.some((option) => option.value === form.value.status)) {
    errors.status = 'Select a governance sharing scope.';
  }
  if (
    form.value.authority_ceiling !== '' &&
    (!Number.isFinite(Number(form.value.authority_ceiling)) || Number(form.value.authority_ceiling) < 0)
  ) {
    errors.authority_ceiling = 'Enter a non-negative authority ceiling.';
  }

  fieldErrors.value = errors;

  if (Object.keys(errors).length > 0) {
    activeTab.value = 'details';
    const errorDetails = [
      missingLabels.length > 0 ? `Missing: ${missingLabels.join(', ')}.` : '',
      errors.authority_ceiling,
      errors.status
    ].filter(Boolean).join(' ');
    toast.error(
      missingLabels.length > 0 ? 'Please fill in all required fields' : 'Check procurement unit details',
      errorDetails
    );
    return;
  }

  const memberKeys = new Set<string>();
  const hasInvalidMember = membersList.value.some((member) => (
    !employeeOptions.some((option) => option.value === member.member_employee_id) ||
    !unitRoleOptions.some((option) => option.value === member.role) ||
    !member.valid_from ||
    (member.valid_to !== '' && member.valid_to < member.valid_from)
  ));
  const hasDuplicateMember = membersList.value.some((member) => {
    if (!member.member_employee_id || !member.role) return false;
    const key = `${member.member_employee_id}|${member.role}|${member.organization_unit_id}`;
    if (memberKeys.has(key)) return true;
    memberKeys.add(key);
    return false;
  });
  if (hasInvalidMember || hasDuplicateMember) {
    activeTab.value = 'members';
    toast.error(
      'Check the unit member roster',
      hasDuplicateMember
        ? 'The same employee cannot have the same role and department assignment more than once.'
        : 'Complete each member, role, and start date; an end date cannot be before its start date.'
    );
    return;
  }

  const ceilingVal = form.value.authority_ceiling === '' ? null : Number(form.value.authority_ceiling);
  const entityIdVal = Number(form.value.entity_id);
  const locationIdVal = form.value.default_location_id ? Number(form.value.default_location_id) : null;

  let unitId: number;
  const existingMembers = editingId.value
    ? unitMembersStore.value.filter((member) => member.procurement_unit_id === editingId.value)
    : [];

  if (editingId.value) {
    unitId = editingId.value;
    const idx = procurementUnitsStore.value.findIndex((u) => u.id === editingId.value);
    if (idx !== -1) {
      const existing = procurementUnitsStore.value[idx];
      procurementUnitsStore.value[idx] = {
        ...existing,
        name: form.value.name.trim(),
        mode: form.value.mode as ProcurementUnitMode,
        authority_ceiling: ceilingVal,
        currency_code: form.value.currency_code,
        buys_for_descendants: form.value.buys_for_descendants,
        entity_id: entityIdVal,
        default_location_id: locationIdVal,
        cost_center_dimension_id: form.value.cost_center_dimension_id || null,
        status: form.value.status
      };
    }
  } else {
    const existingCodes = procurementUnitsStore.value.map((u) => u.code);
    const nextId = Math.max(0, ...procurementUnitsStore.value.map((u) => u.id)) + 1;
    unitId = nextId;
    const generatedCode = generateUnitCode(form.value.name, existingCodes);

    procurementUnitsStore.value.unshift({
      id: nextId,
      uuid: `pu-uuid-${nextId}`,
      code: generatedCode,
      name: form.value.name.trim(),
      mode: form.value.mode as ProcurementUnitMode,
      authority_ceiling: ceilingVal,
      currency_code: form.value.currency_code,
      buys_for_descendants: form.value.buys_for_descendants,
      entity_id: entityIdVal,
      default_location_id: locationIdVal,
      cost_center_dimension_id: form.value.cost_center_dimension_id || null,
      status: form.value.status,
      state: 'active'
    });
  }

  // Preserve existing member identity/state while applying roster edits.
  let nextMemberId = Math.max(0, ...unitMembersStore.value.map((m) => m.id)) + 1;
  const updatedMembers: ProcurementUnitMemberRecord[] = membersList.value.map((m) => {
    const existingMember = existingMembers.find((member) => member.id === m.id);
    const empOption = employeeOptions.find((e) => e.value === m.member_employee_id);
    const empName = empOption ? empOption.label.split(' (')[0] : `Employee #${m.member_employee_id}`;
    const empCode = empOption && empOption.label.includes('(') ? empOption.label.split('(')[1].split(')')[0] : `EMP-${m.member_employee_id}`;
    const deptOption = departmentOptions.find((d) => d.value === m.organization_unit_id);
    const deptName = deptOption ? deptOption.label : 'All Departments';

    const id = existingMember?.id ?? nextMemberId++;
    return {
      id,
      uuid: existingMember?.uuid ?? `pum-uuid-${id}`,
      procurement_unit_id: unitId,
      member_employee_id: Number(m.member_employee_id),
      employee_name: empName,
      employee_code: empCode,
      role: m.role,
      organization_unit_id: m.organization_unit_id ? Number(m.organization_unit_id) : null,
      department_name: deptName,
      valid_from: m.valid_from,
      valid_to: m.valid_to || null,
      state: existingMember?.state ?? 'active'
    };
  });
  unitMembersStore.value = [
    ...unitMembersStore.value.filter((member) => member.procurement_unit_id !== unitId),
    ...updatedMembers
  ];

  isSaved.value = true;
  toast.success(
    editingId.value ? 'Procurement unit updated' : 'Procurement unit created',
    `"${form.value.name.trim()}" and its assigned members have been saved.`
  );
  router.push('/procurement/units');
};
</script>

<template>
  <div class="unit-create-page">
    
    <!-- ═══ TOP BAR (Rule 29: Zero Background Card, Rule 30: SaveStateBadge, Rule 27: Icon-free Save) ═══ -->
    <div class="create-top-bar">
      <AppBreadcrumb :items="breadcrumbItems" :noMargin="true">
        <template #badge>
          <SaveStateBadge :isSaved="isSaved" :isDraft="false" />
        </template>
      </AppBreadcrumb>

      <div class="top-bar-actions">
        <AppButton variant="outline" size="sm" @click="clearForm">
          <template #icon-left><X :size="14" /></template>
          Clear Form
        </AppButton>
        <!-- Rule 27: Save button MUST have zero icons -->
        <AppButton variant="primary" size="sm" @click="handleSave">
          Save
        </AppButton>
      </div>
    </div>

    <!-- ═══ TOP TABS: <BaseTabs /> (Primary Capsule Tab Standard) ═══ -->
    <div class="tabs-header-wrap">
      <BaseTabs
        v-model="activeTab"
        :tabs="tabs"
      />
    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 1: MASTER UNIT DETAILS                                     -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'details'" class="tab-pane">
      <div class="clean-card form-card-body">
        
        <!-- Row 1: Core Identity -->
        <div class="form-grid-3">
          <FormInput
            v-model="form.name"
            label="Unit Name"
            :error="fieldErrors.name"
            required
          />

          <FormSelect
            v-model="form.mode"
            label="Procurement Unit Mode"
            :options="unitModeOptions"
            placeholder="Select"
            :error="fieldErrors.mode"
            required
          />

          <div class="ceiling-amount-group">
            <FormInput
              v-model="form.authority_ceiling"
              label="Authority Ceiling"
              type="number"
              :error="fieldErrors.authority_ceiling"
            />
          </div>
        </div>

        <!-- Row 2: Entity & Infrastructure Linkage -->
        <div class="form-grid-3">
          <FormSelect
            v-model="form.entity_id"
            label="Owning Entity"
            :options="entityOptions"
            placeholder="Select"
            :error="fieldErrors.entity_id"
            required
          />

          <FormSelect
            v-model="form.currency_code"
            label="Ceiling Currency"
            :options="currencyOptions"
            placeholder="Select"
          />

          <FormSelect
            v-model="form.default_location_id"
            label="Default Store Location"
            :options="locationOptions"
            placeholder="Select"
          />
        </div>

        <!-- Row 3: Governance & Dimension -->
        <div class="form-grid-3">
          <FormSelect
            v-model="form.cost_center_dimension_id"
            label="Default Cost Center"
            :options="costCenterOptions"
            placeholder="Select"
          />

          <FormSelect
            v-model="form.status"
            label="Governance Sharing Scope"
            :options="governanceStatusOptions"
            placeholder="Select"
            :error="fieldErrors.status"
          />
        </div>

        <!-- Row 4: Policy Checkboxes -->
        <div class="controls-checkbox-grid">
          <FormCheckbox
            v-model="form.buys_for_descendants"
            label="Buys for Child Entities"
            description="Allows this buying desk to place purchase orders on behalf of subsidiary branches and child entities under this entity node."
          />
        </div>

      </div>

    </div>

    <!-- ══════════════════════════════════════════════════════════════ -->
    <!-- TAB 2: UNIT MEMBERS & ROLES SUB-TABLE (ProcurementUnitMember)  -->
    <!-- ══════════════════════════════════════════════════════════════ -->
    <div v-show="activeTab === 'members'" class="tab-pane">
      <div class="clean-card subtable-card">
        <div class="subtable-card-header">
          <div class="header-text-block">
            <h3 class="section-title">Unit Members &amp; Purchasing Roles</h3>
            <p class="section-subtitle">
              Personnel authorized to request demands, place orders, approve purchase commitments, or receive goods for this unit.
            </p>
          </div>
        </div>

        <div class="subtable-body">
          <DynamicSubTable
            v-model="membersList"
            :columns="memberTableColumns"
            entity-name="Member"
            entity-name-plural="Members"
            empty-text="No members assigned to this unit yet."
            :can-add-row="true"
            :can-delete="true"
            :new-row-factory="newMemberFactory"
          >
            <!-- Custom Cell: Employee Select -->
            <template #employee="{ row }">
              <div class="cell-wrap">
                <FormSelect
                  v-model="row.member_employee_id"
                  :options="employeeOptions"
                  placeholder="Select Employee"
                  variant="cell"
                  :teleport="true"
                  :searchable="true"
                />
              </div>
            </template>

            <!-- Custom Cell: Role Select -->
            <template #role="{ row }">
              <div class="cell-wrap">
                <FormSelect
                  v-model="row.role"
                  :options="unitRoleOptions"
                  placeholder="Select Role"
                  variant="cell"
                  :teleport="true"
                />
              </div>
            </template>

            <!-- Custom Cell: Department Served -->
            <template #department="{ row }">
              <div class="cell-wrap">
                <FormSelect
                  v-model="row.organization_unit_id"
                  :options="departmentOptions"
                  placeholder="All Departments"
                  variant="cell"
                  :teleport="true"
                />
              </div>
            </template>

            <!-- Custom Cell: Valid From -->
            <template #valid_from="{ row }">
              <div class="cell-wrap">
                <input
                  v-model="row.valid_from"
                  type="date"
                  class="cell-grid-date"
                />
              </div>
            </template>

            <!-- Custom Cell: Valid To -->
            <template #valid_to="{ row }">
              <div class="cell-wrap">
                <input
                  v-model="row.valid_to"
                  type="date"
                  class="cell-grid-date"
                />
              </div>
            </template>

            <!-- Expand Modal Slot (Full Edit Form) -->
            <template #expand-modal="{ row }">
              <div class="expand-modal-form">
                <FormSelect
                  v-model="row.member_employee_id"
                  label="Employee / Person"
                  :options="employeeOptions"
                  placeholder="Select Employee"
                  :searchable="true"
                  required
                />

                <div class="modal-grid-2">
                  <FormSelect
                    v-model="row.role"
                    label="Assigned Role"
                    :options="unitRoleOptions"
                    placeholder="Select Role"
                    required
                  />

                  <FormSelect
                    v-model="row.organization_unit_id"
                    label="Department Served"
                    :options="departmentOptions"
                    placeholder="All Departments"
                  />
                </div>

                <div class="modal-grid-2">
                  <FormInput
                    v-model="row.valid_from"
                    label="Valid From"
                    type="date"
                    required
                  />

                  <FormInput
                    v-model="row.valid_to"
                    label="Valid To"
                    type="date"
                    placeholder="Indefinite if empty"
                  />
                </div>
              </div>
            </template>
          </DynamicSubTable>
        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>
.unit-create-page {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  width: 100%;
  padding: 0;
  box-sizing: border-box;
}

/* ─── Top Bar ─── */
.create-top-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  background: transparent;
  padding: 0;
}

.top-bar-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

/* ─── Tabs Header ─── */
.tabs-header-wrap {
  display: flex;
  align-items: center;
}

.tab-pane {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
  width: 100%;
}

/* ─── Master Form Card ─── */
.clean-card {
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0px 1px 2px 0px rgba(10, 13, 18, 0.05);
}

.form-card-body {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-grid-3 {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
  width: 100%;
}

@media (max-width: 900px) {
  .form-grid-3 {
    grid-template-columns: 1fr;
  }
}

.controls-checkbox-grid {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding-top: 4px;
}

/* ─── Sub-Table Section Card ─── */
.subtable-card {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.subtable-card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: #404040;
  line-height: 24px;
  margin: 0;
}

.section-subtitle {
  font-size: 13px;
  color: #737373;
  margin: 4px 0 0 0;
  line-height: 18px;
}

.cell-wrap {
  width: 100%;
}

.cell-grid-date {
  width: 100%;
  height: 42px;
  min-height: 42px;
  padding: 8px 14px;
  font-size: 14px;
  color: #404040;
  border: none;
  border-radius: 0;
  background-color: transparent;
  outline: none;
  font-family: inherit;
  box-sizing: border-box;
}

.cell-grid-date:focus {
  box-shadow: inset 0 0 0 2px #0B529C;
}

/* ─── Collapsible Description ─── */
.accordion-card {
  display: flex;
  flex-direction: column;
}

.card-accordion-header {
  padding: 16px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  user-select: none;
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  transition: background-color 0.15s ease;
}

.card-accordion-header:hover {
  background-color: #fafafa;
}

.header-chevron {
  color: #737373;
}

.card-accordion-divider {
  height: 1px;
  background-color: #e5e5e5;
  width: 100%;
}

.card-accordion-body {
  padding: 24px;
}

/* ─── Expand Row Modal Inside DynamicSubTable ─── */
.expand-modal-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

@media (max-width: 600px) {
  .modal-grid-2 {
    grid-template-columns: 1fr;
  }
}
</style>
