<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  X, Calendar, ShieldCheck, User,
  CheckCircle2, FileText, Clock
} from 'lucide-vue-next';;
import FormSelect from '../../components/FormSelect.vue';
import FormRichText from '../../components/FormRichText.vue';
import SaveStateBadge from '../../components/SaveStateBadge.vue';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import AppButton from '../../components/AppButton.vue';
import { useToast } from '../../composables/useToast';

const router = useRouter();
const route = useRoute();

// ─── Dual Role Persona (Executive Approver vs Department Creator) ───
const userRole = ref<'approver' | 'creator'>('creator');

// ─── Breadcrumb Navigation ───
const breadcrumbItems = computed(() => [
  { label: 'Headcount Budgets', to: '/hr/headcount-planning' },
  { label: userRole.value === 'approver' ? 'Approve Headcount Budgets' : 'Create Headcount Budgets' }
]);

// ─── Lifecycle & Save State ───
const { toast } = useToast();
const isSaved = ref(false);
const planId = ref<number | null>(null);

// ─── Master Form State (Direct 1:1 Mapping to hr_headcount_budgets Schema) ───
const form = ref({
  entity_id: 7,
  organization_unit_id: 5,
  fiscal_year: 'FY 2026/27',
  period_start: '2026-08-07', // 07/08/2026
  period_end: '2027-07-07',   // 07/07/2027
  approved_headcount: 5,
  annual_budget_amount: 900000,
  currency_id: 'ETB',
  budget_state: 'draft' as 'draft' | 'approved' | 'active' | 'closed',
  notes: 'Urgent workforce request to establish a dedicated in-house Talent Acquisition and People Operations team to oversee recruitment, staffing, onboarding, employee relations, and workforce planning across regional hospitality branches, ensuring each location has the right talent and operational support to meet business needs.'
});

// Submitter Context for Approver Review Banner (Matching Image 5)
const submitterInfo = ref({
  name: 'Almaz Ayana',
  title: 'Head of People & Operation',
  unit: 'People & Culture (HR-PEOPLE)',
  initials: 'AA',
  submitted_at: '12/06/2026 at 15:40 GC',
  fiscal_target: 'FY-2027',
  branch: 'Haleta Addis Ababa Hospitality',
  monthly_cap: '75,000 ETB / mo',
  line_allocations: '5/5 Seats Distributed',
  seat_buffer: '0 Seats',
  justification: 'Urgent workforce request to establish a dedicated in-house Talent Acquisition and People Operations team to oversee recruitment, staffing, onboarding, employee relations, and workforce planning across regional hospitality branches, ensuring each location has the right talent and operational support to meet business needs.'
});

// Derived Monthly Cap Calculation for Creator Mode (annual / 12)
const computedMonthlyCapDisplay = computed(() => {
  const annual = Number(form.value.annual_budget_amount);
  if (!annual || isNaN(annual) || annual === 0) return '---- ETB / mo';
  const monthly = Math.round(annual / 12);
  return `${monthly.toLocaleString()} ${form.value.currency_id} / mo`;
});

// Options for Dropdowns
const entityOptions = [
  { value: 7, label: 'Haleta Addis Ababa Hospitality' },
  { value: 3, label: 'Haleta Technologies Group' },
  { value: 9, label: 'Haleta Logistics & Cargo' }
];

const orgUnitOptions = [
  { value: 5, label: 'People & Culture (HR-PEOPLE)' },
  { value: 3, label: 'Commercial Sales (COMM-SALES)' },
  { value: 2, label: 'Engineering & Technology (ENG-TECH)' },
  { value: 1, label: 'Finance & Compliance (FIN-CORP)' }
];

const currencyOptions = [
  { value: 'ETB', label: 'ETB' },
  { value: 'USD', label: 'USD' },
  { value: 'EUR', label: 'EUR' }
];

// Toast
const showToast = (msg: string) => {
  toast.success(msg);
};

// Actions
const handleClearForm = () => {
  form.value = {
    entity_id: 0,
    organization_unit_id: 0,
    fiscal_year: '',
    period_start: '',
    period_end: '',
    approved_headcount: 0,
    annual_budget_amount: 0,
    currency_id: 'ETB',
    budget_state: 'draft',
    notes: ''
  };
  isSaved.value = false;
  showToast('Form cleared.');
};

const handleSave = () => {
  isSaved.value = true;
  form.value.budget_state = 'draft';
  showToast('Headcount budget proposal saved.');
  setTimeout(() => {
    router.push('/hr/headcount-planning');
  }, 1000);
};

const handleApprove = () => {
  form.value.budget_state = 'approved';
  isSaved.value = true;
  showToast('Headcount budget formally sanctioned and approved.');
  setTimeout(() => {
    router.push('/hr/headcount-planning');
  }, 1000);
};

const handleCancel = () => {
  router.push('/hr/headcount-planning');
};

onMounted(() => {
  if (route.query.role === 'approver') {
    userRole.value = 'approver';
  } else if (route.query.role === 'creator') {
    userRole.value = 'creator';
  } else if (route.query.id || route.params.id) {
    userRole.value = 'approver';
  }
});
</script>

<template>
  <div class="headcount-create-page">
    <!-- Top Action & Breadcrumb Navigation Bar (Exact to Image 3 & Image 5) -->
    <div class="page-top-action-bar">
      <!-- Breadcrumbs Cluster -->
      <div class="breadcrumb-cluster">
        <AppBreadcrumb :items="breadcrumbItems" noMargin>
          <template #badge>
            <SaveStateBadge
              :isSaved="isSaved"
              :state="userRole === 'creator' ? 'unsaved' : form.budget_state"
            />
          </template>
        </AppBreadcrumb>
      </div>

      <!-- Right Action Cluster -->
      <div class="top-actions-cluster">
        <!-- Role Persona Switcher (For Interactive Testing between Image 3 & Image 5) -->
        <div class="role-pill-group">
          <button 
            type="button" 
            class="role-pill-btn"
            :class="{ 'role-active': userRole === 'creator' }"
            @click="userRole = 'creator'"
            title="Switch to Creator Mode (Image 3)"
          >
            <User :size="13" />
            <span>Creator</span>
          </button>
          <button 
            type="button" 
            class="role-pill-btn"
            :class="{ 'role-active': userRole === 'approver' }"
            @click="userRole = 'approver'"
            title="Switch to Approver Mode (Image 5)"
          >
            <ShieldCheck :size="13" />
            <span>Approver</span>
          </button>
        </div>

        <!-- Creator Actions (Image 3: "[ ✕ Clear Form ] [ Save ]") -->
        <template v-if="userRole === 'creator'">
          <AppButton 
            variant="outline" 
            size="sm" 
            @click="handleClearForm"
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
        </template>

        <!-- Approver Actions (Image 5: "[ Cancel ] [ Approve ]") -->
        <template v-else>
          <AppButton 
            variant="outline" 
            size="sm" 
            @click="handleCancel"
          >
            Cancel
          </AppButton>

          <AppButton 
            variant="primary" 
            size="sm" 
            @click="handleApprove"
          >
            Approve
          </AppButton>
        </template>
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════════════ -->
    <!-- MODE A: CREATOR FORM (Exact to Image 3: "Create Headcount Budgets") -->
    <!-- ═══════════════════════════════════════════════════════════════════ -->
    <div v-if="userRole === 'creator'" class="form-master-card">
      <!-- Row 1: Owning Entity (2 cols) -->
      <div class="form-grid-2col">
        <FormSelect
          label="Owning Entity"
          v-model="form.entity_id"
          :options="entityOptions"
          placeholder="Select Entity"
        />

        <FormSelect
          label="Organization Unit *"
          v-model="form.organization_unit_id"
          :options="orgUnitOptions"
          placeholder="Select Unit"
          required
        />
      </div>

      <!-- Row 2: Effective Dates & Fiscal Year (3 cols) -->
      <div class="form-grid-3col">
        <!-- Effective From Date * -->
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

        <!-- Effective Until Date * -->
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

        <!-- Fiscal Year with helper subtext -->
        <div class="form-field-wrap">
          <label class="field-label">Fiscal Year</label>
          <input 
            type="text" 
            v-model="form.fiscal_year"
            class="standard-text-input"
          />
          <p class="field-helper-hint">
            This section takes the Fiscal year text Two starting letters FY and mentions the year that the effecting date will be on.
          </p>
        </div>
      </div>

      <!-- Row 3: Targeted Headcount Capacity (Seats) * (3 cols grid with col 1 populated) -->
      <div class="form-grid-3col">
        <div class="form-field-wrap">
          <label class="field-label">Targeted Headcount Capacity (Seats) <span class="required-star">*</span></label>
          <input 
            type="number" 
            v-model.number="form.approved_headcount" 
            class="standard-text-input font-mono"
            min="0"
            required 
          />
        </div>
        <div></div>
        <div></div>
      </div>

      <!-- Row 4: Currency *, Annual Salary Budget *, Est. Monthly Payroll Cap (3 cols) -->
      <div class="form-grid-3col">
        <FormSelect
          label="Currency *"
          v-model="form.currency_id"
          :options="currencyOptions"
          required
        />

        <div class="form-field-wrap">
          <label class="field-label">Annual Rolled-up Salary Budget <span class="required-star">*</span></label>
          <input 
            type="number" 
            v-model.number="form.annual_budget_amount" 
            class="standard-text-input font-mono"
            min="0"
            required 
          />
        </div>

        <div class="form-field-wrap">
          <label class="field-label">Est. Monthly Payroll Cap (Derived)</label>
          <div class="derived-readonly-box font-mono">
            {{ computedMonthlyCapDisplay }}
          </div>
        </div>
      </div>

      <!-- Row 5: Capacity Justification with Standard Rich Text Component -->
      <div class="form-field-wrap full-width mt-2">
        <FormRichText
          v-model="form.notes"
          label="Capacity Justification"
          placeholder="Provide strategic justification for this headcount allocation request..."
          :max-length="5000"
        />
      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════════════ -->
    <!-- MODE B: APPROVER VIEW (Exact to Image 5: "Approve Headcount Budgets")-->
    <!-- ═══════════════════════════════════════════════════════════════════ -->
    <div v-else class="approver-view-container">
      <!-- Card 1: Submitter Context & Justification Card (Matching Image 5) -->
      <div class="approver-summary-card">
        <!-- Submitter Top Row -->
        <div class="submitter-row">
          <div class="submitter-identity-cluster">
            <!-- Avatar photo/circle -->
            <div class="submitter-photo-circle">
              <img src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=120&auto=format&fit=crop&q=80" alt="Almaz Ayana" class="submitter-avatar-img" />
            </div>

            <div class="submitter-info-stack">
              <div class="name-and-tags-row">
                <span class="submitter-display-name">{{ submitterInfo.name }}</span>
                <span class="tag-title-gray">{{ submitterInfo.title }}</span>
                <span class="tag-unit-blue">{{ submitterInfo.unit }}</span>
              </div>
              <div class="meta-subtext-line">
                <span>Submitted on {{ submitterInfo.submitted_at }}</span>
                <span class="meta-dot">•</span>
                <span>Fiscal Target: <strong>{{ submitterInfo.fiscal_target }}</strong></span>
                <span class="meta-dot">•</span>
                <span>Branch: <strong>{{ submitterInfo.branch }}</strong></span>
              </div>
            </div>
          </div>

          <!-- Awaiting Executive Approval Status Pill (Far Right) -->
          <div class="status-right-col">
            <span class="awaiting-approval-pill">
              <Clock :size="12" />
              <span>Awaiting Executive Approval</span>
            </span>
          </div>
        </div>

        <!-- Derived Stats Pill Row (Capsule Container from Image 5) -->
        <div class="derived-stats-capsule-box">
          <div class="stat-capsule-item">
            <span class="stat-capsule-text">Derived Monthly Run-Rate Cap: <strong>{{ submitterInfo.monthly_cap }}</strong></span>
          </div>
          <div class="stat-capsule-item">
            <span class="stat-capsule-text">Position Line Allocations: <strong>{{ submitterInfo.line_allocations }}</strong></span>
          </div>
          <div class="stat-capsule-item">
            <span class="stat-capsule-text">unallocated Seat Buffer: <strong>{{ submitterInfo.seat_buffer }}</strong></span>
          </div>
        </div>

        <!-- Capacity Justification Callout Box (Matching Image 5) -->
        <div class="justification-callout-panel">
          <div class="callout-header-row">
            <FileText :size="14" class="text-slate-500" />
            <span class="callout-header-title">Capacity Justification</span>
          </div>
          <p class="callout-body-paragraph">
            {{ submitterInfo.justification }}
          </p>
        </div>
      </div>

      <!-- Card 2: Budget Plan Specifications - Approver Editable (Matching Image 5) -->
      <div class="plan-specifications-card">
        <h3 class="specifications-card-title">Budget Plan Specifications - Approver Editable</h3>

        <!-- Row 1: Effective From Date *, Effective Until Date *, Fiscal Year * -->
        <div class="form-grid-3col">
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

          <div class="form-field-wrap">
            <label class="field-label">Fiscal Year <span class="required-star">*</span></label>
            <input 
              type="text" 
              v-model="form.fiscal_year"
              class="standard-text-input"
              required 
            />
            <p class="field-helper-hint">
              This section takes the Fiscal year text Two starting letters FY and mentions the year that the effecting date will be on.
            </p>
          </div>
        </div>

        <!-- Row 2: Targeted Headcount Capacity (Seats) *, Currency *, Annual Rolled-up Salary Budget * -->
        <div class="form-grid-3col mt-3">
          <div class="form-field-wrap">
            <label class="field-label">Targeted Headcount Capacity (Seats) <span class="required-star">*</span></label>
            <input 
              type="number" 
              v-model.number="form.approved_headcount" 
              class="standard-text-input font-mono"
              min="0"
              required 
            />
          </div>

          <FormSelect
            label="Currency *"
            v-model="form.currency_id"
            :options="currencyOptions"
            required
          />

          <div class="form-field-wrap">
            <label class="field-label">Annual Rolled-up Salary Budget <span class="required-star">*</span></label>
            <input 
              type="number" 
              v-model.number="form.annual_budget_amount" 
              class="standard-text-input font-mono"
              min="0"
              required 
            />
          </div>
        </div>
      </div>

      <!-- Section 3: Headcount Plan Audit Trail (Matching Image 5) -->
      <div class="audit-trail-section">
        <h3 class="audit-section-heading">Headcount Plan Audit Trail</h3>

        <div class="audit-timeline-container">
          <!-- Step 1: Headcount Planed Submitted -->
          <div class="timeline-step-row">
            <div class="timeline-bullet-col">
              <div class="bullet-dot-black"></div>
              <div class="timeline-line-connector"></div>
            </div>
            <div class="timeline-body-col">
              <div class="timeline-headline">
                <span class="font-bold text-slate-800">Headcount Planed Submitted</span>
                <span class="text-slate-600"> on 12/06/2026 at 15:40 GC</span>
              </div>
              <div class="timeline-sub-detail">
                Initiated by Almaz Ayana (Head of People & Operation)
              </div>
            </div>
          </div>

          <!-- Step 2: Executive Sanction Pending -->
          <div class="timeline-step-row">
            <div class="timeline-bullet-col">
              <div class="bullet-dot-black"></div>
            </div>
            <div class="timeline-body-col">
              <div class="timeline-headline">
                <span class="font-bold text-slate-800">Executive Sanction Pending</span>
                <span class="text-slate-600"> Awaiting Decision</span>
              </div>
              <div class="timeline-sub-detail">
                Awaiting formal review and signature from Corporate Executive Authority.
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.headcount-create-page {
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-3xl, 24px);
}

/* Page Top Action Bar (Rule 29: Clean transparent header) */
.page-top-action-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 4px 0 8px 0;
  flex-wrap: wrap;
  gap: 12px;
}

.breadcrumb-cluster {
  display: flex;
  align-items: center;
  gap: 8px;
}

.breadcrumb-root-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #737373;
  transition: color 0.15s ease;
}

.breadcrumb-root-btn:hover {
  color: #404040;
}

.breadcrumb-separator {
  color: #cbd5e1;
}

.breadcrumb-link {
  font-size: 13.5px;
  color: #737373;
  cursor: pointer;
  transition: color 0.15s ease;
}

.breadcrumb-link:hover {
  color: #0B529C;
}

.breadcrumb-current {
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
}

/* Right Actions Cluster */
.top-actions-cluster {
  display: flex;
  align-items: center;
  gap: 10px;
}

.role-pill-group {
  display: inline-flex;
  background-color: #f5f5f5;
  padding: 2px;
  border-radius: 8px;
  gap: 2px;
}

.role-pill-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  background: transparent;
  border: none;
  cursor: pointer;
}

.role-pill-btn.role-active {
  background-color: #ffffff;
  color: #404040;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
}

.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-secondary-action:hover {
  background-color: #fafafa;
  border-color: #cbd5e1;
}

.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  padding: 0 20px;
  background-color: #0B529C;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 500;
  color: #ffffff;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-primary-action:hover {
  background-color: #09427d;
}

/* Master Form Card (Image 3) */
.form-master-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
}

/* Form Grids */
.form-grid-2col {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

.form-grid-3col {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--alias-spacing-2xl, 20px) var(--alias-spacing-xl, 16px);
}

@media (max-width: 840px) {
  .form-grid-2col,
  .form-grid-3col {
    grid-template-columns: 1fr;
  }
}

.form-field-wrap {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.form-field-wrap.full-width {
  width: 100%;
}

.field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.required-star {
  color: #ef4444;
}

.standard-text-input {
  height: 38px;
  padding: 0 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  color: #404040;
  outline: none;
  background-color: #ffffff;
  transition: border-color 0.15s ease;
}

.standard-text-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.field-helper-hint {
  font-size: 11.5px;
  color: #737373;
  margin: 2px 0 0 0;
  line-height: 1.4;
}

/* Date Composite Input with GC Badge */
.date-composite-input {
  position: relative;
  display: flex;
  align-items: center;
  height: 38px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 0 10px;
}

.date-composite-input:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.date-cal-icon {
  color: #94a3b8;
  margin-right: 6px;
  flex-shrink: 0;
}

.date-field-inner {
  border: none;
  outline: none;
  font-size: 13px;
  color: #404040;
  flex: 1;
  background: transparent;
}

.gc-badge {
  font-size: 10.5px;
  font-weight: 600;
  color: #737373;
  background-color: #f5f5f5;
  padding: 2px 6px;
  border-radius: 4px;
}

/* Derived Readonly Display Box */
.derived-readonly-box {
  height: 38px;
  display: flex;
  align-items: center;
  padding: 0 12px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #737373;
}

/* WYSIWYG Editor Styling (Image 3) */
.wysiwyg-container {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  background-color: #ffffff;
}

.wysiwyg-toolbar {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  flex-wrap: wrap;
}

.toolbar-group {
  display: flex;
  align-items: center;
  gap: 2px;
}

.toolbar-divider {
  width: 1px;
  height: 18px;
  background-color: #d4d4d4;
  margin: 0 4px;
}

.toolbar-select {
  height: 28px;
  padding: 0 6px;
  border: 1px solid #e2e8f0;
  border-radius: 5px;
  font-size: 12px;
  color: #404040;
  outline: none;
  background-color: #ffffff;
}

.toolbar-btn {
  width: 26px;
  height: 26px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  color: #737373;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.toolbar-btn:hover {
  background-color: #e5e5e5;
  color: #404040;
}

.wysiwyg-content {
  min-height: 150px;
  padding: 14px;
  font-size: 13.5px;
  color: #404040;
  line-height: 1.55;
  outline: none;
}

.wysiwyg-footer {
  padding: 6px 14px;
  border-top: 1px solid #f1f5f9;
  background-color: #ffffff;
  display: flex;
  justify-content: flex-start;
}

.char-count {
  font-size: 11.5px;
  color: #94a3b8;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* MODE B: APPROVER STYLES (Image 5)                                  */
/* ═══════════════════════════════════════════════════════════════════ */
.approver-view-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* Card 1: Submitter Context & Justification Card */
.approver-summary-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
}

.submitter-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 14px;
}

.submitter-identity-cluster {
  display: flex;
  align-items: center;
  gap: 12px;
}

.submitter-photo-circle {
  width: 44px;
  height: 44px;
  border-radius: 100px;
  overflow: hidden;
  flex-shrink: 0;
  border: 2px solid #ffffff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.submitter-avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.submitter-info-stack {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.name-and-tags-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.submitter-display-name {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
}

.tag-title-gray {
  font-size: 11.5px;
  color: #737373;
  background-color: #f5f5f5;
  padding: 2px 8px;
  border-radius: 6px;
}

.tag-unit-blue {
  font-size: 11.5px;
  color: #0284c7;
  background-color: #e0f2fe;
  padding: 2px 8px;
  border-radius: 6px;
  font-weight: 500;
}

.meta-subtext-line {
  font-size: 12px;
  color: #737373;
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.meta-dot {
  color: #94a3b8;
}

.status-right-col {
  display: flex;
  align-items: center;
}

.awaiting-approval-pill {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  background-color: #FEF3C7;
  color: #D97706;
  padding: 4px 12px;
  border-radius: 100px;
  font-size: 12px;
  font-weight: 500;
}

/* Derived Stats Capsule Box (Image 5) */
.derived-stats-capsule-box {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 8px 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  flex-wrap: wrap;
}

.stat-capsule-item {
  font-size: 12px;
  color: #737373;
}

.stat-capsule-text strong {
  color: #404040;
}

/* Capacity Justification Callout Panel (Image 5) */
.justification-callout-panel {
  background-color: #fafafa;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.callout-header-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.callout-header-title {
  font-size: 12.5px;
  font-weight: 600;
  color: #404040;
}

.callout-body-paragraph {
  font-size: 13px;
  color: #737373;
  line-height: 1.5;
  margin: 0;
}

/* Card 2: Budget Plan Specifications - Approver Editable */
.plan-specifications-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
}

.specifications-card-title {
  font-size: 14px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

/* Section 3: Headcount Plan Audit Trail */
.audit-trail-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 4px 4px 16px 4px;
}

.audit-section-heading {
  font-size: 15px;
  font-weight: 600;
  color: #404040;
  margin: 0;
}

.audit-timeline-container {
  display: flex;
  flex-direction: column;
}

.timeline-step-row {
  display: flex;
  align-items: stretch;
  gap: 12px;
}

.timeline-bullet-col {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 14px;
}

.bullet-dot-black {
  width: 7px;
  height: 7px;
  background-color: #404040;
  border-radius: 100px;
  margin-top: 5px;
  flex-shrink: 0;
}

.timeline-line-connector {
  width: 1.5px;
  flex: 1;
  background-color: #d4d4d4;
  margin: 3px 0;
  min-height: 24px;
}

.timeline-body-col {
  padding-bottom: 14px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.timeline-headline {
  font-size: 13px;
}

.timeline-sub-detail {
  font-size: 12px;
  color: #737373;
}
</style>
