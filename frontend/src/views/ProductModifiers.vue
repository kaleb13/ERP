<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import {
  Plus, Search, ChevronRight, HelpCircle,
  X, Edit2, Trash2, MoreVertical, Eye, Monitor, Utensils
} from 'lucide-vue-next';
import BaseTable from '../components/BaseTable.vue';
import BaseButton from '../components/BaseButton.vue';

// ─── Types (mirrors ProductModifier / ProductModifierItem schema) ───
interface ModifierItem {
  id: number;
  base_product_id: number | '';   // Pizza, Burger
  added_product_id: number | '';  // Cheese
  state: string;                  // Active / Inactive
}
interface ProductModifier {
  id: number;
  uuid: string;
  name: string;                   // Extra Cheese, Extra Sauce
  entity_id: string;              // entity-specific modifier
  status_lookup_value_id: string; // pending | acceptForAll | acceptForThis
  state: string;                  // Active / Inactive
  items: ModifierItem[];          // ProductModifierItem rows
}

// ─── Reference data ───
const ENTITIES = ['Haleta Enterprise Group', 'Bole Road Branch'];
const STATUS_OPTIONS = [
  { value: 'pending', label: 'Pending' },
  { value: 'acceptForAll', label: 'Accept For All' },
  { value: 'acceptForThis', label: 'Accept For This' }
];

// Products are sourced from the shared Products module (fallback seed below)
const products = ref<Array<{ id: number; name: string }>>([
  { id: 1, name: 'Pizza Margherita' },
  { id: 2, name: 'Classic Burger' },
  { id: 3, name: 'Cheese' },
  { id: 4, name: 'Tomato Sauce' },
  { id: 5, name: 'Beef Patty' }
]);

const productName = (id: number | '') => products.value.find(p => p.id === id)?.name ?? '—';
const statusLabel = (v: string) => STATUS_OPTIONS.find(s => s.value === v)?.label ?? v;

// ─── State ───
const modifiers = ref<ProductModifier[]>([
  {
    id: 1,
    uuid: 'a1b2c3d4-0001',
    name: 'Extra Cheese',
    entity_id: 'Haleta Enterprise Group',
    status_lookup_value_id: 'acceptForAll',
    state: 'Active',
    items: [
      { id: 11, base_product_id: 1, added_product_id: 3, state: 'Active' },
      { id: 12, base_product_id: 2, added_product_id: 3, state: 'Active' }
    ]
  },
  {
    id: 2,
    uuid: 'a1b2c3d4-0002',
    name: 'Spicy Dip',
    entity_id: 'Bole Road Branch',
    status_lookup_value_id: 'acceptForThis',
    state: 'Active',
    items: [
      { id: 21, base_product_id: 2, added_product_id: 4, state: 'Active' }
    ]
  }
]);

// Pagination State
const currentPage = ref(1);
const perPage = ref(10);

const searchQuery = ref('');
const activeActionMenuId = ref<number | null>(null);
const showForm = ref(false);
const showViewModal = ref(false);
const editMode = ref(false);
const selectedId = ref<number | null>(null);
const viewItem = ref<ProductModifier | null>(null);

const blankForm = () => ({
  name: '',
  entity_id: ENTITIES[0],
  status_lookup_value_id: 'acceptForAll',
  state: 'Active',
  items: [{ id: Date.now(), base_product_id: '' as number | '', added_product_id: '' as number | '', state: 'Active' }]
});
const formState = ref(blankForm());

// ─── Persistence ───
onMounted(() => {
  const saved = localStorage.getItem('haleta_erp_product_modifiers');
  if (saved) {
    try {
      const parsed = JSON.parse(saved);
      if (Array.isArray(parsed) && parsed.length > 0) modifiers.value = parsed;
    } catch {}
  }
  const savedProds = localStorage.getItem('haleta_erp_products');
  if (savedProds) {
    try {
      const parsed = JSON.parse(savedProds);
      if (Array.isArray(parsed) && parsed.length > 0) {
        products.value = parsed.map((p: any) => ({ id: p.id, name: p.name }));
      }
    } catch {}
  }
  window.addEventListener('click', closeAllMenus);
});

onUnmounted(() => window.removeEventListener('click', closeAllMenus));

const saveToLocalStorage = () => {
  localStorage.setItem('haleta_erp_product_modifiers', JSON.stringify(modifiers.value));
};

const closeAllMenus = () => {
  activeActionMenuId.value = null;
};

// ─── Search & Pagination ───
const filteredModifiers = computed(() => {
  const q = searchQuery.value.trim().toLowerCase();
  if (!q) return modifiers.value;
  return modifiers.value.filter(m =>
    m.name.toLowerCase().includes(q) ||
    m.entity_id.toLowerCase().includes(q) ||
    m.uuid.toLowerCase().includes(q)
  );
});

const paginatedModifiers = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredModifiers.value.slice(start, start + perPage.value);
});

// ─── UUID helper ───
const newUuid = () => 'mod-' + Math.random().toString(36).substring(2, 10);

// ─── Item rows inside the form ───
const addItemRow = () => {
  formState.value.items.push({
    id: Date.now() + Math.floor(Math.random() * 1000),
    base_product_id: '',
    added_product_id: '',
    state: 'Active'
  });
};
const removeItemRow = (idx: number) => formState.value.items.splice(idx, 1);

// ─── Actions ───
const toggleActionMenu = (e: Event, id: number) => {
  e.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const openAddForm = () => {
  editMode.value = false;
  selectedId.value = null;
  formState.value = blankForm();
  showForm.value = true;
  closeAllMenus();
};

const triggerEdit = (item: ProductModifier) => {
  editMode.value = true;
  selectedId.value = item.id;
  formState.value = {
    name: item.name,
    entity_id: item.entity_id,
    status_lookup_value_id: item.status_lookup_value_id,
    state: item.state,
    items: item.items.map(i => ({ ...i }))
  };
  showForm.value = true;
  closeAllMenus();
};

const triggerView = (item: ProductModifier) => {
  viewItem.value = item;
  showViewModal.value = true;
  closeAllMenus();
};

const triggerDelete = (id: number) => {
  if (!confirm('Are you sure you want to delete this product modifier?')) return;
  modifiers.value = modifiers.value.filter(m => m.id !== id);
  saveToLocalStorage();
  closeAllMenus();
};

const handleSave = () => {
  if (!formState.value.name.trim()) {
    alert('Please provide the Modifier Name.');
    return;
  }
  const cleanItems = formState.value.items.filter(
    i => i.base_product_id !== '' && i.added_product_id !== ''
  );

  if (editMode.value && selectedId.value !== null) {
    const idx = modifiers.value.findIndex(m => m.id === selectedId.value);
    if (idx !== -1) {
      modifiers.value[idx] = {
        ...modifiers.value[idx],
        name: formState.value.name,
        entity_id: formState.value.entity_id,
        status_lookup_value_id: formState.value.status_lookup_value_id,
        state: formState.value.state,
        items: cleanItems
      };
    }
  } else {
    modifiers.value.push({
      id: Date.now(),
      uuid: newUuid(),
      name: formState.value.name,
      entity_id: formState.value.entity_id,
      status_lookup_value_id: formState.value.status_lookup_value_id,
      state: formState.value.state,
      items: cleanItems
    });
  }
  saveToLocalStorage();
  showForm.value = false;
};
</script>

<template>
  <div class="modifiers-page">
    <div class="breadcrumbs">
      <router-link to="/dashboard" class="breadcrumb-link">
        <Monitor :size="16" />
      </router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <span class="breadcrumb-active">Product Modifiers</span>
    </div>

    <!-- Main Content Table Card via BaseTable -->
    <BaseTable
      title="Product Modifiers"
      subtitle="Define optional POS add-ons for hospitality products (e.g. Extra Cheese on a Pizza) and control which base products each add-on applies to."
      v-model:searchQuery="searchQuery"
      :totalEntries="filteredModifiers.length"
      v-model:currentPage="currentPage"
      v-model:perPage="perPage"
      :showFilter="false"
      :showColumns="false"
    >
      <template #actions>
        <BaseButton variant="primary" @click="openAddForm">
          <template #icon-left><Plus :size="18" stroke-width="2.5" /></template>
          <span>Add Modifier</span>
        </BaseButton>
      </template>

      <table class="erp-table">
        <thead>
          <tr>
            <th>Modifier Name</th>
            <th>Applies To (Base → Added)</th>
            <th>Assigned Entity</th>
            <th width="170">Status</th>
            <th width="120">State</th>
            <th width="80" class="text-right">Action</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="m in paginatedModifiers" :key="m.id">
            <td class="col-primary-title">
              <div class="group-name-cell">
                <div class="group-icon-box">
                  <Utensils :size="14" style="color: #0B529C;" />
                </div>
                <span>{{ m.name }}</span>
              </div>
            </td>
            <td class="col-secondary-desc">
              <span v-if="m.items.length === 0" class="text-gray-400">No base products linked</span>
              <span v-else>{{ m.items.length }} product{{ m.items.length > 1 ? 's' : '' }} linked</span>
            </td>
            <td class="col-secondary-text">{{ m.entity_id }}</td>
            <td>
              <span :class="['status-lookup-badge', m.status_lookup_value_id === 'pending' ? 'pending' : 'approved']">
                {{ statusLabel(m.status_lookup_value_id) }}
              </span>
            </td>
            <td>
              <span class="status-pill pill-active">
                {{ m.state }}
              </span>
            </td>
            <td class="text-right">
              <div class="action-menu-container">
                <button @click="toggleActionMenu($event, m.id)" class="btn-action-dots" title="Actions">
                  <MoreVertical :size="16" />
                </button>
                <div v-if="activeActionMenuId === m.id" class="action-dropdown-menu" @click.stop>
                  <button @click="triggerView(m)" class="action-dropdown-item">
                    <Eye :size="14" class="text-gray-500" />
                    <span>View</span>
                  </button>
                  <button @click="triggerEdit(m)" class="action-dropdown-item">
                    <Edit2 :size="14" class="text-gray-500" />
                    <span>Edit</span>
                  </button>
                  <div class="dropdown-divider"></div>
                  <button @click="triggerDelete(m.id)" class="action-dropdown-item text-red-600 hover:bg-red-50">
                    <Trash2 :size="14" class="text-red-500" />
                    <span class="text-red-600 font-medium">Delete</span>
                  </button>
                </div>
              </div>
            </td>
          </tr>
          <tr v-if="filteredModifiers.length === 0">
            <td colspan="6" class="text-center py-8 text-slate-400">
              No product modifiers found matching your search.
            </td>
          </tr>
        </tbody>
      </table>
    </BaseTable>

    <!-- FORM OVERLAY MODAL -->
    <div v-if="showForm" class="modal-overlay" @click.self="showForm = false">
      <div class="modal-card modal-card-lg">
        <button class="modal-close-btn" @click="showForm = false">
          <X :size="18" />
        </button>

        <header class="modal-card-header">
          <h3>{{ editMode ? 'Edit Product Modifier' : 'Create Product Modifier' }}</h3>
        </header>

        <div class="modal-body-content">
          <div class="form-container">
            <div class="form-group">
              <label class="form-label">Modifier Name *</label>
              <input v-model="formState.name" type="text" placeholder="e.g. Extra Cheese, Extra Sauce" class="form-input" />
            </div>

            <div class="form-grid-2">
              <div class="form-group">
                <label class="form-label">Assigned Entity Scope</label>
                <select v-model="formState.entity_id" class="form-select">
                  <option v-for="e in ENTITIES" :key="e" :value="e">{{ e }}</option>
                </select>
              </div>

              <div class="form-group">
                <label class="form-label">Status</label>
                <select v-model="formState.status_lookup_value_id" class="form-select">
                  <option v-for="s in STATUS_OPTIONS" :key="s.value" :value="s.value">{{ s.label }}</option>
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

            <!-- Modifier Items (ProductModifierItem) -->
            <div class="items-block">
              <div class="items-block-header">
                <div class="flex items-center gap-1.5">
                  <span class="items-block-title">Applies To (Base Products)</span>
                  <HelpCircle :size="13" class="text-gray-400 cursor-pointer" title="Each row links a base product (e.g. Pizza) to the added product this modifier brings (e.g. Cheese)." />
                </div>
                <button type="button" @click="addItemRow" class="btn-add-row">
                  <Plus :size="14" /> Add Row
                </button>
              </div>

              <table class="items-table">
                <thead>
                  <tr>
                    <th width="40" class="text-center">No.</th>
                    <th>Base Product</th>
                    <th>Added Product</th>
                    <th width="44" class="text-center">—</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="formState.items.length === 0">
                    <td colspan="4" class="items-empty">No base products linked yet. Add a row to define where this modifier applies.</td>
                  </tr>
                  <tr v-for="(it, idx) in formState.items" :key="it.id">
                    <td class="text-center text-gray-500 font-semibold">{{ idx + 1 }}</td>
                    <td class="p-0">
                      <select v-model="it.base_product_id" class="cell-select">
                        <option value="" disabled>Select base product</option>
                        <option v-for="p in products" :key="p.id" :value="p.id">{{ p.name }}</option>
                      </select>
                    </td>
                    <td class="p-0">
                      <select v-model="it.added_product_id" class="cell-select">
                        <option value="" disabled>Select added product</option>
                        <option v-for="p in products" :key="p.id" :value="p.id">{{ p.name }}</option>
                      </select>
                    </td>
                    <td class="text-center">
                      <button type="button" @click="removeItemRow(idx)" class="btn-row-delete">
                        <Trash2 :size="13" />
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div class="modal-footer-row">
          <button @click="showForm = false" class="btn-modal-secondary">Cancel</button>
          <button @click="handleSave" class="btn-modal-primary">Save Changes</button>
        </div>
      </div>
    </div>

    <!-- VIEW DETAILS MODAL -->
    <div v-if="showViewModal" class="modal-overlay" @click.self="showViewModal = false">
      <div class="modal-card modal-card-lg">
        <button class="modal-close-btn" @click="showViewModal = false">
          <X :size="18" />
        </button>

        <header class="modal-card-header">
          <h3>Product Modifier Details</h3>
        </header>

        <div class="modal-body-content">
          <div class="view-details-grid">
            <div class="detail-item full-width">
              <span class="detail-label">Modifier Name</span>
              <span class="detail-value text-lg font-semibold text-gray-900">{{ viewItem?.name }}</span>
            </div>
            <div class="detail-item">
              <span class="detail-label">Assigned Entity Scope</span>
              <span class="detail-value text-gray-800">{{ viewItem?.entity_id }}</span>
            </div>
            <div class="detail-item">
              <span class="detail-label">Status</span>
              <span :class="['status-lookup-badge inline-block mt-1', viewItem?.status_lookup_value_id === 'pending' ? 'pending' : 'approved']">
                {{ statusLabel(viewItem?.status_lookup_value_id ?? '') }}
              </span>
            </div>
            <div class="detail-item">
              <span class="detail-label">State</span>
              <span class="status-badge status-completed mt-1">
                <span class="dot"></span>{{ viewItem?.state }}
              </span>
            </div>
            <div class="detail-item">
              <span class="detail-label">UUID</span>
              <span class="detail-value text-gray-500" style="font-size:12px">{{ viewItem?.uuid }}</span>
            </div>

            <div class="detail-item full-width" style="border-top:1px solid #f1f5f9; padding-top:14px; margin-top:4px;">
              <span class="detail-label">Applies To (Base → Added Product)</span>
              <table class="items-table mt-2" v-if="viewItem && viewItem.items.length">
                <thead>
                  <tr>
                    <th>Base Product</th>
                    <th>Added Product</th>
                    <th width="90">State</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="it in viewItem.items" :key="it.id">
                    <td>{{ productName(it.base_product_id) }}</td>
                    <td>{{ productName(it.added_product_id) }}</td>
                    <td>{{ it.state }}</td>
                  </tr>
                </tbody>
              </table>
              <span v-else class="detail-value text-gray-400 mt-1">No base products linked.</span>
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
.modifiers-page {
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
.breadcrumbs { display: flex; align-items: center; gap: 8px; font-size: 13px; margin-bottom: 20px; }
.breadcrumb-link { color: #9ca3af; text-decoration: none; display: flex; align-items: center; transition: color 0.15s ease; }
.breadcrumb-link:hover { color: #111827; }
.breadcrumb-separator { color: #9ca3af; display: flex; align-items: center; }
.breadcrumb-active { color: #111827; font-weight: 500; }

/* Content Card */
.content-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  padding: 0;
  box-shadow: 0 1px 3px rgba(0,0,0,0.02);
  overflow: visible;
}
.page-header { padding: 24px 24px 8px 24px; }
.page-title { font-size: 24px; font-weight: 700; color: #111827; margin-bottom: 8px; }
.page-description { font-size: 14px; color: #6b7280; line-height: 1.6; }

/* Action Bar */
.action-bar { display: flex; align-items: center; justify-content: space-between; padding: 16px 24px; gap: 16px; }
.action-bar-left { display: flex; align-items: center; gap: 12px; flex: 1; }
.search-input-wrapper { position: relative; flex: 1; max-width: 320px; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; z-index: 10; }
.table-search {
  width: 100%; padding: 10px 12px 10px 40px; border: 1px solid #e5e7eb; border-radius: 10px;
  font-size: 14px; outline: none; transition: all 0.2s; height: 42px; background: white;
}
.table-search:focus { border-color: #d1d5db; box-shadow: 0 0 0 4px rgba(0,0,0,0.02); }

.btn-create {
  display: flex; align-items: center; gap: 8px; padding: 0 20px; height: 42px;
  background: var(--alias-color-brand-blue-primary); color: #ffffff; border: none; border-radius: 10px;
  font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.2s;
}
.btn-create:hover { background: var(--alias-color-brand-blue-primary-hover); transform: translateY(-1px); }

/* Tables */
.table-wrapper { overflow-x: auto; border-top: 1px solid #e5e7eb; }
.gate-pass-table { width: 100%; border-collapse: collapse; }
.gate-pass-table th {
  text-align: left; padding: 12px 24px; font-size: 13px; font-weight: 500;
  color: #4b5563; background: #f9fafb; border-bottom: 1px solid #e5e7eb;
}
.gate-pass-table td { padding: 14px 24px; font-size: 14px; color: #374151; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
.gate-pass-table tr:hover { background-color: #fcfcfd; }

.group-name-cell { display: flex; align-items: center; gap: 10px; }
.group-icon-box {
  width: 28px; height: 28px; border-radius: 50%; background-color: #ecfdf5;
  display: flex; align-items: center; justify-content: center; border: 1px solid #a7f3d0;
}

.status-lookup-badge { display: inline-flex; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 600; }
.status-lookup-badge.approved { background-color: #e0f2fe; color: #0369a1; }
.status-lookup-badge.pending { background-color: #fef3c7; color: #b45309; }

.status-badge { display: inline-flex; align-items: center; gap: 6px; padding: 4px 12px; border-radius: 20px; font-size: 12px; }
.status-completed { background: #ecfdf5; color: #059669; }
.dot { width: 6px; height: 6px; background: #10b981; border-radius: 50%; }

/* Action Dropdown Menu */
.action-menu-container { position: relative; display: inline-block; }
.btn-three-dots {
  background: none; border: none; color: #9ca3af; cursor: pointer; padding: 6px; border-radius: 8px;
  display: flex; align-items: center; justify-content: center; transition: all 0.15s ease;
}
.btn-three-dots:hover { background-color: #f3f4f6; color: #111827; }
.action-dropdown-menu {
  position: absolute; top: 100%; right: 0; background: white; border: 1px solid #e2e8f0; border-radius: 10px;
  box-shadow: 0 10px 25px -5px rgba(0,0,0,0.08), 0 8px 10px -6px rgba(0,0,0,0.05);
  z-index: 999; min-width: 140px; padding: 6px; display: flex; flex-direction: column; gap: 2px;
  animation: dropFade 0.15s ease-out;
}
@keyframes dropFade { from { opacity: 0; transform: translateY(-5px); } to { opacity: 1; transform: translateY(0); } }
.action-dropdown-item {
  display: flex; align-items: center; gap: 8px; padding: 8px 12px; font-size: 13px; color: #475569;
  background: none; border: none; border-radius: 6px; cursor: pointer; text-align: left; width: 100%; transition: all 0.15s ease;
}
.action-dropdown-item:hover { background-color: #f1f5f9; color: #0f172a; }
.dropdown-divider { height: 1px; background-color: #f1f5f9; margin: 4px 6px; }
.action-dropdown-item.text-red-650 { color: #ef4444; }
.action-dropdown-item.text-red-650:hover { background-color: #fef2f2; color: #dc2626; }

/* Modals */
.modal-overlay {
  position: fixed; top: 0; left: 0; width: 100%; height: 100%; background-color: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(4px); z-index: 1100; display: flex; align-items: center; justify-content: center; padding: 20px;
}
.modal-card {
  background: white; border-radius: 16px; width: 100%; max-width: 520px; padding: 24px;
  box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1), 0 10px 10px -5px rgba(0,0,0,0.04);
  position: relative; display: flex; flex-direction: column;
}
.modal-card-lg { max-width: 640px; max-height: 88vh; }
.modal-close-btn {
  position: absolute; top: 20px; right: 20px; background: none; border: none; color: #94a3b8;
  cursor: pointer; padding: 6px; border-radius: 50%; display: flex;
}
.modal-close-btn:hover { background-color: #f1f5f9; color: #475569; }
.modal-card-header h3 { font-size: 18px; font-weight: 700; color: #0f172a; margin-bottom: 20px; }
.modal-body-content { overflow-y: auto; }

.form-container { display: flex; flex-direction: column; gap: 16px; }
.form-group { display: flex; flex-direction: column; gap: 6px; }
.form-grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.form-label { font-size: 13px; font-weight: 600; color: #374151; }
.form-input, .form-select, .form-textarea {
  width: 100%; padding: 10px 12px; border: 1px solid #e5e7eb; border-radius: 8px;
  font-size: 14px; outline: none; background-color: white; transition: all 0.15s ease;
}
.form-input:focus, .form-select:focus, .form-textarea:focus { border-color: #111827; }

/* Modifier Items sub-table */
.items-block { border: 1px solid #e5e7eb; border-radius: 12px; overflow: hidden; }
.items-block-header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 12px 14px; background: #f9fafb; border-bottom: 1px solid #e5e7eb;
}
.items-block-title { font-size: 13px; font-weight: 700; color: #374151; }
.btn-add-row {
  display: flex; align-items: center; gap: 6px; padding: 6px 12px;
  background: var(--alias-color-brand-blue-primary); color: white; border: none;
  border-radius: 8px; font-size: 12px; font-weight: 600; cursor: pointer; transition: all 0.15s ease;
}
.btn-add-row:hover { background: var(--alias-color-brand-blue-primary-hover); }
.items-table { width: 100%; border-collapse: collapse; }
.items-table th {
  text-align: left; padding: 10px 12px; font-size: 12px; font-weight: 600;
  color: #6b7280; background: #fcfcfd; border-bottom: 1px solid #f3f4f6;
}
.items-table td { padding: 8px 12px; font-size: 13px; color: #374151; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
.items-empty { padding: 18px 12px; text-align: center; color: #9ca3af; font-size: 13px; }
.cell-select { width: 100%; padding: 8px 10px; border: none; font-size: 13px; background: transparent; outline: none; cursor: pointer; }
.cell-select:focus { background: #f8fafc; }
.btn-row-delete { padding: 6px; background: none; border: none; color: #f87171; border-radius: 6px; cursor: pointer; }
.btn-row-delete:hover { background: #fef2f2; color: #dc2626; }

.modal-footer-row { display: flex; gap: 12px; margin-top: 24px; }
.btn-modal-primary, .btn-modal-secondary {
  flex: 1; padding: 10px 16px; border-radius: 8px; font-size: 13px; font-weight: 600;
  cursor: pointer; transition: all 0.2s; text-align: center;
}
.btn-modal-primary { background-color: var(--alias-color-brand-blue-primary); color: white; border: none; }
.btn-modal-primary:hover { background-color: var(--alias-color-brand-blue-primary-hover); }
.btn-modal-secondary { background-color: white; color: #475569; border: 1px solid #e2e8f0; }
.btn-modal-secondary:hover { background-color: #f8fafc; }
.full-width { flex: 1 1 100% !important; width: 100% !important; }

/* View Details */
.view-details-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
.detail-item { display: flex; flex-direction: column; gap: 4px; }
.detail-item.full-width { grid-column: span 2; }
.detail-label { font-size: 11px; font-weight: 700; color: #9ca3af; text-transform: uppercase; letter-spacing: 0.05em; }
.detail-value { font-size: 14px; color: #334155; }
.text-lg { font-size: 18px; }
</style>
