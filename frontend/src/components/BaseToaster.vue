<script setup lang="ts">
import BaseToast from './BaseToast.vue';
import { useToast } from '../composables/useToast';

const { toasts, dismissToast } = useToast();
</script>

<template>
  <Teleport to="body">
    <div v-if="toasts.length" class="qmt-toaster" aria-label="Notifications">
      <TransitionGroup name="qmt-toast-slide">
        <BaseToast
          v-for="item in toasts"
          :key="item.id"
          :type="item.type"
          :status="item.status"
          :title="item.title"
          :description="item.description"
          :showClose="item.showClose"
          :actionLabel="item.actionLabel"
          :cancelLabel="item.cancelLabel"
          @close="dismissToast(item.id)"
          @action="() => { item.onAction?.(); dismissToast(item.id); }"
          @cancel="() => { item.onCancel?.(); dismissToast(item.id); }"
        />
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<style scoped>
.qmt-toaster {
  position: fixed;
  top: 20px;
  right: 20px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: 10px;
  pointer-events: none;
}

.qmt-toaster > :deep(*) {
  pointer-events: auto;
}

.qmt-toast-slide-enter-active,
.qmt-toast-slide-leave-active {
  transition: all 0.2s ease;
}

.qmt-toast-slide-enter-from,
.qmt-toast-slide-leave-to {
  opacity: 0;
  transform: translateX(16px);
}
</style>
