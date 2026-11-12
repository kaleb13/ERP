<script setup lang="ts">
import BaseNavItem, { type BaseNavItemProps } from './BaseNavItem.vue';

const props = defineProps<BaseNavItemProps>();
const emit = defineEmits<{
  (e: 'click', event: MouseEvent): void;
}>();
</script>

<template>
  <BaseNavItem v-bind="props" @click="(e) => emit('click', e)">
    <template v-for="(_, slotName) in $slots" #[slotName]="slotProps">
      <slot :name="slotName" v-bind="slotProps" />
    </template>
  </BaseNavItem>
</template>
