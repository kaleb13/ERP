<script setup lang="ts">
import { Search, Maximize, Moon, Languages, Bell, Menu } from 'lucide-vue-next';
</script>

<template>
  <header class="header">
    <div class="left">
      <button class="btn-icon">
        <Menu :size="20" />
      </button>
      <div class="search-bar">
        <Search :size="16" class="search-icon" />
        <input type="text" placeholder="Search Everything..." class="search-input" />
      </div>
    </div>
    
    <div class="right">
      <button class="btn-icon">
        <Maximize :size="20" />
      </button>
      <button class="btn-icon">
        <Moon :size="20" />
      </button>
      <button class="btn-icon">
        <Languages :size="20" />
      </button>
      <button class="btn-icon bell">
        <Bell :size="20" />
        <span class="badge-dot"></span>
      </button>
      <img src="https://i.pravatar.cc/150?img=68" alt="Profile" class="avatar" />
    </div>
  </header>
</template>

<style scoped>
.header {
  height: 64px;
  background-color: var(--color-surface);
  border-bottom: 1px solid var(--color-border);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 var(--spacing-lg);
}

.left, .right {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
}

.btn-icon {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--radius-sm);
  color: var(--color-secondary);
  transition: background-color 0.2s;
}
.btn-icon:hover {
  background-color: var(--color-bg);
  color: var(--color-text-main);
}

.search-bar {
  display: flex;
  align-items: center;
  background-color: var(--color-bg);
  border-radius: var(--radius-full);
  padding: 8px 16px;
  width: 300px;
  margin-left: var(--spacing-md);
}
.search-icon {
  color: var(--color-secondary);
  margin-right: 8px;
}
.search-input {
  border: none;
  background: transparent;
  outline: none;
  font-size: 14px;
  width: 100%;
}
.search-input::placeholder {
  color: var(--color-text-muted);
}

.bell {
  position: relative;
}
.badge-dot {
  position: absolute;
  top: 8px;
  right: 8px;
  width: 8px;
  height: 8px;
  background-color: var(--color-danger);
  border-radius: 50%;
  border: 2px solid var(--color-surface);
}

.avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  margin-left: var(--spacing-sm);
  cursor: pointer;
}
</style>
