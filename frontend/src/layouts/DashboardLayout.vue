<script setup lang="ts">
import { ref } from 'vue';
import { 
  Search, Maximize, Moon, Languages, Bell, ChevronDown, PanelLeft
} from 'lucide-vue-next';
import AppSidebar from '../components/AppSidebar.vue';

// Sidebar collapse state
const isSidebarCollapsed = ref(false);

const toggleSidebar = () => {
  isSidebarCollapsed.value = !isSidebarCollapsed.value;
};
</script>

<template>
  <div class="erp-layout">
    <!-- STANDALONE MODULAR APPSIDEBAR COMPONENT -->
    <AppSidebar :collapsed="isSidebarCollapsed" />

    <!-- MAIN CONTENT -->
    <main class="main-wrapper">
      <!-- TOP BAR (Figma Node 4237:9495) -->
      <header class="topbar">
        <div class="topbar-left">
          <button 
            @click="toggleSidebar" 
            class="sidebar-toggle-btn" 
            :title="isSidebarCollapsed ? 'Open sidebar' : 'Close sidebar'"
          >
            <PanelLeft :size="20" class="icon-secondary" />
          </button>
        </div>
        
        <div class="topbar-center">
          <div class="search-wrap">
            <Search :size="20" class="search-icon" />
            <input type="text" placeholder="Search Everything..." class="search-input" />
            <div class="search-shortcut" title="Press ⌘K or Ctrl+K to search">
              <span class="shortcut-cmd">⌘</span>
              <span class="shortcut-key">K</span>
            </div>
          </div>
        </div>

        <div class="topbar-right">
          <button class="header-action-btn" title="Fullscreen"><Maximize :size="24" /></button>
          <button class="header-action-btn" title="Dark Mode"><Moon :size="24" /></button>
          <button class="header-action-btn" title="Language"><Languages :size="24" /></button>
          <button class="header-action-btn relative" title="Notifications">
            <Bell :size="24" />
            <span class="notification-badge">2</span>
          </button>
          
          <div class="topbar-divider"></div>
          
          <div class="profile-wrapper">
            <div class="avatar-container">
              <img src="https://i.pravatar.cc/100?img=5" alt="Marta Tadesse" class="avatar-img" />
              <span class="status-indicator"></span>
            </div>
            <span class="profile-name-text">Marta Tadesse</span>
            <ChevronDown :size="16" class="profile-chevron" />
          </div>
        </div>
      </header>

      <!-- PAGE CONTENT AREA -->
      <div class="page-content">
        <slot></slot>
      </div>
    </main>
  </div>
</template>

<style scoped>
.erp-layout {
  display: flex;
  height: 100vh;
  height: 100dvh;
  width: 100%;
  max-width: 100vw;
  background-color: #fafafa;
  overflow: hidden;
  font-family: 'Inter', sans-serif;
}

/* MAIN CONTENT */
.main-wrapper { 
  flex: 1; 
  display: flex; 
  flex-direction: column; 
  height: 100%;
  max-height: 100vh;
  max-height: 100dvh;
  min-width: 0;
  min-height: 0;
  overflow: hidden; 
  background-color: #fafafa; 
}

/* TOP BAR (Figma Node 4237:9495) */
.topbar {
  height: 72px;
  min-height: 72px;
  max-height: 72px;
  flex-shrink: 0;
  background-color: var(--alias-color-generic-white, #ffffff);
  border-bottom: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--alias-spacing-xl, 16px) var(--alias-spacing-3xl, 24px);
  z-index: 50;
  box-sizing: border-box;
}

.topbar-left {
  display: flex;
  align-items: center;
}

.sidebar-toggle-btn {
  background-color: var(--alias-color-background-secondary, #f5f5f5);
  border: none;
  color: var(--alias-color-icon-tertiary, #737373);
  cursor: pointer;
  width: 40px;
  height: 40px;
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
  position: relative;
}
.sidebar-toggle-btn:hover {
  background-color: var(--alias-color-background-tertiary, #e5e5e5);
  color: var(--alias-color-icon-secondary, #404040);
}

.topbar-center {
  flex: 1;
  display: flex;
  justify-content: center;
  padding: 0 var(--alias-spacing-4xl, 32px);
}

.search-wrap {
  position: relative;
  width: 100%;
  max-width: 562px;
  display: flex;
  align-items: center;
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-full, 9999px);
  padding: 10px var(--alias-spacing-xl, 16px);
  gap: var(--alias-spacing-md, 8px);
  box-sizing: border-box;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}
.search-wrap:focus-within {
  border-color: #d4d4d4;
  box-shadow: 0 1px 2px rgba(10, 13, 18, 0.05);
}

.search-icon {
  color: var(--alias-color-icon-tertiary, #737373);
  flex-shrink: 0;
  transition: color 0.15s ease;
}
.search-wrap:focus-within .search-icon {
  color: var(--alias-color-icon-secondary, #404040);
}

.search-input {
  flex: 1;
  border: none;
  outline: none;
  font-size: var(--alias-font-size-xs, 12px);
  line-height: var(--alias-line-height-xs, 18px);
  color: var(--alias-color-text-secondary, #404040);
  background: transparent;
  padding: 0;
  margin: 0;
}
.search-input::placeholder {
  color: #a1a1a1;
}

.search-shortcut {
  background-color: var(--alias-color-background-primary, #fafafa);
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-sm, 6px);
  height: 20px;
  padding: 0 5px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 1.5px;
  color: var(--alias-color-text-tertiary, #737373);
  font-family: inherit;
  user-select: none;
  flex-shrink: 0;
  box-sizing: border-box;
}

.shortcut-cmd {
  font-size: 11px;
  line-height: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transform: translateY(-0.5px);
}

.shortcut-key {
  font-size: 12px;
  font-weight: 500;
  line-height: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.topbar-right {
  display: flex;
  align-items: center;
  gap: var(--alias-spacing-md, 8px);
}

.header-action-btn {
  background: #ffffff;
  border: none;
  color: var(--alias-color-icon-tertiary, #737373);
  cursor: pointer;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--alias-radius-full, 9999px);
  transition: all 0.15s ease;
  position: relative;
  padding: 0;
}
.header-action-btn:hover {
  background-color: var(--alias-color-background-secondary, #f5f5f5);
  color: var(--alias-color-icon-secondary, #404040);
}

.notification-badge {
  position: absolute;
  top: 5px;
  left: 19px;
  background-color: var(--qmt-badge-solid-error-bg, #c10007);
  color: #ffffff;
  font-size: 9.75px;
  font-weight: 600;
  line-height: 14.6px;
  min-width: 13px;
  height: 13px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 9999px;
  padding: 0 2px;
  box-sizing: border-box;
}

.topbar-divider {
  width: 1px;
  height: 25px;
  background-color: var(--alias-color-border-subtle, #e5e5e5);
  margin: 0 var(--alias-spacing-xl, 16px);
}

.profile-wrapper {
  display: flex;
  align-items: center;
  gap: var(--alias-spacing-md, 8px);
  cursor: pointer;
  padding: 4px 6px;
  border-radius: 8px;
  transition: background-color 0.15s ease;
}
.profile-wrapper:hover {
  background-color: #f5f5f5;
}
.profile-wrapper:hover .profile-chevron {
  color: var(--alias-color-icon-secondary, #404040);
}

.avatar-container {
  position: relative;
  display: flex;
  width: 32px;
  height: 32px;
  flex-shrink: 0;
}

.avatar-img {
  width: 32px;
  height: 32px;
  border-radius: var(--alias-radius-full, 9999px);
  object-fit: cover;
}

.status-indicator {
  position: absolute;
  bottom: 0;
  right: 0;
  width: 8px;
  height: 8px;
  background-color: #12b76a;
  border: 1.5px solid #ffffff;
  border-radius: 4px;
}

.profile-name-text {
  font-size: var(--alias-font-size-xs, 12px);
  font-weight: 400;
  line-height: 18px;
  color: var(--alias-color-text-secondary, #404040);
  white-space: nowrap;
}

.profile-chevron {
  color: var(--alias-color-icon-tertiary, #737373);
  flex-shrink: 0;
  transition: color 0.15s ease;
}

/* PAGE CONTENT */
.page-content { 
  flex: 1; 
  min-height: 0; 
  overflow-y: auto; 
  overflow-x: hidden; 
  padding-top: var(--alias-spacing-2xl, 20px);
  padding-bottom: var(--alias-spacing-4xl, 32px);
  padding-left: var(--alias-spacing-3xl, 24px);
  padding-right: var(--alias-spacing-3xl, 24px);
  background-color: var(--alias-color-background-primary, #fafafa); 
}

/* Custom sleek scrollbars for independent scrolling areas */
.page-content::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

.page-content::-webkit-scrollbar-track {
  background: transparent;
}

.page-content::-webkit-scrollbar-thumb {
  background-color: #e2e8f0;
  border-radius: 9999px;
}

.page-content::-webkit-scrollbar-thumb:hover {
  background-color: #cbd5e1;
}

.page-content {
  scrollbar-width: thin;
  scrollbar-color: #e2e8f0 transparent;
}
</style>
