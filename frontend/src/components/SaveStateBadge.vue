<script setup lang="ts">
import { computed } from 'vue';

const props = withDefaults(defineProps<{
  isSaved?: boolean;
  isDraft?: boolean;
  state?: string;
  label?: string;
}>(), {
  isSaved: false,
  isDraft: false,
  state: '',
  label: ''
});

const computedState = computed(() => {
  if (props.state) {
    if (props.state === 'new_unsaved' || props.state === 'draft_modified' || props.state === 'unsaved') return 'unsaved';
    if (props.state === 'draft') return 'draft';
    if (props.state === 'approved' || props.state === 'saved') return 'saved';
    return props.state;
  }
  if (!props.isSaved) return 'unsaved';
  return props.isDraft ? 'draft' : 'saved';
});

const displayLabel = computed(() => {
  if (props.label) return props.label;
  if (computedState.value === 'unsaved') return 'Not Saved';
  if (computedState.value === 'draft') return props.isSaved ? 'Draft Saved' : 'Draft';
  if (computedState.value === 'saved') return 'Saved';
  return computedState.value;
});
</script>

<template>
  <span 
    class="save-state-badge"
    :class="`state-${computedState}`"
  >
    {{ displayLabel }}
  </span>
</template>

<style scoped>
.save-state-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-left: 10px;
  padding: 2.5px 11px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
  line-height: 1.2;
  border: none;
  white-space: nowrap;
  vertical-align: middle;
}

/* Not Saved: exact user specification #FEF3C6 bg, #BB4D00 text, no border */
.save-state-badge.state-unsaved {
  background-color: #FEF3C6;
  color: #BB4D00;
}

/* Saved: clean positive green */
.save-state-badge.state-saved {
  background-color: #ecfdf5;
  color: #059669;
}

/* Draft */
.save-state-badge.state-draft {
  background-color: #eff6ff;
  color: #1d4ed8;
}
</style>
