<script setup lang="ts">
import { ref, computed, nextTick, onMounted, onBeforeUnmount } from 'vue';
import { Search, ChevronDown, Plus, AlertCircle } from 'lucide-vue-next';;

export interface ComboboxOption {
  id: number | string;
  title: string;
  subtitle?: string;
  badge?: string;
  raw?: any;
}

interface Props {
  modelValue?: string;
  selectedId?: number | string | null;
  label?: string;
  required?: boolean;
  placeholder?: string;
  searchPlaceholder?: string;
  options?: ComboboxOption[];
  createLabel?: string;
  createLabelPrefix?: string;
  disabled?: boolean;
  error?: string;
  helperText?: string;
  hint?: string;
  id?: string;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  selectedId: null,
  label: '',
  required: false,
  placeholder: 'Select',
  searchPlaceholder: 'Search by Name, Phone....',
  options: () => [],
  createLabel: 'Create and Continue',
  createLabelPrefix: '',
  disabled: false,
  error: '',
  helperText: '',
  hint: '',
  id: undefined
});

const displayHelper = computed(() => props.hint || props.helperText || '');

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void;
  (e: 'update:selectedId', id: number | string | null): void;
  (e: 'select', option: ComboboxOption): void;
  (e: 'create', value: string): void;
}>();

const isOpen = ref(false);
const searchQuery = ref('');
const comboboxRef = ref<HTMLElement | null>(null);
const searchInputRef = ref<HTMLInputElement | null>(null);

const cleanStr = (s: string) => s.toLowerCase().replace(/[\s\-_+()]/g, '');

const filteredOptions = computed(() => {
  const rawQuery = searchQuery.value.trim().toLowerCase();
  if (!rawQuery) return props.options;
  const normalizedQuery = cleanStr(rawQuery);

  return props.options.filter((opt) => {
    // 1. Match title (Name)
    if (opt.title.toLowerCase().includes(rawQuery) || cleanStr(opt.title).includes(normalizedQuery)) {
      return true;
    }
    // 2. Match subtitle (Phone, TIN, Kebele, Sector)
    if (opt.subtitle && (opt.subtitle.toLowerCase().includes(rawQuery) || cleanStr(opt.subtitle).includes(normalizedQuery))) {
      return true;
    }
    // 3. Match badge (Party ID, status)
    if (opt.badge && opt.badge.toLowerCase().includes(rawQuery)) {
      return true;
    }
    // 4. Match ID directly (e.g. searching "941")
    if (String(opt.id).toLowerCase().includes(rawQuery)) {
      return true;
    }
    // 5. Deep match on raw metadata (phone, tin, national_id, kebele, fayda_id, etc.)
    if (opt.raw && typeof opt.raw === 'object') {
      for (const val of Object.values(opt.raw)) {
        if (typeof val === 'string' || typeof val === 'number') {
          const strVal = String(val).toLowerCase();
          if (strVal.includes(rawQuery) || cleanStr(strVal).includes(normalizedQuery)) {
            return true;
          }
        }
      }
    }
    return false;
  });
});

const hasExactMatch = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return false;
  return props.options.some((opt) => opt.title.toLowerCase() === query);
});

const toggleDropdown = () => {
  if (props.disabled) return;
  if (isOpen.value) {
    closeDropdown();
  } else {
    openDropdown();
  }
};

const openDropdown = () => {
  isOpen.value = true;
  searchQuery.value = props.modelValue || '';
  nextTick(() => {
    searchInputRef.value?.focus();
    searchInputRef.value?.select();
  });
};

const closeDropdown = (commitTypedText = true) => {
  if (commitTypedText && searchQuery.value.trim() && searchQuery.value.trim() !== props.modelValue) {
    commitCustomValue(searchQuery.value.trim());
  }
  isOpen.value = false;
};

const selectOption = (opt: ComboboxOption) => {
  emit('update:modelValue', opt.title);
  emit('update:selectedId', opt.id);
  emit('select', opt);
  isOpen.value = false;
};

const commitCustomValue = (val: string) => {
  const trimmed = val.trim();
  if (!trimmed) return;
  emit('update:modelValue', trimmed);
  emit('update:selectedId', null);
  emit('create', trimmed);
  isOpen.value = false;
};

const handleKeyDown = (e: KeyboardEvent) => {
  if (e.key === 'Enter') {
    e.preventDefault();
    if (filteredOptions.value.length === 1 && !hasExactMatch.value) {
      selectOption(filteredOptions.value[0]);
    } else if (filteredOptions.value.length > 0 && hasExactMatch.value) {
      const match = filteredOptions.value.find(
        (opt) => opt.title.toLowerCase() === searchQuery.value.trim().toLowerCase()
      );
      if (match) selectOption(match);
      else commitCustomValue(searchQuery.value);
    } else if (searchQuery.value.trim()) {
      commitCustomValue(searchQuery.value);
    }
  } else if (e.key === 'Escape') {
    closeDropdown(false);
  }
};

const handleClickOutside = (e: MouseEvent) => {
  if (comboboxRef.value && !comboboxRef.value.contains(e.target as Node)) {
    closeDropdown(true);
  }
};

onMounted(() => {
  document.addEventListener('mousedown', handleClickOutside);
});

onBeforeUnmount(() => {
  document.removeEventListener('mousedown', handleClickOutside);
});
</script>

<template>
  <div 
    ref="comboboxRef" 
    class="combobox-control-wrapper" 
    :class="{ 'has-error': !!error, 'is-disabled': disabled, 'is-open': isOpen }"
  >
    <!-- Label -->
    <label v-if="label" :for="id" class="combobox-label">
      {{ label }}
      <span v-if="required" class="required-asterisk">*</span>
    </label>

    <!-- Trigger Box -->
    <div 
      class="combobox-trigger"
      :class="{ 'has-value': !!modelValue }"
      @click="toggleDropdown"
    >
      <span class="combobox-display-text" :class="{ 'is-placeholder': !modelValue }">
        {{ modelValue || placeholder }}
      </span>
      <span class="combobox-trailing-icons">
        <AlertCircle v-if="error" :size="16" class="combobox-error-icon" aria-hidden="true" />
        <ChevronDown :size="15" class="combobox-chevron" :class="{ 'is-rotated': isOpen }" />
      </span>
    </div>

    <!-- Dropdown Popover (Screenshot Style) -->
    <div v-if="isOpen" class="combobox-popover">
      <!-- Search Input Container with Icon -->
      <div class="combobox-search-box">
        <Search :size="14" class="combobox-search-icon" />
        <input
          ref="searchInputRef"
          type="text"
          v-model="searchQuery"
          class="combobox-search-input"
          :placeholder="searchPlaceholder"
          @keydown="handleKeyDown"
        />
      </div>

      <!-- Options List -->
      <div v-if="filteredOptions.length > 0" class="combobox-options-list">
        <div
          v-for="opt in filteredOptions"
          :key="String(opt.id)"
          class="combobox-item"
          :class="{ 'is-selected': opt.title === modelValue }"
          @click="selectOption(opt)"
        >
          <div class="combobox-item-info">
            <span class="combobox-item-title">{{ opt.title }}</span>
            <span v-if="opt.subtitle" class="combobox-item-subtitle">{{ opt.subtitle }}</span>
          </div>
          <div v-if="opt.badge" class="combobox-item-meta">
            <span class="combobox-item-badge">{{ opt.badge }}</span>
          </div>
        </div>
      </div>

      <!-- No items found label if empty -->
      <div v-else-if="!searchQuery.trim()" class="combobox-empty-state">
        <span>No entries available</span>
      </div>

      <!-- Create New Option (Matches Screenshot '+ Create and Continue') -->
      <div 
        v-if="searchQuery.trim() && !hasExactMatch" 
        class="combobox-create-btn"
        @click="commitCustomValue(searchQuery)"
      >
        <Plus :size="14" class="create-plus-icon" />
        <span>{{ createLabelPrefix ? `${createLabelPrefix} "${searchQuery.trim()}"` : (createLabel || 'Create and Continue') }}</span>
      </div>
    </div>

    <!-- Error / Helper Text -->
    <p v-if="error" class="error-text">{{ error }}</p>
    <p v-else-if="displayHelper" class="helper-text">{{ displayHelper }}</p>
  </div>
</template>

<style scoped>
.combobox-control-wrapper {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 3px;
  width: 100%;
  font-family: inherit;
}

.combobox-label {
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

/* Trigger Box */
.combobox-trigger {
  width: 100%;
  height: var(--qmt-input-sm-height, 38px);
  padding: 0 var(--qmt-input-sm-padding-x, 12px);
  background-color: var(--qmt-input-bg, #ffffff);
  border: var(--qmt-input-border-width, 1px) solid var(--qmt-input-border, #d4d4d4);
  border-radius: var(--qmt-input-radius, 8px);
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  user-select: none;
  box-shadow: 0 1px 2px 0 var(--qmt-color-shadow-faint);
  transition: border-color 0.15s ease, box-shadow 0.15s ease, background-color 0.15s ease;
}

.combobox-control-wrapper.is-open .combobox-trigger,
.combobox-trigger:hover {
  border-color: var(--qmt-input-border-focus, #83bff6);
}

.combobox-control-wrapper.is-open .combobox-trigger {
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-brand, #e1eefd),
    0 1px 2px 0 var(--qmt-color-shadow-faint);
}

.combobox-control-wrapper.has-error .combobox-trigger {
  border-color: var(--qmt-input-border-error, #ffa2a2);
}

.combobox-control-wrapper.has-error.is-open .combobox-trigger {
  border-color: var(--qmt-input-border-error, #ffa2a2);
  box-shadow:
    0 0 0 var(--qmt-focus-ring-width, 4px) var(--qmt-color-focus-ring-error, #ffe2e2),
    0 1px 2px 0 var(--qmt-color-shadow-faint);
}

.combobox-control-wrapper.is-disabled .combobox-trigger {
  background-color: var(--qmt-input-bg-disabled, #fafafa);
  color: var(--qmt-input-fg-disabled, #a1a1a1);
  border-color: var(--qmt-input-border-disabled, #d4d4d4);
  cursor: not-allowed;
}

.combobox-display-text {
  font-size: 13.5px;
  color: var(--qmt-input-fg, #404040);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  flex: 1;
}

.combobox-display-text.is-placeholder {
  color: var(--qmt-input-placeholder, #737373);
}

.combobox-trailing-icons {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
  margin-left: 8px;
}

.combobox-error-icon {
  color: var(--qmt-input-error-icon, #e7000b);
  flex-shrink: 0;
}

.combobox-chevron {
  color: var(--qmt-input-icon, #737373);
  flex-shrink: 0;
  transition: transform 0.2s ease;
}

.combobox-chevron.is-rotated {
  transform: rotate(180deg);
}

/* Popover Panel */
.combobox-popover {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  z-index: 60;
  background: var(--qmt-input-popover-bg, #ffffff);
  border: 1px solid var(--qmt-input-popover-border, #e5e5e5);
  border-radius: var(--qmt-input-popover-radius, 8px);
  padding: 6px;
  box-shadow:
    0 12px 16px -4px var(--qmt-color-shadow-medium, rgba(10, 13, 18, 0.14)),
    0 4px 6px -2px var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
}

/* Search Box */
.combobox-search-box {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
}

.combobox-search-icon {
  position: absolute;
  left: 10px;
  color: var(--qmt-input-icon, #737373);
  pointer-events: none;
}

.combobox-search-input {
  width: 100%;
  height: 36px;
  padding: 0 12px 0 32px;
  border: 1px solid var(--qmt-input-border, #d4d4d4);
  border-radius: 6px;
  font-size: 13px;
  color: var(--qmt-input-fg, #404040);
  outline: none;
  background: var(--qmt-input-bg, #ffffff);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.combobox-search-input:focus {
  border-color: var(--qmt-input-border-focus, #83bff6);
  box-shadow: 0 0 0 3px var(--qmt-color-focus-ring-brand, #e1eefd);
}

/* Options List */
.combobox-options-list {
  max-height: 190px;
  overflow-y: auto;
  margin-top: 6px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 transparent;
}

.combobox-options-list::-webkit-scrollbar {
  width: 5px;
}

.combobox-options-list::-webkit-scrollbar-track {
  background: transparent;
}

.combobox-options-list::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}

.combobox-options-list::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

.combobox-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--qmt-input-option-padding-y, 8px) var(--qmt-input-option-padding-x, 10px);
  border-radius: var(--qmt-input-option-radius, 6px);
  cursor: pointer;
  transition: background-color 0.12s ease;
}

.combobox-item:hover,
.combobox-item.is-selected {
  background-color: var(--qmt-input-option-bg-active, #f5f5f5);
}

.combobox-item-info {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.combobox-item-title {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.combobox-item-subtitle {
  font-size: 12px;
  color: #737373;
}

.combobox-item-meta {
  display: flex;
  align-items: center;
  gap: 6px;
}

.combobox-item-badge {
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 4px;
  background-color: #f1f5f9;
  color: #64748b;
  font-weight: 500;
}

.combobox-empty-state {
  padding: 12px 10px;
  text-align: center;
  font-size: 12.5px;
  color: #94a3b8;
}

/* Create New Button (Matching Screenshot) */
.combobox-create-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 9px 12px;
  margin-top: 6px;
  color: #0B529C;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  border-radius: 8px;
  transition: background-color 0.12s ease;
}

.combobox-create-btn:hover {
  background-color: #eff6ff;
}

.create-plus-icon {
  color: #0B529C;
  flex-shrink: 0;
}

/* Helper & Error */
.helper-text {
  font-size: 11.5px;
  color: var(--qmt-input-hint, #737373);
  margin: 2px 0 0 0;
  line-height: 1.35;
}

.error-text {
  font-size: 11.5px;
  color: var(--qmt-input-hint-error, #c10007);
  margin: 2px 0 0 0;
  line-height: 1.35;
}
</style>
