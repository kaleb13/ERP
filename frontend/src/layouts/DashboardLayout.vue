<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  Box, Search, Maximize, Moon, Languages, Bell, PanelLeft, PanelLeftClose, ChevronDown, ChevronUp, ChevronRight,
  HelpCircle, LayoutDashboard, FileText, Home, Settings, LogOut, ShoppingBag, ShoppingCart, Building2, Users,
  Database, User, Sliders, BarChart3, Utensils, GitBranch
} from 'lucide-vue-next';

const router = useRouter();
const route = useRoute();

// Sidebar state
const isSidebarCollapsed = ref(false);
const sidebarNavRef = ref<HTMLElement | null>(null);

// Dropdown state
const isDropdownOpen = ref(false);
const isSubmenuOpen = ref(false);

// Collapsible group state
const expandedGroups = ref<Record<string, boolean>>({
  'Setup': true,
  'Product & Pricing': true,
  'Items Setup': false
});

const isGroupExpanded = (item: any) => {
  return expandedGroups.value[item.label] !== false; // defaults to true if not specified
};

const toggleGroupExpanded = (label: string) => {
  if (expandedGroups.value[label] === undefined) {
    expandedGroups.value[label] = false;
  } else {
    expandedGroups.value[label] = !expandedGroups.value[label];
  }
};

const toggleSidebar = () => {
  isSidebarCollapsed.value = !isSidebarCollapsed.value;
};

const toggleDropdown = (e: Event) => {
  e.stopPropagation();
  isDropdownOpen.value = !isDropdownOpen.value;
  isSubmenuOpen.value = false; // Reset submenu state on primary toggle
};

const closeDropdown = () => {
  isDropdownOpen.value = false;
  isSubmenuOpen.value = false;
};

const toggleSubmenu = (e: Event) => {
  e.stopPropagation();
  isSubmenuOpen.value = !isSubmenuOpen.value;
};

const openSubmenu = () => {
  isSubmenuOpen.value = true;
};

const closeSubmenu = () => {
  isSubmenuOpen.value = false;
};

const navigateToModule = (routePath: string) => {
  closeDropdown();
  router.push(routePath);
};

const handleLogout = () => {
  closeDropdown();
  alert('Successfully logged out of Haleta ERP!');
  router.push('/home');
};

const handleScroll = (e: Event) => {
  const target = e.target as HTMLElement;
  sessionStorage.setItem('erp_sidebar_scroll', target.scrollTop.toString());
};

// Define icons map for lucide-vue-next
const iconsMap: Record<string, any> = {
  Box,
  ShoppingBag,
  ShoppingCart,
  Building2,
  LayoutDashboard,
  PanelLeft,
  Users,
  Database,
  User,
  Sliders,
  FileText,
  BarChart3,
  Utensils,
  GitBranch
};

// Compute current active module
const activeModule = computed(() => {
  const path = route.path;
  if (path.startsWith('/sales')) {
    return {
      id: 'sales',
      name: 'Sales',
      icon: 'ShoppingBag',
      iconColor: 'var(--primitive-color-orange-500)',
      iconBg: 'var(--primitive-color-orange-50)',
      menu: [
        {
          label: 'Setup',
          icon: 'Database',
          isGroup: true,
          children: [
            { to: '/sales/customers', label: 'Customer', icon: 'User' },
            { to: '/sales/customer-groups', label: 'Customer Group', icon: 'Users' }
          ]
        }
      ]
    };
  } else if (path.startsWith('/buying')) {
    return {
      id: 'buying',
      name: 'Buying',
      icon: 'ShoppingCart',
      iconColor: 'var(--primitive-color-emerald-500)',
      iconBg: 'var(--primitive-color-emerald-50)',
      menu: [
        { to: '/buying', label: 'Suppliers', icon: 'ShoppingCart' }
      ]
    };
  } else if (path.startsWith('/company-setup')) {
    return {
      id: 'company-setup',
      name: 'Company Setup',
      icon: 'Building2',
      iconColor: 'var(--primitive-color-neutral-500)',
      iconBg: 'var(--primitive-color-neutral-100)',
      menu: [
        { to: '/company-setup', label: 'Entities & Employees', icon: 'Building2' }
      ]
    };
  } else {
    // Inventory module (default)
    return {
      id: 'inventory',
      name: 'Inventory',
      icon: 'Box',
      iconColor: 'var(--primitive-color-blue-500)',
      iconBg: 'var(--primitive-color-blue-50)',
      menu: [
        { to: '/dashboard', label: 'Dashboard', icon: 'LayoutDashboard' },
        { to: '/stock-summary', label: 'Stock Summary', icon: 'BarChart3' },
        { to: '/gate-pass', label: 'Gate Pass', icon: 'PanelLeft', rotate: true },
        { to: '/stock-reservation', label: 'Stock Reservation', icon: 'FileText' },
        { isHeader: true, label: 'PRODUCT SETUP' },
        {
          label: 'Product & Pricing',
          icon: 'ShoppingBag',
          isGroup: true,
          children: [
            { to: '/inventory/product-group', label: 'Product Group', icon: 'Database' },
            { to: '/inventory/products', label: 'Products', icon: 'Box' },
            { to: '/inventory/product-variants', label: 'Product Variants', icon: 'GitBranch' },
            { to: '/inventory/product-modifiers', label: 'Product Modifiers', icon: 'Utensils' },
            { to: '/inventory/product-attribute', label: 'Product Attribute', icon: 'Sliders' }
          ]
        },
        {
          label: 'Items Setup',
          icon: 'Box',
          isGroup: true,
          children: []
        },
        { isHeader: true, label: 'TENANT SETUP' },
        { to: '/inventory/locations', label: 'Locations', icon: 'Building2' }
      ]
    };
  }
});

onMounted(() => {
  window.addEventListener('click', closeDropdown);
  if (sidebarNavRef.value) {
    const savedScroll = sessionStorage.getItem('erp_sidebar_scroll');
    if (savedScroll) {
      setTimeout(() => {
        if (sidebarNavRef.value) sidebarNavRef.value.scrollTop = parseInt(savedScroll, 10);
      }, 10);
    }
    sidebarNavRef.value.addEventListener('scroll', handleScroll);
  }
});

onUnmounted(() => {
  window.removeEventListener('click', closeDropdown);
  if (sidebarNavRef.value) {
    sidebarNavRef.value.removeEventListener('scroll', handleScroll);
  }
});
</script>

<template>
  <div class="erp-layout">
    <!-- SIDEBAR -->
    <aside :class="['sidebar', { collapsed: isSidebarCollapsed }]">
      <!-- Sidebar Header -->
      <div class="sidebar-header-wrapper">
        <div class="sidebar-brand-badge" @click="toggleDropdown">
          <div class="logo-box" :style="{ backgroundColor: activeModule.iconBg }">
            <component 
              :is="iconsMap[activeModule.icon] || Box" 
              class="logo-icon" 
              :style="{ color: activeModule.iconColor }" 
              :size="20" 
            />
          </div>
          <div class="brand-info">
            <h1 class="brand-title">{{ activeModule.name }}</h1>
            <p class="brand-subtitle">Haleta ERP</p>
          </div>
          <div class="app-switcher ml-auto">
            <ChevronUp :size="10" class="text-gray-400" />
            <ChevronDown :size="10" class="text-gray-400" />
          </div>

          <!-- DROPDOWN PORTAL MENU -->
          <div 
            v-if="isDropdownOpen" 
            class="brand-dropdown-menu" 
            @click.stop
            @mouseleave="closeSubmenu"
          >
            <!-- Home -->
            <router-link to="/home" class="dropdown-item" @click="closeDropdown">
              <Home :size="16" class="dropdown-icon text-gray-500" />
              <span class="dropdown-text">Home</span>
            </router-link>

            <!-- Modules with Arrow (Triggers Submenu) -->
            <div 
              class="dropdown-item has-submenu" 
              :class="{ 'submenu-active': isSubmenuOpen }"
              @mouseenter="openSubmenu"
              @click="toggleSubmenu"
            >
              <Box :size="16" class="dropdown-icon text-gray-500" />
              <span class="dropdown-text">Modules</span>
              <ChevronRight :size="14" class="ml-auto text-gray-400" />

              <!-- SUBMENU (positioned absolutely to the right) -->
              <div v-if="isSubmenuOpen" class="brand-submenu-menu" @click.stop>
                <div class="submenu-item" @click="navigateToModule('/dashboard')">
                  <div class="submenu-icon-box" style="background-color: #eff6ff;">
                    <Box :size="14" style="color: #2563eb;" />
                  </div>
                  <span class="submenu-text">Inventory</span>
                  <ChevronRight :size="12" class="ml-auto text-gray-400" />
                </div>

                <div class="submenu-item" @click="navigateToModule('/sales')">
                  <div class="submenu-icon-box" style="background-color: #fff7ed;">
                    <ShoppingBag :size="14" style="color: #f97316;" />
                  </div>
                  <span class="submenu-text">Sales</span>
                </div>

                <div class="submenu-item" @click="navigateToModule('/buying')">
                  <div class="submenu-icon-box" style="background-color: #ecfdf5;">
                    <ShoppingCart :size="14" style="color: #10b981;" />
                  </div>
                  <span class="submenu-text">Buying</span>
                </div>

                <div class="submenu-item" @click="navigateToModule('/company-setup')">
                  <div class="submenu-icon-box" style="background-color: #f3f4f6;">
                    <Building2 :size="14" style="color: #6b7280;" />
                  </div>
                  <span class="submenu-text">Company Setup</span>
                </div>
              </div>
            </div>

            <!-- Settings -->
            <router-link to="/settings" class="dropdown-item" @click="closeDropdown">
              <Settings :size="16" class="dropdown-icon text-gray-500" />
              <span class="dropdown-text">Settings</span>
            </router-link>

            <!-- Help -->
            <router-link to="/help" class="dropdown-item" @click="closeDropdown">
              <HelpCircle :size="16" class="dropdown-icon text-gray-500" />
              <span class="dropdown-text">Help</span>
            </router-link>

            <!-- Divider -->
            <div class="dropdown-divider"></div>

            <!-- Logout -->
            <button class="dropdown-item logout-btn" @click="handleLogout">
              <LogOut :size="16" class="dropdown-icon text-red-500" />
              <span class="dropdown-text text-red-600 font-semibold">Logout</span>
            </button>
          </div>
        </div>
      </div>

      <nav class="sidebar-nav" ref="sidebarNavRef">
        <div class="nav-section-title">MENU</div>
        <ul>
          <li v-for="item in activeModule.menu" :key="item.label">
            <!-- HEADER SECTION -->
            <template v-if="item.isHeader">
              <div v-if="!isSidebarCollapsed" class="nav-section-title mt-6">
                {{ item.label }}
              </div>
            </template>

            <!-- REGULAR MENU ITEMS -->
            <template v-else>
              <!-- COLLAPSED SIDEBAR -->
              <template v-if="isSidebarCollapsed">
                <div v-if="item.isGroup && item.children && item.children.length > 0" class="nav-group-collapsed">
                  <div v-for="child in item.children" :key="child.to" class="collapsed-item-wrapper">
                    <router-link :to="child.to" class="nav-item" active-class="active" :title="child.label">
                      <component :is="iconsMap[child.icon] || Users" :size="18" class="nav-icon" />
                    </router-link>
                  </div>
                </div>
                <router-link v-else-if="!item.isGroup" :to="item.to" class="nav-item" active-class="active" :title="item.label">
                  <component :is="iconsMap[item.icon] || LayoutDashboard" :size="18" class="nav-icon" />
                </router-link>
              </template>

              <!-- EXPANDED SIDEBAR -->
              <template v-else>
                <!-- Simple Link -->
                <router-link v-if="!item.isGroup" :to="item.to" class="nav-item" active-class="active">
                  <component :is="iconsMap[item.icon] || LayoutDashboard" :size="18" :class="['nav-icon', { 'rotate-90': item.rotate }]" />
                  <span class="nav-text">{{ item.label }}</span>
                </router-link>

                <!-- Collapsible Group -->
                <div v-else class="nav-group">
                  <div class="nav-group-header" @click="toggleGroupExpanded(item.label)">
                    <div class="nav-group-header-left">
                      <component :is="iconsMap[item.icon] || Database" :size="18" class="nav-icon" />
                      <span class="nav-text">{{ item.label }}</span>
                    </div>
                    <ChevronDown :size="14" class="nav-group-chevron" :class="{ 'collapsed-chevron': !isGroupExpanded(item) }" />
                  </div>
                  <ul v-show="isGroupExpanded(item)" class="nav-group-children">
                    <li v-for="child in item.children" :key="child.to">
                      <router-link :to="child.to" class="nav-child-item" active-class="active">
                        <component :is="iconsMap[child.icon] || Users" :size="16" class="nav-icon" />
                        <span class="nav-text">{{ child.label }}</span>
                      </router-link>
                    </li>
                  </ul>
                </div>
              </template>
            </template>
          </li>
        </ul>

        <!-- Sidebar Footer Actions -->
        <div class="sidebar-bottom-actions mt-auto">
          <router-link to="/settings" class="nav-item">
            <HelpCircle :size="18" class="nav-icon" />
            <span class="nav-text">Settings</span>
          </router-link>
          <router-link to="/help" class="nav-item">
            <HelpCircle :size="18" class="nav-icon" />
            <span class="nav-text">Help</span>
          </router-link>
        </div>
      </nav>
    </aside>

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
          <button class="btn-icon"><Maximize :size="18" /></button>
          <button class="btn-icon"><Moon :size="18" /></button>
          <button class="btn-icon"><Languages :size="18" /></button>
          <button class="btn-icon relative mr-2">
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
.sidebar.collapsed { width: 68px; }

.sidebar-header-wrapper {
  height: 84px;
  display: flex;
  align-items: flex-start;
  padding: 6px 16px 0 16px;
  transition: padding 0.3s ease;
}
.sidebar.collapsed .sidebar-header-wrapper {
  padding: 6px 0 0 0;
  justify-content: center;
}
.sidebar-brand-badge {
  display: flex;
  align-items: center;
  gap: 12px;
  height: 56px;
  padding: 0 14px;
  background-color: #fafafa;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  position: relative;
  cursor: pointer;
  width: 100%;
  transition: all 0.3s ease;
}
.sidebar-brand-badge:hover {
  background-color: #ffffff;
  border-color: #d1d5db;
}
.sidebar.collapsed .sidebar-brand-badge {
  width: 46px;
  height: 46px;
  padding: 0;
  justify-content: center;
  border-radius: 10px;
  gap: 0;
}
.logo-box {
  background: #f3f4f6;
  padding: 6px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.brand-info { 
  flex: 1; 
  line-height: 1.2; 
  transition: all 0.3s ease;
  white-space: nowrap;
  overflow: hidden;
  opacity: 1;
}

.sidebar.collapsed .brand-info {
  width: 0;
  flex: 0 0 0;
  min-width: 0;
  opacity: 0;
  margin: 0;
  padding: 0;
  pointer-events: none;
  transform: translateX(-10px);
}

.brand-title { font-size: 14px; font-weight: 700; color: #0f172a; margin: 0; }
.brand-subtitle { font-size: 11px; font-weight: 400; color: #475569; margin: 0; }

.app-switcher { 
  display: flex; 
  flex-direction: column; 
  align-items: center; 
  cursor: pointer;
  transition: all 0.3s ease;
  opacity: 1;
}

.sidebar.collapsed .app-switcher {
  width: 0;
  height: 0;
  flex: 0 0 0;
  min-width: 0;
  margin: 0;
  padding: 0;
  opacity: 0;
  overflow: hidden;
  pointer-events: none;
}

/* NAV */
.sidebar-nav { 
  flex: 1; 
  padding: 20px 12px; 
  overflow-y: auto; 
  transition: padding 0.3s ease; 
  display: flex;
  flex-direction: column;
}
.sidebar.collapsed .sidebar-nav {
  padding: 20px 0;
  align-items: center;
}
.nav-section-title { 
  font-size: 11px; 
  font-weight: 700; 
  color: #9ca3af; 
  margin-bottom: 8px; 
  padding-left: 12px;
  letter-spacing: 0.05em;
  transition: opacity 0.3s ease;
}
.sidebar.collapsed .nav-section-title {
  opacity: 0;
  height: 0;
  margin: 0;
  overflow: hidden;
}
.mt-6 { margin-top: 24px; }
.mt-auto { margin-top: auto; }
.rotate-90 { transform: rotate(90deg); }

ul { list-style: none; padding: 0; margin: 0; }
.nav-item {
  display: flex;
  align-items: center;
  padding: 10px 12px;
  gap: 12px;
  border-radius: 6px;
  cursor: pointer;
  color: #4b5563;
  margin-bottom: 2px;
  text-decoration: none;
  transition: all 0.2s ease;
}
.nav-item:hover { background: #f3f4f6; color: #111827; }
.nav-item.active { background: #f3f4f6; color: #111827; font-weight: 600; }
.nav-item.active .nav-icon { color: #111827; }

.sidebar.collapsed .nav-item {
  width: 44px;
  height: 44px;
  padding: 0;
  justify-content: center;
  margin-bottom: 8px;
  gap: 0;
}
.nav-icon { flex-shrink: 0; transition: transform 0.2s; }
.nav-text { 
  font-size: 13px;
  transition: all 0.3s ease;
  white-space: nowrap;
  overflow: hidden;
  opacity: 1;
}

.sidebar.collapsed .nav-text {
  width: 0;
  opacity: 0;
  pointer-events: none;
  transform: translateX(-10px);
}

.sidebar-bottom-actions {
  padding-top: 20px;
  border-top: 1px solid #f3f4f6;
  margin-top: auto;
}
.sidebar.collapsed .sidebar-bottom-actions {
  border-top: none;
}

/* SIDEBAR FOOTER */
.sidebar-footer { padding: 12px; border-top: 1px solid #e5e5e5; }
.sidebar.collapsed .sidebar-footer { padding: 12px 8px; }
.avatar-sm { width: 28px; height: 28px; border-radius: 50%; object-fit: cover; border: 1.5px solid #ffffff; box-shadow: 0 0 0 1px #e5e7eb; }

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
  position: relative; /* Establishes positioning context for notification badge */
}
.btn-icon:hover {
  color: #111827;
  background-color: #f3f4f6;
}

.topbar-left {
  position: relative;
  z-index: 50; /* Bring it above topbar-center and the search bar */
  display: flex;
  align-items: center;
}

.sidebar-toggle-btn {
  background-color: transparent; /* Transparent background by default */
  border: none; /* No border by default */
  color: #6b7280; /* Neutral grey icon matching right-side icons */
  cursor: pointer;
  width: 38px;
  height: 38px;
  border-radius: 10px; /* Same rounded shape as the icons on the right */
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  position: relative;
}
.sidebar-toggle-btn:hover {
  color: #111827; /* Darker icon on hover */
  background-color: #f3f4f6; /* Same soft hover background as the right-side icons */
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
  transform: translateX(-1.5px); /* Smooth slide-in of the left chevron */
}

.sidebar-toggle-btn:hover .chevron-right-path.show-arrow {
  opacity: 1;
  transform: translateX(1.5px); /* Smooth slide-in of the right chevron */
}

/* Tooltip styles */
.sidebar-toggle-btn::after {
  content: attr(data-tooltip);
  position: absolute;
  left: calc(100% + 12px);
  top: 50%;
  transform: translateY(-50%) scale(0.95);
  background-color: #18181b; /* Bold black background */
  color: #ffffff; /* Clean white text */
  padding: 6px 12px;
  border-radius: 8px; /* Clean modern corner roundness */
  font-size: 12px;
  font-weight: 500;
  white-space: nowrap;
  pointer-events: none;
  opacity: 0;
  transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.2), 0 4px 6px -2px rgba(0, 0, 0, 0.1);
  border: none;
  z-index: 99999; /* Higher z-index to overlay above search bar elements */
}

.sidebar-toggle-btn::before {
  content: '';
  position: absolute;
  left: calc(100% + 12px); /* Aligns perfectly with the left border of the tooltip box */
  margin-left: -4px; /* Centers the rotated square exactly on the boundary edge */
  top: 50%;
  transform: translateY(-50%) rotate(45deg);
  width: 8px;
  height: 8px;
  background-color: #18181b; /* Matches black background */
  pointer-events: none;
  opacity: 0;
  transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
  z-index: 99999; /* Higher z-index to overlay above search bar elements */
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

/* PAGE CONTENT */
.page-content { flex: 1; overflow-y: auto; padding: 16px; background-color: #fafafa; }

/* BRAND SWITCHER DROPDOWN MENU */
.brand-dropdown-menu {
  position: absolute;
  top: calc(100% + 8px);
  left: 0;
  width: 226px;
  background-color: #fafafa;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
  z-index: 999;
  padding: 6px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  animation: dropFade 0.2s ease-out;
}

@keyframes dropFade {
  from { opacity: 0; transform: translateY(-5px); }
  to { opacity: 1; transform: translateY(0); }
}

.sidebar.collapsed .brand-dropdown-menu {
  width: 190px;
  left: 0;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  border-radius: 8px;
  color: #475569;
  text-decoration: none;
  font-size: 13px;
  font-weight: 500;
  border: none;
  background: none;
  width: 100%;
  text-align: left;
  cursor: pointer;
  transition: all 0.15s ease;
}

.dropdown-item:hover {
  background-color: #ffffff;
  color: #0f172a;
}

.dropdown-icon {
  flex-shrink: 0;
}

.dropdown-text {
  white-space: nowrap;
}

.dropdown-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 4px 6px;
}

.logout-btn:hover {
  background-color: #fef2f2 !important;
}

/* SUBMENU SYSTEM */
.has-submenu {
  position: relative;
}

.brand-submenu-menu {
  position: absolute;
  top: 0;
  left: calc(100% + 8px);
  width: 226px;
  background-color: #fafafa;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
  z-index: 1000;
  padding: 6px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  animation: subFade 0.15s ease-out;
}

@keyframes subFade {
  from { opacity: 0; transform: translateX(-5px); }
  to { opacity: 1; transform: translateX(0); }
}

.submenu-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  border-radius: 8px;
  color: #475569;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
}

.submenu-item:hover {
  background-color: #ffffff;
  color: #0f172a;
}

.submenu-icon-box {
  width: 26px;
  height: 26px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.submenu-text {
  font-weight: 500;
}

.ml-auto {
  margin-left: auto;
}

/* Collapsible Menu Group Styling */
.nav-group {
  display: flex;
  flex-direction: column;
  gap: 2px;
  margin-bottom: 2px;
}

.nav-group-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  border-radius: 6px;
  cursor: pointer;
  color: #4b5563;
  transition: all 0.2s ease;
  user-select: none;
}

.nav-group-header:hover {
  background: #f3f4f6;
  color: #111827;
}

.nav-group-header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.nav-group-chevron {
  color: #9ca3af;
  transition: transform 0.2s ease;
}

.nav-group-chevron.collapsed-chevron {
  transform: rotate(-90deg);
}

.nav-group-children {
  list-style: none;
  padding: 2px 0 2px 8px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-left: 20px;
  border-left: 1.5px solid #f1f5f9;
}

.nav-child-item {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  gap: 10px;
  border-radius: 8px;
  cursor: pointer;
  color: #4b5563;
  text-decoration: none;
  transition: all 0.2s ease;
}

.nav-child-item:hover {
  background: #f3f4f6;
  color: #111827;
}

.nav-child-item.active {
  background: #ffffff;
  color: #0f172a;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
  border: 1px solid #e2e8f0;
  font-weight: 600;
}

.nav-child-item.active .nav-icon {
  color: #0f172a;
}

.nav-group-collapsed {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  width: 100%;
}

.collapsed-item-wrapper {
  display: flex;
  justify-content: center;
  width: 100%;
}
</style>
