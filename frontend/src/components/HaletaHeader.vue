<script setup lang="ts">
import { ChevronRight } from 'lucide-vue-next';

export interface BreadcrumbItem {
  label: string;
  onClick?: () => void;
  isCurrent?: boolean;
}

const props = defineProps<{
  icon?: any;
  breadcrumbs: BreadcrumbItem[];
  statusBadge?: string;
}>();
</script>

<template>
  <header class="haleta-toolbar px-8 py-4 sticky top-0 z-50">
    <div class="toolbar-left-side">
      <component v-if="icon" :is="icon" :size="16" />
      <ChevronRight v-if="icon" :size="10" class="sep" />
      
      <nav class="haleta-breadcrumb">
        <template v-for="(crumb, index) in breadcrumbs" :key="index">
          <span v-if="!crumb.isCurrent" class="crumb-link" @click="crumb.onClick ? crumb.onClick() : null">
            {{ crumb.label }}
          </span>
          <span v-else class="crumb-current">
            {{ crumb.label }}
          </span>
          <ChevronRight v-if="index < breadcrumbs.length - 1" :size="10" class="sep" />
        </template>
      </nav>

      <div v-if="statusBadge" class="haleta-status-pill">
         {{ statusBadge }}
      </div>
    </div>

    <div class="toolbar-right-side">
      <slot name="actions"></slot>
    </div>
  </header>
</template>

<style scoped>
.haleta-toolbar {
  display: grid !important;
  grid-template-columns: 1fr auto !important;
  align-items: center !important;
  background: transparent;
  width: 100%;
}

.toolbar-left-side {
  display: flex !important;
  flex-direction: row !important;
  align-items: center !important;
  gap: 12px !important;
  color: #64748b;
}

.haleta-breadcrumb {
  display: flex !important;
  flex-direction: row !important;
  align-items: center !important;
  gap: 8px !important;
  font-size: 13px;
  font-weight: 600;
  white-space: nowrap;
}

.toolbar-left-side .sep { color: #cbd5e1; }
.crumb-link { color: #64748b; cursor: pointer; transition: color 0.2s; }
.crumb-link:hover { color: #4f46e5; }
.crumb-current { color: #0f172a; font-weight: 700; }

.haleta-status-pill {
  background: #fff7ed;
  color: #c2410c;
  border: 1px solid #ffedd5;
  font-size: 10px;
  font-weight: 700;
  padding: 2px 12px;
  border-radius: 50px;
  white-space: nowrap;
}

.toolbar-right-side {
  display: flex !important;
  justify-content: flex-end !important;
}
</style>
