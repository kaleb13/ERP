<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  Box, ChevronDown, ChevronUp, ChevronRight,
  HelpCircle, LayoutDashboard, FileText, Home, Settings, LogOut, ShoppingBag, ShoppingCart, Building2, Users,
  UserCheck, LayoutGrid, Database, User, Sliders, BarChart3, Utensils, GitBranch, ShieldCheck, Key,
  Briefcase, Layers, Award, GitPullRequest, PanelLeft, FolderTree, Network, GraduationCap, BadgeCheck
} from 'lucide-vue-next';

interface Props {
  collapsed?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  collapsed: false
});

const emit = defineEmits<{
  (e: 'update:collapsed', value: boolean): void;
}>();

const router = useRouter();
const route = useRoute();

const sidebarNavRef = ref<HTMLElement | null>(null);

// Dropdown state
const isDropdownOpen = ref(false);
const isSubmenuOpen = ref(false);

// Collapsible group state
const expandedGroups = ref<Record<string, boolean>>({
  'Setup': true,
  'Product & Pricing': true,
  'User And Access': true,
  'Items Setup': false
});

const isGroupExpanded = (item: any) => {
  return expandedGroups.value[item.label] !== false; // defaults to true
};

const toggleGroupExpanded = (label: string) => {
  if (expandedGroups.value[label] === undefined) {
    expandedGroups.value[label] = false;
  } else {
    expandedGroups.value[label] = !expandedGroups.value[label];
  }
};

const toggleDropdown = (e: Event) => {
  e.stopPropagation();
  isDropdownOpen.value = !isDropdownOpen.value;
  isSubmenuOpen.value = false;
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
  LayoutGrid,
  PanelLeft,
  Users,
  UserCheck,
  Database,
  User,
  Sliders,
  FileText,
  BarChart3,
  Utensils,
  GitBranch,
  ShieldCheck,
  Key,
  Briefcase,
  Layers,
  Award,
  GitPullRequest,
  FolderTree,
  Network,
  GraduationCap,
  BadgeCheck
};

// Active link matching helper
const isChildActive = (to: string) => {
  if (to.includes('?')) {
    const [pathPart, queryPart] = to.split('?');
    const params = new URLSearchParams(queryPart);
    if (route.path === pathPart) {
      for (const [key, val] of params.entries()) {
        if (route.query[key] !== val) return false;
      }
      return true;
    }
    return false;
  }
  if (route.path === to) {
    if (route.query.tab && route.query.tab !== 'users') {
      return false;
    }
    return true;
  }
  return false;
};

const isGroupActive = (item: any) => {
  if (!item.children) return false;
  return item.children.some((child: any) => isChildActive(child.to));
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
  } else if (path.startsWith('/hr')) {
    return {
      id: 'hr',
      name: 'Human Resources',
      icon: 'Users',
      iconColor: 'var(--primitive-color-indigo-500)',
      iconBg: 'var(--primitive-color-indigo-50)',
      menu: [
        { isHeader: true, label: 'Workforce & Profile' },
        { to: '/hr/employees', label: 'Employee Directory', icon: 'Users' },
        { isHeader: true, label: 'Organization & Structure' },
        { to: '/hr/org-structures', label: 'Org Structures', icon: 'Network' },
        { to: '/hr/org-units', label: 'Organization Units', icon: 'FolderTree' },
        { isHeader: true, label: 'Compensation & Pay' },
        { to: '/hr/salary-scales', label: 'Salary Scales', icon: 'Award' },
        { isHeader: true, label: 'Job & Position Architecture' },
        { to: '/hr/job-positions', label: 'Job Positions', icon: 'Briefcase' },
        { to: '/hr/job-titles', label: 'Job Titles & Roles', icon: 'BadgeCheck' },
        { to: '/hr/job-levels', label: 'Job Levels', icon: 'Layers' }
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
        { isHeader: true, label: 'Menu' },
        { to: '/dashboard', label: 'Dashboard', icon: 'LayoutDashboard' },
        { isHeader: true, label: 'Company setup' },
        { to: '/company-setup?tab=entity_types', label: 'Entity Types', icon: 'LayoutGrid' },
        { to: '/company-setup', label: 'Entity', icon: 'Building2' },
        { isHeader: true, label: 'User And Access' },
        {
          label: 'User And Access',
          icon: 'UserCheck',
          isGroup: true,
          children: [
            { to: '/company-setup/user-and-access', label: 'User', icon: 'User' },
            { to: '/company-setup/user-and-access?tab=roles', label: 'Role', icon: 'UserCheck' },
            { to: '/company-setup/user-and-access?tab=permissions', label: 'Permissions', icon: 'Key' }
          ]
        },
        { isHeader: true, label: 'System Configuration' },
        { to: '/company-setup/audit-logs', label: 'Audit Log', icon: 'FileText' }
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
        { isHeader: true, label: 'Product Setup' },
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
        { isHeader: true, label: 'Tenant Setup' },
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
  <aside :class="['app-sidebar', { collapsed: props.collapsed }]">
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

              <div class="submenu-item" @click="navigateToModule('/hr/employees')">
                <div class="submenu-icon-box" style="background-color: #eef2ff;">
                  <Users :size="14" style="color: #4f46e5;" />
                </div>
                <span class="submenu-text">Human Resources</span>
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

    <!-- Main Navigation List -->
    <nav class="sidebar-nav" ref="sidebarNavRef">
      <ul>
        <li v-for="(item, idx) in activeModule.menu" :key="item.label">
          <!-- HEADER SECTION -->
          <template v-if="item.isHeader">
            <div v-if="!props.collapsed" :class="['nav-section-title', idx > 0 ? 'mt-5' : '']">
              {{ item.label }}
            </div>
          </template>

          <!-- REGULAR MENU ITEMS -->
          <template v-else>
            <!-- COLLAPSED SIDEBAR -->
            <template v-if="props.collapsed">
              <div v-if="item.isGroup && item.children && item.children.length > 0" class="nav-group-collapsed">
                <div v-for="child in item.children" :key="child.to" class="collapsed-item-wrapper">
                  <router-link :to="child.to" class="nav-item" :class="{ 'active': isChildActive(child.to) }" :title="child.label">
                    <component :is="iconsMap[child.icon] || Users" :size="18" class="nav-icon" />
                  </router-link>
                </div>
              </div>
              <router-link v-else-if="!item.isGroup" :to="item.to" class="nav-item" :class="{ 'active': isChildActive(item.to) }" :title="item.label">
                <component :is="iconsMap[item.icon] || LayoutDashboard" :size="18" class="nav-icon" />
              </router-link>
            </template>

            <!-- EXPANDED SIDEBAR -->
            <template v-else>
              <!-- Simple Link -->
              <router-link v-if="!item.isGroup" :to="item.to" class="nav-item" :class="{ 'active': isChildActive(item.to) }">
                <component :is="iconsMap[item.icon] || LayoutDashboard" :size="18" :class="['nav-icon', { 'rotate-90': item.rotate }]" />
                <span class="nav-text">{{ item.label }}</span>
              </router-link>

              <!-- Collapsible Group -->
              <div v-else class="nav-group">
                <div class="nav-group-header" :class="{ 'header-active': isGroupActive(item) }" @click="toggleGroupExpanded(item.label)">
                  <div class="nav-group-header-left">
                    <component :is="iconsMap[item.icon] || Database" :size="18" class="nav-icon" />
                    <span class="nav-text">{{ item.label }}</span>
                  </div>
                  <ChevronDown :size="14" class="nav-group-chevron" :class="{ 'collapsed-chevron': !isGroupExpanded(item) }" />
                </div>
                <ul v-show="isGroupExpanded(item)" class="nav-group-children">
                  <li v-for="child in item.children" :key="child.to">
                    <router-link :to="child.to" class="nav-child-item" :class="{ 'active': isChildActive(child.to) }">
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
          <Settings :size="18" class="nav-icon" />
          <span class="nav-text">Settings</span>
        </router-link>
        <router-link to="/help" class="nav-item">
          <HelpCircle :size="18" class="nav-icon" />
          <span class="nav-text">Help</span>
        </router-link>
      </div>
    </nav>
  </aside>
</template>

<style scoped>
.app-sidebar {
  width: 260px;
  height: 100%;
  max-height: 100vh;
  max-height: 100dvh;
  flex-shrink: 0;
  background-color: #ffffff;
  border-right: 1px solid #e5e5e5;
  display: flex;
  flex-direction: column;
  transition: width 0.3s ease;
  z-index: 100;
}
.app-sidebar.collapsed { width: 68px; }

.sidebar-header-wrapper {
  height: 84px;
  flex-shrink: 0;
  display: flex;
  align-items: flex-start;
  padding: 6px 16px 0 16px;
  transition: padding 0.3s ease;
}
.app-sidebar.collapsed .sidebar-header-wrapper {
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
.app-sidebar.collapsed .sidebar-brand-badge {
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

.app-sidebar.collapsed .brand-info {
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

.app-sidebar.collapsed .app-switcher {
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
  min-height: 0; 
  padding: 20px 12px; 
  overflow-y: auto; 
  overflow-x: hidden; 
  transition: padding 0.3s ease; 
  display: flex;
  flex-direction: column;
}
.app-sidebar.collapsed .sidebar-nav {
  padding: 20px 0;
  align-items: center;
}

/* Group / Section Header Titles (Normalized text, color #737373) */
.nav-section-title { 
  font-size: 11.5px; 
  font-weight: 500; 
  color: #737373; 
  margin-bottom: 6px; 
  padding-left: 12px;
  text-transform: none;
  letter-spacing: normal;
  transition: opacity 0.3s ease;
}
.app-sidebar.collapsed .nav-section-title {
  opacity: 0;
  height: 0;
  margin: 0;
  overflow: hidden;
}
.mt-5 { margin-top: 20px; }
.mt-6 { margin-top: 24px; }
.mt-auto { margin-top: auto; }
.rotate-90 { transform: rotate(90deg); }

ul { list-style: none; padding: 0; margin: 0; }

/* Inactive Nav Item (#737373) */
.nav-item {
  display: flex;
  align-items: center;
  padding: 9px 12px;
  gap: 12px;
  border-radius: 8px;
  cursor: pointer;
  color: #737373;
  margin-bottom: 2px;
  text-decoration: none;
  transition: all 0.15s ease;
}
.nav-item .nav-icon { 
  color: #737373; 
  flex-shrink: 0; 
  transition: color 0.15s ease, transform 0.2s; 
}
.nav-item:hover { 
  background-color: #F5F5F5; 
  color: #404040; 
}
.nav-item:hover .nav-icon { 
  color: #404040; 
}

/* Active Nav Item (#404040 text & icon, #F5F5F5 background) */
.nav-item.active { 
  background-color: #F5F5F5; 
  color: #404040; 
  font-weight: 600; 
}
.nav-item.active .nav-icon { 
  color: #404040; 
}

.app-sidebar.collapsed .nav-item {
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

.app-sidebar.collapsed .nav-text {
  width: 0;
  opacity: 0;
  pointer-events: none;
  transform: translateX(-10px);
}

.sidebar-bottom-actions {
  padding-top: 20px;
  border-top: 1px solid #f3f4f6;
  margin-top: auto;
  flex-shrink: 0;
}
.app-sidebar.collapsed .sidebar-bottom-actions {
  border-top: none;
}

/* Scrollbar */
.sidebar-nav::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}
.sidebar-nav::-webkit-scrollbar-track {
  background: transparent;
}
.sidebar-nav::-webkit-scrollbar-thumb {
  background-color: #e2e8f0;
  border-radius: 9999px;
}
.sidebar-nav::-webkit-scrollbar-thumb:hover {
  background-color: #cbd5e1;
}
.sidebar-nav {
  scrollbar-width: thin;
  scrollbar-color: #e2e8f0 transparent;
}

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

.app-sidebar.collapsed .brand-dropdown-menu {
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
  margin-bottom: 4px;
}

.nav-group-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 9px 12px;
  border-radius: 8px;
  cursor: pointer;
  color: #737373;
  font-size: 13px;
  font-weight: 500;
  transition: all 0.15s ease;
  user-select: none;
  border: 1px solid transparent;
}

.nav-group-header .nav-icon {
  color: #737373;
  transition: color 0.15s ease;
}

.nav-group-header:hover {
  background-color: #F5F5F5;
  color: #404040;
}

.nav-group-header:hover .nav-icon,
.nav-group-header:hover .nav-group-chevron {
  color: #404040;
}

.nav-group-header.header-active {
  color: #404040;
  font-weight: 600;
}

.nav-group-header.header-active .nav-icon,
.nav-group-header.header-active .nav-group-chevron {
  color: #404040;
}

.nav-group-header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.nav-group-chevron {
  color: #737373;
  transition: transform 0.2s ease, color 0.15s ease;
}

.nav-group-chevron.collapsed-chevron {
  transform: rotate(-90deg);
}

.nav-group-children {
  list-style: none;
  padding: 2px 0 2px 4px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  margin-left: 10px;
}

.nav-child-item {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  gap: 12px;
  border-radius: 8px;
  cursor: pointer;
  color: #737373;
  font-size: 13px;
  font-weight: 500;
  text-decoration: none;
  transition: all 0.15s ease;
  border: none;
}

.nav-child-item .nav-icon {
  color: #737373;
  transition: color 0.15s ease;
}

.nav-child-item:hover {
  background-color: #F5F5F5;
  color: #404040;
}

.nav-child-item:hover .nav-icon {
  color: #404040;
}

/* Active sub-item pill matching requested #404040 / #F5F5F5 */
.nav-child-item.active {
  background-color: #F5F5F5;
  color: #404040;
  box-shadow: none;
  border: none;
  font-weight: 600;
}

.nav-child-item.active .nav-icon {
  color: #404040;
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
