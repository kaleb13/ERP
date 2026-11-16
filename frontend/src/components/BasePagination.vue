<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted, nextTick } from 'vue';
import { ArrowLeft, ArrowRight, ChevronDown, Check } from 'lucide-vue-next';

interface Props {
  currentPage: number;
  totalEntries: number;
  perPage: number;
  perPageOptions?: number[];
  color?: 'brand' | 'light';
  showSummary?: boolean;
  showPerPage?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  perPageOptions: () => [10, 25, 50, 100],
  color: 'brand',
  showSummary: true,
  showPerPage: true
});

const emit = defineEmits<{
  (e: 'update:currentPage', page: number): void;
  (e: 'update:perPage', size: number): void;
}>();

const totalPages = computed(() => {
  if (props.totalEntries === 0) return 1;
  return Math.ceil(props.totalEntries / props.perPage) || 1;
});

const paginationStart = computed(() => {
  if (props.totalEntries === 0) return 0;
  return (props.currentPage - 1) * props.perPage + 1;
});

const paginationEnd = computed(() => {
  if (props.totalEntries === 0) return 0;
  return Math.min(props.currentPage * props.perPage, props.totalEntries);
});

// QMT Dynamic Visible Page Calculation with ellipsis (matches Figma Node 3345:27425)
const visiblePages = computed(() => {
  const total = totalPages.value;
  const current = props.currentPage;
  const items: (number | string)[] = [];

  if (total <= 7) {
    for (let i = 1; i <= total; i++) {
      items.push(i);
    }
  } else {
    items.push(1);

    if (current <= 4) {
      items.push(2, 3, 4, 5, '…', total);
    } else if (current >= total - 3) {
      items.push('…', total - 4, total - 3, total - 2, total - 1, total);
    } else {
      items.push('…', current - 1, current, current + 1, '…', total);
    }
  }

  return items;
});

const setPage = (p: number | string) => {
  if (typeof p === 'number' && p >= 1 && p <= totalPages.value && p !== props.currentPage) {
    emit('update:currentPage', p);
  }
};

const handlePrevious = () => {
  if (props.currentPage > 1) {
    emit('update:currentPage', props.currentPage - 1);
  }
};

const handleNext = () => {
  if (props.currentPage < totalPages.value) {
    emit('update:currentPage', props.currentPage + 1);
  }
};

const isPerPageOpen = ref(false);
const perPageButtonRef = ref<HTMLButtonElement | null>(null);
const perPageMenuRef = ref<HTMLElement | null>(null);
const perPageMenuStyle = ref<Record<string, string>>({});

const updatePerPageMenuPosition = () => {
  if (!perPageButtonRef.value) return;
  const rect = perPageButtonRef.value.getBoundingClientRect();
  const menuHeight = (props.perPageOptions.length * 36) + 12;
  const spaceBelow = window.innerHeight - rect.bottom;
  const openAbove = spaceBelow < menuHeight && rect.top > menuHeight;

  perPageMenuStyle.value = {
    position: 'fixed',
    top: openAbove ? 'auto' : `${rect.bottom + 4}px`,
    bottom: openAbove ? `${window.innerHeight - rect.top + 4}px` : 'auto',
    left: `${rect.left}px`,
    minWidth: `${Math.max(rect.width, 80)}px`,
    zIndex: '99999'
  };
};

const togglePerPageMenu = () => {
  isPerPageOpen.value = !isPerPageOpen.value;
  if (isPerPageOpen.value) {
    nextTick(() => {
      updatePerPageMenuPosition();
    });
  }
};

const closePerPageMenu = () => {
  isPerPageOpen.value = false;
};

const selectPerPage = (opt: number) => {
  emit('update:perPage', opt);
  emit('update:currentPage', 1);
  closePerPageMenu();
};

const handleClickOutside = (e: MouseEvent) => {
  if (!isPerPageOpen.value) return;
  const target = e.target as Node;
  if (
    perPageButtonRef.value && !perPageButtonRef.value.contains(target) &&
    perPageMenuRef.value && !perPageMenuRef.value.contains(target)
  ) {
    closePerPageMenu();
  }
};

const handleWindowScrollResize = () => {
  if (isPerPageOpen.value) {
    updatePerPageMenuPosition();
  }
};

onMounted(() => {
  document.addEventListener('click', handleClickOutside);
  window.addEventListener('scroll', handleWindowScrollResize, true);
  window.addEventListener('resize', handleWindowScrollResize);
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
  window.removeEventListener('scroll', handleWindowScrollResize, true);
  window.removeEventListener('resize', handleWindowScrollResize);
});
</script>

<template>
  <div 
    class="qmt-pagination-card" 
    data-node-id="3345:27425"
    data-name="Pagination / Card button group right aligned / Brand / Square / Desktop"
  >
    <!-- LEFT SIDE: Summary Info & Per Page Dropdown (Figma Node 5626:1160) -->
    <div v-if="showSummary" class="qmt-pagination-summary-group" data-node-id="5626:1160">
      <p class="qmt-pagination-summary" data-node-id="5626:1161">
        Showing {{ paginationStart }} to {{ paginationEnd }} of {{ totalEntries }} entries
      </p>

      <div v-if="showPerPage" class="qmt-pagination-page-size" data-node-id="5626:1162">
        <span class="qmt-pagination-page-size-label" data-node-id="5626:1163">Per page</span>
        
        <div class="qmt-pagination-select-wrapper" data-node-id="5626:1164">
          <button
            ref="perPageButtonRef"
            type="button"
            class="qmt-pagination-select-button"
            data-node-id="I5626:1164;3345:17964"
            aria-haspopup="listbox"
            :aria-expanded="isPerPageOpen"
            title="Select entries per page"
            @click="togglePerPageMenu"
          >
            <span class="qmt-pagination-select-value">{{ perPage }}</span>
            <ChevronDown :size="16" class="qmt-pagination-select-chevron" :class="{ 'is-open': isPerPageOpen }" />
          </button>

          <Teleport to="body">
            <div
              v-if="isPerPageOpen"
              ref="perPageMenuRef"
              class="qmt-pagination-dropdown-menu"
              :style="perPageMenuStyle"
              role="listbox"
            >
              <button
                v-for="opt in perPageOptions"
                :key="opt"
                type="button"
                class="qmt-pagination-dropdown-item"
                :class="{ 'is-active': opt === perPage }"
                role="option"
                :aria-selected="opt === perPage"
                @click="selectPerPage(opt)"
              >
                <span>{{ opt }}</span>
                <Check v-if="opt === perPage" :size="14" class="qmt-pagination-item-check" />
              </button>
            </div>
          </Teleport>
        </div>
      </div>
    </div>

    <!-- RIGHT SIDE: Contiguous Segmented Button Group (Figma Node 5626:1105) -->
    <div class="qmt-pagination-button-group" data-node-id="5626:1105">
      <!-- Previous Segment Cell -->
      <button 
        type="button"
        class="qmt-pagination-segment qmt-pagination-segment--prev"
        :class="{ 'is-disabled': currentPage <= 1 || totalEntries === 0 }"
        :disabled="currentPage <= 1 || totalEntries === 0"
        title="Previous Page"
        @click="handlePrevious"
      >
        <ArrowLeft :size="16" class="qmt-pagination-segment-icon" />
        <span class="qmt-pagination-segment-label">Previous</span>
      </button>

      <!-- Page Number Segments & Ellipsis -->
      <template v-for="(p, index) in visiblePages" :key="index">
        <!-- Ellipsis Cell -->
        <span 
          v-if="p === '…'" 
          class="qmt-pagination-segment qmt-pagination-segment--ellipsis"
        >
          …
        </span>

        <!-- Page Number Cell -->
        <button 
          v-else 
          type="button"
          :class="[
            'qmt-pagination-segment',
            'qmt-pagination-segment--page',
            { 'is-current': currentPage === p }
          ]"
          :aria-current="currentPage === p ? 'page' : undefined"
          @click="setPage(p)"
        >
          {{ p }}
        </button>
      </template>

      <!-- Next Segment Cell -->
      <button 
        type="button"
        class="qmt-pagination-segment qmt-pagination-segment--next"
        :class="{ 'is-disabled': currentPage >= totalPages || totalEntries === 0 }"
        :disabled="currentPage >= totalPages || totalEntries === 0"
        title="Next Page"
        @click="handleNext"
      >
        <span class="qmt-pagination-segment-label">Next</span>
        <ArrowRight :size="16" class="qmt-pagination-segment-icon" />
      </button>
    </div>
  </div>
</template>

<style scoped>
/* ═══════════════════════════════════════════════════════════════════════════ */
/* QMT CARD BUTTON GROUP RIGHT ALIGNED PAGINATION (Figma 3345:27425)            */
/* ═══════════════════════════════════════════════════════════════════════════ */

.qmt-pagination-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--qmt-pagination-gap, 12px);
  min-height: 60px;
  padding: var(--qmt-pagination-card-padding-top, 12px) var(--qmt-pagination-card-padding-x, 24px) var(--qmt-pagination-card-padding-bottom, 16px) var(--qmt-pagination-card-padding-x, 24px);
  background-color: var(--alias-color-background-surface-elevated, #ffffff);
  border-top: 1px solid var(--qmt-pagination-border, #e5e5e5);
  font-family: var(--qmt-font-family-sans, 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif);
  box-sizing: border-box;
  width: 100%;
}

/* ─── LEFT: Summary & Per Page Dropdown ─── */
.qmt-pagination-summary-group {
  display: flex;
  align-items: center;
  gap: var(--qmt-pagination-gap, 12px);
  flex-shrink: 0;
}

.qmt-pagination-summary {
  font-size: 14px;
  font-weight: 400;
  line-height: 20px;
  color: var(--qmt-pagination-summary-fg, #737373);
  white-space: nowrap;
  margin: 0;
}

.qmt-pagination-page-size {
  display: flex;
  align-items: center;
  gap: var(--qmt-pagination-gap, 12px);
  flex-shrink: 0;
}

.qmt-pagination-page-size-label {
  font-size: 14px;
  font-weight: 400;
  line-height: 20px;
  color: var(--qmt-pagination-summary-fg, #737373);
  white-space: nowrap;
}

/* Page Size Custom Select Button (Figma Node I5626:1164;3345:17964) */
.qmt-pagination-select-wrapper {
  position: relative;
  display: inline-flex;
  align-items: center;
}

.qmt-pagination-select-button {
  background-color: #ffffff;
  border: 1px solid var(--qmt-pagination-button-border, #d9d9d9);
  border-radius: var(--qmt-button-radius, 8px);
  height: 36px;
  padding: 0 var(--qmt-button-sm-padding-x, 14px);
  display: inline-flex;
  align-items: center;
  gap: var(--qmt-button-gap, 8px);
  box-shadow: 0px 1px 2px 0px rgba(10, 13, 18, 0.05);
  cursor: pointer;
  transition: all 0.15s ease;
}

.qmt-pagination-select-value {
  font-size: 14px;
  font-weight: 600;
  line-height: 20px;
  color: #414651;
}

.qmt-pagination-select-chevron {
  color: #414651;
  flex-shrink: 0;
  transition: transform 0.2s ease;
}

.qmt-pagination-select-chevron.is-open {
  transform: rotate(180deg);
}

.qmt-pagination-select-button:hover {
  border-color: #a1a1a1;
  background-color: #fafafa;
}

.qmt-pagination-select-button:focus,
.qmt-pagination-select-button:focus-visible {
  outline: none;
  border-color: #0b529c;
  box-shadow: 0 0 0 3px var(--qmt-color-focus-ring-brand, #e1eefd);
}

/* Teleported Dropdown Menu for Per Page */
.qmt-pagination-dropdown-menu {
  background: #ffffff;
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  padding: 4px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.qmt-pagination-dropdown-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-radius: 6px;
  border: none;
  background: transparent;
  color: #404040;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
  width: 100%;
  text-align: left;
}

.qmt-pagination-dropdown-item:hover {
  background-color: #f5f5f5;
  color: #0b529c;
}

.qmt-pagination-dropdown-item.is-active {
  background-color: #e1eefd;
  color: #0b529c;
  font-weight: 600;
}

.qmt-pagination-item-check {
  color: #0b529c;
  margin-left: 8px;
}

/* ─── RIGHT: Segmented Button Group (Figma Node 5626:1105) ─── */
.qmt-pagination-button-group {
  display: inline-flex;
  align-items: center;
  background-color: var(--qmt-pagination-group-bg, #ffffff);
  border: 1px solid var(--qmt-pagination-group-border, #d4d4d4);
  border-radius: var(--qmt-pagination-group-radius, 8px);
  box-shadow: 0px 1px 2px 0px rgba(10, 13, 18, 0.05);
  overflow: hidden;
  flex-shrink: 0;
}

/* Each Segment Cell (PaginationItemBase: 5624:678) */
.qmt-pagination-segment {
  height: var(--qmt-pagination-item-height, 40px);
  min-width: var(--qmt-pagination-item-min-width, 40px);
  padding: 0 var(--qmt-pagination-item-padding-x, 12px);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--qmt-pagination-item-gap, 8px);
  font-family: inherit;
  font-size: 14px;
  font-weight: 500;
  line-height: 20px;
  border-top: none;
  border-bottom: none;
  border-right: none;
  border-left: 1px solid var(--qmt-pagination-group-border, #d4d4d4);
  background-color: transparent;
  color: var(--qmt-pagination-fg, #737373);
  cursor: pointer;
  user-select: none;
  transition: background-color 0.15s ease, color 0.15s ease;
  box-sizing: border-box;
  white-space: nowrap;
  outline: none;
}

/* First segment in button group has no left border */
.qmt-pagination-segment:first-child {
  border-left: none;
}

.qmt-pagination-segment-icon {
  flex-shrink: 0;
  color: inherit;
}

.qmt-pagination-segment-label {
  font-family: inherit;
  font-weight: 500;
}

/* Inactive Hover */
.qmt-pagination-segment:hover:not(.is-current):not(.is-disabled):not(.qmt-pagination-segment--ellipsis) {
  background-color: var(--qmt-pagination-bg-hover, #f5f5f5);
  color: #404040;
}

/* Active / Current Brand Blue Cell (Figma 5624:654) */
.qmt-pagination-segment.is-current {
  background-color: var(--qmt-pagination-brand-bg-current, #0b529c) !important;
  color: var(--qmt-pagination-brand-fg-current, #ffffff) !important;
  font-weight: 500;
  cursor: default;
}

/* Disabled Cell (Figma 5624:648) */
.qmt-pagination-segment.is-disabled,
.qmt-pagination-segment:disabled {
  color: var(--qmt-pagination-fg-disabled, #a1a1a1) !important;
  cursor: not-allowed;
  background-color: transparent;
}

/* Ellipsis Gap Cell (Figma 5625:416) */
.qmt-pagination-segment--ellipsis {
  color: var(--qmt-pagination-fg, #737373);
  cursor: default;
}

/* Focus Ring */
.qmt-pagination-segment:focus-visible:not(.is-disabled) {
  position: relative;
  z-index: 2;
  box-shadow: inset 0 0 0 2px var(--qmt-pagination-brand-bg-current, #0b529c);
}

/* Responsive Collapse for Small Screens */
@media (max-width: 860px) {
  .qmt-pagination-card {
    flex-direction: column;
    align-items: stretch;
    height: auto;
    padding: 16px;
    gap: 16px;
  }

  .qmt-pagination-summary-group {
    justify-content: space-between;
    width: 100%;
    flex-wrap: wrap;
  }

  .qmt-pagination-button-group {
    align-self: center;
    max-width: 100%;
    overflow-x: auto;
  }
}
</style>
