<!--
  Authoritative QMT AppDataTable Component (Figma 10178:30728 & 3345:27403)
  =========================================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Primary directory and data listing table across Haleta ERP.
  - Pre-assembles: Title block, Table Top Filter Section (search input, filter popover, secondary sort button),
    column visibility hider (`IconColumnSolid`), table body, floating bulk action bar (`TableFloatingBar`),
    and pagination (`BasePagination`).
  - Used for top-level directory views (Employees, Purchase Methods, Categories, Shifts, Leave Requests, Assets).

  WHEN NOT TO USE:
  - DO NOT use for 1:N dynamic child line items or rosters in create forms (use `DynamicSubTable.vue` instead).
  - DO NOT use inside modal dialogs or narrow sidebars.
-->
<script setup lang="ts">
import BaseTable, { type ColumnDef, type SortOption } from './BaseTable.vue';

export type { ColumnDef, SortOption };

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
</script>

<template>
  <BaseTable
    :title="props.title"
    :subtitle="props.subtitle"
    :searchPlaceholder="props.searchPlaceholder"
    :searchQuery="props.searchQuery"
    :showSearch="props.showSearch"
    :showFilter="props.showFilter"
    :filterCount="props.filterCount"
    :showSort="props.showSort"
    :sortOptions="props.sortOptions"
    :currentSort="props.currentSort"
    :sortOrder="props.sortOrder"
    :showColumns="props.showColumns"
    :columns="props.columns"
    :showFullscreen="props.showFullscreen"
    :totalEntries="props.totalEntries"
    :currentPage="props.currentPage"
    :perPage="props.perPage"
    :perPageOptions="props.perPageOptions"
    :showPagination="props.showPagination"
    @update:searchQuery="(v) => emit('update:searchQuery', v)"
    @update:currentPage="(v) => emit('update:currentPage', v)"
    @update:perPage="(v) => emit('update:perPage', v)"
    @update:currentSort="(v) => emit('update:currentSort', v)"
    @update:sortOrder="(v) => emit('update:sortOrder', v)"
    @toggleColumn="(k) => emit('toggleColumn', k)"
    @resetFilter="() => emit('resetFilter')"
  >
    <template v-if="$slots.header" #header><slot name="header" /></template>
    <template v-if="$slots['header-extra']" #header-extra><slot name="header-extra" /></template>
    <template v-if="$slots['toolbar-left']" #toolbar-left><slot name="toolbar-left" /></template>
    <template v-if="$slots['toolbar-right']" #toolbar-right><slot name="toolbar-right" /></template>
    <template v-if="$slots.actions" #actions><slot name="actions" /></template>
    <template v-if="$slots['filter-panel'] || $slots['filter'] || $slots['filterContent']" #filter-panel>
      <slot name="filter-panel" />
      <slot name="filter" />
      <slot name="filterContent" />
    </template>
    <slot name="customTable" />
    <slot />
  </BaseTable>
</template>
