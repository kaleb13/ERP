<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue';
import { 
  Building2, Monitor, ArrowLeftRight, Settings, Grid, Box, Warehouse,
  Tag, Scale, FolderTree, Package, ShoppingBag, Boxes, Copy, Store,
  Search, Maximize, Moon, Languages, Bell, PanelLeftClose, ChevronDown, ChevronUp, ChevronRight,
  ClipboardList, ChefHat, ShieldCheck, ShieldAlert
} from 'lucide-vue-next';

// Sidebar state
const isSidebarCollapsed = ref(false);
const sidebarNavRef = ref<HTMLElement | null>(null);

const toggleSidebar = () => {
  isSidebarCollapsed.value = !isSidebarCollapsed.value;
};

const handleScroll = (e: Event) => {
  const target = e.target as HTMLElement;
  sessionStorage.setItem('erp_sidebar_scroll', target.scrollTop.toString());
};

onMounted(() => {
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
        <div class="sidebar-brand-badge">
          <div class="logo-box">
            <Box class="logo-icon text-orange-400" :size="20" />
          </div>
          <div class="brand-info" v-if="!isSidebarCollapsed">
            <h1 class="brand-title">Haleta ERP</h1>
            <p class="brand-subtitle">Module Name</p>
          </div>
          <div class="app-switcher ml-auto" v-if="!isSidebarCollapsed">
            <ChevronUp :size="12" class="text-gray-400" />
            <ChevronDown :size="12" class="text-gray-400" />
          </div>
        </div>
      </div>

      <!-- Navigation -->
      <nav class="sidebar-nav" ref="sidebarNavRef">
        <div class="nav-section" v-if="!isSidebarCollapsed">ENTITY SETUP</div>
        <ul>
          <li>
            <router-link to="/business-group" class="nav-item" active-class="active">
              <Building2 :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Business Group</span>
            </router-link>
          </li>
          <li>
            <router-link to="/organizations" class="nav-item" active-class="active">
              <Building2 :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Organization</span>
            </router-link>
          </li>
          <li>
            <router-link to="/branches" class="nav-item" active-class="active">
              <Grid :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Branch</span>
            </router-link>
          </li>
          <li>
            <router-link to="/warehouses" class="nav-item" active-class="active">
              <Warehouse :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Warehouse</span>
            </router-link>
          </li>
        </ul>

        <div class="nav-section mt-6" v-if="!isSidebarCollapsed">PRODUCT SETUP</div>
        <ul>
          <li>
            <router-link to="/brands" class="nav-item" active-class="active">
              <Tag :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Brands</span>
            </router-link>
          </li>
          <li>
            <router-link to="/measurements" class="nav-item" active-class="active">
              <Scale :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Measurements</span>
            </router-link>
          </li>
          <li>
            <router-link to="/item-categories" class="nav-item" active-class="active">
              <FolderTree :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Item Categories</span>
            </router-link>
          </li>
          <li>
            <router-link to="/items" class="nav-item" active-class="active">
              <Package :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Items</span>
            </router-link>
          </li>
        </ul>

        <div class="nav-section mt-6" v-if="!isSidebarCollapsed">PRODUCTS</div>
        <ul>
          <li>
            <router-link to="/products" class="nav-item" active-class="active">
              <ShoppingBag :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Products</span>
            </router-link>
          </li>
          <li>
            <router-link to="/product-groups" class="nav-item" active-class="active">
              <Boxes :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Product Groups</span>
            </router-link>
          </li>
          <li>
            <router-link to="/variants" class="nav-item" active-class="active">
              <Copy :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Variants</span>
            </router-link>
          </li>
        </ul>

        <div class="nav-section mt-6" v-if="!isSidebarCollapsed">POS & OPERATIONS</div>
        <ul>
           <li>
            <router-link to="/pos-attributes" class="nav-item" active-class="active">
              <ClipboardList :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Modifiers & Attr</span>
            </router-link>
          </li>
          <li>
            <router-link to="/pos-recipes" class="nav-item" active-class="active">
              <ChefHat :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Recipes & Rules</span>
            </router-link>
          </li>
          <li>
            <router-link to="/inventory-policies" class="nav-item" active-class="active">
              <ShieldAlert :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Procurement limits</span>
            </router-link>
          </li>
          <li>
            <router-link to="/warranties" class="nav-item" active-class="active">
              <ShieldCheck :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Warranties</span>
            </router-link>
          </li>
        </ul>

        <div class="nav-section mt-6" v-if="!isSidebarCollapsed">DISTRIBUTION</div>
        <ul>
          <li>
            <router-link to="/shop-products" class="nav-item" active-class="active">
              <Store :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Shop Products</span>
            </router-link>
          </li>
        </ul>

        <div class="nav-section mt-6" v-if="!isSidebarCollapsed">SETTINGS</div>
        <ul>
          <li>
            <router-link to="/settings" class="nav-item" active-class="active">
              <Settings :size="18" class="nav-icon" />
              <span class="nav-text" v-if="!isSidebarCollapsed">Settings</span>
            </router-link>
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

.sidebar-header-wrapper {
  padding: 16px;
}
.sidebar-brand-badge {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background-color: #fafafa;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
  position: relative;
  cursor: pointer;
}
.logo-box {
  background: #fff8eb;
  padding: 6px;
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
  text-decoration: none;
}
.nav-item:hover { background: #f3f4f6; }
.nav-item.active { background: #eff6ff; color: #1d4ed8; font-weight: 600; }
.nav-item.active .nav-icon { color: #1d4ed8; }
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
