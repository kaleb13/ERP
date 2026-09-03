<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  Monitor, ChevronRight, Search, Filter, ArrowUpDown, ChevronDown, Maximize,
  Plus, Copy, Check, MoreVertical, Edit2, Trash2, UserCheck, UserX, Columns,
  Shield, Key, Users, Eye, RotateCcw
} from 'lucide-vue-next';
import BaseTabs from '../components/BaseTabs.vue';
import BasePagination from '../components/BasePagination.vue';
import BaseButton from '../components/BaseButton.vue';
import AppBreadcrumb from '../components/AppBreadcrumb.vue';

const router = useRouter();
const route = useRoute();

// Active Tab synced with route query
type UATab = 'users' | 'roles' | 'permissions';
const activeTab = ref<UATab>('users');

const syncTabFromRoute = () => {
  const tabQuery = route.query.tab as string;
  if (tabQuery === 'roles') {
    activeTab.value = 'roles';
  } else if (tabQuery === 'permissions') {
    activeTab.value = 'permissions';
  } else {
    activeTab.value = 'users';
  }
};

onMounted(() => {
  syncTabFromRoute();
});

watch(() => route.query.tab, () => {
  syncTabFromRoute();
});

const setTab = (tab: UATab) => {
  activeTab.value = tab;
  if (tab === 'users') {
    router.push({ path: '/company-setup/user-and-access' });
  } else {
    router.push({ path: '/company-setup/user-and-access', query: { tab } });
  }
};

const tabs = [
  { id: 'users' as const, label: 'Users', icon: Users },
  { id: 'roles' as const, label: 'Roles', icon: UserCheck },
  { id: 'permissions' as const, label: 'Permissions', icon: Key }
];

// Controls & Filter state
const searchQuery = ref('');
const statusFilter = ref<string>('All');
const roleFilter = ref<string>('All');
const genderFilter = ref<string>('All');
const showFilterSection = ref(false);

const activeFilterCount = computed(() => {
  let count = 0;
  if (statusFilter.value !== 'All') count++;
  if (roleFilter.value !== 'All') count++;
  if (genderFilter.value !== 'All') count++;
  return count;
});

const resetAllFilters = () => {
  searchQuery.value = '';
  statusFilter.value = 'All';
  roleFilter.value = 'All';
  genderFilter.value = 'All';
};

const sortBy = ref<'id' | 'name' | 'role' | 'status'>('id');
const sortOrder = ref<'asc' | 'desc'>('asc');
const showSortDropdown = ref(false);

const toggleSort = (field: 'id' | 'name' | 'role' | 'status') => {
  if (sortBy.value === field) {
    sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
  } else {
    sortBy.value = field;
    sortOrder.value = 'asc';
  }
  showSortDropdown.value = false;
};

// Selection state
const selectedUserIds = ref<number[]>([]);
const selectAll = ref(false);

const toggleSelectAll = () => {
  if (selectAll.value) {
    selectedUserIds.value = filteredUsers.value.map(u => u.id);
  } else {
    selectedUserIds.value = [];
  }
};

const isUserSelected = (id: number) => selectedUserIds.value.includes(id);

const toggleUserSelection = (id: number) => {
  if (isUserSelected(id)) {
    selectedUserIds.value = selectedUserIds.value.filter(i => i !== id);
  } else {
    selectedUserIds.value.push(id);
  }
};

// Copy feedback state
const copiedIdMap = ref<Record<number, boolean>>({});

const copyNationalId = async (id: number, text: string) => {
  try {
    await navigator.clipboard.writeText(text);
    copiedIdMap.value[id] = true;
    setTimeout(() => {
      copiedIdMap.value[id] = false;
    }, 1800);
  } catch (err) {
    console.error('Failed to copy: ', err);
  }
};

// Column Visibility State
const showColumnsDropdown = ref(false);
const visibleColumns = ref({
  no: true,
  name: true,
  gender: true,
  role: true,
  nationalId: true,
  state: true,
  actions: true
});

const toggleColumnsDropdown = (e: Event) => {
  e.stopPropagation();
  showColumnsDropdown.value = !showColumnsDropdown.value;
  showSortDropdown.value = false;
};

// Fullscreen State
const isFullscreen = ref(false);
const toggleFullscreen = () => {
  isFullscreen.value = !isFullscreen.value;
};

// Active Dropdown Action Menu
const activeActionMenuId = ref<number | null>(null);

const toggleActionMenu = (e: Event, id: number) => {
  e.stopPropagation();
  if (activeActionMenuId.value === id) {
    activeActionMenuId.value = null;
  } else {
    activeActionMenuId.value = id;
  }
};

const closeActionMenus = () => {
  activeActionMenuId.value = null;
  showSortDropdown.value = false;
  showColumnsDropdown.value = false;
};

if (typeof window !== 'undefined') {
  window.addEventListener('click', closeActionMenus);
}

// User List Seed Data matching redesign specs
const users = ref([
  {
    id: 1,
    name: 'Abebe Kebede',
    email: 'abebe@gmail.com',
    gender: 'Male',
    role: 'Admin',
    nationalId: '6535243542432',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    status: 'Active'
  },
  {
    id: 2,
    name: 'Kidst Tesfaye',
    email: 'kidist21@gmail.com',
    gender: 'Female',
    role: 'Product Manager',
    nationalId: '6535243542432',
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    status: 'Active'
  },
  {
    id: 3,
    name: 'Mihret Abera',
    email: 'mihret18@gmail.com',
    gender: 'Female',
    role: 'Branch Manager',
    nationalId: '6535243542432',
    avatar: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
    status: 'Inactive'
  },
  {
    id: 4,
    name: 'Dawit Haile',
    email: 'dawit@haleta.com',
    gender: 'Male',
    role: 'Inventory Officer',
    nationalId: '6535243542432',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    status: 'Active'
  },
  {
    id: 5,
    name: 'Tigist Alemu',
    email: 'tigist@haleta.com',
    gender: 'Female',
    role: 'Accountant',
    nationalId: '6535243542432',
    avatar: 'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?w=150&auto=format&fit=crop&q=80',
    status: 'Active'
  }
]);

// Roles & Permissions Seed Data
const roles = ref([
  { id: 1, name: 'Admin', description: 'Full system administrative control and access to all settings.', userCount: 2, status: 'Active' },
  { id: 2, name: 'Product Manager', description: 'Manage products, pricing tiers, variants, and stock categories.', userCount: 1, status: 'Active' },
  { id: 3, name: 'Branch Manager', description: 'Oversee entity operations, point of sales, and branch level staff.', userCount: 1, status: 'Active' },
  { id: 4, name: 'Inventory Officer', description: 'Handle stock movement, reservation passes, and inventory ledger.', userCount: 1, status: 'Active' },
  { id: 5, name: 'Accountant', description: 'Financial controls, TIN configuration, and reporting invoices.', userCount: 1, status: 'Active' }
]);

const permissions = ref([
  { id: 1, name: 'Create User', module: 'User Management', category: 'User Management', status: 'Active' },
  { id: 2, name: 'View User List', module: 'User Management', category: 'User Management', status: 'Active' },
  { id: 3, name: 'Edit User Information', module: 'User Management', category: 'User Management', status: 'Active' },
  { id: 4, name: 'Reset User Password', module: 'User Management', category: 'User Management', status: 'Active' },
  { id: 5, name: 'Manage User Role', module: 'User Management', category: 'User Management', status: 'Active' },
  { id: 6, name: 'Delete User', module: 'User Management', category: 'User Management', status: 'Active' }
]);

// Filtering & Sorting
const filteredUsers = computed(() => {
  let list = [...users.value];
  const q = searchQuery.value.toLowerCase().trim();

  if (q) {
    list = list.filter(u =>
      u.name.toLowerCase().includes(q) ||
      u.email.toLowerCase().includes(q) ||
      u.role.toLowerCase().includes(q) ||
      u.nationalId.includes(q)
    );
  }

  if (statusFilter.value !== 'All') {
    list = list.filter(u => u.status === statusFilter.value);
  }

  if (roleFilter.value !== 'All') {
    list = list.filter(u => u.role === roleFilter.value);
  }

  if (genderFilter.value !== 'All') {
    list = list.filter(u => u.gender === genderFilter.value);
  }

  list.sort((a, b) => {
    let valA = a[sortBy.value];
    let valB = b[sortBy.value];
    if (typeof valA === 'string') valA = valA.toLowerCase();
    if (typeof valB === 'string') valB = valB.toLowerCase();

    if (valA < valB) return sortOrder.value === 'asc' ? -1 : 1;
    if (valA > valB) return sortOrder.value === 'asc' ? 1 : -1;
    return 0;
  });

  return list;
});

const filteredRoles = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return roles.value;
  return roles.value.filter(r =>
    r.name.toLowerCase().includes(q) || r.description.toLowerCase().includes(q)
  );
});

const filteredPermissions = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return permissions.value;
  return permissions.value.filter(p =>
    p.name.toLowerCase().includes(q) || p.module.toLowerCase().includes(q)
  );
});

// Pagination state
const currentPage = ref(1);
const perPage = ref(10);

const totalPages = computed(() => Math.ceil(filteredUsers.value.length / perPage.value) || 1);

const paginatedUsers = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredUsers.value.slice(start, start + perPage.value);
});

// User Actions
const toggleUserStatus = (id: number) => {
  const target = users.value.find(u => u.id === id);
  if (target) {
    target.status = target.status === 'Active' ? 'Inactive' : 'Active';
  }
  activeActionMenuId.value = null;
};

const handleDeleteUser = (id: number) => {
  if (confirm('Are you sure you want to delete this user?')) {
    users.value = users.value.filter(u => u.id !== id);
  }
  activeActionMenuId.value = null;
};

const goToCreateUser = () => {
  router.push('/company-setup/user-and-access/users/create');
};

const goToEditUser = (id: number) => {
  router.push(`/company-setup/user-and-access/users/${id}`);
};

const getInitials = (name: string) => {
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
};
</script>

<template>
  <div class="user-management-page">

    <!-- Top Breadcrumbs -->
    <AppBreadcrumb :items="[{ label: 'User & Access' }]" />

    <!-- TABLE SECTION CARD: Table Title, Toolbar, Inline Filters, Table & Pagination -->
    <div :class="['table-section-card', { 'is-fullscreen': isFullscreen }]">

      <!-- Optional Tab Switcher Bar if route has ?tab=... -->
      <div v-if="route.query.tab" class="tabs-header-bar mb-4">
        <BaseTabs :model-value="activeTab" :tabs="tabs" size="md" @update:model-value="setTab" />
      </div>

      <!-- Table Title & Description Header -->
      <div class="table-header-title-block">
        <h2 class="table-block-title">
          {{ activeTab === 'users' ? 'Users Directory' : activeTab === 'roles' ? 'Roles Directory' : 'Permissions Directory' }}
        </h2>
        <p class="table-block-subtitle">
          {{ activeTab === 'users' ? 'List of registered system users, roles, and status configurations.' : activeTab === 'roles' ? 'System access roles and permissions distribution.' : 'Granular access control policies and permission assignments.' }}
        </p>
      </div>

      <!-- Action Controls Toolbar -->
      <div class="toolbar-wrapper">
        <div class="toolbar-left">
          <!-- Search input -->
          <div class="search-box">
            <Search :size="16" class="search-box-icon" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search works ..."
              class="search-box-input"
            />
          </div>

          <!-- Filter Toggle Button -->
          <button 
            class="toolbar-btn" 
            :class="{ 'btn-active': activeFilterCount > 0 || showFilterSection }"
            @click.stop="showFilterSection = !showFilterSection; showSortDropdown = false;"
          >
            <Filter :size="15" />
            <span>Filter</span>
            <span v-if="activeFilterCount > 0" class="filter-count-badge">{{ activeFilterCount }}</span>
            <ChevronDown :size="12" class="ml-1 opacity-60" :class="{ 'rotate-180': showFilterSection }" />
          </button>

          <!-- Sort button with dropdown -->
          <div class="relative-dropdown">
            <button 
              class="toolbar-btn" 
              @click.stop="showSortDropdown = !showSortDropdown;"
            >
              <ArrowUpDown :size="15" />
              <span>Sort</span>
              <ChevronDown :size="12" class="ml-1 opacity-60" />
            </button>

            <div v-if="showSortDropdown" class="dropdown-popover sort-popover" @click.stop>
              <button class="sort-option" @click="toggleSort('name')">
                <span>Name</span>
                <span v-if="sortBy === 'name'" class="text-blue-600 font-bold ml-auto">{{ sortOrder === 'asc' ? 'A-Z' : 'Z-A' }}</span>
              </button>
              <button class="sort-option" @click="toggleSort('role')">
                <span>Role</span>
                <span v-if="sortBy === 'role'" class="text-blue-600 font-bold ml-auto">{{ sortOrder === 'asc' ? 'A-Z' : 'Z-A' }}</span>
              </button>
              <button class="sort-option" @click="toggleSort('status')">
                <span>Status</span>
                <span v-if="sortBy === 'status'" class="text-blue-600 font-bold ml-auto">{{ sortOrder === 'asc' ? 'A-Z' : 'Z-A' }}</span>
              </button>
            </div>
          </div>
        </div>

        <div class="toolbar-right">
          <!-- Column Hide / Show Toggle Dropdown -->
          <div class="relative-dropdown">
            <button 
              class="icon-toggle-btn" 
              :class="{ 'btn-active': showColumnsDropdown }"
              @click.stop="toggleColumnsDropdown" 
              title="Show / Hide Columns"
            >
              <Columns :size="16" />
            </button>

            <!-- Columns Selection Popover -->
            <div v-if="showColumnsDropdown" class="dropdown-popover columns-popover" @click.stop>
              <div class="popover-title-text">Show / Hide Columns</div>
              <div class="columns-list-container">
                <label class="column-option-item">
                  <input type="checkbox" v-model="visibleColumns.no" class="custom-checkbox" />
                  <span>No. (Index)</span>
                </label>
                <label class="column-option-item">
                  <input type="checkbox" v-model="visibleColumns.name" class="custom-checkbox" />
                  <span>Name & Email</span>
                </label>
                <label class="column-option-item">
                  <input type="checkbox" v-model="visibleColumns.gender" class="custom-checkbox" />
                  <span>Gender</span>
                </label>
                <label class="column-option-item">
                  <input type="checkbox" v-model="visibleColumns.role" class="custom-checkbox" />
                  <span>Role</span>
                </label>
                <label class="column-option-item">
                  <input type="checkbox" v-model="visibleColumns.nationalId" class="custom-checkbox" />
                  <span>National ID</span>
                </label>
                <label class="column-option-item">
                  <input type="checkbox" v-model="visibleColumns.state" class="custom-checkbox" />
                  <span>State / Status</span>
                </label>
                <label class="column-option-item">
                  <input type="checkbox" v-model="visibleColumns.actions" class="custom-checkbox" />
                  <span>Actions Menu</span>
                </label>
              </div>
            </div>
          </div>

          <!-- Fullscreen Toggle Button -->
          <button 
            class="icon-toggle-btn" 
            :class="{ 'btn-active': isFullscreen }" 
            @click="toggleFullscreen" 
            title="Toggle Fullscreen"
          >
            <Maximize :size="16" />
          </button>

          <!-- Create User Primary Action Button -->
          <BaseButton variant="primary" @click="goToCreateUser">
            <template #icon-left><Plus :size="18" stroke-width="2.5" /></template>
            <span>Create User</span>
          </BaseButton>
        </div>
      </div>

      <!-- REVEALING FILTER PANEL (STANDARD ERP COMPONENT PATTERN) -->
      <transition name="slide-down">
        <div v-if="showFilterSection" class="filter-panel">
          <div class="filter-group">
            <label class="filter-label">Role</label>
            <select v-model="roleFilter" class="filter-select">
              <option value="All">All Roles</option>
              <option value="Admin">Admin</option>
              <option value="Product Manager">Product Manager</option>
              <option value="Branch Manager">Branch Manager</option>
              <option value="Inventory Officer">Inventory Officer</option>
              <option value="Accountant">Accountant</option>
            </select>
          </div>

          <div class="filter-group">
            <label class="filter-label">Gender</label>
            <select v-model="genderFilter" class="filter-select">
              <option value="All">All Genders</option>
              <option value="Male">Male</option>
              <option value="Female">Female</option>
            </select>
          </div>

          <div class="filter-group">
            <label class="filter-label">Status</label>
            <select v-model="statusFilter" class="filter-select">
              <option value="All">All Statuses</option>
              <option value="Active">Active</option>
              <option value="Inactive">Inactive</option>
            </select>
          </div>

          <BaseButton variant="secondary" size="sm" @click="resetAllFilters">
            <template #icon-left><RotateCcw :size="14" /></template>
            <span>Reset</span>
          </BaseButton>
        </div>
      </transition>

      <!-- TABLE CONTAINER -->
      <div class="table-container">

        <!-- USERS TABLE -->
        <table v-if="activeTab === 'users'" class="erp-table">
          <thead>
            <tr>
              <th class="col-checkbox">
                <input 
                  type="checkbox" 
                  v-model="selectAll" 
                  @change="toggleSelectAll" 
                  class="custom-checkbox"
                />
              </th>
              <th v-if="visibleColumns.no" class="col-no">No.</th>
              <th v-if="visibleColumns.name" class="col-name">Name</th>
              <th v-if="visibleColumns.gender" class="col-gender">Gender</th>
              <th v-if="visibleColumns.role" class="col-role">Role</th>
              <th v-if="visibleColumns.nationalId" class="col-nid">National ID</th>
              <th v-if="visibleColumns.state" class="col-state">State</th>
              <th v-if="visibleColumns.actions" class="col-actions text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="(user, idx) in paginatedUsers" 
              :key="user.id" 
              :class="{ 'row-selected': isUserSelected(user.id) }"
            >
              <!-- Checkbox -->
              <td class="col-checkbox">
                <input 
                  type="checkbox" 
                  :checked="isUserSelected(user.id)" 
                  @change="toggleUserSelection(user.id)"
                  class="custom-checkbox"
                />
              </td>

              <!-- Row Index No. -->
              <td v-if="visibleColumns.no" class="col-no">
                {{ (currentPage - 1) * perPage + idx + 1 }}
              </td>

              <!-- Avatar + Name + Email (First text column after number) -->
              <td v-if="visibleColumns.name" class="col-name">
                <div class="user-identity">
                  <img 
                    v-if="user.avatar" 
                    :src="user.avatar" 
                    :alt="user.name" 
                    class="user-avatar-img" 
                  />
                  <div v-else class="user-avatar-fallback">
                    {{ getInitials(user.name) }}
                  </div>
                  <div class="user-name-stack">
                    <span class="user-full-name">{{ user.name }}</span>
                    <span class="user-email-text">{{ user.email }}</span>
                  </div>
                </div>
              </td>

              <!-- Gender -->
              <td v-if="visibleColumns.gender" class="col-gender">
                {{ user.gender }}
              </td>

              <!-- Role -->
              <td v-if="visibleColumns.role" class="col-role">
                {{ user.role }}
              </td>

              <!-- National ID + Copy Button -->
              <td v-if="visibleColumns.nationalId" class="col-nid">
                <div class="nid-wrapper">
                  <span class="nid-text">{{ user.nationalId }}</span>
                  <button 
                    class="btn-copy-id" 
                    @click="copyNationalId(user.id, user.nationalId)"
                    :title="copiedIdMap[user.id] ? 'Copied!' : 'Copy National ID'"
                  >
                    <Check v-if="copiedIdMap[user.id]" :size="14" class="text-emerald-600 animate-bounce" />
                    <Copy v-else :size="14" class="text-slate-400 hover:text-slate-700 transition-colors" />
                  </button>
                </div>
              </td>

              <!-- Status Badge (Active / Inactive) -->
              <td v-if="visibleColumns.state" class="col-state">
                <span 
                  :class="[
                    'status-pill', 
                    user.status === 'Active' ? 'pill-active' : 'pill-inactive'
                  ]"
                >
                  {{ user.status }}
                </span>
              </td>

              <!-- Actions Dropdown -->
              <td v-if="visibleColumns.actions" class="col-actions text-right relative">
                <button 
                  class="btn-action-dots" 
                  @click.stop="toggleActionMenu($event, user.id)"
                  title="More actions"
                >
                  <MoreVertical :size="16" />
                </button>

                <!-- Floating Dropdown Menu -->
                <div 
                  v-if="activeActionMenuId === user.id" 
                  class="action-menu-dropdown"
                  @click.stop
                >
                  <button class="action-menu-item" @click="goToEditUser(user.id)">
                    <Edit2 :size="14" class="text-slate-500" />
                    <span>Edit User</span>
                  </button>
                  <button class="action-menu-item" @click="toggleUserStatus(user.id)">
                    <UserCheck v-if="user.status === 'Inactive'" :size="14" class="text-emerald-600" />
                    <UserX v-else :size="14" class="text-amber-600" />
                    <span>{{ user.status === 'Active' ? 'Deactivate Account' : 'Activate Account' }}</span>
                  </button>
                  <button class="action-menu-item" @click="copyNationalId(user.id, user.nationalId); activeActionMenuId = null;">
                    <Copy :size="14" class="text-slate-500" />
                    <span>Copy National ID</span>
                  </button>
                  <div class="menu-divider"></div>
                  <button class="action-menu-item text-red-600 hover:bg-red-50" @click="handleDeleteUser(user.id)">
                    <Trash2 :size="14" class="text-red-500" />
                    <span class="font-medium text-red-600">Delete User</span>
                  </button>
                </div>
              </td>
            </tr>

            <!-- Empty Search Results -->
            <tr v-if="filteredUsers.length === 0">
              <td colspan="8" class="empty-table-state">
                <p class="font-medium text-slate-700">No users found matching your search</p>
                <p class="text-xs text-slate-400 mt-1">Try adjusting filters or search keywords</p>
              </td>
            </tr>
          </tbody>
        </table>

        <!-- ROLES TABLE -->
        <table v-else-if="activeTab === 'roles'" class="erp-table">
          <thead>
            <tr>
              <th>Role Name</th>
              <th>Description</th>
              <th>Assigned Users</th>
              <th>Status</th>
              <th class="text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="role in filteredRoles" :key="role.id">
              <td class="role-name-cell">{{ role.name }}</td>
              <td class="role-desc-cell">{{ role.description }}</td>
              <td class="col-secondary-text">
                <span class="count-chip">{{ role.userCount }} users</span>
              </td>
              <td>
                <span class="status-pill pill-active">{{ role.status }}</span>
              </td>
              <td class="text-right">
                <button class="btn-action-dots"><MoreVertical :size="16" /></button>
              </td>
            </tr>
          </tbody>
        </table>

        <!-- PERMISSIONS TABLE -->
        <table v-else-if="activeTab === 'permissions'" class="erp-table">
          <thead>
            <tr>
              <th>Permission Name</th>
              <th>Module</th>
              <th>Category</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="perm in filteredPermissions" :key="perm.id">
              <td class="perm-name-cell">{{ perm.name }}</td>
              <td class="col-secondary-text"><code class="code-tag">{{ perm.module }}</code></td>
              <td class="col-secondary-text">{{ perm.category }}</td>
              <td>
                <span class="status-pill pill-active">{{ perm.status }}</span>
              </td>
            </tr>
          </tbody>
        </table>

      </div>

      <!-- Pagination Footer Bar -->
      <BasePagination
        v-if="activeTab === 'users'"
        v-model:currentPage="currentPage"
        v-model:perPage="perPage"
        :totalEntries="filteredUsers.length"
        :perPageOptions="[1, 5, 10, 25, 50]"
      />

    </div>
  </div>
</template>

<style scoped>
.user-management-page {
  animation: fadeIn 0.25s ease-out;
  display: flex;
  flex-direction: column;
  gap: 12px;
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  color: #0f172a;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(6px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Breadcrumb styling */
.breadcrumb-nav {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #64748b;
  margin-bottom: 2px;
}

.breadcrumb-icon-link {
  color: #64748b;
  display: flex;
  align-items: center;
  transition: color 0.15s ease;
  padding: 2px;
  border-radius: 4px;
}
.breadcrumb-icon-link:hover { color: #0f172a; background-color: #f1f5f9; }
.breadcrumb-divider { color: #94a3b8; }
.breadcrumb-current { color: #1e293b; font-weight: 500; }

/* Top Header Section Card */
.header-section-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02), 0 1px 2px rgba(0, 0, 0, 0.03);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* Bottom Table Section Card */
.table-section-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02), 0 1px 2px rgba(0, 0, 0, 0.03);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.table-header-title-block {
  padding: 20px 28px 12px 28px;
}
.table-block-title {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
  margin: 0 0 2px 0;
  letter-spacing: -0.01em;
}
.table-block-subtitle {
  font-size: 13px;
  color: #64748b;
  margin: 0;
}

/* Header title section */
.page-title-header {
  padding: 24px 28px 16px 28px;
}

.main-title {
  font-size: 22px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: -0.02em;
  margin: 0 0 6px 0;
}

.main-subtitle {
  font-size: 13.5px;
  color: #64748b;
  margin: 0;
  line-height: 1.5;
}

/* Toolbar Controls Bar */
.toolbar-wrapper {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 28px 18px 28px;
  gap: 16px;
  flex-wrap: wrap;
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
  min-width: 280px;
}

.search-box {
  position: relative;
  width: 100%;
  max-width: 320px;
}

.search-box-icon {
  position: absolute;
  left: 14px;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
  pointer-events: none;
}

.search-box-input {
  width: 100%;
  height: 40px;
  padding: 0 14px 0 40px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13.5px;
  color: #0f172a;
  outline: none;
  transition: all 0.15s ease;
}

.search-box-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.12);
}

.relative-dropdown {
  position: relative;
}

.toolbar-btn {
  height: 40px;
  padding: 0 14px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13.5px;
  font-weight: 500;
  color: #334155;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.toolbar-btn:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
  color: #0f172a;
}

.btn-active {
  border-color: #0B529C;
  background-color: #eff6ff;
  color: #0B529C;
}

.filter-count-badge {
  background-color: #0B529C;
  color: #ffffff;
  font-size: 11px;
  font-weight: 700;
  padding: 1px 7px;
  border-radius: 10px;
  margin-left: 2px;
}

/* Dynamic Revealing Filter Panel (Standard ERP Design System) */
.filter-panel {
  display: flex;
  align-items: flex-end;
  gap: 16px;
  background: #f9fafb;
  border-top: 1px solid #e5e7eb;
  border-bottom: 1px solid #e5e7eb;
  padding: 14px 28px;
  animation: slideDown 0.2s ease-out;
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-8px); }
  to { opacity: 1; transform: translateY(0); }
}

.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.2s ease-out;
}
.slide-down-enter-from,
.slide-down-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
}

.filter-label {
  font-size: 11px;
  font-weight: 700;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.filter-select {
  width: 100%;
  height: 38px;
  padding: 0 32px 0 12px;
  background: white url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e") no-repeat right 12px center/16px;
  appearance: none;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  color: #1e293b;
  outline: none;
  cursor: pointer;
  transition: all 0.15s ease;
}

.filter-select:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 2px rgba(11, 82, 156, 0.12);
}

.btn-reset-filters {
  height: 38px;
  padding: 0 16px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  color: #374151;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
  display: flex;
  align-items: center;
  gap: 8px;
  white-space: nowrap;
}

.btn-reset-filters:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
  color: #0f172a;
}

/* Columns Selection Popover */
.columns-popover {
  right: 0;
  left: auto !important;
  width: 200px;
  padding: 12px 14px;
}

.popover-title-text {
  font-size: 11px;
  font-weight: 700;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 8px;
  padding-bottom: 6px;
  border-bottom: 1px solid #f1f5f9;
}

.columns-list-container {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.column-option-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #334155;
  cursor: pointer;
  user-select: none;
  transition: color 0.15s ease;
}

.column-option-item:hover {
  color: #0f172a;
}

/* Fullscreen Mode */
.table-section-card.is-fullscreen {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 9999;
  border-radius: 0;
  margin: 0 !important;
  height: 100vh;
  overflow-y: auto;
}

/* Dropdown popovers */
.dropdown-popover {
  position: absolute;
  top: calc(100% + 6px);
  left: 0;
  width: 220px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.04);
  padding: 12px;
  z-index: 100;
  display: flex;
  flex-direction: column;
  gap: 10px;
  animation: popIn 0.15s ease-out;
}

@keyframes popIn {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}

.popover-label {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #94a3b8;
  margin-bottom: 6px;
  display: block;
}

.popover-options {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.popover-chip {
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  background: #f1f5f9;
  color: #475569;
  border: none;
  cursor: pointer;
  transition: all 0.15s ease;
}

.popover-chip:hover {
  background: #e2e8f0;
}

.chip-active {
  background: #0B529C !important;
  color: #ffffff !important;
}

.popover-select {
  width: 100%;
  height: 34px;
  padding: 0 10px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 12.5px;
  color: #1e293b;
  outline: none;
}

.popover-divider {
  height: 1px;
  background: #f1f5f9;
  margin: 2px 0;
}

.sort-popover {
  padding: 6px;
  width: 160px;
}

.sort-option {
  display: flex;
  align-items: center;
  width: 100%;
  padding: 8px 10px;
  border-radius: 6px;
  border: none;
  background: none;
  font-size: 13px;
  color: #334155;
  cursor: pointer;
  transition: background 0.15s;
}

.sort-option:hover {
  background: #f8fafc;
  color: #0f172a;
}

.toolbar-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.view-toggles {
  display: flex;
  align-items: center;
  gap: 4px;
}

.icon-toggle-btn {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
  color: #64748b;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
}

.icon-toggle-btn:hover {
  background: #f8fafc;
  color: #0f172a;
  border-color: #cbd5e1;
}

.btn-create-user {
  height: 40px;
  padding: 0 18px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 10px;
  font-size: 13.5px;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.15s ease;
  box-shadow: 0 2px 4px rgba(11, 82, 156, 0.2);
}

.btn-create-user:hover {
  background-color: #09427d;
  box-shadow: 0 4px 8px rgba(11, 82, 156, 0.3);
  transform: translateY(-1px);
}

/* Tabs Bar */
.tabs-header-bar {
  display: flex;
  padding: 0 28px;
  border-bottom: 1px solid #e2e8f0;
  gap: 20px;
  background-color: #fafafa;
}

.tab-btn {
  padding: 12px 0;
  font-size: 13.5px;
  font-weight: 500;
  color: #64748b;
  border: none;
  background: none;
  cursor: pointer;
  border-bottom: 2px solid transparent;
  transition: all 0.15s ease;
}

.tab-btn:hover {
  color: #0f172a;
}

.active-tab {
  color: #0B529C;
  font-weight: 600;
  border-bottom-color: #0B529C;
}

/* Table Container & Base Table */
.table-container {
  width: 100%;
  overflow-x: auto;
  border-top: 1px solid #f1f5f9;
}

.erp-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
  font-size: 13px;
}

.erp-table th {
  background-color: #fafafa;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 500;
  color: #737373;
  border-bottom: 1px solid #e2e8f0;
  white-space: nowrap;
  height: 34px;
}

.erp-table td {
  padding: 8px 16px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
  color: #404040;
  height: 38px;
}

.erp-table tr:hover {
  background-color: #f8fafc;
}

.row-selected {
  background-color: #f0f7ff !important;
}

/* Columns */
.col-checkbox { width: 44px; text-align: center; }
.col-no { 
  width: 54px; 
  color: #737373;
  font-weight: 500;
}
.col-name { min-width: 240px; }
.col-gender { 
  width: 100px; 
  color: #737373;
}
.col-role { 
  min-width: 160px; 
  color: #737373;
}
.col-nid { 
  min-width: 180px; 
  color: #737373;
}
.col-state { width: 120px; }
.col-actions { width: 80px; }

.col-secondary-text {
  color: #737373;
}

.role-name-cell,
.perm-name-cell {
  font-size: 13.5px;
  font-weight: 600;
  color: #262626;
}

.role-desc-cell {
  font-size: 12.5px;
  color: #737373;
}

/* Custom Checkbox */
.custom-checkbox {
  width: 17px;
  height: 17px;
  border-radius: 4px;
  border: 1.5px solid #cbd5e1;
  cursor: pointer;
  accent-color: #0B529C;
}

/* User Identity Cell (First column after number) */
.user-identity {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-avatar-img {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
  border: 1px solid #e2e8f0;
}

.user-avatar-fallback {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: #0B529C;
  color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 700;
  flex-shrink: 0;
}

.user-name-stack {
  display: flex;
  flex-direction: column;
  line-height: 1.35;
}

/* Primary text in first column: #262626 */
.user-full-name {
  font-size: 13.5px;
  font-weight: 600;
  color: #262626;
}

/* Secondary description text in first column: #737373 */
.user-email-text {
  font-size: 12px;
  color: #737373;
}

/* National ID with Copy Button */
.nid-wrapper {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #737373;
  font-family: monospace, sans-serif;
  font-size: 13px;
}

.nid-text {
  color: #737373;
}

.btn-copy-id {
  background: none;
  border: none;
  padding: 4px;
  border-radius: 4px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.15s;
}

.btn-copy-id:hover {
  background-color: #f1f5f9;
}

/* State Status Badge Pill (Matching screenshots) */
.status-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 4px 14px;
  border-radius: 9999px;
  font-size: 12px;
  font-weight: 600;
  line-height: 1;
}

/* Soft Green Active Badge */
.pill-active {
  background-color: #dcfce7;
  color: #15803d;
}

/* Soft Gray Inactive Badge */
.pill-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

/* Actions Menu Button */
.btn-action-dots {
  background: none;
  border: none;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  color: #737373;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-action-dots:hover {
  background-color: #f1f5f9;
  color: #262626;
}

/* Floating Action Menu Dropdown */
.action-menu-dropdown {
  position: absolute;
  right: 12px;
  top: calc(100% - 6px);
  width: 180px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.04);
  padding: 6px;
  z-index: 90;
  display: flex;
  flex-direction: column;
  gap: 2px;
  text-align: left;
  animation: popIn 0.15s ease-out;
}

.action-menu-item {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 8px 10px;
  border: none;
  background: none;
  border-radius: 6px;
  font-size: 13px;
  color: #334155;
  cursor: pointer;
  transition: background 0.15s;
}

.action-menu-item:hover {
  background-color: #f8fafc;
  color: #0f172a;
}

.menu-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 4px 0;
}

.empty-table-state {
  text-align: center;
  padding: 48px 24px;
}

.count-chip {
  display: inline-flex;
  padding: 3px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 500;
  background-color: #f5f5f5;
  color: #737373;
}

.code-tag {
  background-color: #f5f5f5;
  padding: 2px 6px;
  border-radius: 4px;
  font-family: monospace;
  font-size: 11.5px;
  color: #737373;
}

/* Pagination Footer */
.table-pagination-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 28px;
  border-top: 1px solid #e2e8f0;
  gap: 16px;
  flex-wrap: wrap;
  background-color: #ffffff;
}

.pagination-info {
  font-size: 13px;
  color: #64748b;
}

.per-page-selector {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
}

.per-page-select {
  height: 34px;
  padding: 0 28px 0 10px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  color: #1e293b;
  outline: none;
  background: #ffffff;
  cursor: pointer;
}

.pagination-controls {
  display: flex;
  align-items: center;
  gap: 4px;
}

.page-nav-btn {
  height: 34px;
  padding: 0 14px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
  font-size: 13px;
  font-weight: 500;
  color: #334155;
  cursor: pointer;
  transition: all 0.15s ease;
}

.page-nav-btn:hover:not(:disabled) {
  background: #f8fafc;
  color: #0f172a;
  border-color: #cbd5e1;
}

.page-nav-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.page-num-btn {
  width: 34px;
  height: 34px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
  font-size: 13px;
  font-weight: 500;
  color: #334155;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.15s ease;
}

.page-num-btn:hover {
  background: #f8fafc;
  color: #0f172a;
}

.page-active {
  background-color: #0B529C !important;
  color: #ffffff !important;
  border-color: #0B529C !important;
  font-weight: 600;
}

.page-ellipsis {
  width: 34px;
  height: 34px;
  border: none;
  background: none;
  color: #94a3b8;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: default;
}
</style>
