<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import {
  Monitor, ChevronRight, User, Users, ShieldCheck, Key, Lock, Check, X,
  MoreVertical, Calendar, Image as ImageIcon, Plus, Trash2, HelpCircle,
  ChevronDown, ChevronUp, Bold, Italic, Underline, Strikethrough, Code,
  List, Table, Link as LinkIcon, Undo, Redo, Type, Info, Search, Filter,
  RotateCw, Columns, Maximize2, Edit, Slash, RotateCcw, Power, AlertTriangle
} from 'lucide-vue-next';
import BaseTabs from '../components/BaseTabs.vue';
import UnderlineTabs from '../components/UnderlineTabs.vue';
import AppBreadcrumb from '../components/AppBreadcrumb.vue';
import SaveStateBadge from '../components/SaveStateBadge.vue';

const router = useRouter();
const route = useRoute();

const isEditMode = computed(() => !!route.params.id);
const isSaved = ref(false);

// Active Tab navigation using BaseTabs
type UserTab = 'details' | 'roles' | 'assigned_roles' | 'grant' | 'granted';
const activeTab = ref<UserTab>('details');

const tabs = [
  { id: 'details', label: 'User Detail', icon: User },
  { id: 'roles', label: 'Assign Role', icon: Users },
  { id: 'assigned_roles', label: 'Assigned Role', icon: ShieldCheck },
  { id: 'grant', label: 'Grant Permissions', icon: Key },
  { id: 'granted', label: 'Granted Permissions', icon: Lock }
];

// Secondary Underline Tabs for Granted Permissions view
type SecondaryPermTab = 'role_based' | 'direct_grants' | 'revoked';
const activeSecondaryTab = ref<SecondaryPermTab>('role_based');

const secondaryPermissionTabs = [
  { id: 'role_based', label: 'Role Based Permissions', count: 160 },
  { id: 'direct_grants', label: 'Direct Grants / Temporal', count: 5 },
  { id: 'revoked', label: 'Revoked Role Permissions', count: 3 }
];

// ── GRANT PERMISSIONS state ──────────────────────────────────────────────
const grantForm = ref({
  startDate: '07/15/2026',
  endDate: '',
  entityType: '',
  entityId: '',
  includeDescendants: false
});

const grantPermSearch = ref('');
const grantGroupSearch = ref('');

// Tree structure for permission groups
interface PermNode { id: string; label: string; children?: PermNode[]; }
const permissionGroups: PermNode[] = [
  { id: 'inventory', label: 'Inventory' },
  {
    id: 'user-mgmt', label: 'User Management',
    children: [
      {
        id: 'user-group1', label: 'user Group1',
        children: [
          { id: 'um-user-mgmt', label: 'User Management' },
          { id: 'um-role-mgmt-1', label: 'Role Management' },
          { id: 'um-role-mgmt-2', label: 'Role Management' }
        ]
      }
    ]
  },
  { id: 'user-mgmt-2', label: 'User Management' },
  { id: 'user-mgmt-3', label: 'User Management' }
];

const selectedPermGroup = ref('um-user-mgmt');
const expandedGroups = ref<Set<string>>(new Set(['user-mgmt', 'user-group1']));

const toggleExpand = (id: string) => {
  if (expandedGroups.value.has(id)) {
    expandedGroups.value.delete(id);
  } else {
    expandedGroups.value.add(id);
  }
};

interface PermissionItem { id: string; name: string; enabled: boolean; }
const permissionItems = ref<PermissionItem[]>([
  { id: 'create-user', name: 'Create User', enabled: false },
  { id: 'view-user-list', name: 'View User list', enabled: false },
  { id: 'edit-user-info', name: 'Edit User Information', enabled: false },
  { id: 'reset-password', name: 'Reset User Password', enabled: false },
  { id: 'manage-role', name: 'Manage User Role', enabled: false },
  { id: 'view-activity', name: 'View Activity log', enabled: false },
  { id: 'delete-user', name: 'Delete User', enabled: false }
]);

const grantHeaderChecked = ref(false);
const filteredPermItems = computed(() => {
  if (!grantPermSearch.value.trim()) return permissionItems.value;
  return permissionItems.value.filter(p =>
    p.name.toLowerCase().includes(grantPermSearch.value.toLowerCase())
  );
});

const selectedGroupLabel = computed(() => {
  const flatten = (nodes: PermNode[]): PermNode[] =>
    nodes.flatMap(n => [n, ...(n.children ? flatten(n.children) : [])]);
  return flatten(permissionGroups).find(n => n.id === selectedPermGroup.value)?.label ?? 'User Management';
});

// ── GRANTED PERMISSIONS MATRIX DATA ──────────────────────────────────────────
const grantedSearchQuery = ref('');

const roleBasedPermissionsList = ref([
  { id: 1, permission: 'View User List', roles: 'Inventory Officer and Sales Manager', entity: 'Arat Kilo Branch and Kazanchis...' },
  { id: 2, permission: 'Edit User Information', roles: 'Inventory Officer and Sales Manager', entity: 'Arat Kilo Branch and Kazanchis...' },
  { id: 3, permission: 'Delete User Account', roles: 'Inventory Officer and Sales Manager', entity: 'Arat Kilo Branch and Kazanchis...' },
  { id: 4, permission: 'Manage Inventory', roles: 'Inventory Officer and Sales Manager', entity: 'Arat Kilo Branch and Kazanchis...' },
  { id: 5, permission: 'Approve Purchase Orders', roles: 'Inventory Officer and Sales Manager', entity: 'Arat Kilo Branch and Kazanchis...' },
  { id: 6, permission: 'Generate Reports', roles: 'Inventory Officer and Sales Manager', entity: 'Arat Kilo Branch and Kazanchis...' },
  { id: 7, permission: 'Configure System Settings', roles: 'Inventory Officer and Sales Manager', entity: 'Arat Kilo Branch and Kazanchis...' },
  { id: 8, permission: 'Manage Employee Records', roles: 'Inventory Officer and Sales Manager', entity: 'Kazanchis Branch' },
  { id: 9, permission: 'Process Refunds', roles: 'Inventory Officer and Sales Manager', entity: 'Kazanchis Branch' },
  { id: 10, permission: 'Audit Access Logs', roles: 'Inventory Officer and Sales Manager', entity: 'Kazanchis Branch' }
]);

const directGrantsList = ref([
  { id: 1, permission: 'Create User', validity: 'May 18, 2026 - May 18, 2026', entity: 'Hawassa Branch and Abissinya...', status: 'Granted', startDate: '2026-05-18', endDate: '2026-05-18' },
  { id: 2, permission: 'Create User', validity: 'Oct 01, 2026 - Dec 31, 2026', entity: 'Kazanchis Branch', status: 'Scheduled', startDate: '2026-10-01', endDate: '2026-12-31' },
  { id: 3, permission: 'Delete User Account', validity: 'May 18, 2026 - May 18, 2026', entity: 'Arat Kilo Branch and Kazanchis...', status: 'Granted', startDate: '2026-05-18', endDate: '2026-05-18' },
  { id: 4, permission: 'Manage Inventory', validity: 'Jan 01, 2026 - Jan 01, 2027', entity: 'Arat Kilo Branch and Kazanchis...', status: 'Inactive', startDate: '2026-01-01', endDate: '2027-01-01' },
  { id: 5, permission: 'Approve Purchase Orders', validity: 'May 18, 2026 - May 18, 2026', entity: 'Arat Kilo Branch and Kazanchis...', status: 'Granted', startDate: '2026-05-18', endDate: '2026-05-18' }
]);

const revokedPermissionsList = ref([
  { id: 1, permission: 'Edit Reports', entity: 'Hawassa Branch', period: 'May 18, 2026 - Jul 21, 2027', status: 'Revoked', startDate: '2026-05-18', endDate: '2027-07-21' },
  { id: 2, permission: 'Delete Records', entity: 'Kazanchis Branch', period: 'Oct 01, 2026 - Dec 31, 2026', status: 'Scheduled', startDate: '2026-10-01', endDate: '2026-12-31' },
  { id: 3, permission: 'Export Data', entity: 'Arat Kilo Branch', period: 'Apr 15, 2027 - Jun 30, 2027', status: 'Scheduled', startDate: '2027-04-15', endDate: '2027-06-30' }
]);

// ── ROLE & PERMISSION INTERACTIVE ACTIONS & MODALS ─────────────────────────────
const activeRoleMenuId = ref<number | null>(null);
const activePermMenuId = ref<number | null>(null);

const toggleRoleMenu = (id: number) => {
  activeRoleMenuId.value = activeRoleMenuId.value === id ? null : id;
  activePermMenuId.value = null;
};

const togglePermMenu = (id: number) => {
  activePermMenuId.value = activePermMenuId.value === id ? null : id;
  activeRoleMenuId.value = null;
};

// Edit Role Modal State
const showEditRoleModal = ref(false);
const editingRole = ref<{ id: number; roleName: string; entityScope: string; startDate: string; endDate: string } | null>(null);

const openEditRoleModal = (item: any) => {
  editingRole.value = {
    id: item.id,
    roleName: item.roleName,
    entityScope: Array.isArray(item.parentEntities) ? item.parentEntities.join(', ') : item.entityScope || '',
    startDate: '2026-05-18',
    endDate: '2026-05-18'
  };
  showEditRoleModal.value = true;
  activeRoleMenuId.value = null;
};

const saveEditedRole = () => {
  if (editingRole.value) {
    const roleObj = assignedRoleItems.value.find(r => r.id === editingRole.value!.id);
    if (roleObj) {
      roleObj.validity = `${editingRole.value.startDate} - ${editingRole.value.endDate}`;
    }
  }
  showEditRoleModal.value = false;
};

const toggleRoleStatus = (item: any) => {
  item.status = item.status === 'Active' ? 'Inactive' : 'Active';
  activeRoleMenuId.value = null;
};

const deleteRoleItem = (id: number) => {
  assignedRoleItems.value = assignedRoleItems.value.filter(r => r.id !== id);
  activeRoleMenuId.value = null;
};

// Revoke Permission Modal State
const showRevokeModal = ref(false);
const revokingPerm = ref<{
  permId: number;
  permName: string;
  selectedEntity: string;
  availableEntities: string[];
  startDate: string;
  endDate: string;
} | null>(null);

const openRevokeModal = (item: any) => {
  const entities = ['Arat Kilo Branch', 'Kazanchis Branch', 'Hawassa Branch'];
  revokingPerm.value = {
    permId: item.id,
    permName: item.permission,
    selectedEntity: 'Arat Kilo Branch',
    availableEntities: entities,
    startDate: '05/18/2026',
    endDate: '05/18/2027'
  };
  showRevokeModal.value = true;
  activePermMenuId.value = null;
};

const confirmRevokePermission = () => {
  if (!revokingPerm.value) return;

  const targetPerm = roleBasedPermissionsList.value.find(p => p.id === revokingPerm.value!.permId);
  if (targetPerm) {
    if (targetPerm.entity.includes(revokingPerm.value.selectedEntity)) {
      targetPerm.entity = targetPerm.entity.replace(revokingPerm.value.selectedEntity, '').replace(/and\s*$/, '').trim();
      if (!targetPerm.entity) targetPerm.entity = 'Direct Overridden';
    }
  }

  const newId = revokedPermissionsList.value.length + 1;
  revokedPermissionsList.value.push({
    id: newId,
    permission: revokingPerm.value.permName,
    entity: revokingPerm.value.selectedEntity,
    period: `${revokingPerm.value.startDate} - ${revokingPerm.value.endDate}`,
    status: 'Revoked'
  });

  secondaryPermissionTabs.find(t => t.id === 'revoked')!.count = revokedPermissionsList.value.length;
  secondaryPermissionTabs.find(t => t.id === 'role_based')!.count = roleBasedPermissionsList.value.length;

  showRevokeModal.value = false;
};

// Edit Revoked Permission Modal State
const showEditRevokeModal = ref(false);
const editingRevoke = ref<{ id: number; permission: string; entity: string; startDate: string; endDate: string } | null>(null);

const openEditRevokeModal = (item: any) => {
  editingRevoke.value = {
    id: item.id,
    permission: item.permission,
    entity: item.entity,
    startDate: item.startDate || '2026-05-18',
    endDate: item.endDate || '2027-07-21'
  };
  showEditRevokeModal.value = true;
  activePermMenuId.value = null;
};

const saveEditedRevoke = () => {
  if (editingRevoke.value) {
    const item = revokedPermissionsList.value.find(r => r.id === editingRevoke.value!.id);
    if (item) {
      item.startDate = editingRevoke.value.startDate;
      item.endDate = editingRevoke.value.endDate;
      item.period = `${editingRevoke.value.startDate} - ${editingRevoke.value.endDate}`;
      // Set status to Scheduled if start date is in future
      const isFuture = new Date(editingRevoke.value.startDate) > new Date('2026-07-24');
      item.status = isFuture ? 'Scheduled' : 'Revoked';
    }
  }
  showEditRevokeModal.value = false;
};

// Edit Direct Grant Modal State
const showEditDirectGrantModal = ref(false);
const editingDirectGrant = ref<{ id: number; permission: string; entity: string; startDate: string; endDate: string } | null>(null);

const openEditDirectGrantModal = (item: any) => {
  editingDirectGrant.value = {
    id: item.id,
    permission: item.permission,
    entity: item.entity,
    startDate: item.startDate || '2026-05-18',
    endDate: item.endDate || '2026-05-18'
  };
  showEditDirectGrantModal.value = true;
  activePermMenuId.value = null;
};

const saveEditedDirectGrant = () => {
  if (editingDirectGrant.value) {
    const item = directGrantsList.value.find(d => d.id === editingDirectGrant.value!.id);
    if (item) {
      item.startDate = editingDirectGrant.value.startDate;
      item.endDate = editingDirectGrant.value.endDate;
      item.validity = `${editingDirectGrant.value.startDate} - ${editingDirectGrant.value.endDate}`;
      const isFuture = new Date(editingDirectGrant.value.startDate) > new Date('2026-07-24');
      item.status = isFuture ? 'Scheduled' : 'Granted';
    }
  }
  showEditDirectGrantModal.value = false;
};

const toggleDirectGrantStatus = (item: any) => {
  item.status = item.status === 'Inactive' ? 'Granted' : 'Inactive';
  activePermMenuId.value = null;
};

const toggleRevokedStatus = (item: any) => {
  item.status = item.status === 'Inactive' ? 'Revoked' : 'Inactive';
  activePermMenuId.value = null;
};

// State mode toggle for demonstration / testing empty vs filled state
const isDemoFilled = ref<boolean>(isEditMode.value);

// Profile Photo & File Upload State
const fileInputRef = ref<HTMLInputElement | null>(null);
const profilePhoto = ref<string | null>(
  isDemoFilled.value
    ? 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=300&auto=format&fit=crop&q=80'
    : null
);

const triggerFileInput = () => {
  if (fileInputRef.value) {
    fileInputRef.value.click();
  }
};

const handleFileChange = (e: Event) => {
  const target = e.target as HTMLInputElement;
  if (target.files && target.files[0]) {
    const file = target.files[0];
    profilePhoto.value = URL.createObjectURL(file);
  }
};

// National ID verification state
const isVerified = ref<boolean>(isDemoFilled.value);

const verifyNationalId = () => {
  if (form.value.nationalId.trim().length > 0) {
    isVerified.value = true;
  }
};

// Form state - Default EMPTY for Create User mode, FILLED for Edit mode
const form = ref({
  nationalId: isDemoFilled.value ? '4546453254545' : '',
  firstName: isDemoFilled.value ? 'Aberash' : '',
  middleName: isDemoFilled.value ? 'Kebede' : '',
  lastName: isDemoFilled.value ? 'Ayele' : '',
  countryCode: 'ET',
  phone: isDemoFilled.value ? '+251 184-512-815' : '',
  email: isDemoFilled.value ? 'qelem@gmail.com' : '',
  gender: isDemoFilled.value ? 'Female' : '',
  dob: isDemoFilled.value ? '2000-12-02' : '',
  biography: isDemoFilled.value
    ? `Sarah Jenkins is a Lead ERP Consultant & Inventory Strategist based in Seattle, Washington, with over seven years of experience in enterprise software. She specializes in supply chain forecasting and SAP Inventory Management rollouts, consistently striving to help retail brands streamline their stock control and minimize waste.

Sarah began her career after earning a Master's degree in Operations Management from the University of Washington. Since then, she has guided mid-sized e-commerce businesses through complex digital transformations.

One of her proudest achievements was leading a Microsoft Dynamics 365 migration for a national apparel brand, which synchronized stock across 50+ warehouses and reduced order processing times by 30%.Outside of her professional consulting, Sarah is passionate about open-water swimming and mentors young women pursuing careers in STEM.`
    : ''
});

// Role Assignment Form state (Assign Role tab)
const roleForm = ref({
  selectedRole: isDemoFilled.value ? 'Sales Manager' : '',
  startDate: isDemoFilled.value ? '07/15/2026' : '07/15/2026',
  endDate: isDemoFilled.value ? '07/15/2027' : '',
  entityType: isDemoFilled.value ? 'Branch' : '',
  entityId: isDemoFilled.value ? 'Bole Road Branch' : '',
  includeDescendants: false
});

// Entity Filter Tabs for Assigned Role tab — uses UnderlineTabs secondary style
type EntityTab = 'All' | 'Qelem meda Org.' | 'Bole Branch' | 'Garment Branch';
const entityFilterTabs = [
  { id: 'All', label: 'All' },
  { id: 'Qelem meda Org.', label: 'Qelem meda Org.' },
  { id: 'Bole Branch', label: 'Bole Branch' },
  { id: 'Garment Branch', label: 'Garment Branch' }
] as const;

const activeEntityTab = ref<string>('All');

interface AssignedRoleItem {
  id: number;
  roleName: string;
  parentEntities: string[];
  validity: string;
  status: 'Active' | 'Inactive';
  deactivatedEntity?: string;
}

const assignedRoleItems = ref<AssignedRoleItem[]>([
  {
    id: 1,
    roleName: 'Sales Manager',
    parentEntities: ['Qelem meda Org.', 'Bole Branch'],
    validity: 'May 18, 2026 - May 18, 2027',
    status: 'Active'
  },
  {
    id: 2,
    roleName: 'Inventory Officer',
    parentEntities: ['Garment Branch', 'Qelem meda Org.'],
    validity: 'Jan 10, 2026 - Jan 10, 2027',
    status: 'Active'
  },
  {
    id: 3,
    roleName: 'Branch Manager',
    parentEntities: ['Bole Branch'],
    validity: 'Jul 01, 2026 - Dec 31, 2026',
    status: 'Inactive',
    deactivatedEntity: 'Bole Branch'
  }
]);

const activeAssignedRoles = computed(() => {
  if (activeEntityTab.value === 'All') {
    return assignedRoleItems.value.filter(item => item.status === 'Active');
  }
  return assignedRoleItems.value.filter(
    item => item.status === 'Active' && item.parentEntities.includes(activeEntityTab.value)
  );
});

const inactiveAssignedRoles = computed(() => {
  if (activeEntityTab.value === 'All') {
    return assignedRoleItems.value.filter(item => item.status === 'Inactive');
  }
  return assignedRoleItems.value.filter(
    item => item.status === 'Inactive' && item.parentEntities.includes(activeEntityTab.value)
  );
});

// Multi-select for role rows bulk management
const selectedRoleIds = ref<number[]>([]);

const toggleRoleSelection = (id: number) => {
  const index = selectedRoleIds.value.indexOf(id);
  if (index > -1) {
    selectedRoleIds.value.splice(index, 1);
  } else {
    selectedRoleIds.value.push(id);
  }
};

// Deactivate / Delete Role Modal State
const showDeactivateDeleteRoleModal = ref(false);

interface EntitySelectionState {
  entityName: string;
  selected: boolean;
}

const roleManageState = ref<{
  roleId: number;
  roleName: string;
  actionType: 'deactivate' | 'delete';
  entities: EntitySelectionState[];
}>({
  roleId: 0,
  roleName: '',
  actionType: 'deactivate',
  entities: []
});

const openDeactivateRoleModal = (item: AssignedRoleItem) => {
  roleManageState.value = {
    roleId: item.id,
    roleName: item.roleName,
    actionType: 'deactivate',
    entities: item.parentEntities.map(e => ({ entityName: e, selected: true }))
  };
  showDeactivateDeleteRoleModal.value = true;
  activeRoleMenuId.value = null;
};

const openDeleteRoleModal = (item: AssignedRoleItem) => {
  roleManageState.value = {
    roleId: item.id,
    roleName: item.roleName,
    actionType: 'delete',
    entities: item.parentEntities.map(e => ({ entityName: e, selected: true }))
  };
  showDeactivateDeleteRoleModal.value = true;
  activeRoleMenuId.value = null;
};

const openBulkManageModal = (actionType: 'deactivate' | 'delete') => {
  if (selectedRoleIds.value.length === 0) return;
  
  const selectedRoles = assignedRoleItems.value.filter(r => selectedRoleIds.value.includes(r.id));
  const roleNames = selectedRoles.map(r => r.roleName).join(', ');
  const allEntities = Array.from(new Set(selectedRoles.flatMap(r => r.parentEntities)));

  roleManageState.value = {
    roleId: -1,
    roleName: roleNames,
    actionType: actionType,
    entities: allEntities.map(e => ({ entityName: e, selected: true }))
  };
  showDeactivateDeleteRoleModal.value = true;
};

const toggleAllEntitiesSelection = (checked: boolean) => {
  roleManageState.value.entities.forEach(e => {
    e.selected = checked;
  });
};

const isAllEntitiesSelected = computed(() => {
  return roleManageState.value.entities.length > 0 && roleManageState.value.entities.every(e => e.selected);
});

const applyDeactivateDeleteRole = () => {
  const selectedEntityNames = roleManageState.value.entities
    .filter(e => e.selected)
    .map(e => e.entityName);

  if (selectedEntityNames.length === 0) return;

  if (roleManageState.value.roleId === -1) {
    // Bulk operation for multi-selected roles
    assignedRoleItems.value.forEach(roleObj => {
      if (!selectedRoleIds.value.includes(roleObj.id)) return;

      if (roleManageState.value.actionType === 'deactivate') {
        roleObj.status = 'Inactive';
        roleObj.deactivatedEntity = selectedEntityNames.join(', ');
      } else if (roleManageState.value.actionType === 'delete') {
        roleObj.parentEntities = roleObj.parentEntities.filter(e => !selectedEntityNames.includes(e));
      }
    });

    if (roleManageState.value.actionType === 'delete') {
      assignedRoleItems.value = assignedRoleItems.value.filter(r => r.parentEntities.length > 0);
    }
    selectedRoleIds.value = [];
  } else {
    // Single role operation
    const roleObj = assignedRoleItems.value.find(r => r.id === roleManageState.value.roleId);
    if (roleObj) {
      if (roleManageState.value.actionType === 'deactivate') {
        if (selectedEntityNames.length === roleObj.parentEntities.length) {
          roleObj.status = 'Inactive';
          roleObj.deactivatedEntity = 'All Entities';
        } else {
          roleObj.status = 'Inactive';
          roleObj.deactivatedEntity = selectedEntityNames.join(', ');
        }
      } else if (roleManageState.value.actionType === 'delete') {
        if (selectedEntityNames.length === roleObj.parentEntities.length) {
          assignedRoleItems.value = assignedRoleItems.value.filter(r => r.id !== roleObj.id);
        } else {
          roleObj.parentEntities = roleObj.parentEntities.filter(e => !selectedEntityNames.includes(e));
          if (roleObj.parentEntities.length === 0) {
            assignedRoleItems.value = assignedRoleItems.value.filter(r => r.id !== roleObj.id);
          }
        }
      }
    }
  }

  showDeactivateDeleteRoleModal.value = false;
};

// Toggle between Empty and Filled demo states
const toggleDemoState = () => {
  isDemoFilled.value = !isDemoFilled.value;
  if (isDemoFilled.value) {
    profilePhoto.value = 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=300&auto=format&fit=crop&q=80';
    isVerified.value = true;
    form.value = {
      nationalId: '4546453254545',
      firstName: 'Aberash',
      middleName: 'Kebede',
      lastName: 'Ayele',
      countryCode: 'ET',
      phone: '+251 184-512-815',
      email: 'qelem@gmail.com',
      gender: 'Female',
      dob: '2000-12-02',
      biography: `Sarah Jenkins is a Lead ERP Consultant & Inventory Strategist based in Seattle, Washington.`
    };
    roleForm.value = {
      selectedRole: 'Sales Manager',
      startDate: '07/15/2026',
      endDate: '07/15/2027',
      entityType: 'Branch',
      entityId: 'Bole Road Branch',
      includeDescendants: true
    };
  } else {
    profilePhoto.value = null;
    isVerified.value = false;
    form.value = {
      nationalId: '',
      firstName: '',
      middleName: '',
      lastName: '',
      countryCode: 'ET',
      phone: '',
      email: '',
      gender: '',
      dob: '',
      biography: ''
    };
    roleForm.value = {
      selectedRole: '',
      startDate: '07/15/2026',
      endDate: '',
      entityType: '',
      entityId: '',
      includeDescendants: false
    };
  }
};

const availableRoles = [
  { id: 1, name: 'Admin', description: 'Full system administrative control and access to all settings.' },
  { id: 2, name: 'Sales Manager', description: 'Manage sales campaigns, customer relationships and point of sales.' },
  { id: 3, name: 'Inventory Officer', description: 'Stock management, ledger controls and item variations.' },
  { id: 4, name: 'Accountant', description: 'Financial controls, invoices, pricing structures and TIN setup.' }
];

// Clear Form Action
const handleClearForm = () => {
  if (confirm('Are you sure you want to clear all form fields?')) {
    profilePhoto.value = null;
    isVerified.value = false;
    form.value = {
      nationalId: '',
      firstName: '',
      middleName: '',
      lastName: '',
      countryCode: 'ET',
      phone: '',
      email: '',
      gender: '',
      dob: '',
      biography: ''
    };
    roleForm.value = {
      selectedRole: '',
      startDate: '07/15/2026',
      endDate: '',
      entityType: '',
      entityId: '',
      includeDescendants: false
    };
    isDemoFilled.value = false;
  }
};

const handleSave = () => {
  isSaved.value = true;
  alert('User information saved successfully!');
  router.push('/company-setup/user-and-access');
};
</script>

<template>
  <div class="user-detail-page">

    <!-- Top Navigation Breadcrumbs & Action Bar -->
    <div class="header-action-row">
      <AppBreadcrumb 
        :items="[
          { label: 'User & Access', to: '/company-setup/user-and-access' },
          { label: isEditMode ? 'Edit User' : 'Create User' }
        ]"
      >
        <template #extra>
          <SaveStateBadge :isSaved="isSaved" />
        </template>
      </AppBreadcrumb>

      <!-- Action Buttons -->
      <div class="header-action-buttons">
        <button 
          class="btn-demo-toggle" 
          @click="toggleDemoState" 
          :title="isDemoFilled ? 'Switch to Empty State' : 'Switch to Filled State'"
        >
          <span>{{ isDemoFilled ? 'State: Filled' : 'State: Empty' }}</span>
        </button>

        <button class="icon-menu-btn" title="More options">
          <MoreVertical :size="16" />
        </button>

        <button class="btn-clear-form" @click="handleClearForm">
          <X :size="14" />
          <span>Clear Form</span>
        </button>

        <button class="btn-save-primary" @click="handleSave">
          <span>Save</span>
        </button>
      </div>
    </div>

    <!-- Primary Round Navigation Tabs Header using BaseTabs component -->
    <div class="tab-header-container">
      <BaseTabs v-model="activeTab" :tabs="tabs" size="md" />
    </div>

    <!-- ── TAB 1: USER DETAIL FORM ────────────────────────────────────────── -->
    <div v-if="activeTab === 'details'" class="form-content-card">

      <!-- Section 1: Photo Upload Header -->
      <div class="photo-upload-section">
        <!-- Photo Avatar Container -->
        <div class="avatar-box-wrapper">
          <img
            v-if="profilePhoto"
            :src="profilePhoto"
            alt="User Photo"
            class="user-photo-img"
          />
          <div v-else class="empty-photo-placeholder">
            <ImageIcon :size="30" class="text-slate-400" />
            <span class="empty-photo-label">No Media</span>
          </div>
        </div>

        <!-- Right Upload Controls -->
        <div class="upload-controls-stack">
          <button @click="triggerFileInput" class="btn-upload-new">
            Upload New Photo
          </button>
          <input
            type="file"
            ref="fileInputRef"
            accept="image/*"
            class="hidden"
            @change="handleFileChange"
          />
          <p class="upload-help-text">
            Upload a JPG or PNG image with a minimum resolution of 800 &times; 800 px.<br />
            The file size must not exceed 10 MB.
          </p>
        </div>
      </div>

      <div class="card-divider"></div>

      <!-- Section 2: National ID Verification -->
      <div class="national-id-section">
        <label class="input-field-label">National ID</label>

        <div class="nid-input-group">
          <div class="nid-input-box">
            <input
              v-model="form.nationalId"
              type="text"
              
              class="nid-text-input"
            />
            <Check v-if="isVerified && form.nationalId" :size="16" class="nid-check-icon text-emerald-600" />
          </div>

          <button
            :class="['btn-verify-id', isVerified && form.nationalId ? 'btn-verified-active' : 'btn-verify-disabled']"
            @click="verifyNationalId"
          >
            Verify ID
          </button>
        </div>

        <p v-if="isVerified && form.nationalId" class="nid-success-text">
          National ID Verified Successfully.
        </p>
      </div>

      <div class="card-divider"></div>

      <!-- Section 3: Personal Information -->
      <div class="personal-info-section">
        <h3 class="section-group-title">Personal information</h3>

        <!-- Row 1: Name 3-column grid -->
        <div class="grid-col-3">
          <div class="form-field-group">
            <label class="input-field-label">First name <span class="required-star">*</span></label>
            <input
              v-model="form.firstName"
              type="text"
              placeholder=""
              class="form-text-input"
            />
          </div>

          <div class="form-field-group">
            <label class="input-field-label">Middle name <span class="required-star">*</span></label>
            <input
              v-model="form.middleName"
              type="text"
              placeholder=""
              class="form-text-input"
            />
          </div>

          <div class="form-field-group">
            <label class="input-field-label">Last name</label>
            <input
              v-model="form.lastName"
              type="text"
              placeholder=""
              class="form-text-input"
            />
          </div>
        </div>

        <!-- Row 2: Phone & Email 2-column grid -->
        <div class="grid-col-2">
          <div class="form-field-group">
            <label class="input-field-label">Phone number <span class="required-star">*</span></label>
            <div class="phone-input-wrap">
              <select v-model="form.countryCode" class="phone-country-select">
                <option value="ET">ET</option>
                <option value="US">US</option>
                <option value="UK">UK</option>
              </select>
              <ChevronDown :size="12" class="country-select-arrow" />
              <input
                v-model="form.phone"
                type="text"
                
                class="phone-text-input"
              />
            </div>
          </div>

          <div class="form-field-group">
            <label class="input-field-label">Email</label>
            <input
              v-model="form.email"
              type="email"
              placeholder=""
              class="form-text-input"
            />
          </div>
        </div>

        <!-- Row 3: Gender & Date of Birth 2-column grid -->
        <div class="grid-col-2">
          <div class="form-field-group">
            <label class="input-field-label">Gender <span class="required-star">*</span></label>
            <div class="select-wrapper">
              <select v-model="form.gender" class="form-select-input">
                <option value="">Select</option>
                <option value="Female">Female</option>
                <option value="Male">Male</option>
              </select>
              <ChevronDown :size="14" class="select-chevron-icon" />
            </div>
          </div>

          <div class="form-field-group">
            <label class="input-field-label">Date of Birth</label>
            <div class="dob-input-wrap">
              <Calendar :size="16" class="dob-calendar-icon" />
              <input
                v-model="form.dob"
                type="text"
                
                class="dob-text-input"
              />
              <span class="gc-pill-tag">GC</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Section 4: Biography Rich Text Editor -->
      <div class="biography-section">
        <h3 class="section-group-title">Biography</h3>

        <div class="rich-editor-container">
          <!-- Editor Toolbar -->
          <div class="editor-toolbar">
            <div class="toolbar-dropdown">
              <span>Paragraph</span>
              <ChevronDown :size="12" />
            </div>

            <div class="toolbar-divider"></div>

            <div class="toolbar-dropdown">
              <span>Font Type</span>
              <ChevronDown :size="12" />
            </div>

            <div class="toolbar-divider"></div>

            <div class="toolbar-icon-group">
              <button class="editor-icon-btn" title="List"><List :size="14" /><ChevronDown :size="10" /></button>
              <button class="editor-icon-btn font-bold" title="Bold">B</button>
              <button class="editor-icon-btn italic" title="Italic">I</button>
              <button class="editor-icon-btn underline" title="Underline">U</button>
              <button class="editor-icon-btn line-through" title="Strikethrough">S</button>
              <button class="editor-icon-btn" title="Code">&lt;&gt;</button>
              <button class="editor-icon-btn" title="Table"><Table :size="14" /></button>
            </div>

            <div class="toolbar-divider"></div>

            <div class="toolbar-icon-group">
              <button class="editor-icon-btn" title="Text Color">A<ChevronDown :size="10" /></button>
              <button class="editor-icon-btn" title="Insert Link"><LinkIcon :size="14" /></button>
              <button class="editor-icon-btn" title="Insert Image"><ImageIcon :size="14" /></button>
            </div>

            <div class="toolbar-icon-group ml-auto">
              <button class="editor-icon-btn" title="Undo"><Undo :size="14" /></button>
              <button class="editor-icon-btn" title="Redo"><Redo :size="14" /></button>
            </div>
          </div>

          <!-- Editor Text Area -->
          <textarea
            v-model="form.biography"
            rows="7"
            class="editor-textarea"
            placeholder=""
          ></textarea>

          <!-- Editor Footer Bar -->
          <div class="editor-footer">
            <span class="char-count-pill">{{ form.biography.length }} / 5,000 Characters</span>
            <div class="editor-resize-handle">//</div>
          </div>
        </div>
      </div>

    </div>

    <!-- ── TAB 2: ASSIGN ROLE ─────────────────────────────────────────────── -->
    <div v-else-if="activeTab === 'roles'" class="roles-tab-container">

      <!-- Card 1: Role Assignment -->
      <div class="form-content-card">
        <div class="card-header-with-icon">
          <h2 class="card-section-title">Role Assignment</h2>
          <Info :size="16" class="text-slate-400" title="Roles provide pre-configured bundles of permissions" />
        </div>
        <p class="card-subtitle-desc">
          Roles provide a pre-configured bundle of permissions. Assign a role below and select an effective date range. Once saved, you can review, edit, or remove assignments under the <strong>Assigned Role tab</strong>.
        </p>

        <div class="card-divider"></div>

        <!-- Role Assignment and Date Form -->
        <div class="role-form-block">
          <h3 class="section-group-title">Role Assignment and Date</h3>

          <div class="grid-col-3">
            <!-- Column 1: Select Role -->
            <div class="form-field-group">
              <label class="input-field-label">Select Role</label>
              <div class="select-wrapper">
                <select v-model="roleForm.selectedRole" class="form-select-input">
                  <option value="">Role</option>
                  <option value="Admin">Admin</option>
                  <option value="Sales Manager">Sales Manager</option>
                  <option value="Branch Manager">Branch Manager</option>
                  <option value="Inventory Officer">Inventory Officer</option>
                  <option value="Accountant">Accountant</option>
                </select>
                <ChevronDown :size="14" class="select-chevron-icon" />
              </div>
            </div>

            <!-- Column 2: Start Date * -->
            <div class="form-field-group">
              <label class="input-field-label">Start Date <span class="required-star">*</span></label>
              <div class="dob-input-wrap">
                <Calendar :size="16" class="dob-calendar-icon" />
                <input
                  v-model="roleForm.startDate"
                  type="text"
                  
                  class="dob-text-input"
                />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>

            <!-- Column 3: End Date -->
            <div class="form-field-group">
              <label class="input-field-label">End Date</label>
              <div class="dob-input-wrap">
                <Calendar :size="16" class="dob-calendar-icon" />
                <input
                  v-model="roleForm.endDate"
                  type="text"
                  
                  class="dob-text-input"
                />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Card 2: Entity Specific -->
      <div class="form-content-card">
        <h2 class="card-section-title">Entity Specific</h2>

        <div class="grid-col-2">
          <!-- Column 1: Entity Type -->
          <div class="form-field-group">
            <label class="input-field-label">Entity Type</label>
            <div class="select-wrapper">
              <select v-model="roleForm.entityType" class="form-select-input">
                <option value="">Select Type</option>
                <option value="Business Group">Business Group</option>
                <option value="Organization">Organization</option>
                <option value="Branch">Branch</option>
                <option value="Shop">Shop</option>
              </select>
              <ChevronDown :size="14" class="select-chevron-icon" />
            </div>
          </div>

          <!-- Column 2: Specific Entity -->
          <div class="form-field-group">
            <label class="input-field-label">-</label>
            <div class="select-wrapper">
              <select v-model="roleForm.entityId" class="form-select-input">
                <option value="">Select Entity</option>
                <option value="Haleta Enterprise Group">Haleta Enterprise Group</option>
                <option value="Bole Road Branch">Bole Road Branch</option>
                <option value="Downtown Shop">Downtown Shop</option>
              </select>
              <ChevronDown :size="14" class="select-chevron-icon" />
            </div>
          </div>
        </div>

        <!-- Descendant Inclusion Box -->
        <div class="descendant-box" @click="roleForm.includeDescendants = !roleForm.includeDescendants">
          <span>Include descendant</span>
          <ChevronRight :size="14" class="text-slate-400" />
        </div>
      </div>

    </div>

    <!-- ── TAB 3: ASSIGNED ROLE (Role Management & Entity Filters) ──────────── -->
    <div v-else-if="activeTab === 'assigned_roles'" class="form-content-card">
      <div class="card-header-block">
        <h2 class="card-section-title">Role Management</h2>
        <p class="card-subtitle-desc">
          Manage this user's roles by granting or revoking access across all entities, or assign roles only within selected entities based on their responsibilities.
        </p>
      </div>

      <!-- Entity Filter Bar — Secondary Underline Tabs (same as Granted Permissions) -->
      <div v-if="isDemoFilled && assignedRoleItems.length > 0" class="entity-underline-tabs-wrapper">
        <UnderlineTabs v-model="activeEntityTab" :tabs="entityFilterTabs" />
      </div>

      <!-- About Role Assignments Banner -->
      <div v-if="activeEntityTab === 'All'" class="about-edit-role-banner">
        <div class="banner-icon-box">
          <Info :size="18" class="text-blue-600" />
        </div>
        <div class="banner-content-text">
          <h4 class="banner-title font-bold text-blue-900">About Role Assignments & Entity Scope</h4>
          <p class="banner-desc text-blue-700 text-xs">
            Role statuses are configured per entity rather than as a single global status. In this All view, active roles across your assigned entities are displayed in the top section, while roles deactivated specifically for a particular entity or across all entities are grouped in the inactive section below. Use the entity tabs above to navigate and manage role assignments for a specific parent entity.
          </p>
        </div>
      </div>

      <!-- Bulk Selection Action Bar -->
      <div v-if="selectedRoleIds.length > 0" class="bulk-action-bar flex items-center justify-between p-3 bg-blue-50 border border-blue-200 rounded-xl mb-4 text-xs">
        <div class="flex items-center gap-2 font-medium text-blue-900">
          <Check :size="16" class="text-blue-600" />
          <span>{{ selectedRoleIds.length }} role(s) selected</span>
        </div>
        <div class="flex items-center gap-2">
          <button class="px-3 py-1.5 bg-amber-600 text-white font-semibold rounded-lg hover:bg-amber-700 transition-colors shadow-sm" @click="openBulkManageModal('deactivate')">
            Deactivate Selected Roles...
          </button>
          <button class="px-3 py-1.5 bg-rose-600 text-white font-semibold rounded-lg hover:bg-rose-700 transition-colors shadow-sm" @click="openBulkManageModal('delete')">
            Delete Selected Roles...
          </button>
          <button class="px-2.5 py-1.5 text-slate-600 hover:text-slate-900 font-medium" @click="selectedRoleIds = []">
            Clear Selection
          </button>
        </div>
      </div>

      <!-- Role Lists: Active & Inactive Sections -->
      <div v-if="isDemoFilled && (activeAssignedRoles.length > 0 || inactiveAssignedRoles.length > 0)" class="assigned-roles-container space-y-6">
        
        <!-- ── ACTIVE ROLES SECTION (TOP PART) ── -->
        <div v-if="activeAssignedRoles.length > 0" class="role-group-section">
          <div class="role-group-header flex items-center justify-between mb-3 pb-2 border-b border-slate-100">
            <div class="flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-emerald-500"></span>
              <h3 class="text-sm font-semibold text-slate-800">Active Roles</h3>
              <span class="count-pill-tag bg-emerald-50 text-emerald-700 border border-emerald-200 text-xs px-2 py-0.5 rounded-full font-medium">
                {{ activeAssignedRoles.length }}
              </span>
            </div>
          </div>

          <div class="assigned-role-rows-stack">
            <div 
              v-for="item in activeAssignedRoles" 
              :key="item.id" 
              class="assigned-role-card-row relative"
            >
              <!-- Multi-select Checkbox -->
              <div class="role-select-cell pr-1">
                <input 
                  type="checkbox" 
                  :checked="selectedRoleIds.includes(item.id)" 
                  @change="toggleRoleSelection(item.id)"
                  class="rounded border-slate-300 text-blue-600 focus:ring-blue-500 cursor-pointer" 
                />
              </div>

              <!-- Col 1: Role Name -->
              <div class="role-name-cell font-bold text-slate-900 min-w-[150px]">
                {{ item.roleName }}
              </div>

              <!-- Col 2: Parent Entities (Top tabs matching entity tags) -->
              <div class="role-entities-cell flex-1 flex flex-wrap items-center gap-1.5">
                <span 
                  v-for="entity in item.parentEntities" 
                  :key="entity"
                  class="entity-chip-tag"
                >
                  {{ entity }}
                </span>
              </div>

              <!-- Col 3: Validity Date Range -->
              <div class="role-date-cell text-xs text-slate-500 font-mono">
                {{ item.validity }}
              </div>

              <!-- Col 4: Status Pill -->
              <div class="role-status-cell">
                <span class="status-pill pill-active">
                  Active
                </span>
              </div>

              <!-- Col 5: Actions Menu -->
              <div class="role-action-cell relative">
                <button class="icon-menu-btn-sm" @click.stop="toggleRoleMenu(item.id)" title="More options">
                  <MoreVertical :size="16" />
                </button>

                <!-- Role Action Menu Dropdown -->
                <div v-if="activeRoleMenuId === item.id" class="dropdown-action-menu">
                  <button 
                    v-if="activeEntityTab !== 'All'"
                    class="dropdown-item-btn" 
                    @click="openEditRoleModal(item)"
                  >
                    <Edit :size="14" />
                    <span>Edit Role</span>
                  </button>

                  <button class="dropdown-item-btn" @click="openDeactivateRoleModal(item)">
                    <Power :size="14" />
                    <span>Deactivate Role...</span>
                  </button>

                  <button class="dropdown-item-btn text-rose-600" @click="openDeleteRoleModal(item)">
                    <Trash2 :size="14" />
                    <span>Delete Role...</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- ── INACTIVE ROLES SECTION (BOTTOM PART) ── -->
        <div v-if="inactiveAssignedRoles.length > 0" class="role-group-section mt-6">
          <div class="role-group-header flex items-center justify-between mb-3 pb-2 border-b border-slate-100">
            <div class="flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-amber-500"></span>
              <h3 class="text-sm font-semibold text-slate-800">Inactive Roles</h3>
              <span class="count-pill-tag bg-amber-50 text-amber-700 border border-amber-200 text-xs px-2 py-0.5 rounded-full font-medium">
                {{ inactiveAssignedRoles.length }}
              </span>
            </div>
          </div>

          <div class="assigned-role-rows-stack">
            <div 
              v-for="item in inactiveAssignedRoles" 
              :key="item.id" 
              class="assigned-role-card-row relative bg-slate-50/60 border-amber-200/60"
            >
              <!-- Multi-select Checkbox -->
              <div class="role-select-cell pr-1">
                <input 
                  type="checkbox" 
                  :checked="selectedRoleIds.includes(item.id)" 
                  @change="toggleRoleSelection(item.id)"
                  class="rounded border-slate-300 text-blue-600 focus:ring-blue-500 cursor-pointer" 
                />
              </div>

              <!-- Col 1: Role Name -->
              <div class="role-name-cell font-bold text-slate-700 min-w-[150px]">
                {{ item.roleName }}
              </div>

              <!-- Col 2: Parent Entities -->
              <div class="role-entities-cell flex-1 flex flex-wrap items-center gap-1.5">
                <span 
                  v-for="entity in item.parentEntities" 
                  :key="entity"
                  class="entity-chip-tag opacity-80"
                >
                  {{ entity }}
                </span>
              </div>

              <!-- Col 3: Validity Date Range -->
              <div class="role-date-cell text-xs text-slate-500 font-mono">
                {{ item.validity }}
              </div>

              <!-- Col 4: Status Pill (Entity specific or all entities deactivation indicator) -->
              <div class="role-status-cell">
                <span class="status-pill pill-inactive">
                  {{ item.deactivatedEntity ? `Deactivated (${item.deactivatedEntity})` : 'Inactive' }}
                </span>
              </div>

              <!-- Col 5: Actions Menu -->
              <div class="role-action-cell relative">
                <button class="icon-menu-btn-sm" @click.stop="toggleRoleMenu(item.id)" title="More options">
                  <MoreVertical :size="16" />
                </button>

                <!-- Role Action Menu Dropdown -->
                <div v-if="activeRoleMenuId === item.id" class="dropdown-action-menu">
                  <button 
                    v-if="activeEntityTab !== 'All'"
                    class="dropdown-item-btn" 
                    @click="openEditRoleModal(item)"
                  >
                    <Edit :size="14" />
                    <span>Edit Role</span>
                  </button>

                  <button class="dropdown-item-btn" @click="openDeactivateRoleModal(item)">
                    <Power :size="14" />
                    <span>Manage Status...</span>
                  </button>

                  <button class="dropdown-item-btn text-rose-600" @click="openDeleteRoleModal(item)">
                    <Trash2 :size="14" />
                    <span>Delete Role...</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>

      <!-- Empty State -->
      <div v-else class="empty-assigned-roles-state">
        <p class="font-medium text-slate-700">No roles assigned for the selected entity filter</p>
        <p class="text-xs text-slate-400 mt-1">Go to the "Assign Role" tab to add a new role assignment.</p>
      </div>
    </div>

    <!-- ── TAB 4: GRANT PERMISSIONS ─────────────────────────────────────── -->
    <div v-else-if="activeTab === 'grant'" class="grant-tab-container">

      <!-- Card 1: Permission Management Header -->
      <div class="form-content-card">
        <div class="card-header-with-icon">
          <h2 class="card-section-title">Permission Management</h2>
          <Info :size="16" class="text-slate-400" />
        </div>
        <p class="card-subtitle-desc">
          Grant permissions directly to a user. You can assign the same permission multiple times with different effective date ranges. After granting permissions, you can review, edit, or revoke them from the <strong>Assigned Permissions tab</strong> without changing the user's assigned role.
        </p>

        <div class="card-divider"></div>

        <!-- Validity Period -->
        <div class="validity-period-block">
          <p class="validity-label">Validity Period</p>
          <div class="grid-col-2">
            <div class="form-field-group">
              <label class="input-field-label">Start Date <span class="required-star">*</span></label>
              <div class="dob-input-wrap">
                <Calendar :size="16" class="dob-calendar-icon" />
                <input v-model="grantForm.startDate" type="text"  class="dob-text-input" />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>
            <div class="form-field-group">
              <label class="input-field-label">End Date</label>
              <div class="dob-input-wrap">
                <Calendar :size="16" class="dob-calendar-icon" />
                <input v-model="grantForm.endDate" type="text"  class="dob-text-input" />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Card 2: Entity Specific -->
      <div class="form-content-card">
        <h2 class="card-section-title">Entity Specific</h2>
        <div class="grid-col-2">
          <div class="form-field-group">
            <label class="input-field-label">Entity Type</label>
            <div class="select-wrapper">
              <select v-model="grantForm.entityType" class="form-select-input">
                <option value="">Select Type</option>
                <option value="Business Group">Business Group</option>
                <option value="Organization">Organization</option>
                <option value="Branch">Branch</option>
                <option value="Shop">Shop</option>
              </select>
              <ChevronDown :size="14" class="select-chevron-icon" />
            </div>
          </div>
          <div class="form-field-group">
            <label class="input-field-label">-</label>
            <div class="select-wrapper">
              <select v-model="grantForm.entityId" class="form-select-input">
                <option value="">Select Entity</option>
                <option value="Haleta Enterprise">Haleta Enterprise</option>
                <option value="Bole Branch">Bole Branch</option>
              </select>
              <ChevronDown :size="14" class="select-chevron-icon" />
            </div>
          </div>
        </div>
        <div class="descendant-box" @click="grantForm.includeDescendants = !grantForm.includeDescendants">
          <span>Include descendant</span>
          <ChevronRight :size="14" class="text-slate-400" />
        </div>
      </div>

      <!-- Card 3: Two-panel Permission Picker -->
      <div class="perm-picker-row">

        <!-- LEFT: Permission Group Tree -->
        <div class="perm-group-panel">
          <div class="perm-panel-header">
            <span class="perm-panel-title">Permission Group</span>
            <button class="perm-filter-btn">
              <List :size="14" />
              Filter
            </button>
          </div>

          <!-- Group Search -->
          <div class="perm-search-wrap">
            <HelpCircle :size="14" class="perm-search-icon" />
            <input
              v-model="grantGroupSearch"
              type="text"
              
              class="perm-search-input"
            />
          </div>

          <!-- Tree View -->
          <div class="perm-tree">
            <template v-for="node in permissionGroups" :key="node.id">
              <!-- Root folder node -->
              <div
                :class="['perm-tree-row perm-tree-root', selectedPermGroup === node.id ? 'perm-tree-row--selected' : '']"
                @click="node.children ? toggleExpand(node.id) : selectedPermGroup = node.id"
              >
                <ChevronRight
                  v-if="node.children"
                  :size="12"
                  :class="['perm-expand-icon', expandedGroups.has(node.id) ? 'rotated' : '']"
                />
                <div class="perm-folder-icon" v-if="node.children">
                  <svg width="14" height="14" fill="none" viewBox="0 0 24 24">
                    <path d="M3 7a2 2 0 012-2h4l2 2h8a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V7z" stroke="#64748b" stroke-width="1.5" stroke-linejoin="round"/>
                  </svg>
                </div>
                <span class="perm-tree-label">{{ node.label }}</span>
              </div>

              <!-- Children (L2) -->
              <template v-if="node.children && expandedGroups.has(node.id)">
                <template v-for="child in node.children" :key="child.id">
                  <div
                    :class="['perm-tree-row perm-tree-l2', selectedPermGroup === child.id ? 'perm-tree-row--selected' : '']"
                    @click="child.children ? toggleExpand(child.id) : selectedPermGroup = child.id"
                  >
                    <ChevronRight
                      v-if="child.children"
                      :size="12"
                      :class="['perm-expand-icon', expandedGroups.has(child.id) ? 'rotated' : '']"
                    />
                    <div class="perm-folder-icon" v-if="child.children">
                      <svg width="13" height="13" fill="none" viewBox="0 0 24 24">
                        <path d="M3 7a2 2 0 012-2h4l2 2h8a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V7z" stroke="#64748b" stroke-width="1.5" stroke-linejoin="round"/>
                      </svg>
                    </div>
                    <span class="perm-tree-label">{{ child.label }}</span>
                  </div>

                  <!-- Children (L3) -->
                  <template v-if="child.children && expandedGroups.has(child.id)">
                    <div
                      v-for="leaf in child.children"
                      :key="leaf.id"
                      :class="['perm-tree-row perm-tree-l3', selectedPermGroup === leaf.id ? 'perm-tree-row--selected' : '']"
                      @click="selectedPermGroup = leaf.id"
                    >
                      <div class="perm-leaf-icon">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
                          <circle cx="12" cy="12" r="5" stroke="#94a3b8" stroke-width="2"/>
                        </svg>
                      </div>
                      <span class="perm-tree-label">{{ leaf.label }}</span>
                    </div>
                  </template>
                </template>
              </template>
            </template>
          </div>
        </div>

        <!-- RIGHT: Permissions List -->
        <div class="perm-list-panel">
          <div class="perm-panel-header">
            <span class="perm-panel-title">{{ selectedGroupLabel }}</span>
            <span class="perm-count-badge">20 Total Permissions</span>
          </div>

          <!-- Permission Search -->
          <div class="perm-search-wrap">
            <HelpCircle :size="14" class="perm-search-icon" />
            <input
              v-model="grantPermSearch"
              type="text"
              
              class="perm-search-input"
            />
          </div>

          <!-- Permission Table -->
          <div class="perm-table-wrap">
            <!-- Header Row -->
            <div class="perm-list-header">
              <div class="perm-header-left">
                <input
                  type="checkbox"
                  class="perm-checkbox"
                  v-model="grantHeaderChecked"
                  @change="permissionItems.forEach(p => p.enabled = grantHeaderChecked)"
                />
                <span class="perm-col-label">Permission Name</span>
              </div>
              <div class="perm-access-label">
                <span>Access</span>
                <HelpCircle :size="13" class="text-slate-400" />
              </div>
            </div>

            <!-- Permission Rows -->
            <div
              v-for="perm in filteredPermItems"
              :key="perm.id"
              class="perm-list-row"
            >
              <div class="perm-row-left">
                <input type="checkbox" class="perm-checkbox" />
                <span class="perm-row-name">{{ perm.name }}</span>
              </div>
              <div class="perm-toggle-wrap">
                <button
                  :class="['perm-toggle', perm.enabled ? 'toggle-on' : 'toggle-off']"
                  @click="perm.enabled = !perm.enabled"
                  :title="perm.enabled ? 'Disable' : 'Enable'"
                >
                  <span class="toggle-thumb"></span>
                </button>
              </div>
            </div>
          </div>

          <!-- Pagination Footer -->
          <div class="perm-pagination-bar">
            <span class="perm-pagination-info">Showing 1 to 2 entries&nbsp;&nbsp;Per Page:</span>
            <div class="per-page-select-wrap">
              <select class="per-page-select">
                <option>20</option>
                <option>50</option>
                <option>100</option>
              </select>
              <ChevronDown :size="11" class="per-page-chevron" />
            </div>
            <div class="perm-page-nav">
              <button class="page-nav-btn">&larr; Previous</button>
              <button class="page-nav-btn page-active">1</button>
              <button class="page-nav-btn">2</button>
              <span class="page-ellipsis">...</span>
              <button class="page-nav-btn">8</button>
              <button class="page-nav-btn">Next &rarr;</button>
            </div>
          </div>
        </div>

      </div>
    </div>

    <!-- ── TAB 5: GRANTED PERMISSIONS (Permission Access Matrix) ───────── -->
    <div v-else-if="activeTab === 'granted'" class="granted-tab-container">
      <!-- Card 1: Header & Secondary Underline Tabs -->
      <div class="form-content-card">
        <div class="card-header-block">
          <h2 class="card-section-title">Permission Access Matrix</h2>
          <p class="card-subtitle-desc">
            View all permissions assigned to this user through roles or direct grants. Select an entity to review or override permissions for that specific entity without affecting access elsewhere.
          </p>
        </div>

        <!-- Secondary Underline Tabs Component -->
        <div class="secondary-tabs-wrapper">
          <UnderlineTabs v-model="activeSecondaryTab" :tabs="secondaryPermissionTabs" />
        </div>
      </div>

      <!-- Card 2: Main Table & Toolbar -->
      <div class="form-content-card no-padding-table-card">
        <!-- Toolbar -->
        <div class="matrix-table-toolbar">
          <div class="toolbar-search-box">
            <Search :size="15" class="search-icon-muted" />
            <input
              v-model="grantedSearchQuery"
              type="text"
              
              class="toolbar-search-input"
            />
          </div>

          <button class="toolbar-filter-btn">
            <Filter :size="14" />
            <span>Filter</span>
          </button>

          <div class="toolbar-right-icons">
            <button class="icon-square-btn" title="Refresh">
              <RotateCw :size="15" />
            </button>
            <button class="icon-square-btn" title="Columns">
              <Columns :size="15" />
            </button>
            <button class="icon-square-btn" title="Fullscreen">
              <Maximize2 :size="15" />
            </button>
          </div>
        </div>

        <!-- Table View 1: Role Based Permissions -->
        <div v-if="activeSecondaryTab === 'role_based'" class="perm-matrix-table-wrap">
          <table class="matrix-table">
            <thead>
              <tr>
                <th style="width: 60px;">No.</th>
                <th>Permission</th>
                <th>Roles</th>
                <th>Entity</th>
                <th style="width: 80px; text-align: right;">Action</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in roleBasedPermissionsList" :key="item.id">
                <td class="col-num">{{ item.id }}</td>
                <td class="col-perm-title">{{ item.permission }}</td>
                <td class="col-roles-text">{{ item.roles }}</td>
                <td class="col-entity-text">{{ item.entity }}</td>
                <td class="col-action-right relative">
                  <button class="icon-menu-btn-sm" @click.stop="togglePermMenu(item.id)" title="More options">
                    <MoreVertical :size="16" />
                  </button>

                  <!-- Role Based Permission Action Menu -->
                  <div v-if="activePermMenuId === item.id" class="dropdown-action-menu">
                    <button class="dropdown-item-btn text-amber-600" @click="openRevokeModal(item)">
                      <Slash :size="14" />
                      <span>Revoke Permission</span>
                    </button>
                    <button class="dropdown-item-btn" @click="activePermMenuId = null">
                      <Power :size="14" />
                      <span>Deactivate</span>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Table View 2: Direct Grants / Temporal -->
        <div v-else-if="activeSecondaryTab === 'direct_grants'" class="perm-matrix-table-wrap">
          <table class="matrix-table">
            <thead>
              <tr>
                <th style="width: 60px;">No.</th>
                <th>Permission</th>
                <th>Entity</th>
                <th>Validity Period</th>
                <th>Status</th>
                <th style="width: 80px; text-align: right;">Action</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in directGrantsList" :key="item.id">
                <td class="col-num">{{ item.id }}</td>
                <td class="col-perm-title">{{ item.permission }}</td>
                <td class="col-entity-text">{{ item.entity }}</td>
                <td class="col-roles-text">{{ item.validity }}</td>
                <td>
                  <span :class="['status-pill', item.status === 'Granted' ? 'pill-active' : item.status === 'Scheduled' ? 'pill-scheduled' : 'pill-inactive']">
                    {{ item.status }}
                  </span>
                </td>
                <td class="col-action-right relative">
                  <button class="icon-menu-btn-sm" @click.stop="togglePermMenu(item.id + 200)" title="More options">
                    <MoreVertical :size="16" />
                  </button>

                  <!-- Direct Grants Action Menu -->
                  <div v-if="activePermMenuId === (item.id + 200)" class="dropdown-action-menu">
                    <button class="dropdown-item-btn" @click="openEditDirectGrantModal(item)">
                      <Edit :size="14" />
                      <span>Edit Dates</span>
                    </button>
                    <button class="dropdown-item-btn" @click="toggleDirectGrantStatus(item)">
                      <Power :size="14" />
                      <span>{{ item.status === 'Inactive' ? 'Activate' : 'Deactivate' }}</span>
                    </button>
                    <button class="dropdown-item-btn text-rose-600" @click="directGrantsList = directGrantsList.filter(d => d.id !== item.id); activePermMenuId = null;">
                      <Trash2 :size="14" />
                      <span>Remove Direct Grant</span>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Table View 3: Revoked Role Permissions -->
        <div v-else-if="activeSecondaryTab === 'revoked'" class="perm-matrix-table-wrap">
          <table class="matrix-table">
            <thead>
              <tr>
                <th style="width: 60px;">No.</th>
                <th>Permission</th>
                <th>Entity</th>
                <th>Period</th>
                <th>Status</th>
                <th style="width: 80px; text-align: right;">Action</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in revokedPermissionsList" :key="item.id">
                <td class="col-num">{{ item.id }}</td>
                <td class="col-perm-title">{{ item.permission }}</td>
                <td class="col-entity-text">{{ item.entity }}</td>
                <td class="col-roles-text">{{ item.period }}</td>
                <td>
                  <span :class="['status-pill', item.status === 'Revoked' ? 'pill-revoked' : item.status === 'Scheduled' ? 'pill-scheduled' : 'pill-inactive']">
                    {{ item.status }}
                  </span>
                </td>
                <td class="col-action-right relative">
                  <button class="icon-menu-btn-sm" @click.stop="togglePermMenu(item.id + 100)" title="More options">
                    <MoreVertical :size="16" />
                  </button>

                  <!-- Revoked Permission Action Menu Popover -->
                  <div v-if="activePermMenuId === (item.id + 100)" class="dropdown-action-menu">
                    <button class="dropdown-item-btn" @click="openEditRevokeModal(item)">
                      <Edit :size="14" />
                      <span>Edit Dates</span>
                    </button>
                    <button class="dropdown-item-btn text-blue-600" @click="restoreRevokedPermission(item)">
                      <RotateCcw :size="14" />
                      <span>Restore Permission</span>
                    </button>
                    <button class="dropdown-item-btn" @click="toggleRevokedStatus(item)">
                      <Power :size="14" />
                      <span>{{ item.status === 'Inactive' ? 'Activate' : 'Deactivate' }}</span>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Footer Pagination -->
        <div class="matrix-table-footer">
          <span class="footer-entries-info">Showing 1 to 2 of 2 entries</span>

          <div class="per-page-select-wrap">
            <span class="text-xs text-slate-500">Per Page:</span>
            <select class="per-page-select">
              <option value="10">10</option>
              <option value="20">20</option>
              <option value="50">50</option>
            </select>
            <ChevronDown :size="11" class="per-page-chevron" />
          </div>

          <div class="perm-page-nav">
            <button class="page-nav-btn">&larr; Previous</button>
            <button class="page-nav-btn page-active">1</button>
            <button class="page-nav-btn">2</button>
            <span class="page-ellipsis">...</span>
            <button class="page-nav-btn">9</button>
            <button class="page-nav-btn">10</button>
            <button class="page-nav-btn">Next &rarr;</button>
          </div>
        </div>
      </div>
    </div>

    <!-- ── EDIT ROLE MODAL ──────────────────────────────────────────────── -->
    <div v-if="showEditRoleModal && editingRole" class="modal-backdrop" @click.self="showEditRoleModal = false">
      <div class="modal-dialog-card">
        <div class="modal-header">
          <h3 class="modal-title font-bold text-slate-900">Edit Assigned Role</h3>
          <button class="icon-menu-btn-sm" @click="showEditRoleModal = false"><X :size="16" /></button>
        </div>

        <div class="modal-body-content">
          <div class="form-field-group mb-4">
            <label class="input-field-label">Role Name</label>
            <input type="text" :value="editingRole.roleName" disabled class="form-text-input bg-slate-50 cursor-not-allowed" />
          </div>

          <div class="form-field-group mb-4">
            <label class="input-field-label">Assigned Entity</label>
            <input type="text" :value="editingRole.entityScope" disabled class="form-text-input bg-slate-50 cursor-not-allowed" />
          </div>

          <div class="grid-col-2">
            <div class="form-field-group">
              <label class="input-field-label">Start Date *</label>
              <div class="dob-input-wrap">
                <Calendar :size="16" class="dob-calendar-icon" />
                <input v-model="editingRole.startDate" type="text" class="dob-text-input" />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>
            <div class="form-field-group">
              <label class="input-field-label">End Date</label>
              <div class="dob-input-wrap">
                <Calendar :size="16" class="dob-calendar-icon" />
                <input v-model="editingRole.endDate" type="text" class="dob-text-input" />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn-clear-form" @click="showEditRoleModal = false">Cancel</button>
          <button class="btn-save-primary" @click="saveEditedRole">Save Changes</button>
        </div>
      </div>
    </div>

    <!-- ── DEACTIVATE / DELETE ROLE MULTI-SELECT MODAL ───────────────────── -->
    <div v-if="showDeactivateDeleteRoleModal" class="modal-backdrop" @click.self="showDeactivateDeleteRoleModal = false">
      <div class="modal-dialog-card max-w-lg">
        <div class="modal-header">
          <div>
            <h3 class="modal-title font-bold text-slate-900">
              {{ roleManageState.actionType === 'deactivate' ? 'Deactivate Role Assignment' : 'Delete Role Assignment' }}
            </h3>
            <p class="text-xs text-slate-500 mt-0.5">Role: <span class="font-semibold text-slate-800">{{ roleManageState.roleName }}</span></p>
          </div>
          <button class="icon-menu-btn-sm" @click="showDeactivateDeleteRoleModal = false"><X :size="16" /></button>
        </div>

        <div class="modal-body-content space-y-4">
          <!-- Action Switcher Tabs -->
          <div class="flex items-center p-1 bg-slate-100 rounded-lg border border-slate-200">
            <button 
              :class="['flex-1 py-1.5 text-xs font-semibold rounded-md transition-all', roleManageState.actionType === 'deactivate' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500 hover:text-slate-800']"
              @click="roleManageState.actionType = 'deactivate'"
            >
              Deactivate Access
            </button>
            <button 
              :class="['flex-1 py-1.5 text-xs font-semibold rounded-md transition-all', roleManageState.actionType === 'delete' ? 'bg-white text-rose-600 shadow-sm' : 'text-slate-500 hover:text-slate-800']"
              @click="roleManageState.actionType = 'delete'"
            >
              Delete Role
            </button>
          </div>

          <!-- Notice banner -->
          <p class="text-xs text-slate-600 bg-amber-50/80 border border-amber-200/80 text-amber-900 p-3 rounded-lg flex items-start gap-2">
            <AlertTriangle :size="16" class="text-amber-600 shrink-0 mt-0.5" />
            <span>
              <template v-if="roleManageState.actionType === 'deactivate'">
                Select which parent entities to <strong>deactivate</strong> this role for. Deactivating removes active access privileges for selected entities without deleting the role.
              </template>
              <template v-else>
                Select which parent entities to <strong>delete</strong> this role from. Deleting permanently removes the role assignment from the selected entity scopes.
              </template>
            </span>
          </p>

          <!-- Multi-Select List of Parent Entities -->
          <div class="entity-multiselect-box border border-slate-200 rounded-lg p-3 bg-slate-50/50">
            <div class="flex items-center justify-between pb-2 mb-2 border-b border-slate-200">
              <label class="flex items-center gap-2 cursor-pointer text-xs font-bold text-slate-800">
                <input 
                  type="checkbox" 
                  :checked="isAllEntitiesSelected" 
                  @change="(e: any) => toggleAllEntitiesSelection(e.target.checked)"
                  class="rounded border-slate-300 text-blue-600 focus:ring-blue-500" 
                />
                <span>Select All Assigned Entities</span>
              </label>
              <span class="text-[11px] text-slate-400 font-mono">
                {{ roleManageState.entities.filter(e => e.selected).length }} of {{ roleManageState.entities.length }} selected
              </span>
            </div>

            <div class="space-y-2 max-h-48 overflow-y-auto pr-1">
              <div 
                v-for="ent in roleManageState.entities" 
                :key="ent.entityName"
                class="flex items-center justify-between p-2 rounded-md hover:bg-white bg-slate-100/60 border border-slate-200/60 transition-colors"
              >
                <label class="flex items-center gap-2.5 cursor-pointer text-xs font-medium text-slate-700 flex-1">
                  <input 
                    type="checkbox" 
                    v-model="ent.selected" 
                    class="rounded border-slate-300 text-blue-600 focus:ring-blue-500" 
                  />
                  <span>{{ ent.entityName }}</span>
                </label>
                <span :class="['text-[10.5px] font-semibold px-2 py-0.5 rounded', roleManageState.actionType === 'deactivate' ? 'bg-amber-100 text-amber-800' : 'bg-rose-100 text-rose-800']">
                  Target for {{ roleManageState.actionType }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn-clear-form" @click="showDeactivateDeleteRoleModal = false">Cancel</button>
          <button 
            :class="roleManageState.actionType === 'deactivate' ? 'btn-save-primary bg-amber-600 hover:bg-amber-700 text-white' : 'btn-save-primary bg-rose-600 hover:bg-rose-700 text-white'"
            :disabled="roleManageState.entities.filter(e => e.selected).length === 0"
            @click="applyDeactivateDeleteRole"
          >
            {{ roleManageState.actionType === 'deactivate' ? 'Deactivate Selected Entities' : 'Delete Selected Entities' }}
          </button>
        </div>
      </div>
    </div>

    <!-- ── REVOKE PERMISSION MODAL ──────────────────────────────────────── -->
    <div v-if="showRevokeModal && revokingPerm" class="modal-backdrop" @click.self="showRevokeModal = false">
      <div class="modal-dialog-card">
        <div class="modal-header">
          <h3 class="modal-title font-bold text-slate-900">Revoke Permission: {{ revokingPerm.permName }}</h3>
          <button class="icon-menu-btn-sm" @click="showRevokeModal = false"><X :size="16" /></button>
        </div>

        <div class="modal-body-content">
          <p class="text-xs text-slate-500 mb-4">
            Select the specific entity from which you want to revoke this permission. The user's role assignment will remain active, but this permission will be removed for the selected entity scope.
          </p>

          <div class="form-field-group mb-4">
            <label class="input-field-label">Select Entity to Revoke From *</label>
            <div class="select-wrapper">
              <select v-model="revokingPerm.selectedEntity" class="form-select-input">
                <option v-for="ent in revokingPerm.availableEntities" :key="ent" :value="ent">{{ ent }}</option>
              </select>
              <ChevronDown :size="14" class="select-chevron-icon" />
            </div>
          </div>

          <div class="grid-col-2">
            <div class="form-field-group">
              <label class="input-field-label">Start Date *</label>
              <div class="dob-input-wrap">
                <Calendar :size="16" class="dob-calendar-icon" />
                <input v-model="revokingPerm.startDate" type="text" class="dob-text-input" />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>
            <div class="form-field-group">
              <label class="input-field-label">End Date</label>
              <div class="dob-input-wrap">
                <Calendar :size="16" class="dob-calendar-icon" />
                <input v-model="revokingPerm.endDate" type="text" class="dob-text-input" />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn-clear-form" @click="showRevokeModal = false">Cancel</button>
          <button class="btn-danger-primary" @click="confirmRevokePermission">Confirm Revocation</button>
        </div>
      </div>
    </div>

    <!-- ── EDIT REVOCABLE DATES MODAL ────────────────────────────────────── -->
    <div v-if="showEditRevokeModal && editingRevoke" class="modal-backdrop" @click.self="showEditRevokeModal = false">
      <div class="modal-dialog-card">
        <div class="modal-header">
          <h3 class="modal-title font-bold text-slate-900">Edit Revocation Dates: {{ editingRevoke.permission }}</h3>
          <button class="icon-menu-btn-sm" @click="showEditRevokeModal = false"><X :size="16" /></button>
        </div>

        <div class="modal-body-content">
          <div class="form-field-group mb-4">
            <label class="input-field-label">Entity Scope</label>
            <input type="text" :value="editingRevoke.entity" disabled class="form-text-input bg-slate-50 cursor-not-allowed" />
          </div>

          <div class="grid-col-2">
            <div class="form-field-group">
              <label class="input-field-label">Start Date *</label>
              <div class="dob-input-wrap">
                <Calendar :size="16" class="dob-calendar-icon" />
                <input v-model="editingRevoke.startDate" type="text" class="dob-text-input" />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>
            <div class="form-field-group">
              <label class="input-field-label">End Date</label>
              <div class="dob-input-wrap">
                <Calendar :size="16" class="dob-calendar-icon" />
                <input v-model="editingRevoke.endDate" type="text" class="dob-text-input" />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn-clear-form" @click="showEditRevokeModal = false">Cancel</button>
          <button class="btn-save-primary" @click="saveEditedRevoke">Save Changes</button>
        </div>
      </div>
    </div>

    <!-- ── EDIT DIRECT GRANT DATES MODAL ─────────────────────────────────── -->
    <div v-if="showEditDirectGrantModal && editingDirectGrant" class="modal-backdrop" @click.self="showEditDirectGrantModal = false">
      <div class="modal-dialog-card">
        <div class="modal-header">
          <h3 class="modal-title font-bold text-slate-900">Edit Direct Grant Dates: {{ editingDirectGrant.permission }}</h3>
          <button class="icon-menu-btn-sm" @click="showEditDirectGrantModal = false"><X :size="16" /></button>
        </div>

        <div class="modal-body-content">
          <div class="form-field-group mb-4">
            <label class="input-field-label">Entity Scope</label>
            <input type="text" :value="editingDirectGrant.entity" disabled class="form-text-input bg-slate-50 cursor-not-allowed" />
          </div>

          <div class="grid-col-2">
            <div class="form-field-group">
              <label class="input-field-label">Start Date *</label>
              <div class="dob-input-wrap">
                <Calendar :size="16" class="dob-calendar-icon" />
                <input v-model="editingDirectGrant.startDate" type="text" class="dob-text-input" />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>
            <div class="form-field-group">
              <label class="input-field-label">End Date</label>
              <div class="dob-input-wrap">
                <Calendar :size="16" class="dob-calendar-icon" />
                <input v-model="editingDirectGrant.endDate" type="text" class="dob-text-input" />
                <span class="gc-pill-tag">GC</span>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn-clear-form" @click="showEditDirectGrantModal = false">Cancel</button>
          <button class="btn-save-primary" @click="saveEditedDirectGrant">Save Changes</button>
        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>
.user-detail-page {
  animation: fadeIn 0.25s ease-out;
  display: flex;
  flex-direction: column;
  gap: 16px;
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  color: #0f172a;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(6px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Header Trail & Actions Row */
.header-action-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.breadcrumb-trail {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #64748b;
}

.breadcrumb-home-link, .breadcrumb-link {
  color: #64748b;
  text-decoration: none;
  display: flex;
  align-items: center;
  transition: color 0.15s;
}
.breadcrumb-home-link:hover, .breadcrumb-link:hover { color: #0f172a; }
.breadcrumb-arrow { color: #94a3b8; }
.breadcrumb-active { color: #1e293b; font-weight: 500; }



.header-action-buttons {
  display: flex;
  align-items: center;
  gap: 10px;
}

.btn-demo-toggle {
  height: 38px;
  padding: 0 14px;
  background-color: #f1f5f9;
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  font-size: 12.5px;
  font-weight: 600;
  color: #475569;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-demo-toggle:hover {
  background-color: #e2e8f0;
  color: #0f172a;
}

.icon-menu-btn {
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
  transition: all 0.15s;
}
.icon-menu-btn:hover { background: #f8fafc; color: #0f172a; }

.btn-clear-form {
  height: 38px;
  padding: 0 16px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 500;
  color: #334155;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  transition: all 0.15s;
}
.btn-clear-form:hover { background: #f8fafc; border-color: #cbd5e1; color: #0f172a; }

.btn-save-primary {
  height: 38px;
  padding: 0 24px;
  background-color: #0B529C;
  color: #ffffff;
  border: none;
  border-radius: 10px;
  font-size: 13.5px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
  box-shadow: 0 2px 4px rgba(11, 82, 156, 0.2);
}
.btn-save-primary:hover {
  background-color: #09427d;
  box-shadow: 0 4px 8px rgba(11, 82, 156, 0.3);
  transform: translateY(-1px);
}

/* Tab Header Container */
.tab-header-container {
  display: flex;
  align-items: center;
}

/* Form Content Card */
.form-content-card {
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 28px 32px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.card-divider {
  height: 1px;
  background-color: #f1f5f9;
  width: 100%;
}

/* Section 1: Photo Upload Section */
.photo-upload-section {
  display: flex;
  align-items: center;
  gap: 24px;
}

.avatar-box-wrapper {
  position: relative;
  width: 100px;
  height: 100px;
  flex-shrink: 0;
}

.user-photo-img {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #ffffff;
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.08);
}

.empty-photo-placeholder {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.02);
}

.empty-photo-label {
  font-size: 11px;
  font-weight: 500;
  color: #94a3b8;
}

.upload-controls-stack {
  display: flex;
  flex-direction: column;
  gap: 8px;
  align-items: flex-start;
}

.btn-upload-new {
  height: 38px;
  padding: 0 18px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  color: #334155;
  cursor: pointer;
  transition: all 0.15s ease;
}
.btn-upload-new:hover {
  background: #f8fafc;
  border-color: #cbd5e1;
  color: #0f172a;
}

.upload-help-text {
  font-size: 12.5px;
  color: #64748b;
  margin: 0;
  line-height: 1.5;
}

/* Section 2: National ID Section */
.national-id-section {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.input-field-label {
  font-size: 13px;
  font-weight: 500;
  color: #475569;
}

.required-star {
  color: #ef4444;
}

.nid-input-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.nid-input-box {
  position: relative;
  width: 100%;
  max-width: 360px;
}

.nid-text-input {
  width: 100%;
  height: 42px;
  padding: 0 38px 0 14px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13.5px;
  color: #0f172a;
  outline: none;
  transition: border 0.15s ease;
}
.nid-text-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.12);
}

.nid-check-icon {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
}

.btn-verify-id {
  height: 42px;
  padding: 0 20px;
  border-radius: 10px;
  font-size: 13.5px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-verified-active {
  background-color: #eff6ff;
  color: #0284c7;
  border: 1px solid #bae6fd;
}
.btn-verified-active:hover {
  background-color: #e0f2fe;
}

.btn-verify-disabled {
  background-color: #ffffff;
  color: #cbd5e1;
  border: 1px solid #e2e8f0;
}

.nid-success-text {
  font-size: 13px;
  font-weight: 500;
  color: #15803d;
  margin: 2px 0 0 0;
}

/* Section 3: Personal Information */
.personal-info-section {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.section-group-title {
  font-size: 13.5px;
  font-weight: 500;
  color: #64748b;
  margin: 0 0 4px 0;
}

.grid-col-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

.grid-col-2 {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.form-field-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.input-field-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
  display: block;
}

.form-text-input {
  width: 100%;
  height: 42px;
  padding: 0 14px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13.5px;
  color: #0f172a;
  outline: none;
  transition: border 0.15s ease;
}
.form-text-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.12);
}

.phone-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
  height: 42px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background: #ffffff;
  overflow: hidden;
}

.phone-country-select {
  height: 100%;
  padding: 0 20px 0 12px;
  border: none;
  background: transparent;
  font-size: 13px;
  font-weight: 500;
  color: #334155;
  outline: none;
  cursor: pointer;
  appearance: none;
}

.country-select-arrow {
  position: absolute;
  left: 36px;
  pointer-events: none;
  color: #64748b;
}

.phone-text-input {
  flex: 1;
  height: 100%;
  border: none;
  padding: 0 12px;
  font-size: 13.5px;
  color: #0f172a;
  outline: none;
  border-left: 1px solid #e2e8f0;
}

.select-wrapper {
  position: relative;
  width: 100%;
}

.form-select-input {
  width: 100%;
  height: 42px;
  padding: 0 36px 0 14px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13.5px;
  color: #0f172a;
  outline: none;
  appearance: none;
  cursor: pointer;
}

.select-chevron-icon {
  position: absolute;
  right: 14px;
  top: 50%;
  transform: translateY(-50%);
  color: #64748b;
  pointer-events: none;
}

.dob-input-wrap {
  position: relative;
  display: flex;
  align-items: center;
  width: 100%;
  height: 42px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background: #ffffff;
  padding: 0 12px;
}

.dob-calendar-icon {
  color: #64748b;
  margin-right: 10px;
  flex-shrink: 0;
}

.dob-text-input {
  flex: 1;
  border: none;
  height: 100%;
  font-size: 13.5px;
  color: #0f172a;
  outline: none;
}

.gc-pill-tag {
  font-size: 11px;
  font-weight: 700;
  color: #64748b;
  background-color: #f1f5f9;
  padding: 3px 8px;
  border-radius: 6px;
}

/* Section 4: Biography Rich Editor */
.biography-section {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.rich-editor-container {
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
  background: #ffffff;
}

.editor-toolbar {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  background-color: #fafafa;
  border-bottom: 1px solid #e2e8f0;
  gap: 8px;
  flex-wrap: wrap;
}

.toolbar-dropdown {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #475569;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 6px;
  transition: background 0.15s;
}
.toolbar-dropdown:hover { background: #f1f5f9; }

.toolbar-divider {
  width: 1px;
  height: 18px;
  background-color: #e2e8f0;
}

.toolbar-icon-group {
  display: flex;
  align-items: center;
  gap: 2px;
}

.editor-icon-btn {
  background: none;
  border: none;
  padding: 4px 6px;
  border-radius: 4px;
  color: #475569;
  font-size: 12.5px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 2px;
  transition: background 0.15s;
}
.editor-icon-btn:hover { background: #e2e8f0; color: #0f172a; }

.editor-textarea {
  width: 100%;
  padding: 14px 16px;
  border: none;
  outline: none;
  font-size: 13.5px;
  color: #334155;
  line-height: 1.6;
  resize: vertical;
  font-family: inherit;
}

.editor-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 16px;
  border-top: 1px solid #f1f5f9;
  background-color: #ffffff;
}

.char-count-pill {
  font-size: 11.5px;
  color: #64748b;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 3px 10px;
  border-radius: 9999px;
}

.editor-resize-handle {
  font-size: 12px;
  color: #cbd5e1;
  cursor: se-resize;
  user-select: none;
}

/* ── TAB 2: ASSIGN ROLE STYLING ── */
.roles-tab-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.card-header-with-icon, .card-header-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.card-section-title {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
  margin: 0;
}

.card-subtitle-desc {
  font-size: 13px;
  color: #64748b;
  line-height: 1.55;
  margin: 0;
}

.role-form-block {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.descendant-box {
  background-color: #fafafa;
  border: 1px solid #f1f5f9;
  border-radius: 12px;
  padding: 14px 18px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 13.5px;
  color: #475569;
  cursor: pointer;
  transition: all 0.15s ease;
}
.descendant-box:hover {
  background-color: #f4f4f5;
  color: #0f172a;
}

/* ── TAB 3: ASSIGNED ROLE STYLING ── */
.entity-filter-pill-bar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px;
  background-color: #f4f4f5;
  border: 1px solid #e4e4e7;
  border-radius: 30px;
  width: max-content;
  max-width: 100%;
}

.entity-filter-pill {
  padding: 7px 18px;
  border-radius: 20px;
  border: none;
  background: transparent;
  font-size: 13px;
  font-weight: 500;
  color: #64748b;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.15s ease;
}

.entity-filter-pill:hover {
  color: #0f172a;
}

.entity-filter-pill.pill-active {
  background-color: #ffffff !important;
  color: #0f172a !important;
  font-weight: 600 !important;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.04);
}

.assigned-role-rows-stack {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.assigned-role-card-row {
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 16px 20px;
  background-color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  transition: all 0.15s ease;
}

.assigned-role-card-row:hover {
  border-color: #cbd5e1;
  box-shadow: 0 2px 6px rgba(0,0,0,0.02);
}

.role-name-cell {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
  min-width: 160px;
}

.role-entities-cell {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  flex: 1;
}

.entity-chip-tag {
  font-size: 12px;
  font-weight: 500;
  color: #334155;
  background-color: #f1f5f9;
  border: 1px solid #e2e8f0;
  padding: 3px 10px;
  border-radius: 6px;
  display: inline-flex;
  align-items: center;
  white-space: nowrap;
}

.count-pill-tag {
  font-size: 11.5px;
  font-weight: 600;
  color: #475569;
  background-color: #f1f5f9;
  padding: 3px 10px;
  border-radius: 12px;
}

.role-date-cell {
  font-size: 13px;
  color: #64748b;
  font-family: monospace, sans-serif;
  white-space: nowrap;
}

.icon-menu-btn-sm {
  background: none;
  border: none;
  padding: 6px;
  border-radius: 6px;
  color: #94a3b8;
  cursor: pointer;
  transition: all 0.15s ease;
}
.icon-menu-btn-sm:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.empty-assigned-roles-state {
  text-align: center;
  padding: 40px 24px;
}

/* Secondary Underline Tabs Wrapper */
.secondary-tabs-wrapper {
  margin-top: 4px;
  margin-bottom: 8px;
}

.perm-table-container {
  overflow-x: auto;
}

.code-tag {
  background-color: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
  font-family: monospace;
  font-size: 11.5px;
  color: #0f172a;
}

.role-chip {
  display: inline-flex;
  padding: 3px 10px;
  background-color: #eff6ff;
  color: #1d4ed8;
  border-radius: 12px;
  font-size: 11.5px;
  font-weight: 600;
}

.status-pill {
  display: inline-flex;
  padding: 3px 12px;
  border-radius: 9999px;
  font-size: 12px;
  font-weight: 600;
}

.pill-active {
  background-color: #dcfce7;
  color: #15803d;
}

.pill-scheduled {
  background-color: #fffbeb;
  color: #b45309;
}

.pill-revoked {
  background-color: #fef2f2;
  color: #dc2626;
}

.pill-inactive {
  background-color: #f1f5f9;
  color: #64748b;
}

.btn-danger-primary {
  height: 38px;
  padding: 0 20px;
  background-color: #dc2626;
  color: #ffffff;
  border: none;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
  box-shadow: 0 2px 4px rgba(220, 38, 38, 0.2);
}

.btn-danger-primary:hover {
  background-color: #b91c1c;
}

/* ── GRANT PERMISSIONS TAB ───────────────────────────────────────────────── */
.grant-tab-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.validity-period-block {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.validity-label {
  font-size: 13px;
  font-weight: 500;
  color: #475569;
  margin: 0;
}

/* Two-panel picker row */
.perm-picker-row {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 16px;
  align-items: start;
}

/* Shared panel card style */
.perm-group-panel,
.perm-list-panel {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0,0,0,0.02);
}

.perm-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #f1f5f9;
}

.perm-panel-title {
  font-size: 14.5px;
  font-weight: 700;
  color: #0f172a;
}

.perm-filter-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border: 1px solid #e2e8f0;
  border-radius: 9px;
  background: #ffffff;
  font-size: 12.5px;
  font-weight: 500;
  color: #475569;
  cursor: pointer;
  transition: all 0.15s;
}
.perm-filter-btn:hover { background: #f8fafc; color: #0f172a; }

.perm-count-badge {
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
  background: #f1f5f9;
  padding: 3px 12px;
  border-radius: 9999px;
}

/* Search input row */
.perm-search-wrap {
  position: relative;
  padding: 12px 16px;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  align-items: center;
  gap: 8px;
}

.perm-search-icon {
  color: #94a3b8;
  flex-shrink: 0;
}

.perm-search-input {
  flex: 1;
  border: none;
  outline: none;
  font-size: 13px;
  color: #0f172a;
  background: transparent;
}
.perm-search-input::placeholder { color: #94a3b8; }

/* Tree view */
.perm-tree {
  padding: 8px 0;
}

.perm-tree-row {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  cursor: pointer;
  transition: background 0.15s;
  font-size: 13px;
  color: #334155;
}
.perm-tree-row:hover { background: #f8fafc; }
.perm-tree-row--selected {
  background: #f0f4ff !important;
  color: #0B529C;
  font-weight: 600;
  border-radius: 8px;
}

.perm-tree-root { padding-left: 16px; }
.perm-tree-l2   { padding-left: 30px; }
.perm-tree-l3   { padding-left: 44px; }

.perm-expand-icon {
  color: #94a3b8;
  flex-shrink: 0;
  transition: transform 0.2s ease;
}
.perm-expand-icon.rotated { transform: rotate(90deg); }

.perm-folder-icon {
  display: flex;
  align-items: center;
  flex-shrink: 0;
}

.perm-leaf-icon {
  display: flex;
  align-items: center;
  flex-shrink: 0;
  margin-left: 2px;
}

.perm-tree-label { flex: 1; }

/* Permission list table */
.perm-table-wrap {
  display: flex;
  flex-direction: column;
}

.perm-list-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 20px;
  background: #f8fafc;
  border-bottom: 1px solid #f1f5f9;
}

.perm-header-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.perm-col-label {
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.perm-access-label {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
}

.perm-list-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 20px;
  border-bottom: 1px solid #f8fafc;
  transition: background 0.12s;
}
.perm-list-row:hover { background: #fafafa; }
.perm-list-row:last-child { border-bottom: none; }

.perm-row-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.perm-row-name {
  font-size: 13.5px;
  color: #0f172a;
}

.perm-checkbox {
  width: 15px;
  height: 15px;
  border-radius: 4px;
  cursor: pointer;
  accent-color: #0B529C;
}

/* Toggle switch */
.perm-toggle-wrap {
  display: flex;
  align-items: center;
}

.perm-toggle {
  position: relative;
  width: 36px;
  height: 20px;
  border-radius: 10px;
  border: none;
  cursor: pointer;
  transition: background 0.2s ease;
  padding: 0;
  display: flex;
  align-items: center;
}

.toggle-off {
  background: #e2e8f0;
}

.toggle-on {
  background: #0B529C;
}

.toggle-thumb {
  position: absolute;
  width: 15px;
  height: 15px;
  border-radius: 50%;
  background: #ffffff;
  box-shadow: 0 1px 3px rgba(0,0,0,0.15);
  transition: left 0.2s ease;
  top: 50%;
  transform: translateY(-50%);
}

.toggle-off .toggle-thumb { left: 3px; }
.toggle-on  .toggle-thumb { left: 18px; }

/* Pagination bar */
.perm-pagination-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  border-top: 1px solid #f1f5f9;
  background: #ffffff;
  font-size: 12.5px;
  color: #64748b;
}

.perm-pagination-info {
  white-space: nowrap;
}

.per-page-select-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.per-page-select {
  appearance: none;
  border: 1px solid #e2e8f0;
  border-radius: 7px;
  padding: 3px 22px 3px 8px;
  font-size: 12.5px;
  color: #0f172a;
  background: #fff;
  cursor: pointer;
  outline: none;
}

.per-page-chevron {
  position: absolute;
  right: 6px;
  pointer-events: none;
  color: #64748b;
}

.perm-page-nav {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-left: auto;
}

.page-nav-btn {
  min-width: 30px;
  height: 30px;
  padding: 0 8px;
  border: 1px solid #e2e8f0;
  border-radius: 7px;
  background: #ffffff;
  font-size: 12.5px;
  color: #475569;
  cursor: pointer;
  transition: all 0.15s;
  display: flex;
  align-items: center;
  justify-content: center;
}
.page-nav-btn:hover { background: #f8fafc; color: #0f172a; }

.page-nav-btn.page-active {
  background: #0B529C;
  color: #ffffff;
  border-color: #0B529C;
  font-weight: 700;
}

.page-ellipsis {
  color: #94a3b8;
  font-size: 13px;
  padding: 0 4px;
}

/* ── GRANTED PERMISSIONS MATRIX STYLING ── */
.granted-tab-container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.no-padding-table-card {
  padding: 0 !important;
  overflow: hidden;
}

.matrix-table-toolbar {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 24px;
  border-bottom: 1px solid #f1f5f9;
}

.toolbar-search-box {
  position: relative;
  display: flex;
  align-items: center;
  width: 320px;
}

.search-icon-muted {
  position: absolute;
  left: 12px;
  color: #94a3b8;
  pointer-events: none;
}

.toolbar-search-input {
  width: 100%;
  height: 38px;
  padding: 0 14px 0 36px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13px;
  color: #0f172a;
  outline: none;
  transition: border 0.15s;
}
.toolbar-search-input:focus { border-color: #0B529C; }

.toolbar-filter-btn {
  height: 38px;
  padding: 0 16px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 500;
  color: #475569;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.15s;
}
.toolbar-filter-btn:hover { background: #f8fafc; color: #0f172a; border-color: #cbd5e1; }

.toolbar-right-icons {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-left: auto;
}

.icon-square-btn {
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
  transition: all 0.15s;
}
.icon-square-btn:hover { background: #f8fafc; color: #0f172a; border-color: #cbd5e1; }

.perm-matrix-table-wrap {
  width: 100%;
  overflow-x: auto;
}

.matrix-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
  font-size: 13px;
}

.matrix-table th {
  background-color: #fafafa;
  color: #64748b;
  font-weight: 600;
  font-size: 12px;
  padding: 12px 24px;
  border-bottom: 1px solid #f1f5f9;
  white-space: nowrap;
}

.matrix-table td {
  padding: 16px 24px;
  border-bottom: 1px solid #f1f5f9;
  color: #334155;
}

.matrix-table tr:hover td {
  background-color: #f8fafc;
}

.col-num {
  color: #94a3b8;
  font-weight: 500;
}

.col-perm-title {
  font-weight: 700;
  color: #0f172a;
}

.col-roles-text, .col-entity-text {
  color: #64748b;
}

.col-action-right {
  text-align: right;
}

.revoked-status-badge {
  display: inline-flex;
  padding: 3px 10px;
  background-color: #fef2f2;
  color: #ef4444;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 600;
}

.matrix-table-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 24px;
  background-color: #ffffff;
  border-top: 1px solid #f1f5f9;
}

.footer-entries-info {
  font-size: 12.5px;
  color: #64748b;
}

/* ── ABOUT EDIT ROLE BANNER ── */
.about-edit-role-banner {
  background-color: #eff6ff;
  border: 1px solid #bae6fd;
  border-radius: 16px;
  padding: 16px 20px;
  display: flex;
  align-items: flex-start;
  gap: 14px;
}

.banner-icon-box {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background-color: #dbeafe;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  margin-top: 2px;
}

.banner-content-text {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.banner-title {
  margin: 0;
  font-size: 14px;
}

.banner-desc {
  margin: 0;
  line-height: 1.5;
}

/* ── ACTION DROPDOWN POPOVER MENU ── */
.dropdown-action-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
  padding: 6px;
  z-index: 50;
  min-width: 170px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.dropdown-item-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 12px;
  border: none;
  background: transparent;
  border-radius: 8px;
  font-size: 12.5px;
  font-weight: 500;
  color: #334155;
  cursor: pointer;
  text-align: left;
  transition: background 0.15s ease;
}

.dropdown-item-btn:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

/* ── MODAL BACKDROP & DIALOG CARD ── */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background-color: rgba(15, 23, 42, 0.45);
  backdrop-filter: blur(3px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 16px;
  animation: fadeIn 0.15s ease-out;
}

.modal-dialog-card {
  background-color: #ffffff;
  border-radius: 16px;
  width: 100%;
  max-width: 520px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: slideUp 0.2s ease-out;
}

@keyframes slideUp {
  from { transform: translateY(12px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid #f1f5f9;
}

.modal-title {
  font-size: 16px;
  margin: 0;
}

.modal-body-content {
  padding: 24px;
  display: flex;
  flex-direction: column;
}

.modal-footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 12px;
  padding: 16px 24px;
  background-color: #fafafa;
  border-top: 1px solid #f1f5f9;
}
</style>
