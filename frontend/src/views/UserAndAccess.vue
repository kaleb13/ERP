<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Monitor, ChevronRight, Users, Search, Plus, Edit2, Trash2,
  MoreHorizontal, Shield, Key, UserCheck, Mail, Phone, Calendar
} from 'lucide-vue-next';
import BaseTabs from '../components/BaseTabs.vue';

const router = useRouter();

type UATab = 'users' | 'roles' | 'permissions';
const activeTab = ref<UATab>('users');
const tabs: { id: UATab; label: string }[] = [
  { id: 'users', label: 'Users' },
  { id: 'roles', label: 'Roles' },
  { id: 'permissions', label: 'Permissions' }
];

const searchQuery = ref('');

// Sample users data
const users = ref([
  {
    id: 1,
    uuid: 'USR-001',
    name: 'Abebe Kebede',
    email: 'abebe@gmail.com',
    phone: '+251 911 234 567',
    role: 'Sales Manager',
    entity: 'Bole Road Branch',
    lastLogin: '2026-07-01',
    status: 'Active'
  },
  {
    id: 2,
    uuid: 'USR-002',
    name: 'Marta Tadesse',
    email: 'marta@haleta.com',
    phone: '+251 922 345 678',
    role: 'Admin',
    entity: 'Haleta Enterprise Group',
    lastLogin: '2026-07-03',
    status: 'Active'
  },
  {
    id: 3,
    uuid: 'USR-003',
    name: 'Dawit Haile',
    email: 'dawit@haleta.com',
    phone: '+251 933 456 789',
    role: 'Inventory Officer',
    entity: 'Downtown Shop',
    lastLogin: '2026-06-28',
    status: 'Inactive'
  },
  {
    id: 4,
    uuid: 'USR-004',
    name: 'Tigist Alemu',
    email: 'tigist@haleta.com',
    phone: '+251 944 567 890',
    role: 'Accountant',
    entity: 'Haleta Enterprise Group',
    lastLogin: '2026-07-02',
    status: 'Active'
  }
]);

// Sample roles data
const roles = ref([
  { id: 1, name: 'Admin', description: 'Full system access', userCount: 1, permCount: 32, status: 'Active' },
  { id: 2, name: 'Sales Manager', description: 'Manage sales and customers', userCount: 1, permCount: 18, status: 'Active' },
  { id: 3, name: 'Inventory Officer', description: 'Manage stock and products', userCount: 1, permCount: 14, status: 'Active' },
  { id: 4, name: 'Accountant', description: 'Manage financial records', userCount: 1, permCount: 10, status: 'Active' }
]);

// Sample permissions data
const permissions = ref([
  { id: 1, name: 'Create User', module: 'User Management', group: 'User Management', status: 'Active' },
  { id: 2, name: 'View User List', module: 'User Management', group: 'User Management', status: 'Active' },
  { id: 3, name: 'Edit User Information', module: 'User Management', group: 'User Management', status: 'Active' },
  { id: 4, name: 'Reset User Password', module: 'User Management', group: 'User Management', status: 'Active' },
  { id: 5, name: 'Manage User Role', module: 'User Management', group: 'User Management', status: 'Active' },
  { id: 6, name: 'Delete User', module: 'User Management', group: 'User Management', status: 'Active' }
]);

const filteredUsers = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return users.value;
  return users.value.filter(u =>
    u.name.toLowerCase().includes(q) ||
    u.email.toLowerCase().includes(q) ||
    u.role.toLowerCase().includes(q) ||
    u.uuid.toLowerCase().includes(q)
  );
});

const filteredRoles = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return roles.value;
  return roles.value.filter(r =>
    r.name.toLowerCase().includes(q) ||
    r.description.toLowerCase().includes(q)
  );
});

const filteredPermissions = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return permissions.value;
  return permissions.value.filter(p =>
    p.name.toLowerCase().includes(q) ||
    p.module.toLowerCase().includes(q)
  );
});

const stats = computed(() => [
  { label: 'Total Users', value: users.value.length.toString(), icon: Users, color: 'text-indigo-600', bg: 'bg-indigo-50' },
  { label: 'Active Users', value: users.value.filter(u => u.status === 'Active').length.toString(), icon: UserCheck, color: 'text-emerald-600', bg: 'bg-emerald-50' },
  { label: 'Total Roles', value: roles.value.length.toString(), icon: Shield, color: 'text-orange-600', bg: 'bg-orange-50' },
  { label: 'Total Permissions', value: permissions.value.length.toString(), icon: Key, color: 'text-purple-600', bg: 'bg-purple-50' }
]);

const handleDeleteUser = (id: number) => {
  if (!confirm('Are you sure you want to delete this user?')) return;
  users.value = users.value.filter(u => u.id !== id);
};

const goToCreateUser = () => {
  router.push('/company-setup/user-and-access/users/create');
};

const initials = (name: string) => {
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
};

const avatarColors: Record<string, string> = {
  'AK': '#4f46e5',
  'MT': '#059669',
  'DH': '#f59e0b',
  'TA': '#ec4899'
};

const getAvatarColor = (name: string) => {
  const init = initials(name);
  return avatarColors[init] || '#6b7280';
};
</script>

<template>
  <div class="user-access-page">
    <!-- Breadcrumbs -->
    <div class="breadcrumbs">
      <router-link to="/dashboard" class="breadcrumb-link">
        <Monitor :size="16" />
      </router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <router-link to="/company-setup" class="breadcrumb-link breadcrumb-text">Company Setup</router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <span class="breadcrumb-active">User And Access</span>
    </div>

    <!-- Stats Grid -->
    <div class="stats-grid">
      <div v-for="stat in stats" :key="stat.label" class="stat-card">
        <div class="stat-header">
          <div :class="['stat-icon-box', stat.bg]">
            <component :is="stat.icon" :size="20" :class="stat.color" />
          </div>
        </div>
        <div class="stat-body">
          <p class="stat-label">{{ stat.label }}</p>
          <h3 class="stat-value">{{ stat.value }}</h3>
        </div>
      </div>
    </div>

    <!-- Main Content Card -->
    <div class="content-card">
      <header class="page-header">
        <div class="title-area">
          <h1 class="page-title">User And Access Management</h1>
          <p class="page-description">
            Manage system users, define roles, and control granular permissions across the organization. Assign roles to users and configure permission grants for each module.
          </p>
        </div>
      </header>

      <!-- Inner Navigation Tabs -->
      <div class="tabs-bar">
        <BaseTabs v-model="activeTab" :tabs="tabs" />
      </div>

      <!-- Action & Search Bar -->
      <div class="action-bar">
        <div class="action-bar-left">
          <div class="search-input-wrapper">
            <Search :size="18" class="search-icon" />
            <input
              v-model="searchQuery"
              type="text"
              :placeholder="activeTab === 'users' ? 'Search users...' : activeTab === 'roles' ? 'Search roles...' : 'Search permissions...'"
              class="table-search"
            />
          </div>
        </div>
        <div class="action-bar-right">
          <button v-if="activeTab === 'users'" @click="goToCreateUser" class="btn-create">
            <Plus :size="18" />
            <span>Add User</span>
          </button>
          <button v-else-if="activeTab === 'roles'" class="btn-create">
            <Plus :size="18" />
            <span>Add Role</span>
          </button>
        </div>
      </div>

      <!-- Tables Content -->
      <div class="table-wrapper">

        <!-- USERS TAB -->
        <table v-if="activeTab === 'users'" class="data-table">
          <thead>
            <tr>
              <th>User</th>
              <th>Role</th>
              <th>Entity</th>
              <th>Last Login</th>
              <th>Status</th>
              <th class="text-center">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="user in filteredUsers" :key="user.id">
              <td>
                <div class="user-cell">
                  <div class="user-avatar" :style="{ backgroundColor: getAvatarColor(user.name) }">
                    {{ initials(user.name) }}
                  </div>
                  <div class="user-info">
                    <span class="user-name">{{ user.name }}</span>
                    <span class="user-email">{{ user.email }}</span>
                  </div>
                </div>
              </td>
              <td>
                <span class="role-badge">{{ user.role }}</span>
              </td>
              <td class="text-gray-600">{{ user.entity }}</td>
              <td class="text-gray-500 text-sm">{{ user.lastLogin }}</td>
              <td>
                <span :class="['status-badge', user.status === 'Active' ? 'status-active' : 'status-inactive']">
                  <span class="dot"></span>{{ user.status }}
                </span>
              </td>
              <td class="text-center">
                <div class="action-buttons-cell">
                  <router-link :to="`/company-setup/user-and-access/users/${user.id}`" class="btn-action-icon" title="Edit">
                    <Edit2 :size="15" />
                  </router-link>
                  <button @click="handleDeleteUser(user.id)" class="btn-action-icon btn-danger" title="Delete">
                    <Trash2 :size="15" />
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="filteredUsers.length === 0">
              <td colspan="6" class="empty-state">No users found matching your query.</td>
            </tr>
          </tbody>
        </table>

        <!-- ROLES TAB -->
        <table v-else-if="activeTab === 'roles'" class="data-table">
          <thead>
            <tr>
              <th>Role Name</th>
              <th>Description</th>
              <th>Users</th>
              <th>Permissions</th>
              <th>Status</th>
              <th class="text-center">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="role in filteredRoles" :key="role.id">
              <td class="font-semibold text-gray-900">{{ role.name }}</td>
              <td class="text-gray-500">{{ role.description }}</td>
              <td><span class="count-badge blue">{{ role.userCount }} users</span></td>
              <td><span class="count-badge purple">{{ role.permCount }} perms</span></td>
              <td>
                <span class="status-badge status-active">
                  <span class="dot"></span>{{ role.status }}
                </span>
              </td>
              <td class="text-center">
                <div class="action-buttons-cell">
                  <button class="btn-action-icon" title="Edit"><Edit2 :size="15" /></button>
                  <button class="btn-action-icon btn-danger" title="Delete"><Trash2 :size="15" /></button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>

        <!-- PERMISSIONS TAB -->
        <table v-else-if="activeTab === 'permissions'" class="data-table">
          <thead>
            <tr>
              <th>Permission Name</th>
              <th>Module</th>
              <th>Group</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="perm in filteredPermissions" :key="perm.id">
              <td class="font-semibold text-gray-900">{{ perm.name }}</td>
              <td><code>{{ perm.module }}</code></td>
              <td class="text-gray-600">{{ perm.group }}</td>
              <td>
                <span class="status-badge status-active">
                  <span class="dot"></span>{{ perm.status }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>

      </div>
    </div>
  </div>
</template>

<style scoped>
.user-access-page {
  animation: fadeIn 0.4s ease-out;
  display: flex;
  flex-direction: column;
  gap: 16px;
  font-family: 'Inter', sans-serif;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Breadcrumbs */
.breadcrumbs {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  margin-bottom: 4px;
}
.breadcrumb-link {
  color: #9ca3af;
  text-decoration: none;
  display: flex;
  align-items: center;
  transition: color 0.15s ease;
}
.breadcrumb-link:hover { color: #111827; }
.breadcrumb-text { font-size: 13px; }
.breadcrumb-separator { color: #9ca3af; display: flex; align-items: center; }
.breadcrumb-active { color: #111827; font-weight: 500; }

/* Stats */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}
.stat-card {
  background: white;
  padding: 20px;
  border-radius: 14px;
  border: 1px solid #f3f4f6;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}
.stat-header { margin-bottom: 10px; }
.stat-icon-box {
  padding: 9px;
  border-radius: 10px;
  display: inline-flex;
}
.stat-label { font-size: 13px; color: #6b7280; margin-bottom: 2px; }
.stat-value { font-size: 22px; font-weight: 700; color: #111827; }

.bg-indigo-50 { background-color: #e0e7ff; }
.text-indigo-600 { color: #4f46e5; }
.bg-emerald-50 { background-color: #ecfdf5; }
.text-emerald-600 { color: #059669; }
.bg-orange-50 { background-color: #fff7ed; }
.text-orange-600 { color: #ea580c; }
.bg-purple-50 { background-color: #f5f3ff; }
.text-purple-600 { color: #7c3aed; }

/* Content Card */
.content-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0,0,0,0.02);
}
.page-header { padding: 24px 24px 8px; }
.page-title { font-size: 20px; font-weight: 700; color: #111827; margin-bottom: 6px; }
.page-description { font-size: 13px; color: #6b7280; line-height: 1.6; }

/* Tabs Bar */
.tabs-bar {
  display: flex;
  padding: 14px 24px;
  background-color: #fcfcfd;
  border-bottom: 1px solid #e5e7eb;
}

/* Action Bar */
.action-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 24px;
  gap: 16px;
}
.action-bar-left { display: flex; align-items: center; gap: 12px; flex: 1; }
.search-input-wrapper { position: relative; flex: 1; max-width: 300px; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; z-index: 10; }
.table-search {
  width: 100%;
  padding: 9px 12px 9px 38px;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  font-size: 13px;
  outline: none;
  height: 40px;
  background: white;
  transition: all 0.2s;
}
.table-search:focus { border-color: #d1d5db; box-shadow: 0 0 0 3px rgba(0,0,0,0.02); }

.btn-create {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 0 18px;
  height: 40px;
  background: var(--alias-color-brand-blue-primary, #2563eb);
  color: #fff;
  border: none;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-create:hover {
  background: var(--alias-color-brand-blue-primary-hover, #1d4ed8);
  transform: translateY(-1px);
}

/* Table */
.table-wrapper { overflow-x: auto; border-top: 1px solid #e5e7eb; }
.data-table { width: 100%; border-collapse: collapse; }
.data-table th {
  text-align: left;
  padding: 11px 24px;
  font-size: 12px;
  font-weight: 600;
  color: #4b5563;
  background: #f9fafb;
  border-bottom: 1px solid #e5e7eb;
  letter-spacing: 0.01em;
}
.data-table td {
  padding: 14px 24px;
  font-size: 13px;
  color: #374151;
  border-bottom: 1px solid #f3f4f6;
  vertical-align: middle;
}
.data-table tr:hover { background-color: #fcfcfd; }
.data-table tr:last-child td { border-bottom: none; }

/* User cell */
.user-cell { display: flex; align-items: center; gap: 12px; }
.user-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 700;
  color: white;
  flex-shrink: 0;
}
.user-info { display: flex; flex-direction: column; gap: 2px; }
.user-name { font-size: 13px; font-weight: 600; color: #111827; }
.user-email { font-size: 12px; color: #9ca3af; }

/* Badges */
.role-badge {
  display: inline-flex;
  padding: 3px 10px;
  background: #eff6ff;
  color: #2563eb;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}
.count-badge {
  display: inline-flex;
  padding: 3px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}
.count-badge.blue { background: #eff6ff; color: #2563eb; }
.count-badge.purple { background: #f5f3ff; color: #7c3aed; }

.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 10px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 500;
}
.status-active { background: #ecfdf5; color: #059669; }
.status-inactive { background: #f3f4f6; color: #6b7280; }
.dot { width: 6px; height: 6px; border-radius: 50%; background: currentColor; flex-shrink: 0; }

.action-buttons-cell { display: flex; align-items: center; justify-content: center; gap: 6px; }
.btn-action-icon {
  background: none;
  border: none;
  padding: 6px;
  border-radius: 6px;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.15s;
  text-decoration: none;
  display: inline-flex;
}
.btn-action-icon:hover { background-color: #f3f4f6; color: #111827; }
.btn-danger:hover { background-color: #fef2f2 !important; color: #ef4444 !important; }

.text-center { text-align: center; }
.text-sm { font-size: 12px; }
.font-semibold { font-weight: 600; }
.text-gray-500 { color: #6b7280; }
.text-gray-600 { color: #4b5563; }
.text-gray-900 { color: #111827; }

.empty-state { text-align: center; padding: 40px; color: #9ca3af; font-size: 13px; }

code {
  background-color: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
  font-family: monospace;
  font-size: 11px;
  color: #0f172a;
}
</style>
