<script setup lang="ts">
import { ref } from 'vue';
import { 
  Search, Maximize, Moon, Languages, Bell, ChevronDown
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
      <!-- TOP BAR -->
      <header class="topbar">
        <div class="topbar-left">
          <button 
            @click="toggleSidebar" 
            class="sidebar-toggle-btn" 
            :data-tooltip="isSidebarCollapsed ? 'Open sidebar' : 'Close sidebar'"
          >
            <svg 
              xmlns="http://www.w3.org/2000/svg" 
              width="18" 
              height="18" 
              viewBox="0 0 24 24" 
              fill="none" 
              stroke="currentColor" 
              stroke-width="2.2" 
              stroke-linecap="round" 
              stroke-linejoin="round" 
              class="panel-toggle-svg"
            >
              <rect width="18" height="18" x="3" y="3" rx="4.5" ry="4.5" />
              <path d="M9 3v18" />
              <!-- Left arrow (points left, visible when expanded and hovered, centered in right side pane) -->
              <path 
                d="m15.5 15-3-3 3-3" 
                class="chevron-left-path" 
                :class="{ 'show-arrow': !isSidebarCollapsed }"
              />
              <!-- Right arrow (points right, visible when collapsed and hovered, centered in right side pane) -->
              <path 
                d="m13.5 9 3 3-3 3" 
                class="chevron-right-path" 
                :class="{ 'show-arrow': isSidebarCollapsed }"
              />
            </svg>
          </button>
        </div>
        
        <div class="topbar-center">
          <div class="search-wrap">
            <Search :size="16" class="search-icon" />
            <input type="text" placeholder="Search Everything..." class="search-input" />
            <div class="search-hint">/</div>
          </div>
        </div>

        <div class="topbar-right">
          <button class="btn-icon" title="Fullscreen"><Maximize :size="18" /></button>
          <button class="btn-icon" title="Dark Mode"><Moon :size="18" /></button>
          <button class="btn-icon" title="Language"><Languages :size="18" /></button>
          <button class="btn-icon relative mr-2" title="Notifications">
            <Bell :size="18" />
            <span class="notification-badge">2</span>
          </button>
          
          <div class="topbar-separator"></div>
          
          <div class="profile-wrapper">
            <div class="avatar-container">
              <img src="https://i.pravatar.cc/100?img=5" alt="Profile" class="avatar-sm" />
              <span class="status-indicator"></span>
            </div>
            <div class="profile-info-text">
              <span class="profile-name-text">Marta Tadesse</span>
            </div>
            <ChevronDown :size="14" class="text-gray-400" />
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

/* TOP BAR */
.topbar {
  height: 64px;
  flex-shrink: 0;
  background-color: #ffffff;
  border-bottom: 1px solid #e5e5e5;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  z-index: 50;
}
.topbar-center { flex: 1; display: flex; justify-content: center; padding: 0 40px; }
.search-wrap {
  position: relative;
  width: 100%;
  max-width: 600px;
}
.search-input {
  width: 100%;
  padding: 9px 12px 9px 38px;
  border: 1px solid #e5e7eb;
  border-radius: 24px;
  font-size: 13px;
  outline: none;
  background: #fafafa;
  transition: all 0.2s ease;
}
.search-input:focus { border-color: #d1d5db; background: #ffffff; box-shadow: 0 0 0 4px rgba(0,0,0,0.02); }
.search-icon { position: absolute; left: 14px; top: 50%; transform: translateY(-50%); color: #9ca3af; z-index: 10; }

.topbar-right { display: flex; align-items: center; gap: 8px; }
.btn-icon {
  background: none;
  border: none;
  color: #6b7280;
  cursor: pointer;
  padding: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  transition: all 0.2s;
  position: relative;
}
.btn-icon:hover {
  color: #111827;
  background-color: #f3f4f6;
}

.topbar-left {
  position: relative;
  z-index: 50;
  display: flex;
  align-items: center;
}

.sidebar-toggle-btn {
  background-color: transparent;
  border: none;
  color: #6b7280;
  cursor: pointer;
  width: 38px;
  height: 38px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  position: relative;
}
.sidebar-toggle-btn:hover {
  color: #111827;
  background-color: #f3f4f6;
}

/* Custom interactive arrow paths within inline SVG */
.chevron-left-path,
.chevron-right-path {
  opacity: 0;
  transform: translateX(0);
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.sidebar-toggle-btn:hover .chevron-left-path.show-arrow {
  opacity: 1;
  transform: translateX(-1.5px);
}

.sidebar-toggle-btn:hover .chevron-right-path.show-arrow {
  opacity: 1;
  transform: translateX(1.5px);
}

/* Tooltip styles */
.sidebar-toggle-btn::after {
  content: attr(data-tooltip);
  position: absolute;
  left: calc(100% + 12px);
  top: 50%;
  transform: translateY(-50%) scale(0.95);
  background-color: #18181b;
  color: #ffffff;
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 500;
  white-space: nowrap;
  pointer-events: none;
  opacity: 0;
  transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.2), 0 4px 6px -2px rgba(0, 0, 0, 0.1);
  border: none;
  z-index: 99999;
}

.sidebar-toggle-btn::before {
  content: '';
  position: absolute;
  left: calc(100% + 12px);
  margin-left: -4px;
  top: 50%;
  transform: translateY(-50%) rotate(45deg);
  width: 8px;
  height: 8px;
  background-color: #18181b;
  pointer-events: none;
  opacity: 0;
  transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
  z-index: 99999;
}

.sidebar-toggle-btn:hover::after,
.sidebar-toggle-btn:hover::before {
  opacity: 1;
}

.sidebar-toggle-btn:hover::before {
  transform: translateY(-50%) scale(1) rotate(45deg);
}

.sidebar-toggle-btn:hover::after {
  transform: translateY(-50%) scale(1);
}

.search-hint {
  position: absolute;
  right: 14px;
  top: 50%;
  transform: translateY(-50%);
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  padding: 1px 6px;
  font-size: 11px;
  color: #9ca3af;
  pointer-events: none;
}

.notification-badge {
  position: absolute;
  top: 4px;
  right: 4px;
  background: #ef4444;
  color: white;
  font-size: 9px;
  min-width: 15px;
  height: 15px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  font-weight: 700;
  border: 1.5px solid #ffffff;
}

.topbar-separator {
  width: 1px;
  height: 20px;
  background-color: #e5e7eb;
  margin: 0 12px;
}

.profile-wrapper {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 10px;
  transition: background 0.2s;
}
.profile-wrapper:hover {
  background-color: #f3f4f6;
}

.avatar-container {
  position: relative;
  display: flex;
}

.status-indicator {
  position: absolute;
  bottom: 0;
  right: 0;
  width: 8px;
  height: 8px;
  background-color: #10b981;
  border: 1.5px solid #ffffff;
  border-radius: 50%;
}

.profile-info-text {
  display: flex;
  flex-direction: column;
}

.profile-name-text {
  font-size: 13px;
  font-weight: 500;
  color: #374151;
}

.avatar-sm { width: 28px; height: 28px; border-radius: 50%; object-fit: cover; border: 1.5px solid #ffffff; box-shadow: 0 0 0 1px #e5e7eb; }

/* PAGE CONTENT */
.page-content { 
  flex: 1; 
  min-height: 0; 
  overflow-y: auto; 
  overflow-x: hidden; 
  padding: 16px; 
  background-color: #fafafa; 
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
