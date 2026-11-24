<!--
  Authoritative QMT FormCheckbox Component (Figma 3345:19141)
  ==============================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Form submission models: Statutory compliance flags, policy conditions, governance requirements,
    and boolean entity fields saved on form submission (e.g., `is_mandatory`, `active`, `requires_guarantee`).
  - Settings with Title + Description: Renders clear secondary explanation text beneath the label.
  - Table row selection: Used in table lead cells (`th-lead` / `td-lead`) for single and bulk row selection.
  - Supports indeterminate state (`indeterminate: true`) for partial multi-select parent checkboxes.

  WHEN NOT TO USE:
  - DO NOT use for instant runtime preferences that apply immediately without saving (use `FormToggle.vue`).
  - DO NOT use raw browser `<input type="checkbox">` elements.
-->
<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue';

type CheckboxValue = string | number;

interface Props {
  modelValue?: boolean | CheckboxValue[];
  value?: CheckboxValue;
  indeterminate?: boolean;
  size?: 'sm' | 'md';
  label?: string;
  description?: string;
  disabled?: boolean;
  error?: boolean | string;
  id?: string;
  name?: string;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: false,
  value: undefined,
  indeterminate: false,
  size: 'sm',
  label: '',
  description: '',
  disabled: false,
  error: false,
  id: undefined,
  name: undefined
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean | CheckboxValue[]): void;
  (e: 'change', value: boolean | CheckboxValue[]): void;
}>();

const inputRef = ref<HTMLInputElement | null>(null);

const isChecked = computed(() => {
  if (Array.isArray(props.modelValue)) {
    return props.value !== undefined && props.modelValue.includes(props.value);
  }
  return Boolean(props.modelValue);
});

const hasError = computed(() => Boolean(props.error));
const errorMessage = computed(() => (typeof props.error === 'string' ? props.error : ''));

const syncIndeterminate = () => {
  if (inputRef.value) {
    inputRef.value.indeterminate = Boolean(props.indeterminate);
  }
};

onMounted(syncIndeterminate);
watch(() => props.indeterminate, syncIndeterminate);

const onInput = (event: Event) => {
  const target = event.target as HTMLInputElement;
  if (Array.isArray(props.modelValue)) {
    const next = [...props.modelValue];
    if (props.value !== undefined) {
      const idx = next.indexOf(props.value);
      if (target.checked && idx === -1) {
        next.push(props.value);
      } else if (!target.checked && idx !== -1) {
        next.splice(idx, 1);
      }
    }
    emit('update:modelValue', next);
    emit('change', next);
    return;
  }

  emit('update:modelValue', target.checked);
  emit('change', target.checked);
};
</script>

<template>
  <label
    class="qmt-checkbox-wrapper"
    :class="[
      `qmt-checkbox--${size}`,
      {
        'is-checked': isChecked,
        'is-indeterminate': indeterminate,
        'is-disabled': disabled,
        'has-error': hasError,
        'is-standalone': !label && !description && !$slots.default
      }
    ]"
  >
    <input
      ref="inputRef"
      type="checkbox"
      :id="id"
      :name="name"
      :value="value"
      :checked="isChecked"
      :disabled="disabled"
      :aria-invalid="hasError || undefined"
      :aria-checked="indeterminate ? 'mixed' : isChecked"
      class="qmt-checkbox-input"
      @change="onInput"
    />

    <span class="qmt-checkbox-box" aria-hidden="true">
      <svg
        v-if="indeterminate"
        class="qmt-checkbox-mark"
        viewBox="0 0 12 12"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M2.5 6H9.5"
          stroke="currentColor"
          :stroke-width="size === 'md' ? 2 : 1.6667"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
      <svg
        v-else-if="isChecked"
        class="qmt-checkbox-mark"
        viewBox="0 0 12 12"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M10 3L4.5 8.5L2 6"
          stroke="currentColor"
          :stroke-width="size === 'md' ? 2 : 1.6667"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
    </span>

    <span v-if="label || description || errorMessage || $slots.default" class="qmt-checkbox-meta">
      <span v-if="label || $slots.default" class="qmt-checkbox-label">
        <slot>{{ label }}</slot>
      </span>
      <span v-if="description" class="qmt-checkbox-desc">{{ description }}</span>
      <span v-if="errorMessage" class="qmt-checkbox-error">{{ errorMessage }}</span>
    </span>
  </label>
</template>

<style scoped>
.qmt-checkbox-wrapper {
  position: relative;
  display: inline-flex;
  align-items: flex-start;
  cursor: pointer;
  user-select: none;
  vertical-align: middle;
  padding: 4px;
  margin: -4px;
}

.qmt-checkbox--sm {
  gap: var(--qmt-checkbox-sm-gap, 8px);
}

.qmt-checkbox--md {
  gap: var(--qmt-checkbox-md-gap, 12px);
}

.qmt-checkbox-wrapper.is-standalone {
  gap: 0;
  align-items: center;
  justify-content: center;
  padding: 4px;
  margin: 0;
}

.qmt-checkbox-input {
  position: absolute;
  opacity: 0;
  width: 1px;
  height: 1px;
  margin: 0;
  pointer-events: none;
}

.qmt-checkbox-box {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  background-color: var(--qmt-checkbox-bg, #ffffff);
  border: var(--qmt-checkbox-border-width, 1px) solid var(--qmt-checkbox-border, #d4d4d4);
  color: var(--qmt-checkbox-mark, #ffffff);
  transition: background-color 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease;
}

.qmt-checkbox-wrapper:not(.is-standalone) .qmt-checkbox-box {
  margin-top: var(--qmt-checkbox-box-offset, 2px);
}

.qmt-checkbox--sm .qmt-checkbox-box {
  width: var(--qmt-checkbox-sm-box-size, 16px);
  height: var(--qmt-checkbox-sm-box-size, 16px);
  border-radius: var(--qmt-checkbox-sm-radius, 4px);
}

.qmt-checkbox--md .qmt-checkbox-box {
  width: var(--qmt-checkbox-md-box-size, 20px);
  height: var(--qmt-checkbox-md-box-size, 20px);
  border-radius: var(--qmt-checkbox-md-radius, 6px);
}

.qmt-checkbox-mark {
  display: block;
}

.qmt-checkbox--sm .qmt-checkbox-mark {
  width: 12px;
  height: 12px;
}

.qmt-checkbox--md .qmt-checkbox-mark {
  width: 14px;
  height: 14px;
}

/* Hover - Unchecked */
.qmt-checkbox-wrapper:not(.is-disabled):not(.is-checked):not(.is-indeterminate):hover .qmt-checkbox-box {
  background-color: var(--qmt-checkbox-bg-hover, #f1f7fe);
  border-color: var(--qmt-checkbox-border-hover, #0b529c);
}

/* Focus & Active Press - Unchecked */
.qmt-checkbox-wrapper:not(.is-disabled):active .qmt-checkbox-box,
.qmt-checkbox-input:focus-visible + .qmt-checkbox-box {
  background-color: var(--qmt-checkbox-bg-hover, #f1f7fe);
  border-color: var(--qmt-checkbox-border-focus, #83bff6);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-checkbox-focus-ring, #e1eefd),
    0 1px 2px 0 var(--qmt-color-shadow-faint, #0a0d120d);
}

/* Checked & Indeterminate */
.qmt-checkbox-wrapper.is-checked .qmt-checkbox-box,
.qmt-checkbox-wrapper.is-indeterminate .qmt-checkbox-box {
  background-color: var(--qmt-checkbox-bg-checked, #0b529c);
  border-color: var(--qmt-checkbox-border-checked, #0b529c);
  color: var(--qmt-checkbox-mark, #ffffff);
}

/* Hover - Checked & Indeterminate */
.qmt-checkbox-wrapper.is-checked:not(.is-disabled):hover .qmt-checkbox-box,
.qmt-checkbox-wrapper.is-indeterminate:not(.is-disabled):hover .qmt-checkbox-box {
  background-color: var(--qmt-checkbox-bg-checked-hover, #0d457f);
  border-color: var(--qmt-checkbox-bg-checked-hover, #0d457f);
}

/* Focus & Active Press - Checked & Indeterminate */
.qmt-checkbox-wrapper.is-checked:not(.is-disabled):active .qmt-checkbox-box,
.qmt-checkbox-wrapper.is-indeterminate:not(.is-disabled):active .qmt-checkbox-box,
.qmt-checkbox-wrapper.is-checked .qmt-checkbox-input:focus-visible + .qmt-checkbox-box,
.qmt-checkbox-wrapper.is-indeterminate .qmt-checkbox-input:focus-visible + .qmt-checkbox-box {
  background-color: var(--qmt-checkbox-bg-checked-hover, #0d457f);
  border-color: var(--qmt-checkbox-border-checked, #0b529c);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-checkbox-focus-ring, #e1eefd),
    0 1px 2px 0 var(--qmt-color-shadow-faint, #0a0d120d);
}

/* Error State */
.qmt-checkbox-wrapper.has-error:not(.is-disabled):not(.is-checked):not(.is-indeterminate) .qmt-checkbox-box {
  border-color: var(--qmt-checkbox-border-error, #ffa2a2);
  background-color: var(--qmt-checkbox-bg-error, #ffe2e2);
}

.qmt-checkbox-wrapper.has-error:not(.is-disabled).is-checked .qmt-checkbox-box,
.qmt-checkbox-wrapper.has-error:not(.is-disabled).is-indeterminate .qmt-checkbox-box {
  background-color: var(--qmt-checkbox-mark-error, #c10007);
  border-color: var(--qmt-checkbox-mark-error, #c10007);
}

.qmt-checkbox-wrapper.has-error:not(.is-disabled):active .qmt-checkbox-box,
.qmt-checkbox-wrapper.has-error .qmt-checkbox-input:focus-visible + .qmt-checkbox-box {
  border-color: var(--qmt-checkbox-border-error, #ffa2a2);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-checkbox-focus-ring-error, #ffe2e2),
    0 1px 2px 0 var(--qmt-color-shadow-faint, #0a0d120d);
}

/* Disabled State (Unchecked, Checked, Indeterminate) */
.qmt-checkbox-wrapper.is-disabled {
  cursor: not-allowed;
}

.qmt-checkbox-wrapper.is-disabled .qmt-checkbox-box {
  background-color: var(--qmt-checkbox-bg-disabled, #fafafa);
  border-color: var(--qmt-checkbox-border-disabled, #e5e5e5);
  color: var(--qmt-checkbox-mark-disabled, #a1a1a1);
}

.qmt-checkbox-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.qmt-checkbox-label {
  font-weight: 500;
  color: var(--qmt-checkbox-label, #404040);
}

.qmt-checkbox--sm .qmt-checkbox-label {
  font-size: var(--qmt-checkbox-sm-font, 14px);
  line-height: 20px;
}

.qmt-checkbox--md .qmt-checkbox-label {
  font-size: var(--qmt-checkbox-md-font, 16px);
  line-height: 24px;
}

.qmt-checkbox-desc {
  font-weight: 400;
  color: var(--qmt-checkbox-supporting, #737373);
}

.qmt-checkbox--sm .qmt-checkbox-desc {
  font-size: var(--qmt-checkbox-sm-supporting-font, 12px);
  line-height: 18px;
}

.qmt-checkbox--md .qmt-checkbox-desc {
  font-size: var(--qmt-checkbox-md-supporting-font, 14px);
  line-height: 20px;
}

.qmt-checkbox-error {
  font-size: 12px;
  line-height: 16px;
  color: var(--qmt-checkbox-mark-error, #c10007);
}

.qmt-checkbox-wrapper.is-disabled .qmt-checkbox-label,
.qmt-checkbox-wrapper.is-disabled .qmt-checkbox-desc {
  color: var(--qmt-checkbox-label-disabled, #a1a1a1);
}
</style>
