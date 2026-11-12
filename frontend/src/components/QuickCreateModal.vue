<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { X, Maximize2 } from 'lucide-vue-next';
import BaseButton from './BaseButton.vue';

interface Props {
  /** Controls modal visibility (use with v-model:show or v-model). */
  show?: boolean;
  /** Backwards compatibility alias for show. */
  isOpen?: boolean;
  /** Modal header title (e.g. 'Create Customer', 'Quick Add Position'). */
  title: string;
  /** Target route when "Expand Full Form" is clicked (optional if @expand is handled). */
  expandRoute?: string | object;
  /** Custom label for the bottom-left expand action. */
  expandLabel?: string;
  /** Whether to show the bottom-left "Expand Full Form" button. Default is true. */
  showExpandButton?: boolean;
  /** Backwards compatibility alias for showExpandButton. */
  showExpand?: boolean;
  /** Save button label. Default is 'Save'. */
  saveLabel?: string;
  /** Cancel button label. Default is 'Cancel'. */
  cancelLabel?: string;
  /** Disables the save button and displays a spinner if loading. */
  loading?: boolean;
  /** Disables the save button. */
  disabled?: boolean;
  /** Modal width size: 'sm' (480px), 'md' (580px, default), 'lg' (720px). */
  width?: 'sm' | 'md' | 'lg';
}

const props = withDefaults(defineProps<Props>(), {
  show: undefined,
  isOpen: undefined,
  expandRoute: undefined,
  expandLabel: 'Expand Full Form',
  showExpandButton: true,
  showExpand: undefined,
  saveLabel: 'Save',
  cancelLabel: 'Cancel',
  loading: false,
  disabled: false,
  width: 'md'
});

const isModalVisible = computed(() => {
  if (props.show !== undefined) return props.show;
  if (props.isOpen !== undefined) return props.isOpen;
  return false;
});

const isExpandVisible = computed(() => {
  if (props.showExpand !== undefined) return props.showExpand;
  return props.showExpandButton;
});

const emit = defineEmits<{
  (e: 'update:show', value: boolean): void;
  (e: 'update:isOpen', value: boolean): void;
  (e: 'save'): void;
  (e: 'cancel'): void;
  (e: 'close'): void;
  (e: 'expand'): void;
}>();

const router = useRouter();
const handleClose = () => {
  emit('update:show', false);
  emit('update:isOpen', false);
  emit('cancel');
  emit('close');
};

const handleExpand = () => {
  emit('expand');
  emit('update:show', false);
  emit('update:isOpen', false);
  if (props.expandRoute) {
    router.push(props.expandRoute);
  }
};

const handleBackdropClick = (e: MouseEvent) => {
  if (e.target === e.currentTarget) {
    handleClose();
  }
};

const handleKeydown = (e: KeyboardEvent) => {
  if (e.key === 'Escape' && isModalVisible.value) {
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
  isModalVisible,
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
    <Transition name="modal-fade">
      <div 
        v-if="isModalVisible" 
        class="quick-modal-backdrop" 
        @click="handleBackdropClick"
      >
        <div 
          class="quick-modal-card" 
          :class="`quick-modal-card--${width}`"
          role="dialog"
          aria-modal="true"
        >
          <!-- MODAL HEADER (Title only, no subtitle, no bottom line) -->
          <div class="quick-modal-header">
            <h3 class="quick-modal-title">{{ title }}</h3>
            <button 
              type="button" 
              class="btn-close-modal" 
              title="Close (Esc)" 
              @click="handleClose"
            >
              <X :size="18" />
            </button>
          </div>

          <!-- MODAL FORM BODY (Max 5 Essential Fields) -->
          <div class="quick-modal-body">
            <slot />
          </div>

          <!-- MODAL FOOTER (Bottom-Left: Secondary Actions | Bottom-Right: Primary Save) -->
          <div class="quick-modal-footer">
            <!-- Bottom-Left: Secondary Button (Expand Full Form) -->
            <div class="footer-left">
              <slot name="footer-left">
                <BaseButton
                  v-if="isExpandVisible"
                  variant="secondary-gray"
                  size="sm"
                  @click="handleExpand"
                >
                  <template #icon-left>
                    <Maximize2 :size="14" />
                  </template>
                  {{ expandLabel }}
                </BaseButton>
              </slot>
            </div>

            <!-- Bottom-Right: Primary Button (Save - Strictly Plain Text, Zero Icons) -->
            <div class="footer-right">
              <BaseButton
                variant="primary"
                size="sm"
                :loading="loading"
                :disabled="disabled"
                @click="$emit('save')"
              >
                {{ saveLabel }}
              </BaseButton>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
/* BACKDROP */
.quick-modal-backdrop {
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

/* MODAL CARD CONTAINER */
.quick-modal-card {
  background-color: var(--alias-color-background-surface-elevated, #ffffff);
  border-radius: var(--alias-radius-2xl, 16px);
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04), 0 0 0 1px rgba(0, 0, 0, 0.05);
  display: flex;
  flex-direction: column;
  max-height: calc(100vh - 40px);
  width: 100%;
  overflow: hidden;
  animation: modalPop 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

.quick-modal-card--sm { max-width: 480px; }
.quick-modal-card--md { max-width: 580px; }
.quick-modal-card--lg { max-width: 720px; }

/* HEADER - Title only, no bottom line, seamless transition */
.quick-modal-header {
  padding: var(--alias-spacing-3xl, 24px) var(--alias-spacing-3xl, 24px) var(--alias-spacing-md, 8px) var(--alias-spacing-3xl, 24px);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--alias-spacing-xl, 16px);
}

.quick-modal-title {
  font-size: 18px;
  font-weight: 600;
  color: #404040;
  letter-spacing: -0.01em;
  margin: 0;
  line-height: 1.25;
}

.btn-close-modal {
  background: none;
  border: none;
  color: var(--alias-color-text-tertiary, #737373);
  cursor: pointer;
  padding: var(--alias-spacing-sm, 6px);
  border-radius: var(--alias-radius-lg, 8px);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
  margin-top: -2px;
  margin-right: -4px;
}

.btn-close-modal:hover {
  color: var(--alias-color-text-secondary, #404040);
  background-color: var(--alias-color-bg-secondary, #f5f5f5);
}

/* BODY */
.quick-modal-body {
  padding: var(--alias-spacing-2xl, 20px) var(--alias-spacing-3xl, 24px);
  overflow-y: auto;
  flex: 1;
}

/* FOOTER */
.quick-modal-footer {
  padding: var(--alias-spacing-xl, 16px) var(--alias-spacing-3xl, 24px);
  border-top: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  background-color: var(--alias-color-bg-primary, #fafafa);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--alias-spacing-xl, 16px);
}

.footer-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.quick-draft-menu-wrapper {
  position: relative;
  display: inline-flex;
}

.btn-quick-more {
  width: 32px;
  height: 32px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #404040;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-quick-more:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}

.quick-draft-dropdown {
  position: absolute;
  bottom: calc(100% + 6px);
  left: 0;
  min-width: 160px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08);
  padding: 4px 0;
  z-index: 60;
  animation: fadeIn 0.12s ease-in-out;
}

.quick-draft-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border: none;
  background: transparent;
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  cursor: pointer;
  text-align: left;
  transition: background-color 0.1s ease;
}
.quick-draft-item:hover {
  background-color: #f8fafc;
  color: #0B529C;
}

.quick-draft-icon {
  color: #64748b;
}
.quick-draft-item:hover .quick-draft-icon {
  color: #0B529C;
}

.footer-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* ANIMATIONS */
@keyframes modalPop {
  from {
    opacity: 0;
    transform: scale(0.96) translateY(6px);
  }
  to {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.15s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}
</style>
