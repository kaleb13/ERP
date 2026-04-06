<script setup lang="ts">
import { ref } from 'vue';
import { 
  Building2, Monitor, ArrowLeftRight, Settings, Grid, 
  Search, Maximize, Moon, Languages, Bell, PanelLeftClose, ChevronDown, ChevronUp, ChevronRight
} from 'lucide-vue-next';

// Sidebar state
const isSidebarCollapsed = ref(false);

const toggleSidebar = () => {
  isSidebarCollapsed.value = !isSidebarCollapsed.value;
};
</script>

<template>
  <div class="erp-layout">
    <!-- SIDEBAR -->
    <aside :class="['sidebar', { collapsed: isSidebarCollapsed }]">
      <!-- Sidebar Header -->
      <div class="sidebar-header">
        <div class="logo-box">
          <Box class="logo-icon text-orange-400" :size="24" />
        </div>
        <div class="brand-info" v-if="!isSidebarCollapsed">
          <h1 class="brand-title">Haleta ERP</h1>
          <p class="brand-subtitle">Module Name</p>
        </div>
        <div class="app-switcher" v-if="!isSidebarCollapsed">
          <ChevronUp :size="12" class="text-gray-400" />
          <ChevronDown :size="12" class="text-gray-400" />
        </div>
      </div>

      <!-- Navigation -->
      <nav class="sidebar-nav">
        <div class="nav-section" v-if="!isSidebarCollapsed">ENTITY SETUP</div>
        <ul>
          <li class="nav-item">
            <Building2 :size="18" class="nav-icon" />
            <span class="nav-text" v-if="!isSidebarCollapsed">Business Group</span>
          </li>
          <li class="nav-item active">
            <Building2 :size="18" class="nav-icon" />
            <span class="nav-text" v-if="!isSidebarCollapsed">Organization</span>
          </li>
          <li class="nav-item">
            <Grid :size="18" class="nav-icon" />
            <span class="nav-text" v-if="!isSidebarCollapsed">Branch</span>
          </li>
        </ul>

        <div class="nav-section mt-6" v-if="!isSidebarCollapsed">SETTINGS</div>
        <ul>
          <li class="nav-item">
            <Settings :size="18" class="nav-icon" />
            <span class="nav-text" v-if="!isSidebarCollapsed">Settings</span>
          </li>
        </ul>
      </nav>

      <!-- Bottom Profile -->
      <div class="sidebar-footer">
        <div class="profile-compact">
          <img src="https://i.pravatar.cc/100?img=1" alt="Profile" class="avatar" />
          <div class="profile-info" v-if="!isSidebarCollapsed">
            <p class="profile-name">Asrat Zemedkun</p>
            <p class="profile-email">Asratz@gmail.com</p>
          </div>
          <ChevronRight :size="16" class="ml-auto text-gray-400" v-if="!isSidebarCollapsed" />
        </div>
      </div>
    </aside>

    <!-- MAIN CONTENT -->
    <main class="main-wrapper">
      <!-- TOP BAR -->
      <header class="topbar">
        <div class="topbar-left">
          <button @click="toggleSidebar" class="sidebar-toggle btn-icon">
            <PanelLeftClose :size="20" />
          </button>
        </div>
        
        <div class="topbar-center">
          <div class="search-wrap">
            <Search :size="16" class="search-icon" />
            <input type="text" placeholder="Search Everything..." class="search-input" />
          </div>
        </div>

        <div class="topbar-right">
          <button class="btn-icon"><Maximize :size="18" /></button>
          <button class="btn-icon"><Moon :size="18" /></button>
          <button class="btn-icon"><Languages :size="18" /></button>
          <button class="btn-icon relative">
            <Bell :size="18" />
            <span class="notification-dot">2</span>
          </button>
          <img src="https://i.pravatar.cc/100?img=1" alt="Profile" class="avatar-sm ml-2" />
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
  width: 100vw;
  background-color: #fafafa;
  overflow: hidden;
  font-family: 'Inter', sans-serif;
}

/* SIDEBAR */
.sidebar {
  width: 260px;
  background-color: #ffffff;
  border-right: 1px solid #e5e5e5;
  display: flex;
  flex-direction: column;
  transition: width 0.3s ease;
  z-index: 100;
}
.sidebar.collapsed { width: 80px; }

.sidebar-header {
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 12px;
  border-bottom: 1px solid transparent;
}
.logo-box {
  background: #fff8eb;
  padding: 8px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.brand-info { flex: 1; }
.brand-title { font-size: 15px; font-weight: 700; color: #111827; margin: 0; }
.brand-subtitle { font-size: 11px; color: #6b7280; margin: 0; }
.app-switcher { display: flex; flex-direction: column; align-items: center; cursor: pointer; }

/* NAV */
.sidebar-nav { flex: 1; padding: 20px 12px; overflow-y: auto; }
.nav-section { font-size: 10px; font-weight: 700; color: #9ca3af; margin-bottom: 8px; padding-left: 12px; }
.mt-6 { margin-top: 24px; }
ul { list-style: none; padding: 0; margin: 0; }
.nav-item {
  display: flex;
  align-items: center;
  padding: 10px 12px;
  gap: 12px;
  border-radius: 6px;
  cursor: pointer;
  color: #4b5563;
  margin-bottom: 4px;
}
.nav-item:hover { background: #f3f4f6; }
.nav-item.active { background: #eff6ff; color: #1d4ed8; font-weight: 600; }
.nav-icon { flex-shrink: 0; }
.nav-text { font-size: 13px; }

/* SIDEBAR FOOTER */
.sidebar-footer { padding: 16px; border-top: 1px solid #e5e5e5; }
.profile-compact { display: flex; align-items: center; gap: 12px; cursor: pointer; }
.avatar { width: 32px; height: 32px; border-radius: 50%; object-fit: cover; }
.avatar-sm { width: 28px; height: 28px; border-radius: 50%; object-fit: cover; }
.profile-info { flex: 1; }
.profile-name { font-size: 13px; font-weight: 600; color: #111827; margin: 0; }
.profile-email { font-size: 11px; color: #6b7280; margin: 0; }

/* MAIN CONTENT */
.main-wrapper { flex: 1; display: flex; flex-direction: column; overflow: hidden; background-color: #fafafa; }

/* TOP BAR */
.topbar {
  height: 64px;
  background-color: #ffffff;
  border-bottom: 1px solid #e5e5e5;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
}
.topbar-center { flex: 1; display: flex; justify-content: center; }
.search-wrap {
  position: relative;
  width: 400px;
}
.search-input {
  width: 100%;
  padding: 8px 12px 8px 36px;
  border: 1px solid #e5e5e5;
  border-radius: 20px;
  font-size: 13px;
  outline: none;
  background: #fafafa;
}
.search-input:focus { border-color: #d1d5db; background: #ffffff; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }

.topbar-right { display: flex; align-items: center; gap: 16px; }
.btn-icon { background: none; border: none; color: #4b5563; cursor: pointer; padding: 4px; }
.btn-icon:hover { color: #111827; }
.notification-dot {
  position: absolute; top: 0; right: 0; background: #ef4444; color: white;
  font-size: 9px; padding: 2px 4px; border-radius: 10px; font-weight: bold;
}

/* PAGE CONTENT */
.page-content { flex: 1; overflow-y: auto; padding: 24px; }
</style>
