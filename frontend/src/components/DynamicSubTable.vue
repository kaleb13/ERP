<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import {
  Plus, Maximize2, ArrowUp, ArrowDown,
  Copy, FileDown, FileUp, X,
  Search, Info
} from 'lucide-vue-next';;
import TableFloatingBar from './TableFloatingBar.vue';
import BaseButton from './BaseButton.vue';
import FormCheckbox from './FormCheckbox.vue';
import FormSelect from './FormSelect.vue';
import IconColumnSolid from './IconColumnSolid.vue';

export interface DynamicTableColumn {
  key: string;
  label: string;
  width?: string;
  minWidth?: string;
  align?: 'left' | 'center' | 'right';
  tooltipTitle?: string;
  tooltipDesc?: string;
  type?: 'text' | 'number' | 'select' | 'switch' | 'badge' | 'avatar' | 'readonly' | 'date' | 'checkbox' | 'custom';
  options?: Array<any>;
  placeholder?: string;
  visible?: boolean;
  subtitleKey?: string;
  searchable?: boolean;
}

export interface CatalogItem {
  id: string | number;
  label: string;
  [key: string]: any;
}

interface Props {
  modelValue: any[];
  columns: DynamicTableColumn[];
  entityName?: string;
  entityNamePlural?: string;
  emptyText?: string;
  canAddRow?: boolean;
  canAddMultiple?: boolean;
  canExport?: boolean;
  canImport?: boolean;
  canExpand?: boolean;
  canDelete?: boolean;
  canDuplicate?: boolean;
  useCustomModal?: boolean;
  multiSelectCatalog?: CatalogItem[];
  newRowFactory?: () => any;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => [],
  columns: () => [],
  entityName: 'Item',
  entityNamePlural: 'Items',
  emptyText: 'No rows',
  canAddRow: true,
  canAddMultiple: false,
  canExport: false,
  canImport: false,
  canExpand: true,
  canDelete: true,
  canDuplicate: true,
  useCustomModal: false,
  multiSelectCatalog: () => [],
  newRowFactory: undefined
});

const emit = defineEmits<{
  (e: 'update:modelValue', val: any[]): void;
  (e: 'addRow', newRow: any): void;
  (e: 'addMultiple', selectedCatalogItems: CatalogItem[]): void;
  (e: 'deleteRow', index: number, row: any): void;
  (e: 'batchDelete', indices: number[], rows: any[]): void;
  (e: 'exportCsv'): void;
  (e: 'importCsv', importedRows: any[]): void;
  (e: 'createCatalogItem'): void;
  (e: 'expandRow', index: number, row: any): void;
}>();

// ─── Selection State ────────────────────────────────────────────────────────
const selectedIndices = ref<number[]>([]);

const isAllSelected = computed(() => {
  return props.modelValue.length > 0 && selectedIndices.value.length === props.modelValue.length;
});

const toggleSelectAll = () => {
  if (isAllSelected.value) {
    selectedIndices.value = [];
  } else {
    selectedIndices.value = props.modelValue.map((_, i) => i);
  }
};

const handleSelectAllChange = (checked: boolean | (string | number)[]) => {
  if (Boolean(checked)) {
    selectedIndices.value = props.modelValue.map((_, i) => i);
  } else {
    selectedIndices.value = [];
  }
};

const toggleRowSelection = (index: number) => {
  const pos = selectedIndices.value.indexOf(index);
  if (pos >= 0) {
    selectedIndices.value.splice(pos, 1);
  } else {
    selectedIndices.value.push(index);
  }
};

const handleRowCheckboxChange = (index: number, checked: boolean) => {
  const pos = selectedIndices.value.indexOf(index);
  if (checked && pos === -1) {
    selectedIndices.value.push(index);
  } else if (!checked && pos !== -1) {
    selectedIndices.value.splice(pos, 1);
  }
};

const handleSelectAllTotal = () => {
  selectedIndices.value = props.modelValue.map((_, i) => i);
};

// ─── Column Visibility State (Figma 6095:96580 & 3345:71204) ────────────────
const isColumnsMenuOpen = ref(false);
const columnsMenuRef = ref<HTMLElement | null>(null);
const columnVisibility = ref<Record<string, boolean>>({});

// Initialize visibility from props
watch(
  () => props.columns,
  (cols) => {
    cols.forEach(col => {
      if (columnVisibility.value[col.key] === undefined) {
        columnVisibility.value[col.key] = col.visible !== false;
      }
    });
  },
  { immediate: true, deep: true }
);

const isColumnVisible = (key: string): boolean => {
  return columnVisibility.value[key] !== false;
};

const toggleColumnVisibility = (key: string) => {
  columnVisibility.value[key] = !isColumnVisible(key);
};

const setColumnVisibility = (key: string, visible: boolean) => {
  columnVisibility.value[key] = visible;
};

const visibleColumnsCount = computed(() => {
  return props.columns.filter(c => isColumnVisible(c.key)).length;
});

const toggleColumnsMenu = () => {
  isColumnsMenuOpen.value = !isColumnsMenuOpen.value;
};

const handleClickOutside = (event: MouseEvent) => {
  if (columnsMenuRef.value && !columnsMenuRef.value.contains(event.target as Node)) {
    isColumnsMenuOpen.value = false;
  }
};

onMounted(() => {
  document.addEventListener('click', handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
});

// ─── Default Row Factory ───────────────────────────────────────────────────
const createDefaultRow = (): any => {
  if (props.newRowFactory) {
    return props.newRowFactory();
  }
  const row: Record<string, any> = { id: Date.now() + Math.random() };
  for (const col of props.columns) {
    if (col.type === 'switch') {
      row[col.key] = false;
    } else if (col.type === 'number') {
      row[col.key] = 0;
    } else {
      row[col.key] = '';
    }
  }
  return row;
};

// ─── Add Row Action ────────────────────────────────────────────────────────
const handleAddRow = () => {
  const row = createDefaultRow();
  const next = [...props.modelValue, row];
  emit('update:modelValue', next);
  emit('addRow', row);
};

// ─── Keyboard Enter Cell Traversal (ERPNext Grid Pattern) ──────────────────
const handleCellEnter = (rowIndex: number, columnKey: string) => {
  if (rowIndex < props.modelValue.length - 1) {
    nextTick(() => {
      const nextInput = document.querySelector(`[data-cell-row="${rowIndex + 1}"][data-cell-key="${columnKey}"]`) as HTMLInputElement;
      nextInput?.focus();
    });
  } else if (props.canAddRow) {
    handleAddRow();
    nextTick(() => {
      const nextInput = document.querySelector(`[data-cell-row="${rowIndex + 1}"][data-cell-key="${columnKey}"]`) as HTMLInputElement;
      nextInput?.focus();
    });
  }
};

// ─── Batch Delete Action ───────────────────────────────────────────────────
const handleBatchDelete = () => {
  if (selectedIndices.value.length === 0) return;
  const deletedRows = selectedIndices.value.map(i => props.modelValue[i]);
  const deletedIndices = [...selectedIndices.value];
  const next = props.modelValue.filter((_, i) => !selectedIndices.value.includes(i));
  selectedIndices.value = [];
  emit('update:modelValue', next);
  emit('batchDelete', deletedIndices, deletedRows);
};

// ─── Expand Row Modal State ────────────────────────────────────────────────
const isExpandModalOpen = ref(false);
const activeRowIndex = ref<number>(-1);
const activeRowData = ref<any>({});

const openExpandModal = (index: number) => {
  if (index < 0 || index >= props.modelValue.length) return;
  emit('expandRow', index, props.modelValue[index]);
  if (!props.useCustomModal) {
    activeRowIndex.value = index;
    // Clone active row data so edits or inspection are focused
    activeRowData.value = { ...props.modelValue[index] };
    isExpandModalOpen.value = true;
  }
};

const closeExpandModal = () => {
  // Sync back edits to list
  if (activeRowIndex.value >= 0 && activeRowIndex.value < props.modelValue.length) {
    const next = [...props.modelValue];
    next[activeRowIndex.value] = { ...activeRowData.value };
    emit('update:modelValue', next);
  }
  isExpandModalOpen.value = false;
  activeRowIndex.value = -1;
};

// Sync activeRowData when switching row index
watch(activeRowIndex, (newIdx) => {
  if (newIdx >= 0 && newIdx < props.modelValue.length) {
    activeRowData.value = { ...props.modelValue[newIdx] };
  }
});

// Modal Row Navigation Controls (Center Arrows: Down and Up)
const canNavigateDown = computed(() => {
  return activeRowIndex.value >= 0 && activeRowIndex.value < props.modelValue.length - 1;
});

const canNavigateUp = computed(() => {
  return activeRowIndex.value > 0;
});

const handleNavigateDown = () => {
  if (!canNavigateDown.value) return;
  // Save current
  const next = [...props.modelValue];
  next[activeRowIndex.value] = { ...activeRowData.value };
  emit('update:modelValue', next);

  activeRowIndex.value += 1;
};

const handleNavigateUp = () => {
  if (!canNavigateUp.value) return;
  // Save current
  const next = [...props.modelValue];
  next[activeRowIndex.value] = { ...activeRowData.value };
  emit('update:modelValue', next);

  activeRowIndex.value -= 1;
};

// Modal Row Actions (Right Group)
const handleModalDuplicateRow = () => {
  if (activeRowIndex.value < 0) return;
  const clone = {
    ...activeRowData.value,
    id: Date.now() + Math.random()
  };
  const next = [...props.modelValue];
  next.splice(activeRowIndex.value + 1, 0, clone);
  emit('update:modelValue', next);
  activeRowIndex.value += 1;
};

const handleModalInsertAbove = () => {
  if (activeRowIndex.value < 0) return;
  const blank = createDefaultRow();
  const next = [...props.modelValue];
  next.splice(activeRowIndex.value, 0, blank);
  emit('update:modelValue', next);
  activeRowIndex.value += 1; // Keep current focused or stay on created
};

const handleModalInsertBelow = () => {
  if (activeRowIndex.value < 0) return;
  const blank = createDefaultRow();
  const next = [...props.modelValue];
  next.splice(activeRowIndex.value + 1, 0, blank);
  emit('update:modelValue', next);
};

const handleModalDeleteRow = () => {
  if (activeRowIndex.value < 0) return;
  const deletedIndex = activeRowIndex.value;
  const deletedRow = props.modelValue[deletedIndex];
  const next = [...props.modelValue];
  next.splice(deletedIndex, 1);
  emit('update:modelValue', next);
  emit('deleteRow', deletedIndex, deletedRow);

  if (next.length === 0) {
    isExpandModalOpen.value = false;
    activeRowIndex.value = -1;
  } else if (activeRowIndex.value >= next.length) {
    activeRowIndex.value = next.length - 1;
  } else {
    activeRowData.value = { ...next[activeRowIndex.value] };
  }
};

// ─── Multi-Selection Modal ("+ Add Multiple") ──────────────────────────────
const isAddMultipleModalOpen = ref(false);
const catalogSearchQuery = ref('');
const selectedCatalogIds = ref<(string | number)[]>([]);

const filteredCatalog = computed(() => {
  if (!catalogSearchQuery.value.trim()) return props.multiSelectCatalog;
  const q = catalogSearchQuery.value.toLowerCase();
  return props.multiSelectCatalog.filter(item =>
    item.label.toLowerCase().includes(q)
  );
});

const openAddMultipleModal = () => {
  catalogSearchQuery.value = '';
  selectedCatalogIds.value = [];
  isAddMultipleModalOpen.value = true;
};

const closeAddMultipleModal = () => {
  isAddMultipleModalOpen.value = false;
};

const toggleCatalogSelection = (id: string | number) => {
  const pos = selectedCatalogIds.value.indexOf(id);
  if (pos >= 0) {
    selectedCatalogIds.value.splice(pos, 1);
  } else {
    selectedCatalogIds.value.push(id);
  }
};

const setCatalogSelection = (id: string | number, selected: boolean) => {
  const pos = selectedCatalogIds.value.indexOf(id);
  if (selected && pos === -1) {
    selectedCatalogIds.value.push(id);
  } else if (!selected && pos !== -1) {
    selectedCatalogIds.value.splice(pos, 1);
  }
};

const handleConfirmAddMultiple = () => {
  if (selectedCatalogIds.value.length === 0) {
    closeAddMultipleModal();
    return;
  }
  const chosenItems = props.multiSelectCatalog.filter(c => selectedCatalogIds.value.includes(c.id));
  const newRows = chosenItems.map(item => {
    const row = createDefaultRow();
    // Copy item label / id if appropriate
    row.catalog_id = item.id;
    row.name = item.label;
    return row;
  });

  const next = [...props.modelValue, ...newRows];
  emit('update:modelValue', next);
  emit('addMultiple', chosenItems);
  closeAddMultipleModal();
};

const handleCreateNewCatalogItem = () => {
  emit('createCatalogItem');
};

// ─── Export CSV ────────────────────────────────────────────────────────────
const handleExportCsv = () => {
  emit('exportCsv');
  if (props.modelValue.length === 0) return;

  const visibleCols = props.columns.filter(c => c.type !== 'custom');
  const headers = ['No.', ...visibleCols.map(c => `"${c.label.replace(/"/g, '""')}"`)];
  const rows = props.modelValue.map((r, i) => {
    const cells = [
      String(i + 1),
      ...visibleCols.map(c => {
        const val = r[c.key];
        if (val === null || val === undefined) return '""';
        return `"${String(val).replace(/"/g, '""')}"`;
      })
    ];
    return cells.join(',');
  });

  const csvContent = [headers.join(','), ...rows].join('\r\n');
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', `${props.entityNamePlural.toLowerCase().replace(/\s+/g, '_')}_export.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
};

// ─── Import CSV ────────────────────────────────────────────────────────────
const fileInputRef = ref<HTMLInputElement | null>(null);

const triggerImportClick = () => {
  if (fileInputRef.value) {
    fileInputRef.value.value = '';
    fileInputRef.value.click();
  }
};

const handleFileImport = (event: Event) => {
  const input = event.target as HTMLInputElement;
  if (!input.files || input.files.length === 0) return;
  const file = input.files[0];
  const reader = new FileReader();
  reader.onload = (e) => {
    const text = e.target?.result as string;
    if (!text) return;
    parseAndImportCsv(text);
  };
  reader.readAsText(file);
};

const parseAndImportCsv = (text: string) => {
  const lines = text.split(/\r?\n/).filter(line => line.trim().length > 0);
  if (lines.length < 2) return;

  const headerCells = lines[0].split(',').map(h => h.replace(/^"|"$/g, '').trim());
  const parsedRows: any[] = [];

  for (let i = 1; i < lines.length; i++) {
    const cells = lines[i].split(',').map(c => c.replace(/^"|"$/g, '').trim());
    const row = createDefaultRow();
    props.columns.forEach(col => {
      const idx = headerCells.indexOf(col.label);
      if (idx >= 0 && idx < cells.length) {
        if (col.type === 'switch') {
          row[col.key] = cells[idx].toLowerCase() === 'true' || cells[idx].toLowerCase() === 'yes';
        } else if (col.type === 'number') {
          row[col.key] = Number(cells[idx]) || 0;
        } else {
          row[col.key] = cells[idx];
        }
      }
    });
    parsedRows.push(row);
  }

  const next = [...props.modelValue, ...parsedRows];
  emit('update:modelValue', next);
  emit('importCsv', parsedRows);
};

// ─── Header Tooltip Hover ──────────────────────────────────────────────────
const activeTooltipKey = ref<string | null>(null);
const tooltipPos = ref({ top: 0, left: 0 });

const showTooltip = (key: string, event: MouseEvent) => {
  const target = event.currentTarget as HTMLElement;
  const rect = target.getBoundingClientRect();
  tooltipPos.value = {
    top: rect.top - 8,
    left: rect.left + rect.width / 2
  };
  activeTooltipKey.value = key;
};

const hideTooltip = () => {
  activeTooltipKey.value = null;
};
</script>

<template>
  <div class="dynamic-subtable-root">
    <!-- ─── Table Container (Card Box with subtle border) ─── -->
    <div class="table-container-card">
      <div class="table-scroll-wrap">
        <table class="dynamic-table">
          <thead>
            <tr class="table-header-row">
              <!-- Select All Checkbox Column -->
              <th class="th-cell th-check" @click.stop="toggleSelectAll">
                <FormCheckbox
                  :model-value="isAllSelected"
                  :indeterminate="selectedIndices.length > 0 && !isAllSelected"
                  size="sm"
                  @click.stop
                  @change="handleSelectAllChange"
                  aria-label="Select all rows"
                />
              </th>

              <!-- No. Sequence Column -->
              <th class="th-cell th-no">No.</th>

              <!-- Dynamic Scanning Columns -->
              <template v-for="col in columns" :key="col.key">
                <th
                  v-if="isColumnVisible(col.key)"
                  class="th-cell"
                  :style="{
                    width: col.width,
                    minWidth: col.minWidth || '140px',
                    textAlign: col.align || 'left'
                  }"
                >
                  <div class="th-inner" :class="`align-${col.align || 'left'}`">
                    <span>{{ col.label }}</span>
                    <!-- Info / Help Tooltip Icon -->
                    <button
                      v-if="col.tooltipTitle || col.tooltipDesc"
                      type="button"
                      class="th-info-btn"
                      @mouseenter="showTooltip(col.key, $event)"
                      @mouseleave="hideTooltip"
                      :aria-label="`Help for ${col.label}`"
                    >
                      <Info :size="13" />
                    </button>
                  </div>
                </th>
              </template>

              <!-- Column Layout / Density / Column Hider Header (Figma 6095:96580 & 6095:96606) -->
              <th class="th-cell th-density">
                <div class="columns-menu-anchor" ref="columnsMenuRef">
                  <button
                    type="button"
                    class="btn-density"
                    :class="{ 'btn-density-active': isColumnsMenuOpen }"
                    @click.stop="toggleColumnsMenu"
                    title="Hide / Show Columns"
                    aria-label="Hide or show columns"
                  >
                    <IconColumnSolid :size="16" />
                  </button>

                  <!-- Column Hide / Show Popover Menu -->
                  <div v-if="isColumnsMenuOpen" class="columns-dropdown-popover" @click.stop>
                    <div class="columns-dropdown-header">
                      <span class="columns-dropdown-title">Display Columns</span>
                    </div>
                    <div class="columns-checklist">
                      <div
                        v-for="col in columns"
                        :key="col.key"
                        class="column-check-row"
                      >
                        <FormCheckbox
                          :model-value="isColumnVisible(col.key)"
                          :label="col.label"
                          size="sm"
                          @change="(val) => setColumnVisibility(col.key, Boolean(val))"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </th>
            </tr>
          </thead>

          <tbody>
            <!-- Empty State: Standard Centered "No rows" -->
            <tr v-if="modelValue.length === 0" class="empty-state-row">
              <td :colspan="visibleColumnsCount + 3" class="empty-cell">
                <div class="empty-text">{{ emptyText }}</div>
              </td>
            </tr>

            <!-- Populated Rows with Inline Editing -->
            <tr
              v-else
              v-for="(row, idx) in modelValue"
              :key="row.id || idx"
              class="table-body-row"
              :class="{ 'row-selected': selectedIndices.includes(idx) }"
            >
              <!-- Row Checkbox -->
              <td class="td-cell td-check" @click.stop="toggleRowSelection(idx)">
                <FormCheckbox
                  :model-value="selectedIndices.includes(idx)"
                  size="sm"
                  @click.stop
                  @change="(val) => handleRowCheckboxChange(idx, Boolean(val))"
                  aria-label="Select row"
                />
              </td>

              <!-- No. Sequence -->
              <td class="td-cell td-no">{{ idx + 1 }}</td>

              <!-- Attribute Cells with Scoped Slots & QMT 3345:71204 Standard Cell Variants (ERPNext Grid Cell Pattern) -->
              <template v-for="col in columns" :key="col.key">
                <td
                  v-if="isColumnVisible(col.key)"
                  class="td-cell"
                  :class="[
                    `td-col-${col.type || 'text'}`,
                    {
                      'td-editable': !col.type || col.type === 'text' || col.type === 'number' || col.type === 'select' || col.type === 'date' || col.type === 'custom',
                      'td-readonly': col.type === 'readonly',
                      'td-badge-cell': col.type === 'badge',
                      'td-switch-cell': col.type === 'switch',
                      'td-checkbox-cell': col.type === 'checkbox'
                    }
                  ]"
                  :style="{ textAlign: col.align || 'left' }"
                >
                  <slot
                    :name="`cell-${col.key}`"
                    :row="row"
                    :index="idx"
                    :value="row[col.key]"
                  >
                    <slot
                      :name="col.key"
                      :row="row"
                      :index="idx"
                      :value="row[col.key]"
                    >
                      <!-- 1. Text Cell with Optional Supporting Subtitle (ERPNext Grid Cell) -->
                      <div v-if="!col.type || col.type === 'text'" class="cell-grid-wrap">
                        <input
                          type="text"
                          v-model="row[col.key]"
                          class="cell-grid-input"
                          :data-cell-row="idx"
                          :data-cell-key="col.key"
                          :placeholder="col.placeholder || ''"
                          @keydown.enter="handleCellEnter(idx, col.key)"
                        />
                        <span v-if="col.subtitleKey && row[col.subtitleKey]" class="cell-supporting-text">
                          {{ row[col.subtitleKey] }}
                        </span>
                      </div>

                      <!-- 2. Number Cell (Right-Aligned, ERPNext Grid Cell) -->
                      <div v-else-if="col.type === 'number'" class="cell-grid-wrap">
                        <input
                          type="number"
                          v-model.number="row[col.key]"
                          class="cell-grid-input text-right"
                          :data-cell-row="idx"
                          :data-cell-key="col.key"
                          :placeholder="col.placeholder || '0'"
                          @keydown.enter="handleCellEnter(idx, col.key)"
                        />
                      </div>

                      <!-- 3. FormSelect Dropdown Cell (Product Dropdown with Grouping & Checkmarks) -->
                      <div v-else-if="col.type === 'select'" class="cell-grid-select-wrap">
                        <FormSelect
                          v-model="row[col.key]"
                          :options="col.options || []"
                          :placeholder="col.placeholder || `Select ${col.label}`"
                          :searchable="col.searchable ?? ((col.options?.length || 0) > 6)"
                          variant="cell"
                          :teleport="true"
                          class="cell-grid-select"
                        />
                      </div>

                      <!-- 4. Date Cell (ERPNext Grid Cell) -->
                      <div v-else-if="col.type === 'date'" class="cell-grid-wrap">
                        <input
                          type="date"
                          v-model="row[col.key]"
                          class="cell-grid-input cell-grid-date"
                          :data-cell-row="idx"
                          :data-cell-key="col.key"
                          :placeholder="col.placeholder || ''"
                          @keydown.enter="handleCellEnter(idx, col.key)"
                        />
                      </div>

                      <!-- 5. Checkbox Cell (QMT Product Checkbox) -->
                      <div v-else-if="col.type === 'checkbox'" class="flex items-center justify-center h-full w-full">
                        <FormCheckbox
                          v-model="row[col.key]"
                          :title="col.label"
                        />
                      </div>

                      <!-- 6. Switch / Toggle Cell (Yes / No Pill Switch, QMT 3345:71204) -->
                      <div v-else-if="col.type === 'switch'" class="switch-cell-wrapper">
                        <button
                          type="button"
                          class="qmt-switch"
                          :class="{ 'switch-active': row[col.key] }"
                          @click="row[col.key] = !row[col.key]"
                          role="switch"
                          :aria-checked="row[col.key]"
                        >
                          <span class="switch-thumb"></span>
                        </button>
                        <span class="switch-label">{{ row[col.key] ? 'Yes' : 'No' }}</span>
                      </div>

                      <!-- 7. Status Badge Cell (QMT 3345:71204) -->
                      <span v-else-if="col.type === 'badge'" class="cell-badge-pill">
                        {{ row[col.key] }}
                      </span>

                      <!-- 8. Readonly Text Cell (QMT 3345:71204) -->
                      <div v-else-if="col.type === 'readonly'" class="cell-readonly-text">
                        <span class="cell-primary-text">{{ row[col.key] || '—' }}</span>
                        <span v-if="col.subtitleKey && row[col.subtitleKey]" class="cell-supporting-text">
                          {{ row[col.subtitleKey] }}
                        </span>
                      </div>
                    </slot>
                  </slot>
                </td>
              </template>

              <!-- Expand Row Action Icon (↗) -->
              <td class="td-cell td-expand">
                <button
                  v-if="canExpand"
                  type="button"
                  class="btn-expand-row"
                  @click="openExpandModal(idx)"
                  title="Expand Row Details"
                >
                  <Maximize2 :size="13" />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- ─── Action Strip Directly Below Table ─── -->
    <div v-if="canAddRow || canAddMultiple || canExport || canImport" class="table-bottom-bar">
      <!-- Left Group: + Add Row & + Add Multiple -->
      <div class="bottom-bar-left">
        <BaseButton
          v-if="canAddRow"
          variant="secondary-gray"
          size="sm"
          :icon="Plus"
          @click="handleAddRow"
        >
          Add Row
        </BaseButton>

        <BaseButton
          v-if="canAddMultiple"
          variant="secondary-gray"
          size="sm"
          :icon="Plus"
          @click="openAddMultipleModal"
        >
          Add Multiple
        </BaseButton>
      </div>

      <!-- Right Group: Export & Import in CSV format (Dynamically shown only when enabled) -->
      <div v-if="canExport || canImport" class="bottom-bar-right">
        <BaseButton
          v-if="canExport"
          variant="secondary-gray"
          size="sm"
          :icon="FileDown"
          title="Export data in CSV format"
          @click="handleExportCsv"
        >
          Export
        </BaseButton>

        <BaseButton
          v-if="canImport"
          variant="secondary-gray"
          size="sm"
          :icon="FileUp"
          title="Import data in CSV format"
          @click="triggerImportClick"
        >
          Import
        </BaseButton>

        <!-- Hidden CSV File Input -->
        <input
          ref="fileInputRef"
          type="file"
          accept=".csv,text/csv"
          class="hidden"
          style="display: none;"
          @change="handleFileImport"
        />
      </div>
    </div>

    <!-- ─── Floating Bulk Action Bar (when 1+ rows selected) ─── -->
    <TableFloatingBar
      :show="selectedIndices.length > 0"
      :selected-count="selectedIndices.length"
      :total-count="modelValue.length"
      :show-duplicate="false"
      :show-edit="false"
      :show-change-status="false"
      @selectAll="handleSelectAllTotal"
      @delete="handleBatchDelete"
      @close="selectedIndices = []"
    >
      <template #extra-actions>
        <slot name="bulk-actions" :selected-indices="selectedIndices" :selected-rows="selectedIndices.map(i => modelValue[i])"></slot>
      </template>
    </TableFloatingBar>

    <!-- ─── Expand Row Modal (Matching Figma 5104:71792) ─── -->
    <Teleport to="body">
      <Transition name="modal-fade">
        <div v-if="isExpandModalOpen" class="modal-backdrop" @click="closeExpandModal">
          <div class="expand-modal-box" @click.stop>
            <!-- Modal Header -->
            <div class="expand-modal-header">
              <h3 class="modal-title">
                {{ entityName }} <span class="row-tag">(Row {{ activeRowIndex + 1 }})</span>
              </h3>
              <button
                type="button"
                class="btn-modal-close"
                @click="closeExpandModal"
                aria-label="Close dialog"
              >
                <X :size="16" />
              </button>
            </div>

            <!-- Modal Content / Body Grid -->
            <div class="expand-modal-body">
              <slot
                name="expand-modal"
                :row="activeRowData"
                :index="activeRowIndex"
              >
                <!-- Default Grid of Inputs if no custom slot provided -->
                <div class="default-modal-grid">
                  <div
                    v-for="col in columns"
                    :key="col.key"
                    class="modal-field-wrap"
                  >
                    <label class="modal-field-label">{{ col.label }}</label>
                    <input
                      v-if="!col.type || col.type === 'text' || col.type === 'number'"
                      :type="col.type === 'number' ? 'number' : 'text'"
                      v-model="activeRowData[col.key]"
                      class="modal-input"
                    />
                    <FormSelect
                      v-else-if="col.type === 'select'"
                      v-model="activeRowData[col.key]"
                      :options="col.options || []"
                      :placeholder="col.placeholder || `Select ${col.label}`"
                      :searchable="col.searchable ?? ((col.options?.length || 0) > 6)"
                      :teleport="true"
                    />
                    <div v-else-if="col.type === 'switch'" class="switch-cell-wrapper mt-2">
                      <button
                        type="button"
                        class="qmt-switch"
                        :class="{ 'switch-active': activeRowData[col.key] }"
                        @click="activeRowData[col.key] = !activeRowData[col.key]"
                        role="switch"
                      >
                        <span class="switch-thumb"></span>
                      </button>
                      <span class="switch-label">{{ activeRowData[col.key] ? 'Yes' : 'No' }}</span>
                    </div>
                  </div>
                </div>
              </slot>
            </div>

            <!-- Modal Footer (Figma Canonical 3-section layout) -->
            <div class="expand-modal-footer">
              <!-- Left: Solid Red Delete Button -->
              <div class="footer-left">
                <BaseButton
                  type="button"
                  variant="error"
                  size="sm"
                  @click="handleModalDeleteRow"
                >
                  Delete
                </BaseButton>
              </div>

              <!-- Center: Row Navigation Arrows (Down & Up) -->
              <div class="footer-center" title="Used To Navigate Through The Rows">
                <button
                  type="button"
                  class="btn-nav-arrow"
                  :disabled="!canNavigateDown"
                  @click="handleNavigateDown"
                  title="Next Row"
                >
                  <ArrowDown :size="15" />
                </button>
                <button
                  type="button"
                  class="btn-nav-arrow"
                  :disabled="!canNavigateUp"
                  @click="handleNavigateUp"
                  title="Previous Row"
                >
                  <ArrowUp :size="15" />
                </button>
              </div>

              <!-- Right: Duplicate Row, Insert Above, Insert Below -->
              <div class="footer-right flex items-center gap-2">
                <BaseButton
                  v-if="canDuplicate"
                  type="button"
                  variant="secondary-gray"
                  size="sm"
                  :icon="Copy"
                  @click="handleModalDuplicateRow"
                  title="Clone current row"
                >
                  Duplicate Row
                </BaseButton>
                <BaseButton
                  type="button"
                  variant="secondary-gray"
                  size="sm"
                  :icon="Plus"
                  @click="handleModalInsertAbove"
                >
                  Insert Above
                </BaseButton>
                <BaseButton
                  type="button"
                  variant="secondary-gray"
                  size="sm"
                  :icon="Plus"
                  @click="handleModalInsertBelow"
                >
                  Insert Below
                </BaseButton>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ─── Multi-Selection Modal ("+ Add Multiple") ─── -->
    <Teleport to="body">
      <Transition name="modal-fade">
        <div v-if="isAddMultipleModalOpen" class="modal-backdrop" @click="closeAddMultipleModal">
          <div class="add-multiple-modal-box" @click.stop>
            <div class="expand-modal-header">
              <h3 class="modal-title">Select {{ entityNamePlural }}</h3>
              <button
                type="button"
                class="btn-modal-close"
                @click="closeAddMultipleModal"
                aria-label="Close"
              >
                <X :size="16" />
              </button>
            </div>

            <div class="add-multiple-modal-body">
              <!-- Search Input -->
              <div class="search-input-wrap">
                <Search :size="15" class="search-icon" />
                <input
                  type="text"
                  v-model="catalogSearchQuery"
                  class="catalog-search-input"
                  :placeholder="`Search ${entityNamePlural.toLowerCase()}...`"
                />
              </div>

              <!-- Scrollable Checklist -->
              <div class="catalog-checklist-container">
                <div
                  v-for="item in filteredCatalog"
                  :key="item.id"
                  class="catalog-checklist-item"
                  :class="{ 'item-active': selectedCatalogIds.includes(item.id) }"
                  @click="toggleCatalogSelection(item.id)"
                >
                  <FormCheckbox
                    :model-value="selectedCatalogIds.includes(item.id)"
                    :label="item.label"
                    size="sm"
                    @click.stop
                    @change="(val) => setCatalogSelection(item.id, Boolean(val))"
                  />
                </div>

                <div v-if="filteredCatalog.length === 0" class="catalog-empty">
                  No matching {{ entityNamePlural.toLowerCase() }} found
                </div>
              </div>

              <!-- Persistent Bottom Action: + Create a new [Entity] -->
              <button
                type="button"
                class="btn-create-catalog-shortcut"
                @click="handleCreateNewCatalogItem"
              >
                <Plus :size="14" />
                <span>Create a new {{ entityName }}</span>
              </button>
            </div>

            <div class="add-multiple-modal-footer">
              <BaseButton
                type="button"
                variant="secondary-gray"
                size="sm"
                @click="closeAddMultipleModal"
              >
                Close
              </BaseButton>
              <BaseButton
                type="button"
                variant="primary"
                size="sm"
                :disabled="selectedCatalogIds.length === 0"
                @click="handleConfirmAddMultiple"
              >
                Add Selected ({{ selectedCatalogIds.length }})
              </BaseButton>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ─── Floating Dark Header Tooltip ─── -->
    <Teleport to="body">
      <div
        v-if="activeTooltipKey"
        class="th-dark-tooltip"
        :style="{
          top: `${tooltipPos.top}px`,
          left: `${tooltipPos.left}px`
        }"
      >
        <div class="tooltip-title">
          {{ columns.find(c => c.key === activeTooltipKey)?.tooltipTitle || columns.find(c => c.key === activeTooltipKey)?.label }}
        </div>
        <div
          v-if="columns.find(c => c.key === activeTooltipKey)?.tooltipDesc"
          class="tooltip-desc"
        >
          {{ columns.find(c => c.key === activeTooltipKey)?.tooltipDesc }}
        </div>
        <div class="tooltip-caret"></div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.dynamic-subtable-root {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-md, 12px);
  width: 100%;
}

/* ─── Table Container Box ─────────────────────────────────────────────────── */
.table-container-card {
  width: 100%;
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-xl, 12px);
  overflow: hidden;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.04);
}

.table-scroll-wrap {
  width: 100%;
  overflow-x: auto;
}

.dynamic-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
  font-family: inherit;
  font-size: 13px;
}

/* ─── Header Styling ──────────────────────────────────────────────────────── */
.table-header-row {
  background-color: #ffffff;
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
}

.th-cell {
  padding: 10px 14px;
  font-size: 13px;
  font-weight: 500;
  color: var(--alias-color-text-secondary, #404040);
  white-space: nowrap;
  user-select: none;
  border-right: 1px solid var(--alias-color-border-subtle, #e5e5e5);
}

.th-cell:last-child {
  border-right: none;
}

.th-check {
  width: 44px;
  text-align: center;
  padding: 10px 8px;
  vertical-align: middle;
}

.th-check :deep(.qmt-checkbox-wrapper),
.td-check :deep(.qmt-checkbox-wrapper) {
  margin: 0 auto;
  display: inline-flex;
  vertical-align: middle;
}

.th-no {
  width: 52px;
  color: var(--alias-color-text-tertiary, #737373);
  font-weight: 500;
}

.th-density {
  width: 48px;
  text-align: center;
  padding-right: 14px;
}

.th-inner {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.th-inner.align-center {
  justify-content: center;
  width: 100%;
}

.th-inner.align-right {
  justify-content: flex-end;
  width: 100%;
}

.th-info-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  padding: 0;
  cursor: pointer;
  color: var(--alias-color-icon-tertiary, #737373);
  transition: color 0.15s ease;
}

.th-info-btn:hover {
  color: var(--alias-color-brand-default, #0b529c);
}

.btn-density {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 4px;
  color: var(--alias-color-icon-tertiary, #737373);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: all 0.15s ease;
}

.btn-density:hover,
.btn-density-active {
  color: var(--alias-color-brand-default, #0b529c) !important;
  background-color: #f0f7ff;
}

/* ─── Column Hider Popover Menu (Figma 6095:96580) ────────────────────────── */
.columns-menu-anchor {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.columns-dropdown-popover {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  width: 210px;
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-lg, 8px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
  z-index: 50;
  padding: 8px 0;
  display: flex;
  flex-direction: column;
}

.columns-dropdown-header {
  padding: 6px 12px 8px 12px;
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
}

.columns-dropdown-title {
  font-size: 11px;
  font-weight: 600;
  color: var(--alias-color-text-tertiary, #737373);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.columns-checklist {
  display: flex;
  flex-direction: column;
  max-height: 220px;
  overflow-y: auto;
  padding: 4px 0;
}

.column-check-row {
  display: flex;
  align-items: center;
  padding: 4px 12px;
  cursor: pointer;
  transition: background-color 0.1s ease;
  user-select: none;
}

.column-check-row:hover {
  background-color: var(--alias-color-background-hover, #f5f5f5);
}

.column-check-row :deep(.qmt-checkbox-wrapper) {
  width: 100%;
  margin: 0;
  padding: 2px 0;
  align-items: center;
}

.column-check-row :deep(.qmt-checkbox-label) {
  font-size: 13px;
  color: var(--alias-color-text-secondary, #404040);
  font-weight: 400;
}

/* ─── Checkbox Token Styling ──────────────────────────────────────────────── */
.qmt-checkbox {
  width: 16px;
  height: 16px;
  border-radius: 4px;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  cursor: pointer;
  accent-color: var(--alias-color-brand-default, #0b529c);
  display: block;
  margin: 0 auto;
}

/* ─── Body Rows Styling ───────────────────────────────────────────────────── */
.table-body-row {
  background-color: #ffffff;
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  transition: background-color 0.12s ease;
}

.table-body-row:last-child {
  border-bottom: none;
}

.table-body-row:hover {
  background-color: #fafcff;
}

.table-body-row.row-selected {
  background-color: #f0f7ff;
}

.td-cell {
  padding: 0;
  color: var(--alias-color-text-primary, #262626);
  vertical-align: middle;
  border-right: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  height: 42px;
  position: relative;
  background-color: #ffffff;
  transition: background-color 0.12s ease;
}

.td-cell:last-child {
  border-right: none;
}

.td-check {
  width: 44px;
  text-align: center;
  padding: 0 8px;
  vertical-align: middle;
}

.td-no {
  width: 52px;
  padding: 0 14px;
  font-size: 13px;
  color: var(--alias-color-text-tertiary, #737373);
  font-variant-numeric: tabular-nums;
  vertical-align: middle;
}

.td-expand {
  width: 48px;
  text-align: center;
  padding: 0 14px;
  vertical-align: middle;
}

.td-readonly,
.td-badge-cell,
.td-switch-cell {
  padding: 8px 14px;
}

/* ─── ERPNext Grid Cell Pattern: The Cell ITSELF is the Input ────────────── */
.td-editable {
  padding: 0;
  cursor: text;
}

.td-editable:hover:not(:focus-within) {
  background-color: #fcfcfc;
}

.td-editable:focus-within {
  background-color: #ffffff;
  box-shadow: inset 0 0 0 2px var(--alias-color-brand-default, #0b529c);
  z-index: 5;
}

.cell-grid-wrap {
  width: 100%;
  height: 100%;
  min-height: 42px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  position: relative;
}

.cell-grid-input,
.cell-inline-input {
  width: 100%;
  height: 100%;
  min-height: 42px;
  padding: 8px 14px;
  border: none;
  outline: none;
  background: transparent;
  font-size: 13px;
  font-family: inherit;
  color: var(--alias-color-text-primary, #262626);
  line-height: 20px;
  box-sizing: border-box;
}

.cell-grid-input::placeholder,
.cell-inline-input::placeholder {
  color: var(--alias-color-text-disabled, #a1a1a1);
}

.cell-grid-input.text-right,
.cell-inline-input.text-right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

.cell-grid-date,
.cell-inline-input[type="date"] {
  color: var(--alias-color-text-primary, #262626);
}

.cell-grid-select-wrap {
  width: 100%;
  height: 100%;
  min-height: 42px;
  display: flex;
  align-items: center;
  position: relative;
}

.cell-grid-select {
  width: 100%;
  height: 100%;
}

.cell-supporting-text {
  font-size: 11.5px;
  color: var(--alias-color-text-tertiary, #737373);
  padding: 0 14px 4px 14px;
}

.cell-readonly-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.cell-primary-text {
  font-size: 13px;
  color: var(--alias-color-text-primary, #262626);
  font-weight: 500;
}

.cell-badge-pill {
  display: inline-flex;
  align-items: center;
  padding: 3px 8px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
  background-color: var(--alias-color-background-hover, #f5f5f5);
  color: var(--alias-color-text-secondary, #404040);
}

/* ─── Pill Switch Component (Yes / No) ────────────────────────────────────── */
.switch-cell-wrapper {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.qmt-switch {
  width: 36px;
  height: 20px;
  background-color: #e5e5e5;
  border-radius: 9999px;
  border: none;
  cursor: pointer;
  position: relative;
  padding: 2px;
  transition: background-color 0.2s ease;
  display: inline-block;
}

.qmt-switch.switch-active {
  background-color: var(--alias-color-brand-default, #0b529c);
}

.switch-thumb {
  width: 16px;
  height: 16px;
  background-color: #ffffff;
  border-radius: 9999px;
  display: block;
  transition: transform 0.2s ease;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.15);
}

.qmt-switch.switch-active .switch-thumb {
  transform: translateX(16px);
}

.switch-label {
  font-size: 13px;
  font-weight: 500;
  color: var(--alias-color-text-secondary, #404040);
  min-width: 26px;
}

/* ─── Expand Icon Button ──────────────────────────────────────────────────── */
.btn-expand-row {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: var(--alias-radius-md, 6px);
  color: var(--alias-color-icon-tertiary, #737373);
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-expand-row:hover {
  background-color: #f0f4f9;
  color: var(--alias-color-brand-default, #0b529c);
}

/* ─── Empty State ─────────────────────────────────────────────────────────── */
.empty-state-row td {
  padding: 32px 16px;
  text-align: center;
  border-bottom: none;
}

.empty-text {
  font-size: 13px;
  color: var(--alias-color-text-tertiary, #737373);
  font-weight: 400;
}

/* ─── Bottom Action Strip (Always Below Table) ────────────────────────────── */
.table-bottom-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}

.bottom-bar-left,
.bottom-bar-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.qmt-pill-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 16px;
  border-radius: 100px;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  background-color: #ffffff;
  color: var(--alias-color-text-secondary, #404040);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.04);
  transition: all 0.15s ease;
}

.qmt-pill-btn:hover {
  background-color: #f8fafc;
  border-color: #d1d5db;
  color: var(--alias-color-text-primary, #262626);
}

/* ─── Expand Row Modal Backdrop & Box ─────────────────────────────────────── */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(2px);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.expand-modal-box {
  width: 100%;
  max-width: 820px;
  max-height: 90vh;
  background: #ffffff;
  border-radius: var(--alias-radius-2xl, 16px);
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.expand-modal-header {
  padding: 20px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
}

.modal-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: var(--alias-color-text-primary, #262626);
}

.row-tag {
  color: var(--alias-color-text-tertiary, #737373);
  font-weight: 400;
  font-size: 16px;
  margin-left: 4px;
}

.btn-modal-close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 9999px;
  border: none;
  background: transparent;
  color: var(--alias-color-icon-tertiary, #737373);
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-modal-close:hover {
  background-color: #f1f5f9;
  color: var(--alias-color-text-primary, #262626);
}

.expand-modal-body {
  padding: 24px;
  overflow-y: auto;
  flex: 1;
}

.default-modal-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.modal-field-wrap {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.modal-field-label {
  font-size: 13px;
  font-weight: 500;
  color: var(--alias-color-text-secondary, #404040);
}

.modal-input,
.modal-select {
  height: 40px;
  padding: 0 12px;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-md, 8px);
  background: #ffffff;
  font-size: 13px;
  color: var(--alias-color-text-primary, #262626);
  outline: none;
  transition: border-color 0.15s ease;
}

.modal-input:focus,
.modal-select:focus {
  border-color: var(--alias-color-brand-default, #0b529c);
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.1);
}

/* ─── Modal Footer (Left Delete, Center Nav, Right Actions) ───────────────── */
.expand-modal-footer {
  padding: 16px 24px;
  border-top: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: #ffffff;
  gap: 12px;
}

.footer-left {
  display: flex;
  align-items: center;
}

.btn-modal-delete {
  height: 38px;
  padding: 0 20px;
  border-radius: 100px;
  border: none;
  background-color: var(--alias-color-error-default, #e7000b);
  color: #ffffff;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.btn-modal-delete:hover {
  background-color: #c9000a;
}

.footer-center {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-nav-arrow {
  width: 38px;
  height: 38px;
  border-radius: var(--alias-radius-md, 8px);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  background: #ffffff;
  color: var(--alias-color-text-secondary, #404040);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-nav-arrow:hover:not(:disabled) {
  background-color: #f8fafc;
  border-color: #cbd5e1;
  color: var(--alias-color-text-primary, #262626);
}

.btn-nav-arrow:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.footer-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-modal-action {
  height: 38px;
  padding: 0 14px;
  border-radius: var(--alias-radius-md, 8px);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  background: #ffffff;
  color: var(--alias-color-text-secondary, #404040);
  font-size: 13px;
  font-weight: 500;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-modal-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
  color: var(--alias-color-text-primary, #262626);
}

/* ─── Add Multiple Modal Box ──────────────────────────────────────────────── */
.add-multiple-modal-box {
  width: 100%;
  max-width: 520px;
  max-height: 85vh;
  background: #ffffff;
  border-radius: var(--alias-radius-2xl, 16px);
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.add-multiple-modal-body {
  padding: 20px 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  flex: 1;
  overflow-y: auto;
}

.search-input-wrap {
  position: relative;
  width: 100%;
}

.search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--alias-color-icon-tertiary, #737373);
  pointer-events: none;
}

.catalog-search-input {
  width: 100%;
  height: 38px;
  padding: 0 12px 0 36px;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-md, 8px);
  font-size: 13px;
  outline: none;
}

.catalog-search-input:focus {
  border-color: var(--alias-color-brand-default, #0b529c);
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.1);
}

.catalog-checklist-container {
  max-height: 260px;
  overflow-y: auto;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-md, 8px);
  padding: 6px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.catalog-checklist-item {
  display: flex;
  align-items: center;
  padding: 6px 10px;
  border-radius: var(--alias-radius-sm, 6px);
  cursor: pointer;
  transition: background-color 0.12s ease;
}

.catalog-checklist-item:hover {
  background-color: #f8fafc;
}

.catalog-checklist-item.item-active {
  background-color: #f1f5f9;
}

.catalog-checklist-item :deep(.qmt-checkbox-wrapper) {
  width: 100%;
  margin: 0;
  padding: 0;
  align-items: center;
}

.catalog-checklist-item :deep(.qmt-checkbox-label) {
  font-size: 13px;
  font-weight: 500;
  color: var(--alias-color-text-primary, #262626);
}

.catalog-empty {
  padding: 24px;
  text-align: center;
  font-size: 13px;
  color: var(--alias-color-text-tertiary, #737373);
}

.btn-create-catalog-shortcut {
  background: transparent;
  border: none;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--alias-color-brand-default, #0b529c);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  padding: 4px 0;
  align-self: flex-start;
}

.btn-create-catalog-shortcut:hover {
  text-decoration: underline;
}

.add-multiple-modal-footer {
  padding: 16px 24px;
  border-top: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
}

.btn-confirm-add {
  background-color: var(--alias-color-brand-default, #0b529c);
  border-color: var(--alias-color-brand-default, #0b529c);
  color: #ffffff;
}

.btn-confirm-add:hover:not(:disabled) {
  background-color: #094380;
  color: #ffffff;
}

.btn-confirm-add:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* ─── Floating Dark Header Tooltip ────────────────────────────────────────── */
.th-dark-tooltip {
  position: fixed;
  transform: translate(-50%, -100%);
  background-color: #0f172a;
  color: #ffffff;
  padding: 8px 12px;
  border-radius: var(--alias-radius-md, 8px);
  font-size: 12px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.2);
  pointer-events: none;
  z-index: 2000;
  max-width: 240px;
  text-align: left;
}

.tooltip-title {
  font-weight: 600;
  color: #ffffff;
  margin-bottom: 2px;
}

.tooltip-desc {
  font-size: 11px;
  color: #94a3b8;
  line-height: 1.4;
}

.tooltip-caret {
  position: absolute;
  bottom: -4px;
  left: 50%;
  transform: translateX(-50%);
  width: 0;
  height: 0;
  border-left: 5px solid transparent;
  border-right: 5px solid transparent;
  border-top: 5px solid #0f172a;
}
</style>
