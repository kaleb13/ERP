<!--
  Authoritative QMT BaseAvatar & Avatar Profile Photo Component
  Figma Sources (EVkNwnkJXcHROkdv2QqXoU):
  - Avatar:                  3345:28608 (xs–2xl, Placeholder, Text, Status icon, Default/Hover/Focused)
  - Avatar profile photo:    3345:29188 (profile-md 96px, profile-lg 160px, 4px white ring + dual shadow)
  - _Avatar online indicator: 3345:28987 (xs 6px – 2xl 16px, Online #009966 / Offline #D4D4D4)
  - _Avatar company icon:    3345:29000 (scalable vector SVG or custom companyLogo, xs 10px – profile-lg 32px)
  - _Avatar verified tick:   5230:115   (exact QMT #0B529C rosette tick, xs 10px – profile-lg 32px)

  WHEN TO USE:
  - Primary single-user or company avatar across the entire system (top bar, directory lead cells,
    cards, comment authors, and profile hero headers via size="profile-md" / "profile-lg").
  - Pass `status="company"` for suppliers/organizations, `status="verified"` for verified profiles,
    `status="online"` / `"offline"` for presence.
  - Pass `:placeholder="!src"` to display QMT's Placeholder=True icon variant instead of initials.

  WHEN NOT TO USE:
  - DO NOT use for multi-user rosters or committees (use `AvatarGroup.vue` instead).
  - DO NOT use raw <img> tags or ad-hoc circular divs.
-->
<script setup lang="ts">
import { computed, ref, watch, type Component } from 'vue';
import { User } from 'lucide-vue-next';
import defaultCompanyBadgeSvg from '../assets/qmt-company-badge.svg';

export type AvatarSize =
  | 'xs'
  | 'sm'
  | 'md'
  | 'lg'
  | 'xl'
  | '2xl'
  | 'profile-md'
  | 'profile-lg';

export type AvatarStatus =
  | 'online'
  | 'company'
  | 'verified'
  | 'busy'
  | 'offline'
  | boolean;

interface Props {
  /** Image source URL */
  src?: string;
  /** Full name or company name (used for alt text and initials when placeholder is false) */
  name?: string;
  /** Explicit 1–2 letter initials override */
  text?: string;
  /** Force QMT Placeholder=True icon state when no photo `src` is available */
  placeholder?: boolean;
  /** Custom icon component for Placeholder / icon fallback mode */
  icon?: Component;
  /** Avatar dimension: xs (24), sm (32), md (40), lg (48), xl (56), 2xl (64), profile-md (96), profile-lg (160) */
  size?: AvatarSize;
  /** Shape: circle (default) or rounded square */
  shape?: 'circle' | 'square';
  /** Status indicator overlay: online, offline, company, verified, busy */
  status?: AvatarStatus;
  /** Optional custom sub-logo image URL for status="company" (falls back to scalable QMT company badge SVG) */
  companyLogo?: string;
  /** Subtle 1px border (profile-md & profile-lg always include QMT's 4px white ring + elevation shadow) */
  bordered?: boolean;
  /** Optional alt text for image */
  alt?: string;
  /** Interactive hover & QMT focus-ring treatment */
  interactive?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  size: 'md',
  shape: 'circle',
  placeholder: false,
  status: false,
  companyLogo: undefined,
  bordered: false,
  interactive: false
});

const imageError = ref(false);
watch(() => props.src, () => {
  imageError.value = false;
});

const handleImageError = () => {
  imageError.value = true;
};

const isProfileSize = computed(
  () => props.size === 'profile-md' || props.size === 'profile-lg'
);

const showImage = computed(() => Boolean(props.src) && !imageError.value);

const initials = computed(() => {
  if (props.placeholder) return '';
  if (props.text) return props.text.trim().substring(0, 2).toUpperCase();
  if (!props.name) return '';
  const parts = props.name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '';
  if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
});

const iconPixelSize = computed(() => {
  switch (props.size) {
    case 'xs': return 14;
    case 'sm': return 18;
    case 'md': return 22;
    case 'lg': return 26;
    case 'xl': return 30;
    case '2xl': return 34;
    case 'profile-md': return 46;
    case 'profile-lg': return 76;
    default: return 22;
  }
});

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
        'qmt-avatar--profile': isProfileSize,
        'qmt-avatar--interactive': interactive,
        'qmt-avatar--bordered': bordered && !isProfileSize
      }
    ]"
    :tabindex="interactive ? 0 : undefined"
    data-qmt-avatar="avatar"
  >
    <!-- Photo Mode -->
    <img
      v-if="showImage"
      :src="src"
      :alt="alt || name || 'Avatar'"
      class="qmt-avatar__image"
      @error="handleImageError"
    />

    <!-- Text / Initials Mode (Figma 3345:28608 Text=True) -->
    <span v-else-if="initials" class="qmt-avatar__initials">
      {{ initials }}
    </span>

    <!-- QMT Placeholder / Icon Fallback Mode (Figma 3345:28608 Placeholder=True) -->
    <div v-else class="qmt-avatar__icon-wrapper" :aria-label="alt || name || 'Avatar placeholder'">
      <component :is="icon || User" :size="iconPixelSize" class="qmt-avatar__icon" :stroke-width="1.85" />
    </div>

    <!-- QMT Verified Rosette Tick (Figma 5230:115, all 8 sizes xs–profile-lg) -->
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

    <!-- QMT Company Icon (Figma 3345:29000 — infinitely scalable vector SVG or custom companyLogo) -->
    <span
      v-else-if="normalizedStatus === 'company'"
      :class="['qmt-avatar__company-badge', `qmt-avatar__company-badge--${size}`]"
      aria-hidden="true"
    >
      <img
        :src="companyLogo || defaultCompanyBadgeSvg"
        alt=""
        class="qmt-avatar__company-img"
      />
    </span>

    <!-- QMT Online / Offline / Busy Indicator (Figma 3345:28987) -->
    <span
      v-else-if="normalizedStatus"
      :class="[
        'qmt-avatar__status',
        `qmt-avatar__status--${normalizedStatus}`,
        `qmt-avatar__status--${size}`
      ]"
      aria-hidden="true"
    />
  </div>
</template>

<style scoped>
/* QMT Avatar (3345:28608) & Avatar Profile Photo (3345:29188) */
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
  outline: none;
}

/* Shapes */
.qmt-avatar--circle {
  border-radius: var(--qmt-avatar-radius, 9999px);
}

.qmt-avatar--square {
  border-radius: 8px;
}

/* Standard Sizes (3345:28608) */
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

/* Avatar Profile Photo Sizes (3345:29188: 96px md & 160px lg with 4px white ring + dual shadow) */
.qmt-avatar--profile {
  border: 4px solid #ffffff;
  box-shadow:
    0 4px 6px -2px rgba(10, 13, 18, 0.03),
    0 12px 16px -4px rgba(10, 13, 18, 0.08);
}

.qmt-avatar--profile-md {
  width: 96px;
  height: 96px;
  font-size: 28px;
}

.qmt-avatar--profile-lg {
  width: 160px;
  height: 160px;
  font-size: 48px;
}

/* Image */
.qmt-avatar__image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: inherit;
  pointer-events: none;
  display: block;
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

/* Placeholder Icon */
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

/* Interactive Hover & Focus Ring (3345:28608 State=Hover / Focused) */
.qmt-avatar--interactive {
  cursor: pointer;
  transition: opacity 0.15s ease, transform 0.15s ease, box-shadow 0.15s ease;
}

.qmt-avatar--interactive:hover {
  opacity: 0.92;
  transform: translateY(-1px);
}

.qmt-avatar--interactive:focus-visible {
  box-shadow: 0 0 0 4px #e1eefd;
}

.qmt-avatar--bordered {
  border: 1px solid #e5e5e5;
}

/* QMT Verified Rosette Tick (Figma 5230:115, all 8 sizes) */
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
.qmt-avatar__verified--profile-md { width: 24px; height: 24px; bottom: 0; right: 0; }
.qmt-avatar__verified--profile-lg { width: 32px; height: 32px; bottom: 2px; right: 2px; }

/* QMT Company Icon (Figma 3345:29000, scalable vector SVG + white ring) */
.qmt-avatar__company-badge {
  position: absolute;
  bottom: -2px;
  right: -2px;
  border-radius: 9999px;
  border: 1.5px solid #ffffff;
  background-color: #f4ebff;
  overflow: hidden;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.08);
}

.qmt-avatar__company-badge--xs { width: 10px; height: 10px; }
.qmt-avatar__company-badge--sm { width: 12px; height: 12px; }
.qmt-avatar__company-badge--md { width: 14px; height: 14px; }
.qmt-avatar__company-badge--lg { width: 16px; height: 16px; }
.qmt-avatar__company-badge--xl { width: 18px; height: 18px; }
.qmt-avatar__company-badge--2xl { width: 20px; height: 20px; }
.qmt-avatar__company-badge--profile-md {
  width: 26px;
  height: 26px;
  border-width: 2px;
  bottom: 0;
  right: 0;
}
.qmt-avatar__company-badge--profile-lg {
  width: 34px;
  height: 34px;
  border-width: 2.5px;
  bottom: 2px;
  right: 2px;
}

.qmt-avatar__company-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

/* QMT Online Indicator (Figma 3345:28987 exact sizes & QMT semantic tokens) */
.qmt-avatar__status {
  position: absolute;
  bottom: 0;
  right: 0;
  border-radius: 9999px;
  border: 1.5px solid var(--qmt-avatar-border, #ffffff);
  box-sizing: border-box;
}

.qmt-avatar__status--xs { width: 6px; height: 6px; }
.qmt-avatar__status--sm { width: 8px; height: 8px; }
.qmt-avatar__status--md { width: 10px; height: 10px; }
.qmt-avatar__status--lg { width: 12px; height: 12px; }
.qmt-avatar__status--xl { width: 14px; height: 14px; }
.qmt-avatar__status--2xl { width: 16px; height: 16px; }
.qmt-avatar__status--profile-md { width: 18px; height: 18px; border-width: 2px; }
.qmt-avatar__status--profile-lg { width: 24px; height: 24px; border-width: 2.5px; }

/* Exact QMT Indicator Colors */
.qmt-avatar__status--online {
  background-color: var(--qmt-avatar-status-online, #009966);
}

.qmt-avatar__status--offline {
  background-color: var(--qmt-avatar-status-offline, #d4d4d4);
}

.qmt-avatar__status--busy {
  background-color: var(--qmt-avatar-status-busy, #e7000b);
}
</style>
