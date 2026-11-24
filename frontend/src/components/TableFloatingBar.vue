<!--
  Authoritative QMT TableFloatingBar Component (Figma 3345:27403)
  ==============================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Floating bottom action bar that appears automatically when 1 or more rows are selected in data tables.
  - Houses batch/bulk operations: Bulk Change Status, Bulk Duplicate, Bulk Edit, Bulk Export, Bulk Delete.
  - Automatically wired into `AppDataTable.vue` and available for custom `BaseTable.vue` views.

  WHEN NOT TO USE:
  - DO NOT display when 0 rows are selected.
  - DO NOT use for single-row operations (use the 3-dot kebab menu in the table's Actions column instead).
  - DO NOT use inside modal dialogs or sub-tables with inline row actions.
-->
<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { 
  Copy, Pencil, Trash2, RotateCw, MoreVertical, 
  CheckCircle2, XCircle, Clock, Lock, History, 
  Download, ToggleLeft, X, GripVertical
} from 'lucide-vue-next';

interface Props {
  show?: boolean;
  selectedCount?: number;
  count?: number;
  totalCount?: number;
  total?: number;
  showChangeStatus?: boolean;
  showDuplicate?: boolean;
  showEdit?: boolean;
  showDelete?: boolean;
  showMore?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  show: undefined,
  selectedCount: 0,
  count: 0,
  totalCount: 0,
  total: 0,
  showChangeStatus: true,
  showDuplicate: true,
  showEdit: true,
  showDelete: true,
  showMore: true
});

const emit = defineEmits<{
  (e: 'selectAll'): void;
  (e: 'changeStatus', status: string): void;
  (e: 'duplicate'): void;
  (e: 'edit'): void;
  (e: 'delete'): void;
  (e: 'export'): void;
  (e: 'deactivate'): void;
  (e: 'close'): void;
  (e: 'clear'): void;
}>();

const effectiveSelectedCount = computed<number>(() => {
  return Number(props.selectedCount || props.count || 0);
});

const effectiveTotalCount = computed<number>(() => {
  return Number(props.totalCount || props.total || 0);
});

const isVisible = computed<boolean>(() => {
  if (props.show !== undefined) {
    return props.show && effectiveSelectedCount.value > 0;
  }
  return effectiveSelectedCount.value > 0;
});

// Popover states
const showStatusPopover = ref(false);
const showMorePopover = ref(false);
const showTooltip = ref(false);

const toggleStatusPopover = (event: MouseEvent) => {
  event.stopPropagation();
  showStatusPopover.value = !showStatusPopover.value;
  showMorePopover.value = false;
};

const toggleMorePopover = (event: MouseEvent) => {
  event.stopPropagation();
  showMorePopover.value = !showMorePopover.value;
  showStatusPopover.value = false;
};

const handleSelectStatus = (status: string) => {
  emit('changeStatus', status);
  showStatusPopover.value = false;
};

const handleExport = () => {
  emit('export');
  showMorePopover.value = false;
};

const handleDeactivate = () => {
  emit('deactivate');
  showMorePopover.value = false;
};

const handleClose = () => {
  emit('close');
  emit('clear');
};

const closePopovers = () => {
  showStatusPopover.value = false;
  showMorePopover.value = false;
};

onMounted(() => {
  window.addEventListener('click', closePopovers);
});

onUnmounted(() => {
  window.removeEventListener('click', closePopovers);
});
</script>

<template>
  <Transition name="floating-slide">
    <div v-if="isVisible" class="floating-action-bar-wrap">
      <div class="floating-action-bar" @click.stop>
        <!-- Drag Handle (6 dots) -->
        <div class="floating-grip" title="Bulk Action Bar">
          <GripVertical :size="14" class="grip-icon" />
        </div>

        <div class="floating-sep" />

        <!-- Count & Select All Option -->
        <div class="floating-count-info">
          <span class="count-bold">{{ effectiveSelectedCount }} Selected</span>
          <span v-if="effectiveTotalCount && effectiveTotalCount > effectiveSelectedCount" class="count-divider">•</span>
          <button 
            v-if="effectiveTotalCount && effectiveTotalCount > effectiveSelectedCount" 
            type="button" 
            class="count-select-all" 
            @click="$emit('selectAll')"
          >
            Select all {{ effectiveTotalCount }}
          </button>
        </div>

        <div class="floating-sep" />

        <!-- Action Items -->
        <div class="floating-actions-row">
          <!-- 1. Change Status (with Popover Dropdown) -->
          <div v-if="props.showChangeStatus" class="relative">
            <button 
              type="button" 
              class="floating-btn status-pill-btn" 
              :class="{ 'is-active': showStatusPopover }"
              @click="toggleStatusPopover"
            >
              <RotateCw :size="13" class="status-btn-icon" />
              <span>Change status</span>
            </button>

            <!-- Status Dropdown Popover (Image 2) -->
            <Transition name="popover-fade">
              <div v-if="showStatusPopover" class="floating-popover-menu status-popover">
                <button type="button" class="popover-item text-neutral-800" @click="handleSelectStatus('Approved')">
                  <CheckCircle2 :size="15" class="icon-success flex-shrink-0" />
                  <span>Approve</span>
                </button>
                <button type="button" class="popover-item text-neutral-800" @click="handleSelectStatus('Rejected')">
                  <XCircle :size="15" class="icon-error flex-shrink-0" />
                  <span>Reject</span>
                </button>
                <button type="button" class="popover-item text-neutral-800" @click="handleSelectStatus('Pending')">
                  <Clock :size="15" class="icon-warning flex-shrink-0" />
                  <span>Pending</span>
                </button>
                <button type="button" class="popover-item text-neutral-800" @click="handleSelectStatus('Locked')">
                  <Lock :size="15" class="icon-tertiary flex-shrink-0" />
                  <span>Locked</span>
                </button>
                <button type="button" class="popover-item text-neutral-800" @click="handleSelectStatus('Expired')">
                  <History :size="15" class="icon-tertiary flex-shrink-0" />
                  <span>Expired</span>
                </button>
              </div>
            </Transition>
          </div>

          <!-- 2. Duplicate -->
          <button 
            v-if="props.showDuplicate" 
            type="button" 
            class="floating-btn" 
            @click="$emit('duplicate')"
          >
            <Copy :size="14" class="icon-secondary" />
            <span>Duplicate</span>
          </button>

          <!-- 3. Edit -->
          <button 
            v-if="props.showEdit" 
            type="button" 
            class="floating-btn" 
            @click="$emit('edit')"
          >
            <Pencil :size="14" class="icon-secondary" />
            <span>Edit</span>
          </button>

          <!-- 4. Delete (Red) -->
          <button 
            v-if="props.showDelete" 
            type="button" 
            class="floating-btn btn-delete" 
            @click="$emit('delete')"
          >
            <Trash2 :size="14" class="icon-error" />
            <span class="icon-error font-medium">Delete</span>
          </button>

          <div v-if="props.showMore" class="floating-sep" />

          <!-- 5. More Actions (...) -->
          <div v-if="props.showMore" class="relative">
            <button 
              type="button" 
              class="floating-btn-icon" 
              :class="{ 'is-active': showMorePopover }"
              @click="toggleMorePopover"
              @mouseenter="showTooltip = true"
              @mouseleave="showTooltip = false"
              title="More Actions"
            >
              <MoreVertical :size="15" class="icon-secondary" />
            </button>

            <!-- Tooltip Prompt (Image 2) -->
            <div v-if="showTooltip && !showMorePopover" class="floating-info-tooltip">
              <span>This is needed or available if there are more than 4 bulk actions.</span>
              <div class="tooltip-arrow-left" />
            </div>

            <!-- More Popover (Image 2) -->
            <Transition name="popover-fade">
              <div v-if="showMorePopover" class="floating-popover-menu more-popover">
                <button type="button" class="popover-item text-neutral-800" @click="handleExport">
                  <Download :size="15" class="icon-secondary flex-shrink-0" />
                  <span>Export</span>
                </button>
                <button type="button" class="popover-item text-neutral-800" @click="handleDeactivate">
                  <ToggleLeft :size="15" class="icon-secondary flex-shrink-0" />
                  <span>Deactivate</span>
                </button>
              </div>
            </Transition>
          </div>
        </div>

        <!-- Close / Deselect (X) -->
        <button 
          type="button" 
          class="floating-close-btn" 
          @click="handleClose" 
          title="Clear Selection"
        >
          <X :size="13" />
        </button>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.floating-action-bar-wrap {
  position: fixed;
  bottom: 28px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 1050;
  pointer-events: none;
}

.floating-action-bar {
  pointer-events: auto;
  display: inline-flex;
  align-items: center;
  gap: var(--alias-spacing-lg, 12px);
  background-color: var(--alias-color-background-surface-elevated, #ffffff);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-full, 9999px);
  box-shadow: 0 14px 34px -4px rgba(0, 0, 0, 0.12), 0 4px 12px -2px rgba(0, 0, 0, 0.06);
  padding: var(--alias-spacing-sm, 6px) var(--alias-spacing-xl, 16px);
  height: 46px;
  user-select: none;
}

.floating-grip {
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: grab;
  color: var(--qmt-icon-tertiary, #737373);
  padding: 2px;
}

.grip-icon {
  color: var(--qmt-icon-secondary, #404040);
}

.floating-sep {
  width: 1px;
  height: 18px;
  background-color: var(--alias-color-border-subtle, #e5e5e5);
  flex-shrink: 0;
}

.floating-count-info {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #404040;
  white-space: nowrap;
}

.count-bold {
  font-weight: 500;
  color: var(--alias-color-text-secondary, #404040);
}

.count-divider {
  color: var(--alias-color-text-disabled, #a1a1a1);
  font-size: 11px;
}

.count-select-all {
  background: transparent;
  border: none;
  padding: 0;
  color: var(--alias-color-text-secondary, #404040);
  font-size: 13px;
  font-weight: 500;
  text-decoration: underline;
  cursor: pointer;
  transition: color 0.15s ease;
}
.count-select-all:hover {
  color: var(--alias-color-brand-blue-primary, #0B529C);
}

.floating-actions-row {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.floating-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 32px;
  padding: 0 12px;
  border-radius: 9999px;
  background: transparent;
  border: none;
  font-size: 13px;
  font-weight: 500;
  color: var(--alias-color-text-secondary, #404040);
  cursor: pointer;
  transition: all 0.15s ease;
  white-space: nowrap;
}
.floating-btn:hover {
  background-color: var(--alias-color-background-hover, #f5f5f5);
  color: var(--alias-color-text-secondary, #404040);
}

.status-pill-btn {
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  background-color: #ffffff;
  padding: 0 12px;
}
.status-pill-btn:hover,
.status-pill-btn.is-active {
  background-color: var(--alias-color-background-primary, #fafafa);
  border-color: var(--alias-color-border-primary, #d4d4d4);
}

.status-btn-icon {
  color: var(--qmt-icon-tertiary, #737373);
}

.btn-delete:hover {
  background-color: var(--primitive-color-red-50, #fef2f2);
}

.floating-btn-icon {
  width: 32px;
  height: 32px;
  border-radius: 9999px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  color: var(--qmt-icon-tertiary, #737373);
  cursor: pointer;
  transition: all 0.15s ease;
}
.floating-btn-icon:hover,
.floating-btn-icon.is-active {
  background-color: var(--alias-color-background-hover, #f5f5f5);
  color: var(--qmt-icon-secondary, #404040);
  border-color: var(--alias-color-border-primary, #d4d4d4);
}

.floating-close-btn {
  width: 22px;
  height: 22px;
  border-radius: 9999px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--alias-color-background-hover, #f5f5f5);
  border: none;
  color: var(--qmt-icon-tertiary, #737373);
  cursor: pointer;
  margin-left: 2px;
  transition: all 0.15s ease;
}
.floating-close-btn:hover {
  background-color: var(--alias-color-border-subtle, #e5e5e5);
  color: var(--qmt-icon-secondary, #404040);
}

/* ─── Floating Popover Menus (Image 2) ─── */
.floating-popover-menu {
  position: absolute;
  bottom: calc(100% + 12px);
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: 14px;
  box-shadow: 0 18px 30px -4px rgba(0, 0, 0, 0.14), 0 6px 14px -3px rgba(0, 0, 0, 0.08);
  padding: 6px;
  min-width: 148px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  z-index: 1060;
}

.status-popover {
  left: 0;
}

.more-popover {
  right: 0;
}

.popover-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 7px 12px;
  border-radius: 8px;
  border: none;
  background: transparent;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  text-align: left;
  width: 100%;
  transition: background-color 0.12s ease;
}
.popover-item:hover {
  background-color: #fafafa;
}

/* ─── Tooltip Prompt (Image 2) ─── */
.floating-info-tooltip {
  position: absolute;
  bottom: 0;
  left: calc(100% + 10px);
  width: 180px;
  background-color: #0352A0;
  color: #ffffff;
  padding: 8px 12px;
  border-radius: 8px;
  font-size: 11.5px;
  line-height: 1.35;
  box-shadow: 0 10px 18px -2px rgba(3, 82, 160, 0.35);
  pointer-events: none;
  z-index: 1070;
}

.tooltip-arrow-left {
  position: absolute;
  top: 10px;
  left: -5px;
  width: 0;
  height: 0;
  border-top: 5px solid transparent;
  border-bottom: 5px solid transparent;
  border-right: 5px solid #0352A0;
}

/* ─── Animations ─── */
.floating-slide-enter-active,
.floating-slide-leave-active {
  transition: all 0.22s cubic-bezier(0.16, 1, 0.3, 1);
}
.floating-slide-enter-from,
.floating-slide-leave-to {
  opacity: 0;
  transform: translate(-50%, 18px);
}

.popover-fade-enter-active,
.popover-fade-leave-active {
  transition: all 0.14s ease-out;
}
.popover-fade-enter-from,
.popover-fade-leave-to {
  opacity: 0;
  transform: translateY(6px);
}
</style>
