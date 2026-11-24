<!--
  Authoritative QMT Alert Banner Component (Figma 10777:60848 / 10777:61788)
  ==========================================================================
  WHEN TO USE:
  - Persistent in-context page banners for operational warnings, compliance flags,
    policy mandates, maintenance notices, or inline validation summaries.
  - Supports Type: 'subtle' (tinted surface) | 'outline' (white surface + semantic border)
    and Status: 'default' | 'info' | 'success' | 'warning' | 'error'.
  - Supports optional #badges slot (e.g., clickable BadgeGroup or BaseBadge chips)
    and #actions slot.

  WHEN NOT TO USE:
  - DO NOT use for temporary feedback/confirmation messages (use useToast() / BaseToaster).
-->
<script setup lang="ts">
import { computed } from 'vue';
import { Info, CheckCircle2, AlertTriangle, AlertCircle, X } from 'lucide-vue-next';

export type AlertType = 'subtle' | 'outline';
export type AlertStatus = 'default' | 'info' | 'success' | 'warning' | 'error';

const props = withDefaults(
  defineProps<{
    type?: AlertType;
    status?: AlertStatus;
    title?: string;
    description?: string;
    showIcon?: boolean;
    closable?: boolean;
  }>(),
  {
    type: 'subtle',
    status: 'default',
    title: '',
    description: '',
    showIcon: true,
    closable: false
  }
);

const emit = defineEmits<{
  (e: 'close'): void;
}>();

const defaultIconComponent = computed(() => {
  switch (props.status) {
    case 'success':
      return CheckCircle2;
    case 'warning':
      return AlertTriangle;
    case 'error':
      return AlertCircle;
    default:
      return Info;
  }
});
</script>

<template>
  <div
    class="qmt-alert"
    :class="[`qmt-alert--type-${type}`, `qmt-alert--status-${status}`]"
    role="alert"
  >
    <div v-if="showIcon" class="qmt-alert__icon" aria-hidden="true">
      <slot name="icon">
        <component :is="defaultIconComponent" :size="20" />
      </slot>
    </div>

    <div class="qmt-alert__content">
      <div v-if="title || description || $slots.title || $slots.default" class="qmt-alert__text">
        <div v-if="title || $slots.title" class="qmt-alert__title-row">
          <span class="qmt-alert__title">
            <slot name="title">{{ title }}</slot>
          </span>
          <slot name="title-badge" />
        </div>
        <p v-if="description || $slots.default" class="qmt-alert__description">
          <slot>{{ description }}</slot>
        </p>
      </div>

      <div v-if="$slots.badges" class="qmt-alert__badges">
        <slot name="badges" />
      </div>

      <div v-if="$slots.actions" class="qmt-alert__actions">
        <slot name="actions" />
      </div>
    </div>

    <button
      v-if="closable"
      type="button"
      class="qmt-alert__close"
      aria-label="Dismiss alert"
      @click="emit('close')"
    >
      <X :size="16" />
    </button>
  </div>
</template>

<style scoped>
.qmt-alert {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 12px 14px;
  border-radius: 12px;
  border: 1px solid #d4d4d4;
  background-color: #f5f5f5;
  box-sizing: border-box;
}

.qmt-alert__icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  margin-top: 1px;
}

.qmt-alert__content {
  display: flex;
  flex-direction: column;
  gap: 12px;
  flex: 1;
  min-width: 0;
}

.qmt-alert__text {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.qmt-alert__title-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.qmt-alert__title {
  font-size: 14px;
  line-height: 20px;
  font-weight: 600;
}

.qmt-alert__description {
  margin: 0;
  font-size: 14px;
  line-height: 20px;
  font-weight: 400;
}

.qmt-alert__badges {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}

.qmt-alert__actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}

.qmt-alert__close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  padding: 0;
  border: none;
  border-radius: 6px;
  background: transparent;
  color: #737373;
  cursor: pointer;
  flex-shrink: 0;
}

.qmt-alert__close:hover {
  background-color: rgba(0, 0, 0, 0.05);
  color: #404040;
}

/* ─── Subtle Variants (Figma 10777:60849 - 10777:60917) ─── */
.qmt-alert--type-subtle.qmt-alert--status-default {
  background-color: #f5f5f5;
  border-color: #d4d4d4;
}
.qmt-alert--type-subtle.qmt-alert--status-default .qmt-alert__icon {
  color: #0b529c;
}
.qmt-alert--type-subtle.qmt-alert--status-default .qmt-alert__title,
.qmt-alert--type-subtle.qmt-alert--status-default .qmt-alert__description {
  color: #404040;
}

.qmt-alert--type-subtle.qmt-alert--status-info {
  background-color: #f0f9ff;
  border-color: #74d4ff;
}
.qmt-alert--type-subtle.qmt-alert--status-info .qmt-alert__icon {
  color: #0b529c;
}
.qmt-alert--type-subtle.qmt-alert--status-info .qmt-alert__title,
.qmt-alert--type-subtle.qmt-alert--status-info .qmt-alert__description {
  color: #0069a8;
}

.qmt-alert--type-subtle.qmt-alert--status-success {
  background-color: #ecfdf5;
  border-color: #5ee9b5;
}
.qmt-alert--type-subtle.qmt-alert--status-success .qmt-alert__icon {
  color: #009966;
}
.qmt-alert--type-subtle.qmt-alert--status-success .qmt-alert__title,
.qmt-alert--type-subtle.qmt-alert--status-success .qmt-alert__description {
  color: #007a55;
}

.qmt-alert--type-subtle.qmt-alert--status-warning {
  background-color: #fffbeb;
  border-color: #ffd230;
}
.qmt-alert--type-subtle.qmt-alert--status-warning .qmt-alert__icon {
  color: #e17100;
}
.qmt-alert--type-subtle.qmt-alert--status-warning .qmt-alert__title,
.qmt-alert--type-subtle.qmt-alert--status-warning .qmt-alert__description {
  color: #bb4d00;
}

.qmt-alert--type-subtle.qmt-alert--status-error {
  background-color: #fef2f2;
  border-color: #ffa2a2;
}
.qmt-alert--type-subtle.qmt-alert--status-error .qmt-alert__icon {
  color: #e7000b;
}
.qmt-alert--type-subtle.qmt-alert--status-error .qmt-alert__title,
.qmt-alert--type-subtle.qmt-alert--status-error .qmt-alert__description {
  color: #c10007;
}

/* ─── Outline Variants (Figma 10777:60934 - 10777:61006) ─── */
.qmt-alert--type-outline {
  background-color: #ffffff;
}
.qmt-alert--type-outline .qmt-alert__title,
.qmt-alert--type-outline .qmt-alert__description {
  color: #404040;
}
.qmt-alert--type-outline.qmt-alert--status-default {
  border-color: #e5e5e5;
}
.qmt-alert--type-outline.qmt-alert--status-default .qmt-alert__icon {
  color: #0b529c;
}
.qmt-alert--type-outline.qmt-alert--status-info {
  border-color: #00a6f4;
}
.qmt-alert--type-outline.qmt-alert--status-info .qmt-alert__icon {
  color: #0b529c;
}
.qmt-alert--type-outline.qmt-alert--status-success {
  border-color: #5ee9b5;
}
.qmt-alert--type-outline.qmt-alert--status-success .qmt-alert__icon {
  color: #009966;
}
.qmt-alert--type-outline.qmt-alert--status-warning {
  border-color: #ffd230;
}
.qmt-alert--type-outline.qmt-alert--status-warning .qmt-alert__icon {
  color: #e17100;
}
.qmt-alert--type-outline.qmt-alert--status-error {
  border-color: #ffa2a2;
}
.qmt-alert--type-outline.qmt-alert--status-error .qmt-alert__icon {
  color: #e7000b;
}
</style>
