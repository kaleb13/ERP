<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Box, ShoppingCart, DollarSign, ShoppingBag, Users, Tag, 
  Settings, Sliders, Building2, Search, Maximize, Moon, Languages, 
  Bell, ChevronDown, Check, Lock, X, Laptop, Star, ShieldAlert
} from 'lucide-vue-next';
import BaseTabs from '../components/BaseTabs.vue';

const router = useRouter();

// Active tab filter
const activeFilter = ref<'all' | 'subscribed' | 'unsubscribed'>('all');

// Filter tabs for the toolbar
const filterTabs: { id: 'all' | 'subscribed' | 'unsubscribed'; label: string }[] = [
  { id: 'all', label: 'All' },
  { id: 'subscribed', label: 'Subscribed' },
  { id: 'unsubscribed', label: 'Not Subscribed' }
];

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

// Modal for unsubscribed modules
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

// Module list matching the design mockup exactly
// Module list matching the design mockup exactly
const sections = ref([
  {
    title: 'Inventory Management',
    id: 'inventory_management',
    modules: [
      { 
        id: 'inventory', 
        title: 'Inventory', 
        desc: 'Tracks stock levels, movements, and warehouse operations...', 
        icon: Box, 
        iconColor: 'var(--primitive-color-blue-600)', 
        iconBg: 'var(--primitive-color-blue-50)', 
        subscribed: true, 
        route: '/dashboard' 
      },
      { 
        id: 'procurement', 
        title: 'Procurement', 
        desc: 'Tracks stock levels, movements, and warehouse operations...', 
        icon: ShoppingCart, 
        iconColor: 'var(--primitive-color-neutral-400)', 
        iconBg: 'var(--primitive-color-neutral-100)', 
        subscribed: false 
      },
      { 
        id: 'accounting_inv', 
        title: 'Accounting', 
        desc: 'Tracks stock levels, movements, and warehouse operations...', 
        icon: DollarSign, 
        iconColor: 'var(--primitive-color-purple-500)', 
        iconBg: 'var(--primitive-color-purple-50)', 
        subscribed: true 
      }
    ]
  },
  {
    title: 'Accounting Management',
    id: 'accounting_management',
    modules: [
      { 
        id: 'finance', 
        title: 'Finance', 
        desc: 'Tracks stock levels, movements, and warehouse operations...', 
        icon: DollarSign, 
        iconColor: 'var(--primitive-color-red-500)', 
        iconBg: 'var(--primitive-color-red-50)', 
        subscribed: true 
      },
      { 
        id: 'sales', 
        title: 'Sales', 
        desc: 'Tracks stock levels, movements, and warehouse operations...', 
        icon: ShoppingBag, 
        iconColor: 'var(--primitive-color-orange-500)', 
        iconBg: 'var(--primitive-color-orange-50)', 
        subscribed: true,
        route: '/sales'
      },
      { 
        id: 'hr', 
        title: 'Human Resources', 
        desc: 'Manage organizational structure, job architecture, positions, and workforce movements.', 
        icon: Users, 
        iconColor: 'var(--primitive-color-indigo-600)', 
        iconBg: 'var(--primitive-color-indigo-50)', 
        subscribed: true,
        route: '/hr/parties' 
      }
    ]
  },
  {
    title: 'Purchasing & Procurement',
    id: 'purchasing_procurement',
    modules: [
      { 
        id: 'buying', 
        title: 'Buying', 
        desc: 'Manage supplier relationships, purchase requests, and procurement.', 
        icon: Tag, 
        iconColor: 'var(--primitive-color-emerald-500)', 
        iconBg: 'var(--primitive-color-emerald-50)', 
        subscribed: true,
        route: '/buying'
      },
      { 
        id: 'selling', 
        title: 'Selling', 
        desc: 'Tracks stock levels, movements, and warehouse operations...', 
        icon: ShoppingBag, 
        iconColor: 'var(--primitive-color-neutral-400)', 
        iconBg: 'var(--primitive-color-neutral-100)', 
        subscribed: false 
      }
    ]
  },
  {
    title: 'Customizations',
    id: 'customizations',
    isCustom: true,
    modules: [
      { 
        id: 'sys_config', 
        title: 'System Config', 
        desc: 'The control tower of the entire platform', 
        icon: Sliders, 
        iconColor: 'var(--primitive-color-neutral-500)', 
        iconBg: 'var(--primitive-color-neutral-100)' 
      },
      { 
        id: 'company_setup', 
        title: 'Company Setup', 
        desc: 'Where businesses are shaped and structured', 
        icon: Building2, 
        iconColor: 'var(--primitive-color-neutral-500)', 
        iconBg: 'var(--primitive-color-neutral-100)',
        route: '/company-setup'
      },
      { 
        id: 'settings', 
        title: 'Settings', 
        desc: 'Explore settings to personalize your experience', 
        icon: Settings, 
        iconColor: 'var(--primitive-color-neutral-500)', 
        iconBg: 'var(--primitive-color-neutral-100)' 
      }
    ]
  }
]);

// Filtered sections and modules
const filteredSections = computed(() => {
  return sections.value.map(section => {
    let filteredMods = section.modules;

    // Filter by tab
    if (!section.isCustom) {
      if (activeFilter.value === 'subscribed') {
        filteredMods = filteredMods.filter(m => m.subscribed);
      } else if (activeFilter.value === 'unsubscribed') {
        filteredMods = filteredMods.filter(m => !m.subscribed);
      }
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
  if (section.isCustom) return '';
  const total = section.modules.length;
  const subscribed = section.modules.filter((m: any) => m.subscribed).length;
  // If fully filtered, just show the current matches ratio or mockup standard
  const initialTotal = sections.value.find(s => s.id === section.id)?.modules.length || total;
  const initialSubscribed = sections.value.find(s => s.id === section.id)?.modules.filter(m => m.subscribed).length || subscribed;
  return `${initialSubscribed}/${initialTotal}`;
};

// Handle module card click
const handleModuleClick = (mod: any) => {
  if (mod.route) {
    router.push(mod.route);
  } else if (mod.subscribed) {
    showToast(`Launching ${mod.title} Module... Welcome!`, 'success');
  } else if (mod.isCustomization) {
    showToast(`Opening ${mod.title}...`, 'info');
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
            <p class="brand-subtitle-portal">Admin Dashboard</p>
          </div>
        </div>

        <div class="topbar-right">
          <button class="btn-icon-portal"><Maximize :size="18" /></button>
          <button class="btn-icon-portal"><Moon :size="18" /></button>
          <button class="btn-icon-portal"><Languages :size="18" /></button>
          <button class="btn-icon-portal relative mr-2">
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
        <h2 class="welcome-title">Welcome!</h2>
        <p class="welcome-subtitle">Select a module to get started.</p>
        
        <!-- Search bar inside hero -->
        <div class="search-box-wrapper">
          <Search class="search-icon-hero" :size="18" />
          <input 
            type="text" 
            placeholder="Search Everything..." 
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
            <span class="summary-text">5 of 10 module subscribed</span>
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
                <span v-if="!section.isCustom" class="category-badge">
                  {{ getCategoryCountText(section) }}
                </span>
              </h3>
            </div>

            <!-- Cards Container -->
            <div class="cards-grid">
              <div 
                v-for="mod in section.modules" 
                :key="mod.title" 
                :class="['module-card', { 'unsubscribed-card': !section.isCustom && !mod.subscribed, 'customization-card': section.isCustom }]"
                @click="handleModuleClick(mod)"
              >
                <!-- Card Inner Header -->
                <div class="card-header-row">
                  <div class="card-icon-box" :style="{ backgroundColor: mod.iconBg }">
                    <component :is="mod.icon" :size="20" :style="{ color: mod.iconColor }" />
                  </div>
                </div>

                <!-- Card Content -->
                <div class="card-details">
                  <h4 class="card-title">{{ mod.title }}</h4>
                  <p class="card-desc">{{ mod.desc }}</p>
                </div>

                <!-- Card Status Footer -->
                <div v-if="!section.isCustom" class="card-status-footer">
                  <div v-if="mod.subscribed" class="subscribed-pill">
                    <Check :size="12" class="mr-1 text-emerald-500 stroke-[3px]" />
                    <span>Subscribed</span>
                  </div>
                  <div v-else class="unsubscribed-pill">
                    <Lock :size="10" class="mr-1 text-gray-400" />
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
        <span>©2026 Haleta Systems.</span>
        <span class="separator">|</span>
        <a href="#" @click.prevent="showToast('Contacting support...', 'info')">Contact Us</a>
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
            <Check v-if="toast.type === 'success'" :size="16" class="toast-icon text-emerald-500" />
            <Laptop v-else-if="toast.type === 'info'" :size="16" class="toast-icon text-blue-500" />
            <ShieldAlert v-else :size="16" class="toast-icon text-orange-500" />
            <span>{{ toast.message }}</span>
          </div>
        </div>
      </TransitionGroup>
    </div>

    <!-- PREMIUM UPGRADE MODAL -->
    <div v-if="isModalOpen" class="modal-overlay" @click.self="closeUpgradeModal">
      <div class="modal-card">
        <button class="modal-close-btn" @click="closeUpgradeModal">
          <X :size="18" />
        </button>
        
        <div class="modal-icon-header">
          <div class="premium-badge-icon">
            <Star :size="24" class="text-amber-500 fill-amber-500" />
          </div>
        </div>

        <div class="modal-body-content">
          <h3 class="modal-title">Unlock {{ selectedModule?.title }}</h3>
          <p class="modal-subtitle">Enterprise Suite Premium Module</p>
          <p class="modal-description">
            The <strong>{{ selectedModule?.title }}</strong> module is currently not included in your standard plan. 
            Upgrade to the Enterprise subscription to get full access to advanced logistics workflows, automated processing, and dedicated integrations.
          </p>

          <div class="premium-features-list">
            <div class="feature-item">
              <Check :size="14" class="text-emerald-500" />
              <span>Full read/write permissions for all warehouse personnel</span>
            </div>
            <div class="feature-item">
              <Check :size="14" class="text-emerald-500" />
              <span>Advanced auditing, export functionality & analytics</span>
            </div>
            <div class="feature-item">
              <Check :size="14" class="text-emerald-500" />
              <span>24/7 dedicated enterprise technical support</span>
            </div>
          </div>
        </div>

        <div class="modal-footer-row">
          <button class="btn-modal-secondary" @click="closeUpgradeModal">Maybe Later</button>
          <button 
            class="btn-modal-primary" 
            @click="showToast('Subscription request submitted!', 'success'); closeUpgradeModal()"
          >
            Upgrade Now
          </button>
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
  background-color: #f8fafc;
  font-family: 'Inter', sans-serif;
  overflow-x: hidden;
}

/* BLUE HERO HEADER */
.hero-section {
  background: linear-gradient(to right, #0B529C, #0084D1);
  color: white;
  padding-bottom: 48px;
  position: relative;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

/* HOME TOP BAR */
.home-topbar {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 40px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.logo-box-portal {
  background: rgba(255, 255, 255, 0.15);
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
  font-size: 14px;
  font-weight: 700;
  color: #ffffff;
  margin: 0;
}

.brand-subtitle-portal {
  font-size: 10px;
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
  color: rgba(255, 255, 255, 0.8);
  cursor: pointer;
  padding: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  transition: all 0.2s;
}

.btn-icon-portal:hover {
  color: #ffffff;
  background-color: rgba(255, 255, 255, 0.1);
}

.topbar-separator-portal {
  width: 1px;
  height: 20px;
  background-color: rgba(255, 255, 255, 0.2);
  margin: 0 12px;
}

.profile-wrapper-portal {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 10px;
  transition: background 0.2s;
}

.profile-wrapper-portal:hover {
  background-color: rgba(255, 255, 255, 0.1);
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
  border: 1.5px solid rgba(255, 255, 255, 0.6);
}

text-indicator-portal {
}

.status-indicator-portal {
  position: absolute;
  bottom: 0;
  right: 0;
  width: 8px;
  height: 8px;
  background-color: #10b981;
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
  border: 1.5px solid #0B529C;
}

/* HERO WELCOME CONTAINER */
.welcome-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  margin-top: 40px;
}

.welcome-title {
  font-size: 32px;
  font-weight: 700;
  letter-spacing: -0.02em;
  margin-bottom: 6px;
}

.welcome-subtitle {
  font-size: 16px;
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
  color: rgba(255, 255, 255, 0.6);
  pointer-events: none;
  z-index: 10;
}

.search-input-hero {
  width: 100%;
  height: 46px;
  padding: 12px 16px 12px 48px;
  border-radius: 24px;
  border: 1.5px solid rgba(255, 255, 255, 0.15);
  background-color: rgba(255, 255, 255, 0.12);
  color: #ffffff;
  font-size: 14px;
  outline: none;
  backdrop-filter: blur(8px);
  transition: all 0.25s ease;
}

.search-input-hero::placeholder {
  color: rgba(255, 255, 255, 0.6);
}

.search-input-hero:focus {
  border-color: rgba(255, 255, 255, 0.85);
  background-color: rgba(255, 255, 255, 0.2);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
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
  border-bottom: 1px solid #e2e8f0;
  padding-bottom: 16px;
}

.subscribed-summary {
  font-size: 13px;
  color: #64748b;
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
  color: #1e293b;
  display: flex;
  align-items: center;
  gap: 8px;
}

.category-badge {
  font-size: 11px;
  font-weight: 500;
  background-color: #f1f5f9;
  color: #64748b;
  padding: 2px 6px;
  border-radius: 4px;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
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
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 20px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  position: relative;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
  min-height: 180px;
}

.customization-card {
  min-height: 130px;
}

.module-card:hover {
  transform: translateY(-4px);
  border-color: #cbd5e1;
  box-shadow: 0 10px 20px -5px rgba(0, 0, 0, 0.05), 0 4px 6px -2px rgba(0, 0, 0, 0.02);
}

.card-header-row {
  margin-bottom: 16px;
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

.card-details {
  flex: 1;
}

.card-title {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 6px;
}

.card-desc {
  font-size: 12px;
  color: #64748b;
  line-height: 1.5;
  margin-bottom: 12px;
}

.card-status-footer {
  margin-top: auto;
  display: flex;
  align-items: center;
  font-size: 11px;
  font-weight: 400;
}

.subscribed-pill {
  color: #10b981;
  display: flex;
  align-items: center;
}

.unsubscribed-pill {
  color: #64748b;
  display: flex;
  align-items: center;
  background-color: #f1f5f9;
  padding: 3px 8px;
  border-radius: 12px;
}

/* UNSUBSCRIBED CARD SPECIFICS */
.unsubscribed-card {
  background-color: #fafbfc;
  border-style: solid;
}

.unsubscribed-card .card-title {
  color: #64748b;
}

.unsubscribed-card .card-desc {
  color: #94a3b8;
}

/* PORTAL FOOTER */
.portal-footer {
  border-top: 1px solid #e2e8f0;
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
  color: #64748b;
  flex-wrap: wrap;
  justify-content: center;
}

.footer-links a {
  color: #64748b;
  text-decoration: none;
  transition: color 0.2s;
}

.footer-links a:hover {
  color: #0084D1;
}

.separator {
  color: #cbd5e1;
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
  border-radius: 12px;
  padding: 12px 18px;
  min-width: 280px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  border-left: 4px solid #10b981;
  display: flex;
  align-items: center;
}

.toast-success { border-left-color: #10b981; }
.toast-info { border-left-color: #3b82f6; }
.toast-warning { border-left-color: #f97316; }

.toast-content {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  font-weight: 500;
  color: #334155;
}

.toast-icon {
  flex-shrink: 0;
}

/* Toast Transitions */
.toast-enter-active, .toast-leave-active {
  transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}
.toast-enter-from {
  opacity: 0;
  transform: translateX(50px) scale(0.9);
}
.toast-leave-to {
  opacity: 0;
  transform: translateY(-20px) scale(0.9);
}

/* MODAL OVERLAY */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(15, 23, 42, 0.6);
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
  border-radius: 16px;
  width: 100%;
  max-width: 460px;
  padding: 28px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.15), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  position: relative;
  display: flex;
  flex-direction: column;
  animation: modalSlideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes modalSlideUp {
  from { transform: translateY(20px) scale(0.95); }
  to { transform: translateY(0) scale(1); }
}

.modal-close-btn {
  position: absolute;
  top: 18px;
  right: 18px;
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 6px;
  border-radius: 50%;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-close-btn:hover {
  background-color: #f1f5f9;
  color: #475569;
}

.modal-icon-header {
  display: flex;
  justify-content: center;
  margin-bottom: 16px;
}

.premium-badge-icon {
  width: 56px;
  height: 56px;
  background-color: #fef3c7;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 0 0 4px #fffbeb;
}

.modal-body-content {
  text-align: center;
  margin-bottom: 24px;
}

.modal-title {
  font-size: 18px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 4px;
}

.modal-subtitle {
  font-size: 11px;
  font-weight: 700;
  color: #b45309;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  background-color: #fef3c7;
  padding: 2px 8px;
  border-radius: 12px;
  display: inline-block;
  margin-bottom: 16px;
}

.modal-description {
  font-size: 13px;
  color: #475569;
  line-height: 1.6;
  margin-bottom: 20px;
}

.premium-features-list {
  text-align: left;
  background-color: #f8fafc;
  padding: 16px;
  border-radius: 12px;
  border: 1px solid #f1f5f9;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 12px;
  color: #334155;
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
  background-color: var(--alias-color-brand-blue-primary);
  color: white;
  border: none;
}

.btn-modal-primary:hover {
  background-color: var(--alias-color-brand-blue-primary-hover);
}

.btn-modal-secondary {
  background-color: white;
  color: #475569;
  border: 1px solid #e2e8f0;
}

.btn-modal-secondary:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}
</style>
