<script setup lang="ts">
import type { Component } from 'vue';
import { computed, nextTick, onBeforeUnmount, onMounted, ref, useSlots } from 'vue';
import { AlertCircle, Check, ChevronDown, Loader2, Search, X } from 'lucide-vue-next';

export interface SelectOption {
  value: string | number | boolean;
  label: string;
  description?: string;
  group?: string;
  icon?: Component;
  disabled?: boolean;
  destructive?: boolean;
}

interface Props {
  modelValue?: any;
  label?: string;
  required?: boolean;
  placeholder?: string;
  searchPlaceholder?: string;
  options?: Array<SelectOption | string>;
  disabled?: boolean;
  error?: string;
  helperText?: string;
  hint?: string;
  searchable?: boolean;
  multiple?: boolean;
  loading?: boolean;
  clearable?: boolean;
  emptyText?: string;
  icon?: Component;
  id?: string;
  teleport?: boolean;
  variant?: 'default' | 'cell';
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  label: '',
  required: false,
  placeholder: 'Select',
  searchPlaceholder: 'Search options...',
  options: () => [],
  disabled: false,
  error: '',
  helperText: '',
  hint: '',
  searchable: false,
  multiple: false,
  loading: false,
  clearable: false,
  emptyText: 'No results found',
  icon: undefined,
  id: undefined,
  teleport: false,
  variant: 'default'
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: any): void;
  (e: 'change', event: Event): void;
  (e: 'search', query: string): void;
}>();

const slots = useSlots();
const hasCustomSlotOptions = computed(() => Boolean(slots.default));
const displayHelper = computed(() => props.hint || props.helperText || '');

const isOpen = ref(false);
const searchQuery = ref('');
const highlightedIndex = ref(-1);
const wrapperRef = ref<HTMLElement | null>(null);
const triggerRef = ref<HTMLButtonElement | null>(null);
const searchInputRef = ref<HTMLInputElement | null>(null);
const popoverRef = ref<HTMLElement | null>(null);
const popoverStyle = ref<Record<string, string>>({});

const updatePopoverPosition = () => {
  if (!props.teleport || !triggerRef.value) return;
  const rect = triggerRef.value.getBoundingClientRect();
  const popoverWidth = Math.max(rect.width, 220);
  const spaceBelow = window.innerHeight - rect.bottom;
  const openAbove = spaceBelow < 250 && rect.top > 250;
  popoverStyle.value = {
    position: 'fixed',
    top: openAbove ? 'auto' : `${rect.bottom + 4}px`,
    bottom: openAbove ? `${window.innerHeight - rect.top + 4}px` : 'auto',
    left: `${Math.min(rect.left, Math.max(16, window.innerWidth - popoverWidth - 16))}px`,
    width: `${popoverWidth}px`,
    zIndex: '99999'
  };
};

const normalizedOptions = computed<SelectOption[]>(() =>
  props.options.map((opt) => (typeof opt === 'string' ? { value: opt, label: opt } : opt))
);

const filteredOptions = computed(() => {
  const q = searchQuery.value.trim().toLowerCase();
  if (!props.searchable || !q) return normalizedOptions.value;
  return normalizedOptions.value.filter(
    (opt) =>
      opt.label.toLowerCase().includes(q) ||
      (opt.description && opt.description.toLowerCase().includes(q)) ||
      (opt.group && opt.group.toLowerCase().includes(q))
  );
});

const groupedOptions = computed(() => {
  const groups: Array<{ group: string; items: SelectOption[] }> = [];
  for (const opt of filteredOptions.value) {
    const groupKey = opt.group || '';
    const existing = groups.find((g) => g.group === groupKey);
    if (existing) {
      existing.items.push(opt);
    } else {
      groups.push({ group: groupKey, items: [opt] });
    }
  }
  return groups;
});

const valuesEqual = (a: any, b: any) => {
  if (a === b) return true;
  if (a === null || a === undefined || b === null || b === undefined) return false;
  return String(a) === String(b);
};

const isOptionSelected = (opt: SelectOption) => {
  if (props.multiple) {
    const arr = Array.isArray(props.modelValue) ? props.modelValue : [];
    return arr.some((item) => valuesEqual(item, opt.value));
  }
  return valuesEqual(props.modelValue, opt.value);
};

const hasValue = computed(() => {
  if (props.multiple) {
    return Array.isArray(props.modelValue) && props.modelValue.length > 0;
  }
  return props.modelValue !== '' && props.modelValue !== null && props.modelValue !== undefined;
});

const displayText = computed(() => {
  if (props.multiple) {
    const arr = Array.isArray(props.modelValue) ? props.modelValue : [];
    if (arr.length === 0) return props.placeholder;
    const labels = arr.map((val) => {
      const found = normalizedOptions.value.find((o) => valuesEqual(o.value, val));
      return found ? found.label : String(val);
    });
    return labels.join(', ');
  }
  if (!hasValue.value) return props.placeholder;
  const matched = normalizedOptions.value.find((opt) => valuesEqual(opt.value, props.modelValue));
  return matched ? matched.label : String(props.modelValue);
});

const openMenu = () => {
  if (props.disabled) return;
  isOpen.value = true;
  searchQuery.value = '';
  const selectedIdx = filteredOptions.value.findIndex((o) => isOptionSelected(o) && !o.disabled);
  highlightedIndex.value = selectedIdx >= 0 ? selectedIdx : filteredOptions.value.findIndex((o) => !o.disabled);
  if (props.teleport) {
    updatePopoverPosition();
    nextTick(updatePopoverPosition);
  }
  if (props.searchable) {
    nextTick(() => searchInputRef.value?.focus());
  }
};

const closeMenu = () => {
  isOpen.value = false;
  highlightedIndex.value = -1;
};

const toggleMenu = () => {
  if (isOpen.value) closeMenu();
  else openMenu();
};

const emitSyntheticChange = (val: any) => {
  const synthetic = { target: { value: val } } as unknown as Event;
  emit('change', synthetic);
};

const selectOption = (opt: SelectOption) => {
  if (opt.disabled) return;
  if (props.multiple) {
    const current = Array.isArray(props.modelValue) ? [...props.modelValue] : [];
    const existingIdx = current.findIndex((v) => valuesEqual(v, opt.value));
    if (existingIdx >= 0) {
      current.splice(existingIdx, 1);
    } else {
      current.push(opt.value);
    }
    emit('update:modelValue', current);
    emitSyntheticChange(current);
  } else {
    emit('update:modelValue', opt.value);
    emitSyntheticChange(opt.value);
    closeMenu();
    triggerRef.value?.focus();
  }
};

const clearSelection = () => {
  if (props.disabled) return;
  const emptyVal = props.multiple ? [] : '';
  emit('update:modelValue', emptyVal);
  emitSyntheticChange(emptyVal);
};

const handleSearchInput = () => {
  highlightedIndex.value = filteredOptions.value.findIndex((o) => !o.disabled);
  emit('search', searchQuery.value);
};

const moveHighlight = (step: number) => {
  const opts = filteredOptions.value;
  if (!opts.length) return;
  let next = highlightedIndex.value;
  for (let i = 0; i < opts.length; i++) {
    next = (next + step + opts.length) % opts.length;
    if (!opts[next].disabled) {
      highlightedIndex.value = next;
      break;
    }
  }
};

const handleKeyDown = (e: KeyboardEvent) => {
  if (props.disabled) return;
  if (!isOpen.value) {
    if (e.key === 'ArrowDown' || e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      openMenu();
    }
    return;
  }

  if (e.key === 'Escape') {
    e.preventDefault();
    closeMenu();
    triggerRef.value?.focus();
  } else if (e.key === 'ArrowDown') {
    e.preventDefault();
    moveHighlight(1);
  } else if (e.key === 'ArrowUp') {
    e.preventDefault();
    moveHighlight(-1);
  } else if (e.key === 'Enter') {
    e.preventDefault();
    const target = filteredOptions.value[highlightedIndex.value];
    if (target && !target.disabled) {
      selectOption(target);
    }
  } else if (e.key === 'Tab') {
    closeMenu();
  }
};

const handleNativeChange = (e: Event) => {
  const target = e.target as HTMLSelectElement;
  emit('update:modelValue', target.value);
  emit('change', e);
};

const handleClickOutside = (e: MouseEvent) => {
  const target = e.target as Node;
  if (
    wrapperRef.value &&
    !wrapperRef.value.contains(target) &&
    (!popoverRef.value || !popoverRef.value.contains(target))
  ) {
    closeMenu();
  }
};

onMounted(() => {
  document.addEventListener('mousedown', handleClickOutside);
  if (props.teleport) {
    window.addEventListener('scroll', updatePopoverPosition, true);
    window.addEventListener('resize', updatePopoverPosition);
  }
});

onBeforeUnmount(() => {
  document.removeEventListener('mousedown', handleClickOutside);
  if (props.teleport) {
    window.removeEventListener('scroll', updatePopoverPosition, true);
    window.removeEventListener('resize', updatePopoverPosition);
  }
});
</script>

<template>
  <div
    ref="wrapperRef"
    class="form-control-wrapper"
    :class="{
      'has-error': !!error,
      'is-disabled': disabled,
      'is-open': isOpen,
      'is-cell-variant': variant === 'cell'
    }"
  >
    <!-- Form Label -->
    <label v-if="label" :for="id" class="form-label">
      {{ label }}
      <span v-if="required" class="required-asterisk">*</span>
    </label>

    <!-- Native fallback only when explicit <option> slot children are provided -->
    <div v-if="hasCustomSlotOptions" class="select-container">
      <select
        :id="id"
        :value="modelValue"
        :disabled="disabled"
        class="form-select"
        :class="{ 'with-error-icon': !!error }"
        @change="handleNativeChange"
      >
        <option v-if="placeholder" value="" disabled selected hidden>
          {{ placeholder }}
        </option>
        <slot />
      </select>
      <div class="select-trailing">
        <AlertCircle v-if="error" :size="16" class="select-error-icon" aria-hidden="true" />
        <ChevronDown :size="15" class="select-arrow" />
      </div>
    </div>

    <!-- Custom QMT Select Trigger & Popover Menu (QMT 3377:50 / 5338:672) -->
    <div v-else class="select-container">
      <button
        :id="id"
        ref="triggerRef"
        type="button"
        class="qmt-select-trigger"
        :class="{ 'is-placeholder': !hasValue }"
        :disabled="disabled"
        :aria-expanded="isOpen"
        aria-haspopup="listbox"
        @click="toggleMenu"
        @keydown="handleKeyDown"
      >
        <span class="qmt-select-trigger__content">
          <component :is="icon" v-if="icon" :size="16" class="qmt-select-trigger__leading-icon" />
          <span class="qmt-select-trigger__text">{{ displayText }}</span>
        </span>
        <span class="select-trailing">
          <span
            v-if="clearable && hasValue && !disabled"
            role="button"
            tabindex="0"
            class="select-clear-btn"
            aria-label="Clear selection"
            @click.stop="clearSelection"
            @keydown.enter.stop.prevent="clearSelection"
          >
            <X :size="14" />
          </span>
          <AlertCircle v-if="error" :size="16" class="select-error-icon" aria-hidden="true" />
          <ChevronDown
            :size="15"
            class="select-arrow"
            :class="{ 'is-rotated': isOpen }"
          />
        </span>
      </button>

      <!-- Select Menu Popover -->
      <Teleport to="body" :disabled="!teleport">
        <div
          v-if="isOpen"
          ref="popoverRef"
          class="qmt-select-popover"
          :class="{ 'is-teleported': teleport }"
          :style="teleport ? popoverStyle : undefined"
          role="listbox"
          :aria-multiselectable="multiple"
        >
          <div v-if="searchable" class="qmt-select-search">
            <Search :size="15" class="qmt-select-search__icon" />
            <input
              ref="searchInputRef"
              v-model="searchQuery"
              type="text"
              class="qmt-select-search__input"
              :placeholder="searchPlaceholder"
              @input="handleSearchInput"
              @keydown="handleKeyDown"
            />
          </div>

          <div v-if="loading" class="qmt-select-state">
            <Loader2 :size="15" class="animate-spin" />
            <span>Loading...</span>
          </div>

          <div v-else-if="filteredOptions.length === 0" class="qmt-select-state">
            <span>{{ emptyText }}</span>
          </div>

          <div v-else class="qmt-select-options">
            <template v-for="(grp, gIdx) in groupedOptions" :key="grp.group || `g-${gIdx}`">
              <div v-if="grp.group" class="qmt-select-group-label">{{ grp.group }}</div>
              <button
                v-for="opt in grp.items"
                :key="String(opt.value)"
                type="button"
                role="option"
                :aria-selected="isOptionSelected(opt)"
                :disabled="opt.disabled"
                class="qmt-select-option"
                :class="{
                  'is-selected': isOptionSelected(opt),
                  'is-highlighted': filteredOptions[highlightedIndex]?.value === opt.value,
                  'is-disabled': opt.disabled,
                  'is-destructive': opt.destructive
                }"
                @click="selectOption(opt)"
                @mouseenter="highlightedIndex = filteredOptions.indexOf(opt)"
              >
                <span
                  v-if="multiple"
                  class="qmt-select-checkbox"
                  :class="{ 'is-checked': isOptionSelected(opt) }"
                  aria-hidden="true"
                >
                  <Check v-if="isOptionSelected(opt)" :size="12" stroke-width="2.6" />
                </span>
                <component :is="opt.icon" v-else-if="opt.icon" :size="16" class="qmt-select-option__icon" />
                <span class="qmt-select-option__body">
                  <span class="qmt-select-option__label">{{ opt.label }}</span>
                  <span v-if="opt.description" class="qmt-select-option__desc">{{ opt.description }}</span>
                </span>
                <Check
                  v-if="!multiple && isOptionSelected(opt)"
                  :size="16"
                  class="qmt-select-option__check"
                />
              </button>
            </template>
          </div>
        </div>
      </Teleport>
    </div>

    <!-- Error Message or Helper Text -->
    <p v-if="error" class="error-text">{{ error }}</p>
    <p v-else-if="displayHelper" class="helper-text">{{ displayHelper }}</p>
  </div>
</template>

<style scoped>
.form-control-wrapper {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 3px;
  width: 100%;
  font-family: inherit;
}

.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: var(--qmt-input-label, #404040);
  user-select: none;
  display: inline-flex;
  align-items: center;
  margin-bottom: 0;
  line-height: 1.2;
}

.required-asterisk {
  color: var(--qmt-input-error-icon, #e7000b);
  font-weight: 600;
  margin-left: 3px;
}

.select-container {
  position: relative;
  width: 100%;
  display: flex;
  align-items: center;
}

/* Native fallback styling */
.form-select {
  width: 100%;
  height: var(--qmt-input-sm-height, 38px);
  padding: 0 34px 0 var(--qmt-input-sm-padding-x, 12px);
  background-color: var(--qmt-input-bg, #ffffff);
  border: var(--qmt-input-border-width, 1px) solid var(--qmt-input-border, #d4d4d4);
  border-radius: var(--qmt-input-radius, 8px);
  font-size: 13.5px;
  color: var(--qmt-input-fg, #404040);
  outline: none;
  appearance: none;
  cursor: pointer;
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
  font-family: inherit;
}

.form-select.with-error-icon {
  padding-right: 56px;
}

.form-select:focus {
  border-color: var(--qmt-input-border-focus, #83bff6);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-brand, #e1eefd),
    0 1px 2px 0 var(--qmt-color-shadow-faint);
}

/* Custom QMT Select Trigger (38px compact ERP height) */
.qmt-select-trigger {
  width: 100%;
  height: var(--qmt-input-sm-height, 38px);
  padding: 0 var(--qmt-input-sm-padding-x, 12px);
  background-color: var(--qmt-input-bg, #ffffff);
  border: var(--qmt-input-border-width, 1px) solid var(--qmt-input-border, #d4d4d4);
  border-radius: var(--qmt-input-radius, 8px);
  font-size: 13.5px;
  color: var(--qmt-input-fg, #404040);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--qmt-input-gap, 8px);
  text-align: left;
  cursor: pointer;
  outline: none;
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint);
  transition: border-color 0.15s ease, box-shadow 0.15s ease, background-color 0.15s ease;
  font-family: inherit;
}

.qmt-select-trigger:focus-visible,
.is-open .qmt-select-trigger {
  border-color: var(--qmt-input-border-focus, #83bff6);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-brand, #e1eefd),
    0 1px 2px 0 var(--qmt-color-shadow-faint);
}

.qmt-select-trigger.is-placeholder .qmt-select-trigger__text {
  color: var(--qmt-input-placeholder, #737373);
}

.qmt-select-trigger__content {
  display: flex;
  align-items: center;
  gap: var(--qmt-input-gap, 8px);
  min-width: 0;
  flex: 1;
}

.qmt-select-trigger__leading-icon {
  color: var(--qmt-input-icon, #737373);
  flex-shrink: 0;
}

.qmt-select-trigger__text {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.select-trailing {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
}

.select-container > .select-trailing {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  pointer-events: none;
}

.select-clear-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  padding: 2px;
  border-radius: 4px;
  color: var(--qmt-input-icon, #737373);
  cursor: pointer;
}

.select-clear-btn:hover {
  background-color: var(--qmt-input-option-bg-active, #f5f5f5);
  color: var(--qmt-input-fg, #404040);
}

.select-error-icon {
  color: var(--qmt-input-error-icon, #e7000b);
  flex-shrink: 0;
}

.select-arrow {
  color: var(--qmt-input-icon, #737373);
  flex-shrink: 0;
  transition: transform 0.15s ease;
}

.select-arrow.is-rotated {
  transform: rotate(180deg);
}

/* QMT Select Menu Popover (Figma 5338:672) */
.qmt-select-popover {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  z-index: 60;
  background-color: var(--qmt-input-popover-bg, #ffffff);
  border: 1px solid var(--qmt-input-popover-border, #e5e5e5);
  border-radius: var(--qmt-input-popover-radius, 8px);
  padding: var(--qmt-input-popover-padding, 4px);
  box-shadow:
    0 12px 16px -4px var(--qmt-color-shadow-medium, rgba(10, 13, 18, 0.14)),
    0 4px 6px -2px var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

.qmt-select-search {
  position: relative;
  display: flex;
  align-items: center;
  padding: 4px 4px 6px 4px;
  border-bottom: 1px solid var(--qmt-input-popover-divider, #e5e5e5);
  margin-bottom: 4px;
}

.qmt-select-search__icon {
  position: absolute;
  left: 14px;
  color: var(--qmt-input-icon, #737373);
  pointer-events: none;
}

.qmt-select-search__input {
  width: 100%;
  height: 34px;
  padding: 0 10px 0 32px;
  background-color: var(--qmt-input-bg, #ffffff);
  border: 1px solid var(--qmt-input-border, #d4d4d4);
  border-radius: 6px;
  font-size: 13px;
  color: var(--qmt-input-fg, #404040);
  outline: none;
  font-family: inherit;
}

.qmt-select-search__input:focus {
  border-color: var(--qmt-input-border-focus, #83bff6);
  box-shadow: 0 0 0 3px var(--qmt-color-focus-ring-brand, #e1eefd);
}

.qmt-select-options {
  max-height: 220px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: var(--qmt-input-option-spacing, 2px);
}

.qmt-select-group-label {
  padding: 6px var(--qmt-input-option-padding-x, 10px) 4px;
  font-size: 11.5px;
  font-weight: 600;
  color: var(--qmt-input-option-group-fg, #737373);
}

.qmt-select-option {
  width: 100%;
  display: flex;
  align-items: center;
  gap: var(--qmt-input-option-gap, 8px);
  padding: var(--qmt-input-option-padding-y, 8px) var(--qmt-input-option-padding-x, 10px);
  border: none;
  border-radius: var(--qmt-input-option-radius, 6px);
  background: transparent;
  color: var(--qmt-input-option-fg, #404040);
  font-size: 13.5px;
  font-weight: 500;
  text-align: left;
  cursor: pointer;
  transition: background-color 0.12s ease;
  font-family: inherit;
}

.qmt-select-option:hover:not(:disabled),
.qmt-select-option.is-highlighted:not(:disabled),
.qmt-select-option.is-selected:not(:disabled) {
  background-color: var(--qmt-input-option-bg-active, #f5f5f5);
}

.qmt-select-option.is-disabled {
  color: var(--qmt-input-option-fg-disabled, #a1a1a1);
  cursor: not-allowed;
}

.qmt-select-option.is-destructive {
  color: var(--qmt-input-hint-error, #c10007);
}

.qmt-select-option__icon {
  color: var(--qmt-input-icon, #737373);
  flex-shrink: 0;
}

.qmt-select-option__body {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}

.qmt-select-option__label {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  line-height: 1.35;
}

.qmt-select-option__desc {
  font-size: 12px;
  font-weight: 400;
  color: var(--qmt-input-hint, #737373);
  line-height: 1.3;
}

.qmt-select-option__check {
  color: var(--qmt-input-option-icon-check, #0b529c);
  flex-shrink: 0;
}

.qmt-select-checkbox {
  width: var(--qmt-checkbox-sm-box-size, 16px);
  height: var(--qmt-checkbox-sm-box-size, 16px);
  border-radius: var(--qmt-checkbox-sm-radius, 4px);
  border: var(--qmt-checkbox-border-width, 1px) solid var(--qmt-checkbox-border, #d4d4d4);
  background-color: var(--qmt-checkbox-bg, #ffffff);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--qmt-checkbox-mark, #ffffff);
  flex-shrink: 0;
  transition: background-color 0.15s ease, border-color 0.15s ease;
}

.qmt-select-option:hover:not(:disabled) .qmt-select-checkbox:not(.is-checked) {
  background-color: var(--qmt-checkbox-bg-hover, #f1f7fe);
  border-color: var(--qmt-checkbox-border-hover, #0b529c);
}

.qmt-select-checkbox.is-checked {
  background-color: var(--qmt-checkbox-bg-checked, #0b529c);
  border-color: var(--qmt-checkbox-border-checked, #0b529c);
}

.qmt-select-state {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 14px 12px;
  font-size: 13px;
  color: var(--qmt-input-hint, #737373);
}

/* ERROR STATE (QMT Destructive=True) */
.has-error .form-select,
.has-error .qmt-select-trigger {
  border-color: var(--qmt-input-border-error, #ffa2a2);
}

.has-error .form-select:focus,
.has-error .qmt-select-trigger:focus-visible,
.has-error.is-open .qmt-select-trigger {
  border-color: var(--qmt-input-border-error, #ffa2a2);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-error, #ffe2e2),
    0 1px 2px 0 var(--qmt-color-shadow-faint);
}

.error-text {
  font-size: 11.5px;
  color: var(--qmt-input-hint-error, #c10007);
  margin: 2px 0 0 0;
  line-height: 1.35;
}

.helper-text {
  font-size: 11.5px;
  color: var(--qmt-input-hint, #737373);
  margin: 2px 0 0 0;
  line-height: 1.35;
}

/* DISABLED STATE */
.is-disabled .form-select,
.is-disabled .qmt-select-trigger {
  background-color: var(--qmt-input-bg-disabled, #fafafa);
  color: var(--qmt-input-fg-disabled, #a1a1a1);
  cursor: not-allowed;
  border-color: var(--qmt-input-border-disabled, #d4d4d4);
}

/* ─── Cell Variant (for Dynamic Sub-Tables / Inline Grid Cells) ─── */
.form-control-wrapper.is-cell-variant {
  height: 100%;
  width: 100%;
  gap: 0;
}

.is-cell-variant .select-container {
  height: 100%;
  width: 100%;
}

.is-cell-variant .qmt-select-trigger {
  width: 100%;
  height: 100%;
  min-height: 42px;
  padding: 0 14px;
  border: none !important;
  border-radius: 0 !important;
  background-color: transparent !important;
  box-shadow: none !important;
  font-size: 13px;
  font-weight: 400;
  color: var(--alias-color-text-secondary, #404040);
}

.is-cell-variant .qmt-select-trigger:focus,
.is-cell-variant .qmt-select-trigger:focus-visible,
.is-cell-variant.is-open .qmt-select-trigger {
  border: none !important;
  box-shadow: none !important;
  outline: none !important;
}

.is-cell-variant .select-arrow {
  color: var(--alias-color-icon-tertiary, #737373);
  opacity: 0.6;
  transition: opacity 0.15s ease, transform 0.15s ease;
}

.is-cell-variant:hover .select-arrow,
.is-cell-variant.is-open .select-arrow {
  opacity: 1;
  color: var(--alias-color-brand-default, #0b529c);
}

.qmt-select-popover.is-teleported {
  box-shadow: 0 12px 28px -4px rgba(10, 13, 18, 0.18), 0 4px 10px -2px rgba(10, 13, 18, 0.08);
}
</style>
