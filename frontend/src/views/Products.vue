<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { 
  Monitor, Plus, Search, ChevronRight, HelpCircle,
  X, Check, Lock, Edit2, Trash2, MoreVertical, Eye,
  Filter, ArrowUpDown, RefreshCw, Columns, Maximize2, ChevronDown,
  ArrowLeft, ArrowRight, Expand, ExternalLink, Info, GitBranch,
  FileText, Scale, CreditCard, Box, TrendingUp, Percent, Trash, Upload, Play, Sliders,
  MapPin, ArrowRightLeft
} from 'lucide-vue-next';
import BaseTabs from '../components/BaseTabs.vue';
import BaseButton from '../components/BaseButton.vue';
import AppBreadcrumb from '../components/AppBreadcrumb.vue';
import SaveStateBadge from '../components/SaveStateBadge.vue';

// Routing
const router = useRouter();

// Active tab inside the create/edit form
const activeTab = ref('Basic');
const tabs = [
  { id: 'Basic', label: 'Basic', icon: Info },
  { id: 'Combo Config', label: 'Combo Config', icon: GitBranch },
  { id: 'Product Detail', label: 'Product Detail', icon: FileText },
  { id: 'UOM', label: 'UOM', icon: Scale },
  { id: 'Pricing', label: 'Pricing', icon: CreditCard },
  { id: 'Inventory', label: 'Inventory', icon: Box },
  { id: 'Sales', label: 'Sales', icon: TrendingUp },
  { id: 'Tax', label: 'Tax', icon: Percent }
];

// Product Data State
const products = ref([
  {
    id: 1,
    code: 'PD0001',
    sku: 'IP17P-256',
    color: '#1d4ed8',
    name: 'iPhone 17 Pro',
    item_category: 'Electronics',
    brand_ids: [1],
    has_alternative: false,
    is_tax_included: false,
    alternatives: [],
    modifiers: [],
    product_tax_rates: [{ id: 101, tax_type_id: 1, tax_rate_id: 1 }],
    entity_ids: [1, 2],
    product_group: 'Smartphones',
    product_type: 'Direct Sales',
    uom: 'Pcs',
    is_trackable: 'Yes',
    status: 'Active',
    description: 'The latest iPhone 17 Pro with titanium design and advanced camera systems.',
    price: 1299,
    item_ref: '',
    is_fixed_asset: false,
    apply_to_variants: false,
    is_variants: true,
    parent_product: 'iPhone 17 Base',
    media: [
      { id: 1, url: 'https://assets.mixkit.co/videos/preview/mixkit-holding-a-gold-smartphone-40348-large.mp4', thumbnail: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?q=80&w=600&auto=format&fit=crop', type: 'video', isPrimary: true },
      { id: 2, url: 'https://assets.mixkit.co/videos/preview/mixkit-working-with-a-smartphone-40332-large.mp4', thumbnail: 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?q=80&w=200&auto=format&fit=crop', type: 'video', isPrimary: false },
      { id: 3, url: 'https://assets.mixkit.co/videos/preview/mixkit-rotating-smartphone-mockup-41586-large.mp4', thumbnail: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=200&auto=format&fit=crop', type: 'video', isPrimary: false }
    ],
    combo_items: [],
    sku_attributes: 'Color: Desert Titanium, Storage: 256GB'
  },
  {
    id: 2,
    code: 'AP2032',
    sku: 'APL-RED-01',
    color: '#16a34a',
    name: 'Apple',
    item_category: 'Fruits',
    brand_ids: [5],
    has_alternative: true,
    is_tax_included: true,
    alternatives: [],
    modifiers: [],
    product_tax_rates: [],
    entity_ids: [],
    product_group: 'Fruits',
    product_type: 'Combo',
    uom: 'Pcs',
    is_trackable: 'Yes',
    status: 'Active',
    description: 'Fresh organic apples, crispy and sweet.',
    price: 1.50,
    item_ref: '',
    is_fixed_asset: false,
    apply_to_variants: false,
    is_variants: false,
    parent_product: '',
    media: [
      { id: 1, url: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?q=80&w=600&auto=format&fit=crop', isPrimary: true }
    ],
    combo_items: [
      { name: 'Red Gala Apple', qty: 3, uom: 'Pcs' },
      { name: 'Green Granny Smith', qty: 2, uom: 'Pcs' }
    ],
    sku_attributes: ''
  },
  {
    id: 3,
    code: 'BP0008',
    sku: 'SKU008',
    color: '#7c3aed',
    name: 'Travel Backpack',
    item_category: 'Apparel',
    brand_ids: [7],
    has_alternative: false,
    is_tax_included: false,
    alternatives: [],
    modifiers: [],
    product_tax_rates: [],
    entity_ids: [],
    product_group: 'Apparel',
    product_type: 'Direct Sales',
    uom: 'Pcs',
    is_trackable: 'Yes',
    status: 'Active',
    description: 'Durable 30L travel backpack with padded laptop compartment.',
    price: 79.99,
    item_ref: '',
    is_fixed_asset: false,
    apply_to_variants: false,
    is_variants: false,
    parent_product: '',
    media: [
      { id: 1, url: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?q=80&w=600&auto=format&fit=crop', isPrimary: true }
    ],
    combo_items: [],
    sku_attributes: '',
    // Seeded stock so the Stock by Location list is populated when editing this product
    stock_levels: [
      { id: 301, location: 'Main Warehouse', current_qty: 121, reserved_qty: 0, available_qty: 121, selected: false },
      { id: 302, location: 'Retail Store', current_qty: 8, reserved_qty: 28, available_qty: -20, selected: false },
      { id: 303, location: 'Transit Location', current_qty: 45, reserved_qty: 5, available_qty: 40, selected: false }
    ]
  }
]);

// Lists for Dropdowns
const productGroups = ref([
  { id: 1, name: 'Smartphones' },
  { id: 2, name: 'Fruits' },
  { id: 3, name: 'Electronics' },
  { id: 4, name: 'Groceries' },
  { id: 5, name: 'Apparel' }
]);

const uomList = ref([
  { id: 1, name: 'Pcs' },
  { id: 2, name: 'Box' },
  { id: 3, name: 'Kg' },
  { id: 4, name: 'Liters' },
  { id: 5, name: 'Meters' },
  { id: 6, name: 'Kilogram (KG)' },
  { id: 7, name: 'Pack' },
  { id: 8, name: 'Piece' },
  { id: 9, name: 'Gram (g)' },
  { id: 10, name: 'Milligram (mg)' }
]);

const productTypes = ['Direct Sales', 'Combo', 'Service', 'Manufactured'];
const itemList = ['iPhone 17 Pro', 'Apple', 'Banana', 'Samsung Galaxy', 'Dell Laptop'];
// Parent products available for variant inheritance.
// `apply_to_variants` drives the confirmation + locking behaviour when this
// parent is selected for a variant product:
//   true  -> STRICT: variant inherits & locks everything except Product
//            Attribute Values + a Variant Price Override.
//   false -> SOFT: parent values pre-fill as defaults; variant can change them.
const parentProductsData = [
  {
    id: 9001, name: 'iPhone 17 Base', code: 'PRNT-IP17', sku: 'IP17-BASE',
    apply_to_variants: true,                 // STRICT parent
    product_group: 'Smartphones', item_category: 'Electronics', brand_ids: [1],
    product_type: 'Direct Sales', uom: 'Pcs', price: 1299, is_tax_included: false,
    tax_rate: 15, track_stock: true, track_batch: false, track_expiry: false,
    costing_rule: 'FIFO', business_usage: 'Both Sales and Purchase' as const,
    attributes: [
      { id: 91001, type: 'Storage', color: '0B529C', sizes: ['256GB', '512GB', '1TB'], newSize: '' }
    ]
  },
  {
    id: 9002, name: 'Apple Fruit Bundle', code: 'PRNT-APLB', sku: 'APLB-BASE',
    apply_to_variants: false,                // SOFT parent
    product_group: 'Fresh Produce', item_category: 'Fruits', brand_ids: [5],
    product_type: 'Direct Sales', uom: 'Kg', price: 4.5, is_tax_included: true,
    tax_rate: 0, track_stock: false, track_batch: false, track_expiry: true,
    costing_rule: 'Average', business_usage: 'Sales' as const,
    attributes: []
  }
];

// --- Brand (Brand / ItemCategoryBrand / ProductBrand) ---
// item_category_id on each brand simulates ItemCategoryBrand: which brands are allowed per category.
const brandList = ref([
  { id: 1, name: 'Apple', code: 'APL', item_category_id: 1 },
  { id: 2, name: 'Samsung', code: 'SAM', item_category_id: 1 },
  { id: 3, name: 'Dell', code: 'DEL', item_category_id: 1 },
  { id: 4, name: 'Sony', code: 'SNY', item_category_id: 1 },
  { id: 5, name: 'Organic Farms', code: 'ORG', item_category_id: 2 },
  { id: 6, name: 'Fresh Valley', code: 'FRV', item_category_id: 2 },
  { id: 7, name: 'Generic', code: 'GEN', item_category_id: null }
]);

// ItemCategory — used to restrict available brands (ItemCategoryBrand)
const itemCategoryList = ref([
  { id: 1, name: 'Electronics' },
  { id: 2, name: 'Fruits' },
  { id: 3, name: 'Apparel' }
]);

// TaxType table (instead of hardcoded strings)
const taxTypeList = ref([
  { id: 1, code: 'VAT', name: 'VAT' },
  { id: 2, code: 'EXCISE', name: 'Excise' },
  { id: 3, code: 'TOT', name: 'Turnover Tax' },
  { id: 4, code: 'SURTAX', name: 'Surtax' }
]);

// TaxRate table — rows belong to a TaxType. harmonization_code lives here (nullable, for Excise).
const taxRateList = ref([
  { id: 1, tax_type_id: 1, rate_percent: 15, harmonization_code: null as string | null },
  { id: 2, tax_type_id: 1, rate_percent: 0, harmonization_code: null as string | null },
  { id: 3, tax_type_id: 2, rate_percent: 10, harmonization_code: 'HP2344vt5b' as string | null },
  { id: 4, tax_type_id: 2, rate_percent: 30, harmonization_code: 'HP9981xx2a' as string | null },
  { id: 5, tax_type_id: 3, rate_percent: 2, harmonization_code: null as string | null },
  { id: 6, tax_type_id: 4, rate_percent: 10, harmonization_code: null as string | null }
]);

// Entities / branches (EntityProduct)
const entityList = ref([
  { id: 1, name: 'Main Branch' },
  { id: 2, name: 'Downtown Store' },
  { id: 3, name: 'Airport Kiosk' },
  { id: 4, name: 'Online Shop' }
]);

// Brands restricted by the product's selected item category (ItemCategoryBrand).
// Brands with no category (e.g. Generic) are always available.
const availableBrands = computed(() => {
  const cat = itemCategoryList.value.find(c => c.name === formState.value.item_category);
  if (!cat) return brandList.value;
  return brandList.value.filter(b => b.item_category_id === cat.id || b.item_category_id === null);
});

const toggleBrand = (brandId: number) => {
  const i = formState.value.brand_ids.indexOf(brandId);
  if (i === -1) formState.value.brand_ids.push(brandId);
  else formState.value.brand_ids.splice(i, 1);
};

const brandNames = (ids: number[]) =>
  ids.map(id => brandList.value.find(b => b.id === id)?.name).filter(Boolean).join(', ');

// Tax rows for the selected TaxType (TaxType -> TaxRate)
const ratesForType = (taxTypeId: number | null) =>
  taxRateList.value.filter(r => r.tax_type_id === taxTypeId);

const addProductTaxRate = () => {
  formState.value.product_tax_rates.push({ id: Date.now() + Math.random(), tax_type_id: null, tax_rate_id: null });
};
const removeProductTaxRate = (idx: number) => formState.value.product_tax_rates.splice(idx, 1);

const taxRateRow = (rateId: number | null) => taxRateList.value.find(r => r.id === rateId) || null;

// ProductAlternative (product-level substitutes for sales/procurement)
const addAlternativeRow = () => {
  formState.value.alternatives.push({ id: Date.now() + Math.random(), product: '' });
};
const removeAlternativeRow = (idx: number) => formState.value.alternatives.splice(idx, 1);

// ProductModifier / ProductModifierItem (POS hospitality add-ons)
const addModifierRow = () => {
  formState.value.modifiers.push({ id: Date.now() + Math.random(), name: '', added_product: '' });
};
const removeModifierRow = (idx: number) => formState.value.modifiers.splice(idx, 1);

// EntityProduct (which branches sell this product)
const toggleEntity = (entityId: number) => {
  const i = formState.value.entity_ids.indexOf(entityId);
  if (i === -1) formState.value.entity_ids.push(entityId);
  else formState.value.entity_ids.splice(i, 1);
};

// Interactive UI State
const activeActionMenuId = ref<number | null>(null);
const showFullForm = ref(false);
const isSaved = ref(false);
const editMode = ref(false);
const selectedId = ref<number | null>(null);
const isFullscreen = ref(false);

// Pagination & Search
const searchQuery = ref('');
const currentPage = ref(1);
const perPage = ref(10);
const showColumnsDropdown = ref(false);

// Form State
const formState = ref({
  name: '',
  code: '',
  sku: '',
  color: '#0b529c',
  product_group: '',
  item_category: '',
  item_ref: '',
  brand_ids: [] as number[],
  has_alternative: false,
  product_type: 'Direct Sales',
  uom: '',
  is_fixed_asset: false,
  apply_to_variants: false,
  is_variants: false,
  parent_product: '',
  description: '',
  price: 0,
  is_tax_included: false,
  tax_rate: 15,
  warehouse: 'Main Warehouse',
  alternatives: [] as Array<{ id: number; product: string }>,
  modifiers: [] as Array<{ id: number; name: string; added_product: string }>,
  product_tax_rates: [] as Array<{ id: number; tax_type_id: number | null; tax_rate_id: number | null }>,
  entity_ids: [] as number[],
  media: [] as Array<{ id: number; url: string; thumbnail?: string; type: 'image' | 'video'; isPrimary: boolean }>,
  combo_items: [] as Array<{ name: string; qty: number; uom: string }>,
  uom_conversions: [] as Array<{ id: number; unit: string; rate: number; selected: boolean }>,
  barcode: '',
  business_usage: '' as '' | 'Sales' | 'Purchase' | 'Both Sales and Purchase',
  has_serial_numbers: false,
  locally_produced: false,
  ingredients: [] as Array<{ id: number; product: string; uom: string; qty: number; waste_pct: number; is_optional: boolean; selected: boolean }>,
  ingredient_alternatives: [] as Array<{ id: number; ingredient_id: number; alternative: string; alternativeFor: string; uom: string; qty: number; waste_pct: number; is_optional: boolean }>,
  attributes: [] as Array<{ id: number; type: string; color: string; sizes: string[]; newSize: string }>,
  track_stock: false,
  track_batch: false,
  track_expiry: false,
  allow_transfers: false,
  costing_rule: '',
  inventory_policies: [] as Array<{ id: number; location: string; reorder_level: number; reorder_qty: number; selected: boolean }>,
  stock_levels: [] as Array<{ id: number; location: string; current_qty: number; reserved_qty: number; available_qty: number; selected: boolean }>,
  warranty_type: '',
  warranty_period: ''
});

// Interactive state for video playback
const isVideoPlaying = ref(false);

const visibleTabs = computed(() => {
  return tabs.filter(tab => {
    if (tab.id === 'Combo Config') {
      return formState.value.product_type === 'Combo';
    }
    if (tab.id === 'Sales') {
      return !formState.value.is_fixed_asset;
    }
    return true;
  });
});

// Reset tab state if Combo Config is closed dynamically
watch(() => formState.value.product_type, (newType) => {
  if (newType !== 'Combo' && activeTab.value === 'Combo Config') {
    activeTab.value = 'Basic';
  }
});

// Reset tab state if Sales is closed dynamically by Fixed Asset checkbox
watch(() => formState.value.is_fixed_asset, (isAsset) => {
  if (isAsset && activeTab.value === 'Sales') {
    activeTab.value = 'Basic';
  }
});

// Load from LocalStorage
onMounted(() => {
  const savedProducts = localStorage.getItem('haleta_erp_products');
  if (savedProducts) {
    products.value = JSON.parse(savedProducts);
  }
  const savedGroups = localStorage.getItem('haleta_erp_product_groups');
  if (savedGroups) {
    productGroups.value = JSON.parse(savedGroups);
  }
  window.addEventListener('click', closeAllMenus);
});

onUnmounted(() => {
  window.removeEventListener('click', closeAllMenus);
});

const saveToLocalStorage = () => {
  localStorage.setItem('haleta_erp_products', JSON.stringify(products.value));
};

const closeAllMenus = () => {
  activeActionMenuId.value = null;
  showColumnsDropdown.value = false;
  activeDropdownRowIdx.value = null;
  activeDropdownType.value = null;
};

// Filter & Search computation
const filteredProducts = computed(() => {
  const q = searchQuery.value.toLowerCase().trim();
  if (!q) return products.value;
  return products.value.filter(p => 
    p.name.toLowerCase().includes(q) || 
    p.code.toLowerCase().includes(q) || 
    p.product_group.toLowerCase().includes(q) || 
    p.product_type.toLowerCase().includes(q)
  );
});

// Pagination Calculations
const totalEntries = computed(() => filteredProducts.value.length);
const totalPages = computed(() => Math.ceil(totalEntries.value / perPage.value) || 1);
const startIndex = computed(() => totalEntries.value === 0 ? 0 : (currentPage.value - 1) * perPage.value + 1);
const endIndex = computed(() => Math.min(currentPage.value * perPage.value, totalEntries.value));

const paginatedProducts = computed(() => {
  const start = (currentPage.value - 1) * perPage.value;
  return filteredProducts.value.slice(start, start + perPage.value);
});

const changePage = (page: number) => {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page;
  }
};

// Actions
const toggleActionMenu = (e: Event, id: number) => {
  e.stopPropagation();
  activeActionMenuId.value = activeActionMenuId.value === id ? null : id;
};

const openAddForm = () => {
  editMode.value = false;
  selectedId.value = null;
  activeTab.value = 'Basic';
  isVideoPlaying.value = false;
  formState.value = {
    name: '',
    code: '',
    sku: '',
    color: '#0b529c',
    product_group: '',
    item_category: '',
    item_ref: '',
    brand_ids: [],
    has_alternative: false,
    product_type: 'Direct Sales',
    uom: '',
    is_fixed_asset: false,
    apply_to_variants: false,
    is_variants: false,
    parent_product: '',
    description: '',
    price: 0,
    is_tax_included: false,
    tax_rate: 15,
    warehouse: 'Main Warehouse',
    alternatives: [],
    modifiers: [],
    product_tax_rates: [],
    entity_ids: [],
    media: [
      { id: 1, url: 'https://assets.mixkit.co/videos/preview/mixkit-holding-a-gold-smartphone-40348-large.mp4', thumbnail: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?q=80&w=600&auto=format&fit=crop', type: 'video', isPrimary: true },
      { id: 2, url: 'https://assets.mixkit.co/videos/preview/mixkit-working-with-a-smartphone-40332-large.mp4', thumbnail: 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?q=80&w=200&auto=format&fit=crop', type: 'video', isPrimary: false },
      { id: 3, url: 'https://assets.mixkit.co/videos/preview/mixkit-rotating-smartphone-mockup-41586-large.mp4', thumbnail: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=200&auto=format&fit=crop', type: 'video', isPrimary: false }
    ] as any[],
    combo_items: [],
    uom_conversions: [],
    barcode: Math.random().toString(36).substring(2, 14).toUpperCase(),
    business_usage: '',
    has_serial_numbers: false,
    locally_produced: false,
    ingredients: [],
    ingredient_alternatives: [],
    attributes: [],
    track_stock: false,
    track_batch: false,
    track_expiry: false,
    allow_transfers: false,
    costing_rule: '',
    inventory_policies: [],
    stock_levels: [],
    warranty_type: '',
    warranty_period: ''
  };
  isSaved.value = false;
  showFullForm.value = true;
  closeAllMenus();
};

const triggerEdit = (item: any) => {
  editMode.value = true;
  selectedId.value = item.id;
  activeTab.value = 'Basic';
  isVideoPlaying.value = false;
  formState.value = {
    name: item.name,
    code: item.code,
    sku: item.sku || '',
    color: item.color || '#0b529c',
    product_group: item.product_group,
    item_category: item.item_category || '',
    item_ref: item.item_ref || '',
    brand_ids: item.brand_ids ? [...item.brand_ids] : [],
    has_alternative: item.has_alternative || false,
    product_type: item.product_type || 'Direct Sales',
    uom: item.uom,
    is_fixed_asset: item.is_fixed_asset || false,
    apply_to_variants: item.apply_to_variants || false,
    is_variants: item.is_variants !== undefined ? item.is_variants : false,
    parent_product: item.parent_product || '',
    description: item.description || '',
    price: item.price || 0,
    is_tax_included: item.is_tax_included || false,
    tax_rate: item.tax_rate || 15,
    warehouse: item.warehouse || 'Main Warehouse',
    alternatives: item.alternatives ? [...item.alternatives] : [],
    modifiers: item.modifiers ? [...item.modifiers] : [],
    product_tax_rates: item.product_tax_rates ? [...item.product_tax_rates] : [],
    entity_ids: item.entity_ids ? [...item.entity_ids] : [],
    media: item.media ? [...item.media] : [],
    combo_items: item.combo_items ? [...item.combo_items] : [],
    uom_conversions: item.uom_conversions ? [...item.uom_conversions] : [],
    barcode: item.barcode || Math.random().toString(36).substring(2, 14).toUpperCase(),
    business_usage: item.business_usage || '',
    has_serial_numbers: item.has_serial_numbers || false,
    locally_produced: item.locally_produced || false,
    ingredients: item.ingredients ? [...item.ingredients] : [],
    ingredient_alternatives: item.ingredient_alternatives ? [...item.ingredient_alternatives] : [],
    attributes: item.attributes ? [...item.attributes] : [],
    track_stock: item.track_stock || false,
    track_batch: item.track_batch || false,
    track_expiry: item.track_expiry || false,
    allow_transfers: item.allow_transfers || false,
    costing_rule: item.costing_rule || '',
    inventory_policies: item.inventory_policies ? [...item.inventory_policies] : [],
    stock_levels: item.stock_levels ? [...item.stock_levels] : [],
    warranty_type: item.warranty_type || '',
    warranty_period: item.warranty_period || ''
  };
  isSaved.value = false;
  showFullForm.value = true;
  closeAllMenus();
};

const handleSave = () => {
  if (!formState.value.name.trim()) {
    alert('Please enter a Product Name.');
    return;
  }
  if (!formState.value.code.trim()) {
    alert('Please enter a Product Code.');
    return;
  }
  if (!formState.value.uom) {
    alert('Please select a Default Unit of Measure.');
    return;
  }

  if (editMode.value && selectedId.value !== null) {
    const idx = products.value.findIndex(p => p.id === selectedId.value);
    if (idx !== -1) {
      products.value[idx] = {
        ...products.value[idx],
        name: formState.value.name,
        code: formState.value.code,
        sku: formState.value.sku,
        color: formState.value.color,
        product_group: formState.value.product_group,
        item_category: formState.value.item_category,
        brand_ids: [...formState.value.brand_ids],
        has_alternative: formState.value.has_alternative,
        product_type: formState.value.product_type,
        uom: formState.value.uom,
        is_fixed_asset: formState.value.is_fixed_asset,
        apply_to_variants: formState.value.apply_to_variants,
        is_variants: formState.value.is_variants,
        parent_product: formState.value.parent_product,
        description: formState.value.description,
        price: Number(formState.value.price),
        is_tax_included: formState.value.is_tax_included,
        tax_rate: Number(formState.value.tax_rate),
        warehouse: formState.value.warehouse,
        alternatives: [...formState.value.alternatives],
        modifiers: [...formState.value.modifiers],
        product_tax_rates: [...formState.value.product_tax_rates],
        entity_ids: [...formState.value.entity_ids],
        media: [...formState.value.media],
        combo_items: [...formState.value.combo_items],
        uom_conversions: [...formState.value.uom_conversions],
        barcode: formState.value.barcode,
        business_usage: formState.value.business_usage,
        has_serial_numbers: formState.value.has_serial_numbers,
        locally_produced: formState.value.locally_produced,
        ingredients: [...formState.value.ingredients],
        ingredient_alternatives: [...formState.value.ingredient_alternatives],
        attributes: [...formState.value.attributes],
        track_stock: formState.value.track_stock,
        track_batch: formState.value.track_batch,
        track_expiry: formState.value.track_expiry,
        allow_transfers: formState.value.allow_transfers,
        costing_rule: formState.value.costing_rule,
        inventory_policies: [...formState.value.inventory_policies],
        stock_levels: [...formState.value.stock_levels],
        warranty_type: formState.value.warranty_type,
        warranty_period: formState.value.warranty_period
      };
    }
  } else {
    products.value.push({
      id: Date.now(),
      code: formState.value.code,
      sku: formState.value.sku,
      color: formState.value.color,
      name: formState.value.name,
      product_group: formState.value.product_group || 'Unassigned',
      item_category: formState.value.item_category,
      brand_ids: [...formState.value.brand_ids],
      has_alternative: formState.value.has_alternative,
      product_type: formState.value.product_type,
      uom: formState.value.uom,
      is_trackable: 'Yes',
      status: 'Active',
      description: formState.value.description,
      price: Number(formState.value.price),
      is_tax_included: formState.value.is_tax_included,
      item_ref: formState.value.item_ref,
      is_fixed_asset: formState.value.is_fixed_asset,
      apply_to_variants: formState.value.apply_to_variants,
      is_variants: formState.value.is_variants,
      parent_product: formState.value.parent_product,
      alternatives: [...formState.value.alternatives],
      modifiers: [...formState.value.modifiers],
      product_tax_rates: [...formState.value.product_tax_rates],
      entity_ids: [...formState.value.entity_ids],
      media: [...formState.value.media],
      combo_items: [...formState.value.combo_items],
      uom_conversions: [...formState.value.uom_conversions],
      barcode: formState.value.barcode,
      business_usage: formState.value.business_usage,
      has_serial_numbers: formState.value.has_serial_numbers,
      locally_produced: formState.value.locally_produced,
      ingredients: [...formState.value.ingredients],
      ingredient_alternatives: [...formState.value.ingredient_alternatives],
      attributes: [...formState.value.attributes],
      track_stock: formState.value.track_stock,
      track_batch: formState.value.track_batch,
      track_expiry: formState.value.track_expiry,
      allow_transfers: formState.value.allow_transfers,
      costing_rule: formState.value.costing_rule,
      inventory_policies: [...formState.value.inventory_policies],
      stock_levels: [...formState.value.stock_levels],
      warranty_type: formState.value.warranty_type,
      warranty_period: formState.value.warranty_period,
      sku_attributes: formState.value.is_variants ? 'Color: Default, Size: Std' : ''
    });
  }

  isSaved.value = true;
  saveToLocalStorage();
  showFullForm.value = false;
};

const triggerDelete = (id: number) => {
  if (!confirm('Are you sure you want to delete this product?')) return;
  products.value = products.value.filter(p => p.id !== id);
  saveToLocalStorage();
  closeAllMenus();
};

const clearForm = () => {
  isVideoPlaying.value = false;
  formState.value = {
    name: '',
    code: '',
    sku: '',
    color: '#0b529c',
    product_group: '',
    item_category: '',
    item_ref: '',
    brand_ids: [],
    has_alternative: false,
    product_type: 'Direct Sales',
    uom: '',
    is_fixed_asset: false,
    apply_to_variants: false,
    is_variants: false,
    parent_product: '',
    description: '',
    price: 0,
    is_tax_included: false,
    tax_rate: 15,
    warehouse: 'Main Warehouse',
    alternatives: [],
    modifiers: [],
    product_tax_rates: [],
    entity_ids: [],
    media: [],
    combo_items: [],
    uom_conversions: [],
    barcode: '',
    business_usage: '',
    has_serial_numbers: false,
    locally_produced: false,
    ingredients: [],
    ingredient_alternatives: [],
    attributes: [],
    track_stock: false,
    track_batch: false,
    track_expiry: false,
    allow_transfers: false,
    costing_rule: '',
    inventory_policies: [],
    stock_levels: [],
    warranty_type: '',
    warranty_period: ''
  };
};

const handleRefresh = () => {
  currentPage.value = 1;
  searchQuery.value = '';
};

const setPrimaryImage = (index: number) => {
  isVideoPlaying.value = false;
  formState.value.media.forEach((img, i) => {
    img.isPrimary = i === index;
  });
};

const removeImage = (index: number) => {
  formState.value.media.splice(index, 1);
};

const fileInputEl = ref<HTMLInputElement | null>(null);

const triggerFileUpload = () => {
  if (fileInputEl.value) {
    fileInputEl.value.click();
  }
};

const handleFileChange = (e: Event) => {
  const target = e.target as HTMLInputElement;
  if (target.files) {
    for (let i = 0; i < target.files.length; i++) {
      const file = target.files[i];
      const isVideo = file.type.startsWith('video/');
      const reader = new FileReader();
      reader.onload = (event) => {
        if (event.target?.result) {
          const fileUrl = event.target.result as string;
          formState.value.media.push({
            id: Date.now() + i,
            url: fileUrl,
            thumbnail: isVideo ? undefined : fileUrl,
            type: isVideo ? 'video' : 'image',
            isPrimary: formState.value.media.length === 0
          });
        }
      };
      reader.readAsDataURL(file);
    }
  }
};

const addComboItem = () => {
  formState.value.combo_items.push({
    name: '',
    qty: 1,
    uom: 'Pcs'
  });
};

const addUomRow = () => {
  formState.value.uom_conversions.push({
    id: Date.now(),
    unit: '',
    rate: null as any,
    selected: false
  });
};

const removeUomRow = (index: number) => {
  formState.value.uom_conversions.splice(index, 1);
};

const isAllUomSelected = computed({
  get: () => formState.value.uom_conversions.length > 0 && formState.value.uom_conversions.every(r => r.selected),
  set: (val) => {
    formState.value.uom_conversions.forEach(r => r.selected = val);
  }
});

const activeDropdownRowIdx = ref<number | null>(null);
const activeDropdownType = ref<'unit' | 'rate' | 'actions' | null>(null);

const toggleDropdown = (rowIdx: number, type: 'unit' | 'rate' | 'actions', event: Event) => {
  event.stopPropagation();
  if (activeDropdownRowIdx.value === rowIdx && activeDropdownType.value === type) {
    activeDropdownRowIdx.value = null;
    activeDropdownType.value = null;
  } else {
    activeDropdownRowIdx.value = rowIdx;
    activeDropdownType.value = type;
  }
};

const closeDropdowns = () => {
  activeDropdownRowIdx.value = null;
  activeDropdownType.value = null;
};

const getAlternativeUnits = (defaultUom: string) => {
  const normalized = defaultUom.toLowerCase();
  if (normalized.includes('kilogram') || normalized === 'kg') {
    return ['Gram (g)', 'Milligram (mg)'];
  }
  if (normalized.includes('pack')) {
    return ['Piece', 'Box', 'Dozen'];
  }
  return uomList.value
    .map(u => u.name)
    .filter(name => name !== defaultUom);
};

const getRatePlaceholder = (unitName: string, defaultUom: string) => {
  if (!unitName || !defaultUom) return 'e.g. 1';
  let formattedDefault = defaultUom;
  let formattedUnit = unitName;
  if (defaultUom.toLowerCase().includes('kilogram')) {
    formattedDefault = 'KG';
  }
  if (unitName.toLowerCase().includes('gram')) {
    formattedUnit = 'Gram';
  }
  return `e.g.1000 (1 ${formattedDefault} FROM= 1000 ${formattedUnit} TO)`;
};

const getRatioOptions = (unitName: string, defaultUom: string) => {
  const normalizedUnit = unitName.toLowerCase();
  const normalizedDefault = defaultUom.toLowerCase();
  
  if (normalizedUnit.includes('piece') && normalizedDefault.includes('pack')) {
    return [
      { rate: 12, label: 'Piece To Pack', desc: '12 Piece = 1 Pack' },
      { rate: 6, label: 'Piece To Pack', desc: '6 Piece = 1 Pack' },
      { rate: 24, label: 'Piece To Pack', desc: '24 Piece = 1 Pack' }
    ];
  }
  if (normalizedUnit.includes('gram') && normalizedDefault.includes('kilogram')) {
    return [
      { rate: 1000, label: 'Gram To Kilogram (KG)', desc: '1000 Gram (g) = 1 Kilogram (KG)' },
      { rate: 500, label: 'Gram To Kilogram (KG)', desc: '500 Gram (g) = 1 Kilogram (KG)' }
    ];
  }
  return [
    { rate: 10, label: `${unitName} To ${defaultUom}`, desc: `10 ${unitName} = 1 ${defaultUom}` },
    { rate: 100, label: `${unitName} To ${defaultUom}`, desc: `100 ${unitName} = 1 ${defaultUom}` }
  ];
};

const hasSelectedUomRows = computed(() => {
  return formState.value.uom_conversions.some(r => r.selected);
});

const deleteSelectedUomRows = () => {
  formState.value.uom_conversions = formState.value.uom_conversions.filter(r => !r.selected);
};

const removeComboItem = (index: number) => {
  formState.value.combo_items.splice(index, 1);
};

// ---- Product Detail helpers ----
const generateBarcode = () => {
  formState.value.barcode = Math.random().toString(36).substring(2, 14).toUpperCase();
};

const addIngredientRow = () => {
  formState.value.ingredients.push({ id: Date.now(), product: '', uom: '', qty: 1, waste_pct: 0, is_optional: false, selected: false });
};
const removeIngredientRow = (i: number) => formState.value.ingredients.splice(i, 1);

// Get UOM Category to verify category mismatch
const getUomCategory = (uomName: string): string => {
  const norm = uomName.toLowerCase();
  if (norm.includes('kg') || norm.includes('kilogram') || norm.includes('gram') || norm.includes('g') || norm.includes('mg') || norm.includes('milligram')) {
    return 'weight';
  }
  if (norm.includes('liter') || norm.includes('l')) {
    return 'volume';
  }
  if (norm.includes('meter') || norm.includes('m')) {
    return 'length';
  }
  return 'unit'; // Default/Quantity category
};

// Sync ingredient alternatives with parent ingredients reactively
watch(() => formState.value.ingredients, (newIngs) => {
  const currentAlts = formState.value.ingredient_alternatives || [];
  const syncedAlts = newIngs
    .filter(ing => ing.product)
    .map(ing => {
      const existing = currentAlts.find(alt => alt.ingredient_id === ing.id);
      if (existing) {
        existing.alternativeFor = ing.product;
        return existing;
      } else {
        return {
          id: Date.now() + Math.random(),
          ingredient_id: ing.id,
          alternative: '',
          alternativeFor: ing.product,
          uom: ing.uom,
          qty: ing.qty,
          waste_pct: ing.waste_pct,
          is_optional: false
        };
      }
    });
  formState.value.ingredient_alternatives = syncedAlts;
}, { deep: true });

const ingredientAlternatives = computed(() => {
  const alts = formState.value.ingredient_alternatives || [];
  return alts.map(alt => {
    const parent = formState.value.ingredients.find(ing => ing.id === alt.ingredient_id);
    let uomMismatch = false;
    if (parent && parent.uom && alt.uom) {
      uomMismatch = getUomCategory(parent.uom) !== getUomCategory(alt.uom);
    }
    return {
      ...alt,
      uomMismatch
    };
  });
});

const hasUomMismatch = computed(() => ingredientAlternatives.value.some(a => a.uomMismatch));

const attributeTypeOptions = ['Color', 'Size', 'Material', 'Style'];
const sizePresets = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];

const addAttribute = () => {
  formState.value.attributes.push({ id: Date.now(), type: '', color: '0B529C', sizes: [], newSize: '' });
};
const removeAttribute = (i: number) => formState.value.attributes.splice(i, 1);
const addSize = (attr: any) => {
  const v = attr.newSize.trim();
  if (v && !attr.sizes.includes(v)) attr.sizes.push(v);
  attr.newSize = '';
};
const removeSize = (attr: any, s: string) => { attr.sizes = attr.sizes.filter((x: string) => x !== s); };

// ---- Parent / variant inheritance ----
// When a variant product picks a parent, we stage the selection and surface a
// confirmation before committing. A "strict" parent (apply_to_variants = true)
// locks every section except Product Attribute Values + the Variant Price
// Override; a "soft" parent only pre-fills defaults the user may still change.
const parentConfirmOpen = ref(false);
const pendingParent = ref<string>('');   // parent awaiting confirmation
const previousParent = ref<string>('');  // value to restore on cancel

const selectedParentData = computed(
  () => parentProductsData.find(p => p.name === formState.value.parent_product) || null
);
// Reflects the *pending* parent while the modal is open, otherwise the committed one.
const confirmParentData = computed(
  () => parentProductsData.find(p => p.name === (parentConfirmOpen.value ? pendingParent.value : formState.value.parent_product)) || null
);
const isStrictInherit = computed(() => !!selectedParentData.value?.apply_to_variants);
const isInheriting = computed(() => formState.value.is_variants && !!selectedParentData.value);
const inheritedBadgeText = computed(() => `Inherited from ${formState.value.parent_product}`);

const onParentChange = (e: Event) => {
  const next = (e.target as HTMLSelectElement).value;
  if (!next || next === formState.value.parent_product) return;
  previousParent.value = formState.value.parent_product;
  pendingParent.value = next;
  parentConfirmOpen.value = true;
};

// Copy the strict parent's inherited fields onto the variant form. The child's
// own attribute values and price override stay editable, so we do not clone
// over `price` here when the user has already set an override — but on first
// inherit we seed it from the parent default for convenience.
const applyInheritedValues = () => {
  const p = selectedParentData.value;
  if (!p) return;
  formState.value.product_group = p.product_group;
  formState.value.item_category = p.item_category;
  formState.value.brand_ids = [...p.brand_ids];
  formState.value.product_type = p.product_type;
  formState.value.uom = p.uom;
  formState.value.price = p.price;
  formState.value.is_tax_included = p.is_tax_included;
  formState.value.tax_rate = p.tax_rate;
  formState.value.track_stock = p.track_stock;
  formState.value.track_batch = p.track_batch;
  formState.value.track_expiry = p.track_expiry;
  formState.value.costing_rule = p.costing_rule;
  formState.value.business_usage = p.business_usage;
};

const confirmParent = () => {
  formState.value.parent_product = pendingParent.value;
  if (isStrictInherit.value) applyInheritedValues();
  parentConfirmOpen.value = false;
  pendingParent.value = '';
};

const cancelParent = () => {
  // Never committed pendingParent, so just restore the previous selection.
  formState.value.parent_product = previousParent.value;
  parentConfirmOpen.value = false;
  pendingParent.value = '';
};

// ---- Inventory Tab helpers ----
const policySectionOpen = ref(true);
const stockLevelsSectionOpen = ref(true);
const costingRuleSectionOpen = ref(true);
const warrantySectionOpen = ref(true);

const locationsList = ['All Locations', 'Main Warehouse', 'Secondary Warehouse', 'Retail Store', 'Transit Location'];

const addPolicyRow = () => {
  formState.value.inventory_policies.push({
    id: Date.now() + Math.random(),
    location: 'All Locations',
    reorder_level: 50,
    reorder_qty: 350,
    selected: false
  });
};

const removePolicyRow = (idx: number) => {
  formState.value.inventory_policies.splice(idx, 1);
};

const removeStockLevelRow = (idx: number) => {
  formState.value.stock_levels.splice(idx, 1);
};

const isAllPoliciesSelected = computed({
  get: () => formState.value.inventory_policies.length > 0 && formState.value.inventory_policies.every(r => r.selected),
  set: (val) => formState.value.inventory_policies.forEach(r => r.selected = val)
});

const isAllStockLevelsSelected = computed({
  get: () => formState.value.stock_levels.length > 0 && formState.value.stock_levels.every(r => r.selected),
  set: (val) => formState.value.stock_levels.forEach(r => r.selected = val)
});

// Total available stock across all locations (StockSummary.available_qty roll-up)
const totalAvailableStock = computed(() =>
  formState.value.stock_levels.reduce((sum, s) => sum + (Number(s.current_qty || 0) - Number(s.reserved_qty || 0)), 0)
);

// Real, selectable locations (exclude the "All Locations" meta entry)
const realLocations = computed(() => locationsList.filter(l => l !== 'All Locations'));

// Per-location roll-up of this product's stock for the Stock Levels list.
// Every real location is listed so the user sees where the product is — and isn't — stocked.
const stockByLocation = computed(() =>
  realLocations.value.map(loc => {
    const rows = formState.value.stock_levels.filter(s => s.location === loc);
    const onHand = rows.reduce((a, r) => a + Number(r.current_qty || 0), 0);
    const reserved = rows.reduce((a, r) => a + Number(r.reserved_qty || 0), 0);
    return { location: loc, onHand, reserved, available: onHand - reserved, hasStock: rows.length > 0 };
  })
);

// Largest absolute available qty — scales the bars proportionally across locations
const maxLocationStock = computed(() =>
  Math.max(1, ...stockByLocation.value.map(s => Math.abs(s.available)))
);
const stockBarWidth = (available: number) =>
  `${Math.min(100, (Math.abs(available) / maxLocationStock.value) * 100)}%`;
const stockBarClass = (available: number) =>
  available < 0 ? 'bg-red-400' : available === 0 ? 'bg-gray-300' : available <= 10 ? 'bg-amber-400' : 'bg-emerald-500';
const stockQtyClass = (available: number) =>
  available < 0 ? 'text-red-600' : available === 0 ? 'text-gray-400' : 'text-gray-900';

// Find a location's stock row, or create a fresh one (keeps one row per location)
const findOrCreateStockRow = (location: string) => {
  let row = formState.value.stock_levels.find(s => s.location === location);
  if (!row) {
    row = { id: Date.now() + Math.random(), location, current_qty: 0, reserved_qty: 0, available_qty: 0, selected: false };
    formState.value.stock_levels.push(row);
  }
  return row;
};

// Jump to the Stock Summary page focused on this product at a given location
const goToLocationStock = (location: string) => {
  router.push({ path: '/stock-summary', query: { product: formState.value.name, location } });
};

// ---- Stock-In Modal ----
const showStockInModal = ref(false);
const stockInForm = ref({
  product_name: '',
  to_location: '',
  quantity: null as number | null,
  unit_price: null as number | null
});

const openStockInModal = () => {
  // Product must be saved (editMode means it already has a persisted ID)
  if (!editMode.value || !selectedId.value) {
    alert('Please save the product first before adding stock.');
    return;
  }
  stockInForm.value = {
    product_name: formState.value.name,
    to_location: '',
    quantity: null,
    unit_price: null
  };
  showStockInModal.value = true;
};

// Open the Add Stock modal pre-targeted at a specific location (from the location list)
const openStockInModalFor = (location: string) => {
  if (!editMode.value || !selectedId.value) {
    alert('Please save the product first before adding stock.');
    return;
  }
  stockInForm.value = { product_name: formState.value.name, to_location: location, quantity: null, unit_price: null };
  showStockInModal.value = true;
};

const closeStockInModal = () => {
  showStockInModal.value = false;
};

const submitStockIn = () => {
  if (!stockInForm.value.to_location) {
    alert('Please select a location.');
    return;
  }
  if (!stockInForm.value.quantity || stockInForm.value.quantity <= 0) {
    alert('Please enter a valid quantity.');
    return;
  }
  // Merge into the location's existing row (one row per location keeps the list clean)
  const row = findOrCreateStockRow(stockInForm.value.to_location);
  row.current_qty = Number(row.current_qty || 0) + Number(stockInForm.value.quantity);
  closeStockInModal();
};

// ---- Stock Move (transfer available units between locations) ----
const showMoveModal = ref(false);
const moveForm = ref({ from_location: '', to_location: '', quantity: null as number | null });

const moveDestinations = computed(() =>
  realLocations.value.filter(l => l !== moveForm.value.from_location)
);
const moveAvailable = computed(() => {
  const src = stockByLocation.value.find(s => s.location === moveForm.value.from_location);
  return src ? src.available : 0;
});

const openMoveModal = (from: string) => {
  if (!editMode.value || !selectedId.value) {
    alert('Please save the product first before moving stock.');
    return;
  }
  moveForm.value = { from_location: from, to_location: '', quantity: null };
  showMoveModal.value = true;
};
const closeMoveModal = () => {
  showMoveModal.value = false;
};

const submitMove = () => {
  if (!moveForm.value.to_location) {
    alert('Please select a destination location.');
    return;
  }
  if (!moveForm.value.quantity || moveForm.value.quantity <= 0) {
    alert('Please enter a valid quantity.');
    return;
  }
  if (moveForm.value.quantity > moveAvailable.value) {
    alert(`Only ${moveAvailable.value} available at ${moveForm.value.from_location}.`);
    return;
  }
  const src = findOrCreateStockRow(moveForm.value.from_location);
  src.current_qty = Number(src.current_qty || 0) - Number(moveForm.value.quantity);
  const dest = findOrCreateStockRow(moveForm.value.to_location);
  dest.current_qty = Number(dest.current_qty || 0) + Number(moveForm.value.quantity);
  closeMoveModal();
};

const isAllIngrSelected = computed({
  get: () => formState.value.ingredients.length > 0 && formState.value.ingredients.every(r => r.selected),
  set: (val) => formState.value.ingredients.forEach(r => r.selected = val)
});

const ingredientsSectionOpen = ref(true);
const alternativesSectionOpen = ref(true);
const attributesSectionOpen = ref(true);

const primaryImage = computed(() => {
  if (showFullForm.value) {
    return formState.value.media.find(img => img.isPrimary) || formState.value.media[0] || null;
  }
  return null;
});

const toggleFullscreen = () => {
  isFullscreen.value = !isFullscreen.value;
};
</script>

<template>
  <div :class="['products-view-container', { 'is-fullscreen': isFullscreen }]">
    
    <!-- ==================== FLOW 1: CREATE / EDIT PRODUCT FORM ==================== -->
    <div v-if="showFullForm" class="product-form-layout">
      
      <!-- Top Action Bar & Breadcrumbs -->
      <div class="form-top-bar flex items-center justify-between border-b border-gray-200 pb-4 mb-5">
        <AppBreadcrumb 
          :items="[
            { label: 'Products', to: '/inventory/products' },
            { label: editMode ? 'Edit Product' : 'Create Product' }
          ]" 
        >
          <template #extra>
            <SaveStateBadge :isSaved="isSaved" />
          </template>
        </AppBreadcrumb>

        <div class="form-action-buttons flex items-center gap-3">
          <button class="options-btn-dots p-2 border border-gray-200 rounded-lg bg-white text-gray-500 hover:bg-gray-50 hover:text-gray-900">
            <MoreVertical :size="16" />
          </button>
          <button @click="clearForm" class="clear-form-btn flex items-center gap-1.5 px-4 py-2 border border-gray-200 rounded-lg bg-white text-gray-700 hover:bg-gray-50 font-medium text-sm">
            <X :size="16" />
            Clear Form
          </button>
          <button @click="handleSave" class="save-product-btn px-5 py-2 rounded-lg bg-[#0b529c] text-white hover:bg-[#0c65bd] font-semibold text-sm shadow-sm transition-colors">
            Save
          </button>
        </div>
      </div>

      <!-- Navigation Tabs (shared component) -->
      <div class="tabs-outer-wrapper mb-6 overflow-x-auto">
        <BaseTabs v-model="activeTab" :tabs="visibleTabs" />
      </div>

      <!-- Form Columns Layout -->
      <div class="form-columns-grid grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        <!-- Left Side Forms (2/3 width) -->
        <div class="lg:col-span-2 space-y-6">

          <!-- 1. BASIC TAB CONTENT -->
          <div v-if="activeTab === 'Basic'" class="space-y-6">
            
            <!-- Basic Details Card -->
            <div class="form-card-wrapper bg-white border border-gray-200 rounded-2xl p-6 shadow-sm">
              <div v-if="isStrictInherit" class="inline-flex items-center gap-1.5 text-[11px] font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2.5 py-1 rounded-full mb-4">
                <Lock :size="11" /> {{ inheritedBadgeText }}
              </div>
              <fieldset :disabled="isStrictInherit" :class="['border-0 p-0 m-0', isStrictInherit ? 'opacity-60' : '']">
              <div class="card-grid-fields grid grid-cols-1 md:grid-cols-3 gap-5">
                
                <div class="field-item">
                  <label class="field-label-premium block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">
                    Name <span class="text-red-500">*</span>
                  </label>
                  <input 
                    v-model="formState.name" 
                    type="text" 
                     
                    class="premium-input-style w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:border-gray-300 focus:outline-none focus:ring-1 focus:ring-gray-300"
                  />
                </div>

                <div class="field-item">
                  <label class="field-label-premium block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">
                    Code <span class="text-red-500">*</span>
                  </label>
                  <input
                    v-model="formState.code"
                    type="text"
                    
                    class="premium-input-style w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:border-gray-300 focus:outline-none focus:ring-1 focus:ring-gray-300"
                  />
                  <p class="field-tip-desc text-[10px] text-gray-400 mt-1 font-medium">Organisational code.</p>
                </div>

                <div class="field-item">
                  <label class="field-label-premium block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">
                    SKU
                  </label>
                  <input
                    v-model="formState.sku"
                    type="text"
                    
                    class="premium-input-style w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm font-mono focus:border-gray-300 focus:outline-none focus:ring-1 focus:ring-gray-300"
                  />
                  <p class="field-tip-desc text-[10px] text-gray-400 mt-1 font-medium">Internal sellable/barcode code used at POS.</p>
                </div>

                <div class="field-item">
                  <label class="field-label-premium block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">
                    POS Tile Color
                  </label>
                  <div class="flex items-center gap-2">
                    <div class="flex-1 flex items-center border border-gray-200 rounded-xl overflow-hidden">
                      <span class="px-3 text-gray-400 text-sm font-semibold">#</span>
                      <input v-model="formState.color" type="text"  class="flex-1 py-2.5 text-sm focus:outline-none font-mono" @input="formState.color = formState.color.startsWith('#') ? formState.color : '#' + formState.color.replace('#','')" />
                    </div>
                    <input type="color" v-model="formState.color" class="w-10 h-[42px] rounded-xl border border-gray-200 cursor-pointer p-0.5" />
                  </div>
                  <p class="field-tip-desc text-[10px] text-gray-400 mt-1 font-medium">Quick-button background in POS grids.</p>
                </div>

                <div class="field-item">
                  <label class="field-label-premium block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">
                    Item Category
                  </label>
                  <div class="select-field-wrapper relative">
                    <select
                      v-model="formState.item_category"
                      class="premium-select-style w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm appearance-none bg-white focus:border-gray-300 focus:outline-none"
                    >
                      <option value="">All Categories</option>
                      <option v-for="c in itemCategoryList" :key="c.id" :value="c.name">{{ c.name }}</option>
                    </select>
                    <ChevronDown :size="16" class="select-chevron-arrow absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                  </div>
                  <p class="field-tip-desc text-[10px] text-gray-400 mt-1 font-medium">Restricts the brands available below.</p>
                </div>

                <div class="field-item">
                  <label class="field-label-premium block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">
                    Product Group
                  </label>
                  <div class="select-field-wrapper relative">
                    <select 
                      v-model="formState.product_group" 
                      class="premium-select-style w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm appearance-none bg-white focus:border-gray-300 focus:outline-none"
                    >
                      <option value="" disabled selected>Select option</option>
                      <option v-for="g in productGroups.filter(x => !x.is_group)" :key="g.id" :value="g.name">{{ g.name }}</option>
                    </select>
                    <ChevronDown :size="16" class="select-chevron-arrow absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                  </div>
                </div>

                <div class="field-item">
                  <label class="field-label-premium block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">
                    Item
                  </label>
                  <div class="select-field-wrapper relative">
                    <select 
                      v-model="formState.item_ref" 
                      class="premium-select-style w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm appearance-none bg-white focus:border-gray-300 focus:outline-none"
                    >
                      <option value="" disabled selected>Select option</option>
                      <option v-for="i in itemList" :key="i" :value="i">{{ i }}</option>
                    </select>
                    <ChevronDown :size="16" class="select-chevron-arrow absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                  </div>
                </div>

                <div class="field-item">
                  <label class="field-label-premium flex items-center gap-1 text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">
                    Product Type
                    <HelpCircle :size="13" class="text-gray-400 cursor-pointer" title="Combo type products are composed of multiple items." />
                  </label>
                  <div class="select-field-wrapper relative">
                    <select 
                      v-model="formState.product_type" 
                      class="premium-select-style w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm appearance-none bg-white focus:border-gray-300 focus:outline-none"
                    >
                      <option v-for="t in productTypes" :key="t" :value="t">{{ t }}</option>
                    </select>
                    <ChevronDown :size="16" class="select-chevron-arrow absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                  </div>
                </div>

              </div>
              </fieldset>
            </div>

            <!-- Brands Card (Brand / ItemCategoryBrand / ProductBrand) -->
            <div class="form-card-wrapper bg-white border border-gray-200 rounded-2xl p-6 shadow-sm space-y-4">
              <div v-if="isStrictInherit" class="inline-flex items-center gap-1.5 text-[11px] font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2.5 py-1 rounded-full mb-1">
                <Lock :size="11" /> {{ inheritedBadgeText }}
              </div>
              <fieldset :disabled="isStrictInherit" :class="['border-0 p-0 m-0 space-y-4', isStrictInherit ? 'opacity-60' : '']">
              <div class="flex items-center gap-1.5 border-b border-gray-100 pb-3">
                <h3 class="text-sm font-bold text-gray-800 uppercase tracking-wider">Brands</h3>
                <HelpCircle :size="14" class="text-gray-400 cursor-pointer" title="Assign one or more brands to this product. Available brands are restricted by the selected Item Category." />
              </div>
              <p class="text-xs text-gray-500 font-medium leading-relaxed">
                Assign one or more brands. The list is restricted by the selected
                <span class="font-bold text-gray-900">{{ formState.item_category || 'All Categories' }}</span> item category.
              </p>
              <div v-if="availableBrands.length === 0" class="text-sm text-gray-400 py-2">No brands available for this category.</div>
              <div v-else class="flex flex-wrap gap-2.5">
                <button
                  v-for="b in availableBrands"
                  :key="b.id"
                  type="button"
                  @click="toggleBrand(b.id)"
                  :class="['flex items-center gap-2 px-3.5 py-2 rounded-xl border text-sm font-semibold transition-all',
                    formState.brand_ids.includes(b.id)
                      ? 'bg-[#0b529c] border-[#0b529c] text-white shadow-sm'
                      : 'bg-white border-gray-200 text-gray-700 hover:bg-gray-50']"
                >
                  <Check v-if="formState.brand_ids.includes(b.id)" :size="13" />
                  {{ b.name }}
                  <span :class="['text-[10px] font-mono', formState.brand_ids.includes(b.id) ? 'text-blue-100' : 'text-gray-400']">{{ b.code }}</span>
                </button>
              </div>
              <p v-if="formState.brand_ids.length" class="text-xs text-gray-500 font-medium pt-1">
                Selected: <span class="font-bold text-gray-800">{{ brandNames(formState.brand_ids) }}</span>
              </p>
              </fieldset>
            </div>

            <!-- UOM & Flags Card -->
            <div class="form-card-wrapper bg-white border border-gray-200 rounded-2xl p-6 shadow-sm space-y-5">

              <div v-if="isStrictInherit" class="inline-flex items-center gap-1.5 text-[11px] font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2.5 py-1 rounded-full">
                <Lock :size="11" /> {{ inheritedBadgeText }}
              </div>
              <fieldset :disabled="isStrictInherit" :class="['border-0 p-0 m-0 space-y-5', isStrictInherit ? 'opacity-60' : '']">

              <div class="field-item max-w-lg">
                <label class="field-label-premium block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">
                  Default Unit of Measure <span class="text-red-500">*</span>
                </label>
                <div class="select-field-wrapper relative">
                  <select 
                    v-model="formState.uom" 
                    class="premium-select-style w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm appearance-none bg-white focus:border-gray-300 focus:outline-none"
                  >
                    <option value="" disabled selected>Select UOM</option>
                    <option v-for="u in uomList" :key="u.id" :value="u.name">{{ u.name }}</option>
                  </select>
                  <ChevronDown :size="16" class="select-chevron-arrow absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                </div>
                <p class="field-tip-desc text-xs text-gray-400 mt-2 font-medium">
                  Once you have selected the default unit of measurement, add any additional units of measurement in the UOM tab.
                </p>
              </div>

              <!-- Checkbox settings -->
              <div class="checkbox-settings-grid grid grid-cols-1 md:grid-cols-2 gap-5 pt-2">
                
                <label class="checkbox-row-wrapper flex gap-3.5 p-3.5 rounded-xl border border-gray-100 hover:bg-gray-50 transition-all cursor-pointer">
                  <input type="checkbox" v-model="formState.is_fixed_asset" class="hidden-checkbox-input sr-only" />
                  <div :class="['custom-checkbox-container w-5 h-5 rounded border flex items-center justify-center shrink-0 mt-0.5 transition-colors', formState.is_fixed_asset ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']">
                    <Check v-if="formState.is_fixed_asset" :size="13" />
                  </div>
                  <div class="checkbox-label-content">
                    <span class="checkbox-title text-sm font-semibold text-gray-900 block mb-0.5">Fixed Asset</span>
                    <span class="checkbox-desc text-xs text-gray-400 font-medium leading-relaxed block">
                      Mark this if the product is a long-term asset (like equipment or machinery) and not intended for regular sale or consumption.
                    </span>
                  </div>
                </label>

                <label 
                  :class="[
                    'checkbox-row-wrapper flex gap-3.5 p-3.5 rounded-xl border border-gray-100 transition-all',
                    formState.is_variants ? 'opacity-50 bg-gray-50/50 cursor-not-allowed' : 'hover:bg-gray-50 cursor-pointer'
                  ]"
                >
                  <input 
                    type="checkbox" 
                    v-model="formState.apply_to_variants" 
                    :disabled="formState.is_variants" 
                    class="hidden-checkbox-input sr-only" 
                  />
                  <div :class="['custom-checkbox-container w-5 h-5 rounded border flex items-center justify-center shrink-0 mt-0.5 transition-colors', formState.apply_to_variants ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']">
                    <Check v-if="formState.apply_to_variants" :size="13" />
                  </div>
                  <div class="checkbox-label-content">
                    <span :class="['checkbox-title text-sm font-semibold block mb-0.5', formState.is_variants ? 'text-gray-400' : 'text-gray-900']">Apply Settings to All Variants</span>
                    <span class="checkbox-desc text-xs text-gray-400 font-medium leading-relaxed block">
                      When enabled, all variants will share the same settings (tax, stock behavior, etc.). Turn off to customize each variant individually.
                    </span>
                  </div>
                </label>

                <label class="checkbox-row-wrapper flex gap-3.5 p-3.5 rounded-xl border border-gray-100 hover:bg-gray-50 transition-all cursor-pointer">
                  <input type="checkbox" v-model="formState.has_alternative" class="hidden-checkbox-input sr-only" />
                  <div :class="['custom-checkbox-container w-5 h-5 rounded border flex items-center justify-center shrink-0 mt-0.5 transition-colors', formState.has_alternative ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']">
                    <Check v-if="formState.has_alternative" :size="13" />
                  </div>
                  <div class="checkbox-label-content">
                    <span class="checkbox-title text-sm font-semibold text-gray-900 block mb-0.5">Has Alternatives</span>
                    <span class="checkbox-desc text-xs text-gray-400 font-medium leading-relaxed block">
                      Enable to register substitute products (e.g. "Pepsi" as an alternative to "Coca-Cola") in the Product Detail tab.
                    </span>
                  </div>
                </label>

               </div>
              </fieldset>

               <!-- Inner Variants Card (checked in screenshot) -->
               <div class="inner-variants-card border border-gray-200 rounded-xl p-5 bg-gray-50/50 space-y-4">
                 <label 
                   :class="[
                     'checkbox-row-wrapper flex gap-3.5 transition-all',
                     formState.apply_to_variants ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'
                   ]"
                 >
                   <input 
                     type="checkbox" 
                     v-model="formState.is_variants" 
                     :disabled="formState.apply_to_variants" 
                     class="hidden-checkbox-input sr-only" 
                   />
                   <div :class="['custom-checkbox-container w-5 h-5 rounded border flex items-center justify-center shrink-0 mt-0.5 transition-colors', formState.is_variants ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']">
                     <Check v-if="formState.is_variants" :size="13" />
                   </div>
                   <div class="checkbox-label-content">
                     <span :class="['checkbox-title text-sm font-semibold block mb-0.5', formState.apply_to_variants ? 'text-gray-400' : 'text-gray-900']">Is Variants</span>
                     <span class="checkbox-desc text-xs text-gray-400 font-medium block">
                       Enable this if the product itself is a variant of another Product
                     </span>
                   </div>
                 </label>
 
                 <div v-if="formState.is_variants" class="variant-parent-select max-w-md pt-1">
                   <label class="field-label-premium block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">
                     Select Parent <span class="text-red-500">*</span>
                   </label>
                   <div class="select-field-wrapper relative">
                     <select
                       :value="formState.parent_product"
                       @change="onParentChange($event)"
                       class="premium-select-style w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm appearance-none bg-white focus:border-gray-300 focus:outline-none"
                     >
                       <option value="" disabled>Select</option>
                       <option v-for="p in parentProductsData" :key="p.id" :value="p.name">{{ p.name }}</option>
                     </select>
                     <ChevronDown :size="16" class="select-chevron-arrow absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                   </div>
                   <p v-if="isInheriting" class="text-[11px] mt-1.5 font-semibold flex items-center gap-1" :class="isStrictInherit ? 'text-amber-600' : 'text-[#0b529c]'">
                     <Lock v-if="isStrictInherit" :size="11" />
                     <Info v-else :size="11" />
                     {{ isStrictInherit
                       ? 'Most sections are locked and inherited from this parent.'
                       : 'Some defaults are inherited from this parent; you can still edit them.' }}
                   </p>
                </div>
              </div>

            </div>

          </div>

          <!-- 2. COMBO CONFIG TAB CONTENT -->
          <div v-else-if="activeTab === 'Combo Config'" class="space-y-6">
            <div class="form-card-wrapper bg-white border border-gray-200 rounded-2xl p-6 shadow-sm space-y-4">
              <div class="flex items-center justify-between border-b border-gray-100 pb-3">
                <h3 class="text-sm font-bold text-gray-800 uppercase tracking-wider">Combo Item Composition</h3>
                <button @click="addComboItem" class="flex items-center gap-1.5 px-3 py-1.5 bg-[#0b529c] text-white rounded-lg text-xs font-semibold hover:bg-[#0c65bd]">
                  <Plus :size="14" />
                  Add Component Item
                </button>
              </div>

              <div v-if="formState.combo_items.length === 0" class="text-center py-8 text-gray-400 text-sm">
                No items added to this combo. Click "Add Component Item" to create composition rules.
              </div>

              <div v-else class="space-y-3">
                <div v-for="(cItem, index) in formState.combo_items" :key="index" class="combo-row flex items-center gap-4 bg-gray-50 p-3 rounded-xl border border-gray-100">
                  <div class="flex-1">
                    <label class="text-[10px] font-bold text-gray-500 uppercase tracking-wider block mb-1">Item Name</label>
                    <input 
                      v-model="cItem.name" 
                      type="text" 
                       
                      class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white"
                    />
                  </div>
                  <div class="w-24">
                    <label class="text-[10px] font-bold text-gray-500 uppercase tracking-wider block mb-1">Quantity</label>
                    <input 
                      v-model="cItem.qty" 
                      type="number" 
                      min="1" 
                      class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white"
                    />
                  </div>
                  <div class="w-32">
                    <label class="text-[10px] font-bold text-gray-500 uppercase tracking-wider block mb-1">Unit of Measure</label>
                    <select v-model="cItem.uom" class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm bg-white">
                      <option v-for="u in uomList" :key="u.id" :value="u.name">{{ u.name }}</option>
                    </select>
                  </div>
                  <button @click="removeComboItem(index)" class="self-end mb-1.5 p-2 bg-white text-red-500 hover:text-red-700 hover:bg-red-50 border border-gray-200 rounded-lg" title="Delete Row">
                    <Trash :size="14" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- 3. PRODUCT DETAIL TAB CONTENT -->
          <div v-else-if="activeTab === 'Product Detail'" class="space-y-4">
            <!-- Barcode + Business Usage -->
            <div class="bg-white border border-gray-200 rounded-2xl p-6 shadow-sm">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label class="block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">Barcode</label>
                  <div class="flex items-center gap-2">
                    <input v-model="formState.barcode" type="text"  class="flex-1 border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm font-mono focus:outline-none focus:ring-1 focus:ring-gray-300" />
                    <button @click="generateBarcode" class="p-2.5 border border-gray-200 rounded-xl hover:bg-gray-50 text-gray-500" title="Regenerate"><RefreshCw :size="15" /></button>
                  </div>
                </div>
                <div>
                  <label class="block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">Product Registry Type</label>
                  <div class="relative">
                    <select v-model="formState.business_usage" class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm appearance-none bg-white focus:outline-none focus:ring-1 focus:ring-gray-300">
                      <option value="" disabled selected>Select option</option>
                      <option value="Sales">Sales</option>
                      <option value="Purchase">Purchase</option>
                      <option value="Both Sales and Purchase">Both</option>
                    </select>
                    <ChevronDown :size="16" class="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                  </div>
                  <p class="text-xs text-gray-400 mt-1.5">Specify whether this product registry type is Sales, Purchase, or Both.</p>
                </div>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6 pt-5 border-t border-gray-100">
                <label class="flex gap-3 cursor-pointer">
                  <input type="checkbox" v-model="formState.has_serial_numbers" class="sr-only" />
                  <div :class="['w-5 h-5 rounded border flex items-center justify-center shrink-0 mt-0.5 transition-colors', formState.has_serial_numbers ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']"><Check v-if="formState.has_serial_numbers" :size="12" /></div>
                  <div><span class="text-sm font-semibold text-gray-900 block">Has Serial Numbers</span><span class="text-xs text-gray-400 leading-relaxed block mt-0.5">Enable this to assign a unique serial number to each unit of this product. Use this for items that need individual tracking, such as electronics, devices, or high-value goods.</span></div>
                </label>
                <label class="flex gap-3 cursor-pointer">
                  <input type="checkbox" v-model="formState.locally_produced" class="sr-only" />
                  <div :class="['w-5 h-5 rounded border flex items-center justify-center shrink-0 mt-0.5 transition-colors', formState.locally_produced ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']"><Check v-if="formState.locally_produced" :size="12" /></div>
                  <div><span class="text-sm font-semibold text-gray-900 block">Locally Produced</span><span class="text-xs text-gray-400 leading-relaxed block mt-0.5">Turn this on if the product is made or assembled internally using your own ingredients or materials. This allows you to define how it is produced and what resources are used.</span></div>
                </label>
              </div>
            </div>

            <!-- Add Ingredients -->
            <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
              <button @click="ingredientsSectionOpen = !ingredientsSectionOpen" class="w-full flex items-center justify-between px-6 py-4 hover:bg-gray-50 transition-colors">
                <span class="text-sm font-bold text-gray-800">Add Ingredients</span>
                <ChevronDown :size="16" :class="['text-gray-400 transition-transform duration-200', ingredientsSectionOpen ? 'rotate-180' : '']" />
              </button>
              <div v-if="ingredientsSectionOpen" class="border-t border-gray-100">
                <table class="w-full text-left border-collapse">
                  <thead>
                    <tr class="bg-gray-50/75 text-xs font-bold text-gray-600 border-b border-gray-200">
                      <th class="p-3.5 w-12 text-center border-r border-gray-200"><input type="checkbox" v-model="isAllIngrSelected" class="w-4 h-4 rounded border-gray-300" /></th>
                      <th class="p-3.5 w-14 text-center border-r border-gray-200">No.</th>
                      <th class="p-3.5 border-r border-gray-200">Ingredient Product</th>
                      <th class="p-3.5 border-r border-gray-200">Measurement Unit</th>
                      <th class="p-3.5 border-r border-gray-200">Required Quantity</th>
                      <th class="p-3.5 border-r border-gray-200">Waste In Percentage (%)</th>
                      <th class="p-3.5 border-r border-gray-200 text-center">Is Optional</th>
                      <th class="p-3.5 border-r border-gray-200">Ingredient Alternatives</th>
                      <th class="p-3.5 w-12 text-center"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="text-gray-400 mx-auto"><line x1="4" y1="21" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="3"/></svg></th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="formState.ingredients.length === 0"><td colspan="9" class="p-8 text-center text-sm font-semibold text-gray-400">No rows</td></tr>
                    <tr v-for="(row, idx) in formState.ingredients" :key="row.id" class="border-b border-gray-100 hover:bg-gray-50/50">
                      <td class="p-3 text-center border-r border-gray-200"><input type="checkbox" v-model="row.selected" class="w-4 h-4 rounded border-gray-300" /></td>
                      <td class="p-3 text-sm font-bold text-gray-600 text-center border-r border-gray-200">{{ idx + 1 }}</td>
                      <td class="p-0 border-r border-gray-200"><select v-model="row.product" class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none cursor-pointer"><option value="" disabled>Select product</option><option v-for="p in products" :key="p.id" :value="p.name">{{ p.name }}</option></select></td>
                      <td class="p-0 border-r border-gray-200"><select v-model="row.uom" class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none cursor-pointer"><option value="" disabled>Select UOM</option><option v-for="u in uomList" :key="u.id" :value="u.name">{{ u.name }}</option></select></td>
                      <td class="p-0 border-r border-gray-200"><input type="number" v-model.number="row.qty" min="0" class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none" /></td>
                      <td class="p-0 border-r border-gray-200"><input type="number" v-model.number="row.waste_pct" min="0" max="100" class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none" /></td>
                      <td class="p-3 text-center border-r border-gray-200">
                        <button @click="row.is_optional = !row.is_optional" :class="['relative inline-flex h-5 w-9 rounded-full transition-colors', row.is_optional ? 'bg-[#0b529c]' : 'bg-gray-200']"><span :class="['inline-block w-4 h-4 rounded-full bg-white shadow transition-transform mt-0.5', row.is_optional ? 'translate-x-4' : 'translate-x-0.5']"></span></button>
                      </td>
                      <td class="p-3 text-xs text-gray-400 border-r border-gray-200">—</td>
                      <td class="p-3 text-center"><button @click="removeIngredientRow(idx)" class="p-1.5 hover:bg-red-50 text-red-400 hover:text-red-600 rounded-lg transition-colors"><Trash2 :size="13" /></button></td>
                    </tr>
                  </tbody>
                </table>
                <div class="p-4"><button @click="addIngredientRow" class="flex items-center gap-1.5 px-4 py-2 border border-gray-200 hover:bg-gray-50 rounded-lg text-xs font-bold text-gray-700 transition-colors"><Plus :size="14" /> Add Row</button></div>
              </div>
            </div>

            <!-- Ingredient Alternatives -->
            <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
              <button @click="alternativesSectionOpen = !alternativesSectionOpen" class="w-full flex items-center justify-between px-6 py-4 hover:bg-gray-50 transition-colors">
                <span class="text-sm font-bold text-gray-800">Product Ingredient Alternative Properties</span>
                <ChevronDown :size="16" :class="['text-gray-400 transition-transform duration-200', alternativesSectionOpen ? 'rotate-180' : '']" />
              </button>
              <div v-if="alternativesSectionOpen" class="border-t border-gray-100">
                <table class="w-full text-left border-collapse">
                  <thead>
                    <tr class="bg-gray-50/75 text-xs font-bold text-gray-600 border-b border-gray-200">
                      <th class="p-3.5 w-12 text-center border-r border-gray-200"><input type="checkbox" class="w-4 h-4 rounded border-gray-300" /></th>
                      <th class="p-3.5 w-14 text-center border-r border-gray-200">No.</th>
                      <th class="p-3.5 border-r border-gray-200"><span class="flex items-center gap-1">Ingredient Alternative <HelpCircle :size="12" class="text-gray-400" /></span></th>
                      <th class="p-3.5 border-r border-gray-200">Alternative For</th>
                      <th class="p-3.5 border-r border-gray-200">UOM <span class="text-red-500">*</span></th>
                      <th class="p-3.5 border-r border-gray-200">Required Quantity <span class="text-red-500">*</span></th>
                      <th class="p-3.5 border-r border-gray-200">Waste In (%)</th>
                      <th class="p-3.5 border-r border-gray-200 text-center">Is Optional</th>
                      <th class="p-3.5 w-12 text-center"><svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="text-gray-400 mx-auto"><line x1="4" y1="21" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="3"/></svg></th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="ingredientAlternatives.length === 0"><td colspan="9" class="p-8 text-center text-sm font-semibold text-gray-400">No rows — add ingredients above to populate alternatives</td></tr>
                    <tr v-for="(alt, idx) in ingredientAlternatives" :key="alt.id" class="border-b border-gray-100 hover:bg-gray-50/50">
                      <td class="p-3 text-center border-r border-gray-200"><input type="checkbox" class="w-4 h-4 rounded border-gray-300" /></td>
                      <td :class="['p-3 text-sm font-bold text-center border-r border-gray-200', alt.uomMismatch ? 'text-red-500' : 'text-gray-600']">{{ idx + 1 }}</td>
                      <td class="p-0 border-r border-gray-200"><input v-model="alt.alternative" type="text"  class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none" /></td>
                      <td class="p-3 text-sm text-gray-600 border-r border-gray-200">{{ alt.alternativeFor }}</td>
                      <td class="p-0 border-r border-gray-200"><select v-model="alt.uom" class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none cursor-pointer"><option value="">—</option><option v-for="u in uomList" :key="u.id" :value="u.name">{{ u.name }}</option></select></td>
                      <td class="p-0 border-r border-gray-200"><input type="number" v-model.number="alt.qty" min="0" class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none" /></td>
                      <td class="p-0 border-r border-gray-200"><input type="number" v-model.number="alt.waste_pct" min="0" max="100" class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none" /></td>
                      <td class="p-3 text-center border-r border-gray-200">
                        <button @click="alt.is_optional = !alt.is_optional" :class="['relative inline-flex h-5 w-9 rounded-full transition-colors', alt.is_optional ? 'bg-[#0b529c]' : 'bg-gray-200']"><span :class="['inline-block w-4 h-4 rounded-full bg-white shadow transition-transform mt-0.5', alt.is_optional ? 'translate-x-4' : 'translate-x-0.5']"></span></button>
                      </td>
                      <td class="p-3 text-center"><button class="p-1.5 hover:bg-gray-100 text-gray-400 rounded-lg"><Expand :size="13" /></button></td>
                    </tr>
                  </tbody>
                </table>
                <div v-if="hasUomMismatch" class="m-4 border border-amber-200 bg-amber-50 rounded-xl p-4 flex items-start gap-3">
                  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-amber-500 shrink-0 mt-0.5"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>
                  <p class="text-xs text-amber-700 font-medium leading-relaxed">There are product ingredient alternatives highlighted with red numbers that do not share the same measurement category as their parent ingredients. Please configure their properties manually.</p>
                </div>
              </div>
            </div>

            <!-- Product Attribute Values -->
            <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
              <button @click="attributesSectionOpen = !attributesSectionOpen" class="w-full flex items-center justify-between px-6 py-4 hover:bg-gray-50 transition-colors">
                <span class="text-sm font-bold text-gray-800">Product Attribute Values</span>
                <ChevronDown :size="16" :class="['text-gray-400 transition-transform duration-200', attributesSectionOpen ? 'rotate-180' : '']" />
              </button>
              <div v-if="attributesSectionOpen" class="border-t border-gray-100 p-6 space-y-4">
                <div v-if="formState.attributes.length === 0" class="text-sm text-gray-400 text-center py-2">No attributes yet.</div>
                <div v-for="(attr, idx) in formState.attributes" :key="attr.id" class="flex items-start gap-4 flex-wrap">
                  <div class="w-56 shrink-0">
                    <label class="block text-xs font-bold text-gray-600 mb-1.5 uppercase tracking-wider">Product Attribute</label>
                    <div class="relative">
                      <select v-model="attr.type" class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm appearance-none bg-white focus:outline-none">
                        <option value="" disabled>Select type</option>
                        <option v-for="t in attributeTypeOptions" :key="t" :value="t">{{ t }}</option>
                      </select>
                      <ChevronDown :size="14" class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                    </div>
                  </div>
                  <div v-if="attr.type === 'Color'" class="flex-1">
                    <label class="block text-xs font-bold text-gray-600 mb-1.5 uppercase tracking-wider">Select Color</label>
                    <div class="flex items-center gap-2">
                      <div class="flex-1 flex items-center border border-gray-200 rounded-xl overflow-hidden">
                        <span class="px-3 text-gray-400 text-sm font-semibold">#</span>
                        <input v-model="attr.color" type="text"  class="flex-1 py-2.5 text-sm focus:outline-none font-mono" />
                      </div>
                      <input type="color" :value="'#' + attr.color.replace('#','')" @input="attr.color = ($event.target as HTMLInputElement).value.replace('#','')" class="w-10 h-10 rounded-xl border border-gray-200 cursor-pointer p-0.5" />
                      <button @click="removeAttribute(idx)" class="p-2 hover:bg-red-50 text-gray-400 hover:text-red-500 rounded-lg"><Trash2 :size="14" /></button>
                    </div>
                  </div>
                  <div v-else-if="attr.type === 'Size'" class="flex-1">
                    <label class="block text-xs font-bold text-gray-600 mb-1.5 uppercase tracking-wider">Select Sizes</label>
                    <div class="flex flex-wrap gap-1.5 mb-2">
                      <span v-for="s in attr.sizes" :key="s" class="flex items-center gap-1 px-2.5 py-0.5 bg-blue-50 border border-blue-200 text-blue-700 rounded-full text-xs font-bold">{{ s }}<button @click="removeSize(attr, s)" class="ml-0.5 text-blue-400 hover:text-blue-700 leading-none">×</button></span>
                    </div>
                    <div class="flex items-center gap-2 flex-wrap">
                      <input v-model="attr.newSize" @keydown.enter.prevent="addSize(attr)" type="text"  class="border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none w-40" />
                      <button @click="addSize(attr)" class="px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded-xl text-xs font-bold text-gray-700">Add</button>
                      <div class="flex gap-1 flex-wrap">
                        <button v-for="p in sizePresets" :key="p" @click="!attr.sizes.includes(p) && attr.sizes.push(p)" class="px-2 py-1 border border-gray-200 hover:bg-gray-50 rounded-lg text-xs font-semibold text-gray-600">{{ p }}</button>
                      </div>
                    </div>
                  </div>
                  <div v-else-if="attr.type" class="flex-1">
                    <label class="block text-xs font-bold text-gray-600 mb-1.5 uppercase tracking-wider">{{ attr.type }} Values</label>
                    <input type="text"  class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none" />
                  </div>
                  <button v-if="attr.type !== 'Color'" @click="removeAttribute(idx)" class="mt-6 p-2 hover:bg-red-50 text-gray-400 hover:text-red-500 rounded-lg self-start"><Trash2 :size="14" /></button>
                </div>
                <button @click="addAttribute" class="flex items-center gap-1.5 px-4 py-2 border border-gray-200 hover:bg-gray-50 rounded-lg text-xs font-bold text-gray-700 transition-colors"><Plus :size="14" /> Add Product Attribute</button>
              </div>
            </div>

            <!-- Product Alternatives (ProductAlternative) -->
            <div v-if="formState.has_alternative" class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
              <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100">
                <div class="flex items-center gap-1.5">
                  <span class="text-sm font-bold text-gray-800">Product Alternatives</span>
                  <HelpCircle :size="13" class="text-gray-400 cursor-pointer" title="Product-level substitutes for sales/procurement (e.g. Pepsi as an alternative to Coca-Cola)." />
                </div>
                <button @click="addAlternativeRow" class="flex items-center gap-1.5 px-3 py-1.5 bg-[#0b529c] text-white rounded-lg text-xs font-semibold hover:bg-[#0c65bd]"><Plus :size="14" /> Add Alternative</button>
              </div>
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-gray-50/75 text-xs font-bold text-gray-600 border-b border-gray-200">
                    <th class="p-3.5 w-14 text-center border-r border-gray-200">No.</th>
                    <th class="p-3.5 border-r border-gray-200">Alternative Product</th>
                    <th class="p-3.5 w-12 text-center">—</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="formState.alternatives.length === 0"><td colspan="3" class="p-8 text-center text-sm font-semibold text-gray-400">No alternative products registered.</td></tr>
                  <tr v-for="(alt, idx) in formState.alternatives" :key="alt.id" class="border-b border-gray-100 hover:bg-gray-50/50">
                    <td class="p-3 text-center text-sm font-bold text-gray-600 border-r border-gray-200">{{ idx + 1 }}</td>
                    <td class="p-0 border-r border-gray-200">
                      <select v-model="alt.product" class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none cursor-pointer">
                        <option value="" disabled>Select substitute product</option>
                        <option v-for="p in products.filter(pp => pp.name !== formState.name)" :key="p.id" :value="p.name">{{ p.name }}</option>
                      </select>
                    </td>
                    <td class="p-3 text-center"><button @click="removeAlternativeRow(idx)" class="p-1.5 hover:bg-red-50 text-red-400 hover:text-red-600 rounded-lg"><Trash2 :size="13" /></button></td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Product Modifiers (ProductModifier / ProductModifierItem) -->
            <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
              <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100">
                <div class="flex items-center gap-1.5">
                  <span class="text-sm font-bold text-gray-800">Product Modifiers</span>
                  <HelpCircle :size="13" class="text-gray-400 cursor-pointer" title="Optional add-ons selectable at the POS for hospitality products (e.g. Extra Cheese on a Pizza)." />
                </div>
                <button @click="addModifierRow" class="flex items-center gap-1.5 px-3 py-1.5 bg-[#0b529c] text-white rounded-lg text-xs font-semibold hover:bg-[#0c65bd]"><Plus :size="14" /> Add Modifier</button>
              </div>
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-gray-50/75 text-xs font-bold text-gray-600 border-b border-gray-200">
                    <th class="p-3.5 w-14 text-center border-r border-gray-200">No.</th>
                    <th class="p-3.5 border-r border-gray-200">Modifier Name</th>
                    <th class="p-3.5 border-r border-gray-200">Added Product</th>
                    <th class="p-3.5 w-12 text-center">—</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="formState.modifiers.length === 0"><td colspan="4" class="p-8 text-center text-sm font-semibold text-gray-400">No modifiers. Add POS add-ons like "Extra Cheese".</td></tr>
                  <tr v-for="(mod, idx) in formState.modifiers" :key="mod.id" class="border-b border-gray-100 hover:bg-gray-50/50">
                    <td class="p-3 text-center text-sm font-bold text-gray-600 border-r border-gray-200">{{ idx + 1 }}</td>
                    <td class="p-0 border-r border-gray-200"><input v-model="mod.name" type="text"  class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none" /></td>
                    <td class="p-0 border-r border-gray-200">
                      <select v-model="mod.added_product" class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none cursor-pointer">
                        <option value="" disabled>Select added product</option>
                        <option v-for="p in products" :key="p.id" :value="p.name">{{ p.name }}</option>
                      </select>
                    </td>
                    <td class="p-3 text-center"><button @click="removeModifierRow(idx)" class="p-1.5 hover:bg-red-50 text-red-400 hover:text-red-600 rounded-lg"><Trash2 :size="13" /></button></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- 4. UOM TAB CONTENT -->
          <div v-else-if="activeTab === 'UOM'" class="space-y-6">
            <div v-if="isStrictInherit" class="inline-flex items-center gap-1.5 text-[11px] font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2.5 py-1 rounded-full">
              <Lock :size="11" /> {{ inheritedBadgeText }}
            </div>
            <fieldset :disabled="isStrictInherit" :class="['border-0 p-0 m-0 space-y-6', isStrictInherit ? 'opacity-60' : '']">
            <!-- Alert Info Box when no default UOM is selected -->
            <div v-if="!formState.uom" class="uom-info-box border border-dashed border-blue-300 bg-[#eff6ff] rounded-2xl p-6 flex gap-4 animate-fade-in">
              <div class="info-icon-wrapper shrink-0 mt-0.5">
                <Info :size="20" class="text-blue-500 fill-blue-100" />
              </div>
              <div class="info-text-content space-y-2">
                <h4 class="text-sm font-bold text-gray-900 leading-snug">
                  This section will be available when you Select a Default Measurement Unit
                </h4>
                <p class="text-xs text-blue-700/80 leading-relaxed font-medium">
                  Select the default unit of measurement in the <span class="font-bold text-blue-900">Basics</span> tab before adding alternative units and their conversion ratios. This ensures the inventory system has a single source of truth for unit conversions and can accurately perform stock calculations across different units of measurement.
                </p>
              </div>
            </div>

            <!-- Tabular structure when default UOM is selected -->
            <div v-else class="form-card-wrapper bg-white border border-gray-200 rounded-2xl p-6 shadow-sm space-y-4 animate-fade-in">
              <div class="flex items-center gap-1.5 mb-1">
                <h3 class="text-sm font-bold text-gray-800 uppercase tracking-wider">Product Measurement Conversion</h3>
                <HelpCircle :size="15" class="text-gray-400 cursor-pointer" title="Alternative units and conversion ratios" />
              </div>
              <p class="text-xs text-gray-500 leading-relaxed font-medium">
                Define alternative measurement units and their conversion ratios to the default inventory unit, <span class="font-bold text-gray-900">{{ formState.uom }}</span>. This enables the system to maintain a single source of truth for inventory while allowing the product to be purchased, stocked, and sold in different measurement units.
              </p>

              <div class="border border-gray-200 rounded-xl mt-4">
                <table class="w-full text-left border-collapse">
                  <thead>
                    <tr class="bg-gray-50/75 border-b border-gray-200 text-xs font-bold text-gray-650">
                      <th class="p-3.5 w-12 text-center border-r border-gray-200">
                        <input type="checkbox" v-model="isAllUomSelected" class="custom-checkbox w-4 h-4 rounded border-gray-300 text-[#0b529c] focus:ring-[#0b529c]" />
                      </th>
                      <th class="p-3.5 w-16 text-center border-r border-gray-200">No.</th>
                      <th class="p-3.5 border-r border-gray-200 px-4">Measurement Unit</th>
                      <th class="p-3.5 border-r border-gray-200 px-4">Conversion Rate *</th>
                      <th class="p-3.5 w-16 text-center border-l border-gray-200">
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="text-gray-400 mx-auto">
                          <line x1="4" y1="21" x2="4" y2="3"></line>
                          <line x1="12" y1="21" x2="12" y2="3"></line>
                          <line x1="20" y1="21" x2="20" y2="3"></line>
                        </svg>
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="formState.uom_conversions.length === 0">
                      <td colspan="5" class="p-8 text-center text-sm font-semibold text-gray-400 bg-white">
                        No Row
                      </td>
                    </tr>
                    <tr 
                      v-else 
                      v-for="(row, idx) in formState.uom_conversions" 
                      :key="row.id"
                      class="border-b border-gray-100 hover:bg-gray-50/50 bg-white animate-fade-in"
                    >
                      <td class="p-3.5 w-12 text-center align-middle border-r border-gray-200">
                        <input type="checkbox" v-model="row.selected" class="w-4 h-4 rounded border-gray-300 text-[#0b529c]" />
                      </td>
                      <td class="p-3.5 w-16 text-sm font-bold text-gray-650 text-center align-middle border-r border-gray-200">{{ idx + 1 }}</td>
                      <td class="border-r border-gray-200 align-middle p-0 relative">
                        <div 
                          @click.stop="toggleDropdown(idx, 'unit', $event)"
                          class="w-full h-full px-4 py-3.5 text-sm text-gray-800 font-semibold cursor-pointer hover:bg-gray-50/50 transition-colors select-none flex items-center justify-between"
                        >
                          <span>{{ row.unit || 'Select unit' }}</span>
                          <ChevronDown :size="14" class="text-gray-400" />
                        </div>
                        
                        <!-- Floating popover menu for Measurement Unit -->
                        <div 
                          v-if="activeDropdownRowIdx === idx && activeDropdownType === 'unit'" 
                          class="absolute left-0 top-full mt-1 z-50 bg-white border border-gray-200 rounded-2xl shadow-xl p-1.5 min-w-[200px] text-left animate-fade-in"
                        >
                          <div 
                            v-for="unitOption in getAlternativeUnits(formState.uom)" 
                            :key="unitOption"
                            @click.stop="row.unit = unitOption; closeDropdowns()"
                            class="hover:bg-gray-50 p-2.5 rounded-xl flex items-center justify-between cursor-pointer transition-colors"
                          >
                            <span class="text-sm font-semibold text-gray-700">{{ unitOption }}</span>
                            <Check v-if="row.unit === unitOption" :size="14" class="text-gray-900" />
                          </div>
                        </div>
                      </td>
                      <td class="border-r border-gray-200 align-middle p-0 relative">
                        <div class="flex items-center w-full h-full relative">
                          <input 
                            type="number" 
                            v-model.number="row.rate" 
                            
                            @click.stop="toggleDropdown(idx, 'rate', $event)"
                            class="w-full h-full px-4 py-3.5 bg-transparent focus:outline-none text-sm text-gray-800 placeholder-gray-450 font-semibold"
                          />
                          
                          <!-- Floating popover menu for Conversion Rate -->
                          <div 
                            v-if="activeDropdownRowIdx === idx && activeDropdownType === 'rate' && row.unit" 
                            class="absolute left-0 top-full mt-1 z-50 bg-white border border-gray-200 rounded-2xl shadow-xl p-2 min-w-[260px] text-left animate-fade-in"
                          >
                            <div 
                              v-for="option in getRatioOptions(row.unit, formState.uom)" 
                              :key="option.rate"
                              @click.stop="row.rate = option.rate; closeDropdowns()"
                              :class="[
                                'hover:bg-gray-50 p-2.5 rounded-xl flex items-center justify-between cursor-pointer transition-all',
                                row.rate === option.rate ? 'bg-gray-50/80' : ''
                              ]"
                            >
                              <div>
                                <span class="text-xs font-bold text-gray-900 block">{{ option.label }}</span>
                                <span class="text-[10px] text-gray-400 font-semibold block mt-0.5">{{ option.desc }}</span>
                              </div>
                              <Check v-if="row.rate === option.rate" :size="14" class="text-gray-900" />
                            </div>
                          </div>
                        </div>
                      </td>
                      <td class="p-3.5 w-16 text-center align-middle border-l border-gray-200 relative">
                        <button 
                          @click.stop="toggleDropdown(idx, 'actions', $event)"
                          class="p-1.5 hover:bg-gray-100 rounded-lg transition-colors inline-flex items-center justify-center text-gray-450 hover:text-gray-700"
                        >
                          <Expand :size="15" />
                        </button>
                        <!-- Floating actions popover menu -->
                        <div 
                          v-if="activeDropdownRowIdx === idx && activeDropdownType === 'actions'" 
                          class="absolute right-0 top-full mt-1 z-50 bg-white border border-gray-200 rounded-2xl shadow-xl p-1 min-w-[120px] text-left animate-fade-in"
                        >
                          <button 
                            @click.stop="removeUomRow(idx); closeDropdowns()" 
                            class="w-full text-left px-3 py-2.5 text-xs font-bold text-red-650 hover:bg-red-50 hover:text-red-700 rounded-xl transition-colors flex items-center gap-1.5"
                          >
                            <Trash2 :size="12" />
                            Delete Row
                          </button>
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div class="flex items-center gap-3 mt-4">
                <button 
                  @click="addUomRow" 
                  class="flex items-center gap-1.5 px-4 py-2 border border-gray-200 hover:border-gray-300 hover:bg-gray-50 rounded-lg text-xs font-bold text-gray-700 transition-colors"
                >
                  <Plus :size="14" />
                  Add Row
                </button>
                <button 
                  v-if="hasSelectedUomRows"
                  @click="deleteSelectedUomRows" 
                  class="flex items-center gap-1.5 px-4 py-2 border border-red-200 hover:border-red-300 hover:bg-red-50 rounded-lg text-xs font-bold text-red-650 hover:text-red-700 transition-colors animate-fade-in"
                >
                  <Trash2 :size="14" />
                  Delete Selected
                </button>
              </div>
            </div>
            </fieldset>
          </div>

          <!-- 5. PRICING TAB CONTENT -->
          <div v-else-if="activeTab === 'Pricing'" class="space-y-6">
            <div class="form-card-wrapper bg-white border border-gray-200 rounded-2xl p-6 shadow-sm space-y-4">
              <h3 class="text-sm font-bold text-gray-800 uppercase tracking-wider border-b border-gray-100 pb-3">Pricing Settings</h3>

              <!-- STRICT inherit: inherited default price (read-only) + editable Variant Price Override -->
              <template v-if="isStrictInherit">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div class="field-item">
                    <label class="field-label-premium flex items-center gap-1.5 text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">
                      Inherited Default Price ($)
                      <span class="inline-flex items-center gap-1 text-[10px] font-bold text-amber-700 bg-amber-50 border border-amber-200 px-1.5 py-0.5 rounded-full normal-case tracking-normal">
                        <Lock :size="9" /> {{ inheritedBadgeText }}
                      </span>
                    </label>
                    <input
                      :value="selectedParentData?.price"
                      type="number"
                      disabled
                      class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm bg-gray-50 text-gray-500 cursor-not-allowed focus:outline-none"
                    />
                    <p class="field-tip-desc text-[10px] text-gray-400 mt-1 font-medium">Base price defined on the parent product.</p>
                  </div>
                  <div class="field-item">
                    <label class="field-label-premium flex items-center gap-1.5 text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">
                      Variant Price Override ($)
                      <span class="inline-flex items-center gap-1 text-[10px] font-bold text-green-700 bg-green-50 border border-green-200 px-1.5 py-0.5 rounded-full normal-case tracking-normal">
                        <Edit2 :size="9" /> Editable
                      </span>
                    </label>
                    <input
                      v-model.number="formState.price"
                      type="number"
                      step="0.01"
                      class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:border-gray-300 focus:outline-none"
                    />
                    <p class="field-tip-desc text-[10px] text-gray-400 mt-1 font-medium">
                      Overrides the inherited price for this variant only. Leave equal to the inherited price to keep it.
                    </p>
                  </div>
                </div>
              </template>

              <!-- Normal / soft pricing -->
              <template v-else>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div class="field-item">
                    <label class="field-label-premium block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">Default Price ($)</label>
                    <input
                      v-model="formState.price"
                      type="number"
                      step="0.01"
                      class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:border-gray-300 focus:outline-none"
                    />
                    <p class="field-tip-desc text-[10px] text-gray-400 mt-1 font-medium">
                      {{ formState.is_tax_included ? 'This price already includes tax.' : 'This price is pre-tax (tax added at POS).' }}
                    </p>
                  </div>
                </div>
              </template>

              <!-- Tax-Inclusive Pricing (Product.is_tax_included) -->
              <fieldset :disabled="isStrictInherit" :class="['border-0 p-0 m-0', isStrictInherit ? 'opacity-60' : '']">
              <label class="flex gap-3.5 p-3.5 rounded-xl border border-gray-100 hover:bg-gray-50 transition-all cursor-pointer max-w-xl">
                <input type="checkbox" v-model="formState.is_tax_included" class="sr-only" />
                <div :class="['w-5 h-5 rounded border flex items-center justify-center shrink-0 mt-0.5 transition-colors', formState.is_tax_included ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']">
                  <Check v-if="formState.is_tax_included" :size="13" />
                </div>
                <div>
                  <span class="text-sm font-semibold text-gray-900 block mb-0.5">Price is Tax-Inclusive</span>
                  <span class="text-xs text-gray-400 font-medium leading-relaxed block">
                    When enabled, the price entered above already includes tax. When disabled, tax is calculated on top of the price at POS. This directly affects totals at checkout.
                  </span>
                </div>
              </label>
              </fieldset>
            </div>
          </div>

          <!-- 6. INVENTORY TAB CONTENT -->
          <div v-else-if="activeTab === 'Inventory'" class="space-y-4">
            <div v-if="isStrictInherit" class="inline-flex items-center gap-1.5 text-[11px] font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2.5 py-1 rounded-full">
              <Lock :size="11" /> {{ inheritedBadgeText }}
            </div>
            <fieldset :disabled="isStrictInherit" :class="['border-0 p-0 m-0 space-y-4', isStrictInherit ? 'opacity-60' : '']">

            <!-- A. Product Inventory Policy Collapsible Card -->
            <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
              <button @click="policySectionOpen = !policySectionOpen" class="w-full flex items-center justify-between px-6 py-5 hover:bg-gray-50/50 transition-colors">
                <span class="text-sm font-bold text-gray-800">Product Inventory Policy</span>
                <ChevronDown :size="16" :class="['text-gray-400 transition-transform duration-200', policySectionOpen ? 'rotate-180' : '']" />
              </button>
              
              <div v-if="policySectionOpen" class="border-t border-gray-100 p-6">
                <!-- Empty State -->
                <div v-if="formState.inventory_policies.length === 0" class="text-center py-8">
                  <p class="text-sm font-semibold text-gray-400 mb-4">No Policies Configured Yet</p>
                  <button @click="addPolicyRow" class="inline-flex items-center gap-1.5 px-4 py-2 border border-gray-200 hover:border-gray-300 hover:bg-gray-50 rounded-xl text-xs font-bold text-gray-700 transition-colors">
                    <Plus :size="14" /> Add Policy
                  </button>
                </div>
                
                <!-- Table View -->
                <div v-else class="space-y-4">
                  <div class="border border-gray-200 rounded-xl overflow-hidden">
                    <table class="w-full text-left border-collapse">
                      <thead>
                        <tr class="bg-gray-50/75 text-xs font-bold text-gray-600 border-b border-gray-200">
                          <th class="p-3.5 w-12 text-center border-r border-gray-200">
                            <input type="checkbox" v-model="isAllPoliciesSelected" class="w-4 h-4 rounded border-gray-300" />
                          </th>
                          <th class="p-3.5 w-14 text-center border-r border-gray-200">No.</th>
                          <th class="p-3.5 border-r border-gray-200">Location</th>
                          <th class="p-3.5 border-r border-gray-200">Reorder Level</th>
                          <th class="p-3.5 border-r border-gray-200">Reorder Quantity</th>
                          <th class="p-3.5 w-14 text-center">
                            <button class="p-1 hover:bg-gray-100 rounded text-gray-500" title="Columns Settings">
                              <Columns :size="14" class="mx-auto" />
                            </button>
                          </th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr v-for="(policy, idx) in formState.inventory_policies" :key="policy.id" class="border-b border-gray-100 hover:bg-gray-50/20 bg-white">
                          <td class="p-3 text-center border-r border-gray-200">
                            <input type="checkbox" v-model="policy.selected" class="w-4 h-4 rounded border-gray-300" />
                          </td>
                          <td class="p-3 text-center text-sm font-bold text-gray-600 border-r border-gray-200">{{ idx + 1 }}</td>
                          <td class="p-0 border-r border-gray-200">
                            <select v-model="policy.location" class="w-full px-3 py-3 text-sm bg-transparent focus:outline-none cursor-pointer">
                              <option v-for="loc in locationsList" :key="loc" :value="loc">{{ loc }}</option>
                            </select>
                          </td>
                          <td class="p-0 border-r border-gray-200">
                            <input type="number" v-model.number="policy.reorder_level" class="w-full px-3 py-3 text-sm bg-transparent focus:outline-none font-mono" />
                          </td>
                          <td class="p-0 border-r border-gray-200">
                            <input type="number" v-model.number="policy.reorder_qty" class="w-full px-3 py-3 text-sm bg-transparent focus:outline-none font-mono" />
                          </td>
                          <td class="p-3 text-center flex items-center justify-center gap-1.5">
                            <button @click="removePolicyRow(idx)" class="p-1 hover:bg-red-50 text-red-400 hover:text-red-600 rounded transition-colors" title="Delete Row">
                              <Trash2 :size="13" />
                            </button>
                            <button class="p-1 hover:bg-gray-50 text-gray-400 hover:text-gray-600 rounded" title="Expand Details">
                              <Maximize2 :size="12" />
                            </button>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                  
                  <button @click="addPolicyRow" class="inline-flex items-center gap-1.5 px-4 py-2 border border-gray-200 hover:border-gray-300 hover:bg-gray-50 rounded-xl text-xs font-bold text-gray-700 transition-colors">
                    <Plus :size="14" /> Add Policy
                  </button>
                </div>
              </div>
            </div>

            <!-- B. Stock Levels Collapsible Card -->
            <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
              <button @click="stockLevelsSectionOpen = !stockLevelsSectionOpen" class="w-full flex items-center justify-between px-6 py-5 hover:bg-gray-50/50 transition-colors">
                <span class="text-sm font-bold text-gray-800">Stock Levels</span>
                <ChevronDown :size="16" :class="['text-gray-400 transition-transform duration-200', stockLevelsSectionOpen ? 'rotate-180' : '']" />
              </button>
              
              <div v-if="stockLevelsSectionOpen" class="border-t border-gray-100 p-6">
                <!-- Header: which locations carry this product + total available -->
                <div class="flex items-center justify-between mb-4">
                  <div class="flex items-center gap-1.5">
                    <span class="text-xs font-bold text-gray-700">Stock by Location</span>
                    <HelpCircle :size="13" class="text-gray-400 cursor-pointer" title="Where this product is stocked. Each bar shows the available quantity (on hand minus reserved) per location." />
                  </div>
                  <span class="text-xs text-gray-500">
                    Total Available:
                    <strong class="font-mono text-gray-900">{{ totalAvailableStock }}</strong>
                    <span class="text-gray-400">{{ formState.uom || 'units' }}</span>
                  </span>
                </div>

                <!-- Location list -->
                <div class="border border-gray-200 rounded-xl divide-y divide-gray-100 overflow-hidden">
                  <div
                    v-for="loc in stockByLocation"
                    :key="loc.location"
                    class="flex items-center gap-4 px-4 py-3.5 transition-colors"
                    :class="loc.hasStock ? 'hover:bg-gray-50/60' : 'bg-gray-50/30'"
                  >
                    <!-- Location identity -->
                    <div class="flex items-center gap-2.5 w-52 shrink-0">
                      <div class="w-8 h-8 rounded-lg flex items-center justify-center shrink-0" :class="loc.hasStock ? 'bg-blue-50' : 'bg-gray-100'">
                        <MapPin :size="15" :class="loc.hasStock ? 'text-[#0b529c]' : 'text-gray-400'" />
                      </div>
                      <div class="min-w-0">
                        <div class="text-sm font-semibold text-gray-800 truncate">{{ loc.location }}</div>
                        <div class="text-[11px]" :class="loc.hasStock ? 'text-emerald-600' : 'text-gray-400'">
                          {{ loc.hasStock ? 'Carries this product' : 'Not stocked here' }}
                        </div>
                      </div>
                    </div>

                    <!-- Quantity + proportional bar -->
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center justify-between mb-1.5">
                        <span class="text-[11px] uppercase tracking-wide text-gray-400 font-semibold">Available</span>
                        <span class="text-sm font-bold font-mono" :class="stockQtyClass(loc.available)">
                          {{ loc.available }}<span class="text-[11px] font-normal text-gray-400 ml-1">{{ formState.uom || 'units' }}</span>
                        </span>
                      </div>
                      <div class="h-2 rounded-full bg-gray-100 overflow-hidden">
                        <div class="h-full rounded-full transition-all duration-300" :class="stockBarClass(loc.available)" :style="{ width: stockBarWidth(loc.available) }"></div>
                      </div>
                      <div class="flex items-center gap-4 mt-1.5">
                        <span class="text-[11px] text-gray-400">On hand <span class="font-mono text-gray-600">{{ loc.onHand }}</span></span>
                        <span class="text-[11px] text-gray-400">Reserved <span class="font-mono text-amber-600">{{ loc.reserved }}</span></span>
                      </div>
                    </div>

                    <!-- Actions -->
                    <div class="flex items-center gap-2 shrink-0">
                      <button
                        @click="openMoveModal(loc.location)"
                        :disabled="!loc.hasStock"
                        class="inline-flex items-center gap-1.5 px-3 py-1.5 border border-gray-200 rounded-lg text-xs font-semibold text-gray-700 hover:border-gray-300 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                        title="Transfer stock from this location"
                      >
                        <ArrowRightLeft :size="13" /> Move
                      </button>
                      <button
                        @click="openStockInModalFor(loc.location)"
                        class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-[#0b529c] hover:bg-[#0a4785] text-white rounded-lg text-xs font-semibold transition-colors"
                        title="Add stock to this location"
                      >
                        <Plus :size="13" /> Add
                      </button>
                      <button
                        @click="goToLocationStock(loc.location)"
                        class="p-1.5 rounded-lg text-gray-400 hover:text-[#0b529c] hover:bg-blue-50 transition-colors"
                        title="View this location in Stock Summary"
                      >
                        <ExternalLink :size="14" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- C. Standard Inventory Tracking Flags Card -->
            <div class="bg-white border border-gray-200 rounded-2xl p-6 shadow-sm">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <!-- Track Stock -->
                <label class="flex gap-3 cursor-pointer">
                  <input type="checkbox" v-model="formState.track_stock" class="sr-only" />
                  <div :class="['w-5 h-5 rounded border flex items-center justify-center shrink-0 mt-0.5 transition-colors', formState.track_stock ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']">
                    <Check v-if="formState.track_stock" :size="12" />
                  </div>
                  <div>
                    <span class="text-sm font-semibold text-gray-900 block">Track Stock</span>
                    <span class="text-xs text-gray-400 leading-relaxed block mt-0.5">Turn this on to monitor stock levels and inventory movements for this product.</span>
                  </div>
                </label>

                <!-- Track Batch / Lot -->
                <label class="flex gap-3 cursor-pointer">
                  <input type="checkbox" v-model="formState.track_batch" class="sr-only" />
                  <div :class="['w-5 h-5 rounded border flex items-center justify-center shrink-0 mt-0.5 transition-colors', formState.track_batch ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']">
                    <Check v-if="formState.track_batch" :size="12" />
                  </div>
                  <div>
                    <span class="text-sm font-semibold text-gray-900 block">Track Batch / Lot</span>
                    <span class="text-xs text-gray-400 leading-relaxed block mt-0.5">Enable this to group items into batches or lots for tracking production or purchase groups.</span>
                  </div>
                </label>

                <!-- Track Expiry Dates -->
                <label class="flex gap-3 cursor-pointer">
                  <input type="checkbox" v-model="formState.track_expiry" class="sr-only" />
                  <div :class="['w-5 h-5 rounded border flex items-center justify-center shrink-0 mt-0.5 transition-colors', formState.track_expiry ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']">
                    <Check v-if="formState.track_expiry" :size="12" />
                  </div>
                  <div>
                    <span class="text-sm font-semibold text-gray-900 block">Track Expiry Dates</span>
                    <span class="text-xs text-gray-400 leading-relaxed block mt-0.5">Enable this if the product has an expiration date that must be monitored, such as food, medicine, or perishable goods.</span>
                  </div>
                </label>

                <!-- Allow Transfers Between Locations -->
                <label class="flex gap-3 cursor-pointer">
                  <input type="checkbox" v-model="formState.allow_transfers" class="sr-only" />
                  <div :class="['w-5 h-5 rounded border flex items-center justify-center shrink-0 mt-0.5 transition-colors', formState.allow_transfers ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']">
                    <Check v-if="formState.allow_transfers" :size="12" />
                  </div>
                  <div>
                    <span class="text-sm font-semibold text-gray-900 block">Allow Transfers Between Locations</span>
                    <span class="text-xs text-gray-400 leading-relaxed block mt-0.5">Turn this on if the product can be moved between warehouses, branches, or stores. Disable if it must remain in a fixed location.</span>
                  </div>
                </label>
              </div>
            </div>

            <!-- D. Custom Costing Rule Collapsible Card -->
            <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
              <button @click="costingRuleSectionOpen = !costingRuleSectionOpen" class="w-full flex items-center justify-between px-6 py-5 hover:bg-gray-50/50 transition-colors">
                <span class="text-sm font-bold text-gray-800">Custom Costing Rule</span>
                <ChevronDown :size="16" :class="['text-gray-400 transition-transform duration-200', costingRuleSectionOpen ? 'rotate-180' : '']" />
              </button>
              
              <div v-if="costingRuleSectionOpen" class="border-t border-gray-100 p-6 space-y-4">
                <div>
                  <label class="block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">Select Costing Rule</label>
                  <div class="relative max-w-md">
                    <select v-model="formState.costing_rule" class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm appearance-none bg-white focus:outline-none focus:ring-1 focus:ring-gray-300 cursor-pointer">
                      <option value="" disabled selected>Select</option>
                      <option value="FIFO">FIFO (First In First Out)</option>
                      <option value="LIFO">LIFO (Last In First Out)</option>
                      <option value="Weighted Average">Weighted Average</option>
                      <option value="Standard Costing">Standard Costing</option>
                    </select>
                    <ChevronDown :size="16" class="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                  </div>
                </div>
              </div>
            </div>
            </fieldset>
          </div>

                   <!-- 7. SALES TAB CONTENT -->
          <div v-else-if="activeTab === 'Sales'" class="space-y-4">
            <div v-if="isStrictInherit" class="inline-flex items-center gap-1.5 text-[11px] font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2.5 py-1 rounded-full">
              <Lock :size="11" /> {{ inheritedBadgeText }}
            </div>
            <fieldset :disabled="isStrictInherit" :class="['border-0 p-0 m-0 space-y-4', isStrictInherit ? 'opacity-60' : '']">
            <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
              <button @click="warrantySectionOpen = !warrantySectionOpen" class="w-full flex items-center justify-between px-6 py-5 hover:bg-gray-50/50 transition-colors">
                <span class="text-sm font-bold text-gray-800">Warranty Period</span>
                <ChevronDown :size="16" :class="['text-gray-400 transition-transform duration-200', warrantySectionOpen ? 'rotate-180' : '']" />
              </button>
              
              <div v-if="warrantySectionOpen" class="border-t border-gray-100 p-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label class="block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">Warranty Type</label>
                    <div class="relative">
                      <select v-model="formState.warranty_type" class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm appearance-none bg-white focus:outline-none focus:ring-1 focus:ring-gray-300 cursor-pointer">
                        <option value="" disabled selected>Select</option>
                        <option value="Limited">Limited Warranty</option>
                        <option value="Full">Full Warranty</option>
                        <option value="Manufacturer">Manufacturer Warranty</option>
                      </select>
                      <ChevronDown :size="16" class="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                    </div>
                  </div>
                  <div>
                    <label class="block text-xs font-bold text-gray-700 mb-1.5 uppercase tracking-wider">Warranty Period (in days)</label>
                    <input
                      v-model="formState.warranty_period"
                      type="text"
                      
                      class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:ring-1 focus:ring-gray-300 focus:outline-none"
                    />
                  </div>
                </div>
              </div>
            </div>

            <!-- Branch Availability (EntityProduct) -->
            <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
              <div class="flex items-center gap-1.5 px-6 py-5 border-b border-gray-100">
                <span class="text-sm font-bold text-gray-800">Branch Availability</span>
                <HelpCircle :size="13" class="text-gray-400 cursor-pointer" title="Select which branches/shops sell this product (EntityProduct). If none are selected, the product is treated as global." />
              </div>
              <div class="p-6 space-y-3">
                <p class="text-xs text-gray-500 font-medium leading-relaxed">
                  Select the branches/shops that sell this product. Leave all unchecked to make it available everywhere (global).
                </p>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <label
                    v-for="e in entityList"
                    :key="e.id"
                    class="flex items-center gap-3 p-3.5 rounded-xl border border-gray-100 hover:bg-gray-50 transition-all cursor-pointer"
                  >
                    <input type="checkbox" :checked="formState.entity_ids.includes(e.id)" @change="toggleEntity(e.id)" class="sr-only" />
                    <div :class="['w-5 h-5 rounded border flex items-center justify-center shrink-0 transition-colors', formState.entity_ids.includes(e.id) ? 'bg-[#0b529c] border-[#0b529c] text-white' : 'border-gray-300 bg-white']">
                      <Check v-if="formState.entity_ids.includes(e.id)" :size="13" />
                    </div>
                    <span class="text-sm font-semibold text-gray-800">{{ e.name }}</span>
                  </label>
                </div>
              </div>
            </div>
            </fieldset>
          </div>

          <!-- 8. TAX TAB CONTENT -->
          <div v-else-if="activeTab === 'Tax'" class="space-y-4">
            <div v-if="isStrictInherit" class="inline-flex items-center gap-1.5 text-[11px] font-bold text-amber-700 bg-amber-50 border border-amber-200 px-2.5 py-1 rounded-full">
              <Lock :size="11" /> {{ inheritedBadgeText }}
            </div>
            <fieldset :disabled="isStrictInherit" :class="['border-0 p-0 m-0 space-y-4', isStrictInherit ? 'opacity-60' : '']">
            <div class="bg-white border border-gray-200 rounded-2xl p-6 shadow-sm space-y-4">
              <div class="flex items-center justify-between border-b border-gray-100 pb-3">
                <div class="flex items-center gap-1.5">
                  <h3 class="text-sm font-bold text-gray-800 uppercase tracking-wider">Product Tax Rates</h3>
                  <HelpCircle :size="14" class="text-gray-400 cursor-pointer" title="A product can have multiple tax rates applied simultaneously (e.g. VAT + Excise)." />
                </div>
                <button @click="addProductTaxRate" class="flex items-center gap-1.5 px-3 py-1.5 bg-[#0b529c] text-white rounded-lg text-xs font-semibold hover:bg-[#0c65bd]">
                  <Plus :size="14" /> Add Tax Rate
                </button>
              </div>
              <p class="text-xs text-gray-500 font-medium leading-relaxed">
                Apply one or more tax rates to this product. Tax types come from the <span class="font-bold text-gray-900">TaxType</span> table and rates are filtered by the selected type (<span class="font-bold text-gray-900">TaxRate</span>). Harmonization code is defined on the rate.
              </p>

              <div class="border border-gray-200 rounded-xl overflow-hidden">
                <table class="w-full text-left border-collapse">
                  <thead>
                    <tr class="bg-gray-50/75 text-xs font-bold text-gray-600 border-b border-gray-200">
                      <th class="p-3.5 w-14 text-center border-r border-gray-200">No.</th>
                      <th class="p-3.5 border-r border-gray-200">Tax Type</th>
                      <th class="p-3.5 border-r border-gray-200">Tax Rate</th>
                      <th class="p-3.5 border-r border-gray-200">Rate (%)</th>
                      <th class="p-3.5 border-r border-gray-200">Harmonization Code</th>
                      <th class="p-3.5 w-12 text-center">—</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="formState.product_tax_rates.length === 0">
                      <td colspan="6" class="p-8 text-center text-sm font-semibold text-gray-400">No tax rates applied. Click "Add Tax Rate".</td>
                    </tr>
                    <tr v-for="(row, idx) in formState.product_tax_rates" :key="row.id" class="border-b border-gray-100 hover:bg-gray-50/50">
                      <td class="p-3 text-center text-sm font-bold text-gray-600 border-r border-gray-200">{{ idx + 1 }}</td>
                      <td class="p-0 border-r border-gray-200">
                        <select v-model.number="row.tax_type_id" @change="row.tax_rate_id = null" class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none cursor-pointer">
                          <option :value="null" disabled>Select type</option>
                          <option v-for="t in taxTypeList" :key="t.id" :value="t.id">{{ t.name }}</option>
                        </select>
                      </td>
                      <td class="p-0 border-r border-gray-200">
                        <select v-model.number="row.tax_rate_id" :disabled="!row.tax_type_id" class="w-full px-3 py-3.5 text-sm bg-transparent focus:outline-none cursor-pointer disabled:text-gray-300">
                          <option :value="null" disabled>{{ row.tax_type_id ? 'Select rate' : 'Pick a type first' }}</option>
                          <option v-for="r in ratesForType(row.tax_type_id)" :key="r.id" :value="r.id">{{ r.rate_percent }}%</option>
                        </select>
                      </td>
                      <td class="p-3 text-sm font-mono text-gray-700 border-r border-gray-200 bg-gray-50/50">
                        {{ taxRateRow(row.tax_rate_id) ? taxRateRow(row.tax_rate_id)!.rate_percent + '%' : '—' }}
                      </td>
                      <td class="p-3 text-sm font-mono text-gray-600 border-r border-gray-200 bg-gray-50/50">
                        {{ taxRateRow(row.tax_rate_id)?.harmonization_code || '—' }}
                      </td>
                      <td class="p-3 text-center">
                        <button @click="removeProductTaxRate(idx)" class="p-1.5 hover:bg-red-50 text-red-400 hover:text-red-600 rounded-lg transition-colors"><Trash2 :size="13" /></button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
            </fieldset>
          </div>

        </div>

        <!-- Right Side Media Panel (1/3 width) matching screenshot 2 -->
        <div class="space-y-6">
          <div class="media-card bg-white border border-gray-200 rounded-2xl p-5 shadow-sm space-y-5">
            <h3 class="media-title text-sm font-bold text-gray-800 uppercase tracking-wider border-b border-gray-100 pb-3">
              Primary Product Media
            </h3>

            <!-- Main Media Preview Box -->
            <div class="main-media-box relative aspect-square w-full rounded-2xl bg-gray-50 border border-gray-150 overflow-hidden flex items-center justify-center">
              <template v-if="primaryImage">
                <!-- Video player playing state -->
                <video 
                  v-if="primaryImage.type === 'video' && isVideoPlaying" 
                  :src="primaryImage.url" 
                  controls 
                  autoplay 
                  class="w-full h-full object-cover"
                ></video>
                <!-- Image/Static video cover -->
                <img 
                  v-else 
                  :src="primaryImage.thumbnail || primaryImage.url" 
                  alt="Product Preview" 
                  class="w-full h-full object-cover" 
                />
                
                <!-- Play button overlay for video covers -->
                <div 
                  v-if="primaryImage.type === 'video' && !isVideoPlaying" 
                  @click="isVideoPlaying = true"
                  class="play-button-overlay absolute inset-0 bg-black/15 flex items-center justify-center cursor-pointer transition-colors hover:bg-black/25"
                >
                  <div class="play-icon-circle w-14 h-14 bg-white/90 backdrop-blur rounded-full flex items-center justify-center shadow-lg hover:scale-105 transition-all">
                    <Play :size="20" class="text-gray-900 fill-gray-900 ml-0.5" />
                  </div>
                </div>
              </template>
              <div v-else class="empty-media text-center p-6 text-gray-400">
                <Box :size="48" class="mx-auto mb-2 text-gray-300" />
                <span class="text-xs font-medium">No Media Uploaded</span>
              </div>
            </div>

            <!-- Thumbnail row of images -->
            <div v-if="formState.media.length > 0" class="thumbnails-grid flex items-center gap-3 overflow-x-auto py-1">
              <div 
                v-for="(img, idx) in formState.media" 
                :key="img.id" 
                :class="['thumbnail-wrapper relative w-16 h-16 rounded-xl overflow-hidden border-2 cursor-pointer transition-all shrink-0', img.isPrimary ? 'border-[#0b529c] scale-95 shadow-sm' : 'border-gray-200 hover:border-gray-300']"
                @click="setPrimaryImage(idx)"
              >
                <img :src="img.thumbnail || img.url" class="w-full h-full object-cover" />
                
                <!-- Play button indicator for videos -->
                <div v-if="img.type === 'video'" class="play-tiny absolute inset-0 m-auto w-6 h-6 bg-black/35 backdrop-blur-sm rounded-full flex items-center justify-center pointer-events-none">
                  <Play :size="10" class="text-white fill-white ml-px" />
                </div>

                <button 
                  @click.stop="removeImage(idx)" 
                  class="remove-img-btn absolute -top-1 -right-1 bg-red-500 text-white rounded-full p-0.5 hover:bg-red-600 shadow-sm"
                  title="Remove Image"
                >
                  <X :size="10" />
                </button>
              </div>
            </div>

            <!-- Upload drag and drop box -->
            <div>
              <input 
                type="file" 
                ref="fileInputEl" 
                accept="image/*,video/*" 
                multiple 
                class="hidden" 
                @change="handleFileChange" 
              />
              <div 
                @click="triggerFileUpload"
                class="upload-box-dotted border-2 border-dashed border-gray-200 rounded-2xl p-6 text-center cursor-pointer hover:bg-gray-50/50 hover:border-gray-300 transition-all"
              >
                <Upload :size="24" class="mx-auto mb-2 text-gray-400" />
                <div class="upload-text text-[#0b529c] text-xs font-bold hover:underline mb-1">
                  Click to upload <span class="text-gray-500 font-semibold">or drag and drop</span>
                </div>
                <p class="upload-tip text-[10px] text-gray-400 font-medium">
                  Video and Picture files up to 10MB
                </p>
              </div>
            </div>

          </div>
        </div>

      </div>

    </div>

    <!-- ==================== FLOW 2: STANDARD REGISTRY LIST VIEW ==================== -->
    <div v-else class="product-list-layout">
      
      <!-- Breadcrumbs -->
      <div class="breadcrumbs-area flex items-center gap-2 mb-6">
        <router-link to="/dashboard" class="home-icon-link text-gray-400 hover:text-gray-900">
          <Monitor :size="16" />
        </router-link>
        <ChevronRight :size="12" class="text-gray-400" />
        <span class="breadcrumb-active text-gray-500 font-semibold">Products</span>
      </div>

      <!-- Main Content Card -->
      <div class="registry-card-content bg-white border border-gray-200 rounded-2xl shadow-sm">
        
        <!-- Registry Header -->
        <header class="registry-header-block p-6 pb-2">
          <h1 class="registry-page-title text-xl font-bold text-gray-900 mb-1">Product List</h1>
          <p class="registry-page-subtitle text-xs text-gray-500 font-medium leading-relaxed">
            The core definition of physical goods or abstract services consumed, manufactured, or sold.
          </p>
        </header>

        <!-- Action Bar (Search, Filter, Column picker, + Create Button) -->
        <div class="action-bar-toolbar flex flex-col md:flex-row md:items-center justify-between gap-4 p-6 border-b border-gray-100">
          
          <!-- Left Actions -->
          <div class="toolbar-left-side flex items-center gap-3 flex-1">
            <div class="search-input-box-wrapper relative flex-1 max-w-md">
              <Search :size="18" class="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-450 pointer-events-none" />
              <input 
                v-model="searchQuery"
                type="text" 
                placeholder="Search works ..." 
                class="toolbar-search-input w-full border border-gray-200 rounded-xl pl-10 pr-4 py-2.5 text-sm focus:border-gray-300 focus:outline-none bg-white" 
              />
            </div>
            
            <BaseButton variant="secondary" size="md">
              <template #icon-left><Filter :size="16" /></template>
              <span>Filter</span>
            </BaseButton>
          </div>

          <!-- Right Actions -->
          <div class="toolbar-right-side flex items-center gap-3">
            <button class="density-columns-btn p-2.5 border border-gray-200 rounded-xl bg-white text-gray-500 hover:bg-gray-50 hover:text-gray-900" title="Columns density">
              <!-- Three vertical bars representing columns grid picker -->
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <line x1="4" y1="21" x2="4" y2="3"></line>
                <line x1="12" y1="21" x2="12" y2="3"></line>
                <line x1="20" y1="21" x2="20" y2="3"></line>
              </svg>
            </button>
            
            <button @click="toggleFullscreen" class="fullscreen-toggle-btn p-2.5 border border-gray-200 rounded-xl bg-white text-gray-500 hover:bg-gray-50 hover:text-gray-900" title="Toggle fullscreen">
              <Maximize2 :size="16" />
            </button>

            <BaseButton variant="primary" @click="openAddForm">
              <template #icon-left><Plus :size="18" stroke-width="2.5" /></template>
              <span>Create Product</span>
            </BaseButton>
          </div>

        </div>

        <!-- Product Table Area -->
        <div class="table-scroll-wrapper overflow-x-auto">
          <table class="products-registry-table w-full border-collapse">
            <thead>
              <tr class="border-b border-gray-150 bg-[#fafafa] text-left">
                <th class="px-6 py-3.5 text-xs font-medium text-[#737373]">Name</th>
                <th class="px-6 py-3.5 text-xs font-medium text-[#737373]">Brand</th>
                <th class="px-6 py-3.5 text-xs font-medium text-[#737373]">Product Group</th>
                <th class="px-6 py-3.5 text-xs font-medium text-[#737373]">Product Type</th>
                <th class="px-6 py-3.5 text-xs font-medium text-[#737373]">Measurement unit</th>
                <th class="px-6 py-3.5 text-xs font-medium text-[#737373]">Is Trackable</th>
                <th class="px-6 py-3.5 text-xs font-medium text-[#737373]">Status</th>
                <th class="px-6 py-3.5 text-xs font-medium text-[#737373] text-right" width="80">Action</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="p in paginatedProducts" 
                :key="p.id"
                class="table-row-item border-b border-gray-100 hover:bg-gray-50/50 transition-colors"
              >
                <!-- Name column with item name and code below -->
                <td class="px-6 py-4">
                  <div class="product-identity flex items-center gap-3">
                    <!-- Icon or mini thumbnail preview -->
                    <div class="mini-product-thumbnail w-10 h-10 rounded-lg overflow-hidden border border-gray-100 bg-gray-50 shrink-0">
                      <img v-if="p.media && p.media.length > 0" :src="p.media[0].url" class="w-full h-full object-cover" />
                      <div v-else class="w-full h-full flex items-center justify-center text-gray-300">
                        <Box :size="18" />
                      </div>
                    </div>
                    <div>
                      <div class="product-display-name text-sm font-semibold text-[#262626] flex items-center gap-2">
                        <span v-if="p.color" class="inline-block w-2.5 h-2.5 rounded-full border border-gray-200 shrink-0" :style="{ backgroundColor: p.color }" title="POS tile color"></span>
                        {{ p.name }}
                      </div>
                      <div class="product-secondary-code text-[11px] font-normal text-[#737373] tracking-wider">
                        {{ p.code }}<span v-if="p.sku"> · SKU {{ p.sku }}</span>
                      </div>
                    </div>
                  </div>
                </td>

                <td class="px-6 py-4 text-sm font-normal text-[#737373]">
                  <span v-if="p.brand_ids && p.brand_ids.length">{{ brandNames(p.brand_ids) }}</span>
                  <span v-else class="text-gray-300">—</span>
                </td>

                <td class="px-6 py-4 text-sm font-normal text-[#737373]">
                  {{ p.product_group }}
                </td>

                <td class="px-6 py-4 text-sm font-normal text-[#737373]">
                  {{ p.product_type }}
                </td>

                <td class="px-6 py-4 text-sm font-normal text-[#737373]">
                  {{ p.uom }}
                </td>

                <!-- Is Trackable Badge -->
                <td class="px-6 py-4">
                  <span class="trackable-badge bg-gray-100 border border-gray-200 text-gray-700 px-2.5 py-0.5 rounded-full text-xs font-semibold">
                    {{ p.is_trackable }}
                  </span>
                </td>

                <!-- Status Badge -->
                <td class="px-6 py-4">
                  <span class="status-badge-active bg-emerald-50 border border-emerald-100 text-emerald-600 px-2.5 py-0.5 rounded-full text-xs font-semibold">
                    {{ p.status }}
                  </span>
                </td>

                <!-- Actions Menu Button -->
                <td class="px-6 py-4 text-right">
                  <div class="action-dropdown-wrapper relative inline-block text-left">
                    <button 
                      @click="toggleActionMenu($event, p.id)"
                      class="dots-action-btn p-2 hover:bg-gray-100 rounded-lg transition-colors text-gray-400 hover:text-gray-900"
                    >
                      <MoreVertical :size="18" />
                    </button>
                    
                    <div 
                      v-if="activeActionMenuId === p.id"
                      class="dropdown-actions-floating-card absolute right-0 mt-1.5 w-44 bg-white border border-gray-200 rounded-xl shadow-lg z-50 py-1"
                    >
                      <button @click="triggerEdit(p)" class="action-item-option w-full text-left px-4 py-2.5 text-sm font-semibold text-gray-700 hover:bg-gray-50 flex items-center gap-2">
                        <Edit2 :size="14" class="text-gray-500" />
                        Edit Form
                      </button>
                      <div class="dropdown-divider-line border-t border-gray-100 my-1"></div>
                      <button @click="triggerDelete(p.id)" class="action-item-option w-full text-left px-4 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50 flex items-center gap-2">
                        <Trash2 :size="14" />
                        Remove
                      </button>
                    </div>
                  </div>
                </td>
              </tr>

              <tr v-if="filteredProducts.length === 0">
                <td colspan="8" class="text-center py-12 text-gray-400">
                  <div class="empty-registry-state flex flex-col items-center justify-center">
                    <Box :size="48" class="text-gray-300 mb-2" />
                    <p class="text-sm font-semibold text-gray-500">No products match your search scope.</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination Footer matching screenshot 1 -->
        <div class="table-pagination-footer flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-6 border-t border-gray-100">
          <div class="footer-entries-counter text-xs text-gray-500 font-semibold flex items-center gap-5">
            <span>Showing {{ startIndex }} to {{ endIndex }} of {{ totalEntries }} entries</span>
            
            <span class="per-page-option flex items-center gap-2">
              Per Page:
              <div class="select-page-wrap relative">
                <select 
                  v-model="perPage" 
                  @change="currentPage = 1"
                  class="per-page-select-el border border-gray-200 rounded-lg pl-3 pr-8 py-1 bg-white text-xs font-bold appearance-none cursor-pointer"
                >
                  <option :value="1">1</option>
                  <option :value="2">2</option>
                  <option :value="5">5</option>
                  <option :value="10">10</option>
                  <option :value="20">20</option>
                </select>
                <ChevronDown :size="12" class="absolute right-2 top-1/2 -translate-y-1/2 text-gray-450 pointer-events-none" />
              </div>
            </span>
          </div>

          <!-- Pagination numbers -->
          <div class="pagination-buttons-nav flex items-center gap-1.5 text-xs">
            <button 
              @click="changePage(currentPage - 1)"
              :disabled="currentPage === 1"
              class="page-nav-arrow flex items-center gap-1 px-3 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed font-semibold text-gray-700 bg-white"
            >
              <ArrowLeft :size="14" />
              Previous
            </button>

            <!-- Generate page numbers (showing up to 10 matching screenshot pagination) -->
            <button 
              v-for="page in totalPages" 
              :key="page"
              @click="changePage(page)"
              :class="['page-number-btn w-9 h-9 flex items-center justify-center rounded-lg border font-semibold transition-colors', currentPage === page ? 'bg-[#0b529c] border-[#0b529c] text-white shadow-sm' : 'border-gray-200 text-gray-700 bg-white hover:bg-gray-50']"
            >
              {{ page }}
            </button>

            <!-- Additional dummy page placeholders to perfectly mimic screenshot 1 -->
            <template v-if="totalPages < 10">
              <span class="text-gray-400 font-semibold px-1">...</span>
              <button class="page-number-btn w-9 h-9 flex items-center justify-center rounded-lg border border-gray-200 text-gray-750 bg-white hover:bg-gray-50 font-semibold">8</button>
              <button class="page-number-btn w-9 h-9 flex items-center justify-center rounded-lg border border-gray-200 text-gray-750 bg-white hover:bg-gray-50 font-semibold">9</button>
              <button class="page-number-btn w-9 h-9 flex items-center justify-center rounded-lg border border-gray-200 text-gray-750 bg-white hover:bg-gray-50 font-semibold">10</button>
            </template>

            <button 
              @click="changePage(currentPage + 1)"
              :disabled="currentPage === totalPages"
              class="page-nav-arrow flex items-center gap-1 px-3 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed font-semibold text-gray-750 bg-white"
            >
              Next
              <ArrowRight :size="14" />
            </button>
          </div>

        </div>

      </div>

    </div>

  </div>

  <!-- ===================== Stock-In Modal ===================== -->
  <Teleport to="body">
    <Transition name="modal-fade">
      <div
        v-if="showStockInModal"
        class="fixed inset-0 z-[9999] flex items-center justify-center p-4"
        style="background: rgba(0,0,0,0.35); backdrop-filter: blur(2px);"
        @click.self="closeStockInModal"
      >
        <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden">
          <!-- Modal Header -->
          <div class="flex items-center justify-between px-6 py-5 border-b border-gray-100">
            <h2 class="text-base font-bold text-gray-900">Add Products</h2>
            <button @click="closeStockInModal" class="p-1.5 hover:bg-gray-100 rounded-lg text-gray-400 hover:text-gray-600 transition-colors">
              <X :size="18" />
            </button>
          </div>

          <!-- Modal Body -->
          <div class="px-6 py-6 space-y-5">
            <!-- Product Name (read-only, auto-filled) -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">
                Product Name <span class="text-red-500">*</span>
              </label>
              <input
                v-model="stockInForm.product_name"
                type="text"
                readonly
                class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm bg-gray-50 text-gray-600 cursor-not-allowed focus:outline-none"
                
              />
            </div>

            <!-- To Location -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">
                To Location <span class="text-red-500">*</span>
              </label>
              <div class="relative">
                <select
                  v-model="stockInForm.to_location"
                  class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm appearance-none bg-white focus:outline-none focus:ring-1 focus:ring-[#0b529c] cursor-pointer"
                >
                  <option value="" disabled selected>Select</option>
                  <option v-for="loc in locationsList" :key="loc" :value="loc">{{ loc }}</option>
                </select>
                <ChevronDown :size="16" class="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
              </div>
            </div>

            <!-- Quantity -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">
                Quantity <span class="text-red-500">*</span>
              </label>
              <input
                v-model.number="stockInForm.quantity"
                type="number"
                min="1"
                class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-1 focus:ring-[#0b529c] font-mono"
              />
            </div>

            <!-- Unit Price -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">Unit Price</label>
              <input
                v-model.number="stockInForm.unit_price"
                type="number"
                min="0"
                step="0.01"
                class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-1 focus:ring-[#0b529c] font-mono"
              />
            </div>
          </div>

          <!-- Modal Footer -->
          <div class="flex justify-end px-6 py-4 border-t border-gray-100 bg-gray-50/50">
            <button
              @click="submitStockIn"
              class="px-5 py-2.5 bg-[#0b529c] hover:bg-[#0a4785] text-white text-sm font-bold rounded-xl transition-colors shadow-sm"
            >
              Create Stock In
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>

  <!-- ===================== Stock Move Modal ===================== -->
  <Teleport to="body">
    <Transition name="modal-fade">
      <div
        v-if="showMoveModal"
        class="fixed inset-0 z-[9999] flex items-center justify-center p-4"
        style="background: rgba(0,0,0,0.35); backdrop-filter: blur(2px);"
        @click.self="closeMoveModal"
      >
        <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden">
          <!-- Header -->
          <div class="flex items-center justify-between px-6 py-5 border-b border-gray-100">
            <h2 class="text-base font-bold text-gray-900">Move Stock</h2>
            <button @click="closeMoveModal" class="p-1.5 hover:bg-gray-100 rounded-lg text-gray-400 hover:text-gray-600 transition-colors">
              <X :size="18" />
            </button>
          </div>

          <!-- Body -->
          <div class="px-6 py-6 space-y-5">
            <!-- From (read-only) -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">From Location</label>
              <div class="flex items-center justify-between border border-gray-200 rounded-xl px-3.5 py-2.5 bg-gray-50">
                <span class="text-sm text-gray-700 font-medium">{{ moveForm.from_location }}</span>
                <span class="text-xs text-gray-400">Available: <span class="font-mono text-gray-700">{{ moveAvailable }}</span></span>
              </div>
            </div>

            <!-- To -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">
                To Location <span class="text-red-500">*</span>
              </label>
              <div class="relative">
                <select
                  v-model="moveForm.to_location"
                  class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm appearance-none bg-white focus:outline-none focus:ring-1 focus:ring-[#0b529c] cursor-pointer"
                >
                  <option value="" disabled>Select destination</option>
                  <option v-for="loc in moveDestinations" :key="loc" :value="loc">{{ loc }}</option>
                </select>
                <ChevronDown :size="16" class="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
              </div>
            </div>

            <!-- Quantity -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1.5">
                Quantity <span class="text-red-500">*</span>
              </label>
              <input
                v-model.number="moveForm.quantity"
                type="number"
                min="1"
                :max="moveAvailable"
                class="w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm focus:outline-none focus:ring-1 focus:ring-[#0b529c] font-mono"
              />
            </div>
          </div>

          <!-- Footer -->
          <div class="flex justify-end px-6 py-4 border-t border-gray-100 bg-gray-50/50">
            <button
              @click="submitMove"
              class="px-5 py-2.5 bg-[#0b529c] hover:bg-[#0a4785] text-white text-sm font-bold rounded-xl transition-colors shadow-sm"
            >
              Confirm Move
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>

  <!-- ===================== Parent Inheritance Confirmation ===================== -->
  <Teleport to="body">
    <Transition name="modal-fade">
      <div
        v-if="parentConfirmOpen"
        class="fixed inset-0 z-[9999] flex items-center justify-center p-4"
        style="background: rgba(0,0,0,0.35); backdrop-filter: blur(2px);"
        @click.self="cancelParent"
      >
        <div class="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden">
          <!-- Header -->
          <div
            class="flex items-start gap-3.5 px-6 py-5 border-b"
            :class="confirmParentData?.apply_to_variants ? 'border-amber-100 bg-amber-50/60' : 'border-blue-100 bg-blue-50/40'"
          >
            <div
              class="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
              :class="confirmParentData?.apply_to_variants ? 'bg-amber-100 text-amber-600' : 'bg-blue-100 text-[#0b529c]'"
            >
              <Lock v-if="confirmParentData?.apply_to_variants" :size="18" />
              <Info v-else :size="18" />
            </div>
            <div class="flex-1">
              <h2 class="text-base font-bold text-gray-900">
                {{ confirmParentData?.apply_to_variants
                  ? 'This parent applies its settings to all variants'
                  : 'This parent shares default settings' }}
              </h2>
              <p class="text-xs text-gray-500 font-medium mt-0.5">
                Parent: <span class="font-bold text-gray-700">{{ pendingParent }}</span>
              </p>
            </div>
            <button @click="cancelParent" class="p-1.5 hover:bg-white/70 rounded-lg text-gray-400 hover:text-gray-600 transition-colors">
              <X :size="18" />
            </button>
          </div>

          <!-- Body -->
          <div class="px-6 py-5 space-y-4">
            <!-- STRICT: apply_to_variants ON -->
            <template v-if="confirmParentData?.apply_to_variants">
              <p class="text-sm text-gray-600 leading-relaxed">
                <span class="font-semibold text-gray-900">{{ pendingParent }}</span> has
                <span class="font-semibold">“Apply Settings to All Variants”</span> turned on.
                Most sections of this product will be <span class="font-semibold text-amber-700">overridden and locked</span>,
                inheriting their values directly from the parent.
              </p>

              <div class="rounded-xl border border-amber-100 bg-amber-50/50 p-3.5">
                <p class="text-[11px] font-bold uppercase tracking-wider text-amber-700 mb-2 flex items-center gap-1.5">
                  <Lock :size="12" /> Locked &amp; inherited
                </p>
                <ul class="text-xs text-gray-600 space-y-1.5">
                  <li class="flex items-center gap-2"><Check :size="13" class="text-amber-600 shrink-0" /> Name, code &amp; SKU</li>
                  <li class="flex items-center gap-2"><Check :size="13" class="text-amber-600 shrink-0" /> Product group, category &amp; brands</li>
                  <li class="flex items-center gap-2"><Check :size="13" class="text-amber-600 shrink-0" /> Default pricing &amp; tax</li>
                  <li class="flex items-center gap-2"><Check :size="13" class="text-amber-600 shrink-0" /> UOM, Inventory &amp; Sales settings</li>
                </ul>
              </div>

              <div class="rounded-xl border border-green-100 bg-green-50/50 p-3.5">
                <p class="text-[11px] font-bold uppercase tracking-wider text-green-700 mb-2 flex items-center gap-1.5">
                  <Edit2 :size="12" /> You can still edit
                </p>
                <ul class="text-xs text-gray-600 space-y-1.5">
                  <li class="flex items-center gap-2"><Check :size="13" class="text-green-600 shrink-0" /> Product Attribute values</li>
                  <li class="flex items-center gap-2"><Check :size="13" class="text-green-600 shrink-0" /> Variant Price Override</li>
                </ul>
              </div>
            </template>

            <!-- SOFT: apply_to_variants OFF -->
            <template v-else>
              <p class="text-sm text-gray-600 leading-relaxed">
                <span class="font-semibold text-gray-900">{{ pendingParent }}</span> does
                <span class="font-semibold">not</span> apply its settings to all variants.
                <span class="font-semibold text-[#0b529c]">Not all properties are inherited</span> — some values are
                pre-filled from the parent as defaults, and you remain free to change any of them for this product.
              </p>

              <div class="rounded-xl border border-blue-100 bg-blue-50/40 p-3.5">
                <p class="text-[11px] font-bold uppercase tracking-wider text-[#0b529c] mb-2 flex items-center gap-1.5">
                  <Info :size="12" /> Pre-filled as defaults (editable)
                </p>
                <ul class="text-xs text-gray-600 space-y-1.5">
                  <li class="flex items-center gap-2"><Check :size="13" class="text-[#0b529c] shrink-0" /> Product group, category &amp; brands</li>
                  <li class="flex items-center gap-2"><Check :size="13" class="text-[#0b529c] shrink-0" /> Pricing, tax &amp; UOM</li>
                  <li class="flex items-center gap-2"><Check :size="13" class="text-[#0b529c] shrink-0" /> Inventory tracking defaults</li>
                </ul>
              </div>
            </template>
          </div>

          <!-- Footer -->
          <div class="flex justify-end gap-3 px-6 py-4 border-t border-gray-100 bg-gray-50/50">
            <button
              @click="cancelParent"
              class="px-5 py-2.5 border border-gray-200 hover:bg-gray-100 text-gray-700 text-sm font-bold rounded-xl transition-colors"
            >
              Cancel
            </button>
            <button
              @click="confirmParent"
              class="px-5 py-2.5 text-white text-sm font-bold rounded-xl transition-colors shadow-sm"
              :class="confirmParentData?.apply_to_variants ? 'bg-amber-600 hover:bg-amber-700' : 'bg-[#0b529c] hover:bg-[#0a4785]'"
            >
              {{ confirmParentData?.apply_to_variants ? 'Use this parent & inherit' : 'Use this parent' }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>

</template>

<style>
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.2s ease;
}
.modal-fade-enter-active .bg-white,
.modal-fade-leave-active .bg-white {
  transition: transform 0.2s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.2s ease;
}
.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}
.modal-fade-enter-from .bg-white {
  transform: scale(0.95) translateY(8px);
}
</style>

<style scoped>
.products-view-container {
  animation: fadeIn 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}

.is-fullscreen {
  position: fixed;
  inset: 0;
  z-index: 99999;
  background-color: #fafafa;
  padding: 24px;
  overflow-y: auto;
}

/* Custom premium checkboxes */
.custom-checkbox-container {
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04);
}

/* Tabs scrollbar hiding */
.tabs-scroll-container::-webkit-scrollbar {
  display: none;
}
.tabs-scroll-container {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

/* Premium input states */
.premium-input-style, .premium-select-style {
  box-shadow: 0 1.5px 3px rgba(0, 0, 0, 0.015);
  transition: all 0.2s ease;
}
.premium-input-style:focus, .premium-select-style:focus {
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}
</style>
