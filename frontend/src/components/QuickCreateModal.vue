<script setup lang="ts">
import { onMounted, onUnmounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { X, Maximize2, Check, Loader2 } from 'lucide-vue-next';

interface Props {
  /** Controls modal visibility (use with v-model:show or v-model). */
  show: boolean;
  /** Modal header title (e.g. 'Create Customer', 'Quick Add Position'). */
  title: string;
  /** Target route when "Expand Full Form" is clicked (optional if @expand is handled). */
  expandRoute?: string | object;
  /** Custom label for the bottom-left expand action. */
  expandLabel?: string;
  /** Whether to show the bottom-left "Expand Full Form" button. Default is true. */
  showExpandButton?: boolean;
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
  expandRoute: undefined,
  expandLabel: 'Expand Full Form',
  showExpandButton: true,
  saveLabel: 'Save',
  cancelLabel: 'Cancel',
  loading: false,
  disabled: false,
  width: 'md'
});

const emit = defineEmits<{
  (e: 'update:show', value: boolean): void;
  (e: 'save'): void;
  (e: 'cancel'): void;
  (e: 'expand'): void;
}>();

const router = useRouter();

const handleClose = () => {
  emit('update:show', false);
  emit('cancel');
};

const handleExpand = () => {
  emit('expand');
  emit('update:show', false);
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
    <Transition name="modal-fade">
      <div 
        v-if="show" 
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

          <!-- MODAL FOOTER (Bottom-Left: Secondary Button Expand Full Form | Bottom-Right: Primary Save) -->
          <div class="quick-modal-footer">
            <!-- Bottom-Left: Secondary Button (Expand Full Form) -->
            <div class="footer-left">
              <button 
                v-if="showExpandButton" 
                type="button" 
                class="btn-secondary-action" 
                @click="handleExpand"
              >
                <Maximize2 :size="13" />
                <span>{{ expandLabel }}</span>
              </button>
            </div>

            <!-- Bottom-Right: Primary Button (Save) -->
            <div class="footer-right">
              <button 
                type="button" 
                class="btn-primary-action" 
                :disabled="disabled || loading"
                @click="$emit('save')"
              >
                <Loader2 v-if="loading" :size="14" class="animate-spin" />
                <Check v-else :size="14" stroke-width="2.5" />
                <span>{{ saveLabel }}</span>
              </button>
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
  background-color: #ffffff;
  border-radius: 16px;
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
  padding: 24px 24px 8px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
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
  color: #94a3b8;
  cursor: pointer;
  padding: 6px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
  margin-top: -2px;
  margin-right: -4px;
}

.btn-close-modal:hover {
  color: #0f172a;
  background-color: #f1f5f9;
}

/* BODY */
.quick-modal-body {
  padding: 20px 24px;
  overflow-y: auto;
  flex: 1;
}

/* FOOTER */
.quick-modal-footer {
  padding: 14px 24px;
  border-top: 1px solid #f1f5f9;
  background-color: #fafafa;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.footer-left {
  display: flex;
  align-items: center;
}

.footer-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* BOTTOM-LEFT: SECONDARY ACTION BUTTON (EXPAND FULL FORM - WELL ROUNDED RECTANGLE) */
.btn-secondary-action {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  height: 36px;
  padding: 0 14px;
  border-radius: 8px;
  background-color: #ffffff;
  color: #334155;
  border: 1px solid #e2e8f0;
  font-size: 13px;
  font-weight: 550;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
  transition: all 0.15s ease;
}

.btn-secondary-action:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
  color: #0f172a;
}

.btn-secondary-action:active {
  background-color: #f1f5f9;
}

/* BOTTOM-RIGHT: PRIMARY ACTION BUTTON (SAVE - WELL ROUNDED RECTANGLE) */
.btn-primary-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 18px;
  border-radius: 8px;
  border: none;
  background-color: #0B529C;
  color: #ffffff;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(11, 82, 156, 0.15);
  transition: all 0.15s ease;
}

.btn-primary-action:hover:not(:disabled) {
  background-color: #09427D;
  box-shadow: 0 3px 6px rgba(11, 82, 156, 0.25);
  transform: translateY(-0.5px);
}

.btn-primary-action:active:not(:disabled) {
  transform: translateY(0);
}

.btn-primary-action:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
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
