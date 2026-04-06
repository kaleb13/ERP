<script setup lang="ts">
import { ref } from 'vue';
import { Search, Filter, Plus, MoreVertical, Building, X } from 'lucide-vue-next';

interface Organization {
  id: string;
  name: string;
  abbreviation: string;
  legalEntityType: string;
  state: 'Active' | 'Inactive';
}

const orgs = ref<Organization[]>([
  { id: '1', name: 'Qelem Meda Investment Group', abbreviation: 'QMIG', legalEntityType: 'PLC', state: 'Active' },
  { id: '2', name: 'Medirock Investment Group', abbreviation: 'MIG', legalEntityType: 'Share Company', state: 'Active' },
  { id: '3', name: 'TTM Trading', abbreviation: 'TTM', legalEntityType: 'Sole Proprietorship', state: 'Inactive' }
]);

const currentView = ref<'list' | 'create_full'>('list');
const showQuickCreate = ref(false);

const newOrg = ref({
  name: '',
  abbreviation: '',
  entity_id: ''
});

const openQuickCreate = () => {
  showQuickCreate.value = true;
};

const closeQuickCreate = () => {
  showQuickCreate.value = false;
};

const expandFullForm = () => {
  showQuickCreate.value = false;
  currentView.value = 'create_full';
};

const saveQuickCreate = () => {
  orgs.value.push({
    id: Date.now().toString(),
    name: newOrg.value.name,
    abbreviation: newOrg.value.abbreviation,
    legalEntityType: 'Pending',
    state: 'Active'
  });
  newOrg.value = { name: '', abbreviation: '', entity_id: '' };
  showQuickCreate.value = false;
};

const cancelFullForm = () => {
  currentView.value = 'list';
};

const activeTab = ref('basic');
const tabs = [
  { id: 'basic', label: 'Basic Info' },
  { id: 'legal', label: 'Legal & Tax' },
  { id: 'location', label: 'Location' },
  { id: 'structure', label: 'Structure' },
  { id: 'contact', label: 'Contact' },
  { id: 'advanced', label: 'Advanced' }
];
</script>

<template>
  <div class="organizations">
    
    <!-- ERP TOP NAV / BREADCRUMB BAR -->
    <div class="erp-nav">
      <div class="erp-nav-left">
        <div class="breadcrumb text-sm">
          <span class="root">Home</span>
          <ChevronRight :size="14" class="sep" />
          <span class="current">Organizations</span>
        </div>
        <div class="view-title">
          <h1 class="h2">{{ currentView === 'list' ? 'Organizations' : 'New Organization' }}</h1>
        </div>
      </div>
      <div class="erp-nav-right">
        <button v-if="currentView === 'list'" class="btn btn-primary" @click="openQuickCreate">
          <Plus :size="14" /> Add Organization
        </button>
        <template v-else>
           <button class="btn btn-outline" @click="cancelFullForm">Cancel</button>
           <button class="btn btn-primary">Save</button>
        </template>
      </div>
    </div>

    <!-- LIST VIEW -->
    <div v-if="currentView === 'list'" class="view-list">
      <div class="toolbar card">
        <div class="toolbar-left">
          <div class="search-box">
            <Search :size="14" class="search-icon" />
            <input type="text" placeholder="Search..." class="search-input" />
          </div>
          <button class="btn btn-outline btn-filter">
            <Filter :size="14" /> Filter
          </button>
        </div>
      </div>

      <div class="table-container card">
        <table class="data-table">
          <thead>
            <tr>
              <th class="check-col"><input type="checkbox" /></th>
              <th>Name</th>
              <th>Abbreviation</th>
              <th>Legal Entity</th>
              <th>State</th>
              <th class="actions-col"></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="org in orgs" :key="org.id">
              <td><input type="checkbox" /></td>
              <td class="col-name">
                {{ org.name }}
              </td>
              <td class="text-muted">{{ org.abbreviation }}</td>
              <td class="text-muted">{{ org.legalEntityType }}</td>
              <td>
                <span class="state-dot" :class="org.state.toLowerCase()"></span>
                <span class="text-xs uppercase font-bold">{{ org.state }}</span>
              </td>
              <td class="actions-col">
                <button class="btn-icon"><MoreVertical :size="14" /></button>
              </td>
            </tr>
          </tbody>
        </table>
        
        <div class="pagination">
          <div class="text-xs text-muted">Showing {{ orgs.length }} Organizations</div>
          <div class="page-controls">
            <button class="btn btn-outline btn-xs">1</button>
          </div>
        </div>
      </div>
    </div>

    <!-- FULL FORM VIEW (ERPNext 'Document' style) -->
    <div v-else-if="currentView === 'create_full'" class="view-form">
      <div class="form-container">
        
        <!-- Document Status Header -->
        <div class="doc-header card">
           <div class="doc-title-box">
              <div class="doc-icon"><Building :size="24" /></div>
              <div class="doc-info">
                 <div class="text-xs text-muted uppercase font-bold letter-spacing-tight">Organization</div>
                 <div class="h3 doc-id">Draft</div>
              </div>
           </div>
           <div class="doc-status">
              <div class="badge-status">
                 <span class="dot yellow"></span>
                 Not Saved
              </div>
           </div>
        </div>

        <div class="form-content card">
          <div class="tabs-sideways">
            <div class="tabs-v-header">
              <button 
                v-for="tab in tabs" 
                :key="tab.id"
                class="v-tab-btn"
                :class="{ active: activeTab === tab.id }"
                @click="activeTab = tab.id"
              >
                {{ tab.label }}
              </button>
            </div>

            <div class="tabs-v-body">
              <div v-if="activeTab === 'basic'" class="tab-pane">
                <h4 class="section-title">General Information</h4>
                <div class="form-grid-2">
                  <div class="form-group">
                    <label class="form-label">Organization Name</label>
                    <input type="text" class="input" placeholder="e.g. Qelem Meda Solutions" />
                  </div>
                  <div class="form-group">
                    <label class="form-label">Abbreviation</label>
                    <input type="text" class="input" placeholder="e.g. QMS" />
                  </div>
                  <div class="form-group">
                    <label class="form-label">Entity ID Reference</label>
                    <input type="text" class="input" placeholder="Select Entity..." />
                  </div>
                  <div class="form-group">
                    <label class="form-label">Date Established</label>
                    <input type="date" class="input" />
                  </div>
                </div>
              </div>
              
              <div v-if="activeTab === 'legal'" class="tab-pane">
                <h4 class="section-title">Registration Details</h4>
                <div class="form-grid-2">
                  <div class="form-group">
                    <label class="form-label">Legal Entity Type</label>
                    <select class="input">
                      <option value="">Select Type</option>
                      <option value="plc">PLC</option>
                      <option value="sc">Share Company</option>
                    </select>
                  </div>
                  <div class="form-group">
                    <label class="form-label">TIN Number</label>
                    <input type="text" class="input" placeholder="Tax ID" />
                  </div>
                  <div class="form-group">
                    <label class="form-label">VAT Number</label>
                    <input type="text" class="input" placeholder="VAT Registration" />
                  </div>
                  <div class="form-group">
                    <label class="form-label">Trade Name</label>
                    <input type="text" class="input" />
                  </div>
                </div>
              </div>

              <!-- Other tabs follow same pattern -->
              <div v-if="activeTab === 'contact'" class="tab-pane">
                <h4 class="section-title">Contact Channels</h4>
                <div class="form-grid-2">
                  <div class="form-group">
                    <label class="form-label">Email</label>
                    <input type="email" class="input" />
                  </div>
                  <div class="form-group">
                    <label class="form-label">Phone</label>
                    <input type="tel" class="input" />
                  </div>
                </div>
              </div>

            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- QUICK CREATE MODAL -->
    <div v-if="showQuickCreate" class="modal-overlay">
      <div class="modal">
        <div class="modal-header">
          <h3 class="h3">Quick Create: Organization</h3>
          <button class="btn-icon" @click="closeQuickCreate"><X :size="20" /></button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label class="form-label">Name <span class="text-danger">*</span></label>
            <input type="text" class="input" v-model="newOrg.name" placeholder="Organization name" />
          </div>
          <div class="form-group">
            <label class="form-label">Abbreviation</label>
            <input type="text" class="input" v-model="newOrg.abbreviation" placeholder="e.g. ORG" />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-outline" @click="expandFullForm">Expand Full Form</button>
          <button class="btn btn-primary" @click="saveQuickCreate">Save</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ERP COMPONENT STYLES */
.erp-nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 20px;
  background-color: white;
  border-bottom: 1px solid var(--color-border);
  margin-bottom: 20px;
  position: sticky;
  top: 0;
  z-index: 10;
}

.erp-nav-left {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.breadcrumb {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--color-text-muted);
}
.sep { color: #ccc; }
.breadcrumb .current { color: #1a1c21; font-weight: 500; }

.erp-nav-right {
  display: flex;
  gap: 10px;
}

.title-row { margin-bottom: 0; }

.toolbar {
  background: white;
  padding: 8px 12px;
  margin-bottom: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.search-box {
  display: flex;
  align-items: center;
  background: var(--color-bg);
  padding: 6px 12px;
  border-radius: 4px;
  border: 1px solid transparent;
  width: 250px;
}
.search-box:focus-within {
  background: white;
  border-color: var(--color-primary);
}
.search-input {
  border: none;
  background: transparent;
  outline: none;
  font-size: 13px;
  margin-left: 8px;
  width: 100%;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table th {
  text-align: left;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-text-muted);
  padding: 12px 16px;
  border-bottom: 1px solid var(--color-border);
}

.data-table td {
  padding: 12px 16px;
  font-size: 13px;
  border-bottom: 1px solid #f1f3f4;
}

.check-col { width: 40px; text-align: center; }
.actions-col { width: 40px; text-align: right; }

.col-name { font-weight: 600; color: var(--color-primary); }

.state-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 6px;
}
.state-dot.active { background-color: var(--color-success); }
.state-dot.inactive { background-color: #ccc; }

/* FORM View ERP Style */
.form-container {
  max-width: 1000px;
  margin: 0 auto;
}

.doc-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px;
  margin-bottom: 20px;
}

.doc-title-box {
  display: flex;
  align-items: center;
  gap: 16px;
}

.doc-icon {
  width: 48px;
  height: 48px;
  background: var(--color-primary-light);
  color: var(--color-primary);
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
}

.badge-status {
  padding: 6px 12px;
  background: #fff8e1;
  color: #f57c00;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 6px;
}
.dot.yellow { background: #f57c00; width: 6px; height: 6px; border-radius: 50%; }

.tabs-sideways {
  display: flex;
  min-height: 500px;
}

.tabs-v-header {
  width: 200px;
  border-right: 1px solid var(--color-border);
  padding: 12px 0;
}

.v-tab-btn {
  width: 90%;
  text-align: left;
  padding: 10px 20px;
  font-size: 13px;
  font-weight: 500;
  color: var(--color-text-muted);
  border-radius: 0 4px 4px 0;
  margin-bottom: 2px;
}
.v-tab-btn:hover { background-color: var(--color-bg); color: var(--color-text-main); }
.v-tab-btn.active {
  background-color: var(--color-primary-light);
  color: var(--color-primary);
  border-left: 3px solid var(--color-primary);
}

.tabs-v-body {
  flex: 1;
  padding: 32px;
}

.section-title {
  font-size: 16px;
  font-weight: 700;
  margin-bottom: 24px;
  padding-bottom: 8px;
  border-bottom: 1px solid #f1f3f4;
}

.form-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px 40px;
}

/* Modal Overlay Rest of common ones... */
.modal-overlay {
  position: fixed;
  top: 0; left: 0; width: 100vw; height: 100vh;
  background: rgba(0,0,0,0.25);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}
.modal {
  background: white; border-radius: 8px; width: 450px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.2);
}
.modal-header { padding: 16px 20px; border-bottom: 1px solid #eee; display: flex; justify-content: space-between; align-items: center; }
.modal-body { padding: 24px; }
.modal-footer { padding: 12px 20px; border-top: 1px solid #eee; display: flex; justify-content: flex-end; gap: 8px; }
</style>
