<!--
  Authoritative QMT ApprovalWorkflowRail Component
  (Figma 7009:114669, 9066:90379, 9066:90727 & 10944:42263)
  =======================================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Mandatory right-hand approval sidebar (`360px` expanded, `68px` collapsed Focus mode)
    for ALL Archetype 1 Two-Column Split Workflow Detail pages across Haleta ERP
    (Employee Movements, Leave Requests, Leave Allocations, Leave Encashments,
    Procurement Plans, Supplier Registrations, etc.).

  STRICT INVARIANTS:
  1. Sidebar Collapse / Expand Icon: ALWAYS uses the authoritative QMT `PanelLeft`
     (`sidebar open` in QMT Team Library / DashboardLayout) — NEVER `PanelRightClose`
     or `PanelRightOpen` (which carry arrows not present in QMT Team Library).
  2. Step Cards MUST Always Have Background Surface:
     Every step in the multi-stage approval/progress stepper MUST render inside a
     `.step-card` surface (`background: #fafafa; border: 1px solid #e5e5e5;
     border-radius: 16px; padding: 12px 20px;`) — NEVER bare text sitting on white.
  3. Dynamic Circle Centering & Dual Linear Gradient Connectors:
     `44px × 44px` step circles (`done` #0b529c Check, `active` #fe9a00 Clock,
     `error` #e7000b X, `queued` #e5e5e5 / #d4d4d4 Clock) are dynamically Y-centered
     on each `.step-card` via `ResizeObserver` and joined by 2px linear-gradient lines.
  4. Never render inline `.toast-bar` banners inside the rail — use `useToast()`.
-->
<script setup lang="ts">
import { ref, watch, nextTick, onMounted, onUnmounted } from 'vue';
import { PanelLeft, Check, Clock, X, ShieldCheck, AlertCircle } from 'lucide-vue-next';
import AppButton from './AppButton.vue';
import FormSelect from './FormSelect.vue';
import FormTextarea from './FormTextarea.vue';

export type ApprovalStepState = 'done' | 'active' | 'queued' | 'error';

export interface ApprovalWorkflowStep {
  id?: string | number;
  title: string;
  subtitle?: string;
  timestamp?: string;
  remarks?: string;
  state: ApprovalStepState;
}

export interface ApprovalResolutionOption {
  value: string;
  label: string;
}

export interface ApprovalStatusSummary {
  variant: 'approved' | 'rejected' | 'returned' | 'waiting';
  sectionTitle: string;
  sectionDescription: string;
  sealHeading?: string;
  sealMeta?: string;
  signatoryName?: string;
  signatoryRole?: string;
  quote?: string;
}

const props = withDefaults(
  defineProps<{
    /** Controlled Focus (collapsed) state via v-model:collapsed */
    collapsed?: boolean;
    /** Whether the current user can submit a decision right now */
    canDecide?: boolean;
    /** Approver Decision section heading */
    decisionTitle?: string;
    /** Approver Decision section helper subtitle */
    decisionDescription?: string;
    /** Bound Resolution dropdown value (v-model:resolution) */
    resolution?: string;
    /** Available resolution options */
    resolutionOptions?: ApprovalResolutionOption[];
    /** Resolution select placeholder */
    resolutionPlaceholder?: string;
    /** Resolution field validation error */
    resolutionError?: string;
    /** Bound Remark textarea value (v-model:remark) */
    remark?: string;
    /** Remark placeholder */
    remarkPlaceholder?: string;
    /** Remark field validation error */
    remarkError?: string;
    /** Values in resolution that should style Submit Decision as destructive */
    destructiveResolutions?: string[];
    /** Submit button label */
    submitLabel?: string;
    /** Loading state on Submit Decision button */
    submitting?: boolean;
    /** Summary card displayed in Section 1 when `canDecide` is false */
    statusSummary?: ApprovalStatusSummary | null;
    /** Fallback plain note when `canDecide` is false and no `statusSummary` is passed */
    waitingNote?: string;
    /** Stepper section heading (e.g., "Approval Steps", "Registration Steps") */
    stepsTitle?: string;
    /** Stepper section subtitle */
    stepsSubtitle?: string;
    /** Multi-stage workflow steps; omit or pass empty array for single-approval rails */
    steps?: ApprovalWorkflowStep[];
    /** Accessible tooltip when expanded */
    collapseTooltip?: string;
    /** Accessible tooltip when collapsed */
    expandTooltip?: string;
  }>(),
  {
    collapsed: false,
    canDecide: false,
    decisionTitle: 'Approver Decision',
    decisionDescription:
      'You are authorized to review and sign off on this record. Please enter optional remarks before submitting your decision.',
    resolution: '',
    resolutionOptions: () => [],
    resolutionPlaceholder: 'Select Resolution',
    resolutionError: '',
    remark: '',
    remarkPlaceholder: 'Enter your decision reason...',
    remarkError: '',
    destructiveResolutions: () => ['reject', 'rejected'],
    submitLabel: 'Submit Decision',
    submitting: false,
    statusSummary: null,
    waitingNote: '',
    stepsTitle: 'Approval Steps',
    stepsSubtitle: 'Sequential multi-stage authorization workflow.',
    steps: () => [],
    collapseTooltip: 'Minimize sidebar to focus on dossier',
    expandTooltip: 'Expand approval sidebar'
  }
);

const emit = defineEmits<{
  (e: 'update:collapsed', value: boolean): void;
  (e: 'update:resolution', value: string): void;
  (e: 'update:remark', value: string): void;
  (e: 'submit'): void;
}>();

const toggleFocusMode = () => {
  emit('update:collapsed', !props.collapsed);
};

// ─── Dynamic Stepper Circle Centering & Connector Geometry ───────────────────
const stepperContentRef = ref<HTMLElement | null>(null);
const trackPositions = ref<{
  circles: { top: number }[];
  lines: { top: number; height: number }[];
}>({ circles: [], lines: [] });

const STEP_HEX: Record<ApprovalStepState, string> = {
  done: '#0b529c',
  active: '#fe9a00',
  queued: '#d4d4d4',
  error: '#e7000b'
};

const connectorStyle = (index: number) => {
  const from = props.steps[index]?.state ?? 'queued';
  const to = props.steps[index + 1]?.state ?? 'queued';
  const linePos = trackPositions.value.lines[index];
  const bg =
    from === to
      ? STEP_HEX[from]
      : `linear-gradient(180deg, ${STEP_HEX[from]} 0%, ${STEP_HEX[to]} 100%)`;
  return {
    top: linePos ? `${linePos.top}px` : undefined,
    height: linePos ? `${linePos.height}px` : undefined,
    background: bg
  };
};

const updateStepperAlignment = () => {
  if (!stepperContentRef.value || props.collapsed) return;
  const cards = Array.from(
    stepperContentRef.value.querySelectorAll('.step-card')
  ) as HTMLElement[];
  if (!cards.length) {
    trackPositions.value = { circles: [], lines: [] };
    return;
  }

  const containerRect = stepperContentRef.value.getBoundingClientRect();
  const circles: { top: number }[] = [];
  const lines: { top: number; height: number }[] = [];

  cards.forEach((card) => {
    const rect = card.getBoundingClientRect();
    const center = rect.top - containerRect.top + rect.height / 2;
    circles.push({ top: Math.round(center - 22) });
  });

  for (let i = 0; i < circles.length - 1; i++) {
    const lineTop = circles[i].top + 44;
    const lineHeight = Math.max(0, circles[i + 1].top - lineTop);
    lines.push({ top: lineTop, height: lineHeight });
  }

  trackPositions.value = { circles, lines };
};

let resizeObserver: ResizeObserver | null = null;

const attachObserver = () => {
  if (resizeObserver) {
    resizeObserver.disconnect();
    resizeObserver = null;
  }
  if (stepperContentRef.value && typeof ResizeObserver !== 'undefined') {
    resizeObserver = new ResizeObserver(() => updateStepperAlignment());
    resizeObserver.observe(stepperContentRef.value);
  }
};

onMounted(() => {
  nextTick(() => {
    updateStepperAlignment();
    attachObserver();
  });
});

watch(
  () => [props.steps, props.collapsed],
  () => {
    nextTick(() => {
      updateStepperAlignment();
      attachObserver();
    });
  },
  { deep: true }
);

onUnmounted(() => {
  if (resizeObserver) resizeObserver.disconnect();
});
</script>

<template>
  <aside class="approval-rail" :class="{ 'is-collapsed': collapsed }">
    <!-- Collapsed Focus Rail State (68px slim bar) -->
    <div v-if="collapsed" class="rail-card rail-card-collapsed">
      <button
        type="button"
        class="btn-sidebar-collapsed"
        :title="expandTooltip"
        :aria-label="expandTooltip"
        @click="toggleFocusMode"
      >
        <PanelLeft :size="20" class="btn-focus-icon" />
      </button>
    </div>

    <!-- Expanded Approval Workflow Rail (360px) -->
    <div v-else class="rail-card">
      <!-- Top Focus Button using authoritative QMT PanelLeft (sidebar open) icon -->
      <div class="focus-btn-row">
        <button
          type="button"
          class="btn-focus"
          :title="collapseTooltip"
          :aria-label="collapseTooltip"
          @click="toggleFocusMode"
        >
          <PanelLeft :size="18" class="btn-focus-icon" />
          <span>Focus</span>
        </button>
      </div>

      <!-- SECTION 1: APPROVER DECISION OR STATUS SUMMARY -->
      <slot name="decision">
        <section v-if="canDecide" class="rail-section">
          <div class="section-title-block">
            <h3 class="section-heading">{{ decisionTitle }}</h3>
            <p v-if="decisionDescription" class="section-desc">{{ decisionDescription }}</p>
          </div>

          <div class="decision-form">
            <FormSelect
              :modelValue="resolution"
              label="Resolution"
              :options="resolutionOptions"
              :placeholder="resolutionPlaceholder"
              :error="resolutionError"
              required
              @update:modelValue="(val) => emit('update:resolution', String(val ?? ''))"
            />

            <FormTextarea
              :modelValue="remark"
              label="Remark"
              :placeholder="remarkPlaceholder"
              :rows="3"
              :error="remarkError"
              @update:modelValue="(val) => emit('update:remark', String(val ?? ''))"
            />

            <slot name="decision-extra" />

            <AppButton
              :variant="destructiveResolutions.includes(resolution) ? 'destructive' : 'primary'"
              size="md"
              class="btn-submit-decision"
              :loading="submitting"
              :disabled="submitting"
              @click="emit('submit')"
            >
              {{ submitLabel }}
            </AppButton>
          </div>
        </section>

        <!-- Non-interactive Status Card (Approved / Rejected / Returned / Waiting) -->
        <section v-else-if="statusSummary" class="rail-section">
          <div class="section-title-block">
            <h3 class="section-heading">{{ statusSummary.sectionTitle }}</h3>
            <p v-if="statusSummary.sectionDescription" class="section-desc">
              {{ statusSummary.sectionDescription }}
            </p>
          </div>

          <div
            class="status-signoff-card"
            :class="`status-signoff-${statusSummary.variant}`"
          >
            <div v-if="statusSummary.sealHeading" class="seal-header">
              <div class="seal-icon-wrap" :class="`seal-wrap-${statusSummary.variant}`">
                <ShieldCheck
                  v-if="statusSummary.variant === 'approved'"
                  :size="18"
                  class="seal-icon-approved"
                />
                <X
                  v-else-if="statusSummary.variant === 'rejected'"
                  :size="18"
                  class="seal-icon-rejected"
                />
                <AlertCircle
                  v-else-if="statusSummary.variant === 'returned'"
                  :size="18"
                  class="seal-icon-returned"
                />
                <Clock v-else :size="18" class="seal-icon-waiting" />
              </div>
              <div class="seal-titles">
                <span class="seal-heading" :class="`seal-heading-${statusSummary.variant}`">
                  {{ statusSummary.sealHeading }}
                </span>
                <span v-if="statusSummary.sealMeta" class="seal-meta-date">
                  {{ statusSummary.sealMeta }}
                </span>
              </div>
            </div>

            <div v-if="statusSummary.signatoryName" class="signatory-row">
              <div class="signatory-meta">
                <span class="signatory-name">{{ statusSummary.signatoryName }}</span>
                <span v-if="statusSummary.signatoryRole" class="signatory-role">
                  {{ statusSummary.signatoryRole }}
                </span>
              </div>
            </div>

            <div v-if="statusSummary.quote" class="approval-quote-box">
              <p class="approval-quote-text">&ldquo;{{ statusSummary.quote }}&rdquo;</p>
            </div>
          </div>

          <slot name="decision-actions" />
        </section>

        <section v-else class="rail-section">
          <div class="section-title-block">
            <h3 class="section-heading">{{ decisionTitle }}</h3>
            <p v-if="waitingNote" class="section-desc">{{ waitingNote }}</p>
          </div>
        </section>
      </slot>

      <!-- SECTION 2: LIVING MULTI-STAGE STEPPER (with .step-card #FAFAFA backgrounds) -->
      <template v-if="steps.length > 0">
        <hr class="rail-divider" />

        <section class="rail-section">
          <div class="section-title-block">
            <h3 class="section-heading">{{ stepsTitle }}</h3>
            <p v-if="stepsSubtitle" class="section-desc">{{ stepsSubtitle }}</p>
          </div>

          <div class="stepper-wrap">
            <!-- Left 44px Circle & Gradient Connector Track -->
            <div class="stepper-track">
              <template v-for="(step, idx) in steps" :key="`track-${step.id ?? idx}`">
                <div
                  class="step-circle"
                  :class="`step-circle-${step.state}`"
                  :style="
                    trackPositions.circles[idx]
                      ? { top: `${trackPositions.circles[idx].top}px` }
                      : undefined
                  "
                  :title="step.title"
                >
                  <Check
                    v-if="step.state === 'done'"
                    :size="20"
                    class="step-icon-white"
                    :stroke-width="2.5"
                  />
                  <X
                    v-else-if="step.state === 'error'"
                    :size="20"
                    class="step-icon-white"
                    :stroke-width="2.5"
                  />
                  <Clock
                    v-else-if="step.state === 'active'"
                    :size="20"
                    class="step-icon-white"
                    :stroke-width="2"
                  />
                  <Clock
                    v-else
                    :size="20"
                    class="step-icon-disabled"
                    :stroke-width="2"
                  />
                </div>

                <div
                  v-if="idx < steps.length - 1"
                  class="step-line"
                  :style="connectorStyle(idx)"
                ></div>
              </template>
            </div>

            <!-- Right Step Content Cards Stack (mandatory #FAFAFA card surfaces) -->
            <div ref="stepperContentRef" class="stepper-content">
              <div
                v-for="(step, idx) in steps"
                :key="step.id ?? idx"
                class="step-card"
              >
                <div class="step-meta">
                  <span
                    class="step-title"
                    :class="{ 'is-muted': step.state === 'queued' }"
                  >
                    {{ step.title }}
                  </span>
                  <span
                    v-if="step.subtitle"
                    class="step-subtitle"
                    :class="{ 'is-muted': step.state === 'queued' }"
                  >
                    {{ step.subtitle }}
                  </span>
                  <span
                    v-if="step.timestamp"
                    class="step-timestamp"
                    :class="{ 'is-muted': step.state === 'queued' }"
                  >
                    {{ step.timestamp }}
                  </span>
                </div>
                <div v-if="step.remarks" class="step-quote-box">
                  <p class="step-quote-text">&ldquo;{{ step.remarks }}&rdquo;</p>
                </div>
              </div>
            </div>
          </div>
        </section>
      </template>
    </div>
  </aside>
</template>

<style scoped>
.approval-rail {
  display: flex;
  flex-direction: column;
  width: 100%;
  max-width: 360px;
  transition: max-width 0.25s ease;
}

.approval-rail.is-collapsed {
  max-width: 68px;
  width: 68px;
}

.rail-card {
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 16px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  box-sizing: border-box;
}

.rail-card-collapsed {
  padding: 20px 16px;
  align-items: center;
  min-height: 520px;
}

.focus-btn-row {
  display: flex;
  justify-content: flex-start;
}

.btn-focus,
.btn-sidebar-collapsed {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  background-color: #ffffff;
  border: 1px solid #d4d4d4;
  border-radius: 8px;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
  font-family: inherit;
  font-size: 14px;
  font-weight: 600;
  line-height: 20px;
  color: var(--alias-color-text-secondary, #404040);
  cursor: pointer;
  transition: background-color 0.15s ease, border-color 0.15s ease;
  outline: none;
}

.btn-focus {
  padding: 8px 14px;
}

.btn-sidebar-collapsed {
  width: 36px;
  height: 36px;
  padding: 8px;
}

.btn-focus:hover,
.btn-sidebar-collapsed:hover {
  background-color: #fafafa;
  border-color: #bdbdbd;
}

.btn-focus-icon {
  color: var(--alias-color-icon-secondary, #404040);
  flex-shrink: 0;
}

.rail-section {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.section-title-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.section-heading {
  font-size: 20px;
  font-weight: 600;
  line-height: 28px;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
}

.section-desc {
  font-size: 14px;
  line-height: 20px;
  color: var(--alias-color-text-tertiary, #737373);
  margin: 0;
}

.decision-form {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.btn-submit-decision {
  width: 100%;
}

.rail-divider {
  border: none;
  border-top: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  margin: 4px 0;
  width: 100%;
}

/* Status Sign-off Cards (Non-pending states) */
.status-signoff-card {
  border-radius: 12px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  background-color: #fafafa;
  border: 1px solid #e5e5e5;
}

.status-signoff-approved {
  background-color: #ecfdf5;
  border-color: #a7f3d0;
}

.status-signoff-rejected {
  background-color: #fef2f2;
  border-color: #fecaca;
}

.status-signoff-returned {
  background-color: #fffbeb;
  border-color: #fde68a;
}

.status-signoff-waiting {
  background-color: #fafafa;
  border-color: #e5e5e5;
}

.seal-header {
  display: flex;
  align-items: center;
  gap: 10px;
}

.seal-icon-wrap {
  width: 32px;
  height: 32px;
  border-radius: 9999px;
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.seal-wrap-approved {
  border-color: #6ee7b7;
}

.seal-wrap-rejected {
  border-color: #fca5a5;
}

.seal-wrap-returned {
  border-color: #fcd34d;
}

.seal-icon-approved {
  color: #009966;
}

.seal-icon-rejected {
  color: #e7000b;
}

.seal-icon-returned {
  color: #e17100;
}

.seal-icon-waiting {
  color: #737373;
}

.seal-titles {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.seal-heading {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.seal-heading-approved {
  color: #065f46;
}

.seal-heading-rejected {
  color: #b91c1c;
}

.seal-heading-returned {
  color: #b45309;
}

.seal-meta-date {
  font-size: 11px;
  color: #737373;
}

.signatory-row {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  padding: 8px 12px;
}

.signatory-meta {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.signatory-name {
  font-size: 13px;
  font-weight: 600;
  color: #404040;
}

.signatory-role {
  font-size: 11px;
  color: #737373;
}

.approval-quote-box {
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  padding: 8px 12px;
}

.approval-quote-text {
  font-size: 12px;
  line-height: 18px;
  color: #404040;
  margin: 0;
}

/* Living Multi-Stage Stepper (Figma 7009:114683 & 10944:42277) */
.stepper-wrap {
  display: flex;
  gap: 16px;
  align-items: stretch;
  position: relative;
  width: 100%;
}

.stepper-track {
  width: 44px;
  position: relative;
  flex-shrink: 0;
  min-height: 100%;
}

.step-circle {
  width: 44px;
  height: 44px;
  border-radius: 9999px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-sizing: border-box;
  position: absolute;
  left: 0;
  z-index: 2;
  transition: top 0.15s ease;
}

.step-circle-done {
  background-color: var(--color-brand-blue-primary, #0b529c);
}

.step-circle-active {
  background-color: var(--color-warning-500, #fe9a00);
}

.step-circle-error {
  background-color: var(--color-error-500, #e7000b);
}

.step-circle-queued {
  background-color: var(--color-background-tertiary, #e5e5e5);
  border: 1px solid var(--color-border-primary, #d4d4d4);
}

.step-icon-white {
  color: #ffffff;
}

.step-icon-disabled {
  color: #ffffff;
  opacity: 0.9;
}

.step-line {
  position: absolute;
  left: 21px;
  width: 2px;
  z-index: 1;
  transition: top 0.15s ease, height 0.15s ease;
}

.stepper-content {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.step-card {
  background-color: var(--color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 16px;
  padding: 12px 18px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.step-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
  line-height: 18px;
}

.step-title {
  font-size: 13px;
  font-weight: 600;
  color: var(--alias-color-text-secondary, #404040);
}

.step-subtitle {
  font-size: 12px;
  color: var(--alias-color-text-tertiary, #737373);
}

.step-timestamp {
  font-size: 11px;
  color: var(--alias-color-text-tertiary, #737373);
}

.step-quote-box {
  background-color: #f5f5f5;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 8px;
  padding: 8px 12px;
}

.step-quote-text {
  font-size: 12px;
  line-height: 18px;
  color: var(--alias-color-text-secondary, #404040);
  margin: 0;
}

.is-muted {
  color: #a1a1a1 !important;
}

@media (max-width: 1100px) {
  .approval-rail,
  .approval-rail.is-collapsed {
    max-width: 100%;
    width: 100%;
  }

  .rail-card-collapsed {
    min-height: auto;
  }
}
</style>
