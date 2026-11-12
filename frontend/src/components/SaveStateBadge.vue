<script setup lang="ts">
import { computed } from 'vue';
import BaseBadge, { type BadgeColor } from './BaseBadge.vue';

const props = withDefaults(defineProps<{
  isSaved?: boolean;
  saved?: boolean;
  isDraft?: boolean;
  state?: string;
  label?: string;
  dot?: boolean;
}>(), {
  isSaved: false,
  saved: undefined,
  isDraft: false,
  state: '',
  label: '',
  dot: false
});

const resolvedIsSaved = computed(() => (props.saved !== undefined ? props.saved : props.isSaved));

const computedState = computed(() => {
  if (props.state) {
    if (props.state === 'new_unsaved' || props.state === 'draft_modified' || props.state === 'unsaved') return 'unsaved';
    if (props.state === 'draft') return 'draft';
    if (props.state === 'approved' || props.state === 'saved') return 'saved';
    return props.state;
  }
  if (!resolvedIsSaved.value) return 'unsaved';
  return props.isDraft ? 'draft' : 'saved';
});

const badgeColor = computed<BadgeColor>(() => {
  if (computedState.value === 'unsaved') return 'warning';
  if (computedState.value === 'saved') return 'success';
  if (computedState.value === 'draft') return 'primary';
  return 'gray';
});

const displayLabel = computed(() => {
  if (props.label) return props.label;
  if (computedState.value === 'unsaved') return 'Not Saved';
  if (computedState.value === 'draft') return resolvedIsSaved.value ? 'Draft Saved' : 'Draft';
  if (computedState.value === 'saved') return props.state === 'approved' ? 'Approved' : 'Saved';
  return computedState.value;
});
</script>

<template>
  <BaseBadge
    class="save-state-badge"
    :class="`state-${computedState}`"
    type="pill-color"
    :color="badgeColor"
    :dot="dot"
    size="sm"
  >
    {{ displayLabel }}
  </BaseBadge>
</template>

<style scoped>
.save-state-badge {
  margin: 0;
  display: inline-flex;
  vertical-align: middle;
}
</style>
