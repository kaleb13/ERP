<script setup lang="ts">
import { 
  Package, AlertTriangle, TrendingUp, TrendingDown, 
  ArrowUpRight, ArrowDownRight, Activity, 
  Plus, Search, Filter, MoreVertical, Layers, Box, Truck,
  Monitor, ChevronRight
} from 'lucide-vue-next';
import MetricCard from '../components/MetricCard.vue';

// Mock data for the dashboard
const stats = [
  { label: 'Total Items', value: '2,845', change: '+12%', isPositive: true, icon: Package, color: 'text-blue-600', bg: 'bg-blue-50' },
  { label: 'Total Value', value: '$124,500', change: '+5.4%', isPositive: true, icon: TrendingUp, color: 'text-emerald-600', bg: 'bg-emerald-50' },
  { label: 'Low Stock', value: '42', change: '-2%', isPositive: false, icon: AlertTriangle, color: 'text-orange-600', bg: 'bg-orange-50' },
  { label: 'Out of Stock', value: '12', change: '+1', isPositive: false, icon: TrendingDown, color: 'text-red-600', bg: 'bg-red-50' },
];

const recentActivities = [
  { id: 1, action: 'Stock In', item: 'Nike Air Max', qty: '+50', time: '2 mins ago', user: 'John Doe', status: 'completed' },
  { id: 2, action: 'Stock Out', item: 'Adidas Ultraboost', qty: '-12', time: '15 mins ago', user: 'Jane Smith', status: 'completed' },
  { id: 3, action: 'Adjustment', item: 'Puma Suede', qty: '-2', time: '1 hour ago', user: 'Admin', status: 'pending' },
  { id: 4, action: 'New Item', item: 'New Balance 574', qty: '0', time: '3 hours ago', user: 'John Doe', status: 'completed' },
];
</script>

<template>
  <div class="inventory-dashboard">
    <!-- Breadcrumbs -->
    <div class="breadcrumbs">
      <router-link to="/dashboard" class="breadcrumb-link">
        <Monitor :size="16" />
      </router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <span class="breadcrumb-active">Overview</span>
    </div>

    <!-- Header -->
    <header class="dashboard-header">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Inventory Overview</h1>
        <p class="text-sm text-gray-500">Real-time stock monitoring and management</p>
      </div>
      <div class="header-actions">
        <button class="btn-secondary">
          <Filter :size="18" />
          <span>Filters</span>
        </button>
        <button class="btn-primary">
          <Plus :size="18" />
          <span>Add New Item</span>
        </button>
      </div>
    </header>

    <!-- Stats Grid (Using Centralized MetricCard Component) -->
    <div class="stats-grid">
      <MetricCard 
        v-for="stat in stats" 
        :key="stat.label" 
        :label="stat.label" 
        :value="stat.value" 
        subtext="Real-time status"
        :trend="stat.change"
        :trendType="stat.isPositive ? 'up' : 'down'"
      />
    </div>

    <!-- Main Content Grid -->
    <div class="content-grid">
      <!-- Chart Area (Simulated) -->
      <div class="card chart-container">
        <div class="card-header">
          <h3 class="card-title">Inventory by Category</h3>
          <button class="btn-icon-sm"><MoreVertical :size="16" /></button>
        </div>
        <div class="chart-content">
          <div class="bar-chart">
            <div class="bar-item" style="height: 80%;" data-label="Shoes"></div>
            <div class="bar-item" style="height: 45%;" data-label="Apparel"></div>
            <div class="bar-item" style="height: 60%;" data-label="Accessories"></div>
            <div class="bar-item" style="height: 30%;" data-label="Equipment"></div>
            <div class="bar-item" style="height: 70%;" data-label="Other"></div>
          </div>
          <div class="chart-labels">
            <span>Shoes</span>
            <span>Apparel</span>
            <span>Accs</span>
            <span>Equip</span>
            <span>Other</span>
          </div>
        </div>
      </div>

      <!-- Recent Activity Area -->
      <div class="card activity-container">
        <div class="card-header">
          <h3 class="card-title">Recent Activity</h3>
          <router-link to="/logs" class="text-sm text-blue-600 font-medium">View All</router-link>
        </div>
        <div class="activity-list">
          <div v-for="activity in recentActivities" :key="activity.id" class="activity-item">
            <div class="activity-icon-box">
              <Activity :size="16" class="text-gray-500" />
            </div>
            <div class="activity-details">
              <p class="activity-text">
                <span class="font-semibold">{{ activity.action }}</span>: 
                {{ activity.item }}
              </p>
              <div class="activity-meta">
                <span class="text-gray-500">{{ activity.time }}</span>
                <span class="dot"></span>
                <span class="text-gray-500">By {{ activity.user }}</span>
              </div>
            </div>
            <div :class="['activity-qty', activity.qty.startsWith('+') ? 'text-emerald-600' : 'text-red-600']">
              {{ activity.qty }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Management Area -->
    <div class="management-section card mt-6">
       <div class="card-header border-none">
          <h3 class="card-title">Quick Stock Management</h3>
       </div>
       <div class="quick-grid">
          <div class="quick-card">
             <Layers :size="24" class="text-blue-500 mb-3" />
             <h4>Inventory Check</h4>
             <p>Run a physical count verification.</p>
          </div>
          <div class="quick-card">
             <Truck :size="24" class="text-orange-500 mb-3" />
             <h4>Receive Stock</h4>
             <p>Log incoming shipment from suppliers.</p>
          </div>
          <div class="quick-card">
             <Box :size="24" class="text-emerald-500 mb-3" />
             <h4>Transfer Stock</h4>
             <p>Move items between warehouses.</p>
          </div>
       </div>
    </div>
  </div>
</template>

<style scoped>
.inventory-dashboard {
  animation: fadeIn 0.5s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
}

.header-actions {
  display: flex;
  gap: 12px;
}

.btn-primary, .btn-secondary {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary {
  background-color: var(--alias-color-brand-blue-primary);
  color: white;
  border: none;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

.btn-primary:hover {
  background-color: var(--alias-color-brand-blue-primary-hover);
}

/* Breadcrumbs */
.breadcrumbs {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  margin-bottom: 20px;
  font-family: 'Inter', sans-serif;
}

.breadcrumb-link {
  color: #6b7280; /* Perfect gray-like color */
  text-decoration: none;
  display: flex;
  align-items: center;
  transition: color 0.15s ease;
}

.breadcrumb-link:hover {
  color: #111827; /* Dark on hover */
}

.breadcrumb-separator {
  color: #9ca3af; /* Light gray chevron */
  display: flex;
  align-items: center;
}

.breadcrumb-active {
  color: #111827; /* Dark black color for active page */
  font-weight: 500;
}

.btn-secondary {
  background-color: white;
  color: #374151;
  border: 1px solid #e5e7eb;
}

.btn-secondary:hover {
  background-color: #f9fafb;
}

/* Stats Grid */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 24px;
  margin-bottom: 32px;
}

.stat-card {
  background: white;
  padding: 24px;
  border-radius: 16px;
  border: 1px solid #f3f4f6;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.stat-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}

.stat-icon-box {
  padding: 10px;
  border-radius: 12px;
  display: flex;
}

.stat-badge {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 600;
}

.badge-success { background: #ecfdf5; color: #059669; }
.badge-danger { background: #fef2f2; color: #dc2626; }

.stat-label { font-size: 14px; color: #6b7280; margin-bottom: 4px; }
.stat-value { font-size: 24px; font-weight: 700; color: #111827; }

/* Content Grid */
.content-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 24px;
}

@media (max-width: 1024px) {
  .content-grid { grid-template-columns: 1fr; }
}

.card {
  background: white;
  border-radius: 16px;
  border: 1px solid #f3f4f6;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
  display: flex;
  flex-direction: column;
}

.card-header {
  padding: 20px 24px;
  border-bottom: 1px solid #f3f4f6;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-title { font-size: 16px; font-weight: 600; color: #111827; }

/* Bar Chart Simulation */
.chart-content {
  padding: 24px;
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
}

.bar-chart {
  height: 200px;
  display: flex;
  align-items: flex-end;
  gap: 24px;
  padding: 0 20px;
}

.bar-item {
  flex: 1;
  background: #f3f4f6;
  border-radius: 6px 6px 0 0;
  transition: all 0.3s;
  cursor: pointer;
}

.bar-item:hover { background: #e5e7eb; }
.bar-item:nth-child(1) { background: #bfdbfe; }
.bar-item:nth-child(1):hover { background: #93c5fd; }

.chart-labels {
  display: flex;
  justify-content: space-around;
  margin-top: 16px;
  font-size: 12px;
  color: #9ca3af;
}

/* Activity List */
.activity-list {
  padding: 12px 24px;
}

.activity-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 0;
  border-bottom: 1px solid #f9fafb;
}

.activity-item:last-child { border-bottom: none; }

.activity-icon-box {
  width: 36px;
  height: 36px;
  background: #f9fafb;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.activity-details { flex: 1; }
.activity-text { font-size: 14px; color: #374151; margin-bottom: 2px; }
.activity-meta { display: flex; align-items: center; gap: 6px; font-size: 12px; }
.dot { width: 3px; height: 3px; background: #d1d5db; border-radius: 50%; }

.activity-qty { font-size: 14px; font-weight: 600; }

/* Quick Grid */
.quick-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
  padding: 0 24px 24px;
}

@media (max-width: 640px) {
  .quick-grid { grid-template-columns: 1fr; }
}

.quick-card {
  padding: 24px;
  border-radius: 12px;
  border: 1px solid #f3f4f6;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s;
}

.quick-card:hover {
  border-color: #e5e7eb;
  background-color: #fafafa;
  transform: translateY(-2px);
}

.quick-card h4 { font-size: 15px; font-weight: 600; margin-bottom: 8px; color: #111827; }
.quick-card p { font-size: 13px; color: #6b7280; }

.mt-6 { margin-top: 24px; }
.border-none { border: none; }
</style>
