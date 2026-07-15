<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Plus, Search, ChevronRight, HelpCircle,
  X, Check, Lock, Edit2, Trash2, MoreVertical, Eye,
  Folder, FolderOpen, FolderPlus, Grid, List, ArrowLeft, Info,
  Box, EyeOff, LayoutGrid, AlertCircle, RefreshCw, BarChart2, Monitor
} from 'lucide-vue-next';

// Routing
const router = useRouter();

// Default Hierarchical Group Seed Data
const initialProductGroups = [
  { id: 1, name: 'Electronics', parent_id: null, level: 0, is_group: true, entity: 'Haleta Enterprise Group', status_lookup: 'Approved', state: 'Active', color: '#3b82f6', description: 'All electronic components, consumer devices, and hardware accessories.' },
  { id: 2, name: 'Groceries', parent_id: null, level: 0, is_group: true, entity: 'Haleta Enterprise Group', status_lookup: 'Approved', state: 'Active', color: '#10b981', description: 'Fresh foods, grocery products, and household items.' },
  { id: 3, name: 'Apparel', parent_id: null, level: 0, is_group: true, entity: 'Haleta Enterprise Group', status_lookup: 'Approved', state: 'Active', color: '#8b5cf6', description: 'Clothing, fashion wear, footwear, and textile goods.' },
  { id: 4, name: 'Smartphones', parent_id: 1, level: 1, is_group: true, entity: 'Haleta Enterprise Group', status_lookup: 'Approved', state: 'Active', color: '#3b82f6', description: 'Mobile smartphones and handheld cellular devices.' },
  { id: 5, name: 'Laptops', parent_id: 1, level: 1, is_group: false, entity: 'Haleta Enterprise Group', status_lookup: 'Approved', state: 'Active', color: '#0284c7', description: 'Portable compute notebook systems and laptops.' },
  { id: 6, name: 'iOS Devices', parent_id: 4, level: 2, is_group: false, entity: 'Haleta Enterprise Group', status_lookup: 'Approved', state: 'Active', color: '#2563eb', description: 'Apple iOS mobile hardware and iPhones.' },
  { id: 7, name: 'Android Devices', parent_id: 4, level: 2, is_group: false, entity: 'Haleta Enterprise Group', status_lookup: 'Approved', state: 'Active', color: '#1d4ed8', description: 'Google Android powered handsets and devices.' },
  { id: 8, name: 'Fruits', parent_id: 2, level: 1, is_group: false, entity: 'Bole Road Branch', status_lookup: 'Approved', state: 'Active', color: '#059669', description: 'Fresh, organic tree and ground fruits.' },
  { id: 9, name: 'Vegetables', parent_id: 2, level: 1, is_group: false, entity: 'Bole Road Branch', status_lookup: 'Approved', state: 'Active', color: '#10b981', description: 'Fresh green leafy and root vegetables.' },
  { id: 10, name: 'Menswear', parent_id: 3, level: 1, is_group: false, entity: 'Haleta Enterprise Group', status_lookup: 'Approved', state: 'Active', color: '#7c3aed', description: 'Gents wear, formal wear, shirts and accessories.' },
  { id: 11, name: 'Womenswear', parent_id: 3, level: 1, is_group: false, entity: 'Haleta Enterprise Group', status_lookup: 'Approved', state: 'Active', color: '#db2777', description: 'Ladies clothing, outfits, and fashion lines.' }
];

// State
const productGroups = ref<any[]>([]);
const products = ref<any[]>([]);

// UI Control
const currentGroupId = ref<number | null>(null);
const viewMode = ref<'grid' | 'list'>('grid'); // grid (folder) vs list (tree)
const searchQuery = ref('');
const activeActionMenuId = ref<number | null>(null);

// Modal Management
const showForm = ref(false);
const showViewModal = ref(false);
const editMode = ref(false);
const selectedId = ref<number | null>(null);
const viewItem = ref<any>(null);

// Form Fields State
const formState = ref({
  name: '',
  parent_id: null as number | null,
  is_group: false,
  entity: 'Haleta Enterprise Group',
  status_lookup: 'Approved',
  state: 'Active',
  color: '#3b82f6',
  description: ''
});

// Color Presets for Color Selection
const colorPresets = [
  { name: 'Blue', value: '#3b82f6' },
  { name: 'Sky', value: '#0284c7' },
  { name: 'Emerald', value: '#10b981' },
  { name: 'Green', value: '#059669' },
  { name: 'Purple', value: '#8b5cf6' },
  { name: 'Violet', value: '#7c3aed' },
  { name: 'Pink', value: '#db2777' },
  { name: 'Indigo', value: '#6366f1' },
  { name: 'Amber', value: '#f59e0b' },
  { name: 'Rose', value: '#f43f5e' }
];

// Expanded Node tracker for the flat tree List View
const expandedTreeNodes = ref<Record<number, boolean>>({});

// LifeCycle hooks
onMounted(() => {
  // Load groups
  const savedGroups = localStorage.getItem('haleta_erp_product_groups');
  if (savedGroups) {
    productGroups.value = JSON.parse(savedGroups);
  } else {
    productGroups.value = [...initialProductGroups];
    localStorage.setItem('haleta_erp_product_groups', JSON.stringify(productGroups.value));
  }

  // Load products to compute real statistics (products count per group)
  const savedProducts = localStorage.getItem('haleta_erp_products');
  let productsList = [];
  if (savedProducts) {
    productsList = JSON.parse(savedProducts);
  }

  // Seeding high quality demo products corresponding directly to the nested hierarchy structure
  const demoProducts = [
    {
      id: 101,
      code: 'PD0101',
      sku: 'IP15P-128',
      name: 'iPhone 15 Pro',
      product_group: 'iOS Devices',
      product_type: 'Direct Sales',
      uom: 'Pcs',
      status: 'Active',
      description: 'Superb iOS smartphone featuring a grade-5 titanium build and dynamic island.',
      price: 999.00,
      media: [{ id: 1, url: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?q=80&w=600&auto=format&fit=crop', isPrimary: true }]
    },
    {
      id: 102,
      code: 'PD0102',
      sku: 'GS24U-256',
      name: 'Samsung Galaxy S24 Ultra',
      product_group: 'Android Devices',
      product_type: 'Direct Sales',
      uom: 'Pcs',
      status: 'Active',
      description: 'Flagship Android phone with Galaxy AI and Snapdragon Gen 3 chip.',
      price: 1199.00,
      media: [{ id: 1, url: 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?q=80&w=600&auto=format&fit=crop', isPrimary: true }]
    },
    {
      id: 103,
      code: 'PD0103',
      sku: 'MBP-M3-16',
      name: 'MacBook Pro M3',
      product_group: 'Laptops',
      product_type: 'Direct Sales',
      uom: 'Pcs',
      status: 'Active',
      description: 'Apple Silicon M3 powerhouse with Liquid Retina XDR screen.',
      price: 1599.00,
      media: [{ id: 1, url: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?q=80&w=600&auto=format&fit=crop', isPrimary: true }]
    },
    {
      id: 104,
      code: 'PD0104',
      sku: 'DXPS15-32',
      name: 'Dell XPS 15',
      product_group: 'Laptops',
      product_type: 'Direct Sales',
      uom: 'Pcs',
      status: 'Active',
      description: 'Stunning InfinityEdge display developer laptop with NVIDIA graphics.',
      price: 1899.00,
      media: [{ id: 1, url: 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?q=80&w=600&auto=format&fit=crop', isPrimary: true }]
    },
    {
      id: 105,
      code: 'PD0105',
      sku: 'FR-APL-01',
      name: 'Gala Apples',
      product_group: 'Fruits',
      product_type: 'Direct Sales',
      uom: 'Kg',
      status: 'Active',
      description: 'Fresh organic crunchy Gala apples from organic valley farms.',
      price: 3.99,
      media: [{ id: 1, url: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?q=80&w=600&auto=format&fit=crop', isPrimary: true }]
    },
    {
      id: 106,
      code: 'PD0106',
      sku: 'FR-BAN-02',
      name: 'Organic Bananas',
      product_group: 'Fruits',
      product_type: 'Direct Sales',
      uom: 'Kg',
      status: 'Active',
      description: 'Sweet, energy-boosting organic fresh yellow bananas.',
      price: 1.99,
      media: [{ id: 1, url: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?q=80&w=600&auto=format&fit=crop', isPrimary: true }]
    },
    {
      id: 107,
      code: 'PD0107',
      sku: 'VG-CAR-01',
      name: 'Organic Carrots',
      product_group: 'Vegetables',
      product_type: 'Direct Sales',
      uom: 'Kg',
      status: 'Active',
      description: 'Crisp, pesticide-free sweet carrots harvested daily.',
      price: 2.49,
      media: [{ id: 1, url: 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?q=80&w=600&auto=format&fit=crop', isPrimary: true }]
    },
    {
      id: 108,
      code: 'PD0108',
      sku: 'CL-SHRT-01',
      name: 'Slim Fit Cotton Shirt',
      product_group: 'Menswear',
      product_type: 'Direct Sales',
      uom: 'Pcs',
      status: 'Active',
      description: '100% premium combed cotton slim fit formal button-up shirt.',
      price: 39.99,
      media: [{ id: 1, url: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?q=80&w=600&auto=format&fit=crop', isPrimary: true }]
    },
    {
      id: 109,
      code: 'PD0109',
      sku: 'CL-DRS-02',
      name: 'Summer Floral Dress',
      product_group: 'Womenswear',
      product_type: 'Direct Sales',
      uom: 'Pcs',
      status: 'Active',
      description: 'Breathable, lightweight floral pattern slip-on summer dress.',
      price: 49.99,
      media: [{ id: 1, url: 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?q=80&w=600&auto=format&fit=crop', isPrimary: true }]
    }
  ];

  // Append demo products that aren't already present in local storage list
  demoProducts.forEach(demo => {
    if (!productsList.some(p => p.sku === demo.sku || p.code === demo.code)) {
      productsList.push(demo);
    }
  });

  products.value = productsList;
  localStorage.setItem('haleta_erp_products', JSON.stringify(productsList));

  // Initialize expanded nodes
  productGroups.value.forEach(g => {
    if (g.parent_id === null) {
      expandedTreeNodes.value[g.id] = true;
    }
  });

  window.addEventListener('click', closeAllMenus);
});

onUnmounted(() => {
  window.removeEventListener('click', closeAllMenus);
});

// Sync State
const saveGroupsToLocalStorage = () => {
  localStorage.setItem('haleta_erp_product_groups', JSON.stringify(productGroups.value));
};

const closeAllMenus = () => {
  activeActionMenuId.value = null;
};

// Computations
const currentGroup = computed(() => {
  if (currentGroupId.value === null) return null;
  return productGroups.value.find(g => g.id === currentGroupId.value) || null;
});

// Breadcrumbs Trace path
const breadcrumbs = computed(() => {
  const list = [];
  let current = currentGroup.value;
  while (current) {
    list.unshift(current);
    const parentId = current.parent_id;
    current = parentId ? productGroups.value.find(g => g.id === parentId) : null;
  }
  return list;
});

// Subgroups of the currently open folder
const currentSubgroups = computed(() => {
  return productGroups.value.filter(g => g.parent_id === currentGroupId.value);
});

// Direct products of the currently open folder (by name comparison or custom attribute)
const currentProducts = computed(() => {
  if (!currentGroup.value) return [];
  // Direct matches
  return products.value.filter(p => p.product_group?.toLowerCase() === currentGroup.value.name.toLowerCase());
});

// All sub-groups recursively (used to calculate nested product counts)
const getRecursiveSubgroupIds = (groupId: number): number[] => {
  const ids = [groupId];
  const children = productGroups.value.filter(g => g.parent_id === groupId);
  children.forEach(c => {
    ids.push(...getRecursiveSubgroupIds(c.id));
  });
  return ids;
};

// Get product count inside a group (including its subgroups recursively)
const getProductCount = (group: any) => {
  const groupIds = getRecursiveSubgroupIds(group.id);
  const groupNames = productGroups.value
    .filter(g => groupIds.includes(g.id))
    .map(g => g.name.toLowerCase());
  
  return products.value.filter(p => p.product_group && groupNames.includes(p.product_group.toLowerCase())).length;
};

// Subgroups count
const getSubgroupsCount = (groupId: number) => {
  return productGroups.value.filter(g => g.parent_id === groupId).length;
};

// Tree layout builder for flat list
const flatTreeList = computed(() => {
  const list: any[] = [];
  
  const build = (parentId: number | null, depth: number) => {
    const nodes = productGroups.value.filter(g => g.parent_id === parentId);
    // Sort nodes alphabetically
    nodes.sort((a, b) => a.name.localeCompare(b.name));
    
    nodes.forEach(node => {
      list.push({ ...node, depth });
      const isExpanded = expandedTreeNodes.value[node.id];
      if (isExpanded) {
        build(node.id, depth + 1);
      }
    });
  };
  
  build(null, 0);
  return list;
});

// Global Search Filter (Grid View filters current scope, List view filters the flat tree list)
const filteredGridSubgroups = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return currentSubgroups.value;
  return currentSubgroups.value.filter(g => 
    g.name.toLowerCase().includes(q) || 
    g.description.toLowerCase().includes(q)
  );
});

const filteredGridProducts = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return currentProducts.value;
  return currentProducts.value.filter(p => 
    p.name.toLowerCase().includes(q) || 
    p.code.toLowerCase().includes(q) || 
    p.sku?.toLowerCase().includes(q)
  );
});

const filteredFlatTree = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return flatTreeList.value;
  
  // When searching, bypass tree hierarchies and return matching search nodes directly
  return flatTreeList.value.filter(item => 
    item.name.toLowerCase().includes(q) || 
    item.description?.toLowerCase().includes(q) || 
    item.entity.toLowerCase().includes(q)
  );
});

// Dropdown lists (indented display names for parent selection)
const parentSelectionList = computed(() => {
  const list: { id: number; name: string; level: number }[] = [];
  const build = (parentId: number | null, depth: number) => {
    const children = productGroups.value.filter(g => g.parent_id === parentId);
    children.forEach(c => {
      // Don't list the item itself or its nested descendants as options to avoid cycles
      if (selectedId.value && (c.id === selectedId.value || isDescendantOf(c.id, selectedId.value))) {
        return;
      }
      list.push({ id: c.id, name: c.name, level: depth });
      build(c.id, depth + 1);
    });
  };
  build(null, 0);
  return list;
});

// Check if group is a descendant of parent
const isDescendantOf = (groupId: number, parentId: number): boolean => {
  const g = productGroups.value.find(item => item.id === groupId);
  if (!g || g.parent_id === null) return false;
  if (g.parent_id === parentId) return true;
  return isDescendantOf(g.parent_id, parentId);
};

// Actions
const toggleActionMenu = (e: Event, id: number) => {
  e.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const enterFolder = (id: number) => {
  currentGroupId.value = id;
  searchQuery.value = '';
  closeAllMenus();
};

const navigateUp = () => {
  if (currentGroup.value) {
    currentGroupId.value = currentGroup.value.parent_id;
  }
};

const toggleTreeNode = (id: number) => {
  expandedTreeNodes.value[id] = !expandedTreeNodes.value[id];
};

// CRUD Operations
const openAddForm = () => {
  editMode.value = false;
  selectedId.value = null;
  formState.value = {
    name: '',
    parent_id: currentGroupId.value, // Preselect parent based on currently active directory
    is_group: false,
    entity: 'Haleta Enterprise Group',
    status_lookup: 'Approved',
    state: 'Active',
    color: currentGroup.value?.color || '#3b82f6',
    description: ''
  };
  showForm.value = true;
  closeAllMenus();
};

const triggerEdit = (item: any) => {
  editMode.value = true;
  selectedId.value = item.id;
  formState.value = {
    name: item.name,
    parent_id: item.parent_id,
    is_group: item.is_group,
    entity: item.entity,
    status_lookup: item.status_lookup,
    state: item.state,
    color: item.color || '#3b82f6',
    description: item.description || ''
  };
  showForm.value = true;
  closeAllMenus();
};

const triggerView = (item: any) => {
  viewItem.value = item;
  showViewModal.value = true;
  closeAllMenus();
};

const handleSave = () => {
  if (!formState.value.name.trim()) {
    alert('Please fill out the Product Group Name.');
    return;
  }

  // Calculate nesting level
  let calculatedLevel = 0;
  if (formState.value.parent_id) {
    const parent = productGroups.value.find(g => g.id === formState.value.parent_id);
    if (parent) {
      calculatedLevel = parent.level + 1;
    }
  }

  if (editMode.value && selectedId.value !== null) {
    const idx = productGroups.value.findIndex(g => g.id === selectedId.value);
    if (idx !== -1) {
      // Check for cycles
      if (formState.value.parent_id === selectedId.value) {
        alert('A group cannot be its own parent.');
        return;
      }
      
      productGroups.value[idx].name = formState.value.name;
      productGroups.value[idx].parent_id = formState.value.parent_id;
      productGroups.value[idx].level = calculatedLevel;
      productGroups.value[idx].is_group = formState.value.is_group;
      productGroups.value[idx].entity = formState.value.entity;
      productGroups.value[idx].status_lookup = formState.value.status_lookup;
      productGroups.value[idx].state = formState.value.state;
      productGroups.value[idx].color = formState.value.color;
      productGroups.value[idx].description = formState.value.description;

      // Update levels of descendant nodes
      updateDescendantLevels(selectedId.value, calculatedLevel);
    }
  } else {
    // Create new group
    const newGroup = {
      id: Date.now(),
      name: formState.value.name,
      parent_id: formState.value.parent_id,
      level: calculatedLevel,
      is_group: formState.value.is_group,
      entity: formState.value.entity,
      status_lookup: formState.value.status_lookup,
      state: formState.value.state,
      color: formState.value.color,
      description: formState.value.description || 'No description'
    };
    productGroups.value.push(newGroup);
    
    // Automatically expand the parent node so the new item shows up in flat list
    if (formState.value.parent_id) {
      expandedTreeNodes.value[formState.value.parent_id] = true;
    }
  }

  saveGroupsToLocalStorage();
  showForm.value = false;
};

// Recursively update levels of descendant nodes on edit
const updateDescendantLevels = (parentId: number, parentLevel: number) => {
  const children = productGroups.value.filter(g => g.parent_id === parentId);
  children.forEach(c => {
    const idx = productGroups.value.findIndex(g => g.id === c.id);
    if (idx !== -1) {
      productGroups.value[idx].level = parentLevel + 1;
      updateDescendantLevels(c.id, parentLevel + 1);
    }
  });
};

const triggerDelete = (id: number) => {
  const hasChildren = productGroups.value.some(g => g.parent_id === id);
  if (hasChildren) {
    alert('This product group contains nested sub-groups. Please delete or re-assign the sub-groups first.');
    return;
  }

  const group = productGroups.value.find(g => g.id === id);
  if (group) {
    const linkedProducts = products.value.filter(p => p.product_group?.toLowerCase() === group.name.toLowerCase());
    if (linkedProducts.length > 0) {
      if (!confirm(`Warning: There are ${linkedProducts.length} products associated with this group. Deleting this group will leave those products without an active group assignment. Do you want to proceed?`)) {
        return;
      }
    }
  }

  if (!confirm('Are you sure you want to delete this product group?')) return;
  
  productGroups.value = productGroups.value.filter(g => g.id !== id);
  saveGroupsToLocalStorage();
  closeAllMenus();
  
  // If we deleted the group we are currently inside, go up
  if (currentGroupId.value === id) {
    currentGroupId.value = null;
  }
};
</script>

<template>
  <div class="product-groups-page">
    
    <!-- Top Action Breadcrumbs and View Toggles -->
    <div class="top-nav-bar flex items-center justify-between">
      <div class="breadcrumbs">
        <router-link to="/dashboard" class="breadcrumb-link">
          <Monitor :size="16" />
        </router-link>
        <ChevronRight :size="12" class="breadcrumb-separator" />
        <button @click="currentGroupId = null" class="breadcrumb-link-btn" :class="{ 'font-semibold text-gray-900': currentGroupId === null }">
          Product Groups
        </button>
        <template v-for="(bc, index) in breadcrumbs" :key="bc.id">
          <ChevronRight :size="12" class="breadcrumb-separator" />
          <button 
            @click="enterFolder(bc.id)" 
            class="breadcrumb-link-btn"
            :class="{ 'font-semibold text-gray-900': index === breadcrumbs.length - 1 }"
          >
            {{ bc.name }}
          </button>
        </template>
      </div>

      <!-- View Switcher -->
      <div class="view-toggles flex items-center bg-gray-100 rounded-lg p-1 border border-gray-200">
        <button 
          @click="viewMode = 'grid'" 
          :class="['toggle-btn flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-semibold transition-all', 
            viewMode === 'grid' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-900']"
          title="Grid Folder View"
        >
          <LayoutGrid :size="14" />
          Grid View
        </button>
        <button 
          @click="viewMode = 'list'" 
          :class="['toggle-btn flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-semibold transition-all', 
            viewMode === 'list' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-900']"
          title="Hierarchical Tree List"
        >
          <List :size="14" />
          List View
        </button>
      </div>
    </div>

    <!-- Main Content Panel -->
    <div class="content-card">
      <header class="page-header flex flex-col md:flex-row md:items-center md:justify-between">
        <div class="title-area">
          <h1 class="page-title flex items-center gap-2">
            <span class="p-2 bg-blue-50 border border-blue-100 rounded-xl text-[#0b529c]">
              <Folder :size="22" />
            </span>
            Product Group Hierarchy
          </h1>
          <p class="page-description">
            Organize inventory using hierarchical classifications. Used for sales filtering, POS quick buttons, reports, discounts, and category analytics.
          </p>
        </div>

        <div class="action-buttons-header mt-4 md:mt-0 flex gap-3">
          <button @click="openAddForm" class="btn-create shadow-sm">
            <Plus :size="18" />
            Add New Group
          </button>
        </div>
      </header>

      <!-- Search and Filter Bar -->
      <div class="action-bar flex items-center justify-between border-t border-gray-100">
        <div class="action-bar-left flex-1 max-w-sm">
          <div class="search-input-wrapper relative">
            <Search :size="16" class="search-icon text-gray-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input 
              v-model="searchQuery" 
              type="text" 
              placeholder="Search in this scope..." 
              class="table-search w-full border border-gray-200 rounded-xl pl-9 pr-4 py-2 text-sm outline-none transition-all focus:border-gray-300 focus:ring-1 focus:ring-gray-300" 
            />
          </div>
        </div>

        <div v-if="viewMode === 'grid' && currentGroupId !== null" class="action-bar-right">
          <button @click="navigateUp" class="btn-back-folder flex items-center gap-1.5 px-3 py-2 border border-gray-200 rounded-xl hover:bg-gray-50 text-xs font-semibold text-gray-600 transition-colors">
            <ArrowLeft :size="14" />
            Back to Parent
          </button>
        </div>
      </div>

      <!-- ==================== FLOW A: GRID VIEW (FOLDER EXPLORER) ==================== -->
      <div v-if="viewMode === 'grid'" class="folder-explorer-layout p-6 space-y-6">
        
        <!-- Parent Description Info Callout -->
        <div v-if="currentGroup" class="parent-info-callout border border-gray-200 rounded-xl p-4 bg-gray-50/50 flex items-start gap-3">
          <div class="w-4 h-4 rounded-full flex items-center justify-center shrink-0 mt-0.5" :style="{ backgroundColor: currentGroup.color + '1A', color: currentGroup.color }">
            <Info :size="14" />
          </div>
          <div class="info-content">
            <h4 class="text-xs font-bold text-gray-800 uppercase tracking-wider mb-0.5">About {{ currentGroup.name }}</h4>
            <p class="text-xs text-gray-600 font-medium leading-relaxed">{{ currentGroup.description }}</p>
            <div class="mt-2 flex gap-4 text-[11px] font-semibold text-gray-400">
              <span>Nesting level: <span class="text-gray-700">L{{ currentGroup.level }}</span></span>
              <span>Entity: <span class="text-gray-700">{{ currentGroup.entity }}</span></span>
              <span>Direct Subgroups: <span class="text-gray-700">{{ getSubgroupsCount(currentGroup.id) }}</span></span>
              <span>Direct Products: <span class="text-gray-700">{{ currentProducts.length }}</span></span>
            </div>
          </div>
        </div>

        <!-- 1. Nested Subfolders Section -->
        <div class="subfolders-section">
          <h3 class="section-title-premium text-[11px] font-bold text-gray-400 uppercase tracking-wider mb-3">
            Sub-Groups ({{ filteredGridSubgroups.length }})
          </h3>

          <div v-if="filteredGridSubgroups.length === 0" class="no-subfolders py-6 border border-dashed border-gray-200 rounded-xl text-center text-xs font-medium text-gray-400">
            No nested sub-groups inside this scope.
          </div>

          <div v-else class="folder-cards-grid grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            
            <!-- Folder Card -->
            <div 
              v-for="subg in filteredGridSubgroups" 
              :key="subg.id"
              @dblclick="enterFolder(subg.id)"
              :style="{ '--folder-accent': subg.color || '#3b82f6' }"
              class="folder-card bg-white border border-gray-200 rounded-2xl p-4 shadow-sm hover:shadow-md transition-all cursor-pointer relative group flex flex-col justify-between"
            >
              <!-- Card Header / Folder Icon + Action Button -->
              <div class="folder-card-top flex items-start justify-between">
                <div class="folder-icons-area relative w-12 h-12 flex items-center justify-center rounded-xl bg-gray-50 border border-gray-100 group-hover:bg-white transition-colors">
                  <!-- Custom color coded closed/opened folder icons -->
                  <Folder :size="28" class="folder-closed-icon absolute transition-all duration-300 group-hover:opacity-0 group-hover:scale-75" :style="{ color: subg.color }" />
                  <FolderOpen :size="28" class="folder-open-icon absolute opacity-0 scale-75 transition-all duration-300 group-hover:opacity-100 group-hover:scale-100" :style="{ color: subg.color }" />
                </div>

                <!-- Action Dropdown Trigger -->
                <div class="action-menu-container">
                  <button @click.stop="toggleActionMenu($event, subg.id)" class="btn-three-dots hover:bg-gray-100 p-1.5 rounded-lg text-gray-400 hover:text-gray-600 transition-colors">
                    <MoreVertical :size="16" />
                  </button>
                  <div v-if="activeActionMenuId === subg.id" class="action-dropdown-menu" @click.stop>
                    <button @click="triggerView(subg)" class="action-dropdown-item">
                      <Eye :size="13" class="text-gray-500" />
                      <span>View details</span>
                    </button>
                    <button @click="triggerEdit(subg)" class="action-dropdown-item">
                      <Edit2 :size="13" class="text-gray-500" />
                      <span>Edit group</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button @click="triggerDelete(subg.id)" class="action-dropdown-item text-red-650">
                      <Trash2 :size="13" />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>
              </div>

              <!-- Folder Info -->
              <div class="folder-card-body mt-4">
                <h4 @click="enterFolder(subg.id)" class="folder-title text-sm font-bold text-gray-900 group-hover:text-blue-600 transition-colors truncate" :title="subg.name">
                  {{ subg.name }}
                </h4>
                <p class="folder-desc text-[11px] text-gray-500 mt-1 line-clamp-2 h-8 font-medium">
                  {{ subg.description }}
                </p>
              </div>

              <!-- Folder Footer / Stats -->
              <div class="folder-card-footer mt-4 pt-3 border-t border-gray-100 flex items-center justify-between text-[10px] font-bold text-gray-400 uppercase tracking-wider">
                <span class="flex items-center gap-1">
                  <Folder :size="10" />
                  {{ getSubgroupsCount(subg.id) }} Sub
                </span>
                
                <span class="flex items-center gap-1">
                  <Box :size="10" />
                  {{ getProductCount(subg) }} Products
                </span>

                <span v-if="subg.is_group" class="badge-meta bg-purple-50 text-purple-700 px-1.5 py-0.5 rounded border border-purple-100 text-[8px]">
                  Meta
                </span>
                <span v-else class="badge-meta bg-amber-50 text-amber-700 px-1.5 py-0.5 rounded border border-amber-100 text-[8px]">
                  Leaf
                </span>
              </div>
            </div>

          </div>
        </div>

        <!-- 2. Products inside currently open Group Section -->
        <div class="products-section pt-4">
          <h3 class="section-title-premium text-[11px] font-bold text-gray-400 uppercase tracking-wider mb-3">
            Products In Group ({{ filteredGridProducts.length }})
          </h3>

          <div v-if="filteredGridProducts.length === 0" class="no-products py-8 border border-dashed border-gray-200 rounded-2xl bg-white text-center flex flex-col items-center justify-center p-6">
            <div class="p-3 bg-gray-50 rounded-2xl border border-gray-100 text-gray-300 mb-2">
              <Box :size="24" />
            </div>
            <p class="text-sm font-bold text-gray-700">No Direct Products Registered</p>
            <p class="text-xs text-gray-400 font-medium max-w-sm mt-1">
              There are no products cataloged directly in this product group. Go to the products list to register or modify items under this group name.
            </p>
            <button @click="router.push('/inventory/products')" class="mt-4 flex items-center gap-1 px-4 py-2 border border-gray-200 hover:bg-gray-50 rounded-xl text-xs font-bold text-gray-700 transition-colors">
              Go to Product Register
            </button>
          </div>

          <div v-else class="products-cards-grid grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-3 gap-4">
            
            <!-- Product Card -->
            <div v-for="prod in filteredGridProducts" :key="prod.id" class="product-card bg-white border border-gray-200 rounded-2xl p-4 shadow-sm hover:shadow-md transition-all flex flex-col justify-between">
              <div class="product-card-top flex gap-3">
                <!-- Thumbnail -->
                <div class="product-thumbnail w-14 h-14 rounded-xl border border-gray-100 overflow-hidden shrink-0 bg-gray-50 flex items-center justify-center text-gray-400">
                  <img v-if="prod.media && prod.media.length > 0" :src="prod.media[0].thumbnail || prod.media[0].url" alt="Product Image" class="w-full h-full object-cover" />
                  <Box v-else :size="18" />
                </div>

                <!-- Product Info -->
                <div class="product-text flex-1 min-w-0">
                  <h4 class="product-name text-sm font-bold text-gray-900 truncate" :title="prod.name">{{ prod.name }}</h4>
                  <p class="product-sku font-mono text-[10px] text-gray-400 mt-0.5 truncate">{{ prod.sku || 'No SKU' }} ({{ prod.code }})</p>
                  <p class="product-desc text-[11px] text-gray-500 mt-1 line-clamp-2 h-7 leading-normal font-medium">{{ prod.description }}</p>
                </div>
              </div>

              <!-- Product Footer Stats -->
              <div class="product-card-footer mt-4 pt-3 border-t border-gray-100 flex items-center justify-between">
                <span class="product-price text-sm font-bold text-gray-800">
                  ${{ prod.price.toFixed(2) }} <span class="text-[10px] font-bold text-gray-400">/ {{ prod.uom }}</span>
                </span>
                <span class="status-badge bg-emerald-50 text-emerald-700 border border-emerald-100 text-[10px] px-2 py-0.5 rounded-full font-bold">
                  {{ prod.status || 'Active' }}
                </span>
              </div>
            </div>

          </div>
        </div>

      </div>

      <!-- ==================== FLOW B: LIST / TREE VIEW (TABLE TREE) ==================== -->
      <div v-if="viewMode === 'list'" class="table-wrapper">
        <table class="gate-pass-table">
          <thead>
            <tr>
              <th>Group Category Name</th>
              <th>Group Description / Scope</th>
              <th>Assigned Entity</th>
              <th width="150" class="text-center">Nesting Level</th>
              <th width="140" class="text-center">Nesting Mode</th>
              <th width="150">Status Value</th>
              <th width="110">State</th>
              <th width="80" class="text-center">Action</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in filteredFlatTree" :key="item.id" class="hover:bg-gray-50/50 transition-colors">
              <td class="font-semibold text-gray-900">
                <div class="group-name-cell" :style="{ paddingLeft: (searchQuery ? 0 : item.depth * 20) + 'px' }">
                  
                  <!-- Expand/Collapse toggle icon (only visible when not searching) -->
                  <button 
                    v-if="!searchQuery && getSubgroupsCount(item.id) > 0" 
                    @click.stop="toggleTreeNode(item.id)" 
                    class="btn-expand-tree mr-1 p-0.5 hover:bg-gray-100 rounded text-gray-400 hover:text-gray-700 transition-colors"
                  >
                    <ChevronRight :size="14" :class="['transform transition-transform duration-150', expandedTreeNodes[item.id] ? 'rotate-90' : '']" />
                  </button>
                  <span v-else class="w-5 shrink-0"></span>

                  <!-- Color Folder icon -->
                  <div class="group-icon-box" :style="{ backgroundColor: (item.color || '#3b82f6') + '10', borderColor: (item.color || '#3b82f6') + '40' }">
                    <Folder v-if="item.is_group" :size="12" :style="{ color: item.color || '#3b82f6' }" />
                    <Box v-else :size="12" :style="{ color: item.color || '#3b82f6' }" />
                  </div>
                  
                  <span 
                    @click="enterFolder(item.id)" 
                    class="hover:text-blue-600 hover:underline cursor-pointer"
                    :title="'Double click to explore folder'"
                  >
                    {{ item.name }}
                  </span>
                </div>
              </td>
              <td class="text-gray-500 font-medium text-xs truncate max-w-[240px]">{{ item.description }}</td>
              <td class="text-gray-700 text-xs">{{ item.entity }}</td>
              <td class="text-center">
                <span class="bg-gray-100 text-gray-800 text-[10px] font-bold px-2 py-0.5 rounded-full border border-gray-200">
                  Level {{ item.level }}
                </span>
              </td>
              <td class="text-center">
                <span v-if="item.is_group" class="status-lookup-badge bg-purple-50 text-purple-700 border border-purple-100">
                  Category (Meta)
                </span>
                <span v-else class="status-lookup-badge bg-amber-50 text-amber-700 border border-amber-100">
                  Leaf Group
                </span>
              </td>
              <td>
                <span :class="['status-lookup-badge', item.status_lookup === 'Approved' ? 'approved' : 'pending']">
                  {{ item.status_lookup }}
                </span>
              </td>
              <td>
                <span :class="['status-badge', item.state === 'Active' ? 'status-completed' : 'bg-gray-50 text-gray-400 border border-gray-150']">
                  <span v-if="item.state === 'Active'" class="dot"></span>
                  {{ item.state }}
                </span>
              </td>
              <td class="text-center">
                <div class="action-menu-container">
                  <button @click="toggleActionMenu($event, item.id)" class="btn-three-dots" title="Actions">
                    <MoreVertical :size="18" />
                  </button>
                  <div v-if="activeActionMenuId === item.id" class="action-dropdown-menu" @click.stop>
                    <button @click="triggerView(item)" class="action-dropdown-item">
                      <Eye :size="14" class="text-gray-500" />
                      <span>View</span>
                    </button>
                    <button @click="triggerEdit(item)" class="action-dropdown-item">
                      <Edit2 :size="14" class="text-gray-500" />
                      <span>Edit</span>
                    </button>
                    <div class="dropdown-divider"></div>
                    <button @click="triggerDelete(item.id)" class="action-dropdown-item text-red-650">
                      <Trash2 :size="14" />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>
              </td>
            </tr>
            <tr v-if="filteredFlatTree.length === 0">
              <td colspan="8" class="text-center py-8 text-gray-400">No product groups found matching the search criteria.</td>
            </tr>
          </tbody>
        </table>
      </div>

    </div>

    <!-- ==================== DIALOG 1: FORM MODAL (CREATE / EDIT) ==================== -->
    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal-card max-w-lg">
        <button class="modal-close-btn" @click="showForm = false">
          <X :size="18" />
        </button>

        <header class="modal-card-header">
          <h3 class="flex items-center gap-2">
            <FolderPlus :size="20" class="text-blue-600" />
            {{ editMode ? 'Edit Product Classification Group' : 'Create Product Classification Group' }}
          </h3>
        </header>

        <div class="modal-body-content overflow-y-auto max-h-[70vh]">
          <div class="form-container">
            
            <div class="form-group">
              <label class="form-label">Product Group Name *</label>
              <input v-model="formState.name" type="text" placeholder="e.g. Android Devices, Laptops" class="form-input" />
            </div>

            <div class="form-group">
              <label class="form-label">Parent Group (Nesting Category)</label>
              <select v-model="formState.parent_id" class="form-select">
                <option :value="null">None (Root Level Group)</option>
                <option v-for="g in parentSelectionList" :key="g.id" :value="g.id">
                  {{ '&nbsp;&nbsp;'.repeat(g.level) }} 📂 {{ g.name }}
                </option>
              </select>
              <p class="text-[10px] text-gray-400 font-medium">Select where this group lives in the hierarchy tree to enable nested explorer behavior.</p>
            </div>

            <!-- Group Type Toggle (Is Meta Category vs Direct Product Group) -->
            <div class="form-group pt-2">
              <label class="checkbox-row-wrapper flex gap-3.5 p-3 rounded-xl border border-gray-150 bg-gray-50/50 hover:bg-gray-50 transition-all cursor-pointer">
                <input type="checkbox" v-model="formState.is_group" class="hidden-checkbox-input sr-only" />
                <div :class="['custom-checkbox-container w-5 h-5 rounded border flex items-center justify-center shrink-0 mt-0.5 transition-colors', formState.is_group ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']">
                  <Check v-if="formState.is_group" :size="13" />
                </div>
                <div class="checkbox-label-content">
                  <span class="checkbox-title text-xs font-bold text-gray-900 block">Is Meta Group (Category Container)</span>
                  <span class="checkbox-desc text-[10px] text-gray-400 font-medium leading-relaxed block mt-0.5">
                    When enabled, this group acts as a structural category folder and will NOT appear in the product registration select lists (leaves only).
                  </span>
                </div>
              </label>
            </div>

            <!-- Color Palette Selection -->
            <div class="form-group">
              <label class="form-label">Group Theme Color</label>
              <div class="flex flex-wrap gap-2 pt-1">
                <button
                  v-for="color in colorPresets"
                  :key="color.value"
                  type="button"
                  @click="formState.color = color.value"
                  :style="{ backgroundColor: color.value }"
                  :class="['w-8 h-8 rounded-full border-2 transition-all relative flex items-center justify-center', 
                    formState.color === color.value ? 'border-gray-900 scale-110 shadow-sm' : 'border-transparent hover:scale-105']"
                  :title="color.name"
                >
                  <Check v-if="formState.color === color.value" :size="12" class="text-white" />
                </button>
              </div>
            </div>

            <div class="form-grid-2">
              <div class="form-group">
                <label class="form-label">Scope / Assigned Entity</label>
                <select v-model="formState.entity" class="form-select">
                  <option value="Haleta Enterprise Group">Haleta Enterprise Group</option>
                  <option value="Bole Road Branch">Bole Road Branch</option>
                </select>
              </div>

              <div class="form-group">
                <label class="form-label">Workflow Status</label>
                <select v-model="formState.status_lookup" class="form-select">
                  <option value="Approved">Approved</option>
                  <option value="Pending Approval">Pending Approval</option>
                </select>
              </div>
            </div>

            <div class="form-group">
              <label class="form-label">State</label>
              <select v-model="formState.state" class="form-select">
                <option value="Active">Active</option>
                <option value="Inactive">Inactive</option>
              </select>
            </div>

            <div class="form-group">
              <label class="form-label">Group Description</label>
              <textarea v-model="formState.description" rows="3" placeholder="Describe the inventory category context and reporting usage" class="form-textarea"></textarea>
            </div>
          </div>
        </div>

        <div class="modal-footer-row">
          <button @click="showForm = false" class="btn-modal-secondary">Cancel</button>
          <button @click="handleSave" class="btn-modal-primary">Save Changes</button>
        </div>
      </div>
    </div>

    <!-- ==================== DIALOG 2: VIEW DETAILS MODAL ==================== -->
    <div v-if="showViewModal" class="modal-overlay" @click.self="showViewModal = false">
      <div class="modal-card max-w-lg">
        <button class="modal-close-btn" @click="showViewModal = false">
          <X :size="18" />
        </button>

        <header class="modal-card-header">
          <h3 class="flex items-center gap-2">
            <BarChart2 :size="20" class="text-blue-600" />
            Group Information Details
          </h3>
        </header>

        <div class="modal-body-content overflow-y-auto max-h-[70vh]">
          <div class="view-details-grid">
            
            <div class="detail-item full-width">
              <span class="detail-label">Product Group Name</span>
              <div class="flex items-center gap-2 mt-1">
                <span class="w-3.5 h-3.5 rounded-full inline-block" :style="{ backgroundColor: viewItem?.color }"></span>
                <span class="detail-value text-lg font-bold text-gray-900">{{ viewItem?.name }}</span>
              </div>
            </div>

            <div class="detail-item full-width">
              <span class="detail-label">Hierarchy Location Folder Trail</span>
              <span class="detail-value text-xs text-gray-500 font-semibold mt-1 bg-gray-50 border border-gray-100 p-2 rounded-lg flex items-center flex-wrap gap-1">
                <span>Root</span>
                <template v-for="bc in breadcrumbs" :key="bc.id">
                  <ChevronRight :size="10" class="text-gray-400" />
                  <span>{{ bc.name }}</span>
                </template>
                <template v-if="breadcrumbs.every(bc => bc.id !== viewItem?.id)">
                  <ChevronRight :size="10" class="text-gray-400" />
                  <span class="text-gray-800 font-bold">{{ viewItem?.name }}</span>
                </template>
              </span>
            </div>

            <div class="detail-item full-width">
              <span class="detail-label">Scope Description</span>
              <span class="detail-value text-xs text-gray-650 leading-relaxed font-medium mt-1">{{ viewItem?.description }}</span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Assigned Scope Scope</span>
              <span class="detail-value text-xs font-semibold text-gray-700 mt-1">{{ viewItem?.entity }}</span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Nesting Depth</span>
              <span class="detail-value text-xs font-bold text-gray-700 mt-1">Level {{ viewItem?.level }}</span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Nesting Behaviour</span>
              <span class="detail-value mt-1">
                <span v-if="viewItem?.is_group" class="status-lookup-badge bg-purple-50 text-purple-700 border border-purple-100">
                  Category (Meta)
                </span>
                <span v-else class="status-lookup-badge bg-amber-50 text-amber-700 border border-amber-100">
                  Leaf Group
                </span>
              </span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Status Lookup Value</span>
              <span :class="['status-lookup-badge inline-block mt-1', viewItem?.status_lookup === 'Approved' ? 'approved' : 'pending']">
                {{ viewItem?.status_lookup }}
              </span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Operational State</span>
              <span :class="['status-badge mt-1', viewItem?.state === 'Active' ? 'status-completed' : 'bg-gray-50 text-gray-400 border border-gray-150']">
                <span v-if="viewItem?.state === 'Active'" class="dot"></span>
                {{ viewItem?.state }}
              </span>
            </div>

            <div class="detail-item">
              <span class="detail-label">Sub-Groups Count</span>
              <span class="detail-value text-xs font-bold text-gray-700 mt-1">
                {{ viewItem ? getSubgroupsCount(viewItem.id) : 0 }} subgroups
              </span>
            </div>

            <!-- List Products under this Group directly -->
            <div class="detail-item full-width border-t border-gray-100 pt-4 mt-2">
              <span class="detail-label">Linked Catalogued Products ({{ viewItem ? products.filter(p => p.product_group?.toLowerCase() === viewItem.name.toLowerCase()).length : 0 }})</span>
              <div v-if="viewItem && products.filter(p => p.product_group?.toLowerCase() === viewItem.name.toLowerCase()).length > 0" class="mt-2 space-y-2 max-h-[160px] overflow-y-auto pr-1">
                <div 
                  v-for="p in products.filter(p => p.product_group?.toLowerCase() === viewItem.name.toLowerCase())" 
                  :key="p.id"
                  class="flex items-center justify-between p-2 rounded-lg border border-gray-150 bg-gray-50/50 hover:bg-gray-50 transition-colors"
                >
                  <div class="flex items-center gap-2">
                    <Box :size="14" class="text-gray-400" />
                    <span class="text-xs font-bold text-gray-800">{{ p.name }}</span>
                    <span class="text-[9px] font-mono text-gray-400">({{ p.code }})</span>
                  </div>
                  <span class="text-[11px] font-bold text-gray-650">${{ p.price.toFixed(2) }}</span>
                </div>
              </div>
              <div v-else class="text-xs text-gray-450 italic mt-2">No direct products registered under this specific group name.</div>
            </div>

          </div>
        </div>

        <div class="modal-footer-row">
          <button @click="showViewModal = false" class="btn-modal-primary full-width">Close Details</button>
        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>
.product-groups-page {
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
}
.breadcrumb-link {
  color: #9ca3af;
  text-decoration: none;
  display: flex;
  align-items: center;
  transition: color 0.15s ease;
}
.breadcrumb-link:hover {
  color: #111827;
}
.breadcrumb-link-btn {
  background: none;
  border: none;
  color: #6b7280;
  cursor: pointer;
  padding: 0;
  font-size: 13px;
  transition: color 0.15s ease;
}
.breadcrumb-link-btn:hover {
  color: #111827;
}
.breadcrumb-separator {
  color: #9ca3af;
  display: flex;
  align-items: center;
}

/* Content Card */
.content-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 0;
  box-shadow: 0 1px 3px rgba(0,0,0,0.02);
  overflow: visible;
}
.page-header {
  padding: 24px;
}
.page-title {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin-bottom: 8px;
}
.page-description {
  font-size: 13px;
  color: #6b7280;
  line-height: 1.6;
}

/* Action Bar */
.action-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  gap: 16px;
}
.table-search {
  height: 40px;
  background: #fafafa;
}
.table-search:focus {
  background: white;
}

.btn-create {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 20px;
  height: 42px;
  background: #0b529c;
  color: #ffffff;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-create:hover {
  background: #0c65bd;
  transform: translateY(-1px);
}

/* Tables */
.table-wrapper {
  overflow-x: auto;
  border-top: 1px solid #e5e7eb;
}
.gate-pass-table {
  width: 100%;
  border-collapse: collapse;
}
.gate-pass-table th {
  text-align: left;
  padding: 12px 24px;
  font-size: 12px;
  font-weight: 600;
  color: #4b5563;
  background: #f9fafb;
  border-bottom: 1px solid #e5e7eb;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.gate-pass-table td {
  padding: 14px 24px;
  font-size: 13px;
  color: #374151;
  border-bottom: 1px solid #f3f4f6;
  vertical-align: middle;
}

.group-name-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}
.group-icon-box {
  width: 24px;
  height: 24px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid transparent;
}

.status-lookup-badge {
  display: inline-flex;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}
.status-lookup-badge.approved { background-color: #e0f2fe; color: #0369a1; }
.status-lookup-badge.pending { background-color: #fef3c7; color: #b45309; }

.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 2px 10px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 600;
}
.status-completed { background: #ecfdf5; color: #059669; border: 1px solid #a7f3d0; }
.dot { width: 5px; height: 5px; background: #10b981; border-radius: 50%; }

/* Action Dropdown Menu */
.action-menu-container {
  position: relative;
  display: inline-block;
}
.btn-three-dots {
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}
.btn-three-dots:hover {
  background-color: #f3f4f6;
  color: #111827;
}

.action-dropdown-menu {
  position: absolute;
  top: 100%;
  right: 0;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
  z-index: 999;
  min-width: 140px;
  padding: 6px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  animation: dropFade 0.15s ease-out;
}
@keyframes dropFade {
  from { opacity: 0; transform: translateY(-5px); }
  to { opacity: 1; transform: translateY(0); }
}

.action-dropdown-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  font-size: 13px;
  color: #475569;
  background: none;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  width: 100%;
  transition: all 0.15s ease;
}
.action-dropdown-item:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}
.dropdown-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 4px 6px;
}
.action-dropdown-item.text-red-650 {
  color: #ef4444;
}
.action-dropdown-item.text-red-650:hover {
  background-color: #fef2f2;
  color: #dc2626;
}

/* Modals */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(4px);
  z-index: 1100;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}
.modal-card {
  background: white;
  border-radius: 16px;
  width: 100%;
  padding: 24px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  position: relative;
  display: flex;
  flex-direction: column;
}
.modal-close-btn {
  position: absolute;
  top: 20px;
  right: 20px;
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 6px;
  border-radius: 50%;
  display: flex;
}
.modal-close-btn:hover { background-color: #f1f5f9; color: #475569; }

.modal-card-header h3 {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 20px;
}

.form-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}
.form-label {
  font-size: 13px;
  font-weight: 600;
  color: #374151;
}
.form-input, .form-select, .form-textarea {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 14px;
  outline: none;
  background-color: white;
  transition: all 0.15s ease;
}
.form-input:focus, .form-select:focus, .form-textarea:focus {
  border-color: #111827;
}
.form-textarea {
  resize: vertical;
}

.modal-footer-row {
  display: flex;
  gap: 12px;
  margin-top: 24px;
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
  background-color: #0b529c;
  color: white;
  border: none;
}
.btn-modal-primary:hover { background-color: #0c65bd; }
.btn-modal-secondary {
  background-color: white;
  color: #475569;
  border: 1px solid #e2e8f0;
}
.btn-modal-secondary:hover { background-color: #f8fafc; }

.full-width {
  flex: 1 1 100% !important;
  width: 100% !important;
}

/* View Details Styles */
.view-details-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}
.detail-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.detail-item.full-width {
  grid-column: span 2;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 12px;
  margin-bottom: 4px;
}
.detail-label {
  font-size: 11px;
  font-weight: 700;
  color: #9ca3af;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.detail-value {
  font-size: 14px;
  color: #334155;
}
.text-lg {
  font-size: 18px;
}

/* Specific Folder View Card Styles */
.folder-card {
  --folder-accent: #3b82f6;
  border-left-width: 4px;
  border-left-color: var(--folder-accent);
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}
.folder-card:hover {
  transform: translateY(-2px);
  border-left-color: var(--folder-accent);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -2px rgba(0, 0, 0, 0.02);
}

.folder-title {
  cursor: pointer;
}
.folder-title:hover {
  text-decoration: underline;
}

/* Product Card Specific Styles */
.product-card {
  transition: all 0.2s ease-in-out;
}
.product-card:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.03);
}

/* Tree expand/collapse toggle */
.btn-expand-tree {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
}

/* Custom Checkbox Design */
.hidden-checkbox-input:checked + .custom-checkbox-container {
  background-color: #0b529c;
  border-color: #0b529c;
  color: white;
}
.custom-checkbox-container {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}
</style>
