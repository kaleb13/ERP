<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  Box, ChevronRight, HelpCircle, LayoutDashboard,
  FileText, Home, Settings, LogOut,
  ShoppingBag, ShoppingCart, Building2, Users,
  UserCheck, LayoutGrid, Database, User,
  Sliders, BarChart3, Utensils, GitBranch,
  ShieldCheck, Key, Briefcase, Layers,
  Award, GitPullRequest, PanelLeft, FolderTree,
  Network, GraduationCap, BadgeCheck, ClipboardList,
  Activity, Calendar, Clock, Repeat,
  CalendarRange, ArrowLeftRight, CalendarDays, Umbrella,
  GitCommit, PieChart, Banknote, ListFilter,
  Fingerprint, UserMinus, CheckSquare, Receipt,
  ClipboardCheck, Calculator, Megaphone, LifeBuoy,
  Tag, DollarSign, Check, Lock, Scale
} from 'lucide-vue-next';
import BaseNavItem from './BaseNavItem.vue';

interface ERPModuleItem {
  id: string;
  title: string;
  icon: any;
  iconColor: string;
  iconBg: string;
  subscribed: boolean;
  route: string;
}

const allModulesList: ERPModuleItem[] = [
  {
    id: 'inventory',
    title: 'Inventory',
    icon: Box,
    iconColor: '#0B529C',
    iconBg: '#EFF6FF',
    subscribed: true,
    route: '/inventory/stock-summary'
  },
  {
    id: 'procurement',
    title: 'Procurement',
    icon: ShoppingCart,
    iconColor: '#009966',
    iconBg: '#ECFDF5',
    subscribed: true,
    route: '/procurement/categories'
  },
  {
    id: 'hr',
    title: 'Human Resources',
    icon: Users,
    iconColor: '#7C3AED',
    iconBg: '#F5F3FF',
    subscribed: true,
    route: '/hr/employees'
  },
  {
    id: 'buying',
    title: 'Buying',
    icon: Tag,
    iconColor: '#0D9488',
    iconBg: '#F0FDFA',
    subscribed: false,
    route: '/inventory/stock-summary'
  },
  {
    id: 'company_setup',
    title: 'Company Setup',
    icon: Building2,
    iconColor: '#525252',
    iconBg: '#F5F5F5',
    subscribed: false,
    route: '/company-setup'
  },
  {
    id: 'sales',
    title: 'Sales',
    icon: ShoppingBag,
    iconColor: '#FA7014',
    iconBg: '#FFF7ED',
    subscribed: false,
    route: '/inventory/stock-summary'
  },
  {
    id: 'finance',
    title: 'Finance & Accounting',
    icon: DollarSign,
    iconColor: '#E7000B',
    iconBg: '#FEF2F2',
    subscribed: false,
    route: '/inventory/stock-summary'
  },
  {
    id: 'selling',
    title: 'Selling & POS',
    icon: Receipt,
    iconColor: '#D97706',
    iconBg: '#FEF3C7',
    subscribed: false,
    route: '/inventory/stock-summary'
  },
  {
    id: 'sys_config',
    title: 'System Config',
    icon: Sliders,
    iconColor: '#0284C7',
    iconBg: '#F0F9FF',
    subscribed: false,
    route: '/sys-config'
  },
  {
    id: 'settings',
    title: 'Settings',
    icon: Settings,
    iconColor: '#475569',
    iconBg: '#F1F5F9',
    subscribed: false,
    route: '/settings'
  }
];

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
  'Employees': true,
  'Attendance': true,
  'Leave': true
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
  router.push('/inventory/stock-summary');
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
  BadgeCheck,
  ClipboardList,
  Activity,
  Calendar,
  Clock,
  Repeat,
  CalendarRange,
  ArrowLeftRight,
  CalendarDays,
  Umbrella,
  GitCommit,
  PieChart,
  Banknote,
  ListFilter,
  Fingerprint,
  UserMinus,
  ClipboardCheck,
  Calculator,
  Receipt,
  CheckSquare,
  Settings,
  Megaphone,
  LifeBuoy,
  Scale
};

// Active link matching helper
const isChildActive = (to?: string) => {
  if (!to) return false;
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
  if (path.startsWith('/procurement')) {
    return {
      id: 'procurement',
      name: 'Procurement',
      icon: 'ShoppingCart',
      iconColor: '#009966',
      iconBg: '#ECFDF5',
      menu: [
        { isHeader: true, label: 'Foundation & Policy' },
        { to: '/procurement/categories', label: 'Procurement Categories', icon: 'FolderTree' },
        { to: '/procurement/units', label: 'Procurement Units', icon: 'Building2' },
        { to: '/procurement/thresholds', label: 'Spend Threshold Bands', icon: 'Scale' }
      ]
    };
  } else if (path.startsWith('/hr')) {
    return {
      id: 'hr',
      name: 'Human Resource',
      icon: 'Users',
      iconColor: '#7C3AED',
      iconBg: '#F5F3FF',
      menu: [
        { isHeader: true, label: 'USER AND ACCESS' },
        { to: '/hr/employees', label: 'Employee Directory', icon: 'User' },
        { isHeader: true, label: 'Organization & Structure' },
        { to: '/hr/org-structures', label: 'Org Structures', icon: 'Network' },
        { isHeader: true, label: 'Work Calendar & Shifts' },
        { to: '/hr/calendar', label: 'Calendar', icon: 'CalendarDays' },
        { to: '/hr/shift-patterns', label: 'Shift Patterns', icon: 'Repeat' },
        { to: '/hr/attendance', label: 'Daily Attendance', icon: 'Clock' },
        { to: '/hr/shift-swaps', label: 'Shift Swaps', icon: 'ArrowLeftRight' },
        { isHeader: true, label: 'LEAVE & ABSENCE' },
        {
          isGroup: true,
          label: 'Leave',
          icon: 'Calendar',
          children: [
            { to: '/hr/leave-requests', label: 'Leave Requests', icon: 'FileText' },
            { to: '/hr/leave-allocations', label: 'Leave Allocations', icon: 'Layers' },
            { to: '/hr/leave-balances', label: 'Leave Balances', icon: 'Scale' },
            { to: '/hr/leave-encashments', label: 'Leave Encashments', icon: 'Receipt' },
            { to: '/hr/leave-policies', label: 'Leave Policies', icon: 'ShieldCheck' }
          ]
        }
      ]
    };
  } else {
    // Inventory module (default)
    return {
      id: 'inventory',
      name: 'Inventory',
      icon: 'Box',
      iconColor: '#0B529C',
      iconBg: '#eff6ff',
      menu: [
        { isHeader: true, label: 'Stock & Storage' },
        { to: '/inventory/stock-summary', label: 'Stock Summary', icon: 'LayoutGrid' },
        { to: '/inventory/warehouses', label: 'Warehouses', icon: 'Building2' },
        { to: '/inventory/item-master', label: 'Item Master', icon: 'Box' },
        { to: '/inventory/categories', label: 'Categories', icon: 'Layers' },
        { to: '/inventory/units', label: 'Units of Measure', icon: 'Sliders' },
        { isHeader: true, label: 'Operations' },
        { to: '/inventory/stock-moves', label: 'Stock Moves', icon: 'ArrowLeftRight' },
        { to: '/inventory/deliveries', label: 'Deliveries', icon: 'ShoppingBag' },
        { to: '/inventory/receipts', label: 'Receipts', icon: 'Receipt' },
        { isHeader: true, label: 'Adjustments' },
        { to: '/inventory/physical-inventory', label: 'Physical Inventory', icon: 'CheckSquare' },
        { to: '/inventory/scrap', label: 'Scrap Orders', icon: 'UserMinus' }
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
    <!-- Sidebar Header Frame (Figma QMT Node 3345:24551 Type=Mega & Type=Collapsed) -->
    <div class="sidebar-header-wrapper">
      <div class="sidebar-header-relative w-full">
        <!-- Collapsed State: 40px square icon with dark tooltip -->
        <div v-if="props.collapsed" class="collapsed-item-container">
          <BaseNavItem
            type="collapsed"
            :icon="iconsMap[activeModule.icon] || Box"
            :label="activeModule.name"
            :tile-bg="activeModule.iconBg"
            :tile-color="activeModule.iconColor"
            :expanded="isDropdownOpen"
            @click="toggleDropdown"
          />
        </div>

        <!-- Expanded State: 56px rich mega item with tile, title, and chevron -->
        <BaseNavItem
          v-else
          type="mega"
          :label="activeModule.name"
          supporting-text="Haleta ERP"
          :icon="iconsMap[activeModule.icon] || Box"
          :tile-bg="activeModule.iconBg"
          :tile-color="activeModule.iconColor"
          :show-chevron="true"
          :expanded="isDropdownOpen"
          @click="toggleDropdown"
        />

        <!-- DROPDOWN PORTAL MENU (Using QMT NavItemBase components) -->
        <div 
          v-if="isDropdownOpen" 
          :class="['brand-dropdown-menu', { 'collapsed-dropdown': props.collapsed }]" 
          @click.stop
          @mouseleave="closeSubmenu"
        >
          <!-- Home -->
          <BaseNavItem
            type="sidebar"
            to="/"
            label="Home"
            :icon="Home"
            @click="closeDropdown"
          />

          <!-- Modules with Arrow (Triggers Submenu) -->
          <div 
            class="dropdown-item-wrapper has-submenu" 
            :class="{ 'submenu-active': isSubmenuOpen }"
            @mouseenter="openSubmenu"
            @click="toggleSubmenu"
          >
            <BaseNavItem
              type="sidebar"
              label="Modules"
              :icon="Box"
              :show-chevron="true"
              :chevron="ChevronRight"
            />

            <!-- SUBMENU (positioned absolutely to the right) -->
            <div v-if="isSubmenuOpen" class="brand-submenu-menu" @click.stop>
              <div 
                v-for="mod in allModulesList" 
                :key="mod.id"
                class="submenu-module-card"
                :class="{ 
                  'is-active': activeModule.id === mod.id,
                  'is-unsubscribed': !mod.subscribed 
                }"
                :title="mod.subscribed ? mod.title : `${mod.title} (Not Subscribed)`"
                @click="navigateToModule(mod.subscribed ? mod.route : '/')"
              >
                <div class="submenu-module-tile" :style="{ backgroundColor: mod.iconBg }">
                  <component 
                    :is="mod.icon" 
                    :size="16" 
                    :style="{ color: mod.iconColor }" 
                  />
                </div>
                <div class="submenu-module-body">
                  <span class="submenu-module-name">{{ mod.title }}</span>
                  <span v-if="!mod.subscribed" class="submenu-module-pill">Not Subscribed</span>
                </div>
                <Check v-if="activeModule.id === mod.id" :size="14" class="submenu-module-check" />
              </div>
            </div>
          </div>

          <!-- Settings -->
          <BaseNavItem
            type="sidebar"
            to="/settings"
            label="Settings"
            :icon="Settings"
            @click="closeDropdown"
          />

          <!-- Help -->
          <BaseNavItem
            type="sidebar"
            to="/help"
            label="Help"
            :icon="HelpCircle"
            @click="closeDropdown"
          />

          <!-- Divider -->
          <div class="dropdown-divider"></div>

          <!-- Logout -->
          <BaseNavItem
            type="sidebar"
            label="Logout"
            :icon="LogOut"
            custom-class="logout-nav-item"
            @click="handleLogout"
          />
        </div>
      </div>
    </div>

    <!-- Main Navigation List (Figma QMT Node 3345:24551 Type=Sidebar & Sub item) -->
    <nav class="sidebar-nav" ref="sidebarNavRef">
      <ul class="sidebar-nav-list">
        <li v-for="(item, idx) in activeModule.menu" :key="item.label">
          <!-- SECTION HEADER TITLE -->
          <template v-if="item.isHeader">
            <div v-if="!props.collapsed" :class="['nav-section-title', idx > 0 ? 'mt-5' : '']">
              {{ item.label }}
            </div>
          </template>

          <!-- REGULAR MENU ITEMS -->
          <template v-else>
            <!-- COLLAPSED SIDEBAR (Icon-only rails with dark hover tooltips) -->
            <template v-if="props.collapsed">
              <div v-if="item.isGroup && item.children && item.children.length > 0" class="nav-group-collapsed">
                <div v-for="child in item.children" :key="child.to" class="collapsed-item-wrapper">
                  <BaseNavItem
                    type="collapsed"
                    :to="child.to"
                    :icon="iconsMap[child.icon] || Users"
                    :label="child.label"
                    :active="isChildActive(child.to)"
                  />
                </div>
              </div>
              <BaseNavItem
                v-else-if="!item.isGroup"
                type="collapsed"
                :to="item.to"
                :icon="iconsMap[item.icon] || LayoutDashboard"
                :label="item.label"
                :active="isChildActive(item.to)"
              />
            </template>

            <!-- EXPANDED SIDEBAR (QMT NavItemBase rows) -->
            <template v-else>
              <!-- Simple Link Item (Type=Sidebar) -->
              <BaseNavItem
                v-if="!item.isGroup"
                type="sidebar"
                :to="item.to"
                :icon="iconsMap[item.icon] || LayoutDashboard"
                :label="item.label"
                :active="isChildActive(item.to)"
              />

              <!-- Collapsible Group Item -->
              <div v-else class="nav-group">
                <BaseNavItem
                  type="sidebar"
                  :icon="iconsMap[item.icon] || Database"
                  :label="item.label"
                  :show-chevron="true"
                  :expanded="isGroupExpanded(item)"
                  :active="isGroupActive(item)"
                  @click="toggleGroupExpanded(item.label)"
                />
                <!-- Sub Items (Type=Sub item with indent) -->
                <ul v-show="isGroupExpanded(item)" class="nav-group-children">
                  <li v-for="child in item.children" :key="child.to">
                    <BaseNavItem
                      type="sub-item"
                      :to="child.to"
                      :icon="iconsMap[child.icon] || Users"
                      :label="child.label"
                      :active="isChildActive(child.to)"
                    />
                  </li>
                </ul>
              </div>
            </template>
          </template>
        </li>
      </ul>
    </nav>

    <!-- Sidebar Footer Actions (Fixed at bottom with transition border-top) -->
    <div class="sidebar-bottom-actions">
      <template v-if="props.collapsed">
        <BaseNavItem type="collapsed" to="/settings" :icon="Settings" label="Settings" :active="isChildActive('/settings')" />
        <BaseNavItem type="collapsed" to="/help" :icon="HelpCircle" label="Help" :active="isChildActive('/help')" />
      </template>
      <template v-else>
        <BaseNavItem type="sidebar" to="/settings" :icon="Settings" label="Settings" :active="isChildActive('/settings')" />
        <BaseNavItem type="sidebar" to="/help" :icon="HelpCircle" label="Help" :active="isChildActive('/help')" />
      </template>
    </div>
  </aside>
</template>

<style scoped>
.app-sidebar {
  width: 284px;
  height: 100%;
  max-height: 100vh;
  max-height: 100dvh;
  flex-shrink: 0;
  background-color: #ffffff;
  border-right: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  display: flex;
  flex-direction: column;
  transition: width 0.3s ease;
  z-index: 100;
  box-sizing: border-box;
}
.app-sidebar.collapsed { width: 68px; }

/* Sidebar Top Menu Frame: Top 16px, Left/Right 16px, Bottom gap 20px */
.sidebar-header-wrapper {
  height: 72px;
  min-height: 72px;
  max-height: 72px;
  flex-shrink: 0;
  display: flex;
  align-items: stretch;
  padding: var(--alias-spacing-xl, 16px) var(--alias-spacing-xl, 16px) 0 var(--alias-spacing-xl, 16px);
  margin-bottom: var(--alias-spacing-2xl, 20px);
  transition: padding 0.3s ease;
  box-sizing: border-box;
}
.app-sidebar.collapsed .sidebar-header-wrapper {
  height: 72px;
  min-height: 72px;
  max-height: 72px;
  padding: var(--alias-spacing-xl, 16px) 0;
  margin-bottom: var(--alias-spacing-2xl, 20px);
  display: flex;
  justify-content: center;
  align-items: center;
  box-sizing: border-box;
}

.sidebar-header-relative {
  position: relative;
  width: 100%;
  height: 100%;
}

.collapsed-item-container {
  display: flex;
  justify-content: center;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
}

/* BRAND SWITCHER DROPDOWN MENU */
.brand-dropdown-menu {
  position: absolute;
  top: calc(100% + 8px);
  left: 0;
  width: 100%;
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-xl, 12px);
  box-shadow: 0 10px 25px -5px rgba(10, 13, 18, 0.08), 0 8px 10px -6px rgba(10, 13, 18, 0.04);
  z-index: 999;
  padding: var(--alias-spacing-xs, 4px);
  display: flex;
  flex-direction: column;
  gap: 2px;
  animation: dropFade 0.2s ease-out;
  box-sizing: border-box;
}

.brand-dropdown-menu.collapsed-dropdown {
  left: calc(100% + 12px);
  top: 0;
  width: 220px;
}

@keyframes dropFade {
  from { opacity: 0; transform: translateY(-5px); }
  to { opacity: 1; transform: translateY(0); }
}

.dropdown-item-wrapper {
  position: relative;
  width: 100%;
}

.dropdown-divider {
  height: 1px;
  background-color: var(--alias-color-border-subtle, #e5e5e5);
  margin: 4px 6px;
}

:deep(.logout-nav-item:hover) {
  background-color: var(--primitive-color-red-50, #fef2f2) !important;
  color: var(--primitive-color-red-600, #e7000b) !important;
}
:deep(.logout-nav-item:hover .qmt-nav-item__icon) {
  color: var(--primitive-color-red-600, #e7000b) !important;
}

/* SUBMENU SYSTEM */
.brand-submenu-menu {
  position: absolute;
  top: 0;
  left: calc(100% + 8px);
  width: 250px;
  max-height: 440px;
  overflow-y: auto;
  overflow-x: hidden;
  background-color: #ffffff;
  border: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  border-radius: var(--alias-radius-xl, 12px);
  box-shadow: 0 10px 25px -5px rgba(10, 13, 18, 0.08), 0 8px 10px -6px rgba(10, 13, 18, 0.04);
  z-index: 1000;
  padding: 6px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  animation: subFade 0.15s ease-out;
  box-sizing: border-box;
}

.brand-submenu-menu::-webkit-scrollbar {
  width: 5px;
}
.brand-submenu-menu::-webkit-scrollbar-thumb {
  background-color: #e5e5e5;
  border-radius: 9999px;
}

.submenu-module-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 8px;
  border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.15s ease;
  user-select: none;
}

.submenu-module-card:hover {
  background-color: #f5f5f5;
}

.submenu-module-card.is-active {
  background-color: #eff6ff;
}

.submenu-module-tile {
  width: 30px;
  height: 30px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: inset 0 0 0 0.5px rgba(0, 0, 0, 0.05);
}

.submenu-module-body {
  display: flex;
  flex-direction: column;
  min-width: 0;
  flex: 1;
}

.submenu-module-name {
  font-size: 13px;
  font-weight: 500;
  color: #404040;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.submenu-module-card.is-active .submenu-module-name {
  color: #0b529c;
  font-weight: 600;
}

.submenu-module-pill {
  font-size: 10px;
  color: #737373;
  line-height: 1.2;
}

.submenu-module-check {
  color: #0b529c;
  flex-shrink: 0;
}

@keyframes subFade {
  from { opacity: 0; transform: translateX(-5px); }
  to { opacity: 1; transform: translateX(0); }
}

/* NAV */
.sidebar-nav { 
  flex: 1; 
  min-height: 0; 
  padding: 0 var(--alias-spacing-xl, 16px); 
  overflow-y: auto; 
  overflow-x: hidden; 
  transition: padding 0.3s ease; 
  display: flex;
  flex-direction: column;
}
.app-sidebar.collapsed .sidebar-nav {
  padding: 0;
  align-items: center;
}

.sidebar-nav-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-xs, 4px);
}

/* Section Header Titles */
.nav-section-title { 
  font-size: 12px; 
  font-weight: 500; 
  line-height: 18px; 
  color: var(--alias-color-text-tertiary, #737373); 
  padding: var(--alias-spacing-md, 8px) var(--alias-spacing-md, 8px) 6px var(--alias-spacing-md, 8px); 
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin: 0;
  transition: opacity 0.3s ease;
}
.app-sidebar.collapsed .nav-section-title {
  opacity: 0;
  height: 0;
  margin: 0;
  padding: 0;
  overflow: hidden;
}
.mt-5 { margin-top: var(--alias-spacing-2xl, 20px); }
.mt-auto { margin-top: auto; }

/* Collapsible Menu Group Styling */
.nav-group {
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-xs, 4px);
  width: 100%;
}

.nav-group-children {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-xs, 4px);
}

.nav-group-collapsed {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--alias-spacing-xs, 4px);
  width: 100%;
}

.collapsed-item-wrapper {
  display: flex;
  justify-content: center;
  width: 100%;
}

.sidebar-bottom-actions {
  padding: var(--alias-spacing-xl, 16px);
  border-top: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: var(--alias-spacing-xs, 4px);
  box-sizing: border-box;
}
.app-sidebar.collapsed .sidebar-bottom-actions {
  border-top: 1px solid var(--alias-color-border-subtle, #e5e5e5);
  padding: var(--alias-spacing-xl, 16px) 0;
  align-items: center;
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
</style>
