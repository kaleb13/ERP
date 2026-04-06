<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { 
  Search, Filter, Plus, MoreVertical, Building2, Building, GitBranch, Store, ShoppingCart,
  X, ChevronRight, ArrowLeft, Save, Trash2, Edit, CheckCircle, Info, MapPin, Globe, Loader2
} from 'lucide-vue-next';

const route = useRoute();
const router = useRouter();

// --- STATE MANAGEMENT ---
const currentView = ref<'list' | 'create' | 'detail'>('list');
const isLoading = ref(false);
const entities = ref<any[]>([]);
const hasBusinessGroup = ref(false); // Simulated check
const parentEntity = ref<any>(null); // For the "Floating Parent Card"

// --- CONFIGURATION BASED ON ROUTE ---
const entityTypeConfig = computed(() => {
  const path = route.path;
  if (path.includes('business-groups')) return { name: 'Business Group', icon: Building2, level: 1, typeId: 1 };
  if (path.includes('organizations')) return { name: 'Organization', icon: Building, level: 2, typeId: 2 };
  if (path.includes('branches')) return { name: 'Branch', icon: GitBranch, level: 3, typeId: 3 };
  if (path.includes('branch-shops')) return { name: 'Branch Shop', icon: Store, level: 4, typeId: 4 };
  if (path.includes('outlets')) return { name: 'Outlet', icon: ShoppingCart, level: 5, typeId: 5 };
  return { name: 'Entity', icon: Building, level: 0, typeId: 0 };
});

const form = ref({
  name: '',
  code: '',
  abbreviation: '',
  parent_id: '',
  pos_type: 'retail',
  state: 'active',
  // Details
  tin: '',
  legal_name: '',
  email: '',
  phone: '',
  vat_reg_number: '',
  latitude: '',
  longitude: ''
});

// --- ACTIONS ---
const fetchEntities = async () => {
  isLoading.value = true;
  // Simulated fetch
  setTimeout(() => {
    if (entityTypeConfig.value.level === 1) {
      entities.value = [
        { id: '1', name: 'QMT Business Group', code: 'QMT-BG-001', abbreviation: 'QMTBG', state: 'active' }
      ];
      hasBusinessGroup.value = true;
    } else if (entityTypeConfig.value.level === 2) {
       entities.value = [
         { id: '10', name: 'QMT Addis Branch Org', code: 'QMT-BR-ADDIS-01', abbreviation: 'QMT-ADDIS', state: 'active', parent_name: 'QMT Business Group' }
       ];
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

const resetForm = () => {
  form.value = {
    name: '', code: '', abbreviation: '', parent_id: '', pos_type: 'retail', state: 'active',
    tin: '', legal_name: '', email: '', phone: '', vat_reg_number: '', latitude: '', longitude: ''
  };
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

onMounted(() => {
  fetchEntities();
  fetchParentIfNeeded();
});
watch(() => route.path, () => {
  currentView.value = 'list';
  fetchEntities();
});
watch(() => route.query.parent_id, fetchParentIfNeeded);

// Tabs for Full Form
const activeTab = ref('basic');
const tabs = [
  { id: 'basic', label: 'Basic Info' },
  { id: 'detail', label: 'Legal/Details' },
  { id: 'location', label: 'Location' }
];

</script>

<template>
  <div class="entity-manager">
    <!-- TOP NAVIGATION BAR -->
    <div class="erp-nav">
      <div class="erp-nav-left">
        <div class="breadcrumb text-xs">
          <span class="root cursor-pointer" @click="router.push('/dashboard')">Home</span>
          <ChevronRight :size="12" class="sep" />
          <span class="current">{{ entityTypeConfig.name }}s</span>
        </div>
        <div class="view-title">
          <h1 class="h2">{{ currentView === 'list' ? `${entityTypeConfig.name}s` : `Create ${entityTypeConfig.name}` }}</h1>
        </div>
      </div>
      <div class="erp-nav-right">
        <template v-if="currentView === 'list'">
          <!-- Business Group Logic: If exists and level 1, hide create button -->
          <button 
            v-if="!(entityTypeConfig.level === 1 && hasBusinessGroup)"
            class="btn btn-primary" 
            @click="goToCreate()"
          >
            <Plus :size="14" /> {{ entityTypeConfig.level === 1 ? 'Create Business Group' : `Add ${entityTypeConfig.name}` }}
          </button>
        </template>
        <template v-else>
           <button class="btn btn-outline" @click="cancel">Cancel</button>
           <button class="btn btn-primary" @click="saveEntity" :disabled="isLoading">
             <Save :size="14" v-if="!isLoading" />
             <Loader2 :size="14" v-else class="animate-spin" />
             Save
           </button>
        </template>
      </div>
    </div>

    <div class="main-content">
      <!-- LIST VIEW -->
      <div v-if="currentView === 'list'" class="view-list">
        
        <!-- EMPTY STATE FOR BUSINESS GROUP (CENTERED) -->
        <div v-if="entityTypeConfig.level === 1 && !hasBusinessGroup && !isLoading" class="empty-state">
           <div class="empty-illust">
             <Building2 :size="64" class="text-primary opacity-20" />
           </div>
           <h2 class="h2">No Business Group Yet</h2>
           <p class="text-muted">Register your business group to start building your organization hierarchy.</p>
           <button class="btn btn-primary btn-lg mt-4" @click="goToCreate()">
             Establish Business Group
           </button>
        </div>

        <template v-else>
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
                  <th>Name</th>
                  <th>Code</th>
                  <th v-if="entityTypeConfig.level > 1">Parent</th>
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
                     {{ entity.parent_name }}
                  </td>
                  <td>
                    <span class="badge" :class="entity.state === 'active' ? 'badge-success' : 'badge-neutral'">
                      {{ entity.state }}
                    </span>
                  </td>
                  <td class="actions-col text-right">
                    <button class="btn btn-xs btn-outline mr-2" @click.stop="addChild(entity)">
                      <Plus :size="12" /> Child
                    </button>
                    <button class="btn-icon"><MoreVertical :size="14" /></button>
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

          <!-- DUAL-MODE FORM (Document Style) -->
          <div class="doc-wrapper">
             <div class="doc-sidebar">
                <div class="doc-icon-ring">
                   <component :is="entityTypeConfig.icon" :size="32" class="text-primary" />
                </div>
                <nav class="doc-nav">
                  <button 
                    v-for="tab in tabs" 
                    :key="tab.id"
                    class="doc-nav-btn"
                    :class="{ active: activeTab === tab.id }"
                    @click="activeTab = tab.id"
                  >
                    {{ tab.label }}
                  </button>
                </nav>
             </div>

             <div class="doc-body card">
                <div v-if="activeTab === 'basic'" class="tab-content transition-tab">
                  <h3 class="section-title">General Identity</h3>
                  <div class="form-grid">
                    <div class="form-group span-2">
                       <label class="form-label">Full Name <span class="text-danger">*</span></label>
                       <input v-model="form.name" type="text" class="input" :placeholder="`e.g. ${entityTypeConfig.name} Addis`" />
                    </div>
                    <div class="form-group">
                       <label class="form-label">Unique Code <span class="text-danger">*</span></label>
                       <input v-model="form.code" type="text" class="input" placeholder="e.g. QMT-001" />
                    </div>
                    <div class="form-group">
                       <label class="form-label">Abbreviation</label>
                       <input v-model="form.abbreviation" type="text" class="input" placeholder="e.g. QMT" />
                    </div>
                    <div class="form-group">
                       <label class="form-label">Operation Type</label>
                       <select v-model="form.pos_type" class="input">
                         <option value="retail">Retail</option>
                         <option value="hospitality">Hospitality</option>
                         <option value="mixed">Mixed</option>
                       </select>
                    </div>
                    <div class="form-group">
                       <label class="form-label">Initial State</label>
                       <select v-model="form.state" class="input">
                         <option value="active">Active</option>
                         <option value="inactive">Inactive</option>
                       </select>
                    </div>
                  </div>
                </div>

                <div v-if="activeTab === 'detail'" class="tab-content transition-tab">
                  <h3 class="section-title">Legal & Commercial Information</h3>
                  <div class="form-grid">
                    <div class="form-group span-2">
                       <label class="form-label">Legal Company Name</label>
                       <input v-model="form.legal_name" type="text" class="input" />
                    </div>
                    <div class="form-group">
                       <label class="form-label">TIN Number</label>
                       <input v-model="form.tin" type="text" class="input" />
                    </div>
                    <div class="form-group">
                       <label class="form-label">VAT Reg. Number</label>
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

                <div v-if="activeTab === 'location'" class="tab-content transition-tab">
                   <h3 class="section-title">Geolocation</h3>
                   <div class="form-info-box">
                      <Info :size="16" />
                      <span>Latitude and Longitude help in mapping resources and delivery zones.</span>
                   </div>
                   <div class="form-grid">
                     <div class="form-group">
                        <label class="form-label">Latitude</label>
                        <div class="input-with-icon">
                          <MapPin :size="14" class="icon" />
                          <input v-model="form.latitude" type="text" class="input" placeholder="0.0000" />
                        </div>
                     </div>
                     <div class="form-group">
                        <label class="form-label">Longitude</label>
                        <div class="input-with-icon">
                          <Globe :size="14" class="icon" />
                          <input v-model="form.longitude" type="text" class="input" placeholder="0.0000" />
                        </div>
                     </div>
                   </div>
                </div>
                
                <!-- FOOTER WITHIN CARD FOR MOBILE OR ALTERNATIVE -->
                <div class="form-footer-ghost mt-8">
                   <p class="text-xs text-muted">Field marked with <span class="text-danger">*</span> are mandatory.</p>
                </div>
             </div>
          </div>
        </div>
      </div>

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
      </div>
    </div>
  </div>
</template>

<style scoped>
.entity-manager {
  display: flex;
  flex-direction: column;
  height: 100%;
}

/* TOP NAV */
.erp-nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 24px;
  background: white;
  border-bottom: 1px solid var(--color-border);
  position: sticky;
  top: 0;
  z-index: 20;
}

.breadcrumb .sep { margin: 0 4px; color: #cbd5e1; }
.breadcrumb .root:hover { color: var(--color-primary); }

.view-title h1 { margin: 4px 0 0; }

/* CONTENT AREA */
.main-content {
  flex: 1;
  padding: 24px;
  overflow-y: auto;
}

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
  padding: 12px 16px;
  font-size: 11px;
  text-transform: uppercase;
  color: var(--color-text-muted);
  border-bottom: 1px solid var(--color-border);
}

.data-table td {
  padding: 14px 16px;
  font-size: 13px;
  border-bottom: 1px solid #f1f5f9;
}

.clickable { cursor: pointer; }
.clickable:hover { background-color: #f8fafc; }

.col-name { font-weight: 600; color: var(--color-primary); }

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

.form-info-box {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 16px;
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 12px;
  color: #64748b;
  margin-bottom: 24px;
}

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
</style>
