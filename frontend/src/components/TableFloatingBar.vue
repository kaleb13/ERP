<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue';
import { 
  Copy, Pencil, Trash2, RotateCw, MoreVertical, 
  CheckCircle2, XCircle, Clock, Lock, History, 
  Download, ToggleLeft, X
} from 'lucide-vue-next';

interface Props {
  show?: boolean;
  selectedCount: number;
  totalCount?: number;
  showChangeStatus?: boolean;
  showDuplicate?: boolean;
  showEdit?: boolean;
  showDelete?: boolean;
  showMore?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  show: false,
  selectedCount: 0,
  totalCount: 0,
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
}>();

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
    <div v-if="props.show && props.selectedCount > 0" class="floating-action-bar-wrap">
      <div class="floating-action-bar" @click.stop>
        <!-- Drag Handle (6 dots) -->
        <div class="floating-grip" title="Bulk Action Bar">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor" class="grip-icon">
            <circle cx="8" cy="5" r="1.8" />
            <circle cx="16" cy="5" r="1.8" />
            <circle cx="8" cy="12" r="1.8" />
            <circle cx="16" cy="12" r="1.8" />
            <circle cx="8" cy="19" r="1.8" />
            <circle cx="16" cy="19" r="1.8" />
          </svg>
        </div>

        <div class="floating-sep" />

        <!-- Count & Select All Option -->
        <div class="floating-count-info">
          <span class="count-bold">{{ props.selectedCount }} Selected</span>
          <span v-if="props.totalCount && props.totalCount > props.selectedCount" class="count-divider">•</span>
          <button 
            v-if="props.totalCount && props.totalCount > props.selectedCount" 
            type="button" 
            class="count-select-all" 
            @click="$emit('selectAll')"
          >
            Select all {{ props.totalCount }}
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
                  <CheckCircle2 :size="15" class="text-emerald-500 flex-shrink-0" />
                  <span>Approve</span>
                </button>
                <button type="button" class="popover-item text-neutral-800" @click="handleSelectStatus('Rejected')">
                  <XCircle :size="15" class="text-rose-500 flex-shrink-0" />
                  <span>Reject</span>
                </button>
                <button type="button" class="popover-item text-neutral-800" @click="handleSelectStatus('Pending')">
                  <Clock :size="15" class="text-amber-500 flex-shrink-0" />
                  <span>Pending</span>
                </button>
                <button type="button" class="popover-item text-neutral-800" @click="handleSelectStatus('Locked')">
                  <Lock :size="15" class="text-slate-400 flex-shrink-0" />
                  <span>Locked</span>
                </button>
                <button type="button" class="popover-item text-neutral-800" @click="handleSelectStatus('Expired')">
                  <History :size="15" class="text-slate-400 flex-shrink-0" />
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
            <Copy :size="14" class="text-neutral-600" />
            <span>Duplicate</span>
          </button>

          <!-- 3. Edit -->
          <button 
            v-if="props.showEdit" 
            type="button" 
            class="floating-btn" 
            @click="$emit('edit')"
          >
            <Pencil :size="14" class="text-neutral-600" />
            <span>Edit</span>
          </button>

          <!-- 4. Delete (Red) -->
          <button 
            v-if="props.showDelete" 
            type="button" 
            class="floating-btn btn-delete" 
            @click="$emit('delete')"
          >
            <Trash2 :size="14" class="text-rose-600" />
            <span class="text-rose-600 font-medium">Delete</span>
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
              <MoreVertical :size="15" />
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
                  <Download :size="15" class="text-neutral-600 flex-shrink-0" />
                  <span>Export</span>
                </button>
                <button type="button" class="popover-item text-neutral-800" @click="handleDeactivate">
                  <ToggleLeft :size="15" class="text-neutral-600 flex-shrink-0" />
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
          @click="$emit('close')" 
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
  gap: 12px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 9999px;
  box-shadow: 0 14px 34px -4px rgba(0, 0, 0, 0.12), 0 4px 12px -2px rgba(0, 0, 0, 0.06);
  padding: 6px 14px 6px 16px;
  height: 46px;
  user-select: none;
}

.floating-grip {
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: grab;
  color: #64748b;
  padding: 2px;
}

.grip-icon {
  color: #475569;
}

.floating-sep {
  width: 1px;
  height: 18px;
  background-color: #e2e8f0;
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
  color: #334155;
}

.count-divider {
  color: #94a3b8;
  font-size: 11px;
}

.count-select-all {
  background: transparent;
  border: none;
  padding: 0;
  color: #475569;
  font-size: 13px;
  font-weight: 500;
  text-decoration: underline;
  cursor: pointer;
  transition: color 0.15s ease;
}
.count-select-all:hover {
  color: #0B529C;
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
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
  white-space: nowrap;
}
.floating-btn:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.status-pill-btn {
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
  padding: 0 12px;
}
.status-pill-btn:hover,
.status-pill-btn.is-active {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.status-btn-icon {
  color: #64748b;
}

.btn-delete:hover {
  background-color: #fee2e2;
}

.floating-btn-icon {
  width: 32px;
  height: 32px;
  border-radius: 9999px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: 1px solid #e2e8f0;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s ease;
}
.floating-btn-icon:hover,
.floating-btn-icon.is-active {
  background-color: #f1f5f9;
  color: #0f172a;
  border-color: #cbd5e1;
}

.floating-close-btn {
  width: 22px;
  height: 22px;
  border-radius: 9999px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f1f5f9;
  border: none;
  color: #64748b;
  cursor: pointer;
  margin-left: 2px;
  transition: all 0.15s ease;
}
.floating-close-btn:hover {
  background-color: #e2e8f0;
  color: #0f172a;
}

/* ─── Floating Popover Menus (Image 2) ─── */
.floating-popover-menu {
  position: absolute;
  bottom: calc(100% + 12px);
  background-color: #ffffff;
  border: 1px solid #e5e7eb;
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
  background-color: #f8fafc;
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
