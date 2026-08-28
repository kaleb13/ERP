<script setup lang="ts">
import BaseButton from './BaseButton.vue';

interface Props {
  variant?: 'primary' | 'secondary' | 'outline' | 'icon' | 'destructive' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  active?: boolean;
  disabled?: boolean;
  type?: 'button' | 'submit' | 'reset';
  title?: string;
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  active: false,
  disabled: false,
  type: 'button',
  title: undefined
});

const emit = defineEmits<{
  (e: 'click', event: MouseEvent): void;
}>();
</script>

<template>
  <BaseButton
    :variant="props.variant"
    :size="props.size"
    :active="props.active"
    :disabled="props.disabled"
    :type="props.type"
    :title="props.title"
    @click="(e) => emit('click', e)"
  >
    <template #icon-left><slot name="icon-left" /></template>
    <slot />
    <template #icon-right><slot name="icon-right" /></template>
  </BaseButton>
</template>
