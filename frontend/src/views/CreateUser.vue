<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import {
  Monitor, ChevronRight, User, ShieldCheck, Key, ListChecks,
  RotateCcw, Save, Camera, ChevronDown
} from 'lucide-vue-next';
import BaseTabs from '../components/BaseTabs.vue';

const router = useRouter();

type UserTab = 'details' | 'roles' | 'grant' | 'assigned';
const activeTab = ref<UserTab>('details');
const tabs: { id: UserTab; label: string; icon?: any }[] = [
  { id: 'details',  label: 'User Details',         icon: User },
  { id: 'roles',    label: 'Assign Roles',          icon: ShieldCheck },
  { id: 'grant',    label: 'Grant Permissions',     icon: Key },
  { id: 'assigned', label: 'Assigned Permissions',  icon: ListChecks }
];

// ── Form state ──────────────────────────────────────────────────────────────
const form = ref({
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  username: '',
  password: '',
  confirmPassword: '',
  entity: '',
  role: '',
  status: 'Active',
  avatarInitials: 'AK'
});

const status = ref<'Active' | 'Inactive'>('Active');

// ── Roles ────────────────────────────────────────────────────────────────────
const availableRoles = [
  { id: 1, name: 'Admin',              description: 'Full system access',          permCount: 32 },
  { id: 2, name: 'Sales Manager',      description: 'Manage sales & customers',    permCount: 18 },
  { id: 3, name: 'Inventory Officer',  description: 'Manage stock and products',   permCount: 14 },
  { id: 4, name: 'Accountant',         description: 'Manage financial records',    permCount: 10 }
];
const selectedRoles = ref<number[]>([]);

const toggleRole = (id: number) => {
  const idx = selectedRoles.value.indexOf(id);
  idx === -1 ? selectedRoles.value.push(id) : selectedRoles.value.splice(idx, 1);
};

// ── Grant Permissions ────────────────────────────────────────────────────────
const permGroups = ref([
  {
    id: 'ug1', label: 'User Management', count: '5', subGroups: [
      {
        id: 'ug1-sg1', label: 'Manage User', count: '2/5',
        permissions: [
          { id: 1, name: 'Create User',           granted: false },
          { id: 2, name: 'View User List',         granted: false },
          { id: 3, name: 'Edit User Information',  granted: false },
          { id: 4, name: 'Reset User Password',    granted: false },
          { id: 5, name: 'Manage User Role',       granted: false },
          { id: 6, name: 'View Activity Log',      granted: false },
          { id: 7, name: 'Delete User',            granted: false }
        ]
      }
    ]
  },
  {
    id: 'ig1', label: 'Inventory Management', count: '3', subGroups: [
      {
        id: 'ig1-sg1', label: 'Products', count: '1/3',
        permissions: [
          { id: 8,  name: 'View Products',   granted: false },
          { id: 9,  name: 'Create Product',  granted: false },
          { id: 10, name: 'Edit Product',    granted: false }
        ]
      }
    ]
  }
]);

const selectedGroupId = ref('ug1');
const permSearch = ref('');

const activeGroup = computed(() =>
  permGroups.value.find(g => g.id === selectedGroupId.value)
);

const flatPerms = computed(() => {
  const grp = activeGroup.value;
  if (!grp) return [];
  const all = grp.subGroups.flatMap(sg => sg.permissions);
  const q = permSearch.value.toLowerCase();
  return q ? all.filter(p => p.name.toLowerCase().includes(q)) : all;
});

const togglePerm = (id: number) => {
  for (const g of permGroups.value)
    for (const sg of g.subGroups)
      for (const p of sg.permissions)
        if (p.id === id) { p.granted = !p.granted; return; }
};

// Collect all granted permissions for "Assigned" tab
const allGranted = computed(() =>
  permGroups.value.flatMap(g =>
    g.subGroups.flatMap(sg =>
      sg.permissions.filter(p => p.granted).map(p => ({ ...p, group: sg.label, module: g.label }))
    )
  )
);

// ── Actions ──────────────────────────────────────────────────────────────────
const handleSave = () => {
  alert('User created successfully!');
  router.push('/company-setup/user-and-access');
};

const handleClearChange = () => {
  form.value = { firstName:'', lastName:'', email:'', phone:'', username:'', password:'', confirmPassword:'', entity:'', role:'', status:'Active', avatarInitials:'AK' };
  selectedRoles.value = [];
  for (const g of permGroups.value)
    for (const sg of g.subGroups)
      for (const p of sg.permissions) p.granted = false;
};

const goBack = () => router.push('/company-setup/user-and-access');
</script>

<template>
  <div class="create-user-page">

    <!-- Breadcrumbs -->
    <div class="breadcrumbs">
      <router-link to="/dashboard" class="breadcrumb-link"><Monitor :size="16" /></router-link>
      <ChevronRight :size="12" class="breadcrumb-sep" />
      <router-link to="/company-setup/user-and-access" class="breadcrumb-link breadcrumb-text">User</router-link>
      <ChevronRight :size="12" class="breadcrumb-sep" />
      <span class="breadcrumb-active">Create User</span>
      <span class="not-saved-badge">Not Saved</span>
    </div>

    <!-- Top Action Bar -->
    <div class="top-action-bar">
      <button class="btn-clear" @click="handleClearChange">
        <RotateCcw :size="15" /> Clear Change
      </button>
      <button class="btn-save" @click="handleSave">
        <Save :size="15" /> Save
      </button>
    </div>

    <!-- Tabs -->
    <div class="tabs-row">
      <BaseTabs v-model="activeTab" :tabs="tabs" />
    </div>

    <!-- User Preview Card -->
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
        <span class="role-badge">{{ availableRoles.find(r => selectedRoles.includes(r.id))?.name || 'Sales Manager' }}</span>
      </div>
      <div class="preview-status-block">
        <span class="preview-label">Status:</span>
        <span :class="['status-badge', status === 'Active' ? 'status-active' : 'status-inactive']">
          <span class="dot"></span>{{ status }}
        </span>
      </div>
    </div>

    <!-- ── TAB: USER DETAILS ─────────────────────────────────────────────── -->
    <div v-if="activeTab === 'details'" class="form-card">
      <div class="form-section-title">Personal Information</div>
      <div class="form-grid-2">
        <div class="form-group">
          <label class="form-label">First Name *</label>
          <input v-model="form.firstName" type="text" placeholder="First name" class="form-input" />
        </div>
        <div class="form-group">
          <label class="form-label">Last Name *</label>
          <input v-model="form.lastName" type="text" placeholder="Last name" class="form-input" />
        </div>
      </div>
      <div class="form-grid-2">
        <div class="form-group">
          <label class="form-label">Email Address *</label>
          <input v-model="form.email" type="email" placeholder="email@example.com" class="form-input" />
        </div>
        <div class="form-group">
          <label class="form-label">Phone Number</label>
          <input v-model="form.phone" type="text" placeholder="+251 9XX XXX XXX" class="form-input" />
        </div>
      </div>
      <div class="form-divider"></div>
      <div class="form-section-title">Account Credentials</div>
      <div class="form-grid-2">
        <div class="form-group">
          <label class="form-label">Username *</label>
          <input v-model="form.username" type="text" placeholder="unique_username" class="form-input" />
        </div>
        <div class="form-group">
          <label class="form-label">Entity / Branch</label>
          <select v-model="form.entity" class="form-select">
            <option value="">Select entity...</option>
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
      <div class="form-group" style="max-width:260px;">
        <label class="form-label">Account Status</label>
        <div class="status-toggle-wrap">
          <button
            :class="['status-toggle-btn', status === 'Active' ? 'active' : '']"
            @click="status = 'Active'"
          >Active</button>
          <button
            :class="['status-toggle-btn', status === 'Inactive' ? 'active-inactive' : '']"
            @click="status = 'Inactive'"
          >Inactive</button>
        </div>
      </div>
    </div>

    <!-- ── TAB: ASSIGN ROLES ─────────────────────────────────────────────── -->
    <div v-else-if="activeTab === 'roles'" class="form-card">
      <div class="form-section-title">Assign Roles</div>
      <p class="form-desc">Select one or more roles to assign to this user. Roles define what the user can do in the system.</p>
      <div class="roles-grid">
        <div
          v-for="role in availableRoles"
          :key="role.id"
          :class="['role-card', { selected: selectedRoles.includes(role.id) }]"
          @click="toggleRole(role.id)"
        >
          <div class="role-card-check">
            <div :class="['check-circle', { checked: selectedRoles.includes(role.id) }]">
              <span v-if="selectedRoles.includes(role.id)">✓</span>
            </div>
          </div>
          <div class="role-card-body">
            <div class="role-card-name">{{ role.name }}</div>
            <div class="role-card-desc">{{ role.description }}</div>
            <div class="role-card-meta">{{ role.permCount }} permissions</div>
          </div>
        </div>
      </div>
    </div>

    <!-- ── TAB: GRANT PERMISSIONS ────────────────────────────────────────── -->
    <div v-else-if="activeTab === 'grant'" class="form-card grant-layout">
      <!-- Left: Permission Groups -->
      <div class="perm-group-panel">
        <div class="panel-title">Permission Group</div>
        <div class="perm-group-search">
          <input type="text" placeholder="Search..." class="form-input" style="font-size:12px;height:34px;padding:6px 10px;" />
        </div>
        <ul class="perm-group-list">
          <li
            v-for="g in permGroups"
            :key="g.id"
            :class="['perm-group-item', { active: selectedGroupId === g.id }]"
            @click="selectedGroupId = g.id"
          >
            <span class="perm-group-label">{{ g.label }}</span>
            <span class="perm-group-count">{{ g.count }}</span>
          </li>
          <template v-for="g in permGroups" :key="g.id + '-sub'">
            <template v-if="selectedGroupId === g.id">
              <li
                v-for="sg in g.subGroups"
                :key="sg.id"
                class="perm-subgroup-item"
              >
                <span>↳ {{ sg.label }}</span>
                <span class="perm-group-count">{{ sg.count }}</span>
              </li>
            </template>
          </template>
        </ul>
      </div>

      <!-- Right: Permissions List -->
      <div class="perm-list-panel">
        <div class="perm-list-header">
          <div class="perm-list-title">
            {{ activeGroup?.label }}
            <span class="perm-list-count">{{ flatPerms.length }} Total Permissions</span>
          </div>
          <div class="perm-search-wrap">
            <input v-model="permSearch" type="text" placeholder="Search Permissions..." class="form-input" style="font-size:12px;height:34px;" />
          </div>
        </div>
        <table class="perm-table">
          <thead>
            <tr>
              <th><input type="checkbox" /></th>
              <th>Permission Name</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in flatPerms" :key="p.id">
              <td><input type="checkbox" :checked="p.granted" @change="togglePerm(p.id)" /></td>
              <td class="perm-name">{{ p.name }}</td>
              <td>
                <div class="toggle-wrap" @click="togglePerm(p.id)">
                  <div :class="['toggle', { on: p.granted }]">
                    <div class="toggle-knob"></div>
                  </div>
                  <span :class="['toggle-label', p.granted ? 'granted' : 'not-granted']">
                    {{ p.granted ? 'Granted' : 'Not Assigned' }}
                  </span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- ── TAB: ASSIGNED PERMISSIONS ─────────────────────────────────────── -->
    <div v-else-if="activeTab === 'assigned'" class="form-card">
      <div class="form-section-title">Assigned Permissions</div>
      <p class="form-desc">These permissions have been explicitly granted to this user.</p>
      <div v-if="allGranted.length === 0" class="empty-perm">
        No permissions have been granted yet. Go to <strong>Grant Permissions</strong> to assign them.
      </div>
      <table v-else class="perm-table" style="margin-top:16px;">
        <thead>
          <tr>
            <th>Permission Name</th>
            <th>Module</th>
            <th>Group</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in allGranted" :key="p.id">
            <td class="perm-name">{{ p.name }}</td>
            <td><code>{{ p.module }}</code></td>
            <td class="text-gray-500">{{ p.group }}</td>
            <td><span class="status-badge status-active"><span class="dot"></span>Granted</span></td>
          </tr>
        </tbody>
      </table>
    </div>

  </div>
</template>

<style scoped>
.create-user-page {
  display: flex;
  flex-direction: column;
  gap: 14px;
  font-family: 'Inter', sans-serif;
  animation: fadeIn 0.3s ease-out;
}
@keyframes fadeIn { from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)} }

/* Breadcrumbs */
.breadcrumbs { display:flex;align-items:center;gap:8px;font-size:13px;margin-bottom:4px; }
.breadcrumb-link { color:#9ca3af;text-decoration:none;display:flex;align-items:center;transition:color .15s; }
.breadcrumb-link:hover { color:#111827; }
.breadcrumb-text { font-size:13px; }
.breadcrumb-sep { color:#9ca3af;display:flex;align-items:center; }
.breadcrumb-active { color:#111827;font-weight:500; }
.not-saved-badge {
  background:#fff7ed; color:#c2410c; border:1px solid #fed7aa;
  padding:2px 10px; border-radius:20px; font-size:11px; font-weight:600; margin-left:4px;
}

/* Top action bar */
.top-action-bar { display:flex;justify-content:flex-end;gap:10px; }
.btn-clear {
  display:flex;align-items:center;gap:6px;padding:0 16px;height:38px;
  border:1px solid #e5e7eb;background:white;border-radius:8px;
  font-size:13px;font-weight:500;color:#374151;cursor:pointer;transition:all .2s;
}
.btn-clear:hover { background:#f9fafb;border-color:#d1d5db; }
.btn-save {
  display:flex;align-items:center;gap:6px;padding:0 20px;height:38px;
  background:var(--alias-color-brand-blue-primary,#2563eb);color:#fff;
  border:none;border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;transition:all .2s;
}
.btn-save:hover { background:var(--alias-color-brand-blue-primary-hover,#1d4ed8); }

/* Tabs row */
.tabs-row { display:flex; }

/* User Preview Card */
.user-preview-card {
  background:white;border:1px solid #e5e7eb;border-radius:14px;
  padding:18px 24px;display:flex;align-items:center;gap:24px;
  box-shadow:0 1px 3px rgba(0,0,0,.04);
}
.preview-avatar-wrap { position:relative; }
.preview-avatar {
  width:52px;height:52px;border-radius:50%;background:#4f46e5;
  display:flex;align-items:center;justify-content:center;
  font-size:18px;font-weight:700;color:white;text-transform:uppercase;
}
.avatar-edit-btn {
  position:absolute;bottom:-2px;right:-2px;width:22px;height:22px;border-radius:50%;
  background:white;border:1px solid #e5e7eb;color:#6b7280;cursor:pointer;
  display:flex;align-items:center;justify-content:center;
}
.preview-name { font-size:15px;font-weight:700;color:#111827; }
.preview-email { font-size:12px;color:#9ca3af;margin-top:2px; }
.preview-role-block,.preview-status-block { display:flex;flex-direction:column;gap:4px; }
.preview-label { font-size:11px;color:#9ca3af;font-weight:500;text-transform:uppercase;letter-spacing:.05em; }
.role-badge { display:inline-flex;padding:3px 12px;background:#eff6ff;color:#2563eb;border-radius:12px;font-size:12px;font-weight:600; }
.status-badge { display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:20px;font-size:12px;font-weight:500; }
.status-active { background:#ecfdf5;color:#059669; }
.status-inactive { background:#f3f4f6;color:#6b7280; }
.dot { width:6px;height:6px;border-radius:50%;background:currentColor;flex-shrink:0; }

/* Form Card */
.form-card {
  background:white;border:1px solid #e5e7eb;border-radius:14px;
  padding:24px;display:flex;flex-direction:column;gap:16px;
  box-shadow:0 1px 3px rgba(0,0,0,.04);
}
.form-section-title { font-size:14px;font-weight:700;color:#111827;margin-bottom:4px; }
.form-desc { font-size:13px;color:#6b7280;margin-top:-8px;line-height:1.6; }
.form-divider { border:none;border-top:1px solid #f3f4f6;margin:4px 0; }
.form-grid-2 { display:grid;grid-template-columns:1fr 1fr;gap:16px; }
.form-group { display:flex;flex-direction:column;gap:6px; }
.form-label { font-size:12px;font-weight:600;color:#374151; }
.form-input,.form-select {
  width:100%;padding:9px 12px;border:1px solid #e5e7eb;border-radius:8px;
  font-size:13px;outline:none;background:white;transition:border .15s;
}
.form-input:focus,.form-select:focus { border-color:#6366f1; }

/* Status Toggle */
.status-toggle-wrap { display:flex;gap:0;border:1px solid #e5e7eb;border-radius:8px;overflow:hidden; }
.status-toggle-btn {
  flex:1;padding:8px 0;font-size:12px;font-weight:600;border:none;
  cursor:pointer;background:white;color:#6b7280;transition:all .2s;
}
.status-toggle-btn.active { background:#ecfdf5;color:#059669; }
.status-toggle-btn.active-inactive { background:#f3f4f6;color:#374151; }

/* Roles Grid */
.roles-grid { display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:12px; }
.role-card {
  border:1.5px solid #e5e7eb;border-radius:12px;padding:16px;
  cursor:pointer;transition:all .2s;display:flex;gap:12px;align-items:flex-start;
}
.role-card:hover { border-color:#6366f1;background:#fafafe; }
.role-card.selected { border-color:#4f46e5;background:#f5f3ff; }
.check-circle {
  width:20px;height:20px;border-radius:50%;border:2px solid #d1d5db;
  display:flex;align-items:center;justify-content:center;
  flex-shrink:0;font-size:11px;font-weight:700;color:white;transition:all .2s;
}
.check-circle.checked { background:#4f46e5;border-color:#4f46e5; }
.role-card-name { font-size:13px;font-weight:700;color:#111827;margin-bottom:2px; }
.role-card-desc { font-size:12px;color:#6b7280;margin-bottom:6px; }
.role-card-meta { font-size:11px;color:#9ca3af; }

/* Grant Permissions – two-panel layout */
.grant-layout { flex-direction:row !important;gap:0;padding:0 !important;overflow:hidden; }
.perm-group-panel {
  width:230px;flex-shrink:0;border-right:1px solid #e5e7eb;
  padding:16px;display:flex;flex-direction:column;gap:10px;
}
.perm-list-panel { flex:1;padding:16px;display:flex;flex-direction:column;gap:12px;overflow:auto; }
.panel-title { font-size:13px;font-weight:700;color:#111827; }
.perm-group-list { list-style:none;padding:0;margin:0;display:flex;flex-direction:column;gap:2px; }
.perm-group-item {
  display:flex;align-items:center;justify-content:space-between;
  padding:8px 10px;border-radius:8px;cursor:pointer;font-size:12px;color:#374151;
  transition:all .15s;
}
.perm-group-item:hover { background:#f3f4f6; }
.perm-group-item.active { background:#eff6ff;color:#2563eb;font-weight:600; }
.perm-subgroup-item {
  display:flex;align-items:center;justify-content:space-between;
  padding:7px 10px 7px 20px;font-size:11px;color:#6b7280;
}
.perm-group-count { font-size:11px;background:#f1f5f9;color:#64748b;padding:1px 7px;border-radius:10px; }
.perm-list-header { display:flex;align-items:center;justify-content:space-between;gap:12px; }
.perm-list-title { font-size:13px;font-weight:700;color:#111827;display:flex;align-items:center;gap:8px; }
.perm-list-count { font-size:11px;background:#eff6ff;color:#2563eb;padding:2px 8px;border-radius:10px;font-weight:600; }
.perm-search-wrap { flex:1;max-width:260px; }

/* Perm Table */
.perm-table { width:100%;border-collapse:collapse; }
.perm-table th {
  text-align:left;padding:10px 12px;font-size:11px;font-weight:600;
  color:#6b7280;background:#f9fafb;border-bottom:1px solid #e5e7eb;
}
.perm-table td { padding:11px 12px;font-size:13px;border-bottom:1px solid #f3f4f6;vertical-align:middle; }
.perm-table tr:last-child td { border-bottom:none; }
.perm-name { font-size:13px;color:#374151; }

/* Toggle switch */
.toggle-wrap { display:flex;align-items:center;gap:8px;cursor:pointer; }
.toggle {
  width:34px;height:18px;border-radius:9px;background:#e5e7eb;
  position:relative;transition:background .2s;flex-shrink:0;
}
.toggle.on { background:#4f46e5; }
.toggle-knob {
  position:absolute;top:2px;left:2px;width:14px;height:14px;
  border-radius:50%;background:white;box-shadow:0 1px 2px rgba(0,0,0,.15);
  transition:transform .2s;
}
.toggle.on .toggle-knob { transform:translateX(16px); }
.toggle-label { font-size:12px;font-weight:500; }
.toggle-label.granted { color:#4f46e5; }
.toggle-label.not-granted { color:#9ca3af; }

/* Empty state */
.empty-perm {
  text-align:center;padding:40px;color:#9ca3af;font-size:13px;
  border:1.5px dashed #e5e7eb;border-radius:10px;line-height:1.7;
}

code {
  background:#f1f5f9;padding:2px 6px;border-radius:4px;
  font-family:monospace;font-size:11px;color:#0f172a;
}
.text-gray-500 { color:#6b7280; }
</style>
