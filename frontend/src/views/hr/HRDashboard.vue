<script setup lang="ts">
import { Monitor, ChevronRight } from 'lucide-vue-next';
</script>

<template>
  <div class="hr-dashboard-page">
    <!-- Breadcrumbs -->
    <div class="breadcrumb-nav">
      <router-link to="/dashboard" class="breadcrumb-icon-link" title="Dashboard">
        <Monitor :size="15" />
      </router-link>
      <ChevronRight :size="12" class="breadcrumb-divider" />
      <span class="breadcrumb-current">Human Resources</span>
    </div>

    <!-- Header -->
    <div class="page-header">
      <div>
        <h1 class="page-title">Human Resources</h1>
        <p class="page-subtitle">Welcome to the HR Module. Ready for page building.</p>
      </div>
    </div>

    <!-- Empty Slate Area -->
    <div class="empty-dashboard-container">
      <!-- Empty state / blank container for building -->
    </div>
  </div>
</template>

<style scoped>
.hr-dashboard-page {
  padding: 0;
  animation: fadeIn 0.2s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(4px); }
  to { opacity: 1; transform: translateY(0); }
}

.breadcrumb-nav {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  margin-bottom: 20px;
  font-family: 'Inter', sans-serif;
}

.breadcrumb-icon-link {
  color: #6b7280;
  text-decoration: none;
  display: flex;
  align-items: center;
  transition: color 0.15s ease;
}

.breadcrumb-icon-link:hover {
  color: #111827;
}

.breadcrumb-divider {
  color: #9ca3af;
  display: flex;
  align-items: center;
}

.breadcrumb-current {
  color: #111827;
  font-weight: 500;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
}

.page-title {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  letter-spacing: -0.02em;
}

.page-subtitle {
  font-size: 13px;
  color: #6b7280;
  margin-top: 4px;
}

.empty-dashboard-container {
  min-height: 400px;
}
</style>
