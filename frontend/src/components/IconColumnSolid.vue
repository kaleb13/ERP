<script setup lang="ts">
interface Props {
  size?: number | string;
  class?: string;
}

const props = withDefaults(defineProps<Props>(), {
  size: 16,
  class: ''
});
</script>

<template>
  <svg
    :width="props.size"
    :height="props.size"
    viewBox="0 0 20 20"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    :class="['column-solid-svg', props.class]"
  >
    <path
      d="M12.5 3.33333H7.5V16.6667H12.5V3.33333ZM14.1667 16.6667H16.6667C17.1087 16.6667 17.5326 16.4911 17.8452 16.1785C18.1577 15.8659 18.3333 15.442 18.3333 15V5C18.3333 4.55797 18.1577 4.13405 17.8452 3.82149C17.5326 3.50893 17.1087 3.33333 16.6667 3.33333H14.1667V16.6667ZM3.33333 3.33333H5.83333V16.6667H3.33333C2.89131 16.6667 2.46738 16.4911 2.15482 16.1785C1.84226 15.8659 1.66667 15.442 1.66667 15V5C1.66667 4.55797 1.84226 4.13405 2.15482 3.82149C2.46738 3.50893 2.89131 3.33333 3.33333 3.33333Z"
      fill="currentColor"
      fill-rule="evenodd"
      clip-rule="evenodd"
    />
  </svg>
</template>

<style scoped>
.column-solid-svg {
  display: block;
  flex-shrink: 0;
}
</style>
