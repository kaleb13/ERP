<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Box, ShoppingCart, DollarSign, ShoppingBag, Users, Tag, 
  Settings, Sliders, Building2, Search, Maximize, Moon, Languages, 
  Bell, ChevronDown, Check, Lock, X, Laptop, ShieldAlert, Receipt
} from 'lucide-vue-next';
import BaseTabs from '../components/BaseTabs.vue';
import AppButton from '../components/AppButton.vue';

const router = useRouter();

// Active tab filter
const activeFilter = ref<'all' | 'subscribed' | 'unsubscribed'>('all');

// Search query
const searchQuery = ref('');

// Toast notification state
const toasts = ref<{ id: number; message: string; type: 'success' | 'info' | 'warning' }[]>([]);
let toastId = 0;

const showToast = (message: string, type: 'success' | 'info' | 'warning' = 'success') => {
  const id = ++toastId;
  toasts.value.push({ id, message, type });
  setTimeout(() => {
    toasts.value = toasts.value.filter(t => t.id !== id);
  }, 4000);
};

// Modal for locked modules
const isModalOpen = ref(false);
const selectedModule = ref<{ title: string; desc: string } | null>(null);

const openUpgradeModal = (mod: { title: string; desc: string }) => {
  selectedModule.value = mod;
  isModalOpen.value = true;
};

const closeUpgradeModal = () => {
  isModalOpen.value = false;
  selectedModule.value = null;
};

// Module list with distinct colors for each module
const sections = ref([
  {
    title: 'Operations & Supply Chain',
    id: 'operations_supply',
    modules: [
      { 
        id: 'inventory', 
        title: 'Inventory', 
        desc: 'Tracks stock levels, movements, and warehouse operations across facilities.', 
        icon: Box, 
        iconColor: '#0B529C', // Brand Blue (kept for inventory)
        iconBg: '#EFF6FF', 
        subscribed: true, 
        route: '/inventory/stock-summary' 
      },
      { 
        id: 'procurement', 
        title: 'Procurement', 
        desc: 'Manage spend categories, purchase methods, requisitions, sourcing, and supplier compliance.', 
        icon: ShoppingCart, 
        iconColor: '#009966', // Emerald Green (distinct color for procurement)
        iconBg: '#ECFDF5', 
        subscribed: true,
        route: '/procurement/categories'
      },
      { 
        id: 'buying', 
        title: 'Buying', 
        desc: 'Manage supplier relationships, purchase requests, RFQs, and purchase orders.', 
        icon: Tag, 
        iconColor: '#0D9488', // Teal
        iconBg: '#F0FDFA', 
        subscribed: false 
      }
    ]
  },
  {
    title: 'Workforce & Corporate Governance',
    id: 'workforce_governance',
    modules: [
      { 
        id: 'hr', 
        title: 'Human Resources', 
        desc: 'Manage organizational structure, job architecture, positions, and workforce movements.', 
        icon: Users, 
        iconColor: '#7C3AED', // Vibrant Violet / Purple (distinct color for HR)
        iconBg: '#F5F3FF', 
        subscribed: true,
        route: '/hr/employees' 
      },
      { 
        id: 'company_setup', 
        title: 'Company Setup', 
        desc: 'Configure business entities, branches, fiscal calendars, and organizational hierarchies.', 
        icon: Building2, 
        iconColor: '#525252', // Slate
        iconBg: '#F5F5F5', 
        subscribed: false 
      }
    ]
  },
  {
    title: 'Sales & Financial Management',
    id: 'sales_financial',
    modules: [
      { 
        id: 'sales', 
        title: 'Sales', 
        desc: 'Customer accounts, pricing agreements, quotations, sales pipelines, and customer segments.', 
        icon: ShoppingBag, 
        iconColor: '#FA7014', // Brand Orange
        iconBg: '#FFF7ED', 
        subscribed: false 
      },
      { 
        id: 'finance', 
        title: 'Finance & Accounting', 
        desc: 'Financial reporting, general ledger, cash flows, and expense allocations.', 
        icon: DollarSign, 
        iconColor: '#E7000B', // Crimson Red
        iconBg: '#FEF2F2', 
        subscribed: false 
      },
      { 
        id: 'selling', 
        title: 'Selling & POS', 
        desc: 'Point-of-sale checkout, customer receipts, credit notes, and counter operations.', 
        icon: Receipt, 
        iconColor: '#D97706', // Amber
        iconBg: '#FEF3C7', 
        subscribed: false 
      }
    ]
  },
  {
    title: 'Platform & Configuration',
    id: 'platform_config',
    isCustom: true,
    modules: [
      { 
        id: 'sys_config', 
        title: 'System Config', 
        desc: 'The control tower: access controls, security roles, permissions, and audit logs.', 
        icon: Sliders, 
        iconColor: '#0284C7', // Sky Blue
        iconBg: '#F0F9FF',
        subscribed: false
      },
      { 
        id: 'settings', 
        title: 'Settings', 
        desc: 'System customization, application parameters, themes, and notification rules.', 
        icon: Settings, 
        iconColor: '#737373', // Charcoal
        iconBg: '#F1F5F9',
        subscribed: false
      }
    ]
  }
]);

// Summary metrics
const totalCount = computed(() => {
  return sections.value.reduce((acc, s) => acc + s.modules.length, 0);
});

const subscribedCount = computed(() => {
  return sections.value.reduce((acc, s) => acc + s.modules.filter(m => m.subscribed).length, 0);
});

// Filter tabs for toolbar
const filterTabs = computed(() => [
  { id: 'all' as const, label: 'All', count: totalCount.value },
  { id: 'subscribed' as const, label: 'Subscribed', count: subscribedCount.value },
  { id: 'unsubscribed' as const, label: 'Not Subscribed', count: totalCount.value - subscribedCount.value }
]);

// Filtered sections and modules
const filteredSections = computed(() => {
  return sections.value.map(section => {
    let filteredMods = section.modules;

    // Filter by tab
    if (activeFilter.value === 'subscribed') {
      filteredMods = filteredMods.filter(m => m.subscribed);
    } else if (activeFilter.value === 'unsubscribed') {
      filteredMods = filteredMods.filter(m => !m.subscribed);
    }

    // Filter by search query
    if (searchQuery.value.trim() !== '') {
      const q = searchQuery.value.toLowerCase();
      filteredMods = filteredMods.filter(m => 
        m.title.toLowerCase().includes(q) || 
        m.desc.toLowerCase().includes(q)
      );
    }

    return {
      ...section,
      modules: filteredMods
    };
  }).filter(section => section.modules.length > 0);
});

// Counts for categories
const getCategoryCountText = (section: any) => {
  const total = section.modules.length;
  const subscribed = section.modules.filter((m: any) => m.subscribed).length;
  return `${subscribed}/${total} subscribed`;
};

// Handle module card click
const handleModuleClick = (mod: any) => {
  if (mod.subscribed && mod.route) {
    router.push(mod.route);
  } else {
    openUpgradeModal(mod);
  }
};
</script>

<template>
  <div class="home-portal">
    <!-- BLUE HERO HEADER SECTION -->
    <div class="hero-section">
      <!-- Transparent Top Bar -->
      <header class="home-topbar">
        <div class="topbar-left">
          <div class="logo-box-portal">
            <Box class="logo-icon-portal" :size="20" />
          </div>
          <div class="brand-info-portal">
            <h1 class="brand-title-portal">Haleta ERP</h1>
            <p class="brand-subtitle-portal">Enterprise Portal</p>
          </div>
        </div>

        <div class="topbar-right">
          <button class="btn-icon-portal" title="Fullscreen"><Maximize :size="18" /></button>
          <button class="btn-icon-portal" title="Toggle Theme"><Moon :size="18" /></button>
          <button class="btn-icon-portal" title="Language"><Languages :size="18" /></button>
          <button class="btn-icon-portal relative mr-2" title="Notifications">
            <Bell :size="18" />
            <span class="notification-badge-portal">2</span>
          </button>
          
          <div class="topbar-separator-portal"></div>
          
          <div class="profile-wrapper-portal">
            <div class="avatar-container-portal">
              <img src="https://i.pravatar.cc/100?img=5" alt="Profile" class="avatar-sm-portal" />
              <span class="status-indicator-portal"></span>
            </div>
            <div class="profile-info-text-portal">
              <span class="profile-name-text-portal">Marta Tadesse</span>
            </div>
            <ChevronDown :size="14" class="text-white opacity-80" />
          </div>
        </div>
      </header>

      <!-- Welcome Hero Details -->
      <div class="welcome-container">
        <h2 class="welcome-title">Welcome to Haleta ERP</h2>
        <p class="welcome-subtitle">Select an available operational module to get started.</p>
        
        <!-- Search bar inside hero -->
        <div class="search-box-wrapper">
          <Search class="search-icon-hero" :size="18" />
          <input 
            type="text" 
            placeholder="Search modules and services..." 
            v-model="searchQuery" 
            class="search-input-hero"
          />
        </div>
      </div>
    </div>

    <!-- MAIN BODY -->
    <div class="portal-body">
      <div class="portal-container">
        <!-- Toolbar Filters -->
        <div class="toolbar-section">
          <BaseTabs v-model="activeFilter" :tabs="filterTabs" />
          
          <div class="subscribed-summary">
            <span class="summary-text">{{ subscribedCount }} of {{ totalCount }} modules subscribed</span>
          </div>
        </div>

        <!-- MODULE SECTIONS GRID -->
        <div class="modules-grid-wrapper">
          <div 
            v-for="section in filteredSections" 
            :key="section.title" 
            class="section-group"
          >
            <!-- Category Title Header -->
            <div class="section-header">
              <h3 class="section-title">
                {{ section.title }}
                <span class="category-badge">
                  {{ getCategoryCountText(section) }}
                </span>
              </h3>
            </div>

            <!-- Cards Container -->
            <div class="cards-grid">
              <div 
                v-for="mod in section.modules" 
                :key="mod.id" 
                :class="['module-card', { 'unsubscribed-card': !mod.subscribed, 'subscribed-card': mod.subscribed }]"
                @click="handleModuleClick(mod)"
              >
                <!-- Card Inner Header -->
                <div class="card-header-row">
                  <div class="card-icon-box" :style="{ backgroundColor: mod.iconBg }">
                    <component :is="mod.icon" :size="20" :style="{ color: mod.iconColor }" />
                  </div>
                  <div v-if="!mod.subscribed" class="card-lock-indicator" title="Not Subscribed">
                    <Lock :size="14" class="text-neutral-400" />
                  </div>
                </div>

                <!-- Card Content -->
                <div class="card-details">
                  <h4 class="card-title">{{ mod.title }}</h4>
                  <p class="card-desc">{{ mod.desc }}</p>
                </div>

                <!-- Card Status Footer -->
                <div class="card-status-footer">
                  <div v-if="mod.subscribed" class="subscribed-pill">
                    <Check :size="12" class="mr-1 text-emerald-600 stroke-[3px]" />
                    <span>Subscribed</span>
                  </div>
                  <div v-else class="unsubscribed-pill">
                    <Lock :size="10" class="mr-1 text-neutral-500" />
                    <span>Not Subscribed</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- FOOTER -->
    <footer class="portal-footer">
      <div class="footer-links">
        <span>© 2026 Haleta Systems. All rights reserved.</span>
        <span class="separator">|</span>
        <a href="#" @click.prevent="showToast('Contacting Haleta Enterprise Support...', 'info')">Contact Us</a>
        <span class="separator">|</span>
        <a href="#" @click.prevent="showToast('Loading Privacy Policy...', 'info')">Privacy Policy</a>
        <span class="separator">|</span>
        <a href="#" @click.prevent="showToast('Loading Terms of Service...', 'info')">Terms of Service</a>
      </div>
    </footer>

    <!-- TOAST NOTIFICATIONS CONTAINER -->
    <div class="toast-container">
      <TransitionGroup name="toast">
        <div 
          v-for="toast in toasts" 
          :key="toast.id" 
          :class="['toast-alert', `toast-${toast.type}`]"
        >
          <div class="toast-content">
            <Check v-if="toast.type === 'success'" :size="16" class="toast-icon text-emerald-600" />
            <Laptop v-else-if="toast.type === 'info'" :size="16" class="toast-icon text-blue-600" />
            <ShieldAlert v-else :size="16" class="toast-icon text-amber-600" />
            <span>{{ toast.message }}</span>
          </div>
        </div>
      </TransitionGroup>
    </div>

    <!-- LOCKED MODULE MODAL -->
    <div v-if="isModalOpen" class="modal-overlay" @click.self="closeUpgradeModal">
      <div class="modal-card">
        <button class="modal-close-btn" @click="closeUpgradeModal" aria-label="Close modal">
          <X :size="18" />
        </button>
        
        <div class="modal-icon-header">
          <div class="locked-badge-icon">
            <Lock :size="24" class="text-amber-600" />
          </div>
        </div>

        <div class="modal-body-content">
          <h3 class="modal-title">{{ selectedModule?.title }} is Not Subscribed</h3>
          <p class="modal-subtitle">Enterprise Suite Module</p>
          <p class="modal-description">
            The <strong>{{ selectedModule?.title }}</strong> module is not subscribed in your deployment. Active operational modules include <strong>Inventory</strong>, <strong>Procurement</strong>, and <strong>Human Resources</strong>.
          </p>

          <div class="premium-features-list">
            <div class="feature-item">
              <Check :size="14" class="text-emerald-600" />
              <span>Full read/write permissions for organizational staff</span>
            </div>
            <div class="feature-item">
              <Check :size="14" class="text-emerald-600" />
              <span>Dedicated audit trail, reporting & data exports</span>
            </div>
            <div class="feature-item">
              <Check :size="14" class="text-emerald-600" />
              <span>Automated workflows and ERP system integration</span>
            </div>
          </div>
        </div>

        <div class="modal-footer-row">
          <AppButton variant="outline" size="md" @click="closeUpgradeModal">Cancel</AppButton>
          <AppButton 
            variant="primary" 
            size="md"
            @click="showToast(`Request sent to unlock ${selectedModule?.title}!`, 'success'); closeUpgradeModal()"
          >
            Request Access
          </AppButton>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.home-portal {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background-color: #fafafa;
  font-family: inherit;
  overflow-x: hidden;
}

/* BLUE HERO HEADER */
.hero-section {
  background: linear-gradient(135deg, #0B529C 0%, #0084D1 100%);
  color: white;
  padding-bottom: 48px;
  position: relative;
  box-shadow: 0 4px 20px rgba(11, 82, 156, 0.15);
}

/* HOME TOP BAR */
.home-topbar {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 40px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.15);
}

.logo-box-portal {
  background: rgba(255, 255, 255, 0.18);
  padding: 6px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.logo-icon-portal {
  color: #ffffff;
}

.brand-info-portal {
  margin-left: 12px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.brand-title-portal {
  font-size: 15px;
  font-weight: 700;
  color: #ffffff;
  margin: 0;
  line-height: 1.2;
}

.brand-subtitle-portal {
  font-size: 11px;
  font-weight: 400;
  color: rgba(255, 255, 255, 0.8);
  margin: 0;
}

.topbar-left {
  display: flex;
  align-items: center;
}

.topbar-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-icon-portal {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.85);
  cursor: pointer;
  padding: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  transition: all 0.2s;
}

.btn-icon-portal:hover {
  color: #ffffff;
  background-color: rgba(255, 255, 255, 0.15);
}

.topbar-separator-portal {
  width: 1px;
  height: 20px;
  background-color: rgba(255, 255, 255, 0.25);
  margin: 0 12px;
}

.profile-wrapper-portal {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 8px;
  transition: background 0.2s;
}

.profile-wrapper-portal:hover {
  background-color: rgba(255, 255, 255, 0.15);
}

.avatar-container-portal {
  position: relative;
  display: flex;
}

.avatar-sm-portal {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  object-fit: cover;
  border: 1.5px solid rgba(255, 255, 255, 0.8);
}

.status-indicator-portal {
  position: absolute;
  bottom: 0;
  right: 0;
  width: 8px;
  height: 8px;
  background-color: #009966;
  border: 1.5px solid #0B529C;
  border-radius: 50%;
}

.profile-info-text-portal {
  display: flex;
  flex-direction: column;
}

.profile-name-text-portal {
  font-size: 13px;
  font-weight: 500;
  color: #ffffff;
}

.notification-badge-portal {
  position: absolute;
  top: 4px;
  right: 4px;
  background: #E7000B;
  color: white;
  font-size: 9px;
  min-width: 15px;
  height: 15px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  font-weight: 700;
  border: 1.5px solid #0B529C;
}

/* HERO WELCOME CONTAINER */
.welcome-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  margin-top: 36px;
}

.welcome-title {
  font-size: 32px;
  font-weight: 700;
  letter-spacing: -0.02em;
  margin-bottom: 8px;
}

.welcome-subtitle {
  font-size: 15px;
  color: rgba(255, 255, 255, 0.9);
  font-weight: 400;
  margin-bottom: 24px;
}

.search-box-wrapper {
  position: relative;
  width: 100%;
  max-width: 480px;
}

.search-icon-hero {
  position: absolute;
  left: 16px;
  top: 50%;
  transform: translateY(-50%);
  color: rgba(255, 255, 255, 0.7);
  pointer-events: none;
  z-index: 10;
}

.search-input-hero {
  width: 100%;
  height: 46px;
  padding: 12px 16px 12px 48px;
  border-radius: 24px;
  border: 1.5px solid rgba(255, 255, 255, 0.25);
  background-color: rgba(255, 255, 255, 0.15);
  color: #ffffff;
  font-size: 14px;
  outline: none;
  backdrop-filter: blur(8px);
  transition: all 0.25s ease;
}

.search-input-hero::placeholder {
  color: rgba(255, 255, 255, 0.7);
}

.search-input-hero:focus {
  border-color: rgba(255, 255, 255, 0.9);
  background-color: rgba(255, 255, 255, 0.25);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

/* PORTAL BODY */
.portal-body {
  flex: 1;
  padding: 24px 0 60px;
}

.portal-container {
  width: 100%;
  max-width: 1100px;
  margin: 0 auto;
  padding: 0 24px;
}

/* TOOLBAR & FILTERS */
.toolbar-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 28px;
  border-bottom: 1px solid #E5E5E5;
  padding-bottom: 16px;
  gap: 16px;
  flex-wrap: wrap;
}

.subscribed-summary {
  font-size: 13px;
  color: #737373;
  font-weight: 500;
}

/* MODULES GRID */
.modules-grid-wrapper {
  display: flex;
  flex-direction: column;
  gap: 36px;
}

.section-group {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.section-header {
  display: flex;
  align-items: center;
}

.section-title {
  font-size: 15px;
  font-weight: 700;
  color: #404040;
  display: flex;
  align-items: center;
  gap: 8px;
}

.category-badge {
  font-size: 11px;
  font-weight: 500;
  background-color: #F5F5F5;
  color: #737373;
  padding: 2px 8px;
  border-radius: 4px;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

@media (max-width: 900px) {
  .cards-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 600px) {
  .cards-grid {
    grid-template-columns: 1fr;
  }
}

/* MODULE CARD */
.module-card {
  background: #ffffff;
  border: 1px solid #E5E5E5;
  border-radius: 12px;
  padding: 20px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  position: relative;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
  min-height: 180px;
}

.module-card:hover {
  transform: translateY(-2px);
  border-color: #D4D4D4;
  box-shadow: 0 8px 16px -4px rgba(0, 0, 0, 0.06);
}

.subscribed-card:hover {
  border-color: #0B529C;
}

.unsubscribed-card {
  background-color: #FAFAFA;
}

.unsubscribed-card:hover {
  border-color: #A3A3A3;
}

.card-header-row {
  margin-bottom: 14px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-icon-box {
  width: 42px;
  height: 42px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.card-lock-indicator {
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.card-details {
  flex: 1;
}

.card-title {
  font-size: 15px;
  font-weight: 700;
  color: #404040;
  margin-bottom: 6px;
}

.unsubscribed-card .card-title {
  color: #404040;
}

.card-desc {
  font-size: 12px;
  color: #737373;
  line-height: 1.5;
  margin-bottom: 12px;
}

.card-status-footer {
  margin-top: auto;
  display: flex;
  align-items: center;
  font-size: 11px;
  font-weight: 500;
}

.subscribed-pill {
  color: #009966;
  display: flex;
  align-items: center;
}

.unsubscribed-pill {
  color: #737373;
  display: flex;
  align-items: center;
  background-color: #F5F5F5;
  padding: 3px 8px;
  border-radius: 12px;
}

/* PORTAL FOOTER */
.portal-footer {
  border-top: 1px solid #E5E5E5;
  padding: 24px;
  background-color: #ffffff;
  display: flex;
  justify-content: center;
  align-items: center;
  margin-top: auto;
}

.footer-links {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 12px;
  color: #737373;
  flex-wrap: wrap;
  justify-content: center;
}

.footer-links a {
  color: #737373;
  text-decoration: none;
  transition: color 0.2s;
}

.footer-links a:hover {
  color: #0B529C;
}

.separator {
  color: #D4D4D4;
}

/* TOAST ALERTS */
.toast-container {
  position: fixed;
  top: 24px;
  right: 24px;
  z-index: 1000;
  display: flex;
  flex-direction: column;
  gap: 10px;
  pointer-events: none;
}

.toast-alert {
  pointer-events: auto;
  background: white;
  border-radius: 10px;
  padding: 12px 18px;
  min-width: 280px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  border-left: 4px solid #009966;
  display: flex;
  align-items: center;
}

.toast-success { border-left-color: #009966; }
.toast-info { border-left-color: #0B529C; }
.toast-warning { border-left-color: #E17100; }

.toast-content {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  font-weight: 500;
  color: #404040;
}

.toast-icon {
  flex-shrink: 0;
}

/* Toast Transitions */
.toast-enter-active, .toast-leave-active {
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}
.toast-enter-from {
  opacity: 0;
  transform: translateX(40px) scale(0.95);
}
.toast-leave-to {
  opacity: 0;
  transform: translateY(-16px) scale(0.95);
}

/* MODAL OVERLAY */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  z-index: 1100;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  animation: modalFadeIn 0.2s ease-out;
}

@keyframes modalFadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.modal-card {
  background: white;
  border-radius: 14px;
  width: 100%;
  max-width: 460px;
  padding: 28px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.15), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  position: relative;
  display: flex;
  flex-direction: column;
  animation: modalSlideUp 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes modalSlideUp {
  from { transform: translateY(16px) scale(0.96); }
  to { transform: translateY(0) scale(1); }
}

.modal-close-btn {
  position: absolute;
  top: 16px;
  right: 16px;
  background: none;
  border: none;
  color: #737373;
  cursor: pointer;
  padding: 6px;
  border-radius: 50%;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-close-btn:hover {
  background-color: #F5F5F5;
  color: #404040;
}

.modal-icon-header {
  display: flex;
  justify-content: center;
  margin-bottom: 16px;
}

.locked-badge-icon {
  width: 52px;
  height: 52px;
  background-color: #FEF3C7;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 0 0 4px #FFFBEB;
}

.modal-body-content {
  text-align: center;
  margin-bottom: 24px;
}

.modal-title {
  font-size: 18px;
  font-weight: 700;
  color: #404040;
  margin-bottom: 4px;
}

.modal-subtitle {
  font-size: 11px;
  font-weight: 700;
  color: #B45309;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  background-color: #FEF3C7;
  padding: 2px 8px;
  border-radius: 12px;
  display: inline-block;
  margin-bottom: 16px;
}

.modal-description {
  font-size: 13px;
  color: #525252;
  line-height: 1.6;
  margin-bottom: 20px;
}

.premium-features-list {
  text-align: left;
  background-color: #FAFAFA;
  padding: 16px;
  border-radius: 10px;
  border: 1px solid #E5E5E5;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 12px;
  color: #404040;
  font-weight: 500;
}

.modal-footer-row {
  display: flex;
  gap: 12px;
}

.btn-modal-primary, .btn-modal-secondary {
  flex: 1;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  text-align: center;
}

.btn-modal-primary {
  background-color: #0B529C;
  color: white;
  border: none;
}

.btn-modal-primary:hover {
  background-color: #09427D;
}

.btn-modal-secondary {
  background-color: white;
  color: #404040;
  border: 1px solid #E5E5E5;
}

.btn-modal-secondary:hover {
  background-color: #F5F5F5;
  border-color: #D4D4D4;
}
</style>
