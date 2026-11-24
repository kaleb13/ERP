<script setup lang="ts">
import { ref, computed } from 'vue';
import qmtStarFilled from '../assets/qmt-star-filled.svg';
import qmtStarEmpty from '../assets/qmt-star-empty.svg';

interface Props {
  /** Rating value from 0 to 5 (supports 0.5 half-star increments) */
  modelValue?: number;
  /** Icon size in pixels (default 20px matching QMT Table cell / Style=Star ratings) */
  size?: number;
  /** Enables interactive hover preview & half-star click selection */
  interactive?: boolean;
  /** Allow 0.5 half-star selection */
  allowHalf?: boolean;
  /** Optional accessible label */
  ariaLabel?: string;
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: 0,
  size: 20,
  interactive: true,
  allowHalf: true,
  ariaLabel: 'Rating'
});

const emit = defineEmits<{
  (e: 'update:modelValue', value: number): void;
  (e: 'select', value: number): void;
}>();

const hoverValue = ref<number | null>(null);

const displayValue = computed(() =>
  hoverValue.value !== null ? hoverValue.value : props.modelValue
);

const getStarFillPercent = (starIndex: number): number => {
  const val = displayValue.value;
  if (val >= starIndex) return 100;
  if (val >= starIndex - 0.5) return 50;
  return 0;
};

const computeStarValue = (starIndex: number, event: MouseEvent): number => {
  if (!props.allowHalf) return starIndex;
  const target = event.currentTarget as HTMLElement | null;
  if (!target) return starIndex;
  const rect = target.getBoundingClientRect();
  const isLeftHalf = event.clientX - rect.left <= rect.width / 2;
  return isLeftHalf ? starIndex - 0.5 : starIndex;
};

const handleMouseMove = (starIndex: number, event: MouseEvent) => {
  if (!props.interactive) return;
  hoverValue.value = computeStarValue(starIndex, event);
};

const handleMouseLeave = () => {
  hoverValue.value = null;
};

const handleClick = (starIndex: number, event: MouseEvent) => {
  if (!props.interactive) return;
  const picked = computeStarValue(starIndex, event);
  emit('update:modelValue', picked);
  emit('select', picked);
};
</script>

<template>
  <div
    class="qmt-star-rating"
    :class="{ 'is-interactive': interactive }"
    :aria-label="ariaLabel"
    @mouseleave="handleMouseLeave"
  >
    <button
      v-for="n in 5"
      :key="n"
      type="button"
      class="qmt-star-slot"
      :style="{ width: `${size}px`, height: `${size}px` }"
      :disabled="!interactive"
      :aria-label="`Rate ${n} out of 5`"
      @mousemove="handleMouseMove(n, $event)"
      @click.stop="handleClick(n, $event)"
    >
      <img
        :src="qmtStarEmpty"
        alt=""
        :width="size"
        :height="size"
        class="qmt-star-layer qmt-star-base"
        draggable="false"
      />
      <span
        v-if="getStarFillPercent(n) > 0"
        class="qmt-star-fill-clip"
        :style="{ width: `${getStarFillPercent(n)}%`, height: `${size}px` }"
      >
        <img
          :src="qmtStarFilled"
          alt=""
          :width="size"
          :height="size"
          class="qmt-star-layer"
          draggable="false"
        />
      </span>
    </button>
  </div>
</template>

<style scoped>
.qmt-star-rating {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.qmt-star-slot {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  border: none;
  background: transparent;
  flex-shrink: 0;
  cursor: default;
  transition: transform 0.12s ease;
}

.qmt-star-rating.is-interactive .qmt-star-slot {
  cursor: pointer;
}

.qmt-star-rating.is-interactive .qmt-star-slot:hover {
  transform: scale(1.12);
}

.qmt-star-layer {
  display: block;
  pointer-events: none;
  user-select: none;
  max-width: none;
}

.qmt-star-fill-clip {
  position: absolute;
  top: 0;
  left: 0;
  overflow: hidden;
  pointer-events: none;
}
</style>
