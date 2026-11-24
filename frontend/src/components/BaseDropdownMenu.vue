<!--
  Authoritative QMT BaseDropdownMenu Component (Figma 3345:2 / 5338:672)
  =======================================================================
  WHEN TO USE (SCENARIOS & PLACES):
  - Standard popover dropdown menu for Filter buttons, 3-dot (`MoreVertical`) action menus,
    section headers (e.g., Activity Log header), and table row action menus.
  - Uses QMT `--qmt-dropdown-*` design tokens from `src/style.css`.
  - Teleports menu panel to `body` with viewport-aware positioning so it never clips
    inside `overflow: hidden` cards or `overflow-x: auto` table wrappers.

  WHEN NOT TO USE:
  - DO NOT use for form field lookups/selectors (use `FormSelect.vue` or `FormCombobox.vue`).
-->
<script setup lang="ts">
import { ref, nextTick, onMounted, onUnmounted, type Component } from 'vue';
import { Check } from 'lucide-vue-next';

export interface DropdownMenuItem {
  key: string;
  label?: string;
  sectionLabel?: string;
  icon?: Component;
  selected?: boolean;
  destructive?: boolean;
  disabled?: boolean;
  divider?: boolean;
  onClick?: () => void;
}

const props = withDefaults(
  defineProps<{
    items: DropdownMenuItem[];
    align?: 'left' | 'right';
    minWidth?: string;
    closeOnSelect?: boolean;
  }>(),
  {
    align: 'right',
    minWidth: '196px',
    closeOnSelect: true
  }
);

const emit = defineEmits<{
  (e: 'select', item: DropdownMenuItem): void;
  (e: 'open'): void;
  (e: 'close'): void;
}>();

const isOpen = ref(false);
const triggerWrapRef = ref<HTMLElement | null>(null);
const menuRef = ref<HTMLElement | null>(null);
const menuStyle = ref<Record<string, string>>({});

const updatePosition = () => {
  const trigger = triggerWrapRef.value;
  if (!trigger) return;
  const rect = trigger.getBoundingClientRect();
  const menuEl = menuRef.value;
  const menuHeight = menuEl ? menuEl.offsetHeight : 180;
  const menuWidth = menuEl ? menuEl.offsetWidth : parseInt(props.minWidth, 10) || 196;

  const spaceBelow = window.innerHeight - rect.bottom;
  const openUpward = spaceBelow < menuHeight + 8 && rect.top > menuHeight + 8;

  let top = openUpward ? Math.max(8, rect.top - menuHeight - 6) : rect.bottom + 6;
  let left = props.align === 'right' ? rect.right - menuWidth : rect.left;

  if (left + menuWidth > window.innerWidth - 8) {
    left = Math.max(8, window.innerWidth - menuWidth - 8);
  }
  if (left < 8) {
    left = 8;
  }

  menuStyle.value = {
    position: 'fixed',
    top: `${top}px`,
    left: `${left}px`,
    minWidth: props.minWidth,
    zIndex: '99999'
  };
};

const close = () => {
  if (!isOpen.value) return;
  isOpen.value = false;
  emit('close');
};

const open = () => {
  if (isOpen.value) return;
  isOpen.value = true;
  emit('open');
  updatePosition();
  nextTick(updatePosition);
};

const toggle = () => {
  if (isOpen.value) close();
  else open();
};

const handleItemClick = (item: DropdownMenuItem) => {
  if (item.disabled || item.divider || item.sectionLabel) return;
  item.onClick?.();
  emit('select', item);
  if (props.closeOnSelect) {
    close();
  }
};

const handleOutsideClick = (event: MouseEvent) => {
  if (!isOpen.value) return;
  const target = event.target as Node | null;
  if (!target) return;
  if (triggerWrapRef.value?.contains(target)) return;
  if (menuRef.value?.contains(target)) return;
  close();
};

const handleKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Escape' && isOpen.value) {
    close();
  }
};

const handleScrollOrResize = () => {
  if (isOpen.value) {
    close();
  }
};

onMounted(() => {
  document.addEventListener('click', handleOutsideClick, true);
  document.addEventListener('keydown', handleKeydown);
  window.addEventListener('scroll', handleScrollOrResize, true);
  window.addEventListener('resize', handleScrollOrResize);
});

onUnmounted(() => {
  document.removeEventListener('click', handleOutsideClick, true);
  document.removeEventListener('keydown', handleKeydown);
  window.removeEventListener('scroll', handleScrollOrResize, true);
  window.removeEventListener('resize', handleScrollOrResize);
});

defineExpose({ open, close, toggle, isOpen });
</script>

<template>
  <div ref="triggerWrapRef" class="qmt-dropdown-trigger-wrap" @click.stop>
    <slot name="trigger" :isOpen="isOpen" :toggle="toggle" :close="close" />

    <Teleport to="body">
      <div
        v-if="isOpen"
        ref="menuRef"
        class="qmt-dropdown-panel"
        role="menu"
        :style="menuStyle"
        @click.stop
      >
        <template v-for="item in items" :key="item.key">
          <div v-if="item.divider" class="qmt-dropdown-separator" role="separator" />
          <div v-else-if="item.sectionLabel" class="qmt-dropdown-section">
            {{ item.sectionLabel }}
          </div>
          <button
            v-else
            type="button"
            role="menuitem"
            class="qmt-dropdown-item"
            :class="{
              'is-selected': item.selected,
              'is-destructive': item.destructive,
              'is-disabled': item.disabled
            }"
            :disabled="item.disabled"
            @click="handleItemClick(item)"
          >
            <component
              :is="item.icon"
              v-if="item.icon"
              :size="15"
              class="qmt-dropdown-item__icon"
            />
            <span class="qmt-dropdown-item__label">{{ item.label }}</span>
            <Check
              v-if="item.selected"
              :size="15"
              class="qmt-dropdown-item__check"
            />
          </button>
        </template>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.qmt-dropdown-trigger-wrap {
  position: relative;
  display: inline-flex;
  align-items: center;
}

.qmt-dropdown-panel {
  background-color: var(--qmt-dropdown-panel-bg, #ffffff);
  border: 1px solid var(--qmt-dropdown-panel-border, #e5e5e5);
  border-radius: var(--qmt-dropdown-panel-radius, 8px);
  padding: var(--qmt-dropdown-panel-padding, 4px);
  box-shadow:
    0 12px 16px -4px var(--qmt-color-shadow-medium, rgba(10, 13, 18, 0.14)),
    0 4px 6px -2px var(--qmt-color-shadow-faint, rgba(10, 13, 18, 0.05));
  display: flex;
  flex-direction: column;
  gap: var(--qmt-dropdown-item-spacing, 2px);
  box-sizing: border-box;
}

.qmt-dropdown-separator {
  height: 1px;
  background-color: var(--qmt-dropdown-separator-color, #e5e5e5);
  margin: var(--qmt-dropdown-separator-margin-y, 4px) 0;
}

.qmt-dropdown-section {
  padding: 6px var(--qmt-dropdown-item-padding-x, 10px) 4px;
  font-size: 11.5px;
  font-weight: 600;
  color: var(--qmt-dropdown-section-fg, #737373);
  user-select: none;
}

.qmt-dropdown-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: var(--qmt-dropdown-item-gap, 8px);
  padding: var(--qmt-dropdown-item-padding-y, 8px) var(--qmt-dropdown-item-padding-x, 10px);
  border: none;
  border-radius: var(--qmt-dropdown-item-radius, 6px);
  background: transparent;
  color: var(--qmt-dropdown-item-fg, #404040);
  font-size: 13.5px;
  font-weight: 500;
  line-height: 20px;
  text-align: left;
  cursor: pointer;
  transition: background-color 0.12s ease, color 0.12s ease;
  font-family: inherit;
  outline: none;
}

.qmt-dropdown-item:hover:not(:disabled) {
  background-color: var(--qmt-dropdown-item-bg-hover, #f5f5f5);
}

.qmt-dropdown-item.is-selected:not(:disabled) {
  background-color: var(--qmt-dropdown-item-bg-selected, #f5f5f5);
}

.qmt-dropdown-item.is-disabled {
  color: var(--qmt-dropdown-item-fg-disabled, #a1a1a1);
  cursor: not-allowed;
}

.qmt-dropdown-item.is-destructive {
  color: var(--alias-color-error-600, #e7000b);
}

.qmt-dropdown-item.is-destructive:hover:not(:disabled) {
  background-color: var(--primitive-color-red-50, #fef2f2);
}

.qmt-dropdown-item.is-destructive .qmt-dropdown-item__icon {
  color: inherit;
}

.qmt-dropdown-item__icon {
  color: var(--qmt-dropdown-item-icon, #737373);
  flex-shrink: 0;
}

.qmt-dropdown-item__label {
  flex: 1;
  min-width: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.qmt-dropdown-item__check {
  color: var(--qmt-dropdown-item-check, #0b529c);
  flex-shrink: 0;
}
</style>
