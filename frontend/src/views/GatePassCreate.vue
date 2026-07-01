<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { 
  Monitor, ChevronRight, Info, FileText, ChevronDown, Plus, Trash2,
  Upload, Download, Columns, Undo2, Redo2, Bold, Italic, Underline, 
  Strikethrough, Code, Link, Image, AlignLeft, UploadCloud, Square, Maximize2,
  Send, ArrowDownLeft, Printer, ScanLine, ZoomIn, ZoomOut, MoreVertical, Check, X, ArrowUpRight
} from 'lucide-vue-next';
import BaseTabs from '../components/BaseTabs.vue';

// State management
const documentState = ref<'new_unsaved' | 'draft' | 'draft_modified' | 'approved'>('new_unsaved');
const savedDraftData = ref<any>(null);
const isSaved = ref(false);
const activeTab = ref<'basic' | 'more'>('basic');
const tabs: { id: 'basic' | 'more'; label: string; icon: any }[] = [
  { id: 'basic', label: 'Basic', icon: Info },
  { id: 'more', label: 'More Information', icon: FileText }
];
const isMovementExpanded = ref(true);
const isMoreInfoExpanded = ref(true);
const isAttachmentsExpanded = ref(false);

const documentName = ref('');
const issuedTo = ref('');
const movementDirection = ref('');
const sourceLocation = ref('');
const destinationLocation = ref('');
const referenceDocumentType = ref('');
const selectedDocument = ref('');

// More Info fields
const vehiclePlate = ref('');
const driverName = ref('');
const externalReference = ref('');
const canBeReferenced = ref(true);
const remark = ref('');

const showPrintPreview = ref(false);
const zoomLevel = ref(1.0);
const collapseSettings = ref(false);
const printDocumentName = ref('');

const printSettings = ref({
  showCompanyLogo: true,
  showDocumentName: true,
  showVehiclePlate: false,
  showReceiverName: false,
  showRemark: false,
  productDisplayMode: 'detailed' // 'detailed' or 'summary'
});

const columns = ref({
  product: true,
  batch: true,
  uom: true,
  location: false,
  quantity: true
});

const docNumber = computed(() => {
  if (movementDirection.value === 'inward') return 'IGP-2026-00012';
  if (movementDirection.value === 'outward') return 'OGP-2026-00012';
  return 'IGP-2026-00012'; // default match screenshot
});

const printPages = computed(() => {
  if (printSettings.value.productDisplayMode === 'summary') {
    return [{
      pageNumber: 1,
      isSummary: true,
      rows: [],
      startIndex: 0
    }];
  }
  
  const pages: any[] = [];
  const rows = movementRows.value.length > 0 ? movementRows.value : [
    { id: 1, product: 'Bluetooth Speaker (SPK-3005)', batch: 'BCH-1001', uom: 'Kg', quantity: '52' },
    { id: 2, product: 'Notebook A5 (STN-4003)', batch: 'BCH-1001', uom: 'Pcs', quantity: '10' }
  ];
  
  let currentIdx = 0;
  let pageNum = 1;
  
  while (currentIdx < rows.length) {
    const limit = pageNum === 1 ? 8 : 18;
    const pageRows = rows.slice(currentIdx, currentIdx + limit);
    pages.push({
      pageNumber: pageNum,
      isSummary: false,
      rows: pageRows,
      startIndex: currentIdx
    });
    currentIdx += limit;
    pageNum++;
  }
  
  return pages;
});

const handlePrint = () => {
  zoomLevel.value = 1.0;
  printDocumentName.value = documentName.value || 'Gate Pass Document';
  showPrintPreview.value = true;
};

const executePrint = () => {
  window.print();
};

const downloadPDF = () => {
  alert("Downloading Document as PDF...");
};

const zoomIn = () => {
  if (zoomLevel.value < 2.0) zoomLevel.value += 0.1;
};
const zoomOut = () => {
  if (zoomLevel.value > 0.5) zoomLevel.value -= 0.1;
};

const openDropdown = ref<string | null>(null);
const toggleDropdown = (name: string) => {
  openDropdown.value = openDropdown.value === name ? null : name;
};
const closeDropdowns = () => { openDropdown.value = null; };

onMounted(() => document.addEventListener('click', closeDropdowns));
onUnmounted(() => document.removeEventListener('click', closeDropdowns));

const getTriggerLabel = computed(() => {
  if (referenceDocumentType.value === 'po') return 'Purchase Document';
  if (referenceDocumentType.value === 'so') return 'Sales Document';
  return 'Select';
});

const getDocumentLabel = computed(() => {
  const doc = documentOptions.value.find(d => d.value === selectedDocument.value);
  return doc ? doc.label : 'Select document...';
});

const documentOptions = computed(() => {
  if (referenceDocumentType.value === 'po') {
    return [
      { value: 'PO-2026-001', label: 'PO-2026-001 (Tech Supplier Inc)' },
      { value: 'PO-2026-002', label: 'PO-2026-002 (Office Depot)' }
    ];
  } else if (referenceDocumentType.value === 'so') {
    return [
      { value: 'SO-2026-001', label: 'SO-2026-001 (Client A)' },
      { value: 'SO-2026-002', label: 'SO-2026-002 (Client B)' }
    ];
  }
  return [];
});

const movementRows = ref<{ id: number; selected: boolean; product: string; batch: string; uom: string; location: string; quantity: string }[]>([]);

watch(selectedDocument, (newVal) => {
  if (newVal) {
    if (newVal.startsWith('PO')) {
      movementRows.value = [
        { id: Date.now() + 1, selected: false, product: 'Notebook A5 (STN-4003)', batch: 'BCH-1001', uom: 'Pcs', location: 'Main Warehouse', quantity: '10' },
        { id: Date.now() + 2, selected: false, product: 'Printer Ink (CY-120)', batch: 'BCH-1002', uom: 'Box', location: 'Warehouse - 22', quantity: '2' }
      ];
    } else if (newVal.startsWith('SO')) {
      movementRows.value = [
        { id: Date.now() + 3, selected: false, product: 'Office Chair (ERG-202)', batch: 'BCH-2001', uom: 'Pcs', location: 'Main Warehouse', quantity: '5' }
      ];
    }
  } else {
    movementRows.value = [];
  }
});

const totalProducts = computed(() => movementRows.value.length || 2); // fallback if empty for display
const totalQuantity = computed(() => {
  if (movementRows.value.length === 0) return 62; // fallback
  return movementRows.value.reduce((acc, row) => acc + Number(row.quantity || 0), 0);
});
const batchCount = computed(() => {
  if (movementRows.value.length === 0) return 1; // fallback
  return new Set(movementRows.value.map(row => row.batch).filter(b => b)).size;
});

const hasSelectedRows = computed(() => movementRows.value.some(row => row.selected));

const isAllSelected = computed(() => {
  return movementRows.value.length > 0 && movementRows.value.every(row => row.selected);
});

const toggleAll = (e: Event) => {
  const checked = (e.target as HTMLInputElement).checked;
  movementRows.value.forEach(row => {
    row.selected = checked;
  });
};

const addRow = () => {
  movementRows.value.push({
    id: Date.now(),
    selected: false,
    product: '',
    batch: '',
    uom: 'Pcs',
    location: sourceLocation.value || 'Main Warehouse',
    quantity: ''
  });
};

const deleteSelectedRows = () => {
  movementRows.value = movementRows.value.filter(row => !row.selected);
};

const activeProductDropdownId = ref<number | null>(null);

const closeProductDropdown = (id: number) => {
  setTimeout(() => {
    if (activeProductDropdownId.value === id) {
      activeProductDropdownId.value = null;
    }
  }, 150);
};

const selectProduct = (row: any, productName: string) => {
  row.product = productName;
  activeProductDropdownId.value = null;
};

// Form state machine handlers
const handleSaveDraft = () => {
  savedDraftData.value = {
    documentName: documentName.value,
    issuedTo: issuedTo.value,
    movementDirection: movementDirection.value,
    sourceLocation: sourceLocation.value,
    destinationLocation: destinationLocation.value,
    referenceDocumentType: referenceDocumentType.value,
    selectedDocument: selectedDocument.value,
    vehiclePlate: vehiclePlate.value,
    driverName: driverName.value,
    externalReference: externalReference.value,
    canBeReferenced: canBeReferenced.value,
    remark: remark.value,
    movementRows: JSON.parse(JSON.stringify(movementRows.value))
  };
  isSaved.value = true;
  documentState.value = 'draft';
  closeDropdowns();
};

const handleClearChange = () => {
  if (!savedDraftData.value) return;
  documentName.value = savedDraftData.value.documentName;
  issuedTo.value = savedDraftData.value.issuedTo;
  movementDirection.value = savedDraftData.value.movementDirection;
  sourceLocation.value = savedDraftData.value.sourceLocation;
  destinationLocation.value = savedDraftData.value.destinationLocation;
  referenceDocumentType.value = savedDraftData.value.referenceDocumentType;
  selectedDocument.value = savedDraftData.value.selectedDocument;
  vehiclePlate.value = savedDraftData.value.vehiclePlate;
  driverName.value = savedDraftData.value.driverName;
  externalReference.value = savedDraftData.value.externalReference;
  canBeReferenced.value = savedDraftData.value.canBeReferenced;
  remark.value = savedDraftData.value.remark;
  movementRows.value = JSON.parse(JSON.stringify(savedDraftData.value.movementRows));
  documentState.value = 'draft';
  closeDropdowns();
};

const handleClearForm = () => {
  documentName.value = '';
  issuedTo.value = '';
  movementDirection.value = '';
  sourceLocation.value = '';
  destinationLocation.value = '';
  referenceDocumentType.value = '';
  selectedDocument.value = '';
  vehiclePlate.value = '';
  driverName.value = '';
  externalReference.value = '';
  canBeReferenced.value = true;
  remark.value = '';
  movementRows.value = [];
  documentState.value = 'new_unsaved';
  closeDropdowns();
};

const handleApprove = () => {
  documentState.value = 'approved';
  closeDropdowns();
};

// Form state detector
const hasChangesFromDraft = computed(() => {
  if (!isSaved.value || !savedDraftData.value) return false;
  
  const simpleChanged = 
    documentName.value !== savedDraftData.value.documentName ||
    issuedTo.value !== savedDraftData.value.issuedTo ||
    movementDirection.value !== savedDraftData.value.movementDirection ||
    sourceLocation.value !== savedDraftData.value.sourceLocation ||
    destinationLocation.value !== savedDraftData.value.destinationLocation ||
    referenceDocumentType.value !== savedDraftData.value.referenceDocumentType ||
    selectedDocument.value !== savedDraftData.value.selectedDocument ||
    vehiclePlate.value !== savedDraftData.value.vehiclePlate ||
    driverName.value !== savedDraftData.value.driverName ||
    externalReference.value !== savedDraftData.value.externalReference ||
    canBeReferenced.value !== savedDraftData.value.canBeReferenced ||
    remark.value !== savedDraftData.value.remark;

  if (simpleChanged) return true;

  if (movementRows.value.length !== savedDraftData.value.movementRows.length) return true;

  for (let i = 0; i < movementRows.value.length; i++) {
    const r1 = movementRows.value[i];
    const r2 = savedDraftData.value.movementRows[i];
    if (
      r1.product !== r2.product ||
      r1.batch !== r2.batch ||
      r1.uom !== r2.uom ||
      r1.location !== r2.location ||
      r1.quantity !== r2.quantity
    ) {
      return true;
    }
  }

  return false;
});

watch(hasChangesFromDraft, (changed) => {
  if (documentState.value === 'approved') return;
  if (isSaved.value) {
    documentState.value = changed ? 'draft_modified' : 'draft';
  } else {
    documentState.value = 'new_unsaved';
  }
});

// Badges
const statusBadgeText = computed(() => {
  switch (documentState.value) {
    case 'new_unsaved': return 'Not Saved';
    case 'draft': return 'Draft';
    case 'draft_modified': return 'Not Saved';
    case 'approved': return 'Approved';
    default: return 'Not Saved';
  }
});

const statusBadgeClass = computed(() => {
  switch (documentState.value) {
    case 'new_unsaved': return 'badge-notsaved';
    case 'draft': return 'badge-draft';
    case 'draft_modified': return 'badge-notsaved';
    case 'approved': return 'badge-approved';
    default: return 'badge-notsaved';
  }
});
</script>

<template>
  <div class="gate-pass-create-page">
    
    <!-- Top Action Bar & Breadcrumbs -->
    <div class="page-top-bar">
      <div class="breadcrumbs">
        <router-link to="/dashboard" class="breadcrumb-link">
          <Monitor :size="16" />
        </router-link>
        <ChevronRight :size="14" class="breadcrumb-separator" />
        <router-link to="/gate-pass" class="breadcrumb-link text-gray-500">Gate Pass</router-link>
        <ChevronRight :size="14" class="breadcrumb-separator" />
        <span class="breadcrumb-active">Create Gate Pass</span>
        
        <!-- Dynamic Status Badge -->
        <span class="status-badge" :class="statusBadgeClass">
          {{ statusBadgeText }}
        </span>
      </div>

      <!-- Action buttons on top right -->
      <div class="top-bar-actions">
        <!-- Three Dot Menu -->
        <div class="three-dot-menu-wrapper" @click.stop="toggleDropdown('threeDot')">
          <button class="btn-three-dot" :class="{ 'is-active': openDropdown === 'threeDot' }">
            <MoreVertical :size="18" />
          </button>
          
          <div class="three-dot-dropdown shadow-lg" v-if="openDropdown === 'threeDot'">
            <button 
              class="dropdown-menu-item" 
              @click="handleSaveDraft"
              :disabled="documentState === 'approved' || documentState === 'draft'"
            >
              <FileText :size="16" /> Save as draft
            </button>
            <button 
              v-if="documentState === 'new_unsaved'" 
              class="dropdown-menu-item" 
              @click="handleClearForm"
            >
              <Undo2 :size="16" /> Clear Form
            </button>
            <button 
              v-if="documentState === 'draft_modified'" 
              class="dropdown-menu-item" 
              @click="handleClearChange"
            >
              <Undo2 :size="16" /> Clear Change
            </button>
            <button 
              class="dropdown-menu-item" 
              @click="handleApprove"
              :disabled="documentState === 'approved'"
            >
              <Check :size="16" /> Approve
            </button>
          </div>
        </div>

        <!-- Direct Actions -->
        <template v-if="documentState === 'new_unsaved'">
          <button class="btn-secondary" @click="handleClearForm">
            <X :size="16" /> Clear Form
          </button>
          <button class="btn-approve-primary" @click="handleApprove">
            Approve
          </button>
        </template>
        
        <template v-else-if="documentState === 'draft'">
          <button class="btn-approve-primary" @click="handleApprove">
            Approve
          </button>
        </template>

        <template v-else-if="documentState === 'draft_modified'">
          <button class="btn-secondary" @click="handleClearChange">
            <X :size="16" /> Clear Change
          </button>
          <button class="btn-approve-primary" @click="handleApprove">
            Approve
          </button>
        </template>

        <template v-else-if="documentState === 'approved'">
          <button class="btn-approved-disabled" disabled>
            Approved
          </button>
        </template>
      </div>
    </div>

    <!-- Tabs Area (shared component) -->
    <div class="tabs-wrapper">
      <BaseTabs v-model="activeTab" :tabs="tabs" />
    </div>

    <!-- Info Banner (Only when Draft/Saved) spans FULL WIDTH -->
    <div v-if="documentState === 'draft' || documentState === 'draft_modified'" class="alert-banner info-banner">
      <div class="banner-content">
        <Info :size="18" class="banner-icon" />
        <span>
          This gate pass has been saved as a draft and is <strong>not yet authorized for use</strong>. Approve the gate pass to authorize the movement and make it available for verification and processing.
        </span>
      </div>
    </div>

    <!-- MAIN CONTENT GRID -->
    <div class="content-body" :class="{ 'has-sidebar': isSaved }">
      
      <!-- LEFT / MAIN COLUMN -->
      <div class="main-column">

        <!-- BASIC INFORMATION TAB -->
        <template v-if="activeTab === 'basic'">
          <!-- Basic Information Form Card -->
          <div class="content-card form-card">
            <div class="form-grid-three-col">
              
              <!-- Document Name -->
              <div class="form-group span-two">
                <label class="form-label">Document Name</label>
                <input 
                  type="text" 
                  class="form-input" 
                  v-model="documentName" 
                  placeholder="Enter document header..." 
                  :disabled="documentState === 'approved'"
                />
              </div>

              <!-- Issued To dropdown -->
              <div class="form-group">
                <label class="form-label">Issued To</label>
                <div class="custom-select-wrapper" @click.stop="documentState !== 'approved' && toggleDropdown('issuedTo')">
                  <div class="custom-select-trigger" :class="{ 'is-open': openDropdown === 'issuedTo', 'is-disabled': documentState === 'approved' }">
                    {{ issuedTo || 'Select' }}
                    <ChevronDown :size="16" class="select-icon" />
                  </div>
                  <div class="custom-select-dropdown" v-if="openDropdown === 'issuedTo'">
                    <div class="custom-option" @click="issuedTo = 'Bekele Alemu'; closeDropdowns()">Bekele Alemu</div>
                    <div class="custom-option" @click="issuedTo = 'Kaleb Tadesse'; closeDropdowns()">Kaleb Tadesse</div>
                    <div class="custom-option" @click="issuedTo = 'General Store Manager'; closeDropdowns()">General Store Manager</div>
                  </div>
                </div>
              </div>

              <!-- Movement Direction -->
              <div class="form-group">
                <label class="form-label">Movement Direction <span class="required">*</span></label>
                <div class="custom-select-wrapper" @click.stop="documentState !== 'approved' && toggleDropdown('direction')">
                  <div class="custom-select-trigger" :class="{ 'is-open': openDropdown === 'direction', 'is-disabled': documentState === 'approved' }">
                    {{ movementDirection === 'inward' ? 'Inward' : (movementDirection === 'outward' ? 'Outward' : 'Select Location') }}
                    <ChevronDown :size="16" class="select-icon" />
                  </div>
                  <div class="custom-select-dropdown" v-if="openDropdown === 'direction'">
                    <div class="custom-option" @click="movementDirection = 'inward'; closeDropdowns()">Inward</div>
                    <div class="custom-option" @click="movementDirection = 'outward'; closeDropdowns()">Outward</div>
                  </div>
                </div>
              </div>

              <!-- Source Location -->
              <div class="form-group">
                <label class="form-label">Source Location <span class="required">*</span></label>
                <div class="custom-select-wrapper" @click.stop="documentState !== 'approved' && toggleDropdown('source_location')">
                  <div class="custom-select-trigger" :class="{ 'is-open': openDropdown === 'source_location', 'is-disabled': documentState === 'approved' }">
                    {{ sourceLocation || 'Select Location' }}
                    <ChevronDown :size="16" class="select-icon" />
                  </div>
                  <div class="custom-select-dropdown" v-if="openDropdown === 'source_location'">
                    <div class="custom-option" @click="sourceLocation = 'Main Warehouse'; closeDropdowns()">Main Warehouse</div>
                    <div class="custom-option" @click="sourceLocation = 'Warehouse - 22'; closeDropdowns()">Warehouse - 22</div>
                    <div class="custom-option" @click="sourceLocation = 'Loading Dock A'; closeDropdowns()">Loading Dock A</div>
                  </div>
                </div>
              </div>

              <!-- Destination Location -->
              <div class="form-group">
                <label class="form-label">Destination Location</label>
                <div class="custom-select-wrapper" @click.stop="documentState !== 'approved' && toggleDropdown('dest_location')">
                  <div class="custom-select-trigger" :class="{ 'is-open': openDropdown === 'dest_location', 'is-disabled': documentState === 'approved' }">
                    {{ destinationLocation || 'Select Location' }}
                    <ChevronDown :size="16" class="select-icon" />
                  </div>
                  <div class="custom-select-dropdown" v-if="openDropdown === 'dest_location'">
                    <div class="custom-option" @click="destinationLocation = 'Main Warehouse'; closeDropdowns()">Main Warehouse</div>
                    <div class="custom-option" @click="destinationLocation = 'Warehouse - 22'; closeDropdowns()">Warehouse - 22</div>
                    <div class="custom-option" @click="destinationLocation = 'Customer Site'; closeDropdowns()">Customer Site</div>
                  </div>
                </div>
              </div>

              <!-- Reference Document Type -->
              <div class="form-group">
                <label class="form-label">Reference Document Type</label>
                <div class="custom-select-wrapper" @click.stop="documentState !== 'approved' && toggleDropdown('ref_type')">
                  <div class="custom-select-trigger" :class="{ 'is-open': openDropdown === 'ref_type', 'is-disabled': documentState === 'approved' }">
                    {{ referenceDocumentType === 'po' ? 'Purchase Document' : (referenceDocumentType === 'so' ? 'Sales Document' : 'Select') }}
                    <ChevronDown :size="16" class="select-icon" />
                  </div>
                  <div class="custom-select-dropdown" v-if="openDropdown === 'ref_type'">
                    <div class="custom-option" @click="referenceDocumentType = 'po'; selectedDocument = ''; closeDropdowns()">Purchase Document</div>
                    <div class="custom-option" @click="referenceDocumentType = 'so'; selectedDocument = ''; closeDropdowns()">Sales Document</div>
                    <div class="custom-option" @click="referenceDocumentType = ''; selectedDocument = ''; closeDropdowns()">None</div>
                  </div>
                </div>
              </div>

              <!-- Get Items From -->
              <div class="form-group span-two">
                <label class="form-label">Get Items From</label>
                <div class="custom-select-wrapper" @click.stop="documentState !== 'approved' && referenceDocumentType && toggleDropdown('get_items')">
                  <div class="custom-select-trigger" :class="{ 'is-open': openDropdown === 'get_items', 'is-disabled': documentState === 'approved' || !referenceDocumentType }">
                    {{ getDocumentLabel }}
                    <ChevronDown :size="16" class="select-icon" />
                  </div>
                  <div class="custom-select-dropdown" v-if="openDropdown === 'get_items'">
                    <div class="custom-option" v-for="doc in documentOptions" :key="doc.value" @click="selectedDocument = doc.value; closeDropdowns()">
                      {{ doc.label }}
                    </div>
                  </div>
                </div>
                <p class="select-hint-text">
                  Select the source document that contains the required items. The items will be automatically imported from the selected document.
                </p>
              </div>

            </div>
          </div>

          <!-- Movement Products Form Card -->
          <div class="content-card toggle-card">
            <div class="card-header-toggle" :class="{ 'is-expanded': isMovementExpanded }" @click="isMovementExpanded = !isMovementExpanded">
              <h3 class="card-title">Movement Products</h3>
              <ChevronDown 
                :size="18" 
                class="text-gray-500 transition-transform" 
                :class="{ 'rotate-minus-90': !isMovementExpanded }" 
              />
            </div>

            <div class="card-inner-body" v-show="isMovementExpanded">
              <div class="table-wrapper">
                <table class="grid-table">
                  <thead>
                    <tr>
                      <th width="40" class="text-center">
                        <input 
                          type="checkbox" 
                          class="table-checkbox" 
                          :checked="isAllSelected"
                          @change="toggleAll"
                          :disabled="documentState === 'approved'"
                        />
                      </th>
                      <th width="80">No.</th>
                      <th v-if="columns.product">Product</th>
                      <th width="180" v-if="columns.batch">Batch</th>
                      <th width="120" v-if="columns.uom">UOM</th>
                      <th width="180" v-if="columns.location">Location</th>
                      <th width="120" v-if="columns.quantity">Quantity</th>
                      <th width="60" class="text-center">
                        <Columns :size="16" class="text-gray-400 cursor-pointer hover:text-gray-600 inline" @click.stop="toggleDropdown('columns')" />
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="movementRows.length === 0">
                      <td colspan="7" class="empty-row text-center">
                        No rows
                      </td>
                    </tr>
                    <tr v-for="(row, index) in movementRows" :key="row.id" class="data-row">
                      <td class="text-center">
                        <input type="checkbox" class="table-checkbox" v-model="row.selected" :disabled="documentState === 'approved'" />
                      </td>
                      <td>{{ index + 1 }}</td>
                      <td class="relative-cell" v-if="columns.product">
                        <input 
                          type="text" 
                          class="table-input" 
                          v-model="row.product" 
                          placeholder="Search or enter product..." 
                          @focus="activeProductDropdownId = row.id"
                          @blur="closeProductDropdown(row.id)"
                          :disabled="documentState === 'approved'"
                        />
                        
                        <!-- Product Search Dropdown -->
                        <div class="product-dropdown shadow-lg" v-if="activeProductDropdownId === row.id">
                          <div class="dropdown-item" @click="selectProduct(row, 'Notebook A5 (STN-4003)')">Notebook A5 (STN-4003)</div>
                          <div class="dropdown-item" @click="selectProduct(row, 'Printer Ink (CY-120)')">Printer Ink (CY-120)</div>
                          <div class="dropdown-item" @click="selectProduct(row, 'Office Chair (ERG-202)')">Office Chair (ERG-202)</div>
                          <div class="dropdown-divider"></div>
                          <div class="dropdown-action" @click="activeProductDropdownId = null">
                            <Plus :size="14" />
                            Create New Product
                          </div>
                        </div>
                      </td>
                      <td v-if="columns.batch">
                        <input type="text" class="table-input" v-model="row.batch" placeholder="Batch no." :disabled="documentState === 'approved'" />
                      </td>
                      <td v-if="columns.uom">
                        <input type="text" class="table-input" v-model="row.uom" placeholder="UOM" :disabled="documentState === 'approved'" />
                      </td>
                      <td v-if="columns.location">
                        <input type="text" class="table-input" v-model="row.location" placeholder="Location" :disabled="documentState === 'approved'" />
                      </td>
                      <td v-if="columns.quantity">
                        <input type="text" class="table-input" v-model="row.quantity" placeholder="0" :disabled="documentState === 'approved'" />
                      </td>
                      <td class="text-center">
                        <Maximize2 :size="16" class="text-gray-400 cursor-pointer hover:text-gray-600 inline" />
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div class="table-actions-footer">
                <button v-if="!hasSelectedRows" class="btn-secondary" @click="addRow" :disabled="documentState === 'approved'">
                  <Plus :size="16" />
                  Add Row
                </button>
                <button v-else class="btn-danger" @click="deleteSelectedRows" :disabled="documentState === 'approved'">
                  <Trash2 :size="16" />
                  Delete Row
                </button>
                <div class="right-actions">
                  <button class="btn-secondary" :disabled="documentState === 'approved'">
                    <Upload :size="16" />
                    Export
                  </button>
                  <button class="btn-secondary" :disabled="documentState === 'approved'">
                    <Download :size="16" />
                    Import
                  </button>
                </div>
              </div>

              <!-- Columns show/hide menu -->
              <div class="column-toggle-menu shadow-xl" v-if="openDropdown === 'columns'" @click.stop>
                <div class="column-menu-title">Show/hide columns</div>
                
                <label class="column-menu-item" :class="{ 'is-active': columns.product }">
                  <input type="checkbox" class="table-checkbox" v-model="columns.product" />
                  <span>Product</span>
                </label>
                
                <label class="column-menu-item" :class="{ 'is-active': columns.batch }">
                  <input type="checkbox" class="table-checkbox" v-model="columns.batch" />
                  <span>Batch</span>
                </label>
                
                <label class="column-menu-item" :class="{ 'is-active': columns.quantity }">
                  <input type="checkbox" class="table-checkbox" v-model="columns.quantity" />
                  <span>Quantity</span>
                </label>
                
                <label class="column-menu-item" :class="{ 'is-active': columns.uom }">
                  <input type="checkbox" class="table-checkbox" v-model="columns.uom" />
                  <span>Measurement Unit</span>
                </label>
                
                <label class="column-menu-item" :class="{ 'is-active': columns.location }">
                  <input type="checkbox" class="table-checkbox" v-model="columns.location" />
                  <span>Location</span>
                </label>
              </div>

            </div>
          </div>
        </template>

        <!-- MORE INFORMATION TAB -->
        <template v-if="activeTab === 'more'">
          <div class="content-card form-card">
            
            <div class="form-grid-three-col" style="margin-bottom: 24px;">
              <div class="form-group">
                <label class="form-label">Vehicle Plate Number</label>
                <input 
                  type="text" 
                  class="form-input" 
                  v-model="vehiclePlate" 
                  placeholder="Enter plate number..." 
                  :disabled="documentState === 'approved'"
                />
              </div>
              <div class="form-group">
                <label class="form-label">Driver Name</label>
                <input 
                  type="text" 
                  class="form-input" 
                  v-model="driverName" 
                  placeholder="Enter driver name..." 
                  :disabled="documentState === 'approved'"
                />
              </div>
              <div class="form-group">
                <label class="form-label">External Reference</label>
                <input 
                  type="text" 
                  class="form-input" 
                  v-model="externalReference" 
                  placeholder="Enter external reference ID..." 
                  :disabled="documentState === 'approved'"
                />
              </div>
            </div>

            <!-- Can Be Referenced Checkbox -->
            <div class="form-group checkbox-group" style="margin-bottom: 24px;">
              <label class="checkbox-container">
                <input 
                  type="checkbox" 
                  v-model="canBeReferenced" 
                  :disabled="documentState === 'approved'"
                />
                <span class="checkmark"></span>
                <div class="checkbox-label-block">
                  <span class="checkbox-title">Can Be Referenced</span>
                  <span class="checkbox-desc">Allows this document to be used as a source or reference when creating related documents.</span>
                </div>
              </label>
            </div>

            <!-- Rich Text Editor Section -->
            <div class="editor-section" style="margin-bottom: 24px;">
              <label class="form-label" style="margin-bottom: 12px; display: block;">Remark</label>
              <div class="rich-text-container">
                <div class="editor-toolbar">
                  <button class="toolbar-btn" :disabled="documentState === 'approved'"><Undo2 :size="16" /></button>
                  <button class="toolbar-btn" :disabled="documentState === 'approved'"><Redo2 :size="16" /></button>
                  <div class="toolbar-divider"></div>
                  
                  <div class="toolbar-dropdown">
                    <span>Normal text</span>
                    <ChevronDown :size="14" />
                  </div>
                  
                  <div class="toolbar-dropdown">
                    <AlignLeft :size="16" />
                    <ChevronDown :size="14" />
                  </div>
                  
                  <div class="toolbar-dropdown">
                    <Square :size="14" fill="currentColor" class="text-gray-800" />
                    <ChevronDown :size="14" />
                  </div>
                  
                  <div class="toolbar-divider"></div>
                  
                  <button class="toolbar-btn" :disabled="documentState === 'approved'"><Bold :size="16" /></button>
                  <button class="toolbar-btn" :disabled="documentState === 'approved'"><Italic :size="16" /></button>
                  <button class="toolbar-btn" :disabled="documentState === 'approved'"><Underline :size="16" /></button>
                  <button class="toolbar-btn" :disabled="documentState === 'approved'"><Strikethrough :size="16" /></button>
                  <button class="toolbar-btn" :disabled="documentState === 'approved'"><Code :size="16" /></button>
                  
                  <div class="toolbar-divider"></div>
                  
                  <button class="toolbar-btn" :disabled="documentState === 'approved'"><Link :size="16" /></button>
                  <button class="toolbar-btn" :disabled="documentState === 'approved'"><Image :size="16" /></button>
                </div>
                
                <textarea 
                  class="editor-textarea" 
                  v-model="remark" 
                  placeholder="Enter remarks..."
                  :disabled="documentState === 'approved'"
                ></textarea>
              </div>
            </div>

            <!-- Attachment Section Accordion -->
            <div class="attachments-accordion">
              <div 
                class="accordion-header" 
                @click="isAttachmentsExpanded = !isAttachmentsExpanded"
                :class="{ 'is-expanded': isAttachmentsExpanded }"
              >
                <span class="accordion-title">Attachments</span>
                <ChevronDown 
                  :size="18" 
                  class="text-gray-500 transition-transform" 
                  :class="{ 'rotate-minus-90': !isAttachmentsExpanded }" 
                />
              </div>
              
              <div class="accordion-body" v-show="isAttachmentsExpanded">
                <div class="upload-dropzone" :class="{ 'is-disabled': documentState === 'approved' }">
                  <UploadCloud :size="24" class="text-gray-500 mb-2" />
                  <div class="upload-text">
                    <span class="text-blue-600 font-medium cursor-pointer" :class="{ 'is-disabled': documentState === 'approved' }">Click to upload</span>
                    <span class="text-gray-600"> or drag and drop</span>
                  </div>
                  <div class="upload-hint">PDF, DOC, DOCX files up to 10MB</div>
                </div>
              </div>
            </div>

          </div>
        </template>

      </div> <!-- /main-column -->

      <!-- RIGHT / SIDEBAR COLUMN (Only visible when Saved/Draft) -->
      <div class="sidebar-column" v-if="isSaved">
        
        <!-- Summary Card -->
        <div class="content-card sidebar-card summary-card">
          <div class="summary-header">
            <div class="summary-title">
              <ArrowDownLeft v-if="movementDirection === 'inward'" :size="16" />
              <ArrowUpRight v-else :size="16" />
              <span style="text-transform: capitalize;">{{ movementDirection || 'Inward' }} Movement</span>
            </div>
            <div class="summary-print" @click="handlePrint">
              Print <Printer :size="16" />
            </div>
          </div>
          <div class="summary-subtext">
            To: {{ destinationLocation || 'Main Warehouse' }}
          </div>
          
          <div class="summary-stats">
            <div class="stat-row">
              <span class="stat-label">Source Location</span>
              <span class="stat-value">{{ sourceLocation || 'Main Warehouse' }}</span>
            </div>
            <div class="stat-row">
              <span class="stat-label">Total Product</span>
              <span class="stat-value">{{ totalProducts }}</span>
            </div>
            <div class="stat-row">
              <span class="stat-label">Total Quantity</span>
              <span class="stat-value">{{ totalQuantity }}</span>
            </div>
            <div class="stat-row">
              <span class="stat-label">Batch Count</span>
              <span class="stat-value">{{ batchCount }}</span>
            </div>
          </div>
          
          <div class="summary-footer">
            <span class="stat-label">Status</span>
            <span class="status-badge" :class="statusBadgeClass">
              {{ statusBadgeText }}
            </span>
          </div>
        </div>

        <!-- Barcode Card -->
        <div class="content-card sidebar-card barcode-card">
          <div class="barcode-header">
            <div class="barcode-title">
              <strong>Barcode</strong> <ScanLine :size="16" />
            </div>
            <div class="barcode-subtext">Scan at Gate</div>
          </div>
          <div class="barcode-box">
            <!-- Simulated Barcode Graphic -->
            <div class="barcode-bars"></div>
            <div class="barcode-text">{{ docNumber }}</div>
          </div>
        </div>

        <!-- Info Text -->
        <div class="sidebar-info-box">
          Gate Pass <strong>does not affect stock</strong>. It validates physical movement against the source document.
        </div>

      </div> <!-- /sidebar-column -->

    </div> <!-- /content-body -->

    <!-- Print Settings Modal (Large Full-screen Overlay) -->
    <div v-if="showPrintPreview" class="print-modal-overlay" @click="showPrintPreview = false">
      <div class="print-modal-card" @click.stop>
        
        <!-- Modal Header -->
        <div class="print-modal-header">
          <div class="header-left">
            <h2 class="modal-title">Print Settings</h2>
            <p class="modal-subtitle">Configure Document layout and Visibility</p>
          </div>
          <button class="btn-close-icon" @click="showPrintPreview = false">
            <X :size="20" />
          </button>
        </div>

        <!-- Modal Body (Preview + Settings Sidebar) -->
        <div class="print-modal-body">
          
          <!-- Left: Scrollable Preview Area -->
          <div class="print-preview-container">
            <div class="preview-scrollable-content">
              
              <!-- Printable Sheet -->
              <div class="preview-sheet shadow-lg">
                <div class="sheet-page">
                  
                  <!-- Sheet Header -->
                  <div class="sheet-header">
                    <!-- Left: Logo & Company -->
                    <div class="sheet-logo-group">
                      <div v-if="printSettings.showCompanyLogo" class="sheet-logo-circle">
                        <span class="logo-text-m">M</span>
                      </div>
                      <div class="sheet-title-group">
                        <h1 v-if="printSettings.showDocumentName" class="sheet-doc-title">
                          {{ printDocumentName || 'Gate Pass Document' }}
                        </h1>
                        <h1 v-else class="sheet-doc-title-placeholder">Gate Pass System</h1>
                        <span class="sheet-company-name">Qelem Media Technology</span>
                      </div>
                    </div>
                    
                    <!-- Right: Doc Number & Barcode -->
                    <div class="sheet-doc-number-group">
                      <span class="sheet-doc-number">{{ docNumber }}</span>
                      <div class="sheet-barcode-bars"></div>
                    </div>
                  </div>

                  <!-- Subheader Card / Grid -->
                  <div class="sheet-meta-card">
                    <div class="meta-card-col">
                      <span class="meta-card-value">{{ sourceLocation || 'Main Warehouse' }}</span>
                      <span class="meta-card-label">Location Name</span>
                    </div>
                    <div class="meta-card-col">
                      <span class="meta-card-value" style="text-transform: capitalize;">{{ movementDirection || 'Inward' }}</span>
                      <span class="meta-card-label">Movement Direction</span>
                    </div>
                    <div class="meta-card-col">
                      <span class="meta-card-value">{{ new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) }}</span>
                      <span class="meta-card-label">Date</span>
                    </div>
                  </div>

                  <!-- Optional Info Rows: Vehicle Plate & Receiver & Remark -->
                  <div v-if="(printSettings.showVehiclePlate && vehiclePlate) || (printSettings.showReceiverName && issuedTo) || (printSettings.showRemark && remark)" class="sheet-optional-info">
                    <div v-if="printSettings.showVehiclePlate && vehiclePlate" class="optional-info-item">
                      <span class="optional-label">Vehicle Plate:</span>
                      <span class="optional-value">{{ vehiclePlate }}</span>
                    </div>
                    <div v-if="printSettings.showReceiverName && issuedTo" class="optional-info-item">
                      <span class="optional-label">Receiver Name:</span>
                      <span class="optional-value">{{ issuedTo }}</span>
                    </div>
                    <div v-if="printSettings.showRemark && remark" class="optional-info-item span-full">
                      <span class="optional-label">Remark / Notes:</span>
                      <span class="optional-value">{{ remark }}</span>
                    </div>
                  </div>

                  <!-- Product List / Table Section -->
                  <div class="sheet-products-section">
                    
                    <!-- Summary Mode -->
                    <div v-if="printSettings.productDisplayMode === 'summary'" class="sheet-summary-card">
                      <div class="summary-card-title">Movement Summary</div>
                      <div class="summary-card-grid">
                        <div class="summary-card-item">
                          <span class="summary-label">Total Unique Products</span>
                          <span class="summary-value">{{ movementRows.length || 2 }}</span>
                        </div>
                        <div class="summary-card-item">
                          <span class="summary-label">Total Quantity</span>
                          <span class="summary-value">{{ totalQuantity || 62 }}</span>
                        </div>
                        <div class="summary-card-item">
                          <span class="summary-label">Total Batches</span>
                          <span class="summary-value">{{ batchCount || 1 }}</span>
                        </div>
                      </div>
                    </div>

                    <!-- Detailed List Mode -->
                    <table v-else class="sheet-products-table">
                      <thead>
                        <tr>
                          <th width="60">No.</th>
                          <th>Product</th>
                          <th width="150">Batch No</th>
                          <th width="100">UOM</th>
                          <th width="100" class="text-right">Quantity</th>
                        </tr>
                      </thead>
                      <tbody>
                        <template v-if="movementRows.length > 0">
                          <tr v-for="(row, idx) in movementRows" :key="row.id">
                            <td>{{ idx + 1 }}</td>
                            <td class="font-medium">{{ row.product || 'Unnamed Product' }}</td>
                            <td>{{ row.batch || '-' }}</td>
                            <td>{{ row.uom || '-' }}</td>
                            <td class="text-right font-medium">{{ row.quantity || '0' }}</td>
                          </tr>
                        </template>
                        <!-- Fallback / Demo Rows to match the screenshot -->
                        <template v-else>
                          <tr>
                            <td>1</td>
                            <td class="font-medium">Bluetooth Speaker (SPK-3005)</td>
                            <td>BCH-1001</td>
                            <td>Kg</td>
                            <td class="text-right font-medium">52</td>
                          </tr>
                          <tr>
                            <td>2</td>
                            <td class="font-medium">Notebook A5 (STN-4003)</td>
                            <td>BCH-1001</td>
                            <td>Pcs</td>
                            <td class="text-right font-medium">10</td>
                          </tr>
                        </template>
                      </tbody>
                    </table>
                  </div>

                  <!-- Sheet Signatures -->
                  <div class="sheet-signatures">
                    <div class="signature-line">
                      <span class="sig-label">Authorized Signature</span>
                    </div>
                    <div class="signature-line">
                      <span class="sig-label">Security / Gate Signature</span>
                    </div>
                  </div>

                  <!-- Page Number Badge inside Sheet -->
                  <div class="sheet-page-badge">
                    Page 1/1
                  </div>

                </div>
              </div>

            </div>
          </div>

          <!-- Right: Print Settings Sidebar Menu -->
          <div class="print-sidebar-menu">
            
            <!-- Company Logo Toggle -->
            <div class="setting-row">
              <span class="setting-title">Company Logo</span>
              <label class="switch">
                <input type="checkbox" v-model="printSettings.showCompanyLogo" />
                <span class="slider round"></span>
              </label>
            </div>

            <!-- Document Title Toggle -->
            <div class="setting-row">
              <span class="setting-title">Document Title</span>
              <label class="switch">
                <input type="checkbox" v-model="printSettings.showDocumentName" />
                <span class="slider round"></span>
              </label>
            </div>

            <!-- Vehicle Plate Toggle -->
            <div class="setting-row">
              <span class="setting-title">Vehicle Plate</span>
              <label class="switch">
                <input type="checkbox" v-model="printSettings.showVehiclePlate" />
                <span class="slider round"></span>
              </label>
            </div>

            <!-- Receiver Name Toggle -->
            <div class="setting-row">
              <span class="setting-title">Receiver Name</span>
              <label class="switch">
                <input type="checkbox" v-model="printSettings.showReceiverName" />
                <span class="slider round"></span>
              </label>
            </div>

            <!-- Show Remark Toggle -->
            <div class="setting-row">
              <span class="setting-title">Show Remark</span>
              <label class="switch">
                <input type="checkbox" v-model="printSettings.showRemark" />
                <span class="slider round"></span>
              </label>
            </div>

            <!-- Product Display Layout (Segmented Radio) -->
            <div class="layout-selector-section">
              <span class="section-label">Product Display Layout</span>
              
              <label class="radio-option">
                <input 
                  type="radio" 
                  name="displayLayout" 
                  value="detailed" 
                  v-model="printSettings.productDisplayMode" 
                />
                <span class="radio-circle"></span>
                <div class="radio-text">
                  <span class="radio-title">Detail List</span>
                  <span class="radio-desc">List all products individually. Content automatically paginated to A4 sized pages.</span>
                </div>
              </label>

              <label class="radio-option">
                <input 
                  type="radio" 
                  name="displayLayout" 
                  value="summary" 
                  v-model="printSettings.productDisplayMode" 
                />
                <span class="radio-circle"></span>
                <div class="radio-text">
                  <span class="radio-title">Summary Mode</span>
                  <span class="radio-desc">Displays a compact card showing total counts and quantities. Fits on 1 page.</span>
                </div>
              </label>
            </div>

          </div>

        </div>

        <!-- Modal Footer -->
        <div class="print-modal-footer">
          <button class="btn-close" @click="showPrintPreview = false">
            <X :size="16" /> Close
          </button>
          <div class="footer-right-actions">
            <button class="btn-pdf" @click="downloadPDF">
              <Download :size="16" /> Download PDF
            </button>
            <button class="btn-print" @click="executePrint">
              <Printer :size="16" /> Print
            </button>
          </div>
        </div>

      </div>
    </div>

  </div>
</template>

<style scoped>
.gate-pass-create-page {
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

/* Header & Breadcrumbs */
.page-top-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.breadcrumbs {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
}
.breadcrumb-link {
  color: #6b7280;
  text-decoration: none;
  display: flex;
  align-items: center;
  transition: color 0.15s ease;
}
.breadcrumb-link:hover { color: #111827; }
.breadcrumb-separator { color: #9ca3af; display: flex; align-items: center; }
.breadcrumb-active { color: #374151; font-weight: 600; }

.status-badge {
  margin-left: 8px;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
}
.badge-notsaved { background: #fef3c7; color: #b45309; }
.badge-draft { background: #fce7f3; color: #be185d; }
.badge-approved { background: #ecfdf5; color: #059669; }

/* Top Actions */
.top-bar-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

/* Three Dot Dropdown */
.three-dot-menu-wrapper {
  position: relative;
}
.btn-three-dot {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  cursor: pointer;
  color: #374151;
  transition: all 0.15s;
}
.btn-three-dot:hover, .btn-three-dot.is-active {
  background: #f9fafb;
  border-color: #d1d5db;
}
.three-dot-dropdown {
  position: absolute;
  top: 100%;
  right: 0;
  margin-top: 6px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  width: 180px;
  z-index: 90;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
.dropdown-menu-item {
  width: 100%;
  padding: 12px 16px;
  font-size: 13px;
  color: #374151;
  background: transparent;
  border: none;
  text-align: left;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: background 0.15s;
}
.dropdown-menu-item:hover:not(:disabled) {
  background: #f3f4f6;
}
.dropdown-menu-item:disabled {
  color: #9ca3af;
  cursor: not-allowed;
  opacity: 0.6;
}

/* Secondary Button */
.btn-secondary {
  height: 40px;
  padding: 0 16px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  color: #374151;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-secondary:hover:not(:disabled) {
  background: #f9fafb;
  border-color: #d1d5db;
  color: #111827;
}

.btn-secondary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Approve Primary */
.btn-approve-primary {
  height: 40px;
  padding: 0 24px;
  background: var(--alias-color-brand-blue-primary);
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: white;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-approve-primary:hover {
  background: var(--alias-color-brand-blue-primary-hover);
}

/* Approved Disabled */
.btn-approved-disabled {
  height: 40px;
  padding: 0 24px;
  background: #f3f4f6;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #9ca3af;
  cursor: not-allowed;
}

/* Tabs */
.tabs-wrapper {
  display: inline-flex;
  align-self: flex-start;
}

/* Info Banner */
.alert-banner {
  padding: 12px 20px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 500;
  line-height: 1.5;
  margin-bottom: 8px;
}
.info-banner {
  background-color: #fffbeb;
  border: 1px solid #fde68a;
  color: #b45309;
}
.banner-content {
  display: flex;
  align-items: flex-start;
  gap: 10px;
}
.banner-icon {
  flex-shrink: 0;
  margin-top: 2px;
}

/* Form Layout Grids */
.form-grid-three-col {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
}
.span-two {
  grid-column: span 2;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.form-label {
  font-size: 13px;
  font-weight: 600;
  color: #4b5563;
}
.required {
  color: #ef4444;
  margin-left: 2px;
}
.select-hint-text {
  font-size: 12px;
  color: #6b7280;
  margin-top: 4px;
  line-height: 1.4;
}

.form-input {
  width: 100%;
  height: 40px;
  padding: 0 14px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 14px;
  color: #111827;
  outline: none;
  box-sizing: border-box;
  transition: all 0.15s ease;
}
.form-input:focus:not(:disabled) {
  border-color: #111827;
  box-shadow: 0 0 0 1px #111827;
}
.form-input:disabled {
  background: #f3f4f6;
  color: #9ca3af;
  cursor: not-allowed;
}

/* Custom Select Dropdowns */
.custom-select-wrapper {
  position: relative;
  width: 100%;
}
.custom-select-trigger {
  width: 100%;
  height: 40px;
  padding: 0 12px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 14px;
  color: #374151;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  box-sizing: border-box;
  transition: all 0.2s;
  user-select: none;
}
.custom-select-trigger.is-open {
  border-color: #111827;
  box-shadow: 0 0 0 1px #111827;
}
.custom-select-trigger.is-disabled {
  background: #f3f4f6;
  color: #9ca3af;
  cursor: not-allowed;
}
.select-icon {
  color: #9ca3af;
}
.custom-select-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  margin-top: 4px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  z-index: 50;
  max-height: 200px;
  overflow-y: auto;
}
.custom-option {
  padding: 10px 12px;
  font-size: 14px;
  color: #374151;
  cursor: pointer;
  transition: background 0.15s;
}
.custom-option:hover {
  background: #f3f4f6;
}

/* Content Cards */
.content-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.02);
}
.toggle-card {
  overflow: hidden;
  position: relative;
}
.form-card {
  padding: 24px;
}

/* Card Toggles */
.card-header-toggle {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 16px 24px;
  border-bottom: 1px solid transparent;
  transition: border-color 0.2s;
  user-select: none;
}
.card-header-toggle.is-expanded {
  border-bottom-color: #f3f4f6;
}
.card-title {
  font-size: 14px;
  font-weight: 600;
  color: #374151;
  flex: 1;
}
.card-inner-body {
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding: 24px;
}

/* Grid Table */
.table-wrapper {
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: visible; /* Changed to show dropdown properly */
}
.grid-table {
  width: 100%;
  border-collapse: collapse;
}
.grid-table th {
  text-align: left;
  padding: 12px 16px;
  font-size: 13px;
  font-weight: 600;
  color: #4b5563;
  background: #f9fafb;
  border-bottom: 1px solid #e5e7eb;
}
.grid-table td {
  padding: 12px 16px;
  font-size: 13px;
  color: #374151;
  border-bottom: 1px solid #f3f4f6;
  vertical-align: middle;
}
.grid-table tr:last-child td {
  border-bottom: none;
}
.empty-row {
  color: #9ca3af !important;
  padding: 32px !important;
}
.data-row:hover td {
  background: #f9fafb;
}

.table-input {
  width: 100%;
  border: none;
  background: transparent;
  font-size: 13px;
  color: #374151;
  outline: none;
  height: 30px;
}
.table-input::placeholder {
  color: #9ca3af;
}
.table-input:disabled {
  color: #9ca3af;
  cursor: not-allowed;
}

/* Checkbox Style */
.table-checkbox {
  appearance: none;
  width: 18px;
  height: 18px;
  border-radius: 6px;
  border: 1.5px solid #d1d5db;
  background-color: #f9fafb;
  margin: 0 auto;
  display: flex;
  cursor: pointer;
  transition: all 0.15s;
}
.table-checkbox:hover:not(:disabled) {
  border-color: #9ca3af;
}
.table-checkbox:checked {
  background-color: #111827;
  border-color: #111827;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 16 16' fill='white' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M12.207 4.793a1 1 0 010 1.414l-5 5a1 1 0 01-1.414 0l-2-2a1 1 0 011.414-1.414L6.5 9.086l4.293-4.293a1 1 0 011.414 0z'/%3E%3C/svg%3E");
  background-size: 100% 100%;
  background-position: center;
  background-repeat: no-repeat;
}
.table-checkbox:disabled {
  background-color: #f3f4f6;
  border-color: #e5e7eb;
  cursor: not-allowed;
}

.relative-cell {
  position: relative;
}
.product-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  width: 280px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  z-index: 50;
  margin-top: 4px;
  overflow: hidden;
}

.dropdown-item {
  padding: 10px 16px;
  font-size: 13px;
  color: #374151;
  cursor: pointer;
  transition: background 0.15s;
}
.dropdown-item:hover {
  background: #f3f4f6;
}
.dropdown-divider {
  height: 1px;
  background: #e5e7eb;
  margin: 4px 0;
}
.dropdown-action {
  padding: 10px 16px;
  font-size: 13px;
  font-weight: 500;
  color: #0056cc;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: background 0.15s;
}
.dropdown-action:hover {
  background: #eff6ff;
}

/* Footer Actions */
.table-actions-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 12px;
}
.right-actions {
  display: flex;
  gap: 12px;
}

/* Danger Action */
.btn-danger {
  height: 38px;
  padding: 0 16px;
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 8px;
  font-size: 13px;
  color: #ef4444;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-danger:hover:not(:disabled) {
  background: #fee2e2;
  border-color: #fca5a5;
  color: #dc2626;
}
.btn-danger:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Segmented Custom Radio Checkbox */
.checkbox-container {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  cursor: pointer;
  user-select: none;
}
.checkbox-container input {
  position: absolute;
  opacity: 0;
  cursor: pointer;
  height: 0;
  width: 0;
}
.checkmark {
  width: 20px;
  height: 20px;
  background-color: white;
  border: 1.5px solid #d1d5db;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  flex-shrink: 0;
  margin-top: 2px;
}
.checkbox-container:hover input:not(:disabled) ~ .checkmark {
  border-color: #9ca3af;
}
.checkbox-container input:checked ~ .checkmark {
  background-color: var(--alias-color-brand-blue-primary);
  border-color: var(--alias-color-brand-blue-primary);
}
.checkmark:after {
  content: "";
  display: none;
  width: 5px;
  height: 10px;
  border: solid white;
  border-width: 0 2px 2px 0;
  transform: rotate(45deg);
  margin-bottom: 2px;
}
.checkbox-container input:checked ~ .checkmark:after {
  display: block;
}
.checkbox-container input:disabled ~ .checkmark {
  background-color: #f3f4f6;
  border-color: #e5e7eb;
  cursor: not-allowed;
}
.checkbox-label-block {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.checkbox-title {
  font-size: 14px;
  font-weight: 600;
  color: #374151;
}
.checkbox-desc {
  font-size: 12px;
  color: #6b7280;
  line-height: 1.4;
}

/* Rich text container */
.rich-text-container {
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  background: #f9fafb;
  overflow: hidden;
}
.editor-toolbar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 8px 16px;
  border-bottom: 1px solid #e5e7eb;
  background: white;
}
.toolbar-btn {
  background: transparent;
  border: none;
  border-radius: 6px;
  padding: 6px;
  color: #4b5563;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
}
.toolbar-btn:hover:not(:disabled) {
  background: #f3f4f6;
  color: #111827;
}
.toolbar-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.toolbar-divider {
  width: 1px;
  height: 20px;
  background: #e5e7eb;
  margin: 0 8px;
}
.toolbar-dropdown {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 10px;
  border-radius: 6px;
  font-size: 13px;
  color: #4b5563;
  cursor: pointer;
  transition: all 0.15s;
}
.toolbar-dropdown:hover {
  background: #f3f4f6;
}
.editor-textarea {
  width: 100%;
  min-height: 160px;
  padding: 16px;
  border: none;
  background: #f9fafb;
  resize: vertical;
  outline: none;
  font-size: 14px;
  color: #374151;
  font-family: 'Inter', sans-serif;
  box-sizing: border-box;
}
.editor-textarea:disabled {
  background: #f3f4f6;
  color: #9ca3af;
  cursor: not-allowed;
}

/* Accordion for Attachments */
.attachments-accordion {
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
  background: white;
  margin-top: 16px;
}
.accordion-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  cursor: pointer;
  user-select: none;
  background: white;
  transition: background 0.15s;
}
.accordion-header:hover {
  background: #f9fafb;
}
.accordion-header.is-expanded {
  border-bottom: 1px solid #f3f4f6;
}
.accordion-title {
  font-size: 14px;
  font-weight: 600;
  color: #374151;
}
.accordion-body {
  padding: 24px;
  background: white;
}

.upload-dropzone {
  border: 1.5px dashed #d1d5db;
  border-radius: 12px;
  padding: 32px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #ffffff;
  transition: all 0.2s;
}
.upload-dropzone:hover:not(.is-disabled) {
  border-color: #9ca3af;
  background: #f9fafb;
}
.upload-dropzone.is-disabled {
  background: #f3f4f6;
  border-color: #e5e7eb;
  cursor: not-allowed;
  opacity: 0.7;
}
.upload-text {
  font-size: 14px;
  margin-bottom: 4px;
}
.upload-text span.is-disabled {
  color: #9ca3af;
  cursor: not-allowed;
  text-decoration: none;
}
.upload-hint {
  font-size: 12px;
  color: #9ca3af;
}

/* SPLIT LAYOUT & SIDEBAR */
.content-body {
  display: grid;
  grid-template-columns: 1fr;
  gap: 24px;
  align-items: start;
}
.content-body.has-sidebar {
  grid-template-columns: 1fr 340px;
}
.main-column {
  display: flex;
  flex-direction: column;
  gap: 24px;
  min-width: 0;
}
.sidebar-column {
  display: flex;
  flex-direction: column;
  gap: 24px;
  min-width: 0;
}

/* Sidebar Cards */
.sidebar-card {
  padding: 20px 24px;
}
.summary-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}
.summary-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #374151;
}
.summary-print {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #0056cc;
  cursor: pointer;
  font-weight: 600;
}
.summary-print:hover {
  color: #003d99;
}
.summary-subtext {
  font-size: 12px;
  color: #6b7280;
  margin-bottom: 20px;
}

.summary-stats {
  display: flex;
  flex-direction: column;
  gap: 12px;
  background: #f9fafb;
  padding: 16px;
  border-radius: 8px;
  margin-bottom: 20px;
}
.stat-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
}
.stat-label {
  color: #6b7280;
}
.stat-value {
  color: #111827;
  font-weight: 600;
}
.summary-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
  padding-top: 16px;
  border-top: 1px solid #f3f4f6;
}

/* Barcode Section */
.barcode-header {
  margin-bottom: 16px;
}
.barcode-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #111827;
}
.barcode-subtext {
  font-size: 12px;
  color: #9ca3af;
  margin-top: 2px;
}
.barcode-box {
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 24px 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.barcode-bars {
  height: 32px;
  width: 100%;
  background: repeating-linear-gradient(
    to right,
    #111827 0,
    #111827 2px,
    transparent 2px,
    transparent 5px,
    #111827 5px,
    #111827 8px,
    transparent 8px,
    transparent 10px,
    #111827 10px,
    #111827 12px,
    transparent 12px,
    transparent 16px,
    #111827 16px,
    #111827 20px,
    transparent 20px,
    transparent 24px
  );
  margin-bottom: 12px;
  opacity: 0.9;
}
.barcode-text {
  font-size: 13px;
  color: #6b7280;
  letter-spacing: 1px;
}

/* Sidebar Info Box */
.sidebar-info-box {
  background: #f9fafb;
  border-radius: 8px;
  padding: 16px;
  font-size: 13px;
  line-height: 1.5;
  color: #6b7280;
}
.sidebar-info-box strong {
  color: #374151;
  font-weight: 600;
}

/* Column Toggle Menu */
.column-toggle-menu {
  position: absolute;
  top: 60px;
  right: 24px;
  background: white;
  border-radius: 16px;
  padding: 16px;
  width: 240px;
  z-index: 50;
  border: 1px solid #e5e7eb;
}
.column-menu-title {
  font-size: 14px;
  color: #6b7280;
  margin-bottom: 12px;
  font-weight: 500;
}
.column-menu-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s;
  margin-bottom: 4px;
}
.column-menu-item .table-checkbox {
  margin: 0;
}
.column-menu-item:last-child { margin-bottom: 0; }
.column-menu-item:hover { background: #f9fafb; }
.column-menu-item.is-active { background: #f3f4f6; }
.column-menu-item span {
  font-size: 14px;
  color: #111827;
  font-weight: 500;
}

/* ---------------------------------------------------- */
/* NEW HIGH-FIDELITY PRINT SETTINGS MODAL / DRAWER STYLES */
/* ---------------------------------------------------- */
.print-modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(17, 24, 39, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 200;
  backdrop-filter: blur(4px);
  padding: 40px;
}

.print-modal-card {
  background: white;
  width: 95vw;
  max-width: 1200px;
  height: 85vh;
  border-radius: 16px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  border: 1px solid #e5e7eb;
  animation: modalScaleUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes modalScaleUp {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}

.print-modal-header {
  padding: 20px 28px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  border-bottom: 1px solid #f3f4f6;
  background: white;
}

.header-left {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.modal-title {
  font-size: 20px;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.modal-subtitle {
  font-size: 13px;
  color: #6b7280;
  margin: 0;
}

.btn-close-icon {
  background: transparent;
  border: none;
  cursor: pointer;
  color: #9ca3af;
  padding: 4px;
  border-radius: 6px;
  transition: all 0.15s;
}
.btn-close-icon:hover {
  background: #f3f4f6;
  color: #4b5563;
}

.print-modal-body {
  display: flex;
  flex-direction: row;
  flex: 1;
  overflow: hidden;
  background: #f3f4f6;
}

/* Left side: Scrollable preview */
.print-preview-container {
  flex: 1;
  overflow-y: auto;
  padding: 40px;
  display: flex;
  justify-content: center;
  align-items: flex-start;
  box-sizing: border-box;
}

.preview-scrollable-content {
  width: 100%;
  max-width: 800px;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.preview-sheet {
  background: white;
  width: 210mm;
  min-height: 297mm;
  padding: 20mm;
  box-sizing: border-box;
  position: relative;
  text-align: left;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
}

.sheet-page {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.sheet-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  border-bottom: 1px solid #e5e7eb;
  padding-bottom: 20px;
  margin-bottom: 24px;
}

.sheet-logo-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.sheet-logo-circle {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: #f3f4f6;
  color: #0f4c81;
  font-weight: 800;
  font-size: 22px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid #0f4c81;
}

.logo-text-m {
  line-height: 1;
  font-style: italic;
}

.sheet-title-group {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.sheet-doc-title {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 0;
  letter-spacing: -0.01em;
}

.sheet-doc-title-placeholder {
  font-size: 18px;
  font-weight: 700;
  color: #9ca3af;
  margin: 0;
}

.sheet-company-name {
  font-size: 12px;
  color: #6b7280;
  font-weight: 500;
}

.sheet-doc-number-group {
  text-align: right;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
}

.sheet-doc-number {
  font-size: 12px;
  font-weight: 600;
  color: #4b5563;
  letter-spacing: 0.5px;
}

.sheet-barcode-bars {
  height: 24px;
  width: 140px;
  background: repeating-linear-gradient(
    to right,
    #111827 0,
    #111827 2px,
    transparent 2px,
    transparent 4px,
    #111827 4px,
    #111827 6px,
    transparent 6px,
    transparent 8px,
    #111827 8px,
    #111827 10px,
    transparent 10px,
    transparent 12px
  );
  opacity: 0.95;
}

/* Meta Grid In Printable */
.sheet-meta-card {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 16px 24px;
  margin-bottom: 24px;
}

.meta-card-col {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.meta-card-value {
  font-size: 14px;
  font-weight: 700;
  color: #374151;
}

.meta-card-label {
  font-size: 11px;
  color: #9ca3af;
  font-weight: 500;
}

/* Optional fields block */
.sheet-optional-info {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-bottom: 24px;
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 12px 16px;
}

.optional-info-item {
  font-size: 13px;
}

.optional-info-item.span-full {
  grid-column: span 2;
  border-top: 1px solid #e5e7eb;
  padding-top: 8px;
  margin-top: 4px;
}

.optional-label {
  font-weight: 600;
  color: #4b5563;
  margin-right: 6px;
}

.optional-value {
  color: #111827;
}

/* Printable products section */
.sheet-products-section {
  flex: 1;
  margin-bottom: 40px;
}

.sheet-products-table {
  width: 100%;
  border-collapse: collapse;
}

.sheet-products-table th {
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  padding: 10px 14px;
  font-size: 11px;
  font-weight: 700;
  color: #4b5563;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  text-align: left;
}

.sheet-products-table td {
  border: 1px solid #e5e7eb;
  padding: 12px 14px;
  font-size: 13px;
  color: #374151;
}

.sheet-summary-card {
  border: 1.5px solid #111827;
  border-radius: 12px;
  padding: 24px;
  background: white;
}

.summary-card-title {
  font-size: 14px;
  font-weight: 700;
  color: #111827;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 16px;
  border-bottom: 1.5px solid #111827;
  padding-bottom: 8px;
}

.summary-card-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

.summary-card-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.summary-label {
  font-size: 11px;
  color: #6b7280;
  font-weight: 500;
}

.summary-value {
  font-size: 20px;
  font-weight: 800;
  color: #111827;
}

.sheet-signatures {
  display: flex;
  justify-content: space-between;
  margin-top: auto;
  padding-top: 40px;
}

.signature-line {
  width: 220px;
  border-top: 1.5px solid #374151;
  padding-top: 8px;
  text-align: center;
}

.sig-label {
  font-size: 11px;
  font-weight: 600;
  color: #4b5563;
}

.sheet-page-badge {
  position: absolute;
  bottom: 24px;
  right: 24px;
  background: #f3f4f6;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 600;
  color: #4b5563;
}

/* Right side Settings Menu */
.print-sidebar-menu {
  width: 320px;
  background: white;
  border-left: 1px solid #e5e7eb;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  box-sizing: border-box;
  overflow-y: auto;
}

.setting-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 12px;
  border-bottom: 1px solid #f3f4f6;
}

.setting-title {
  font-size: 13px;
  font-weight: 600;
  color: #374151;
}

/* Custom switch toggle */
.switch {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
}
.switch input {
  opacity: 0;
  width: 0;
  height: 0;
}
.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #e5e7eb;
  transition: .2s;
  border-radius: 24px;
}
.slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: .2s;
  border-radius: 50%;
}
input:checked + .slider {
  background-color: #0f4c81;
}
input:checked + .slider:before {
  transform: translateX(20px);
}

/* Radio layout option group */
.layout-selector-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 12px;
}

.section-label {
  font-size: 13px;
  font-weight: 600;
  color: #374151;
  margin-bottom: 4px;
}

.radio-option {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  cursor: pointer;
  user-select: none;
  padding: 8px 0;
}

.radio-option input {
  position: absolute;
  opacity: 0;
  cursor: pointer;
  height: 0;
  width: 0;
}

.radio-circle {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  border: 1.5px solid #d1d5db;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: 2px;
  flex-shrink: 0;
  transition: all 0.15s;
}

.radio-option:hover input ~ .radio-circle {
  border-color: #9ca3af;
}

.radio-option input:checked ~ .radio-circle {
  border-color: #0f4c81;
}

.radio-circle::after {
  content: "";
  display: none;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #0f4c81;
}

.radio-option input:checked ~ .radio-circle::after {
  display: block;
}

.radio-text {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.radio-title {
  font-size: 13px;
  font-weight: 600;
  color: #374151;
}

.radio-desc {
  font-size: 11px;
  color: #6b7280;
  line-height: 1.4;
}

/* Modal Footer */
.print-modal-footer {
  padding: 16px 28px;
  background: white;
  border-top: 1px solid #f3f4f6;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.btn-close {
  height: 40px;
  padding: 0 16px;
  background: white;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  color: #374151;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.15s;
}
.btn-close:hover {
  background: #f9fafb;
  border-color: #c5c7cb;
}

.footer-right-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.btn-pdf {
  height: 40px;
  padding: 0 20px;
  background: white;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  color: #374151;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.15s;
}
.btn-pdf:hover {
  background: #f9fafb;
  border-color: #c5c7cb;
}

.btn-print {
  height: 40px;
  padding: 0 24px;
  background: #0f4c81;
  border: none;
  border-radius: 8px;
  color: white;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.15s;
}
.btn-print:hover {
  background: #0c3e69;
}

/* Print Stylesheet Overrides */
@media print {
  body * {
    visibility: hidden;
  }
  .print-modal-overlay,
  .print-modal-overlay * {
    visibility: visible;
  }
  .print-modal-overlay {
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    padding: 0;
    background: none;
    backdrop-filter: none;
  }
  .print-modal-card {
    border: none;
    box-shadow: none;
    height: auto;
    width: auto;
  }
  .print-modal-header,
  .print-sidebar-menu,
  .print-modal-footer,
  .btn-close-icon {
    display: none !important;
  }
  .print-preview-container {
    padding: 0;
    overflow: visible;
  }
  .preview-sheet {
    border: none;
    box-shadow: none;
    padding: 0;
    margin: 0;
    width: 210mm;
    min-height: 297mm;
  }
}
</style>
