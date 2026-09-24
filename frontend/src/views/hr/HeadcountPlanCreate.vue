<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  Monitor, ChevronRight, X, Plus, Trash2, 
  List, Undo, Redo, MoreVertical, FileText, CheckCircle2,
  Calendar, Layers, FileSpreadsheet, Maximize2
} from 'lucide-vue-next';
import BaseTabs from '../../components/BaseTabs.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import TableFloatingBar from '../../components/TableFloatingBar.vue';

const router = useRouter();
const route = useRoute();

// ─── Lifecycle & Save State ───
const isSaved = ref(false);
const showDraftMenu = ref(false);
const quickActionToast = ref('');

// ─── Tab System (Rule 1: BaseTabs Capsule) ───
type TabId = 'details' | 'positions';
const activeTab = ref<TabId>('details');

const tabs = [
  { id: 'details' as const, label: 'Plan Details', icon: FileSpreadsheet },
  { id: 'positions' as const, label: 'Position Allocations', icon: Layers }
];

// ─── Master Form State (Planning Parameters ONLY; String fiscal_year) ───
const form = ref({
  entity_id: 7,
  organization_unit_id: 3,
  fiscal_year: '2027',
  period_start: '2026-07-08',
  period_end: '2027-07-07',
  approved_headcount: 12,
  annual_budget_amount: 936000,
  currency_id: 'ETB',
  budget_state: 'draft' as 'draft' | 'approved' | 'active',
  notes: 'Strategic operational headcount allocation for unit growth and hiring quotas.'
});

// Dynamic Computed Tag for Fiscal Year
const computedFiscalYear = computed(() => {
  if (!form.value.fiscal_year) return 'FY-PENDING';
  return `FY-${form.value.fiscal_year}`;
});

// Monthly Payroll Cap (Derived: annual_budget / 12)
const monthlyBudgetCap = computed(() => {
  const annual = Number(form.value.annual_budget_amount) || 0;
  return Math.round(annual / 12);
});

// Entity & Org Unit Options
const entityOptions = [
  { value: 7, label: 'Haleta Addis Ababa Hospitality' },
  { value: 3, label: 'Haleta Technologies Group' },
  { value: 9, label: 'Haleta Logistics & Cargo' }
];

const orgUnitOptions = [
  { value: 3, label: 'Commercial & Sales Operations (COMM-OPS)' },
  { value: 2, label: 'Engineering & Technology (ENG-TECH)' },
  { value: 1, label: 'Finance & Compliance (FIN-CORP)' },
  { value: 5, label: 'People & Culture (HR-PEOPLE)' }
];

const currencyOptions = [
  { value: 'ETB', label: 'ETB — Ethiopian Birr' },
  { value: 'USD', label: 'USD — US Dollar' },
  { value: 'EUR', label: 'EUR — Euro' }
];

// ─── Child Sub-Table: Position Allocations ───
export interface PositionAllocationLine {
  id: number;
  job_position_id: number;
  position_name: string;
  position_code: string;
  job_grade: string;
  allocated_seats: number;
  avg_monthly_salary: number;
  notes?: string;
}

const positionAllocations = ref<PositionAllocationLine[]>([
  {
    id: 1,
    job_position_id: 101,
    position_name: 'Guest Relations Specialist',
    position_code: 'POS-GRS-01',
    job_grade: 'L3 / Specialist',
    allocated_seats: 4,
    avg_monthly_salary: 18000,
    notes: 'Front-desk check-in and VIP reception staff.'
  },
  {
    id: 2,
    job_position_id: 102,
    position_name: 'Lead Catering Coordinator',
    position_code: 'POS-LCC-02',
    job_grade: 'L4 / Senior',
    allocated_seats: 2,
    avg_monthly_salary: 25000,
    notes: 'Banquet event sales and kitchen logistics.'
  },
  {
    id: 3,
    job_position_id: 103,
    position_name: 'Hospitality Service Associate',
    position_code: 'POS-HSA-03',
    job_grade: 'L2 / Associate',
    allocated_seats: 6,
    avg_monthly_salary: 12000,
    notes: 'Shift service associates for floor management.'
  }
]);

const selectedPositionIds = ref<number[]>([]);
const isPositionModalOpen = ref(false);
const editingPositionIndex = ref<number | null>(null);

const positionForm = ref({
  job_position_id: 101,
  allocated_seats: 2,
  avg_monthly_salary: 15000,
  notes: ''
});

const jobPositionCatalog = [
  { id: 101, name: 'Guest Relations Specialist', code: 'POS-GRS-01', grade: 'L3 / Specialist' },
  { id: 102, name: 'Lead Catering Coordinator', code: 'POS-LCC-02', grade: 'L4 / Senior' },
  { id: 103, name: 'Hospitality Service Associate', code: 'POS-HSA-03', grade: 'L2 / Associate' },
  { id: 104, name: 'Senior Software Engineer', code: 'POS-SWE-01', grade: 'L5 / Lead' },
  { id: 105, name: 'Financial Accountant', code: 'POS-ACC-01', grade: 'L3 / Specialist' }
];

// Sub-table Selection
const isAllPositionsSelected = computed(() => {
  return positionAllocations.value.length > 0 && selectedPositionIds.value.length === positionAllocations.value.length;
});

const toggleSelectAllPositions = () => {
  if (isAllPositionsSelected.value) {
    selectedPositionIds.value = [];
  } else {
    selectedPositionIds.value = positionAllocations.value.map(p => p.id);
  }
};

const togglePositionSelection = (id: number) => {
  const index = selectedPositionIds.value.indexOf(id);
  if (index > -1) selectedPositionIds.value.splice(index, 1);
  else selectedPositionIds.value.push(id);
};

const handleBatchDeletePositions = () => {
  if (!confirm(`Delete ${selectedPositionIds.value.length} selected position allocation lines?`)) return;
  positionAllocations.value = positionAllocations.value.filter(p => !selectedPositionIds.value.includes(p.id));
  selectedPositionIds.value = [];
  showToast('Position allocation lines removed.');
};

const openAddPositionModal = () => {
  editingPositionIndex.value = null;
  positionForm.value = {
    job_position_id: 101,
    allocated_seats: 1,
    avg_monthly_salary: 15000,
    notes: ''
  };
  isPositionModalOpen.value = true;
};

const openEditPositionModal = (index: number) => {
  editingPositionIndex.value = index;
  const item = positionAllocations.value[index];
  positionForm.value = {
    job_position_id: item.job_position_id,
    allocated_seats: item.allocated_seats,
    avg_monthly_salary: item.avg_monthly_salary,
    notes: item.notes || ''
  };
  isPositionModalOpen.value = true;
};

const handleSavePosition = () => {
  const catalogItem = jobPositionCatalog.find(c => c.id === positionForm.value.job_position_id) || jobPositionCatalog[0];
  if (editingPositionIndex.value !== null) {
    positionAllocations.value[editingPositionIndex.value] = {
      id: positionAllocations.value[editingPositionIndex.value].id,
      job_position_id: catalogItem.id,
      position_name: catalogItem.name,
      position_code: catalogItem.code,
      job_grade: catalogItem.grade,
      allocated_seats: Number(positionForm.value.allocated_seats),
      avg_monthly_salary: Number(positionForm.value.avg_monthly_salary),
      notes: positionForm.value.notes
    };
  } else {
    positionAllocations.value.push({
      id: Date.now(),
      job_position_id: catalogItem.id,
      position_name: catalogItem.name,
      position_code: catalogItem.code,
      job_grade: catalogItem.grade,
      allocated_seats: Number(positionForm.value.allocated_seats),
      avg_monthly_salary: Number(positionForm.value.avg_monthly_salary),
      notes: positionForm.value.notes
    });
  }
  isPositionModalOpen.value = false;
  showToast('Position quota updated.');
};

// Rich Text Editor Commands
const execFormat = (cmd: string, value: string | undefined = undefined) => {
  document.execCommand(cmd, false, value);
};

// Toast
const showToast = (msg: string) => {
  quickActionToast.value = msg;
  setTimeout(() => { quickActionToast.value = ''; }, 3000);
};

// ─── Save & Clear Actions ───
const handleSave = () => {
  if (!form.value.approved_headcount || !form.value.organization_unit_id) {
    alert('Please fill all mandatory headcount fields.');
    return;
  }
  isSaved.value = true;
  form.value.budget_state = 'active';
  showToast('Headcount budget plan published successfully.');
  setTimeout(() => {
    router.push('/hr/headcount-planning');
  }, 1000);
};

const handleSaveAsDraft = () => {
  isSaved.value = true;
  form.value.budget_state = 'draft';
  showDraftMenu.value = false;
  showToast('Headcount budget saved as Draft.');
  setTimeout(() => {
    router.push('/hr/headcount-planning');
  }, 1000);
};

const handleClearForm = () => {
  form.value = {
    entity_id: 7,
    organization_unit_id: 3,
    fiscal_year: '2027',
    period_start: '',
    period_end: '',
    approved_headcount: 0,
    annual_budget_amount: 0,
    currency_id: 'ETB',
    budget_state: 'draft',
    notes: ''
  };
  positionAllocations.value = [];
  isSaved.value = false;
  showToast('Form cleared.');
};
</script>

<template>
  <div class="headcount-plan-create-page">
    <!-- Top Action & Breadcrumb Navigation Bar (Rule 29: Zero Background) -->
    <div class="page-top-action-bar">
      <!-- Breadcrumbs: Home -> Headcount Planning -> Create Headcount Plan (Rule 3/4) -->
      <div class="breadcrumb-cluster">
        <router-link to="/home" class="breadcrumb-root-btn" title="Home">
          <Monitor :size="16" />
        </router-link>
        <ChevronRight :size="14" class="breadcrumb-separator" />
        <span class="breadcrumb-link" @click="router.push('/hr/headcount-planning')">Headcount Planning</span>
        <ChevronRight :size="14" class="breadcrumb-separator" />
        <span class="breadcrumb-current">Create Headcount Plan</span>
        
        <!-- Standardized SaveStateBadge (Rule 30: #FEF3C6 / #BB4D00, borderless pill) -->
        <SaveStateBadge :isSaved="isSaved" :isDraft="form.budget_state === 'draft'" />
      </div>

      <!-- Right Action Cluster (Rule 4: [⋮ More] [✕ Clear Form] [Save]) -->
      <div class="top-actions-cluster">
        <!-- Dynamic 3-Dots More Menu for Draft-Capable Schema (Rule 4 Standard) -->
        <div class="draft-menu-container">
          <button 
            type="button" 
            class="btn-icon-more" 
            @click.stop="showDraftMenu = !showDraftMenu"
            title="More Options"
          >
            <MoreVertical :size="16" />
          </button>

          <div v-if="showDraftMenu" class="draft-popover-menu" @click.stop>
            <button 
              type="button" 
              class="draft-menu-item"
              @click="handleSaveAsDraft"
            >
              <FileText :size="14" />
              <span>Save as Draft</span>
            </button>
          </div>
        </div>

        <button 
          type="button" 
          class="btn-secondary-clear" 
          @click="handleClearForm"
        >
          <X :size="14" />
          <span>Clear Form</span>
        </button>

        <button 
          type="button" 
          class="btn-primary-save" 
          @click="handleSave"
        >
          <span>Save</span>
        </button>
      </div>
    </div>

    <!-- Toast Notification Banner -->
    <div v-if="quickActionToast" class="quick-toast-banner">
      <CheckCircle2 :size="15" class="toast-icon" />
      <span>{{ quickActionToast }}</span>
    </div>

    <!-- Top Navigation Tabs (Rule 1: BaseTabs Capsule) -->
    <div class="top-tabs-wrapper">
      <BaseTabs 
        v-model="activeTab" 
        :tabs="tabs" 
      />
    </div>

    <!-- TAB 1: PLAN DETAILS -->
    <div v-if="activeTab === 'details'" class="tab-content-container">
      <div class="clean-master-card">
        <div class="card-section-title-row">
          <span class="card-section-title">Budget Plan Specifications</span>
        </div>

        <!-- Section 1 Riser: Work Location & Unit Allocation -->
        <div class="form-section-riser">
          <span class="riser-title">Work Location & Unit Allocation</span>
          <div class="riser-line"></div>
        </div>

        <div class="form-grid-2col">
          <FormSelect
            label="Owning Entity"
            v-model="form.entity_id"
            :options="entityOptions"
            required
          />

          <FormSelect
            label="Organization Unit"
            v-model="form.organization_unit_id"
            :options="orgUnitOptions"
            required
          />
        </div>

        <!-- Section 2 Riser: Fiscal Capacity & Period -->
        <div class="form-section-riser">
          <span class="riser-title">Fiscal Capacity & Period</span>
          <div class="riser-line"></div>
        </div>

        <div class="form-grid-3col">
          <!-- Effective From Date with [GC] Badge -->
          <div class="form-field-wrap">
            <label class="field-label">Effective From Date <span class="required-star">*</span></label>
            <div class="date-composite-input">
              <Calendar :size="15" class="date-cal-icon" />
              <input 
                type="date" 
                v-model="form.period_start" 
                class="date-field-inner"
                required 
              />
              <span class="gc-badge">GC</span>
            </div>
          </div>

          <!-- Effective Until Date with [GC] Badge -->
          <div class="form-field-wrap">
            <label class="field-label">Effective Until Date <span class="required-star">*</span></label>
            <div class="date-composite-input">
              <Calendar :size="15" class="date-cal-icon" />
              <input 
                type="date" 
                v-model="form.period_end" 
                class="date-field-inner"
                required 
              />
              <span class="gc-badge">GC</span>
            </div>
          </div>

          <!-- Fiscal Year: String input with Dynamic FY Pill Tag and selective format hint -->
          <div class="form-field-wrap">
            <div class="field-label-with-tag">
              <label class="field-label">Fiscal Year <span class="required-star">*</span></label>
              <span class="fy-tag-pill">{{ computedFiscalYear }}</span>
            </div>
            <FormInput
              v-model="form.fiscal_year"
              hint="Statutory financial calendar cycle (e.g. 2026/27 or 2026)."
              required
            />
          </div>

          <!-- Target Capacity (Seats) -->
          <FormInput
            label="Target Headcount Capacity (Seats)"
            v-model="form.approved_headcount"
            type="number"
            required
          />
        </div>

        <!-- Section 3 Riser: Financial Authorization & Ceilings -->
        <div class="form-section-riser">
          <span class="riser-title">Financial Authorization & Ceilings</span>
          <div class="riser-line"></div>
        </div>

        <div class="form-grid-3col">
          <FormSelect
            label="Currency"
            v-model="form.currency_id"
            :options="currencyOptions"
            required
          />

          <FormInput
            label="Annual Rolled-up Salary Budget"
            v-model="form.annual_budget_amount"
            type="number"
            required
          />

          <!-- Estimated Monthly Cap (Derived) -->
          <div class="form-field-wrap">
            <label class="field-label">Est. Monthly Payroll Cap (Derived)</label>
            <div class="derived-field-display font-mono">
              {{ monthlyBudgetCap.toLocaleString() }} {{ form.currency_id }} / mo
            </div>
          </div>
        </div>

        <!-- Section 4 Riser: Budget Justification & Scope -->
        <div class="form-section-riser">
          <span class="riser-title">Budget Justification & Scope</span>
          <div class="riser-line"></div>
        </div>

        <!-- Strategic Description & Justification -->
        <div class="rich-editor-section">
          <div class="rich-editor-container">
            <div class="editor-toolbar">
              <button type="button" class="toolbar-btn font-bold" @click="execFormat('bold')" title="Bold">B</button>
              <button type="button" class="toolbar-btn italic" @click="execFormat('italic')" title="Italic">I</button>
              <button type="button" class="toolbar-btn underline" @click="execFormat('underline')" title="Underline">U</button>
              <div class="toolbar-divider"></div>
              <button type="button" class="toolbar-btn" @click="execFormat('insertUnorderedList')" title="Bullet List">
                <List :size="14" />
              </button>
              <button type="button" class="toolbar-btn" @click="execFormat('undo')" title="Undo">
                <Undo :size="14" />
              </button>
              <button type="button" class="toolbar-btn" @click="execFormat('redo')" title="Redo">
                <Redo :size="14" />
              </button>
            </div>

            <div 
              class="editor-editable-area" 
              contenteditable="true"
              @input="(e: any) => form.notes = e.target.innerText"
            >
              Strategic operational headcount allocation for unit growth, capacity management, and hiring quotas under the approved corporate fiscal plan.
            </div>

            <div class="editor-footer">
              <span class="char-count">{{ form.notes ? form.notes.length : 124 }} / 5,000 Characters</span>
              <span class="resize-handle">//</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- TAB 2: POSITION ALLOCATIONS (Rule 11/19 Dynamic Child Sub-Table) -->
    <div v-if="activeTab === 'positions'" class="tab-content-container">
      <div class="clean-master-card">
        <div class="card-section-title-row">
          <span class="card-section-title">Planned Job Position Allocations</span>
          <button 
            type="button" 
            class="btn-add-item-header"
            @click="openAddPositionModal"
          >
            <Plus :size="14" />
            <span>Add Position Quota</span>
          </button>
        </div>

        <!-- Dynamic Sub-Table -->
        <div class="child-subtable-wrapper">
          <table class="child-erp-table">
            <thead>
              <tr>
                <th class="col-th-check">
                  <input 
                    type="checkbox" 
                    class="custom-checkbox" 
                    :checked="isAllPositionsSelected" 
                    @change="toggleSelectAllPositions" 
                  />
                </th>
                <th class="col-th-no">#</th>
                <th class="col-th-position">Job Position</th>
                <th class="col-th-grade">Target Grade</th>
                <th class="col-th-seats">Allocated Seats</th>
                <th class="col-th-salary">Est. Monthly Salary</th>
                <th class="col-th-subtotal">Monthly Subtotal</th>
                <th class="col-th-notes">Notes</th>
                <th class="col-th-actions">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="(pos, idx) in positionAllocations" 
                :key="pos.id"
                class="child-table-row"
                :class="{ 'child-row-selected': selectedPositionIds.includes(pos.id) }"
              >
                <td class="col-th-check" @click.stop>
                  <input 
                    type="checkbox" 
                    class="custom-checkbox" 
                    :checked="selectedPositionIds.includes(pos.id)" 
                    @change="togglePositionSelection(pos.id)" 
                  />
                </td>
                <td class="col-th-no text-tertiary font-mono">{{ idx + 1 }}</td>
                <td class="col-th-position">
                  <div class="position-cell-stack">
                    <span class="table-name-primary">{{ pos.position_name }}</span>
                    <span class="table-code-subtext font-mono">{{ pos.position_code }}</span>
                  </div>
                </td>
                <td class="col-th-grade text-tertiary">{{ pos.job_grade }}</td>
                <td class="col-th-seats font-medium text-slate-700">{{ pos.allocated_seats }} Seats</td>
                <td class="col-th-salary font-mono text-tertiary">{{ pos.avg_monthly_salary.toLocaleString() }} ETB</td>
                <td class="col-th-subtotal font-mono font-medium text-slate-700">
                  {{ (pos.allocated_seats * pos.avg_monthly_salary).toLocaleString() }} ETB
                </td>
                <td class="col-th-notes text-tertiary text-xs">{{ pos.notes || '—' }}</td>
                <td class="col-th-actions" @click.stop>
                  <div class="row-actions-group">
                    <button 
                      type="button" 
                      class="btn-row-action" 
                      @click="openEditPositionModal(idx)"
                      title="Edit"
                    >
                      <Maximize2 :size="13" />
                    </button>
                    <button 
                      type="button" 
                      class="btn-row-action text-rose-500 hover:text-rose-700" 
                      @click="positionAllocations.splice(idx, 1); showToast('Removed position allocation.');"
                      title="Delete"
                    >
                      <Trash2 :size="13" />
                    </button>
                  </div>
                </td>
              </tr>

              <!-- Empty State -->
              <tr v-if="positionAllocations.length === 0">
                <td colspan="9" class="child-empty-state">
                  <p>No position allocations added yet. Click "+ Add Position Quota" to distribute seats.</p>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="add-row-action-footer">
          <button 
            type="button" 
            class="btn-add-row"
            @click="openAddPositionModal"
          >
            <Plus :size="14" />
            <span>Add Position Quota</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Floating Batch Bar for Child Sub-Table -->
    <TableFloatingBar
      :count="selectedPositionIds.length"
      @delete="handleBatchDeletePositions"
    />

    <!-- Position Allocation Modal (Expand Modal) -->
    <div v-if="isPositionModalOpen" class="modal-backdrop" @click="isPositionModalOpen = false">
      <div class="modal-card" @click.stop>
        <div class="modal-header">
          <h3 class="modal-title">{{ editingPositionIndex !== null ? 'Edit Position Quota' : 'Add Position Quota' }}</h3>
          <button type="button" class="btn-modal-close" @click="isPositionModalOpen = false">
            <X :size="16" />
          </button>
        </div>

        <div class="modal-body">
          <FormSelect
            label="Job Position"
            v-model="positionForm.job_position_id"
            :options="jobPositionCatalog.map(p => ({ value: p.id, label: `${p.name} (${p.code}) — ${p.grade}` }))"
            required
          />

          <div class="modal-row-grid">
            <FormInput
              label="Allocated Seats"
              v-model="positionForm.allocated_seats"
              type="number"
              required
            />

            <FormInput
              label="Estimated Monthly Salary (ETB)"
              v-model="positionForm.avg_monthly_salary"
              type="number"
              required
            />
          </div>

          <div class="form-field-wrap">
            <label class="field-label">Allocation Notes & Justification</label>
            <textarea 
              v-model="positionForm.notes" 
              class="simple-textarea"
              rows="3"
            ></textarea>
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn-secondary-clear" @click="isPositionModalOpen = false">Cancel</button>
          <button type="button" class="btn-primary-save" @click="handleSavePosition">
            <span>Save</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.headcount-plan-create-page {
  padding: 0;
  animation: fadeIn 0.15s ease-in-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(2px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Rule 29: Top Action Bar Zero Background */
.page-top-action-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
  margin-bottom: 20px;
}

.breadcrumb-cluster {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
}

.breadcrumb-root-btn {
  display: flex;
  align-items: center;
  color: #737373;
  text-decoration: none;
}
.breadcrumb-root-btn:hover {
  color: #0B529C;
}

.breadcrumb-separator {
  color: #94a3b8;
}

.breadcrumb-link {
  color: #737373;
  cursor: pointer;
}
.breadcrumb-link:hover {
  color: #0B529C;
}

.breadcrumb-current {
  color: #404040;
  font-weight: 600;
}

.top-actions-cluster {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-icon-more {
  width: 38px;
  height: 38px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-icon-more:hover {
  background-color: #f8fafc;
  color: #0f172a;
}

.btn-secondary-clear {
  height: 38px;
  padding: 0 16px;
  display: flex;
  align-items: center;
  gap: 6px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  color: #404040;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-secondary-clear:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.btn-primary-save {
  height: 38px;
  padding: 0 22px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  border-radius: 8px;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 13.5px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(11, 82, 156, 0.2);
  transition: background-color 0.15s ease;
}
.btn-primary-save:hover {
  background-color: #09427d;
}

.draft-menu-container {
  position: relative;
}

.draft-popover-menu {
  position: absolute;
  top: calc(100% + 6px);
  left: 0;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  padding: 4px;
  min-width: 140px;
  z-index: 100;
}

.draft-menu-item {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 12px;
  border: none;
  background: none;
  font-size: 12.5px;
  color: #404040;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
}
.draft-menu-item:hover {
  background-color: #f1f5f9;
}

.quick-toast-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background-color: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  margin-bottom: 16px;
  font-size: 13px;
  color: #065f46;
}

.toast-icon {
  color: #059669;
  flex-shrink: 0;
}

.top-tabs-wrapper {
  margin-bottom: 16px;
}

.clean-master-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 22px 24px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}

.card-section-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 18px;
}

.card-section-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
}

.form-section-riser {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 22px;
  margin-bottom: 14px;
}
.form-section-riser:first-of-type {
  margin-top: 4px;
}

.riser-title {
  font-size: 12.5px;
  font-weight: 600;
  color: #0B529C;
  white-space: nowrap;
}

.riser-line {
  flex: 1;
  height: 1px;
  background-color: #f1f5f9;
}

.form-grid-2col {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px 20px;
  margin-bottom: 18px;
}

.form-grid-3col {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px 20px;
  margin-bottom: 24px;
}

.field-label-with-tag {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 4px;
}

.fy-tag-pill {
  font-size: 11px;
  font-weight: 600;
  background-color: #eff6ff;
  color: #0284c7;
  padding: 1.5px 7px;
  border-radius: 100px;
}

.form-field-wrap {
  display: flex;
  flex-direction: column;
}

.field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  margin-bottom: 4px;
}

.required-star {
  color: #ef4444;
}

.date-composite-input {
  display: flex;
  align-items: center;
  height: 38px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 0 10px;
  background-color: #ffffff;
  transition: border-color 0.15s ease;
}
.date-composite-input:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.date-cal-icon {
  color: #737373;
  margin-right: 8px;
  flex-shrink: 0;
}

.date-field-inner {
  flex: 1;
  border: none;
  outline: none;
  font-size: 13px;
  color: #404040;
  background: transparent;
}

.date-field-inner::-webkit-calendar-picker-indicator {
  display: none;
  -webkit-appearance: none;
}

.gc-badge {
  font-size: 10.5px;
  font-weight: 600;
  background-color: #f1f5f9;
  color: #64748b;
  padding: 2px 6px;
  border-radius: 4px;
  user-select: none;
}

.derived-field-display {
  display: flex;
  align-items: center;
  height: 38px;
  border: 1px dashed #cbd5e1;
  border-radius: 8px;
  padding: 0 12px;
  background-color: #f8fafc;
  color: #0f172a;
  font-size: 13px;
  font-weight: 500;
}

/* Rich Text Editor Section */
.rich-editor-section {
  margin-top: 10px;
}

.rich-editor-container {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  overflow: hidden;
}

.editor-toolbar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 8px 12px;
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.toolbar-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #64748b;
  font-size: 13px;
  cursor: pointer;
}
.toolbar-btn:hover {
  background-color: #e2e8f0;
  color: #0f172a;
}

.toolbar-divider {
  width: 1px;
  height: 16px;
  background-color: #cbd5e1;
  margin: 0 4px;
}

.editor-editable-area {
  min-height: 120px;
  padding: 12px 14px;
  font-size: 13px;
  color: #404040;
  line-height: 1.6;
  outline: none;
}

.editor-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px;
  border-top: 1px solid #f1f5f9;
  background-color: #fafafa;
  font-size: 11px;
  color: #94a3b8;
}

/* Child Sub-Table */
.btn-add-item-header {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 12px;
  background-color: #eff6ff;
  color: #0B529C;
  border: 1px solid #bfdbfe;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-add-item-header:hover {
  background-color: #0B529C;
  color: #ffffff;
}

.child-subtable-wrapper {
  overflow-x: auto;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.child-erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.child-erp-table th {
  height: 34px;
  padding: 6px 14px;
  background-color: #f8fafc;
  color: #737373;
  font-size: 12px;
  font-weight: 500;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
}

.child-erp-table td {
  height: 38px;
  padding: 6px 14px;
  font-size: 12.5px;
  color: #404040;
  border-bottom: 1px solid #f1f5f9;
}

.child-row-selected td {
  background-color: #f0f7ff;
}

.col-th-check { width: 36px; text-align: center; }
.col-th-no { width: 40px; }
.col-th-actions { width: 70px; text-align: right; }

.position-cell-stack {
  display: flex;
  flex-direction: column;
}

.table-name-primary {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.table-code-subtext {
  font-size: 11px;
  color: #737373;
}

.text-tertiary {
  color: #737373;
}

.row-actions-group {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 6px;
}

.btn-row-action {
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #64748b;
  cursor: pointer;
}
.btn-row-action:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.child-empty-state {
  text-align: center;
  padding: 32px 16px;
  color: #94a3b8;
  font-size: 13px;
}

.add-row-action-footer {
  margin-top: 10px;
}

.btn-add-row {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 12px;
  background-color: #ffffff;
  border: 1px dashed #cbd5e1;
  border-radius: 8px;
  font-size: 12.5px;
  color: #475569;
  cursor: pointer;
}
.btn-add-row:hover {
  background-color: #f8fafc;
  border-color: #0B529C;
  color: #0B529C;
}

/* Modal */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 16px;
}

.modal-card {
  background-color: #ffffff;
  border-radius: 12px;
  width: 100%;
  max-width: 520px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #f1f5f9;
}

.modal-title {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.btn-modal-close {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 4px;
}

.modal-body {
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.modal-row-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.simple-textarea {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #404040;
  outline: none;
  resize: vertical;
  font-family: inherit;
}
.simple-textarea:focus {
  border-color: #0B529C;
}

.modal-footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 20px;
  border-top: 1px solid #f1f5f9;
  background-color: #fafafa;
}
</style>
