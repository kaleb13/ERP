<script setup lang="ts">
import { computed, onMounted, onUnmounted, watch } from 'vue';
import { X, ArrowDown, ArrowUp, Copy, Plus } from 'lucide-vue-next';

interface Props {
  /** Controls modal visibility. Supports v-model:show or :show */
  show: boolean;
  /** Primary entity / action name (e.g. 'Create Item', 'Edit Schedule Day') */
  title: string;
  /** 0-based index of the currently active row */
  rowIndex: number;
  /** Total count of rows */
  totalRows?: number;
  /** Whether the row can be deleted */
  canDelete?: boolean;
  /** Can navigate to next row (down) */
  canNavigateDown?: boolean;
  /** Can navigate to previous row (up) */
  canNavigateUp?: boolean;
  /** Whether duplicate row action is allowed */
  canDuplicate?: boolean;
  /** Whether insert above action is allowed */
  canInsertAbove?: boolean;
  /** Whether insert below action is allowed */
  canInsertBelow?: boolean;
  /** Maximum modal card width (default '860px') */
  maxWidth?: string;
}

const props = withDefaults(defineProps<Props>(), {
  totalRows: 1,
  canDelete: true,
  canNavigateDown: false,
  canNavigateUp: false,
  canDuplicate: true,
  canInsertAbove: true,
  canInsertBelow: true,
  maxWidth: '860px'
});

const emit = defineEmits<{
  (e: 'update:show', value: boolean): void;
  (e: 'close'): void;
  (e: 'delete'): void;
  (e: 'navigateDown'): void;
  (e: 'navigateUp'): void;
  (e: 'duplicate'): void;
  (e: 'insertAbove'): void;
  (e: 'insertBelow'): void;
}>();

const handleClose = () => {
  emit('update:show', false);
  emit('close');
};

const handleBackdropClick = (e: MouseEvent) => {
  if (e.target === e.currentTarget) {
    handleClose();
  }
};

const handleKeydown = (e: KeyboardEvent) => {
  if (e.key === 'Escape' && props.show) {
    handleClose();
  }
};

onMounted(() => {
  window.addEventListener('keydown', handleKeydown);
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown);
});

// Lock body scroll when modal is open
watch(
  () => props.show,
  (isOpen) => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
  }
);
</script>

<template>
  <Teleport to="body">
    <Transition name="dynamic-modal-fade">
      <div
        v-if="show"
        class="dynamic-modal-backdrop"
        @click="handleBackdropClick"
        role="dialog"
        aria-modal="true"
      >
        <div
          class="dynamic-modal-card"
          :style="{ maxWidth }"
          @click.stop
        >
          <!-- ─── HEADER (Figma 6095:96371) ─── -->
          <div class="dynamic-modal-header">
            <div class="dynamic-modal-title-wrap">
              <span class="dynamic-modal-title-main">{{ title }}</span>
              <span class="dynamic-modal-title-row">(Row {{ rowIndex + 1 }})</span>
            </div>
            <button
              type="button"
              class="btn-modal-close"
              title="Close (Esc)"
              @click="handleClose"
            >
              <X :size="18" />
            </button>
          </div>

          <!-- ─── BODY (Figma 6095:96375) ─── -->
          <div class="dynamic-modal-body">
            <slot />
          </div>

          <!-- ─── FOOTER (Figma 6095:96395) ─── -->
          <div class="dynamic-modal-footer">
            <!-- Left: Red Destructive Delete Action -->
            <div class="footer-left">
              <button
                v-if="canDelete"
                type="button"
                class="btn-error-delete"
                @click="$emit('delete')"
              >
                Delete
              </button>
            </div>

            <!-- Right: Action Buttons Group (↓, ↑, Duplicate Row, Insert Above, Insert Below) -->
            <div class="footer-right">
              <!-- Used to Navigate Down (Next Row) -->
              <button
                type="button"
                class="btn-secondary-nav-arrow"
                :disabled="!canNavigateDown"
                title="Next Row (Down)"
                @click="$emit('navigateDown')"
              >
                <ArrowDown :size="20" />
              </button>

              <!-- Used to Navigate Up (Previous Row) -->
              <button
                type="button"
                class="btn-secondary-nav-arrow"
                :disabled="!canNavigateUp"
                title="Previous Row (Up)"
                @click="$emit('navigateUp')"
              >
                <ArrowUp :size="20" />
              </button>

              <!-- Duplicate Row -->
              <button
                v-if="canDuplicate"
                type="button"
                class="btn-secondary-action"
                title="Duplicate Current Row"
                @click="$emit('duplicate')"
              >
                <Copy :size="18" />
                <span>Duplicate Row</span>
              </button>

              <!-- Insert Above -->
              <button
                v-if="canInsertAbove"
                type="button"
                class="btn-secondary-action"
                title="Insert Blank Row Above"
                @click="$emit('insertAbove')"
              >
                <Plus :size="18" />
                <span>Insert Above</span>
              </button>

              <!-- Insert Below -->
              <button
                v-if="canInsertBelow"
                type="button"
                class="btn-secondary-action"
                title="Insert Blank Row Below"
                @click="$emit('insertBelow')"
              >
                <Plus :size="18" />
                <span>Insert Below</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
/* ─── Backdrop ─── */
.dynamic-modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(3px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
  z-index: 9999;
  user-select: none;
}

/* ─── Modal Card Container (Figma 6095:96370) ─── */
.dynamic-modal-card {
  background-color: #ffffff;
  border-radius: 16px;
  border: 1px solid #d4d4d4;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  display: flex;
  flex-direction: column;
  width: 100%;
  max-height: calc(100vh - 48px);
  overflow: hidden;
  animation: dynamicModalPop 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes dynamicModalPop {
  from {
    opacity: 0;
    transform: scale(0.97) translateY(6px);
  }
  to {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

/* ─── Header (Figma 6095:96371) ─── */
.dynamic-modal-header {
  padding: 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: #ffffff;
  flex-shrink: 0;
}

.dynamic-modal-title-wrap {
  display: flex;
  align-items: baseline;
  gap: 8px;
  min-width: 0;
}

.dynamic-modal-title-main {
  font-size: 20px;
  font-weight: 600;
  color: #262626;
  line-height: 28px;
}

.dynamic-modal-title-row {
  font-size: 20px;
  font-weight: 600;
  color: #737373;
  line-height: 28px;
}

.btn-modal-close {
  width: 32px;
  height: 32px;
  border-radius: 9999px;
  background-color: #ffffff;
  border: 1px solid #e5e5e5;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #737373;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-modal-close:hover {
  background-color: #f5f5f5;
  color: #404040;
  border-color: #d4d4d4;
}

/* ─── Body (Figma 6095:96375) ─── */
.dynamic-modal-body {
  padding: 0 24px 24px 24px;
  background-color: #ffffff;
  overflow-y: auto;
  max-height: calc(100vh - 220px);
  flex-grow: 1;
}

/* ─── Footer (Figma 6095:96395) ─── */
.dynamic-modal-footer {
  height: 74px;
  background-color: #fafafa;
  border-top: 1px solid #e5e7eb;
  padding: 0 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-shrink: 0;
}

.footer-left {
  display: flex;
  align-items: center;
}

.btn-error-delete {
  background-color: #fb2c36;
  border: 1px solid #fb2c36;
  color: #ffffff;
  font-size: 15px;
  font-weight: 600;
  padding: 10px 18px;
  border-radius: 8px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 1px 2px 0 rgba(10, 13, 18, 0.05);
  transition: background-color 0.15s, border-color 0.15s;
  user-select: none;
}

.btn-error-delete:hover {
  background-color: #dc2626;
  border-color: #dc2626;
}

.footer-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.btn-secondary-nav-arrow {
  width: 44px;
  height: 44px;
  background-color: #ffffff;
  border: 1px solid #d9d9d9;
  border-radius: 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #404040;
  cursor: pointer;
  box-shadow: 0 1px 2px 0 rgba(10, 13, 18, 0.05);
  transition: all 0.15s ease;
  user-select: none;
}

.btn-secondary-nav-arrow:hover:not(:disabled) {
  background-color: #f5f5f5;
  border-color: #bfbfbf;
}

.btn-secondary-nav-arrow:disabled {
  opacity: 0.35;
  cursor: not-allowed;
  background-color: #fafafa;
}

.btn-secondary-action {
  height: 44px;
  padding: 0 18px;
  background-color: #ffffff;
  border: 1px solid #d9d9d9;
  border-radius: 8px;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #404040;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 1px 2px 0 rgba(10, 13, 18, 0.05);
  transition: all 0.15s ease;
  white-space: nowrap;
  user-select: none;
}

.btn-secondary-action:hover {
  background-color: #f5f5f5;
  border-color: #bfbfbf;
}

/* ─── Transition ─── */
.dynamic-modal-fade-enter-active,
.dynamic-modal-fade-leave-active {
  transition: opacity 0.2s ease;
}

.dynamic-modal-fade-enter-from,
.dynamic-modal-fade-leave-to {
  opacity: 0;
}
</style>
