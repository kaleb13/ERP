<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { 
  Search, Filter, Plus, MoreVertical, Building2, Building, GitBranch, Store, ShoppingCart,
  ChevronRight, ArrowLeft, Edit, CheckCircle, Monitor, X
} from 'lucide-vue-next';
import HaletaHeader from '../components/HaletaHeader.vue';

const route = useRoute();
const router = useRouter();

// --- STATE MANAGEMENT ---
const currentView = ref<'list' | 'create' | 'detail'>('list');
const isLoading = ref(false);
const entities = ref<any[]>([]);
const hasBusinessGroup = ref(false); 
const parentEntity = ref<any>(null); 
const allEntities = ref<any[]>([]);

// --- METRIC STATE ---
const metrics = computed(() => {
  const activeCount = entities.value.filter(e => e.state === 'active').length;
  const detailedCount = entities.value.filter(e => e.has_detail).length;
  const total = entities.value.length;
  
  return [
    { label: `${entityTypeConfig.value.name} Volume`, value: total, icon: Building2, color: 'primary', sub: 'Total registered units' },
    { label: 'Operational Nodes', value: activeCount, icon: CheckCircle, color: 'success', sub: `${total - activeCount} Inactive/Hidden` },
    { label: 'Admin Compliance', value: `${((detailedCount/total)*100 || 0).toFixed(0)}%`, icon: Edit, color: 'indigo', sub: 'Nodes with TIN/VAT details' },
    { label: 'Sub-Units', value: '42', icon: GitBranch, color: 'warning', sub: 'Children nodes registered' }
  ];
});

// --- CONFIGURATION BASED ON ROUTE ---
const entityTypeConfig = computed(() => {
  const path = route.path;
  if (path.includes('business-groups')) return { 
    name: 'Business Group', 
    icon: Building2, 
    level: 1, 
    typeId: 1,
    description: 'Manage the highest level of your enterprise hierarchy.'
  };
  if (path.includes('organizations')) return { 
    name: 'Organization', 
    icon: Building, 
    level: 2, 
    typeId: 2,
    description: 'Establish legally distinct companies under your group.'
  };
  if (path.includes('branches')) return { 
    name: 'Branch', 
    icon: GitBranch, 
    level: 3, 
    typeId: 3,
    description: 'Regional units focused on specific operational zones.'
  };
  if (path.includes('branch-shops')) return { 
    name: 'Branch Shop', 
    icon: Store, 
    level: 4, 
    typeId: 4,
    description: 'Direct sales locations representing your brand.'
  };
  if (path.includes('outlets')) return { 
    name: 'Outlet', 
    icon: ShoppingCart, 
    level: 5, 
    typeId: 5,
    description: 'The final point-of-sale nodes for transaction handling.'
  };
  return { name: 'Entity', icon: Building, level: 0, typeId: 0, description: 'Organizational unit management.' };
});

const form = ref({
  // CORE ENTITY FIELDS
  name: '',
  code: '',
  abbreviation: '',
  pos_type: 'retail',
  parent_id: '',
  state: 'active',
  latitude: '',
  longitude: '',
  is_group: false,
  
  // ENTITY DETAIL FIELDS (Optional section)
  legal_entity_type_id: '',
  logo: '',
  tin: '',
  vat_reg_number: '',
  vat_reg_date: '',
  email: '',
  phone: '',
  house_number: '',
  trade_name: '',
  legal_name: '',
  tax_center_id: '',
  number_of_branches: 0,
  number_of_employees: 0,
  date_established: '',
  is_primary: false,

  // CONFIGURATION FIELDS
  costing_rule: 'FIFO',
  base_currency_id: '1',
  selected_sectors: [] as { sector_id: string, is_primary: boolean }[]
});

const availableSectors = [
  { id: '1', name: 'Retail' },
  { id: '2', name: 'Manufacturing' },
  { id: '3', name: 'Services' },
  { id: '4', name: 'Agriculture' },
  { id: '5', name: 'Technology' }
];

const showDetailSection = ref(false); 
const activeTab = ref('basic');
const tabs = [
  { id: 'basic', label: '1. Identity' },
  { id: 'config', label: '2. Configuration' },
  { id: 'detail', label: '3. Legal Detail' }
];

// --- ACTIONS ---
const fetchEntities = async () => {
  isLoading.value = true;
  // Simulated fetch
  setTimeout(() => {
    // allEntities simulates a list of potential parents
    allEntities.value = [
      { id: '1', name: 'QMT Business Group', code: 'QMT-BG-001', level: 1, state: 'active', has_detail: true },
      { id: '10', name: 'QMT Addis Branch Org', code: 'QMT-BR-ADDIS-01', level: 2, state: 'active', has_detail: false, parent_name: 'QMT Business Group' }
    ];

    if (entityTypeConfig.value.level === 1) {
      entities.value = [allEntities.value[0]];
      hasBusinessGroup.value = true;
    } else if (entityTypeConfig.value.level === 2) {
       entities.value = [allEntities.value[1]];
    } else {
      entities.value = [];
    }
    isLoading.value = false;
  }, 500);
};

const fetchParentIfNeeded = async () => {
  const pId = route.query.parent_id;
  if (pId) {
    isLoading.value = true;
    // Simulate fetching parent
    setTimeout(() => {
       parentEntity.value = { id: pId, name: 'QMT Business Group', code: 'QMT-BG-001', abbreviation: 'QMTBG' };
       form.value.parent_id = pId.toString();
       currentView.value = 'create';
       isLoading.value = false;
    }, 300);
  }
};

const openDetail = (entity: any) => {
  selectedEntity.value = entity;
  currentView.value = 'detail';
};

const goToCreate = (parent: any = null) => {
  if (parent) {
    parentEntity.value = parent;
    form.value.parent_id = parent.id;
  } else {
    parentEntity.value = null;
    form.value.parent_id = '';
  }
  currentView.value = 'create';
};

const cancel = () => {
  currentView.value = 'list';
  parentEntity.value = null;
  resetForm();
};

const goToList = () => cancel();

const resetForm = () => {
  form.value = {
    name: '', code: '', abbreviation: '', pos_type: 'retail', parent_id: '', state: 'active',
    latitude: '', longitude: '', is_group: false,
    legal_entity_type_id: '', logo: '', tin: '', vat_reg_number: '', vat_reg_date: '',
    email: '', phone: '', house_number: '', trade_name: '', legal_name: '',
    tax_center_id: '', number_of_branches: 0, number_of_employees: 0, date_established: '',
    is_primary: false,
    costing_rule: 'FIFO',
    base_currency_id: '1',
    selected_sectors: []
  };
  showDetailSection.value = false;
  activeTab.value = 'basic';
};

const saveEntity = () => {
  isLoading.value = true;
  setTimeout(() => {
    entities.value.push({
      id: Date.now().toString(),
      ...form.value
    });
    if (entityTypeConfig.value.level === 1) hasBusinessGroup.value = true;
    isLoading.value = false;
    currentView.value = 'list';
    resetForm();
  }, 800);
};

const addChild = (entity: any) => {
  const nextTarget = entityTypeConfig.value.level === 1 ? '/organizations' : 
                     entityTypeConfig.value.level === 2 ? '/branches' :
                     entityTypeConfig.value.level === 3 ? '/branch-shops' : '/outlets';
  
  router.push(`${nextTarget}?parent_id=${entity.id}`);
};

const selectedEntity = ref<any>(null);
const showDetailModal = ref(false);

const openDetailFormModal = (entity: any) => {
  selectedEntity.value = entity;
  // Fill form with entity info and clear detail fields
  form.value.name = entity.name;
  form.value.code = entity.code;
  // In a real app, you'd fetch existing detail here
  showDetailModal.value = true;
};

const saveDetailOnly = () => {
  isLoading.value = true;
  setTimeout(() => {
    isLoading.value = false;
    showDetailModal.value = false;
    // Notify or refresh
  }, 600);
};

const clearDetailFields = () => {
  form.value.legal_entity_type_id = '';
  form.value.logo = '';
  form.value.tin = '';
  form.value.vat_reg_number = '';
  form.value.vat_reg_date = '';
  form.value.email = '';
  form.value.phone = '';
  form.value.house_number = '';
  form.value.trade_name = '';
  form.value.legal_name = '';
  form.value.tax_center_id = '';
  form.value.number_of_branches = 0;
  form.value.number_of_employees = 0;
  form.value.date_established = '';
  form.value.is_primary = false;
};

const addSector = (id: string) => {
  if (!form.value.selected_sectors.find(s => s.sector_id === id)) {
    form.value.selected_sectors.push({ sector_id: id, is_primary: form.value.selected_sectors.length === 0 });
  }
};

const removeSector = (id: string) => {
  form.value.selected_sectors = form.value.selected_sectors.filter(s => s.sector_id !== id);
};

const setPrimarySector = (id: string) => {
  form.value.selected_sectors.forEach(s => s.is_primary = s.sector_id === id);
};

onMounted(() => {
  fetchEntities();
  fetchParentIfNeeded();
});
watch(() => route.path, () => {
  currentView.value = 'list';
  fetchEntities();
});
watch(() => route.query.parent_id, fetchParentIfNeeded);

</script>

<template>
  <div class="entity-manager">
    <!-- RIGID HORIZONTAL TOOLBAR (Haleta ERP High Fidelity) -->
    <HaletaHeader 
      :icon="Monitor" 
      :breadcrumbs="[
        { label: entityTypeConfig.name, onClick: goToList },
        { label: currentView === 'list' ? `${entityTypeConfig.name}s` : `Create ${entityTypeConfig.name}`, isCurrent: true }
      ]"
      :statusBadge="currentView === 'create' ? 'Not Saved' : ''"
    >
      <template #actions>
        <button v-if="currentView === 'list'" class="btn-establish" @click="goToCreate()">
          <Plus :size="16" /> Establish {{ entityTypeConfig.name }}
        </button>
        <button v-else class="btn-save" @click="saveEntity">Save</button>
      </template>
    </HaletaHeader>

    <!-- CONTENT AREA -->
    <main class="haleta-scroll-body">
       <div class="haleta-container">
      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'" class="view-list">
        
        <!-- EMPTY STATE FOR BUSINESS GROUP (CENTERED) -->
         <div v-if="entityTypeConfig.level === 1 && !hasBusinessGroup && !isLoading" class="empty-state card py-32">
            <div class="empty-illust bg-primary-light">
              <Building2 :size="64" class="text-primary" />
            </div>
            <h2 class="h2 mb-2">No Business Group Yet</h2>
            <p class="text-muted max-w-sm mx-auto">Register your core business group to begin establishing your multi-tenant organizational structure.</p>
            <button class="btn btn-primary btn-lg mt-8 shimmer" @click="goToCreate()">
              Add My First Business Group
            </button>
         </div>

        <template v-else>
          <!-- METRIC CARDS SECTION -->
          <div class="metrics-grid mb-8">
             <div v-for="m in metrics" :key="m.label" class="metric-card card animate-in">
                <div class="metric-body">
                   <div class="metric-info">
                      <div class="metric-label">{{ m.label }}</div>
                      <div class="metric-value">{{ m.value }}</div>
                   </div>
                   <div class="metric-icon-box" :class="`bg-${m.color}-light`">
                      <component :is="m.icon" :size="24" :class="`text-${m.color}`" />
                   </div>
                </div>
                <div class="metric-footer">
                   <span class="text-xs text-muted">{{ m.sub }}</span>
                </div>
             </div>
          </div>

          <!-- TOOLBAR -->
          <div class="toolbar card">
            <div class="toolbar-left">
              <div class="search-box">
                <Search :size="14" class="search-icon" />
                <input type="text" placeholder="Search..." class="search-input" />
              </div>
              <button class="btn btn-outline">
                <Filter :size="14" /> Filter
              </button>
            </div>
            <div class="toolbar-right">
              <span class="text-xs text-muted">{{ entities.length }} Records Found</span>
            </div>
          </div>

          <!-- TABLE -->
          <div class="table-container card">
            <table class="data-table">
              <thead>
                <tr>
                  <th class="check-col"><input type="checkbox" /></th>
                  <th>{{ entityTypeConfig.name }} Name</th>
                  <th>Code</th>
                  <th v-if="entityTypeConfig.level > 1">Parent Node</th>
                  <th>State</th>
                  <th class="actions-col"></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="entity in entities" :key="entity.id" @click="openDetail(entity)" class="clickable">
                  <td><input type="checkbox" @click.stop /></td>
                  <td class="col-name">
                    <div class="flex items-center gap-2">
                      <component :is="entityTypeConfig.icon" :size="14" class="text-muted" />
                      {{ entity.name }}
                    </div>
                  </td>
                  <td><code class="code-badge">{{ entity.code }}</code></td>
                  <td v-if="entityTypeConfig.level > 1" class="text-muted text-xs">
                     <div class="flex items-center gap-1">
                        <GitBranch :size="10" />
                        {{ entity.parent_name || 'Root Group' }}
                     </div>
                  </td>
                  <td>
                     <span class="status-indicator" :class="entity.state">
                        {{ entity.state }}
                     </span>
                  </td>
                  <td class="actions-col text-right">
                    <div class="flex items-center justify-end gap-1">
                      <button class="btn btn-xs btn-outline" title="Add Detail" @click.stop="openDetailFormModal(entity)">
                        <Edit :size="12" /> Detail
                      </button>
                      <button class="btn btn-xs btn-outline" @click.stop="addChild(entity)">
                        <Plus :size="12" /> Child
                      </button>
                      <button class="btn-icon"><MoreVertical :size="14" /></button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </template>
      </div>

      <!-- CREATE VIEW -->
      <div v-else-if="currentView === 'create'" class="view-create">
        <div class="form-container">
          
          <!-- FLOATING PARENT CARD -->
          <transition name="fade">
            <div v-if="parentEntity" class="parent-context-card animate-in">
              <div class="context-label">Creating Child For:</div>
              <div class="context-content">
                <div class="context-icon">
                  <Building :size="20" />
                </div>
                <div class="context-info">
                  <div class="context-title">{{ parentEntity.name }}</div>
                  <div class="context-meta text-xs">{{ parentEntity.code }} | {{ parentEntity.abbreviation }}</div>
                </div>
              </div>
              <div class="context-link">
                 <CheckCircle :size="16" class="text-success" />
              </div>
            </div>
          </transition>

          <!-- UNIFIED FORM CONTAINER (Side Tabs Removed) -->
          <div class="doc-body card min-h-[70vh]">
            
            <!-- TABS (Capsule Style) -->
            <div class="capsule-tabs mb-10">
               <button 
                 v-for="tab in tabs" 
                 :key="tab.id"
                 class="capsule-tab"
                 :class="{ active: activeTab === tab.id }"
                 @click="activeTab = tab.id"
               >
                 {{ tab.label }}
               </button>
            </div>

                <!-- TAB 1: IDENTITY -->
                <div v-if="activeTab === 'basic'" class="tab-content transition-tab">
                  <div class="form-grid">
                    <div class="form-group">
                       <label class="form-label">Name</label>
                       <input v-model="form.name" type="text" class="input" placeholder="e.g. Qelem Meda" />
                    </div>
                    
                    <div v-if="entityTypeConfig.level > 1" class="form-group">
                       <label class="form-label">Parent {{ entityTypeConfig.name }}</label>
                       <select v-model="form.parent_id" class="input">
                          <option value="">-- Select Parent --</option>
                          <option v-for="parent in allEntities" :key="parent.id" :value="parent.id">
                             {{ parent.name }}
                          </option>
                       </select>
                    </div>

                    <div class="form-group">
                       <label class="form-label">Code</label>
                       <input v-model="form.code" type="text" class="input" placeholder="e.g. QMT-ORG1" />
                    </div>
                    <div class="form-group">
                       <label class="form-label">Abbreviation</label>
                       <input v-model="form.abbreviation" type="text" class="input" placeholder="QMT" />
                    </div>
                    <div class="form-group span-2">
                       <label class="form-label">POS Mode</label>
                       <select v-model="form.pos_type" class="input">
                         <option value="retail">Retail</option>
                         <option value="hospitality">Hospitality</option>
                       </select>
                    </div>
                  </div>

                  <!-- Toggle Section -->
                  <div class="toggle-card mt-8">
                     <div class="toggle-info">
                        <div class="toggle-title font-bold">Can Have Sub-Entities</div>
                        <div class="text-xs text-muted">Turn this on if this entity will contain other entities under it.</div>
                     </div>
                     <label class="switch">
                        <input v-model="form.is_group" type="checkbox" />
                        <span class="slider round"></span>
                     </label>
                  </div>

                  <!-- DETAIL TRIGGER -->
                  <div class="mt-8 border-t pt-8">
                     <div v-if="!showDetailSection">
                        <p class="text-sm text-muted mb-4">Does this organization require legal, tax, or contact information?</p>
                        <button class="btn btn-outline py-2 px-6" @click="showDetailSection = true">
                           <Plus :size="14" /> Add Detail
                        </button>
                     </div>

                     <div v-else class="inline-expanded-detail mt-4">
                        <div class="flex gap-2 mb-6">
                           <button class="btn btn-xs btn-outline" @click="showDetailSection = false"><ChevronRight :size="12" class="rotate-90" /> Hide Form</button>
                           <button class="btn btn-xs btn-outline text-danger" @click="clearDetailFields"><X :size="12" /> Clear & Discard</button>
                        </div>

                        <div class="detail-fields-grid border p-4 rounded-xl">
                           <div class="form-grid">
                              <div class="form-group">
                                 <label class="form-label text-xs">Official Legal Company Name</label>
                                 <input v-model="form.legal_name" type="text" class="input input-sm" placeholder="eg. QELEM MEDA PLC" />
                              </div>
                              <div class="form-group">
                                 <label class="form-label text-xs">Trade Name</label>
                                 <select v-model="form.trade_name" class="input input-sm">
                                    <option value="">eg. Qelem Meda</option>
                                 </select>
                              </div>

                              <div class="form-group span-2">
                                 <label class="form-label text-xs">Upload Icon</label>
                                 <div class="upload-zone border-dashed border-2 p-8 text-center rounded-lg">
                                    <div class="flex-center flex-col gap-2">
                                       <div class="upload-icon-box text-muted">
                                          <Plus :size="24" />
                                       </div>
                                       <p class="text-xs text-muted"> <span class="text-primary font-bold">Click to upload</span> or drag and drop</p>
                                       <p class="text-[10px] text-muted opacity-60">SVG, PNG files up to 5MB</p>
                                    </div>
                                 </div>
                              </div>

                              <div class="form-group">
                                 <label class="form-label text-xs">Legal Entity Type</label>
                                 <select v-model="form.legal_entity_type_id" class="input input-sm">
                                    <option value="">Select Type</option>
                                    <option value="1">PLC</option>
                                 </select>
                              </div>
                              <div class="form-group">
                                 <label class="form-label text-xs">Establishment Date</label>
                                 <input v-model="form.date_established" type="date" class="input input-sm" />
                              </div>
                              <div class="form-group">
                                 <label class="form-label text-xs">Tin Number</label>
                                 <input v-model="form.tin" type="text" class="input input-sm" placeholder="000000" />
                              </div>
                              <div class="form-group">
                                 <label class="form-label text-xs">VAT Reg Number</label>
                                 <input v-model="form.vat_reg_number" type="text" class="input input-sm" placeholder="VAT-000-000" />
                              </div>
                              <div class="form-group">
                                 <label class="form-label text-xs">VAT Reg Date</label>
                                 <input v-model="form.vat_reg_date" type="date" class="input input-sm" />
                              </div>
                              <div class="form-group">
                                 <label class="form-label text-xs">Tax Center</label>
                                 <select v-model="form.tax_center_id" class="input input-sm">
                                    <option value="">eg. Large Tax</option>
                                 </select>
                              </div>
                              <div class="form-group">
                                 <label class="form-label text-xs">Contact Email</label>
                                 <input v-model="form.email" type="email" class="input input-sm" placeholder="office@company.com" />
                              </div>
                              <div class="form-group">
                                 <label class="form-label text-xs">Contact Phone</label>
                                 <div class="phone-input">
                                    <select class="phone-code">
                                       <option>ET</option>
                                    </select>
                                    <input v-model="form.phone" type="tel" class="input input-sm" placeholder="+251 000-000-000" style="border:none" />
                                 </div>
                              </div>
                              <div class="form-group span-2">
                                 <label class="form-label text-xs">House Number</label>
                                 <input v-model="form.house_number" type="text" class="input input-sm" />
                              </div>
                           </div>

                           <div class="toggle-card mt-6 p-4 bg-white">
                              <div class="toggle-info">
                                 <div class="toggle-title text-sm font-bold">Primary Branch/Shop</div>
                                 <div class="text-[11px] text-muted">Marks this as the main branch or shop for this entity.</div>
                              </div>
                              <label class="switch">
                                 <input v-model="form.is_primary" type="checkbox" />
                                 <span class="slider round"></span>
                              </label>
                           </div>
                        </div>
                     </div>
                  </div>
                </div>

                <!-- TAB 2: CONFIGURATION -->
                <div v-if="activeTab === 'config'" class="tab-content transition-tab">
                   <div class="form-grid">
                      <div class="form-group">
                         <label class="form-label">Costing Rule</label>
                         <input type="text" class="input" placeholder="Weighted Average Cost" readonly />
                      </div>
                      <div class="form-group">
                         <label class="form-label">Base Currency</label>
                         <select v-model="form.base_currency_id" class="input">
                            <option value="1">Birr</option>
                         </select>
                      </div>

                      <div class="form-group">
                         <label class="form-label">Select Document</label>
                         <div class="multi-select-box p-2 border rounded-lg flex flex-wrap gap-2">
                           <span class="chip-label">Manufacturing <X :size="10" /></span>
                           <span class="chip-label">Agriculture <X :size="10" /></span>
                           <span class="chip-label">Technology <X :size="10" /></span>
                           <span class="chip-label text-muted">+ 3</span>
                         </div>
                      </div>
                      <div class="form-group">
                         <label class="form-label">Select Primary Sector</label>
                         <select class="input">
                            <option>Technology</option>
                         </select>
                      </div>
                   </div>

                   <!-- MAP INTEGRATION SECTION -->
                   <div class="map-integration-card border rounded-xl p-6 mt-8">
                      <div class="flex-between mb-4">
                         <div>
                            <h4 class="font-bold text-sm">Map Integration</h4>
                            <p class="text-xs text-muted">Choose the Method and Select insert the coordinates</p>
                         </div>
                         <div class="qelem-visual">
                            <span class="text-primary font-bold">QelemMeda</span>
                         </div>
                      </div>

                      <div class="segment-toggle mb-6">
                         <button class="segment-btn active">Decimal degrees (DD)</button>
                         <button class="segment-btn">Degrees, minutes, and seconds (DMS)</button>
                      </div>

                      <div class="form-grid">
                         <div class="form-group">
                            <label class="form-label text-[11px]">latitude</label>
                            <input v-model="form.latitude" type="text" class="input" placeholder="eg.40.40338, 2.17..." />
                         </div>
                         <div class="form-group">
                            <label class="form-label text-[11px]">longitude</label>
                            <input v-model="form.longitude" type="text" class="input" placeholder="eg.41.40338, 2.17..." />
                         </div>
                      </div>
                   </div>
                </div>

                <div v-if="activeTab === 'detail'" class="tab-content transition-tab">
                  <div class="flex-between mb-8 border-b pb-4">
                     <div>
                        <h3 class="h3 mb-1">Entity Details</h3>
                        <p class="text-xs text-muted">A dedicated view of the legal and commercial data for this node.</p>
                     </div>
                  </div>
                  
                  <div v-if="!showDetailSection" class="empty-state-mini p-12 text-center border-2 border-dashed rounded-xl">
                      <Edit :size="48" class="text-muted mx-auto mb-4 opacity-20" />
                      <p class="text-sm text-muted">No details have been added yet in the Identity tab.</p>
                      <button class="btn btn-primary mt-4" @click="activeTab = 'basic'; showDetailSection = true">Jump to Identity & Add Details</button>
                  </div>

                  <div v-else class="form-grid">
                    <div class="form-group span-2">
                       <label class="form-label">Legal Company Name</label>
                       <input v-model="form.legal_name" type="text" class="input" />
                    </div>
                    <!-- fields identical to inline section -->
                    <div class="form-group">
                       <label class="form-label">Legal Entity Type</label>
                       <select v-model="form.legal_entity_type_id" class="input">
                         <option value="">Select Type</option>
                         <option value="1">PLC</option>
                         <option value="2">Share Company</option>
                         <option value="3">NGO</option>
                       </select>
                    </div>
                    <div class="form-group">
                       <label class="form-label">TIN Number</label>
                       <input v-model="form.tin" type="text" class="input" />
                    </div>
                    <div class="form-group">
                       <label class="form-label">VAT Reg Number</label>
                       <input v-model="form.vat_reg_number" type="text" class="input" />
                    </div>
                    <div class="form-group">
                       <label class="form-label">Contact Email</label>
                       <input v-model="form.email" type="email" class="input" />
                    </div>
                    <div class="form-group">
                       <label class="form-label">Contact Phone</label>
                       <input v-model="form.phone" type="tel" class="input" />
                    </div>
                  </div>
                </div>
                
                <!-- FOOTER WITHIN CARD FOR MOBILE OR ALTERNATIVE -->
            <div class="form-footer-ghost mt-8">
               <p class="text-xs text-muted">Field marked with <span class="text-danger">*</span> are mandatory.</p>
            </div>
          </div> <!-- end doc-body -->
        </div> <!-- end form-container -->
      </div> <!-- end view-create -->

      <!-- DETAIL VIEW -->
      <div v-else-if="currentView === 'detail' && selectedEntity" class="view-detail">
        <div class="detail-container">
           <div class="detail-header card">
              <div class="flex items-center gap-4">
                 <button class="btn btn-icon" @click="currentView = 'list'"><ArrowLeft :size="18" /></button>
                 <div class="header-main">
                    <div class="text-xs uppercase font-bold text-muted">{{ entityTypeConfig.name }}</div>
                    <div class="h1">{{ selectedEntity.name }}</div>
                 </div>
              </div>
              <div class="header-actions">
                 <button class="btn btn-outline"><Edit :size="14" /> Edit</button>
                 <button v-if="entityTypeConfig.level < 5" class="btn btn-primary" @click="addChild(selectedEntity)">
                    <Plus :size="14" /> Add {{ entityTypeConfig.level === 1 ? 'Organization' : 'Child' }}
                 </button>
              </div>
           </div>

           <div class="detail-grid mt-4">
              <div class="card detail-info">
                 <h3 class="h3 border-b pb-2 mb-4">Properties</h3>
                 <div class="info-row">
                    <span class="label">Code</span>
                    <span class="value font-mono">{{ selectedEntity.code }}</span>
                 </div>
                 <div class="info-row">
                    <span class="label">Abbreviation</span>
                    <span class="value">{{ selectedEntity.abbreviation }}</span>
                 </div>
                 <div class="info-row">
                    <span class="label">Status</span>
                    <span class="value"><span class="badge badge-success">{{ selectedEntity.state }}</span></span>
                 </div>
              </div>
              
              <div class="card detail-stats">
                 <h3 class="h3 border-b pb-2 mb-4">Structure</h3>
                 <div class="empty-mini">
                    <GitBranch :size="32" class="text-muted opacity-20" />
                    <p class="text-xs text-muted">No children records registered under this entity yet.</p>
                 </div>
              </div>
           </div>
        </div>
      </div> <!-- end view-specific-logic -->
    </div> <!-- end haleta-container -->
  </main> <!-- end haleta-scroll-body -->

    <!-- MODAL FOR ADDING DETAIL FROM LIST (High Fidelity - Outside Scroll) -->
    <div v-if="showDetailModal" class="modal-overlay">
       <div class="modal w-lg animate-in">
          <div class="modal-header">
             <h3 class="h3">Add Detail: {{ selectedEntity?.name }}</h3>
             <button class="btn-icon" @click="showDetailModal = false"><X :size="20" /></button>
          </div>
          <div class="modal-body p-8 max-h-[70vh] overflow-y-auto">
             <div class="form-grid">
                <div class="form-group span-2">
                   <label class="form-label text-xs">Official Company Name</label>
                   <input v-model="form.legal_name" type="text" class="input" placeholder="eg. Haleta ERP" />
                </div>
                <div class="form-group">
                   <label class="form-label text-xs">TIN</label>
                   <input v-model="form.tin" type="text" class="input" />
                </div>
                <div class="form-group">
                   <label class="form-label text-xs">VAT</label>
                   <input v-model="form.vat_reg_number" type="text" class="input" />
                </div>
             </div>
          </div>
          <div class="modal-footer px-8 py-4 border-t flex justify-end gap-3">
             <button class="btn btn-outline" @click="showDetailModal = false">Cancel</button>
             <button class="btn btn-save px-8" @click="saveDetailOnly">Save</button>
          </div>
       </div>
    </div>
  </div> <!-- end entity-manager wrapper -->
</template>

<style scoped>
.entity-manager {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background-color: #f8fafc;
}

.btn-save {
  background: #1d4ed8;
  color: white;
  border-radius: 6px;
  padding: 8px 36px;
  border: none;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
}

.btn-establish {
  background: #4f46e5;
  color: white;
  border-radius: 6px;
  padding: 8px 24px;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 600;
}

.haleta-scroll-body {
  flex: 1;
  overflow-y: auto;
  background: #f8fafc;
}

.haleta-container {
  padding: 32px 64px;
}

.breadcrumb .sep { margin: 0 4px; color: #cbd5e1; }

/* LIST STYLES */
.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  margin-bottom: 16px;
}

.search-box {
  display: flex;
  align-items: center;
  background: #f1f5f9;
  border-radius: 6px;
  padding: 4px 12px;
  width: 300px;
}
.search-input {
  border: none;
  background: transparent;
  outline: none;
  padding: 6px;
  font-size: 13px;
  width: 100%;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table th {
  text-align: left;
  padding: 16px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--color-text-muted);
  border-bottom: 2px solid #f1f5f9;
  background: #f8fafc;
}

.data-table td {
  padding: 16px;
  vertical-align: middle;
}

.clickable:hover { background-color: #f8fafc; }

.status-indicator {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
}
.status-indicator.active { background: #ecfdf5; color: #059669; }
.status-indicator.inactive { background: #fef2f2; color: #dc2626; }
.status-indicator::before { content: ''; width: 6px; height: 6px; border-radius: 50%; background: currentColor; }

/* METRIC CARDS */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 20px;
}
.metric-card {
  padding: 24px;
  transition: transform 0.2s, box-shadow 0.2s;
}
.metric-card:hover { transform: translateY(-4px); box-shadow: var(--shadow-lg); }

.metric-body { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 16px; }
.metric-label { font-size: 13px; font-weight: 600; color: var(--color-text-muted); text-transform: uppercase; margin-bottom: 8px; }
.metric-value { font-size: 28px; font-weight: 800; color: #0f172a; }
.metric-icon-box { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; }

.metric-footer { border-top: 1px solid #f1f5f9; pt: 12px; display: flex; gap: 8px; }

.bg-primary-light { background: #eef2ff; }
.bg-success-light { background: #ecfdf5; }
.bg-indigo-light { background: #f5f3ff; }
.bg-warning-light { background: #fffbeb; }

.text-primary { color: #4f46e5; }
.text-success { color: #059669; }
.text-indigo { color: #4f46e5; }
.text-warning { color: #d97706; }

.code-badge {
  background: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
  font-family: monospace;
  font-size: 12px;
  color: #475569;
}

/* EMPTY STATE */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 100px 20px;
  text-align: center;
}
.empty-illust {
  background: var(--color-primary-light);
  width: 120px; height: 120px;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  margin-bottom: 24px;
}

/* FORM STYLES */
.form-container {
  max-width: 1100px;
  margin: 0 auto;
}

.parent-context-card {
  background: linear-gradient(135deg, #5e5cc7 0%, #4a49a8 100%);
  color: white;
  border-radius: 12px;
  padding: 16px 24px;
  margin-bottom: 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 10px 25px -5px rgba(94, 92, 199, 0.4);
}

.context-label { font-size: 10px; text-transform: uppercase; font-weight: 700; opacity: 0.8; margin-bottom: 4px; }
.context-content { display: flex; align-items: center; gap: 16px; }
.context-icon { background: rgba(255,255,255,0.2); width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; }
.context-title { font-size: 18px; font-weight: 700; }

.doc-wrapper {
  display: flex;
  gap: 32px;
}

.doc-sidebar {
  width: 200px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.doc-icon-ring {
  width: 80px; height: 80px;
  background: white;
  border: 1px solid var(--color-border);
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  margin-bottom: 32px;
  box-shadow: var(--shadow-sm);
}

.doc-nav {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.doc-nav-btn {
  width: 100%;
  text-align: right;
  padding: 10px 16px;
  font-size: 13px;
  font-weight: 600;
  color: var(--color-text-muted);
  border-radius: 6px;
  border: none;
  background: transparent;
  cursor: pointer;
  transition: all 0.2s;
}

.doc-nav-btn.active {
  background: white;
  color: var(--color-primary);
  box-shadow: var(--shadow-sm);
}

.doc-body {
  flex: 1;
  padding: 40px;
  min-height: 600px;
}

.section-title {
  margin-top: 0;
  margin-bottom: 32px;
  padding-bottom: 12px;
  border-bottom: 2px solid #f1f5f9;
  font-size: 18px;
  color: #0f172a;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px 32px;
}
.span-2 { grid-column: span 2; }

.input-with-icon {
  position: relative;
  display: flex;
  align-items: center;
}
.input-with-icon .icon {
  position: absolute;
  left: 12px;
  color: var(--color-text-muted);
}
.input-with-icon .input {
  padding-left: 36px;
}

.form-info-box span { line-height: 1.4; }

.checkbox-group { display: flex; align-items: center; height: 38px; }
.checkbox-label { 
  display: flex; align-items: center; gap: 8px; 
  font-size: 13px; font-weight: 500; cursor: pointer; 
}
.checkbox-label input { width: 16px; height: 16px; accent-color: var(--color-primary); cursor: pointer; }

.pt-lg { padding-top: 24px; }

.animate-spin { animation: spin 1s linear infinite; }
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }

.animate-in { animation: slideUp 0.4s ease-out; }
@keyframes slideUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

.transition-tab { animation: fadeIn 0.3s ease; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

/* DETAIL VIEW STYLES */
.detail-container {
  max-width: 1000px;
  margin: 0 auto;
}
.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px;
}
.detail-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}
.info-row {
  display: flex;
  justify-content: space-between;
  padding: 12px 0;
  border-bottom: 1px solid #f1f5f9;
}
.info-row:last-child { border-bottom: none; }
.info-row .label { color: var(--color-text-muted); font-size: 13px; }
.info-row .value { font-weight: 600; font-size: 13px; }

.empty-mini {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px;
  text-align: center;
  gap: 12px;
}

.w-lg { width: 700px; }
.max-h-lg { max-height: 70vh; }
.overflow-y { overflow-y: auto; }

.sector-picker .chip {
  background: #f1f5f9;
  color: #64748b;
  padding: 6px 14px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 500;
  border: 1px solid transparent;
  transition: all 0.2s;
}

.sector-picker .chip.active {
  background: var(--color-primary-light);
  color: var(--color-primary);
  border-color: var(--color-primary);
}

.flex-center { display: flex; align-items: center; justify-content: center; }
.flex-between { display: flex; align-items: center; justify-content: space-between; }

/* CAPSULE TABS */
.capsule-tabs {
  display: flex;
  background: #f1f5f9;
  padding: 4px;
  border-radius: 50px;
  width: fit-content;
}
.capsule-tab {
  padding: 6px 20px;
  border-radius: 50px;
  font-size: 13px;
  font-weight: 600;
  color: #64748b;
  border: none;
  background: transparent;
  cursor: pointer;
  transition: all 0.2s;
}
.capsule-tab.active {
  background: white;
  color: #0f172a;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

/* TOGGLE SECTION */
.toggle-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #f8fafc;
  padding: 16px 24px;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}
.toggle-info { flex: 1; }
.toggle-title { font-size: 14px; color: #0f172a; margin-bottom: 2px; }

/* SWITCH STYLES */
.switch { position: relative; display: inline-block; width: 44px; height: 24px; }
.switch input { opacity: 0; width: 0; height: 0; }
.slider {
  position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0;
  background-color: #cbd5e1; transition: .4s;
}
.slider:before {
  position: absolute; content: ""; height: 18px; width: 18px; left: 3px; bottom: 3px;
  background-color: white; transition: .4s;
}
input:checked + .slider { background-color: #4f46e5; }
input:checked + .slider:before { transform: translateX(20px); }
.slider.round { border-radius: 34px; }
.slider.round:before { border-radius: 50%; }

/* UPLOAD ZONE */
.upload-zone { border: 2px dashed #e2e8f0; background: #fafafa; }
.upload-icon-box { background: white; border: 1px solid #e2e8f0; width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; }

/* SEGMENT BUTTONS */
.segment-toggle { background: #f1f5f9; padding: 4px; border-radius: 8px; display: flex; width: fit-content; }
.segment-btn {
  padding: 8px 16px; border-radius: 6px; font-size: 12px; font-weight: 500; border: none; background: transparent; cursor: pointer;
}
.segment-btn.active { background: white; color: #0f172a; box-shadow: 0 1px 2px rgba(0,0,0,0.1); }

.chip-label { background: #eef2ff; color: #4f46e5; padding: 4px 10px; border-radius: 6px; font-weight: 600; font-size: 11px; display: flex; align-items: center; gap: 6px; }
.phone-input { display: flex; align-items: center; border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden; }
.phone-code { background: #f8fafc; border: none; border-right: 1px solid #e2e8f0; padding: 0 8px; height: 100%; font-size: 12px; }

</style>
