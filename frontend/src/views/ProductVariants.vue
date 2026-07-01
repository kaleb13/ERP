<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import {
  Monitor, ChevronRight, ChevronDown, Plus, Search, X, Edit2, Trash2,
  MoreVertical, Eye, GitBranch, Box, Layers, Package, Sparkles, Trash,
  RefreshCw, Check, Info, Tag, ArrowLeft
} from 'lucide-vue-next';

// ─────────────────────────────────────────────────────────────
// TYPES  (mirrors Product.parent_id / ProductAttribute / ProductVariantOption)
// ─────────────────────────────────────────────────────────────
interface BaseProduct {
  id: number;
  code: string;
  sku: string;
  name: string;
  color: string;
  product_group: string;
  uom: string;
  brand: string;
  price: number;
  is_tax_included: boolean;
  media?: Array<{ url: string; thumbnail?: string; type?: string; isPrimary?: boolean }>;
}
// A single ProductVariantOption (attribute → value pair held on a variant)
interface VariantOption {
  attribute: string;   // Color, Storage, Size ...
  value: string;       // Desert Titanium, 256GB ...
}
// A variant === a Product row with parent_id NOT NULL
interface Variant {
  id: number;
  parent_id: number;
  code: string;
  sku: string;
  name: string;
  barcode: string;
  color: string;
  price: number;
  status: string;      // Active / Inactive
  options: VariantOption[];
}

// ─────────────────────────────────────────────────────────────
// REFERENCE DATA — Attribute catalogue (ProductAttribute / ProductAttributeValue)
// ─────────────────────────────────────────────────────────────
const attributeCatalog = ref<Array<{ name: string; input_type: string; values: string[] }>>([
  { name: 'Color', input_type: 'select', values: ['Desert Titanium', 'Natural Titanium', 'Black', 'White', 'Blue', 'Red', 'Green'] },
  { name: 'Storage', input_type: 'select', values: ['128GB', '256GB', '512GB', '1TB'] },
  { name: 'Size', input_type: 'select', values: ['XS', 'S', 'M', 'L', 'XL', 'XXL'] },
  { name: 'Material', input_type: 'select', values: ['Cotton', 'Leather', 'Polyester', 'Silk'] },
  { name: 'Flavor', input_type: 'select', values: ['Vanilla', 'Chocolate', 'Strawberry'] }
]);

// ─────────────────────────────────────────────────────────────
// BASE PRODUCTS — sourced from the shared Products module (fallback seed)
// ─────────────────────────────────────────────────────────────
const baseProducts = ref<BaseProduct[]>([
  {
    id: 1, code: 'PD0001', sku: 'IP17P', name: 'iPhone 17 Pro', color: '#1d4ed8',
    product_group: 'Smartphones', uom: 'Pcs', brand: 'Apple', price: 1299, is_tax_included: false,
    media: [{ url: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?q=80&w=400&auto=format&fit=crop', isPrimary: true }]
  },
  {
    id: 3, code: 'TS5510', sku: 'CT-TEE', name: 'Cotton Crew T-Shirt', color: '#16a34a',
    product_group: 'Apparel', uom: 'Pcs', brand: 'Generic', price: 24.99, is_tax_included: true,
    media: [{ url: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?q=80&w=400&auto=format&fit=crop', isPrimary: true }]
  },
  {
    id: 2, code: 'AP2032', sku: 'APL-RED-01', name: 'Apple', color: '#16a34a',
    product_group: 'Fruits', uom: 'Pcs', brand: 'Organic Farms', price: 1.5, is_tax_included: true,
    media: [{ url: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?q=80&w=400&auto=format&fit=crop', isPrimary: true }]
  }
]);

// ─────────────────────────────────────────────────────────────
// VARIANTS — Product rows with parent_id NOT NULL (seed)
// ─────────────────────────────────────────────────────────────
const variants = ref<Variant[]>([
  {
    id: 1001, parent_id: 1, code: 'PD0001-V1', sku: 'IP17P-DT-256', name: 'iPhone 17 Pro — Desert Titanium / 256GB',
    barcode: 'A1B2C3D4E5', color: '#c19a6b', price: 1299, status: 'Active',
    options: [{ attribute: 'Color', value: 'Desert Titanium' }, { attribute: 'Storage', value: '256GB' }]
  },
  {
    id: 1002, parent_id: 1, code: 'PD0001-V2', sku: 'IP17P-NT-512', name: 'iPhone 17 Pro — Natural Titanium / 512GB',
    barcode: 'F6G7H8I9J0', color: '#b8b8b0', price: 1499, status: 'Active',
    options: [{ attribute: 'Color', value: 'Natural Titanium' }, { attribute: 'Storage', value: '512GB' }]
  },
  {
    id: 1003, parent_id: 1, code: 'PD0001-V3', sku: 'IP17P-BLK-1TB', name: 'iPhone 17 Pro — Black / 1TB',
    barcode: 'K1L2M3N4O5', color: '#111827', price: 1699, status: 'Inactive',
    options: [{ attribute: 'Color', value: 'Black' }, { attribute: 'Storage', value: '1TB' }]
  }
]);

// ─────────────────────────────────────────────────────────────
// PERSISTENCE
// ─────────────────────────────────────────────────────────────
const STORAGE_KEY = 'haleta_erp_product_variants';

onMounted(() => {
  // Pull base products created in the Products module if present
  const savedProducts = localStorage.getItem('haleta_erp_products');
  if (savedProducts) {
    try {
      const parsed = JSON.parse(savedProducts);
      if (Array.isArray(parsed) && parsed.length) {
        baseProducts.value = parsed.map((p: any) => ({
          id: p.id,
          code: p.code,
          sku: p.sku || '',
          name: p.name,
          color: p.color || '#0b529c',
          product_group: p.product_group || '—',
          uom: p.uom || 'Pcs',
          brand: Array.isArray(p.brand_ids) && p.brand_ids.length ? 'Linked' : (p.brand || '—'),
          price: Number(p.price) || 0,
          is_tax_included: !!p.is_tax_included,
          media: p.media || []
        }));
      }
    } catch (e) { /* keep seed */ }
  }

  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved) {
    try { variants.value = JSON.parse(saved); } catch (e) { /* keep seed */ }
  } else {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(variants.value));
  }
  window.addEventListener('click', closeAllMenus);
});

onUnmounted(() => {
  window.removeEventListener('click', closeAllMenus);
});

const persist = () => localStorage.setItem(STORAGE_KEY, JSON.stringify(variants.value));

// ─────────────────────────────────────────────────────────────
// LIST STATE
// ─────────────────────────────────────────────────────────────
const activeTab = ref<'withVariants' | 'standalone' | 'all'>('withVariants');
const searchQuery = ref('');
const expandedGroups = ref<Record<number, boolean>>({ 1: true });
const activeActionMenuId = ref<number | null>(null);

const toggleGroup = (id: number) => { expandedGroups.value[id] = !expandedGroups.value[id]; };
const closeAllMenus = () => { activeActionMenuId.value = null; };

const baseById = (id: number) => baseProducts.value.find(b => b.id === id);
const variantsOf = (id: number) => variants.value.filter(v => v.parent_id === id);
const primaryImg = (b?: BaseProduct) =>
  b?.media?.find(m => m.isPrimary)?.url || b?.media?.[0]?.url || '';

// Group base products by whether they have variant children
const groupedProducts = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  return baseProducts.value
    .map(b => ({ base: b, children: variantsOf(b.id) }))
    .filter(g => {
      if (activeTab.value === 'withVariants' && g.children.length === 0) return false;
      if (activeTab.value === 'standalone' && g.children.length > 0) return false;
      if (!q) return true;
      return (
        g.base.name.toLowerCase().includes(q) ||
        g.base.code.toLowerCase().includes(q) ||
        g.children.some(v => v.sku.toLowerCase().includes(q) || v.name.toLowerCase().includes(q))
      );
    });
});

// Headline stats
const stats = computed(() => {
  const withVar = baseProducts.value.filter(b => variantsOf(b.id).length > 0).length;
  const standalone = baseProducts.value.length - withVar;
  return { withVar, standalone, totalVariants: variants.value.length };
});

const priceRange = (children: Variant[]) => {
  if (!children.length) return '—';
  const prices = children.map(c => c.price);
  const min = Math.min(...prices), max = Math.max(...prices);
  return min === max ? `$${min.toLocaleString()}` : `$${min.toLocaleString()} – $${max.toLocaleString()}`;
};

// Distinct attribute names used across a group's variants (for the chips on the header)
const groupAttributes = (children: Variant[]) => {
  const set = new Set<string>();
  children.forEach(v => v.options.forEach(o => set.add(o.attribute)));
  return Array.from(set);
};

const toggleActionMenu = (e: Event, id: number) => {
  e.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const deleteVariant = (id: number) => {
  if (!confirm('Delete this variant? This removes the variant product permanently.')) return;
  variants.value = variants.value.filter(v => v.id !== id);
  persist();
  closeAllMenus();
};

// ─────────────────────────────────────────────────────────────
// VARIANT BUILDER  (full-page flow — inherits base, overrides only changes)
// ─────────────────────────────────────────────────────────────
const showBuilder = ref(false);
const builderBaseId = ref<number | ''>('');
const builderEditId = ref<number | null>(null); // editing a single existing variant

// Attribute selectors the user is building variants from
interface AttrSelection { id: number; attribute: string; values: string[] }
const selectedAttributes = ref<AttrSelection[]>([]);

// Generated variant rows (the matrix the user fine-tunes)
interface DraftRow {
  key: string;
  include: boolean;
  options: VariantOption[];
  sku: string;
  barcode: string;
  price: number;
  color: string;
  status: string;
}
const draftRows = ref<DraftRow[]>([]);

const builderBase = computed(() => (builderBaseId.value ? baseById(Number(builderBaseId.value)) : undefined));

const randomBarcode = () => Math.random().toString(36).substring(2, 14).toUpperCase();

const valuesForAttribute = (name: string) =>
  attributeCatalog.value.find(a => a.name === name)?.values ?? [];

// attributes not yet picked (avoid duplicates)
const availableAttributes = computed(() =>
  attributeCatalog.value.filter(a => !selectedAttributes.value.some(s => s.attribute === a.name))
);

const openBuilder = (baseId?: number) => {
  builderEditId.value = null;
  builderBaseId.value = baseId ?? '';
  selectedAttributes.value = [];
  draftRows.value = [];
  showBuilder.value = true;
  closeAllMenus();
};

// Edit a single existing variant — preload one editable row
const editVariant = (v: Variant) => {
  builderEditId.value = v.id;
  builderBaseId.value = v.parent_id;
  selectedAttributes.value = v.options.map((o, i) => ({ id: i + 1, attribute: o.attribute, values: [o.value] }));
  draftRows.value = [{
    key: v.options.map(o => o.value).join('|'),
    include: true,
    options: v.options.map(o => ({ ...o })),
    sku: v.sku, barcode: v.barcode, price: v.price, color: v.color, status: v.status
  }];
  showBuilder.value = true;
  closeAllMenus();
};

const closeBuilder = () => { showBuilder.value = false; };

const addAttributeSelector = () => {
  const next = availableAttributes.value[0];
  selectedAttributes.value.push({
    id: Date.now() + Math.floor(Math.random() * 1000),
    attribute: next ? next.name : '',
    values: []
  });
};
const removeAttributeSelector = (idx: number) => {
  selectedAttributes.value.splice(idx, 1);
};
const toggleAttrValue = (sel: AttrSelection, value: string) => {
  const i = sel.values.indexOf(value);
  if (i === -1) sel.values.push(value); else sel.values.splice(i, 1);
};

// Cartesian product of all selected attribute values
const cartesian = (lists: VariantOption[][]): VariantOption[][] =>
  lists.reduce<VariantOption[][]>(
    (acc, list) => acc.flatMap(combo => list.map(item => [...combo, item])),
    [[]]
  );

const generateMatrix = () => {
  const base = builderBase.value;
  if (!base) { alert('Select a base product first.'); return; }
  const active = selectedAttributes.value.filter(s => s.attribute && s.values.length > 0);
  if (!active.length) { alert('Add at least one attribute with one or more values.'); return; }

  const lists = active.map(s => s.values.map(v => ({ attribute: s.attribute, value: v })));
  const combos = cartesian(lists);

  // preserve any edits the user already made for combos that still exist
  const prevByKey = new Map(draftRows.value.map(r => [r.key, r]));

  draftRows.value = combos.map(opts => {
    const key = opts.map(o => o.value).join('|');
    const existing = prevByKey.get(key);
    if (existing) return existing;
    const suffix = opts.map(o => abbr(o.value)).join('-');
    return {
      key,
      include: true,
      options: opts,
      sku: `${base.sku || base.code}-${suffix}`,
      barcode: randomBarcode(),
      price: base.price,
      color: base.color,
      status: 'Active'
    };
  });
};

// Build a short SKU token from a value: "256GB" -> "256GB", "Desert Titanium" -> "DT"
const abbr = (value: string) => {
  const trimmed = value.trim();
  if (/\d/.test(trimmed)) return trimmed.replace(/\s+/g, '').toUpperCase();
  const words = trimmed.split(/\s+/);
  if (words.length === 1) return words[0].substring(0, 3).toUpperCase();
  return words.map(w => w[0]).join('').toUpperCase();
};

const variantLabel = (opts: VariantOption[]) => opts.map(o => o.value).join(' / ');

// Regenerate automatically when attribute selection changes (only in create mode)
watch(selectedAttributes, () => {
  if (showBuilder.value && builderEditId.value === null) generateMatrix();
}, { deep: true });

const includedCount = computed(() => draftRows.value.filter(r => r.include).length);

const saveBuilder = () => {
  const base = builderBase.value;
  if (!base) { alert('Select a base product first.'); return; }
  const rows = draftRows.value.filter(r => r.include);
  if (!rows.length) { alert('Include at least one variant before saving.'); return; }

  // Validate unique SKUs within the batch
  const skus = rows.map(r => r.sku.trim().toLowerCase());
  if (skus.some(s => !s)) { alert('Every included variant needs an SKU.'); return; }
  if (new Set(skus).size !== skus.length) { alert('Variant SKUs must be unique.'); return; }

  if (builderEditId.value !== null) {
    // single-variant edit
    const idx = variants.value.findIndex(v => v.id === builderEditId.value);
    const r = rows[0];
    if (idx !== -1) {
      variants.value[idx] = {
        ...variants.value[idx],
        sku: r.sku, barcode: r.barcode, price: Number(r.price), color: r.color,
        status: r.status, options: r.options.map(o => ({ ...o })),
        name: `${base.name} — ${variantLabel(r.options)}`
      };
    }
  } else {
    let seq = variantsOf(base.id).length;
    rows.forEach((r, i) => {
      seq += 1;
      variants.value.push({
        id: Date.now() + i,
        parent_id: base.id,
        code: `${base.code}-V${seq}`,
        sku: r.sku.trim(),
        name: `${base.name} — ${variantLabel(r.options)}`,
        barcode: r.barcode,
        color: r.color,
        price: Number(r.price),
        status: r.status,
        options: r.options.map(o => ({ ...o }))
      });
    });
    expandedGroups.value[base.id] = true;
  }
  persist();
  showBuilder.value = false;
};

// ─────────────────────────────────────────────────────────────
// VIEW VARIANT MODAL
// ─────────────────────────────────────────────────────────────
const showViewModal = ref(false);
const viewVariant = ref<Variant | null>(null);
const triggerView = (v: Variant) => {
  viewVariant.value = v;
  showViewModal.value = true;
  closeAllMenus();
};
</script>

<template>
  <div class="variants-page">
    <!-- Breadcrumbs -->
    <div class="breadcrumbs">
      <router-link to="/dashboard" class="breadcrumb-link"><Monitor :size="16" /></router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <router-link to="/inventory/products" class="breadcrumb-link-text">Products</router-link>
      <ChevronRight :size="12" class="breadcrumb-separator" />
      <span class="breadcrumb-active">Product Variants</span>
    </div>

    <!-- ═══════════════ LIST VIEW ═══════════════ -->
    <template v-if="!showBuilder">
      <!-- Stat cards -->
      <div class="stats-row">
        <div class="stat-card">
          <div class="stat-icon" style="background:#eff6ff;"><Layers :size="18" style="color:#2563eb;" /></div>
          <div>
            <div class="stat-value">{{ stats.withVar }}</div>
            <div class="stat-label">Products with Variants</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon" style="background:#f0fdf4;"><GitBranch :size="18" style="color:#16a34a;" /></div>
          <div>
            <div class="stat-value">{{ stats.totalVariants }}</div>
            <div class="stat-label">Total Variants</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon" style="background:#fff7ed;"><Package :size="18" style="color:#ea580c;" /></div>
          <div>
            <div class="stat-value">{{ stats.standalone }}</div>
            <div class="stat-label">Standalone (Zero Variants)</div>
          </div>
        </div>
      </div>

      <!-- Main Card -->
      <div class="content-card">
        <header class="page-header">
          <div class="title-area">
            <h1 class="page-title">Product Variants</h1>
            <p class="page-description">
              Build sellable variants from a base product by combining attributes like Color, Storage or Size.
              The variant keeps the base product's structure — you only override what changes (SKU, barcode, price).
            </p>
          </div>
        </header>

        <!-- Tabs + Search + Create -->
        <div class="action-bar">
          <div class="filter-tabs">
            <button :class="['filter-tab', { active: activeTab === 'withVariants' }]" @click="activeTab = 'withVariants'">
              With Variants <span class="tab-count">{{ stats.withVar }}</span>
            </button>
            <button :class="['filter-tab', { active: activeTab === 'standalone' }]" @click="activeTab = 'standalone'">
              Zero Variants <span class="tab-count">{{ stats.standalone }}</span>
            </button>
            <button :class="['filter-tab', { active: activeTab === 'all' }]" @click="activeTab = 'all'">
              All Products <span class="tab-count">{{ baseProducts.length }}</span>
            </button>
          </div>

          <div class="action-bar-right">
            <div class="search-input-wrapper">
              <Search :size="18" class="search-icon" />
              <input v-model="searchQuery" type="text" placeholder="Search products or SKUs..." class="table-search" />
            </div>
            <button @click="openBuilder()" class="btn-create">
              <Plus :size="20" /><span>Create Variants</span>
            </button>
          </div>
        </div>

        <!-- Grouped list -->
        <div class="groups-wrapper">
          <div v-if="groupedProducts.length === 0" class="empty-state">
            <Layers :size="40" class="text-gray-300" />
            <p>No products in this view.</p>
            <button @click="openBuilder()" class="btn-create-sm"><Plus :size="16" /> Create Variants</button>
          </div>

          <div v-for="g in groupedProducts" :key="g.base.id" class="variant-group">
            <!-- Group header (base product) -->
            <div class="group-header" @click="g.children.length && toggleGroup(g.base.id)">
              <button v-if="g.children.length" class="chevron-btn" :class="{ open: expandedGroups[g.base.id] }">
                <ChevronRight :size="16" />
              </button>
              <span v-else class="chevron-spacer"></span>

              <div class="base-thumb" :style="{ backgroundColor: g.base.color }">
                <img v-if="primaryImg(g.base)" :src="primaryImg(g.base)" :alt="g.base.name" />
                <Box v-else :size="18" class="text-white" />
              </div>

              <div class="base-info">
                <div class="base-name-row">
                  <span class="base-name">{{ g.base.name }}</span>
                  <span class="base-code">{{ g.base.code }}</span>
                </div>
                <div class="base-meta">
                  <span class="meta-chip">{{ g.base.product_group }}</span>
                  <span class="meta-dot">·</span>
                  <span>{{ g.base.uom }}</span>
                  <span class="meta-dot">·</span>
                  <span>Base ${{ g.base.price.toLocaleString() }}</span>
                </div>
              </div>

              <!-- Attribute chips -->
              <div class="attr-chips">
                <span v-for="a in groupAttributes(g.children)" :key="a" class="attr-chip">
                  <Tag :size="11" /> {{ a }}
                </span>
              </div>

              <div class="group-right">
                <template v-if="g.children.length">
                  <span class="price-range">{{ priceRange(g.children) }}</span>
                  <span class="variant-count-badge">{{ g.children.length }} variant{{ g.children.length > 1 ? 's' : '' }}</span>
                </template>
                <span v-else class="no-variant-badge">No variants</span>

                <button class="btn-add-variant" @click.stop="openBuilder(g.base.id)" title="Add variants to this product">
                  <Plus :size="15" />
                </button>
              </div>
            </div>

            <!-- Variant rows -->
            <div v-if="g.children.length && expandedGroups[g.base.id]" class="variant-table-wrap">
              <table class="variant-table">
                <thead>
                  <tr>
                    <th>Variant</th>
                    <th>Attributes</th>
                    <th>SKU</th>
                    <th>Barcode</th>
                    <th width="110">Price</th>
                    <th width="110">Status</th>
                    <th width="60" class="text-center">Action</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="v in g.children" :key="v.id">
                    <td>
                      <div class="variant-name-cell">
                        <span class="swatch" :style="{ backgroundColor: v.color }"></span>
                        <span class="variant-name">{{ variantLabel(v.options) }}</span>
                      </div>
                    </td>
                    <td>
                      <div class="opt-chips">
                        <span v-for="o in v.options" :key="o.attribute" class="opt-chip">
                          <strong>{{ o.attribute }}:</strong> {{ o.value }}
                        </span>
                      </div>
                    </td>
                    <td class="mono">{{ v.sku }}</td>
                    <td class="mono text-gray-400">{{ v.barcode }}</td>
                    <td class="font-semibold">${{ v.price.toLocaleString() }}</td>
                    <td>
                      <span :class="['status-badge', v.status === 'Active' ? 'status-active' : 'status-inactive']">
                        <span class="dot"></span>{{ v.status }}
                      </span>
                    </td>
                    <td class="text-center">
                      <div class="action-menu-container">
                        <button @click="toggleActionMenu($event, v.id)" class="btn-three-dots"><MoreVertical :size="16" /></button>
                        <div v-if="activeActionMenuId === v.id" class="action-dropdown-menu" @click.stop>
                          <button @click="triggerView(v)" class="action-dropdown-item"><Eye :size="14" class="text-gray-500" /><span>View</span></button>
                          <button @click="editVariant(v)" class="action-dropdown-item"><Edit2 :size="14" class="text-gray-500" /><span>Edit</span></button>
                          <div class="dropdown-divider"></div>
                          <button @click="deleteVariant(v.id)" class="action-dropdown-item text-red"><Trash2 :size="14" /><span>Delete</span></button>
                        </div>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- ═══════════════ VARIANT BUILDER ═══════════════ -->
    <template v-else>
      <div class="builder-top-bar">
        <button @click="closeBuilder" class="btn-back"><ArrowLeft :size="16" /> Back to Variants</button>
        <div class="builder-actions">
          <button @click="closeBuilder" class="btn-modal-secondary">Cancel</button>
          <button @click="saveBuilder" class="btn-modal-primary">
            <Check :size="16" />
            {{ builderEditId !== null ? 'Save Variant' : `Save ${includedCount} Variant${includedCount !== 1 ? 's' : ''}` }}
          </button>
        </div>
      </div>

      <div class="builder-grid">
        <!-- LEFT: configuration -->
        <div class="builder-left">
          <!-- Step 1: Base product -->
          <section class="builder-section">
            <div class="section-title-row">
              <span class="step-badge">1</span>
              <h3>Base Product</h3>
            </div>
            <p class="section-hint">The variant inherits this product's group, UOM, brand and tax setup.</p>

            <select v-model="builderBaseId" class="form-select" :disabled="builderEditId !== null">
              <option value="" disabled>Select a base product…</option>
              <option v-for="b in baseProducts" :key="b.id" :value="b.id">{{ b.name }} ({{ b.code }})</option>
            </select>

            <!-- Inherited summary -->
            <div v-if="builderBase" class="inherited-card">
              <div class="inherited-head">
                <div class="base-thumb lg" :style="{ backgroundColor: builderBase.color }">
                  <img v-if="primaryImg(builderBase)" :src="primaryImg(builderBase)" :alt="builderBase.name" />
                  <Box v-else :size="20" class="text-white" />
                </div>
                <div>
                  <div class="inherited-name">{{ builderBase.name }}</div>
                  <div class="inherited-code">{{ builderBase.code }}</div>
                </div>
              </div>
              <div class="inherited-grid">
                <div><span class="il">Group</span><span class="iv">{{ builderBase.product_group }}</span></div>
                <div><span class="il">Unit</span><span class="iv">{{ builderBase.uom }}</span></div>
                <div><span class="il">Brand</span><span class="iv">{{ builderBase.brand }}</span></div>
                <div><span class="il">Base Price</span><span class="iv">${{ builderBase.price.toLocaleString() }}</span></div>
                <div><span class="il">Tax</span><span class="iv">{{ builderBase.is_tax_included ? 'Inclusive' : 'Exclusive' }}</span></div>
              </div>
              <div class="inherited-note"><Info :size="13" /> Inherited automatically — kept on every variant.</div>
            </div>
          </section>

          <!-- Step 2: Attributes -->
          <section class="builder-section" :class="{ disabled: !builderBase }">
            <div class="section-title-row">
              <span class="step-badge">2</span>
              <h3>Variant Attributes</h3>
            </div>
            <p class="section-hint">Pick the attributes that vary and tick the values. Combinations generate automatically.</p>

            <div v-for="(sel, idx) in selectedAttributes" :key="sel.id" class="attr-selector">
              <div class="attr-selector-head">
                <select v-model="sel.attribute" class="form-select attr-name-select">
                  <option value="" disabled>Choose attribute…</option>
                  <option v-if="sel.attribute" :value="sel.attribute">{{ sel.attribute }}</option>
                  <option v-for="a in availableAttributes" :key="a.name" :value="a.name">{{ a.name }}</option>
                </select>
                <button class="btn-row-delete" @click="removeAttributeSelector(idx)"><Trash2 :size="14" /></button>
              </div>
              <div v-if="sel.attribute" class="value-pills">
                <button
                  v-for="val in valuesForAttribute(sel.attribute)"
                  :key="val"
                  type="button"
                  :class="['value-pill', { selected: sel.values.includes(val) }]"
                  @click="toggleAttrValue(sel, val)"
                >
                  <Check v-if="sel.values.includes(val)" :size="12" />{{ val }}
                </button>
              </div>
            </div>

            <button
              v-if="builderBase && builderEditId === null && availableAttributes.length"
              class="btn-add-attr"
              @click="addAttributeSelector"
            >
              <Plus :size="15" /> Add Attribute
            </button>
          </section>
        </div>

        <!-- RIGHT: generated matrix -->
        <div class="builder-right">
          <section class="builder-section matrix-section">
            <div class="section-title-row matrix-head">
              <div class="flex items-center gap-2">
                <span class="step-badge">3</span>
                <h3>{{ builderEditId !== null ? 'Variant Detail' : 'Generated Variants' }}</h3>
              </div>
              <div class="matrix-head-right">
                <span v-if="draftRows.length" class="matrix-count">
                  {{ includedCount }} / {{ draftRows.length }} included
                </span>
                <button v-if="builderEditId === null" class="btn-regen" @click="generateMatrix" title="Regenerate matrix">
                  <RefreshCw :size="14" /> Regenerate
                </button>
              </div>
            </div>
            <p class="section-hint">Override only what changes per variant. Untouched fields stay at the base value.</p>

            <div v-if="draftRows.length === 0" class="matrix-empty">
              <Sparkles :size="34" class="text-gray-300" />
              <p>Pick attributes and values on the left to generate the variant matrix.</p>
            </div>

            <div v-else class="matrix-table-wrap">
              <table class="matrix-table">
                <thead>
                  <tr>
                    <th v-if="builderEditId === null" width="40" class="text-center">
                      <Check :size="13" />
                    </th>
                    <th>Variant</th>
                    <th width="150">SKU</th>
                    <th width="140">Barcode</th>
                    <th width="110">Price</th>
                    <th width="70">Color</th>
                    <th width="110">Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="row in draftRows" :key="row.key" :class="{ excluded: !row.include }">
                    <td v-if="builderEditId === null" class="text-center">
                      <input type="checkbox" v-model="row.include" class="row-check" />
                    </td>
                    <td>
                      <div class="opt-chips">
                        <span v-for="o in row.options" :key="o.attribute" class="opt-chip">{{ o.value }}</span>
                      </div>
                    </td>
                    <td class="p-1"><input v-model="row.sku" class="cell-input mono" placeholder="SKU" /></td>
                    <td class="p-1"><input v-model="row.barcode" class="cell-input mono" placeholder="Barcode" /></td>
                    <td class="p-1">
                      <div class="price-input-wrap">
                        <span class="price-prefix">$</span>
                        <input v-model.number="row.price" type="number" min="0" class="cell-input price-input" />
                      </div>
                    </td>
                    <td class="text-center p-1">
                      <input type="color" v-model="row.color" class="color-input" />
                    </td>
                    <td class="p-1">
                      <select v-model="row.status" class="cell-input cell-select">
                        <option value="Active">Active</option>
                        <option value="Inactive">Inactive</option>
                      </select>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
        </div>
      </div>
    </template>

    <!-- VIEW MODAL -->
    <div v-if="showViewModal" class="modal-overlay" @click.self="showViewModal = false">
      <div class="modal-card">
        <button class="modal-close-btn" @click="showViewModal = false"><X :size="18" /></button>
        <header class="modal-card-header"><h3>Variant Details</h3></header>
        <div class="modal-body-content" v-if="viewVariant">
          <div class="view-variant-head">
            <span class="swatch lg" :style="{ backgroundColor: viewVariant.color }"></span>
            <div>
              <div class="view-variant-name">{{ viewVariant.name }}</div>
              <div class="view-variant-base">Base: {{ baseById(viewVariant.parent_id)?.name || '—' }}</div>
            </div>
          </div>
          <div class="view-grid">
            <div class="detail-item"><span class="detail-label">Variant Code</span><span class="detail-value mono">{{ viewVariant.code }}</span></div>
            <div class="detail-item"><span class="detail-label">SKU</span><span class="detail-value mono">{{ viewVariant.sku }}</span></div>
            <div class="detail-item"><span class="detail-label">Barcode</span><span class="detail-value mono">{{ viewVariant.barcode }}</span></div>
            <div class="detail-item"><span class="detail-label">Price</span><span class="detail-value">${{ viewVariant.price.toLocaleString() }}</span></div>
            <div class="detail-item"><span class="detail-label">Status</span>
              <span :class="['status-badge mt-1', viewVariant.status === 'Active' ? 'status-active' : 'status-inactive']">
                <span class="dot"></span>{{ viewVariant.status }}
              </span>
            </div>
          </div>
          <div class="view-options">
            <span class="detail-label">Attribute Options</span>
            <div class="opt-chips mt-2">
              <span v-for="o in viewVariant.options" :key="o.attribute" class="opt-chip">
                <strong>{{ o.attribute }}:</strong> {{ o.value }}
              </span>
            </div>
          </div>
        </div>
        <div class="modal-footer-row">
          <button @click="showViewModal = false" class="btn-modal-primary full-width">Close</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.variants-page {
  animation: fadeIn 0.4s ease-out;
  display: flex; flex-direction: column; gap: 16px;
  font-family: 'Inter', sans-serif;
}
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

/* Breadcrumbs */
.breadcrumbs { display: flex; align-items: center; gap: 8px; font-size: 13px; }
.breadcrumb-link { color: #9ca3af; text-decoration: none; display: flex; align-items: center; }
.breadcrumb-link:hover { color: #111827; }
.breadcrumb-link-text { color: #6b7280; text-decoration: none; font-weight: 500; }
.breadcrumb-link-text:hover { color: #111827; }
.breadcrumb-separator { color: #9ca3af; }
.breadcrumb-active { color: #111827; font-weight: 600; }

/* Stat cards */
.stats-row { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; }
.stat-card {
  background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 16px 18px;
  display: flex; align-items: center; gap: 14px; box-shadow: 0 1px 3px rgba(0,0,0,0.02);
}
.stat-icon { width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.stat-value { font-size: 22px; font-weight: 700; color: #111827; line-height: 1.1; }
.stat-label { font-size: 12px; color: #6b7280; margin-top: 2px; }

/* Content card */
.content-card { background: #fff; border: 1px solid #e5e7eb; border-radius: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.02); overflow: visible; }
.page-header { padding: 22px 24px 6px 24px; }
.page-title { font-size: 22px; font-weight: 700; color: #111827; margin-bottom: 6px; }
.page-description { font-size: 13.5px; color: #6b7280; line-height: 1.6; max-width: 760px; }

/* Action bar */
.action-bar { display: flex; align-items: center; justify-content: space-between; padding: 16px 24px; gap: 16px; flex-wrap: wrap; }
.filter-tabs { display: inline-flex; background: #f3f4f6; padding: 4px; border-radius: 10px; gap: 2px; }
.filter-tab {
  display: flex; align-items: center; gap: 7px; padding: 7px 14px; border: none; background: transparent;
  border-radius: 8px; font-size: 13px; font-weight: 600; color: #6b7280; cursor: pointer; transition: all 0.15s;
}
.filter-tab:hover { color: #111827; }
.filter-tab.active { background: #fff; color: #111827; box-shadow: 0 1px 2px rgba(0,0,0,0.06); }
.tab-count { background: #e5e7eb; color: #4b5563; font-size: 11px; padding: 1px 7px; border-radius: 10px; font-weight: 700; }
.filter-tab.active .tab-count { background: var(--alias-color-brand-blue-primary, #2563eb); color: #fff; }

.action-bar-right { display: flex; align-items: center; gap: 12px; }
.search-input-wrapper { position: relative; width: 260px; }
.search-icon { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #9ca3af; }
.table-search {
  width: 100%; padding: 10px 12px 10px 40px; border: 1px solid #e5e7eb; border-radius: 10px;
  font-size: 14px; outline: none; height: 42px; background: #fff; transition: all 0.2s;
}
.table-search:focus { border-color: #d1d5db; box-shadow: 0 0 0 4px rgba(0,0,0,0.02); }

.btn-create {
  display: flex; align-items: center; gap: 8px; padding: 0 18px; height: 42px;
  background: var(--alias-color-brand-blue-primary, #2563eb); color: #fff; border: none; border-radius: 10px;
  font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.2s; white-space: nowrap;
}
.btn-create:hover { background: var(--alias-color-brand-blue-primary-hover, #1d4ed8); transform: translateY(-1px); }
.btn-create-sm {
  display: inline-flex; align-items: center; gap: 6px; padding: 8px 14px; margin-top: 12px;
  background: var(--alias-color-brand-blue-primary, #2563eb); color: #fff; border: none; border-radius: 8px;
  font-size: 13px; font-weight: 600; cursor: pointer;
}

/* Groups */
.groups-wrapper { border-top: 1px solid #e5e7eb; padding: 12px; display: flex; flex-direction: column; gap: 12px; }
.empty-state { display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 48px; color: #9ca3af; font-size: 14px; }

.variant-group { border: 1px solid #e5e7eb; border-radius: 12px; overflow: hidden; transition: box-shadow 0.2s; }
.variant-group:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.04); }

.group-header { display: flex; align-items: center; gap: 12px; padding: 12px 16px; cursor: pointer; background: #fff; }
.group-header:hover { background: #fafafa; }
.chevron-btn { background: none; border: none; color: #9ca3af; cursor: pointer; display: flex; padding: 2px; transition: transform 0.2s; }
.chevron-btn.open { transform: rotate(90deg); }
.chevron-spacer { width: 20px; flex-shrink: 0; }

.base-thumb {
  width: 38px; height: 38px; border-radius: 9px; flex-shrink: 0; overflow: hidden;
  display: flex; align-items: center; justify-content: center;
}
.base-thumb img { width: 100%; height: 100%; object-fit: cover; }
.base-thumb.lg { width: 48px; height: 48px; border-radius: 11px; }

.base-info { min-width: 180px; }
.base-name-row { display: flex; align-items: center; gap: 8px; }
.base-name { font-size: 14px; font-weight: 600; color: #111827; }
.base-code { font-size: 11px; color: #9ca3af; background: #f3f4f6; padding: 1px 7px; border-radius: 6px; font-weight: 600; }
.base-meta { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #6b7280; margin-top: 3px; }
.meta-chip { background: #eff6ff; color: #2563eb; padding: 1px 8px; border-radius: 6px; font-weight: 600; font-size: 11px; }
.meta-dot { color: #d1d5db; }

.attr-chips { display: flex; flex-wrap: wrap; gap: 6px; flex: 1; justify-content: center; }
.attr-chip {
  display: inline-flex; align-items: center; gap: 4px; background: #f8fafc; border: 1px solid #e2e8f0;
  color: #475569; padding: 3px 9px; border-radius: 20px; font-size: 11px; font-weight: 600;
}

.group-right { display: flex; align-items: center; gap: 12px; margin-left: auto; }
.price-range { font-size: 13px; font-weight: 600; color: #374151; white-space: nowrap; }
.variant-count-badge { background: #eef2ff; color: #4338ca; padding: 4px 11px; border-radius: 20px; font-size: 12px; font-weight: 700; white-space: nowrap; }
.no-variant-badge { background: #fff7ed; color: #c2410c; padding: 4px 11px; border-radius: 20px; font-size: 12px; font-weight: 600; }
.btn-add-variant {
  width: 32px; height: 32px; border-radius: 8px; border: 1px solid #e5e7eb; background: #fff; color: #2563eb;
  display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.15s;
}
.btn-add-variant:hover { background: var(--alias-color-brand-blue-primary, #2563eb); color: #fff; border-color: transparent; }

/* Variant table */
.variant-table-wrap { border-top: 1px solid #f1f5f9; background: #fcfcfd; overflow-x: auto; }
.variant-table { width: 100%; border-collapse: collapse; }
.variant-table th {
  text-align: left; padding: 10px 16px; font-size: 11.5px; font-weight: 600; color: #6b7280;
  background: #f9fafb; border-bottom: 1px solid #f1f5f9; text-transform: uppercase; letter-spacing: 0.03em;
}
.variant-table td { padding: 11px 16px; font-size: 13px; color: #374151; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
.variant-table tr:last-child td { border-bottom: none; }
.variant-table tr:hover td { background: #f8fafc; }

.variant-name-cell { display: flex; align-items: center; gap: 9px; }
.swatch { width: 16px; height: 16px; border-radius: 5px; border: 1px solid rgba(0,0,0,0.1); flex-shrink: 0; }
.swatch.lg { width: 36px; height: 36px; border-radius: 9px; }
.variant-name { font-weight: 600; color: #111827; }
.mono { font-family: 'SF Mono', 'Roboto Mono', monospace; font-size: 12px; }

.opt-chips { display: flex; flex-wrap: wrap; gap: 5px; }
.opt-chip { background: #f1f5f9; color: #475569; padding: 2px 9px; border-radius: 6px; font-size: 11.5px; font-weight: 500; }
.opt-chip strong { color: #334155; font-weight: 700; }

.status-badge { display: inline-flex; align-items: center; gap: 6px; padding: 3px 11px; border-radius: 20px; font-size: 12px; font-weight: 500; }
.status-active { background: #ecfdf5; color: #059669; }
.status-active .dot { background: #10b981; }
.status-inactive { background: #f3f4f6; color: #6b7280; }
.status-inactive .dot { background: #9ca3af; }
.dot { width: 6px; height: 6px; border-radius: 50%; }

/* Action dropdown */
.action-menu-container { position: relative; display: inline-block; }
.btn-three-dots { background: none; border: none; color: #9ca3af; cursor: pointer; padding: 6px; border-radius: 8px; display: flex; }
.btn-three-dots:hover { background: #f3f4f6; color: #111827; }
.action-dropdown-menu {
  position: absolute; top: 100%; right: 0; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px;
  box-shadow: 0 10px 25px -5px rgba(0,0,0,0.08); z-index: 999; min-width: 140px; padding: 6px;
  display: flex; flex-direction: column; gap: 2px; animation: dropFade 0.15s ease-out;
}
@keyframes dropFade { from { opacity: 0; transform: translateY(-5px); } to { opacity: 1; transform: translateY(0); } }
.action-dropdown-item {
  display: flex; align-items: center; gap: 8px; padding: 8px 12px; font-size: 13px; color: #475569;
  background: none; border: none; border-radius: 6px; cursor: pointer; text-align: left; width: 100%;
}
.action-dropdown-item:hover { background: #f1f5f9; color: #0f172a; }
.dropdown-divider { height: 1px; background: #f1f5f9; margin: 4px 6px; }
.action-dropdown-item.text-red { color: #ef4444; }
.action-dropdown-item.text-red:hover { background: #fef2f2; color: #dc2626; }

/* ═══════ BUILDER ═══════ */
.builder-top-bar {
  display: flex; align-items: center; justify-content: space-between;
  background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 12px 18px;
}
.btn-back {
  display: flex; align-items: center; gap: 8px; background: none; border: none; color: #475569;
  font-size: 14px; font-weight: 600; cursor: pointer; padding: 6px 8px; border-radius: 8px;
}
.btn-back:hover { background: #f3f4f6; color: #111827; }
.builder-actions { display: flex; gap: 10px; }

.builder-grid { display: grid; grid-template-columns: 420px 1fr; gap: 16px; align-items: start; }
.builder-left { display: flex; flex-direction: column; gap: 16px; }
.builder-section { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 20px; }
.builder-section.disabled { opacity: 0.5; pointer-events: none; }
.section-title-row { display: flex; align-items: center; gap: 10px; }
.step-badge {
  width: 24px; height: 24px; border-radius: 7px; background: var(--alias-color-brand-blue-primary, #2563eb); color: #fff;
  display: flex; align-items: center; justify-content: center; font-size: 13px; font-weight: 700; flex-shrink: 0;
}
.section-title-row h3 { font-size: 15px; font-weight: 700; color: #111827; margin: 0; }
.section-hint { font-size: 12.5px; color: #6b7280; margin: 8px 0 14px 0; line-height: 1.5; }

.form-select {
  width: 100%; padding: 10px 12px; border: 1px solid #e5e7eb; border-radius: 9px; font-size: 14px;
  outline: none; background: #fff; transition: all 0.15s;
}
.form-select:focus { border-color: #111827; }
.form-select:disabled { background: #f9fafb; color: #6b7280; }

/* Inherited card */
.inherited-card { margin-top: 14px; border: 1px solid #e2e8f0; border-radius: 12px; padding: 14px; background: #f8fafc; }
.inherited-head { display: flex; align-items: center; gap: 12px; margin-bottom: 14px; }
.inherited-name { font-size: 14px; font-weight: 700; color: #111827; }
.inherited-code { font-size: 12px; color: #9ca3af; }
.inherited-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px 14px; }
.inherited-grid > div { display: flex; flex-direction: column; gap: 2px; }
.il { font-size: 10.5px; font-weight: 700; color: #9ca3af; text-transform: uppercase; letter-spacing: 0.04em; }
.iv { font-size: 13px; color: #334155; font-weight: 600; }
.inherited-note {
  display: flex; align-items: center; gap: 6px; margin-top: 14px; padding-top: 12px;
  border-top: 1px dashed #e2e8f0; font-size: 11.5px; color: #2563eb;
}

/* Attribute selectors */
.attr-selector { border: 1px solid #e5e7eb; border-radius: 11px; padding: 12px; margin-bottom: 12px; }
.attr-selector-head { display: flex; align-items: center; gap: 8px; }
.attr-name-select { flex: 1; }
.value-pills { display: flex; flex-wrap: wrap; gap: 7px; margin-top: 12px; }
.value-pill {
  display: inline-flex; align-items: center; gap: 5px; padding: 5px 12px; border: 1px solid #e5e7eb;
  background: #fff; border-radius: 20px; font-size: 12.5px; font-weight: 600; color: #475569; cursor: pointer; transition: all 0.15s;
}
.value-pill:hover { border-color: #93c5fd; }
.value-pill.selected { background: var(--alias-color-brand-blue-primary, #2563eb); color: #fff; border-color: transparent; }
.btn-add-attr {
  display: inline-flex; align-items: center; gap: 7px; padding: 9px 14px; width: 100%; justify-content: center;
  border: 1.5px dashed #cbd5e1; background: #f8fafc; color: #475569; border-radius: 10px;
  font-size: 13px; font-weight: 600; cursor: pointer; transition: all 0.15s;
}
.btn-add-attr:hover { border-color: #93c5fd; color: #2563eb; background: #eff6ff; }
.btn-row-delete { padding: 8px; background: none; border: none; color: #f87171; border-radius: 7px; cursor: pointer; }
.btn-row-delete:hover { background: #fef2f2; color: #dc2626; }

/* Matrix */
.builder-right { position: sticky; top: 0; }
.matrix-section { padding: 20px; }
.matrix-head { justify-content: space-between; }
.matrix-head-right { display: flex; align-items: center; gap: 10px; }
.matrix-count { font-size: 12px; font-weight: 600; color: #4338ca; background: #eef2ff; padding: 4px 11px; border-radius: 20px; }
.btn-regen {
  display: inline-flex; align-items: center; gap: 6px; padding: 6px 12px; border: 1px solid #e5e7eb;
  background: #fff; color: #475569; border-radius: 8px; font-size: 12.5px; font-weight: 600; cursor: pointer;
}
.btn-regen:hover { background: #f8fafc; color: #111827; }

.matrix-empty { display: flex; flex-direction: column; align-items: center; gap: 10px; padding: 60px 20px; color: #9ca3af; font-size: 13.5px; text-align: center; }
.matrix-table-wrap { border: 1px solid #e5e7eb; border-radius: 11px; overflow: auto; max-height: 62vh; }
.matrix-table { width: 100%; border-collapse: collapse; }
.matrix-table th {
  text-align: left; padding: 10px 12px; font-size: 11px; font-weight: 700; color: #6b7280;
  background: #f9fafb; border-bottom: 1px solid #e5e7eb; position: sticky; top: 0; z-index: 1;
  text-transform: uppercase; letter-spacing: 0.03em;
}
.matrix-table td { padding: 8px 12px; font-size: 13px; color: #374151; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
.matrix-table tr.excluded { opacity: 0.45; background: #fafafa; }
.matrix-table tr:hover td { background: #fcfcfd; }
.matrix-table td.p-1 { padding: 5px 8px; }
.row-check { width: 16px; height: 16px; accent-color: var(--alias-color-brand-blue-primary, #2563eb); cursor: pointer; }

.cell-input {
  width: 100%; padding: 7px 9px; border: 1px solid #e5e7eb; border-radius: 7px; font-size: 12.5px;
  outline: none; background: #fff; transition: all 0.15s;
}
.cell-input:focus { border-color: #2563eb; box-shadow: 0 0 0 3px rgba(37,99,235,0.08); }
.cell-select { cursor: pointer; }
.price-input-wrap { position: relative; display: flex; align-items: center; }
.price-prefix { position: absolute; left: 9px; color: #9ca3af; font-size: 12.5px; }
.price-input { padding-left: 20px; }
.color-input { width: 34px; height: 30px; border: 1px solid #e5e7eb; border-radius: 7px; padding: 2px; cursor: pointer; background: #fff; }

/* Modal */
.modal-overlay {
  position: fixed; inset: 0; background: rgba(15,23,42,0.4); backdrop-filter: blur(4px);
  z-index: 1100; display: flex; align-items: center; justify-content: center; padding: 20px;
}
.modal-card {
  background: #fff; border-radius: 16px; width: 100%; max-width: 520px; padding: 24px;
  box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1); position: relative; display: flex; flex-direction: column;
}
.modal-close-btn { position: absolute; top: 20px; right: 20px; background: none; border: none; color: #94a3b8; cursor: pointer; padding: 6px; border-radius: 50%; display: flex; }
.modal-close-btn:hover { background: #f1f5f9; color: #475569; }
.modal-card-header h3 { font-size: 18px; font-weight: 700; color: #0f172a; margin-bottom: 20px; }
.modal-body-content { overflow-y: auto; }

.view-variant-head { display: flex; align-items: center; gap: 14px; margin-bottom: 20px; }
.view-variant-name { font-size: 16px; font-weight: 700; color: #111827; }
.view-variant-base { font-size: 12.5px; color: #6b7280; margin-top: 2px; }
.view-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; margin-bottom: 18px; }
.detail-item { display: flex; flex-direction: column; gap: 4px; }
.detail-label { font-size: 11px; font-weight: 700; color: #9ca3af; text-transform: uppercase; letter-spacing: 0.05em; }
.detail-value { font-size: 14px; color: #334155; }
.view-options { border-top: 1px solid #f1f5f9; padding-top: 16px; }

.modal-footer-row { display: flex; gap: 12px; margin-top: 24px; }
.btn-modal-primary, .btn-modal-secondary {
  display: inline-flex; align-items: center; justify-content: center; gap: 7px;
  padding: 10px 18px; border-radius: 9px; font-size: 13.5px; font-weight: 600; cursor: pointer; transition: all 0.2s;
}
.btn-modal-primary { background: var(--alias-color-brand-blue-primary, #2563eb); color: #fff; border: none; }
.btn-modal-primary:hover { background: var(--alias-color-brand-blue-primary-hover, #1d4ed8); }
.btn-modal-secondary { background: #fff; color: #475569; border: 1px solid #e2e8f0; }
.btn-modal-secondary:hover { background: #f8fafc; }
.full-width { flex: 1; width: 100%; }

.mt-1 { margin-top: 4px; }
.mt-2 { margin-top: 8px; }
.flex { display: flex; }
.items-center { align-items: center; }
.gap-2 { gap: 8px; }
.text-white { color: #fff; }
.text-gray-300 { color: #d1d5db; }
.text-gray-400 { color: #9ca3af; }
.text-gray-500 { color: #6b7280; }
.font-semibold { font-weight: 600; }
.text-center { text-align: center; }

@media (max-width: 1100px) {
  .builder-grid { grid-template-columns: 1fr; }
  .builder-right { position: static; }
  .stats-row { grid-template-columns: 1fr; }
}
</style>
