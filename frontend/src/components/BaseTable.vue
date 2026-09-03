<script setup lang="ts">
import { ref, computed } from 'vue';
import { 
  Search, Filter, ArrowUpDown, ChevronDown, Columns, Maximize, RotateCcw 
} from 'lucide-vue-next';
import BasePagination from './BasePagination.vue';

export interface ColumnDef {
  key: string;
  label: string;
  visible?: boolean;
}

export interface SortOption {
  key: string;
  label: string;
}

interface Props {
  title?: string;
  subtitle?: string;
  searchPlaceholder?: string;
  searchQuery?: string;
  showSearch?: boolean;
  showFilter?: boolean;
  filterCount?: number;
  showSort?: boolean;
  sortOptions?: SortOption[];
  currentSort?: string;
  sortOrder?: 'asc' | 'desc';
  showColumns?: boolean;
  columns?: ColumnDef[];
  showFullscreen?: boolean;
  totalEntries?: number;
  currentPage?: number;
  perPage?: number;
  perPageOptions?: number[];
  showPagination?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  title: undefined,
  subtitle: undefined,
  searchPlaceholder: 'Search...',
  searchQuery: '',
  showSearch: true,
  showFilter: true,
  filterCount: 0,
  showSort: false,
  sortOptions: () => [],
  currentSort: '',
  sortOrder: 'asc',
  showColumns: true,
  columns: () => [],
  showFullscreen: true,
  totalEntries: 0,
  currentPage: 1,
  perPage: 10,
  perPageOptions: () => [5, 10, 25, 50],
  showPagination: true
});

const emit = defineEmits<{
  (e: 'update:searchQuery', val: string): void;
  (e: 'update:currentPage', val: number): void;
  (e: 'update:perPage', val: number): void;
  (e: 'update:currentSort', val: string): void;
  (e: 'update:sortOrder', val: 'asc' | 'desc'): void;
  (e: 'toggleColumn', colKey: string): void;
  (e: 'resetFilter'): void;
}>();

// Filter panel reveal state
const showFilterPanel = ref(false);

// Dropdowns
const showSortDropdown = ref(false);
const showColumnsDropdown = ref(false);

// Fullscreen
const isFullscreen = ref(false);

const toggleFullscreen = () => {
  isFullscreen.value = !isFullscreen.value;
};

const toggleSort = (key: string) => {
  if (props.currentSort === key) {
    emit('update:sortOrder', props.sortOrder === 'asc' ? 'desc' : 'asc');
  } else {
    emit('update:currentSort', key);
    emit('update:sortOrder', 'asc');
  }
  showSortDropdown.value = false;
};

const handleSearchInput = (e: Event) => {
  const target = e.target as HTMLInputElement;
  emit('update:searchQuery', target.value);
};

const closeAllPopovers = () => {
  showSortDropdown.value = false;
  showColumnsDropdown.value = false;
};

if (typeof window !== 'undefined') {
  window.addEventListener('click', closeAllPopovers);
}
</script>

<template>
  <div :class="['table-section-card', { 'is-fullscreen': isFullscreen }]">
    <!-- Optional Header Title & Subtitle -->
    <div v-if="props.title || $slots.header" class="table-header-title-block">
      <slot name="header">
        <h2 class="table-block-title">{{ props.title }}</h2>
        <p v-if="props.subtitle" class="table-block-subtitle">{{ props.subtitle }}</p>
      </slot>
    </div>

    <!-- Action Controls Toolbar -->
    <div class="toolbar-wrapper">
      <div class="toolbar-left">
        <!-- Search Input -->
        <div v-if="props.showSearch" class="search-box">
          <Search :size="16" class="search-box-icon" />
          <input
            :value="props.searchQuery"
            type="text"
            :placeholder="props.searchPlaceholder"
            class="search-box-input"
            @input="handleSearchInput"
          />
        </div>

        <!-- Filter Toggle Button -->
        <button
          v-if="props.showFilter"
          type="button"
          class="toolbar-btn"
          :class="{ 'btn-active': props.filterCount > 0 || showFilterPanel }"
          @click.stop="showFilterPanel = !showFilterPanel; showSortDropdown = false; showColumnsDropdown = false;"
        >
          <Filter :size="15" />
          <span>Filter</span>
          <span v-if="props.filterCount > 0" class="filter-count-badge">{{ props.filterCount }}</span>
          <ChevronDown :size="12" class="opacity-60 transition-transform" :class="{ 'rotate-180': showFilterPanel }" />
        </button>

        <!-- Sort Button & Dropdown -->
        <div v-if="props.showSort && props.sortOptions.length > 0" class="relative-dropdown">
          <button
            type="button"
            class="toolbar-btn"
            :class="{ 'btn-active': showSortDropdown || !!props.currentSort }"
            @click.stop="showSortDropdown = !showSortDropdown; showColumnsDropdown = false;"
          >
            <ArrowUpDown :size="15" />
            <span>Sort</span>
            <ChevronDown :size="12" class="opacity-60" />
          </button>

          <div v-if="showSortDropdown" class="dropdown-popover sort-popover" @click.stop>
            <div class="popover-title-text">Sort By</div>
            <button
              v-for="opt in props.sortOptions"
              :key="opt.key"
              type="button"
              class="sort-option"
              @click="toggleSort(opt.key)"
            >
              <span>{{ opt.label }}</span>
              <span v-if="props.currentSort === opt.key" class="text-blue-600 font-bold ml-auto text-xs">
                {{ props.sortOrder === 'asc' ? 'A-Z' : 'Z-A' }}
              </span>
            </button>
          </div>
        </div>

        <slot name="toolbar-left" />
      </div>

      <div class="toolbar-right">
        <!-- Columns Visibility Dropdown -->
        <div v-if="props.showColumns && props.columns.length > 0" class="relative-dropdown">
          <button
            type="button"
            class="icon-toggle-btn"
            :class="{ 'btn-active': showColumnsDropdown }"
            title="Show / Hide Columns"
            @click.stop="showColumnsDropdown = !showColumnsDropdown; showSortDropdown = false;"
          >
            <Columns :size="16" />
          </button>

          <div v-if="showColumnsDropdown" class="dropdown-popover columns-popover" @click.stop>
            <div class="popover-title-text">Show / Hide Columns</div>
            <div class="columns-list-container">
              <label
                v-for="col in props.columns"
                :key="col.key"
                class="column-option-item"
              >
                <input
                  type="checkbox"
                  :checked="col.visible !== false"
                  class="custom-checkbox"
                  @change="emit('toggleColumn', col.key)"
                />
                <span>{{ col.label }}</span>
              </label>
            </div>
          </div>
        </div>

        <!-- Fullscreen Button -->
        <button
          v-if="props.showFullscreen"
          type="button"
          class="icon-toggle-btn"
          :class="{ 'btn-active': isFullscreen }"
          title="Toggle Fullscreen"
          @click="toggleFullscreen"
        >
          <Maximize :size="16" />
        </button>

        <slot name="toolbar-right" />

        <!-- Primary Actions Button Slot -->
        <slot name="actions" />
      </div>
    </div>

    <!-- Revealing Filter Panel -->
    <transition name="slide-down">
      <div v-if="showFilterPanel && $slots['filter-panel']" class="filter-panel">
        <slot name="filter-panel" />
      </div>
    </transition>

    <!-- Table Container -->
    <div class="table-container">
      <slot />
    </div>

    <!-- Pagination Footer -->
    <BasePagination
      v-if="props.showPagination && props.totalEntries > 0"
      :currentPage="props.currentPage"
      :perPage="props.perPage"
      :totalEntries="props.totalEntries"
      :perPageOptions="props.perPageOptions"
      @update:currentPage="(val) => emit('update:currentPage', val)"
      @update:perPage="(val) => emit('update:perPage', val)"
    />
  </div>
</template>

<style scoped>
/* TABLE SECTION CARD CONTAINER */
.table-section-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02), 0 1px 2px rgba(0, 0, 0, 0.03);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  position: relative;
}

/* Fullscreen Mode */
.table-section-card.is-fullscreen {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 9999;
  border-radius: 0;
  margin: 0 !important;
  height: 100vh;
  overflow-y: auto;
}

/* Table Header Title */
.table-header-title-block {
  padding: 20px 24px 12px 24px;
}
.table-block-title {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
  margin: 0 0 2px 0;
  letter-spacing: -0.01em;
}
.table-block-subtitle {
  font-size: 13px;
  color: #64748b;
  margin: 0;
}

/* Toolbar */
.toolbar-wrapper {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  gap: 16px;
  flex-wrap: wrap;
}

.table-header-title-block + .toolbar-wrapper {
  padding-top: 0;
  padding-bottom: 16px;
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
  min-width: 280px;
}

.toolbar-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

/* Search Box */
.search-box {
  position: relative;
  width: 100%;
  max-width: 320px;
}

.search-box-icon {
  position: absolute;
  left: 14px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
  pointer-events: none;
}

.search-box-input {
  width: 100%;
  height: 40px;
  padding: 0 14px 0 40px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13.5px;
  color: #1e293b;
  outline: none;
  transition: all 0.15s ease;
}

.search-box-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.12);
}

/* Toolbar Buttons */
.toolbar-btn {
  height: 40px;
  padding: 0 14px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 500;
  color: #334155;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.toolbar-btn:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
  color: #0f172a;
}

.btn-active {
  border-color: #0B529C;
  background-color: #eff6ff;
  color: #0B529C;
}

.filter-count-badge {
  background-color: #0B529C;
  color: #ffffff;
  font-size: 11px;
  font-weight: 700;
  padding: 1px 7px;
  border-radius: 10px;
  margin-left: 2px;
}

.icon-toggle-btn {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
  color: #64748b;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
}

.icon-toggle-btn:hover {
  background: #f8fafc;
  color: #0f172a;
  border-color: #cbd5e1;
}

/* Dropdown Popovers */
.relative-dropdown {
  position: relative;
}

.dropdown-popover {
  position: absolute;
  top: calc(100% + 6px);
  left: 0;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.04);
  padding: 12px;
  z-index: 100;
  display: flex;
  flex-direction: column;
  gap: 6px;
  animation: popIn 0.15s ease-out;
}

@keyframes popIn {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}

.sort-popover {
  width: 170px;
  padding: 8px;
}

.sort-option {
  display: flex;
  align-items: center;
  width: 100%;
  padding: 8px 10px;
  border-radius: 6px;
  border: none;
  background: none;
  font-size: 13px;
  color: #334155;
  cursor: pointer;
  transition: background 0.15s;
}

.sort-option:hover {
  background: #f8fafc;
  color: #0f172a;
}

.columns-popover {
  right: 0;
  left: auto !important;
  width: 220px;
  padding: 12px 14px;
}

.popover-title-text {
  font-size: 11px;
  font-weight: 700;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 6px;
  padding-bottom: 6px;
  border-bottom: 1px solid #f1f5f9;
}

.columns-list-container {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 280px;
  overflow-y: auto;
  padding-right: 4px;
}

.column-option-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #334155;
  cursor: pointer;
  user-select: none;
  transition: color 0.15s ease;
}

.column-option-item:hover {
  color: #0f172a;
}

.custom-checkbox {
  width: 16px;
  height: 16px;
  border-radius: 4px;
  border: 1.5px solid #cbd5e1;
  cursor: pointer;
  accent-color: #0B529C;
}

/* REVEALING FILTER PANEL */
.filter-panel {
  display: flex;
  align-items: flex-end;
  gap: 16px;
  background: #f9fafb;
  border-top: 1px solid #e5e7eb;
  border-bottom: 1px solid #e5e7eb;
  padding: 14px 28px;
  animation: slideDown 0.2s ease-out;
  flex-wrap: wrap;
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-8px); }
  to { opacity: 1; transform: translateY(0); }
}

.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.2s ease-out;
}
.slide-down-enter-from,
.slide-down-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

/* TABLE CONTAINER */
.table-container {
  width: 100%;
  overflow-x: auto;
  border-top: 1px solid #f1f5f9;
}

/* GLOBAL ERP TABLE STYLES (Applies to all slotted tables) */
:deep(.erp-table) {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
  font-size: 13px;
}

:deep(.erp-table th) {
  background-color: #fafafa;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
  height: 34px;
}

:deep(.erp-table td) {
  padding: 8px 16px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
  color: #404040;
  height: 38px;
}

:deep(.erp-table tr:hover) {
  background-color: #f8fafc;
}

:deep(.col-no) {
  width: 50px;
  color: #737373;
  font-weight: 500;
}

:deep(.col-primary-title) {
  font-size: 13px;
  font-weight: 550;
  color: #404040;
}

:deep(.col-secondary-desc) {
  font-size: 11.5px;
  color: #737373;
  line-height: 1.25;
}

:deep(.col-secondary-text) {
  color: #737373;
}

:deep(.status-pill) {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 2px 10px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 550;
  line-height: 1.2;
}

:deep(.pill-active) {
  background-color: #dcfce7;
  color: #15803d;
}

:deep(.pill-inactive) {
  background-color: #f1f5f9;
  color: #64748b;
}

:deep(.btn-action-dots) {
  background: none;
  border: none;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  color: #737373;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
}

:deep(.btn-action-dots:hover) {
  background-color: #f1f5f9;
  color: #404040;
}
</style>
