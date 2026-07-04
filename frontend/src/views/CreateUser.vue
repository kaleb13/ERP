<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  Monitor, ChevronRight, User, ShieldCheck, Key, ListChecks,
  RotateCcw, Save, Camera, Plus, Trash2, Calendar, HelpCircle,
  AlertCircle, ShieldAlert, Check, X, Edit, ChevronDown, ChevronUp, Lock
} from 'lucide-vue-next';
import BaseTabs from '../components/BaseTabs.vue';

const router = useRouter();
const route = useRoute();

const isEditMode = computed(() => !!route.params.id);

type UserTab = 'details' | 'roles' | 'grant' | 'assigned';
const activeTab = ref<UserTab>('details');
const tabs: { id: UserTab; label: string; icon?: any }[] = [
  { id: 'details',  label: 'User Details',         icon: User },
  { id: 'roles',    label: 'Assign Roles',          icon: ShieldCheck },
  { id: 'grant',    label: 'Grant Permissions',     icon: Key },
  { id: 'assigned', label: 'Assigned Permissions',  icon: ListChecks }
];

// Form fields
const form = ref({
  firstName: isEditMode.value ? 'Abebe' : '',
  lastName: isEditMode.value ? 'Kebede' : '',
  email: isEditMode.value ? 'abebe@gmail.com' : '',
  phone: isEditMode.value ? '+251 911 234 567' : '',
  username: isEditMode.value ? 'abebe.k' : '',
  password: '',
  confirmPassword: '',
  entity: isEditMode.value ? 'Bole Road Branch' : '',
  status: 'Active'
});

// Role assignment state
interface RoleAssignment {
  roleId: number;
  startDate: string;
  endDate: string;
}

const assignedRoles = ref<RoleAssignment[]>(
  isEditMode.value 
    ? [{ roleId: 2, startDate: '2026-07-04', endDate: '2026-12-31' }]
    : []
);

// Helper role assignment inputs
const tempRoleDates = ref<Record<number, { startDate: string; endDate: string }>>({});

const availableRoles = [
  { 
    id: 1, 
    name: 'Admin', 
    description: 'Full system administrative control and access to all settings.',
    permissions: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  },
  { 
    id: 2, 
    name: 'Sales Manager', 
    description: 'Manage sales campaigns, customer relationships and point of sales.',
    permissions: [2, 3, 5, 8]
  },
  { 
    id: 3, 
    name: 'Inventory Officer', 
    description: 'Stock management, ledger controls and item variations.',
    permissions: [8, 9, 10]
  },
  { 
    id: 4, 
    name: 'Accountant', 
    description: 'Financial controls, invoices, pricing structures and TIN setup.',
    permissions: [2, 8]
  }
];

// Initialize temporary role dates
availableRoles.forEach(r => {
  tempRoleDates.value[r.id] = {
    startDate: new Date().toISOString().split('T')[0],
    endDate: '2027-12-31'
  };
});

const isRoleAssigned = (roleId: number) => {
  return assignedRoles.value.some(ar => ar.roleId === roleId);
};

const getRoleAssignment = (roleId: number) => {
  return assignedRoles.value.find(ar => ar.roleId === roleId);
};

const toggleRole = (roleId: number) => {
  const index = assignedRoles.value.findIndex(ar => ar.roleId === roleId);
  if (index === -1) {
    assignedRoles.value.push({
      roleId,
      startDate: tempRoleDates.value[roleId].startDate,
      endDate: tempRoleDates.value[roleId].endDate
    });
  } else {
    assignedRoles.value.splice(index, 1);
  }
};

const updateRoleDates = (roleId: number) => {
  const ar = getRoleAssignment(roleId);
  if (ar) {
    ar.startDate = tempRoleDates.value[roleId].startDate;
    ar.endDate = tempRoleDates.value[roleId].endDate;
  }
};

// ── Permissions Setup ───────────────────────────────────────────────────
interface Permission {
  id: number;
  name: string;
  description: string;
  module: string;
}

const allPermissions: Permission[] = [
  { id: 1, name: 'Create User', description: 'Allows creating new user profiles', module: 'User Management' },
  { id: 2, name: 'View User List', description: 'Allows listing all system users', module: 'User Management' },
  { id: 3, name: 'Edit User Information', description: 'Allows editing user accounts and personal info', module: 'User Management' },
  { id: 4, name: 'Reset User Password', description: 'Allows resetting user passwords manually', module: 'User Management' },
  { id: 5, name: 'Manage User Role', description: 'Allows assigning roles and granting special permissions', module: 'User Management' },
  { id: 6, name: 'View Activity Log', description: 'Allows viewing audit logs and user operations', module: 'User Management' },
  { id: 7, name: 'Delete User', description: 'Allows deleting/archiving user accounts permanently', module: 'User Management' },
  { id: 8, name: 'View Products', description: 'Allows viewing general inventory products list', module: 'Inventory Management' },
  { id: 9, name: 'Create Product', description: 'Allows creating new catalog items and pricing rules', module: 'Inventory Management' },
  { id: 10, name: 'Edit Product', description: 'Allows updating details of existing inventory items', module: 'Inventory Management' }
];

// Direct/Special Permission Grants state
interface DirectGrant {
  id: string; // Unique id for the period record
  permissionId: number;
  startDate: string;
  endDate: string;
}

const directGrants = ref<DirectGrant[]>(
  isEditMode.value
    ? [
        { id: 'dg-1', permissionId: 5, startDate: '2026-07-04', endDate: '2026-07-05' },
        { id: 'dg-2', permissionId: 5, startDate: '2026-07-04', endDate: '2026-07-15' }
      ]
    : []
);

// Revoked Role Permissions Override state
// When a role permission is revoked for a specific duration or permanently
interface Revocation {
  permissionId: number;
  startDate?: string;
  endDate?: string;
  permanent: boolean;
}

const revokedRolePermissions = ref<Revocation[]>([]);

// Grant permission tab inputs
const selectedGroupId = ref<string>('user_mgmt');
const grantSearch = ref('');
const grantStartDate = ref(new Date().toISOString().split('T')[0]);
const grantEndDate = ref('2026-07-15');

const permModules = [
  { id: 'user_mgmt', label: 'User Management', count: 7 },
  { id: 'inv_mgmt', label: 'Inventory Management', count: 3 }
];

const getPermissionsByModule = (moduleId: string) => {
  const mLabel = moduleId === 'user_mgmt' ? 'User Management' : 'Inventory Management';
  return allPermissions.filter(p => p.module === mLabel);
};

const filteredGrantPermissions = computed(() => {
  const perms = getPermissionsByModule(selectedGroupId.value);
  const q = grantSearch.value.toLowerCase().trim();
  if (!q) return perms;
  return perms.filter(p => p.name.toLowerCase().includes(q) || p.description.toLowerCase().includes(q));
});

// Add a special permission grant
const addDirectGrant = (permissionId: number) => {
  const uniqueId = 'dg-' + Math.random().toString(36).substr(2, 9);
  directGrants.value.push({
    id: uniqueId,
    permissionId,
    startDate: grantStartDate.value,
    endDate: grantEndDate.value
  });
};

const removeDirectGrant = (grantId: string) => {
  directGrants.value = directGrants.value.filter(dg => dg.id !== grantId);
};

// Update direct grant dates
const updateDirectGrantDates = (grantId: string, start: string, end: string) => {
  const dg = directGrants.value.find(d => d.id === grantId);
  if (dg) {
    dg.startDate = start;
    dg.endDate = end;
  }
};

// Revoke an inherited role permission
const revokeRolePermission = (permissionId: number) => {
  // If not already revoked, add it
  if (!revokedRolePermissions.value.some(r => r.permissionId === permissionId)) {
    revokedRolePermissions.value.push({
      permissionId,
      permanent: true
    });
  }
};

// Re-grant a previously revoked role permission
const restoreRolePermission = (permissionId: number) => {
  revokedRolePermissions.value = revokedRolePermissions.value.filter(r => r.permissionId !== permissionId);
};

// ── Computed Assigned Permissions for Table Tree ───────────────────────────
// This lists all permissions, grouped by their source:
// 1. Role Permissions (with their active or revoked status)
// 2. Special / Direct Grants (with possible multiple time periods grouped)
interface AssignedPermissionsGroup {
  roleName: string;
  roleId?: number;
  startDate?: string;
  endDate?: string;
  permissions: {
    permission: Permission;
    status: 'Active' | 'Revoked';
    isRevoked: boolean;
  }[];
}

const assignedRoleGroups = computed<AssignedPermissionsGroup[]>(() => {
  return assignedRoles.value.map(ar => {
    const role = availableRoles.find(r => r.id === ar.roleId);
    if (!role) return null;
    
    const rolePerms = role.permissions.map(pid => {
      const perm = allPermissions.find(p => p.id === pid)!;
      const isRevoked = revokedRolePermissions.value.some(r => r.permissionId === pid);
      return {
        permission: perm,
        status: isRevoked ? ('Revoked' as const) : ('Active' as const),
        isRevoked
      };
    });

    return {
      roleName: role.name,
      roleId: role.id,
      startDate: ar.startDate,
      endDate: ar.endDate,
      permissions: rolePerms
    };
  }).filter(Boolean) as AssignedPermissionsGroup[];
});

// Grouped special/direct grants by permission so they can show periods tree-style
interface GroupedDirectGrant {
  permission: Permission;
  grants: DirectGrant[];
  isExpanded: boolean;
}

const groupedDirectGrants = ref<Record<number, boolean>>({});

const assignedDirectGrants = computed<GroupedDirectGrant[]>(() => {
  const result: Record<number, DirectGrant[]> = {};
  directGrants.value.forEach(dg => {
    if (!result[dg.permissionId]) {
      result[dg.permissionId] = [];
    }
    result[dg.permissionId].push(dg);
  });

  return Object.keys(result).map(key => {
    const pid = Number(key);
    const perm = allPermissions.find(p => p.id === pid)!;
    return {
      permission: perm,
      grants: result[pid],
      isExpanded: groupedDirectGrants.value[pid] !== false
    };
  });
});

const toggleGroupExpand = (permissionId: number) => {
  if (groupedDirectGrants.value[permissionId] === undefined) {
    groupedDirectGrants.value[permissionId] = false;
  } else {
    groupedDirectGrants.value[permissionId] = !groupedDirectGrants.value[permissionId];
  }
};

// ── Actions ─────────────────────────────────────────────────────────────
const handleSave = () => {
  alert('User saved successfully!');
  router.push('/company-setup/user-and-access');
};

const handleClearChange = () => {
  if (confirm('Are you sure you want to discard all changes?')) {
    form.value = {
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      username: '',
      password: '',
      confirmPassword: '',
      entity: '',
      status: 'Active'
    };
    assignedRoles.value = [];
    directGrants.value = [];
    revokedRolePermissions.value = [];
  }
};
</script>

<template>
  <div class="create-user-page">
    
    <!-- Breadcrumbs -->
    <div class="breadcrumbs">
      <router-link to="/dashboard" class="breadcrumb-link">
        <Monitor :size="16" />
      </router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <router-link to="/company-setup/user-and-access" class="breadcrumb-link breadcrumb-text">User</router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <span class="breadcrumb-active">{{ isEditMode ? 'Edit User' : 'Create User' }}</span>
      <span class="not-saved-badge">Not Saved</span>
    </div>

    <!-- Actions bar -->
    <div class="top-action-bar">
      <button class="btn-clear" @click="handleClearChange">
        <RotateCcw :size="15" /> 
        <span>Clear Change</span>
      </button>
      <button class="btn-save" @click="handleSave">
        <Save :size="15" /> 
        <span>Save</span>
      </button>
    </div>

    <!-- Navigation Tabs -->
    <div class="tabs-row">
      <BaseTabs v-model="activeTab" :tabs="tabs" />
    </div>

    <!-- User Preview Header -->
    <div class="user-preview-card">
      <div class="preview-avatar-wrap">
        <div class="preview-avatar">
          <span>{{ form.firstName ? form.firstName[0] : 'A' }}{{ form.lastName ? form.lastName[0] : 'K' }}</span>
        </div>
        <button class="avatar-edit-btn"><Camera :size="13" /></button>
      </div>
      <div class="preview-info">
        <div class="preview-name">{{ form.firstName || 'Abebe' }} {{ form.lastName || 'Kebede' }}</div>
        <div class="preview-email">{{ form.email || 'abebe@gmail.com' }}</div>
      </div>
      <div class="preview-role-block">
        <span class="preview-label">Role</span>
        <div class="role-badge-container">
          <span v-for="ar in assignedRoles" :key="ar.roleId" class="role-badge">
            {{ availableRoles.find(r => r.id === ar.roleId)?.name }}
          </span>
          <span v-if="assignedRoles.length === 0" class="role-badge italic text-gray-400">
            No Assigned Role
          </span>
        </div>
      </div>
      <div class="preview-status-block">
        <span class="preview-label">Status</span>
        <span :class="['status-badge', form.status === 'Active' ? 'status-active' : 'status-inactive']">
          <span class="dot"></span>{{ form.status }}
        </span>
      </div>
    </div>

    <!-- ── TAB 1: USER DETAILS ───────────────────────────────────────────── -->
    <div v-if="activeTab === 'details'" class="form-card">
      <div class="form-section-title">Personal Information</div>
      <div class="form-grid-2">
        <div class="form-group">
          <label class="form-label">First Name *</label>
          <input v-model="form.firstName" type="text" placeholder="Enter first name" class="form-input" />
        </div>
        <div class="form-group">
          <label class="form-label">Last Name *</label>
          <input v-model="form.lastName" type="text" placeholder="Enter last name" class="form-input" />
        </div>
      </div>
      
      <div class="form-grid-2">
        <div class="form-group">
          <label class="form-label">Email Address *</label>
          <input v-model="form.email" type="email" placeholder="example@domain.com" class="form-input" />
        </div>
        <div class="form-group">
          <label class="form-label">Phone Number</label>
          <input v-model="form.phone" type="text" placeholder="+251 9XX XXX XXX" class="form-input" />
        </div>
      </div>

      <div class="form-divider"></div>

      <div class="form-section-title">Account Setup</div>
      <div class="form-grid-2">
        <div class="form-group">
          <label class="form-label">Username *</label>
          <input v-model="form.username" type="text" placeholder="Enter unique username" class="form-input" />
        </div>
        <div class="form-group">
          <label class="form-label">Entity Scope</label>
          <select v-model="form.entity" class="form-select">
            <option value="">Select organizational entity...</option>
            <option>Haleta Enterprise Group</option>
            <option>Bole Road Branch</option>
            <option>Downtown Shop</option>
          </select>
        </div>
      </div>

      <div class="form-grid-2">
        <div class="form-group">
          <label class="form-label">Password *</label>
          <input v-model="form.password" type="password" placeholder="••••••••" class="form-input" />
        </div>
        <div class="form-group">
          <label class="form-label">Confirm Password *</label>
          <input v-model="form.confirmPassword" type="password" placeholder="••••••••" class="form-input" />
        </div>
      </div>

      <div class="form-group" style="max-width: 250px;">
        <label class="form-label">Account Status</label>
        <div class="status-toggle-wrap">
          <button 
            type="button" 
            :class="['status-toggle-btn', form.status === 'Active' ? 'active' : '']"
            @click="form.status = 'Active'"
          >
            Active
          </button>
          <button 
            type="button" 
            :class="['status-toggle-btn', form.status === 'Inactive' ? 'active-inactive' : '']"
            @click="form.status = 'Inactive'"
          >
            Inactive
          </button>
        </div>
      </div>
    </div>

    <!-- ── TAB 2: ASSIGN ROLES ───────────────────────────────────────────── -->
    <div v-else-if="activeTab === 'roles'" class="form-card">
      <div class="form-section-title">Assign Organizational Roles</div>
      <p class="form-desc">
        Select one or more roles. Each role carries set defaults and temporal validity periods.
      </p>

      <div class="roles-grid">
        <div 
          v-for="role in availableRoles" 
          :key="role.id" 
          :class="['role-card', { selected: isRoleAssigned(role.id) }]"
        >
          <!-- Left check circle -->
          <div class="role-card-check" @click="toggleRole(role.id)">
            <div :class="['check-circle', { checked: isRoleAssigned(role.id) }]">
              <Check v-if="isRoleAssigned(role.id)" :size="12" style="stroke-width: 3;" />
            </div>
          </div>

          <!-- Card content -->
          <div class="role-card-body">
            <div class="role-card-name" @click="toggleRole(role.id)">{{ role.name }}</div>
            <div class="role-card-desc">{{ role.description }}</div>
            
            <!-- Dates config when assigned -->
            <div class="role-dates-box">
              <div class="date-input-group">
                <div class="date-field">
                  <label>Start Date</label>
                  <input 
                    type="date" 
                    v-model="tempRoleDates[role.id].startDate" 
                    @change="updateRoleDates(role.id)"
                    class="date-input" 
                  />
                </div>
                <div class="date-field">
                  <label>End Date</label>
                  <input 
                    type="date" 
                    v-model="tempRoleDates[role.id].endDate" 
                    @change="updateRoleDates(role.id)"
                    class="date-input" 
                  />
                </div>
              </div>
            </div>
            
            <div class="role-card-meta">
              <span>{{ role.permissions.length }} Default Permissions</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ── TAB 3: GRANT PERMISSIONS ─────────────────────────────────────── -->
    <div v-else-if="activeTab === 'grant'" class="form-card grant-layout">
      <!-- Left sidebar: Permission Modules -->
      <div class="perm-group-panel">
        <div class="panel-title">Permission Group</div>
        <ul class="perm-group-list">
          <li 
            v-for="mod in permModules" 
            :key="mod.id" 
            :class="['perm-group-item', { active: selectedGroupId === mod.id }]"
            @click="selectedGroupId = mod.id"
          >
            <span class="perm-group-label">{{ mod.label }}</span>
            <span class="perm-group-count">{{ mod.count }}</span>
          </li>
        </ul>
      </div>

      <!-- Right content: Granular Permissions & Date Setup -->
      <div class="perm-list-panel">
        <div class="perm-list-header">
          <div class="perm-list-title">
            <span>{{ permModules.find(m => m.id === selectedGroupId)?.label }}</span>
          </div>
          
          <div class="perm-search-wrap">
            <input 
              v-model="grantSearch" 
              type="text" 
              placeholder="Search permissions..." 
              class="form-input" 
              style="height: 36px; font-size: 13px;" 
            />
          </div>
        </div>

        <!-- Global Validity setup for newly granted permissions -->
        <div class="grant-validity-card">
          <div class="card-icon-box">
            <Calendar :size="16" class="text-indigo-600" />
          </div>
          <div class="validity-inputs">
            <div class="val-group">
              <span class="val-label">Grant Start Date</span>
              <input type="date" v-model="grantStartDate" class="date-input" />
            </div>
            <div class="val-group">
              <span class="val-label">Grant End Date</span>
              <input type="date" v-model="grantEndDate" class="date-input" />
            </div>
          </div>
          <div class="val-helper">
            Toggling a permission below will grant it with the active dates configured above.
          </div>
        </div>

        <table class="perm-table">
          <thead>
            <tr>
              <th>Permission Name</th>
              <th>Description</th>
              <th width="150" class="text-center">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in filteredGrantPermissions" :key="p.id">
              <td class="perm-name font-semibold text-gray-900">{{ p.name }}</td>
              <td class="text-gray-500 text-sm">{{ p.description }}</td>
              <td class="text-center">
                <button 
                  type="button" 
                  class="btn-grant-action" 
                  @click="addDirectGrant(p.id)"
                >
                  <Plus :size="14" />
                  <span>Grant Period</span>
                </button>
              </td>
            </tr>
            <tr v-if="filteredGrantPermissions.length === 0">
              <td colspan="3" class="text-center text-gray-400 py-6">No permissions found matching search query.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- ── TAB 4: ASSIGNED PERMISSIONS (TABLE TREE) ──────────────────────── -->
    <div v-else-if="activeTab === 'assigned'" class="form-card">
      <div class="form-section-title">Assigned Permissions Matrix</div>
      <p class="form-desc">
        A tree representing all user authorizations. Permissions derived from active roles can be individually revoked. Special direct grants support multiple active date ranges.
      </p>

      <div class="assigned-table-wrapper">
        <table class="assigned-tree-table">
          <thead>
            <tr>
              <th>Permission</th>
              <th>Source / Type</th>
              <th>Active Period</th>
              <th>Status</th>
              <th class="text-center" width="180">Actions</th>
            </tr>
          </thead>
          <tbody>
            
            <!-- ── SUB-SECTION: ROLE INHERITED PERMISSIONS ── -->
            <tr class="tree-section-header">
              <td colspan="5">
                <div class="section-title">
                  <ShieldCheck :size="15" class="text-indigo-600" />
                  <span>Role Inherited Permissions</span>
                </div>
              </td>
            </tr>

            <!-- Render roles & their default permissions -->
            <template v-for="group in assignedRoleGroups" :key="group.roleName">
              <tr class="tree-role-row">
                <td class="font-bold text-gray-800" style="padding-left: 20px;">
                  Role: {{ group.roleName }}
                </td>
                <td class="italic text-gray-500">Role Base</td>
                <td class="font-mono text-xs text-gray-600">
                  {{ group.startDate }} to {{ group.endDate }}
                </td>
                <td>
                  <span class="status-badge status-active">
                    <span class="dot"></span>Active
                  </span>
                </td>
                <td class="text-center">
                  <span class="text-xs text-gray-400">Managed via Role</span>
                </td>
              </tr>

              <!-- Permissions within this Role -->
              <tr 
                v-for="rp in group.permissions" 
                :key="group.roleName + '-' + rp.permission.id"
                class="tree-perm-row"
              >
                <td style="padding-left: 40px;">
                  <div class="perm-title-cell">
                    <span>↳ {{ rp.permission.name }}</span>
                    <span class="perm-desc-hint" :title="rp.permission.description">
                      <HelpCircle :size="12" />
                    </span>
                  </div>
                </td>
                <td class="text-xs text-gray-500">Inherited</td>
                <td class="font-mono text-xs text-gray-400">
                  {{ group.startDate }} to {{ group.endDate }}
                </td>
                <td>
                  <span :class="['status-badge', rp.isRevoked ? 'status-revoked' : 'status-active']">
                    <span class="dot"></span>{{ rp.status }}
                  </span>
                </td>
                <td class="text-center">
                  <button 
                    v-if="!rp.isRevoked"
                    type="button" 
                    class="btn-revoke" 
                    @click="revokeRolePermission(rp.permission.id)"
                  >
                    <X :size="12" />
                    <span>Revoke</span>
                  </button>
                  <button 
                    v-else
                    type="button" 
                    class="btn-restore" 
                    @click="restoreRolePermission(rp.permission.id)"
                  >
                    <Check :size="12" />
                    <span>Restore</span>
                  </button>
                </td>
              </tr>
            </template>

            <tr v-if="assignedRoleGroups.length === 0">
              <td colspan="5" class="text-center text-gray-400 py-4 italic">
                No roles assigned yet. Go to "Assign Roles" tab.
              </td>
            </tr>

            <!-- ── SUB-SECTION: SPECIAL DIRECT GRANTS (TREE / TIMELINES) ── -->
            <tr class="tree-section-header">
              <td colspan="5">
                <div class="section-title">
                  <Key :size="15" class="text-emerald-600" />
                  <span>Special / Direct Grants (Temporal)</span>
                </div>
              </td>
            </tr>

            <template v-for="gp in assignedDirectGrants" :key="gp.permission.id">
              <!-- Expandable parent row for permission -->
              <tr class="tree-parent-perm-row" @click="toggleGroupExpand(gp.permission.id)">
                <td class="font-semibold text-gray-900" style="padding-left: 20px;">
                  <div class="expand-label-wrap">
                    <ChevronDown v-if="gp.isExpanded" :size="14" class="text-gray-500" />
                    <ChevronUp v-else :size="14" class="text-gray-500" />
                    <span>{{ gp.permission.name }}</span>
                  </div>
                </td>
                <td class="text-xs text-emerald-600 font-semibold">Special Grant</td>
                <td class="text-xs text-gray-500">
                  {{ gp.grants.length }} Active Periods
                </td>
                <td>
                  <span class="status-badge status-special">
                    <span class="dot"></span>Granted
                  </span>
                </td>
                <td class="text-center">
                  <span class="text-xs text-gray-400">Multiple ranges</span>
                </td>
              </tr>

              <!-- Sub-rows representing each specific period granted -->
              <template v-if="gp.isExpanded">
                <tr 
                  v-for="(grant, idx) in gp.grants" 
                  :key="grant.id" 
                  class="tree-child-period-row"
                >
                  <td style="padding-left: 45px;" class="text-gray-600 text-sm">
                    ↳ Period #{{ idx + 1 }}
                  </td>
                  <td></td>
                  <td colspan="2">
                    <div class="period-edit-row">
                      <div class="date-field-inline">
                        <span>Start:</span>
                        <input 
                          type="date" 
                          v-model="grant.startDate" 
                          @change="updateDirectGrantDates(grant.id, grant.startDate, grant.endDate)"
                          class="date-input-mini" 
                        />
                      </div>
                      <div class="date-field-inline">
                        <span>End:</span>
                        <input 
                          type="date" 
                          v-model="grant.endDate" 
                          @change="updateDirectGrantDates(grant.id, grant.startDate, grant.endDate)"
                          class="date-input-mini" 
                        />
                      </div>
                    </div>
                  </td>
                  <td class="text-center">
                    <button 
                      type="button" 
                      class="btn-delete-period"
                      @click="removeDirectGrant(grant.id)"
                      title="Revoke and delete this period"
                    >
                      <Trash2 :size="12" />
                      <span>Remove</span>
                    </button>
                  </td>
                </tr>
              </template>
            </template>

            <tr v-if="assignedDirectGrants.length === 0">
              <td colspan="5" class="text-center text-gray-400 py-4 italic">
                No direct/special permissions granted. Use the "Grant Permissions" tab.
              </td>
            </tr>

          </tbody>
        </table>
      </div>
    </div>

  </div>
</template>

<style scoped>
.create-user-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
  font-family: 'Inter', sans-serif;
  animation: fadeIn 0.3s ease-out;
}
@keyframes fadeIn { 
  from { opacity: 0; transform: translateY(8px); } 
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
  transition: color 0.15s; 
}
.breadcrumb-link:hover { color: #111827; }
.breadcrumb-text { font-size: 13px; }
.breadcrumb-separator { color: #9ca3af; display: flex; align-items: center; }
.breadcrumb-active { color: #111827; font-weight: 500; }
.not-saved-badge {
  background: #fff7ed; 
  color: #c2410c; 
  border: 1px solid #fed7aa;
  padding: 2px 10px; 
  border-radius: 20px; 
  font-size: 11px; 
  font-weight: 600; 
  margin-left: 6px;
}

/* Top action bar */
.top-action-bar { display: flex; justify-content: flex-end; gap: 10px; }
.btn-clear {
  display: flex; align-items: center; gap: 6px; padding: 0 16px; height: 38px;
  border: 1px solid #e5e7eb; background: white; border-radius: 8px;
  font-size: 13px; font-weight: 500; color: #374151; cursor: pointer; transition: all 0.2s;
}
.btn-clear:hover { background: #f9fafb; border-color: #d1d5db; }
.btn-save {
  display: flex; align-items: center; gap: 6px; padding: 0 20px; height: 38px;
  background: var(--alias-color-brand-blue-primary, #2563eb); color: #fff;
  border: none; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; transition: all 0.2s;
}
.btn-save:hover { background: var(--alias-color-brand-blue-primary-hover, #1d4ed8); }

/* Tabs row */
.tabs-row { display: flex; }

/* User Preview Card */
.user-preview-card {
  background: white; border: 1px solid #e5e7eb; border-radius: 14px;
  padding: 18px 24px; display: flex; align-items: center; gap: 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}
.preview-avatar-wrap { position: relative; }
.preview-avatar {
  width: 52px; height: 52px; border-radius: 50%; background: #4f46e5;
  display: flex; align-items: center; justify-content: center;
  font-size: 18px; font-weight: 700; color: white; text-transform: uppercase;
}
.avatar-edit-btn {
  position: absolute; bottom: -2px; right: -2px; width: 22px; height: 22px; border-radius: 50%;
  background: white; border: 1px solid #e5e7eb; color: #6b7280; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
}
.preview-name { font-size: 15px; font-weight: 700; color: #111827; }
.preview-email { font-size: 12px; color: #9ca3af; margin-top: 2px; }
.preview-role-block, .preview-status-block { display: flex; flex-direction: column; gap: 4px; }
.preview-label { font-size: 11px; color: #9ca3af; font-weight: 500; text-transform: uppercase; letter-spacing: 0.05em; }
.role-badge-container { display: flex; gap: 6px; flex-wrap: wrap; }
.role-badge { display: inline-flex; padding: 3px 12px; background: #eff6ff; color: #2563eb; border-radius: 12px; font-size: 12px; font-weight: 600; }
.status-badge { display: inline-flex; align-items: center; gap: 5px; padding: 3px 10px; border-radius: 20px; font-size: 12px; font-weight: 500; }
.status-active { background: #ecfdf5; color: #059669; }
.status-inactive { background: #f3f4f6; color: #6b7280; }
.status-revoked { background: #fef2f2; color: #ef4444; }
.status-special { background: #ecfdf5; color: #10b981; }
.dot { width: 6px; height: 6px; border-radius: 50%; background: currentColor; flex-shrink: 0; }

/* Form Card */
.form-card {
  background: white; border: 1px solid #e5e7eb; border-radius: 14px;
  padding: 24px; display: flex; flex-direction: column; gap: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}
.form-section-title { font-size: 14px; font-weight: 700; color: #111827; margin-bottom: 4px; }
.form-desc { font-size: 13px; color: #6b7280; margin-top: -8px; line-height: 1.6; }
.form-divider { border: none; border-top: 1px solid #f3f4f6; margin: 4px 0; }
.form-grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.form-group { display: flex; flex-direction: column; gap: 6px; }
.form-label { font-size: 12px; font-weight: 600; color: #374151; }
.form-input, .form-select {
  width: 100%; padding: 9px 12px; border: 1px solid #e5e7eb; border-radius: 8px;
  font-size: 13px; outline: none; background: white; transition: border 0.15s;
}
.form-input:focus, .form-select:focus { border-color: #6366f1; }

/* Status Toggle */
.status-toggle-wrap { display: flex; gap: 0; border: 1px solid #e5e7eb; border-radius: 8px; overflow: hidden; }
.status-toggle-btn {
  flex: 1; padding: 8px 0; font-size: 12px; font-weight: 600; border: none;
  cursor: pointer; background: white; color: #6b7280; transition: all 0.2s;
}
.status-toggle-btn.active { background: #ecfdf5; color: #059669; }
.status-toggle-btn.active-inactive { background: #f3f4f6; color: #374151; }

/* Roles Grid */
.roles-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 16px; }
.role-card {
  border: 1.5px solid #e5e7eb; border-radius: 12px; padding: 18px;
  transition: all 0.2s; display: flex; gap: 14px; align-items: flex-start;
  background: white;
}
.role-card:hover { border-color: #6366f1; background: #fafafe; }
.role-card.selected { border-color: #4f46e5; background: #f5f3ff; }
.check-circle {
  width: 20px; height: 20px; border-radius: 50%; border: 2px solid #d1d5db;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0; font-size: 11px; font-weight: 700; color: white; transition: all 0.2s;
}
.check-circle.checked { background: #4f46e5; border-color: #4f46e5; }
.role-card-name { font-size: 14px; font-weight: 700; color: #111827; margin-bottom: 4px; cursor: pointer; }
.role-card-desc { font-size: 12px; color: #6b7280; margin-bottom: 12px; line-height: 1.5; }

.role-dates-box {
  background: #f8fafc;
  padding: 10px;
  border-radius: 8px;
  border: 1px dashed #e2e8f0;
  margin-bottom: 10px;
}
.date-input-group {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
.date-field {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.date-field label {
  font-size: 10px;
  font-weight: 600;
  color: #64748b;
  text-transform: uppercase;
}
.date-input {
  border: 1px solid #cbd5e1;
  border-radius: 4px;
  font-size: 11px;
  padding: 4px 6px;
  background: white;
  font-family: monospace;
}

.role-card-meta { font-size: 11px; color: #9ca3af; font-weight: 500; }

/* Grant Permissions – layout split */
.grant-layout { flex-direction: row !important; gap: 0; padding: 0 !important; overflow: hidden; }
.perm-group-panel {
  width: 220px; flex-shrink: 0; border-right: 1px solid #e5e7eb;
  padding: 18px; display: flex; flex-direction: column; gap: 10px;
  background: #f8fafc;
}
.perm-list-panel { flex: 1; padding: 20px; display: flex; flex-direction: column; gap: 16px; overflow: auto; }
.panel-title { font-size: 13px; font-weight: 700; color: #111827; }
.perm-group-list { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 3px; }
.perm-group-item {
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 12px; border-radius: 8px; cursor: pointer; font-size: 13px; color: #374151;
  transition: all 0.15s;
}
.perm-group-item:hover { background: #e2e8f0; }
.perm-group-item.active { background: #eff6ff; color: #2563eb; font-weight: 600; }
.perm-group-count { font-size: 11px; background: #e2e8f0; color: #475569; padding: 2px 8px; border-radius: 10px; }
.perm-list-header { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.perm-list-title { font-size: 15px; font-weight: 700; color: #111827; }
.perm-search-wrap { flex: 1; max-width: 250px; }

/* Validity Config Card */
.grant-validity-card {
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 10px;
  padding: 12px 16px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 16px;
}
.card-icon-box {
  background: #dcfce7;
  padding: 8px;
  border-radius: 8px;
  display: flex;
  align-items: center;
}
.validity-inputs {
  display: flex;
  gap: 14px;
}
.val-group {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.val-label {
  font-size: 10px;
  font-weight: 600;
  color: #166534;
  text-transform: uppercase;
}
.val-helper {
  font-size: 11px;
  color: #166534;
  line-height: 1.4;
  flex: 1;
  min-width: 200px;
}

/* Perm Table */
.perm-table { width: 100%; border-collapse: collapse; }
.perm-table th {
  text-align: left; padding: 10px 12px; font-size: 11px; font-weight: 600;
  color: #6b7280; background: #f9fafb; border-bottom: 1px solid #e5e7eb;
}
.perm-table td { padding: 12px; font-size: 13px; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
.perm-name { font-size: 13px; color: #111827; }
.btn-grant-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: #10b981;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s;
}
.btn-grant-action:hover {
  background: #059669;
}

/* Tree Table Styles */
.assigned-table-wrapper {
  overflow-x: auto;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  margin-top: 12px;
}
.assigned-tree-table {
  width: 100%;
  border-collapse: collapse;
}
.assigned-tree-table th {
  text-align: left;
  padding: 12px 18px;
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}
.assigned-tree-table td {
  padding: 12px 18px;
  font-size: 13px;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}
.tree-section-header {
  background: #f1f5f9;
}
.tree-section-header .section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 700;
  font-size: 12px;
  color: #1e293b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 6px 0;
}
.tree-role-row {
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}
.tree-perm-row:hover, .tree-parent-perm-row:hover {
  background: #fafafa;
}
.perm-title-cell {
  display: flex;
  align-items: center;
  gap: 6px;
}
.perm-desc-hint {
  color: #94a3b8;
  cursor: help;
  display: flex;
  align-items: center;
}
.btn-revoke {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  background: #fef2f2;
  color: #dc2626;
  border: 1px solid #fecaca;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}
.btn-revoke:hover {
  background: #fee2e2;
}
.btn-restore {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  background: #ecfdf5;
  color: #059669;
  border: 1px solid #a7f3d0;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}
.btn-restore:hover {
  background: #d1fae5;
}

/* Direct grant expandable group */
.tree-parent-perm-row {
  cursor: pointer;
  background: #fcfcfd;
}
.expand-label-wrap {
  display: flex;
  align-items: center;
  gap: 6px;
}
.tree-child-period-row {
  background: #f8fafc;
}
.period-edit-row {
  display: flex;
  align-items: center;
  gap: 16px;
}
.date-field-inline {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  font-weight: 600;
  color: #475569;
}
.date-input-mini {
  border: 1px solid #cbd5e1;
  border-radius: 4px;
  font-size: 11px;
  padding: 3px 5px;
  font-family: monospace;
  background: white;
}
.btn-delete-period {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  background: #ffffff;
  color: #ef4444;
  border: 1px solid #fecaca;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}
.btn-delete-period:hover {
  background: #fef2f2;
}

code {
  background: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
  font-family: monospace;
  font-size: 11px;
  color: #0f172a;
}
.text-gray-500 { color: #6b7280; }
</style>
