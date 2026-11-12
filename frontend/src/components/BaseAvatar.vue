<script setup lang="ts">
import { computed, ref, type Component } from 'vue';
import { User } from 'lucide-vue-next';

interface Props {
  /** Image source URL */
  src?: string;
  /** Full name or string to derive uppercase initials from */
  name?: string;
  /** Direct text to display inside the avatar */
  text?: string;
  /** Custom icon component when no image or text is provided */
  icon?: Component;
  /** Avatar dimension: xs (24px), sm (32px), md (40px default), lg (48px), xl (56px), 2xl (64px) */
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl' | '2xl';
  /** Shape: circle (default) or rounded square */
  shape?: 'circle' | 'square';
  /** Status indicator: online (green), company (brand blue), busy (red), offline (gray) */
  status?: 'online' | 'company' | 'busy' | 'offline' | boolean;
  /** Optional alt text for image */
  alt?: string;
  /** Whether the avatar has hover/active interactive styling */
  interactive?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  size: 'md',
  shape: 'circle',
  status: false,
  interactive: false
});

const imageError = ref(false);

const handleImageError = () => {
  imageError.value = true;
};

// Calculate 1 or 2 letter uppercase initials
const initials = computed(() => {
  if (props.text) return props.text.trim().substring(0, 2).toUpperCase();
  if (!props.name) return '';
  const parts = props.name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '';
  if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
});

// Normalized status key
const normalizedStatus = computed(() => {
  if (props.status === true) return 'online';
  if (!props.status) return null;
  return props.status;
});
</script>

<template>
  <div 
    :class="[
      'qmt-avatar',
      `qmt-avatar--${size}`,
      `qmt-avatar--${shape}`,
      { 'qmt-avatar--interactive': interactive }
    ]"
    data-qmt-avatar="avatar"
  >
    <!-- Image Mode -->
    <img
      v-if="src && !imageError"
      :src="src"
      :alt="alt || name || 'Avatar'"
      class="qmt-avatar__image"
      @error="handleImageError"
    />

    <!-- Text / Initials Mode (Figma 3345:28681) -->
    <span 
      v-else-if="initials" 
      class="qmt-avatar__initials"
    >
      {{ initials }}
    </span>

    <!-- Icon Fallback Mode -->
    <div v-else class="qmt-avatar__icon-wrapper">
      <component 
        :is="icon || User" 
        :size="size === 'xs' ? 12 : size === 'sm' ? 16 : size === 'lg' ? 24 : size === 'xl' ? 28 : size === '2xl' ? 32 : 20" 
        class="qmt-avatar__icon"
      />
    </div>

    <!-- Status Indicator Dot (Figma 3345:28933 / 3345:1798) -->
    <span 
      v-if="normalizedStatus" 
      :class="[
        'qmt-avatar__status',
        `qmt-avatar__status--${normalizedStatus}`,
        `qmt-avatar__status--${size}`
      ]"
    />
  </div>
</template>

<style scoped>
/* QMT Avatar (Figma Node 3345:28608 / 3345:28681 / 3345:28933) */
.qmt-avatar {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background-color: var(--qmt-avatar-bg, #f1f7fe);
  color: var(--qmt-avatar-fg, #0b529c);
  font-family: var(--qmt-font-family-sans, 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif);
  font-weight: 600;
  user-select: none;
  flex-shrink: 0;
  box-sizing: border-box;
}

/* Shapes */
.qmt-avatar--circle {
  border-radius: var(--qmt-avatar-radius, 9999px);
}

.qmt-avatar--square {
  border-radius: 8px;
}

/* Sizes */
.qmt-avatar--xs {
  width: 24px;
  height: 24px;
  font-size: 11px;
}

.qmt-avatar--sm {
  width: 32px;
  height: 32px;
  font-size: 12px;
}

.qmt-avatar--md {
  width: 40px;
  height: 40px;
  font-size: 14px;
}

.qmt-avatar--lg {
  width: 48px;
  height: 48px;
  font-size: 16px;
}

.qmt-avatar--xl {
  width: 56px;
  height: 56px;
  font-size: 18px;
}

.qmt-avatar--2xl {
  width: 64px;
  height: 64px;
  font-size: 20px;
}

/* Image */
.qmt-avatar__image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: inherit;
  pointer-events: none;
}

/* Initials */
.qmt-avatar__initials {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  line-height: 1;
  text-align: center;
  letter-spacing: -0.02em;
}

/* Icon */
.qmt-avatar__icon-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
}

.qmt-avatar__icon {
  color: var(--qmt-avatar-fg, #0b529c);
}

/* Interactive hover */
.qmt-avatar--interactive {
  cursor: pointer;
  transition: opacity 0.15s ease, transform 0.15s ease;
}

.qmt-avatar--interactive:hover {
  opacity: 0.9;
  transform: translateY(-1px);
}

/* Status Indicator Dot (Figma 3345:1798) */
.qmt-avatar__status {
  position: absolute;
  bottom: 0;
  right: 0;
  border-radius: 9999px;
  border: 1.5px solid var(--qmt-avatar-border, #ffffff);
  box-sizing: border-box;
}

.qmt-avatar__status--xs {
  width: 7px;
  height: 7px;
}

.qmt-avatar__status--sm {
  width: 8px;
  height: 8px;
}

.qmt-avatar__status--md {
  width: 10px;
  height: 10px;
}

.qmt-avatar__status--lg {
  width: 12px;
  height: 12px;
  border-width: 2px;
}

.qmt-avatar__status--xl {
  width: 14px;
  height: 14px;
  border-width: 2px;
}

.qmt-avatar__status--2xl {
  width: 16px;
  height: 16px;
  border-width: 2px;
}

/* Status Colors */
.qmt-avatar__status--online {
  background-color: var(--qmt-avatar-status-online, #12b76a);
}

.qmt-avatar__status--company {
  background-color: var(--qmt-avatar-status-company, #0b529c);
}

.qmt-avatar__status--busy {
  background-color: var(--qmt-avatar-status-busy, #e7000b);
}

.qmt-avatar__status--offline {
  background-color: var(--qmt-avatar-status-offline, #a1a1a1);
}
</style>
