<script setup lang="ts">
import { ref } from 'vue';
import DashboardLayout from '../layouts/DashboardLayout.vue';
import { 
  Monitor, ChevronRight, ChevronDown, Layers, Box, CheckCircle, XCircle,
  Search, Filter, ArrowUpDown, Plus, MoreVertical 
} from 'lucide-vue-next';

// Dummy data matching the image
const summaryCards = [
  { value: '8', label: 'Module Groups', icon: Layers, iconColor: 'text-gray-500', iconBg: 'bg-gray-100' },
  { value: '8', label: 'Total Modules', icon: Box, iconColor: 'text-blue-500', iconBg: 'bg-blue-50' },
  { value: '7', label: 'Active Modules', icon: CheckCircle, iconColor: 'text-green-500', iconBg: 'bg-green-50' },
  { value: '1', label: 'In Active Modules', icon: XCircle, iconColor: 'text-red-500', iconBg: 'bg-red-50' }
];

const organizations = [
  {
    id: 1,
    name: 'QMT Addis Branch Org',
    code: 'QMT-ORG-001',
    parent: 'QMT Business Group',
    branches: ['Qelem meda', 'Qelem Hibr', 'Qelem Awtar'],
    extraBranches: '+5',
    state: 'Active'
  }
];
</script>

<template>
  <DashboardLayout>
    <div class="org-layout">
      <!-- Breadcrumb -->
      <div class="breadcrumb">
        <Monitor :size="14" class="icon-dashboard" />
        <ChevronRight :size="12" class="sep" />
        <span class="current">Organizations</span>
      </div>

      <!-- Header Section -->
      <div class="page-container p-6 bg-white rounded-xl shadow-sm border border-gray-200 mt-4 mb-6">
        <div class="page-header mb-6">
          <h2 class="text-xl font-bold text-gray-900 mb-1">Organizations</h2>
          <p class="text-sm text-gray-500">Establish legally distinct companies under your group.</p>
        </div>

        <!-- Metrics Cards -->
        <div class="metrics-grid">
          <div class="metric-card" v-for="(card, i) in summaryCards" :key="i">
            <div>
              <div class="text-2xl font-bold text-gray-900">{{ card.value }}</div>
              <div class="text-xs text-gray-500 mt-1">{{ card.label }}</div>
            </div>
            <div :class="['metric-icon-box', card.iconBg, card.iconColor]">
              <component :is="card.icon" :size="18" />
            </div>
          </div>
        </div>
      </div>

      <!-- Main Table Section -->
      <div class="page-container bg-white rounded-xl shadow-sm border border-gray-200">
        <!-- Toolbar -->
        <div class="toolbar p-4 border-b border-gray-100 flex items-center justify-between">
          <div class="toolbar-left flex gap-3">
            <div class="search-box">
              <Search :size="16" class="search-icon" />
              <input type="text" placeholder="Search..." class="search-input" />
            </div>
            <button class="btn-outline flex items-center gap-2">
              <Filter :size="14" /> Filter
            </button>
            <button class="btn-outline flex items-center gap-2">
              <ArrowUpDown :size="14" /> Sort <ChevronDown class="ml-1" :size="12"/>
            </button>
          </div>
          <div class="toolbar-right">
            <button class="btn-primary flex items-center gap-2">
              <Plus :size="14" /> Create Organization
            </button>
          </div>
        </div>

        <!-- Table -->
        <div class="table-responsive">
          <table class="w-full text-left text-sm text-gray-700">
            <thead class="text-xs text-gray-500 border-b border-gray-100">
              <tr>
                <th class="px-6 py-4 font-semibold">Feature Name</th>
                <th class="px-6 py-4 font-semibold">Parent</th>
                <th class="px-6 py-4 font-semibold">Branches <span class="help-icon">?</span></th>
                <th class="px-6 py-4 font-semibold">State</th>
                <th class="px-6 py-4 font-semibold">Action</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="org in organizations" :key="org.id" class="border-b border-gray-50 hover:bg-gray-50">
                <td class="px-6 py-4">
                  <div class="font-medium text-gray-900">{{ org.name }}</div>
                  <div class="text-xs text-gray-400 mt-1">{{ org.code }}</div>
                </td>
                <td class="px-6 py-4 text-gray-500">{{ org.parent }}</td>
                <td class="px-6 py-4">
                  <div class="flex gap-2 items-center">
                    <span class="chip" v-for="b in org.branches" :key="b">{{ b }}</span>
                    <span class="chip-extra">{{ org.extraBranches }}</span>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <span class="badge badge-success">{{ org.state }}</span>
                </td>
                <td class="px-6 py-4">
                  <button class="text-gray-400 hover:text-gray-600">
                    <MoreVertical :size="16" />
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination Footer -->
        <div class="pagination-footer p-4 border-t border-gray-100 flex items-center justify-between text-sm text-gray-500">
          <div class="flex items-center gap-4">
            <span>Showing 1 to 2 of 2 entries</span>
            <div class="flex items-center gap-2">
              <span>Per Page:</span>
              <select class="per-page-select">
                <option>1</option>
                <option>10</option>
                <option>50</option>
              </select>
            </div>
          </div>
          
          <div class="flex items-center border border-gray-200 rounded-md overflow-hidden">
            <button class="page-btn flex items-center gap-1 border-r border-gray-200 px-3">
              <ChevronRight class="rotate-180" :size="14" /> Previous
            </button>
            <button class="page-btn active">1</button>
            <button class="page-btn">2</button>
            <button class="page-btn">3</button>
            <button class="page-btn px-2">...</button>
            <button class="page-btn">8</button>
            <button class="page-btn">9</button>
            <button class="page-btn border-r-0">10</button>
            <button class="page-btn flex items-center gap-1 border-l border-gray-200 px-3">
              Next <ChevronRight :size="14" />
            </button>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
/* Scoped specific to Organizations View */
.org-layout {
  max-width: 1200px;
  margin: 0 auto;
}

.breadcrumb {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #6b7280;
  font-size: 12px;
}
.sep { color: #d1d5db; }
.current { color: #374151; font-weight: 500; }

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.metric-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
  border: 1px solid #e5e5e5;
  border-radius: 12px;
}

.metric-icon-box {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.search-box {
  position: relative;
  width: 300px;
}

.search-input {
  width: 100%;
  padding: 8px 12px 8px 36px;
  border: 1px solid #e5e5e5;
  border-radius: 6px;
  font-size: 13px;
  outline: none;
}

.search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #9ca3af;
}

.btn-outline {
  padding: 8px 16px;
  border: 1px solid #e5e5e5;
  background: white;
  color: #374151;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.btn-primary {
  padding: 8px 16px;
  background: #0056b3;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.chip {
  background: #eff6ff;
  color: #2563eb;
  padding: 4px 8px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 500;
}
.chip-extra {
  background: #f3f4f6;
  color: #4b5563;
  padding: 4px 8px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 500;
}

.badge-success {
  background: #dcfce7;
  color: #16a34a;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 500;
}

.help-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 14px;
  height: 14px;
  border: 1px solid #d1d5db;
  border-radius: 50%;
  font-size: 9px;
  color: #6b7280;
  margin-left: 4px;
}

.per-page-select {
  border: 1px solid #e5e5e5;
  border-radius: 4px;
  padding: 4px 8px;
  font-size: 13px;
  outline: none;
}

.page-btn {
  padding: 6px 12px;
  background: white;
  border: none;
  border-right: 1px solid #e5e5e5;
  color: #374151;
  cursor: pointer;
  font-size: 13px;
}
.page-btn:last-child {
  border-right: none;
}
.page-btn:hover {
  background: #f9fafb;
}
.page-btn.active {
  background: #0056b3;
  color: white;
  font-weight: 500;
}
</style>
