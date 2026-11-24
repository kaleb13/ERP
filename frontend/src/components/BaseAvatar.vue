<!--
  Authoritative QMT BaseAvatar Component (Figma 3345:28608)
  =============================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Primary single-user avatar across the entire system: Top navigation profile header,
    employee dossier cards, comment authors, single assignee cells, and directory lead cells.
  - Automatically derives 1 or 2 letter uppercase initials when no photo `src` is present.
  - Supports status dot indicators (`online`, `company`, `busy`, `offline`).

  WHEN NOT TO USE:
  - DO NOT use for groups, committees, or multi-user rosters (use `AvatarGroup.vue` instead).
  - DO NOT use bare `<img>` tags or raw unstyled circular divs for avatars.
-->
<script setup lang="ts">
import { computed, ref, type Component } from 'vue';
import { User } from 'lucide-vue-next';
import defaultCompanyBadge from '../assets/qmt-company-badge.jpg';

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
  /** Status indicator (QMT 3345:28608): online (green dot), company (sub-logo image), verified (brand Rosette tick 5230:397), busy (red), offline (gray) */
  status?: 'online' | 'company' | 'verified' | 'busy' | 'offline' | boolean;
  /** Optional sub-logo image URL for status="company" (QMT _Avatar company icon 3345:28940) */
  companyLogo?: string;
  /** Optional subtle outline ring (QMT 3345:28608) */
  bordered?: boolean;
  /** Optional alt text for image */
  alt?: string;
  /** Whether the avatar has hover/active interactive styling */
  interactive?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  size: 'md',
  shape: 'circle',
  status: false,
  companyLogo: undefined,
  bordered: false,
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
      {
        'qmt-avatar--interactive': interactive,
        'qmt-avatar--bordered': bordered
      }
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

    <!-- QMT Verified Rosette Tick (Figma 5230:397 exact SVG) -->
    <span
      v-if="normalizedStatus === 'verified'"
      :class="['qmt-avatar__verified', `qmt-avatar__verified--${size}`]"
      aria-hidden="true"
    >
      <svg viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg" class="qmt-avatar__verified-svg">
        <path
          d="M2.24582 5.02831C2.16068 4.64478 2.17375 4.24597 2.28383 3.86884C2.39391 3.49171 2.59743 3.14849 2.87551 2.87098C3.1536 2.59347 3.49725 2.39068 3.87461 2.28139C4.25197 2.1721 4.65081 2.15986 5.03416 2.24581C5.24515 1.91582 5.53583 1.64425 5.87938 1.45614C6.22293 1.26803 6.60831 1.16943 6.99999 1.16943C7.39167 1.16943 7.77705 1.26803 8.1206 1.45614C8.46415 1.64425 8.75483 1.91582 8.96582 2.24581C9.34975 2.15949 9.74928 2.17167 10.1272 2.28123C10.5052 2.39078 10.8493 2.59414 11.1276 2.8724C11.4058 3.15066 11.6092 3.49477 11.7187 3.87273C11.8283 4.25068 11.8405 4.65021 11.7542 5.03414C12.0841 5.24514 12.3557 5.53581 12.5438 5.87936C12.7319 6.22292 12.8305 6.60829 12.8305 6.99998C12.8305 7.39166 12.7319 7.77703 12.5438 8.12059C12.3557 8.46414 12.0841 8.75481 11.7542 8.96581C11.8401 9.34916 11.8279 9.748 11.7186 10.1254C11.6093 10.5027 11.4065 10.8464 11.129 11.1245C10.8515 11.4025 10.5083 11.6061 10.1311 11.7161C9.754 11.8262 9.35518 11.8393 8.97166 11.7541C8.76093 12.0854 8.47004 12.3581 8.1259 12.5471C7.78176 12.736 7.39551 12.8351 7.00291 12.8351C6.61031 12.8351 6.22406 12.736 5.87992 12.5471C5.53578 12.3581 5.24488 12.0854 5.03416 11.7541C4.65081 11.8401 4.25197 11.8278 3.87461 11.7186C3.49725 11.6093 3.1536 11.4065 2.87551 11.129C2.59743 10.8515 2.39391 10.5082 2.28383 10.1311C2.17375 9.75398 2.16068 9.35517 2.24582 8.97164C1.9133 8.7612 1.6394 8.47008 1.4496 8.12535C1.25981 7.78062 1.16028 7.3935 1.16028 6.99998C1.16028 6.60645 1.25981 6.21933 1.4496 5.8746C1.6394 5.52987 1.9133 5.23875 2.24582 5.02831Z"
          fill="#0B529C"
        />
        <path
          d="M5.25 6.99992L6.41667 8.16659L8.75 5.83325"
          stroke="white"
          stroke-width="1.45833"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
    </span>

    <!-- QMT Company Sub-Logo Icon (Figma 3345:28940) -->
    <span
      v-else-if="normalizedStatus === 'company'"
      :class="['qmt-avatar__company-badge', `qmt-avatar__company-badge--${size}`]"
      aria-hidden="true"
    >
      <img :src="companyLogo || defaultCompanyBadge" alt="" class="qmt-avatar__company-img" />
    </span>

    <!-- Status Indicator Dot (Figma 3345:28934) -->
    <span
      v-else-if="normalizedStatus"
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

.qmt-avatar--bordered {
  border: 1px solid #e5e5e5;
}

/* QMT Verified Rosette Tick (Figma 5230:397) */
.qmt-avatar__verified {
  position: absolute;
  bottom: -2px;
  right: -2px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 9999px;
  background-color: #ffffff;
}

.qmt-avatar__verified-svg {
  width: 100%;
  height: 100%;
  display: block;
}

.qmt-avatar__verified--xs { width: 10px; height: 10px; }
.qmt-avatar__verified--sm { width: 12px; height: 12px; }
.qmt-avatar__verified--md { width: 14px; height: 14px; }
.qmt-avatar__verified--lg { width: 16px; height: 16px; }
.qmt-avatar__verified--xl { width: 18px; height: 18px; }
.qmt-avatar__verified--2xl { width: 20px; height: 20px; }

/* QMT Company Sub-Logo Icon (Figma 3345:28940) */
.qmt-avatar__company-badge {
  position: absolute;
  bottom: -2px;
  right: -2px;
  border-radius: 9999px;
  border: 1.5px solid #ffffff;
  background-color: #ffffff;
  overflow: hidden;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
}

.qmt-avatar__company-badge--xs { width: 10px; height: 10px; }
.qmt-avatar__company-badge--sm { width: 12px; height: 12px; }
.qmt-avatar__company-badge--md { width: 14px; height: 14px; }
.qmt-avatar__company-badge--lg { width: 16px; height: 16px; }
.qmt-avatar__company-badge--xl { width: 18px; height: 18px; }
.qmt-avatar__company-badge--2xl { width: 20px; height: 20px; }

.qmt-avatar__company-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.qmt-avatar__company-dot {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #0b529c 0%, #6366f1 100%);
  border-radius: 9999px;
}

/* Status Indicator Dot (Figma 3345:28934) */
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

.qmt-avatar__status--verified {
  background-color: #009966;
}

.qmt-avatar__status--busy {
  background-color: var(--qmt-avatar-status-busy, #e7000b);
}

.qmt-avatar__status--offline {
  background-color: var(--qmt-avatar-status-offline, #a1a1a1);
}
</style>
