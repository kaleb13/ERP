<script setup lang="ts">
import { Box, Layers, CheckCircle, XCircle } from 'lucide-vue-next';
</script>

<template>
  <div class="dashboard">
    <div class="page-header">
      <div class="breadcrumbs text-xs text-muted">
        <span class="icon-monitor">🖥</span> > Dashboard
      </div>
      <h1 class="h1">Dashboard Overview</h1>
      <p class="text-muted text-sm">System-wide summary of components and entities.</p>
    </div>

    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-info">
          <div class="stat-value h1">12</div>
          <div class="stat-label text-sm text-muted">Business Groups</div>
        </div>
        <div class="stat-icon box">
          <Box :size="24" />
        </div>
      </div>
      
      <div class="stat-card">
        <div class="stat-info">
          <div class="stat-value h1">45</div>
          <div class="stat-label text-sm text-muted">Total Organizations</div>
        </div>
        <div class="stat-icon layers">
          <Layers :size="24" />
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-info">
          <div class="stat-value h1">128</div>
          <div class="stat-label text-sm text-muted">Active Branches</div>
        </div>
        <div class="stat-icon check">
          <CheckCircle :size="24" />
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-info">
          <div class="stat-value h1">3</div>
          <div class="stat-label text-sm text-muted">Inactive Entities</div>
        </div>
        <div class="stat-icon cross">
          <XCircle :size="24" />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-header {
  margin-bottom: var(--spacing-xl);
}
.breadcrumbs {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
  margin-bottom: var(--spacing-sm);
}
.icon-monitor {
  font-size: 14px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: var(--spacing-lg);
}

.stat-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: var(--spacing-lg);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-md);
  display: flex;
  align-items: center;
  justify-content: center;
}
.stat-icon.box { background: #f0f4f8; color: var(--color-primary); }
.stat-icon.layers { background: #eef8ff; color: #0091ff; }
.stat-icon.check { background: var(--color-success-bg); color: var(--color-success); }
.stat-icon.cross { background: var(--color-danger-bg); color: var(--color-danger); }
</style>
