<script setup lang="ts">
import { computed } from 'vue';
import { ArrowLeft, ArrowRight, ChevronDown } from 'lucide-vue-next';

interface Props {
  currentPage: number;
  totalEntries: number;
  perPage: number;
  perPageOptions?: number[];
}

const props = withDefaults(defineProps<Props>(), {
  perPageOptions: () => [1, 5, 10, 25, 50, 100]
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

// Dynamic visible page numbers calculation matching standard pagination with ellipsis
const visiblePages = computed(() => {
  const total = totalPages.value;
  const current = props.currentPage;
  const items: (number | string)[] = [];

  if (total <= 7) {
    for (let i = 1; i <= total; i++) {
      items.push(i);
    }
  } else {
    // Always include page 1
    items.push(1);

    if (current <= 3) {
      items.push(2, 3, '...', total - 2, total - 1, total);
    } else if (current >= total - 2) {
      items.push('...', total - 4, total - 3, total - 2, total - 1, total);
    } else {
      items.push('...', current - 1, current, current + 1, '...', total);
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

const handlePerPageChange = (event: Event) => {
  const target = event.target as HTMLSelectElement;
  const newSize = parseInt(target.value, 10);
  emit('update:perPage', newSize);
  emit('update:currentPage', 1);
};
</script>

<template>
  <div class="custom-pagination-container">
    <!-- LEFT SIDE: Showing info + Per Page select -->
    <div class="pagination-left-section">
      <span class="showing-entries-text">
        Showing {{ paginationStart }} to {{ paginationEnd }} of {{ totalEntries }} entries
      </span>

      <div class="per-page-group">
        <span class="per-page-label">Per Page:</span>
        <div class="per-page-dropdown-box">
          <select 
            :value="perPage" 
            @change="handlePerPageChange" 
            class="per-page-select-input"
          >
            <option v-for="opt in perPageOptions" :key="opt" :value="opt">
              {{ opt }}
            </option>
          </select>
          <ChevronDown :size="13" class="per-page-chevron-icon" />
        </div>
      </div>
    </div>

    <!-- RIGHT SIDE: Single Joined Segmented Pagination Bar -->
    <div class="pagination-right-section">
      <div class="segmented-pagination-bar">
        <!-- Previous Button -->
        <button 
          type="button"
          class="seg-nav-btn seg-prev-btn" 
          :disabled="currentPage === 1 || totalEntries === 0"
          @click="handlePrevious"
        >
          <ArrowLeft :size="14" class="seg-arrow-icon" />
          <span>Previous</span>
        </button>

        <!-- Page Numbers and Ellipses -->
        <template v-for="(p, index) in visiblePages" :key="index">
          <span v-if="p === '...'" class="seg-page-ellipsis">
            ...
          </span>
          <button 
            v-else 
            type="button"
            :class="['seg-page-number-btn', { 'seg-active-page': currentPage === p }]"
            @click="setPage(p)"
          >
            {{ p }}
          </button>
        </template>

        <!-- Next Button -->
        <button 
          type="button"
          class="seg-nav-btn seg-next-btn" 
          :disabled="currentPage >= totalPages || totalEntries === 0"
          @click="handleNext"
        >
          <span>Next</span>
          <ArrowRight :size="14" class="seg-arrow-icon" />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-pagination-container {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  background-color: #ffffff;
  border-top: 1px solid #f1f5f9;
  gap: 16px;
  flex-wrap: wrap;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

/* Left Side: Showing Info & Per Page */
.pagination-left-section {
  display: flex;
  align-items: center;
  gap: 20px;
  flex-wrap: wrap;
}

.showing-entries-text {
  font-size: 13px;
  color: #64748b;
  font-weight: 400;
  white-space: nowrap;
}

.per-page-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.per-page-label {
  font-size: 13px;
  color: #64748b;
  font-weight: 400;
  white-space: nowrap;
}

.per-page-dropdown-box {
  position: relative;
  display: inline-flex;
  align-items: center;
}

.per-page-select-input {
  appearance: none;
  -webkit-appearance: none;
  -moz-appearance: none;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 6px 30px 6px 12px;
  font-size: 13px;
  font-weight: 500;
  color: #1e293b;
  cursor: pointer;
  outline: none;
  min-width: 58px;
  height: 34px;
  transition: all 0.15s ease;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}

.per-page-select-input:hover {
  border-color: #cbd5e1;
}

.per-page-select-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.12);
}

.per-page-chevron-icon {
  position: absolute;
  right: 10px;
  color: #64748b;
  pointer-events: none;
}

/* Right Side: Segmented Joined Control Bar */
.pagination-right-section {
  display: flex;
  align-items: center;
}

.segmented-pagination-bar {
  display: inline-flex;
  align-items: stretch;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
}

/* Segmented Buttons */
.seg-nav-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 0 16px;
  height: 36px;
  background: #ffffff;
  border: none;
  font-size: 13px;
  font-weight: 500;
  color: #334155;
  cursor: pointer;
  transition: all 0.15s ease;
  white-space: nowrap;
}

.seg-prev-btn {
  border-right: 1px solid #e2e8f0;
}

.seg-next-btn {
  border-left: 1px solid #e2e8f0;
}

.seg-nav-btn:hover:not(:disabled) {
  background-color: #f8fafc;
  color: #0f172a;
}

.seg-nav-btn:disabled {
  color: #94a3b8;
  cursor: not-allowed;
  background-color: #ffffff;
  opacity: 0.6;
}

.seg-arrow-icon {
  flex-shrink: 0;
}

/* Page Numbers */
.seg-page-number-btn {
  min-width: 36px;
  height: 36px;
  padding: 0 10px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: #ffffff;
  border: none;
  border-right: 1px solid #e2e8f0;
  font-size: 13px;
  font-weight: 500;
  color: #334155;
  cursor: pointer;
  transition: all 0.15s ease;
}

.seg-page-number-btn:hover:not(.seg-active-page) {
  background-color: #f8fafc;
  color: #0f172a;
}

/* Active Page Matching Screenshot: Solid #0B529C */
.seg-page-number-btn.seg-active-page {
  background-color: #0B529C !important;
  color: #ffffff !important;
  font-weight: 600 !important;
  border-color: #0B529C;
  cursor: default;
}

/* Ellipsis */
.seg-page-ellipsis {
  min-width: 36px;
  height: 36px;
  padding: 0 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: #ffffff;
  border: none;
  border-right: 1px solid #e2e8f0;
  font-size: 13px;
  color: #64748b;
  user-select: none;
  cursor: default;
}

@media (max-width: 640px) {
  .custom-pagination-container {
    flex-direction: column;
    align-items: flex-start;
  }
  .pagination-right-section {
    width: 100%;
    overflow-x: auto;
  }
}
</style>
