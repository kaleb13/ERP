<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { 
  Monitor, ChevronRight, Info, FileText, ChevronDown, Plus, Trash2,
  Download, Columns, Undo2, Printer, ScanLine, ZoomIn, ZoomOut, MoreVertical, Check, X, ArrowUpRight
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
const isReservationExpanded = ref(true);
const isMoreInfoExpanded = ref(true);
const isAttachmentsExpanded = ref(false);

const reservedFor = ref('');
const sourceLocation = ref('');
const reservationType = ref('');
const referenceDocumentType = ref('');
const selectedDocument = ref('');
const documentDate = ref(new Date().toISOString().substring(0, 10));

// More Info fields
const documentNumberInput = ref('SR-2026-00012');
const postingDate = ref(new Date().toISOString().substring(0, 10));
const createdBy = ref('Marta Tadesse');
const approvedBy = ref('-');
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
  showWarehouseLocation: true,
  showCustomerName: true,
  showRemark: true,
  productDisplayMode: 'detailed' // 'detailed' or 'summary'
});

const columns = ref({
  product: true,
  batch: true,
  uom: true,
  available: true,
  reserved: true
});

const docNumber = computed(() => {
  return documentNumberInput.value || 'SR-2026-00012';
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
  const rows = reservationRows.value.length > 0 ? reservationRows.value : [
    { id: 1, product: 'Bluetooth Speaker (SPK-3005)', batch: 'BCH-1001', uom: 'Pcs', available: '150', reserved: '15' },
    { id: 2, product: 'Notebook A5 (STN-4003)', batch: 'BCH-1001', uom: 'Pcs', available: '200', reserved: '10' }
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
  printDocumentName.value = 'Stock Reservation Voucher';
  showPrintPreview.value = true;
};

const executePrint = () => {
  window.print();
};

const downloadPDF = () => {
  alert("Downloading Stock Reservation as PDF...");
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
  if (referenceDocumentType.value === 'mr') return 'Material Request';
  return 'Select Type';
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
  } else if (referenceDocumentType.value === 'mr') {
    return [
      { value: 'MR-2026-001', label: 'MR-2026-001 (Production Line B)' },
      { value: 'MR-2026-002', label: 'MR-2026-002 (General Store)' }
    ];
  }
  return [];
});

const reservationRows = ref<{ id: number; selected: boolean; product: string; batch: string; uom: string; available: string; reserved: string }[]>([]);

watch(selectedDocument, (newVal) => {
  if (newVal) {
    if (newVal.startsWith('PO')) {
      reservationRows.value = [
        { id: Date.now() + 1, selected: false, product: 'Notebook A5 (STN-4003)', batch: 'BCH-1001', uom: 'Pcs', available: '200', reserved: '10' },
        { id: Date.now() + 2, selected: false, product: 'Printer Ink (CY-120)', batch: 'BCH-1002', uom: 'Box', available: '45', reserved: '2' }
      ];
    } else if (newVal.startsWith('SO')) {
      reservationRows.value = [
        { id: Date.now() + 3, selected: false, product: 'Office Chair (ERG-202)', batch: 'BCH-2001', uom: 'Pcs', available: '80', reserved: '5' }
      ];
    } else if (newVal.startsWith('MR')) {
      reservationRows.value = [
        { id: Date.now() + 4, selected: false, product: 'Bluetooth Speaker (SPK-3005)', batch: 'BCH-2005', uom: 'Pcs', available: '150', reserved: '15' }
      ];
    }
  } else {
    reservationRows.value = [];
  }
});

const totalProducts = computed(() => reservationRows.value.length || 2);
const totalQuantity = computed(() => {
  if (reservationRows.value.length === 0) return 25;
  return reservationRows.value.reduce((acc, row) => acc + Number(row.reserved || 0), 0);
});
const batchCount = computed(() => {
  if (reservationRows.value.length === 0) return 1;
  return new Set(reservationRows.value.map(row => row.batch).filter(b => b)).size;
});

const hasSelectedRows = computed(() => reservationRows.value.some(row => row.selected));

const isAllSelected = computed(() => {
  return reservationRows.value.length > 0 && reservationRows.value.every(row => row.selected);
});

const toggleAll = (e: Event) => {
  const checked = (e.target as HTMLInputElement).checked;
  reservationRows.value.forEach(row => {
    row.selected = checked;
  });
};

const addRow = () => {
  reservationRows.value.push({
    id: Date.now(),
    selected: false,
    product: '',
    batch: '',
    uom: 'Pcs',
    available: '100',
    reserved: ''
  });
};

const deleteSelectedRows = () => {
  reservationRows.value = reservationRows.value.filter(row => !row.selected);
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
    reservedFor: reservedFor.value,
    sourceLocation: sourceLocation.value,
    reservationType: reservationType.value,
    referenceDocumentType: referenceDocumentType.value,
    selectedDocument: selectedDocument.value,
    documentDate: documentDate.value,
    documentNumberInput: documentNumberInput.value,
    postingDate: postingDate.value,
    externalReference: externalReference.value,
    canBeReferenced: canBeReferenced.value,
    remark: remark.value,
    reservationRows: JSON.parse(JSON.stringify(reservationRows.value))
  };
  isSaved.value = true;
  documentState.value = 'draft';
  closeDropdowns();
};

const handleClearChange = () => {
  if (!savedDraftData.value) return;
  reservedFor.value = savedDraftData.value.reservedFor;
  sourceLocation.value = savedDraftData.value.sourceLocation;
  reservationType.value = savedDraftData.value.reservationType;
  referenceDocumentType.value = savedDraftData.value.referenceDocumentType;
  selectedDocument.value = savedDraftData.value.selectedDocument;
  documentDate.value = savedDraftData.value.documentDate;
  documentNumberInput.value = savedDraftData.value.documentNumberInput;
  postingDate.value = savedDraftData.value.postingDate;
  externalReference.value = savedDraftData.value.externalReference;
  canBeReferenced.value = savedDraftData.value.canBeReferenced;
  remark.value = savedDraftData.value.remark;
  reservationRows.value = JSON.parse(JSON.stringify(savedDraftData.value.reservationRows));
  documentState.value = 'draft';
  closeDropdowns();
};

const handleClearForm = () => {
  reservedFor.value = '';
  sourceLocation.value = '';
  reservationType.value = '';
  referenceDocumentType.value = '';
  selectedDocument.value = '';
  documentDate.value = new Date().toISOString().substring(0, 10);
  documentNumberInput.value = 'SR-2026-00012';
  postingDate.value = new Date().toISOString().substring(0, 10);
  externalReference.value = '';
  canBeReferenced.value = true;
  remark.value = '';
  reservationRows.value = [];
  documentState.value = 'new_unsaved';
  closeDropdowns();
};

const handleApprove = () => {
  if (!sourceLocation.value || !reservedFor.value || reservationRows.value.length === 0) {
    alert("Please complete the basic information and add reservation items before approval.");
    return;
  }
  documentState.value = 'approved';
  approvedBy.value = 'Marta Tadesse';
  closeDropdowns();
};

// Form state detector
const hasChangesFromDraft = computed(() => {
  if (!isSaved.value || !savedDraftData.value) return false;
  
  const simpleChanged = 
    reservedFor.value !== savedDraftData.value.reservedFor ||
    sourceLocation.value !== savedDraftData.value.sourceLocation ||
    reservationType.value !== savedDraftData.value.reservationType ||
    referenceDocumentType.value !== savedDraftData.value.referenceDocumentType ||
    selectedDocument.value !== savedDraftData.value.selectedDocument ||
    documentDate.value !== savedDraftData.value.documentDate ||
    documentNumberInput.value !== savedDraftData.value.documentNumberInput ||
    postingDate.value !== savedDraftData.value.postingDate ||
    externalReference.value !== savedDraftData.value.externalReference ||
    canBeReferenced.value !== savedDraftData.value.canBeReferenced ||
    remark.value !== savedDraftData.value.remark;
    
  if (simpleChanged) return true;
  
  // Check rows
  if (reservationRows.value.length !== savedDraftData.value.reservationRows.length) return true;
  for (let i = 0; i < reservationRows.value.length; i++) {
    const rCurrent = reservationRows.value[i];
    const rSaved = savedDraftData.value.reservationRows[i];
    if (
      rCurrent.product !== rSaved.product ||
      rCurrent.batch !== rSaved.batch ||
      rCurrent.uom !== rSaved.uom ||
      rCurrent.reserved !== rSaved.reserved
    ) {
      return true;
    }
  }
  
  return false;
});

watch(hasChangesFromDraft, (changed) => {
  if (documentState.value === 'approved') return;
  if (changed && documentState.value === 'draft') {
    documentState.value = 'draft_modified';
  } else if (!changed && documentState.value === 'draft_modified') {
    documentState.value = 'draft';
  }
});
</script>

<template>
  <div class="reservation-create-page">
    
    <!-- Header with Breadcrumbs and Actions -->
    <div class="page-top-bar">
      <div class="breadcrumbs">
        <router-link to="/dashboard" class="breadcrumb-link">
          <Monitor :size="16" />
        </router-link>
        <ChevronRight :size="12" class="breadcrumb-separator" />
        <router-link to="/stock-reservation" class="breadcrumb-link">Stock Reservation</router-link>
        <ChevronRight :size="12" class="breadcrumb-separator" />
        <span class="breadcrumb-active">Create Stock Reservation</span>
        
        <!-- Status Badges -->
        <span v-if="documentState === 'new_unsaved'" class="status-badge badge-notsaved">Not Saved</span>
        <span v-else-if="documentState === 'draft'" class="status-badge badge-draft">Draft</span>
        <span v-else-if="documentState === 'draft_modified'" class="status-badge badge-notsaved">Not Saved</span>
        <span v-else-if="documentState === 'approved'" class="status-badge badge-approved">Approved</span>
      </div>
      
      <!-- Action Buttons -->
      <div class="top-bar-actions">
        
        <!-- Revert edits back to saved draft state -->
        <button 
          v-if="documentState === 'draft_modified'" 
          @click="handleClearChange" 
          class="btn-secondary"
        >
          <Undo2 :size="16" /> Clear Change
        </button>
        
        <!-- Three Dot Menu -->
        <div class="three-dot-menu-wrapper" v-if="documentState !== 'approved'">
          <button 
            @click.stop="toggleDropdown('actions')" 
            :class="['btn-three-dot', { 'is-active': openDropdown === 'actions' }]"
          >
            <MoreVertical :size="18" />
          </button>
          
          <div class="three-dot-dropdown" v-if="openDropdown === 'actions'">
            <button @click="handleSaveDraft" class="dropdown-menu-item">
              <Check :size="14" /> Save as draft
            </button>
            <button @click="handleClearForm" class="dropdown-menu-item">
              <X :size="14" /> Clear form
            </button>
          </div>
        </div>
        
        <!-- Approve button -->
        <button 
          v-if="documentState !== 'approved'" 
          @click="handleApprove" 
          class="btn-approve-primary"
        >
          Approve
        </button>
        <button 
          v-else 
          class="btn-approved-disabled" 
          disabled
        >
          Approved
        </button>
        
      </div>
    </div>
    
    <!-- Tab Section -->
    <div class="tabs-wrapper">
      <BaseTabs :tabs="tabs" v-model="activeTab" />
    </div>
    
    <!-- Info Banner for Draft Statuses -->
    <div v-if="documentState === 'draft' || documentState === 'draft_modified'" class="alert-banner">
      <Info :size="18" class="text-amber-600 mr-2 flex-shrink-0" />
      <span class="text-amber-800 text-sm">
        This stock reservation has been saved as a draft and is <strong>not yet authorized for use</strong>. Approve the voucher to allocate the inventory and make it available for shipping/production.
      </span>
    </div>
    
    <!-- Main content grid -->
    <div class="main-layout-grid">
      
      <!-- Left Form Section -->
      <div class="form-content-area">
        
        <!-- Card 1: Basic Information -->
        <div class="form-card" v-show="activeTab === 'basic'">
          <div class="card-header" @click="isReservationExpanded = !isReservationExpanded">
            <span class="card-title">Basic Information</span>
            <ChevronDown :class="['chevron-icon', { rotate: !isReservationExpanded }]" :size="18" />
          </div>
          
          <div class="card-body" v-show="isReservationExpanded">
            <div class="form-grid-three">
              
              <!-- Warehouse / Location -->
              <div class="form-field-col">
                <label class="field-label">Warehouse / Location <span class="required">*</span></label>
                <select 
                  v-model="sourceLocation" 
                  class="field-input-select"
                  :disabled="documentState === 'approved'"
                >
                  <option value="" disabled>Select Location</option>
                  <option value="Main Warehouse">Main Warehouse</option>
                  <option value="Warehouse - 22">Warehouse - 22</option>
                  <option value="Store - A">Store - A</option>
                </select>
              </div>

              <!-- Customer / Reserved For -->
              <div class="form-field-col">
                <label class="field-label">Reserved For / Customer <span class="required">*</span></label>
                <select 
                  v-model="reservedFor" 
                  class="field-input-select"
                  :disabled="documentState === 'approved'"
                >
                  <option value="" disabled>Select Customer</option>
                  <option value="Bekele Alemu">Bekele Alemu</option>
                  <option value="Qelem Media Technology">Qelem Media Technology</option>
                  <option value="Tech Supplier Inc">Tech Supplier Inc</option>
                  <option value="Client A">Client A</option>
                  <option value="Client B">Client B</option>
                </select>
              </div>

              <!-- Reservation Type -->
              <div class="form-field-col">
                <label class="field-label">Reservation Type <span class="required">*</span></label>
                <select 
                  v-model="reservationType" 
                  class="field-input-select"
                  :disabled="documentState === 'approved'"
                >
                  <option value="" disabled>Select Type</option>
                  <option value="Sales Order Reservation">Sales Order Reservation</option>
                  <option value="Production Reservation">Production Reservation</option>
                  <option value="Transfer Reservation">Transfer Reservation</option>
                  <option value="General Reservation">General Reservation</option>
                </select>
              </div>

              <!-- Document Date -->
              <div class="form-field-col">
                <label class="field-label">Document Date</label>
                <input 
                  type="date" 
                  v-model="documentDate" 
                  class="field-input-text"
                  :disabled="documentState === 'approved'"
                />
              </div>

              <!-- Reference Document Type -->
              <div class="form-field-col">
                <label class="field-label">Reference Document Type</label>
                <div class="custom-select-wrapper">
                  <button 
                    type="button" 
                    @click.stop="documentState !== 'approved' && toggleDropdown('refType')" 
                    class="custom-select-trigger"
                    :disabled="documentState === 'approved'"
                  >
                    <span>{{ getTriggerLabel }}</span>
                    <ChevronDown :size="16" class="text-gray-400" />
                  </button>
                  <div class="custom-select-options" v-if="openDropdown === 'refType'">
                    <div @click="referenceDocumentType = 'po'; selectedDocument = ''; closeDropdowns()" class="custom-option-item">Purchase Document</div>
                    <div @click="referenceDocumentType = 'so'; selectedDocument = ''; closeDropdowns()" class="custom-option-item">Sales Document</div>
                    <div @click="referenceDocumentType = 'mr'; selectedDocument = ''; closeDropdowns()" class="custom-option-item">Material Request</div>
                  </div>
                </div>
              </div>

              <!-- Get Items From -->
              <div class="form-field-col" v-if="referenceDocumentType">
                <label class="field-label">Get Items From</label>
                <div class="custom-select-wrapper">
                  <button 
                    type="button" 
                    @click.stop="documentState !== 'approved' && toggleDropdown('getItems')" 
                    class="custom-select-trigger"
                    :disabled="documentState === 'approved'"
                  >
                    <span>{{ getDocumentLabel }}</span>
                    <ChevronDown :size="16" class="text-gray-400" />
                  </button>
                  <div class="custom-select-options" v-if="openDropdown === 'getItems'">
                    <div 
                      v-for="opt in documentOptions" 
                      :key="opt.value" 
                      @click="selectedDocument = opt.value; closeDropdowns()" 
                      class="custom-option-item"
                    >
                      {{ opt.label }}
                    </div>
                  </div>
                </div>
                <span class="field-helper-text">Select the source document containing the items you wish to reserve.</span>
              </div>

            </div>
          </div>
        </div>

        <!-- Card 2: More Information -->
        <div class="form-card" v-show="activeTab === 'more'">
          <div class="card-header" @click="isMoreInfoExpanded = !isMoreInfoExpanded">
            <span class="card-title">More Information</span>
            <ChevronDown :class="['chevron-icon', { rotate: !isMoreInfoExpanded }]" :size="18" />
          </div>
          
          <div class="card-body" v-show="isMoreInfoExpanded">
            <div class="form-grid-three">
              
              <!-- Document Number -->
              <div class="form-field-col">
                <label class="field-label">Document Number</label>
                <input 
                  type="text" 
                  v-model="documentNumberInput" 
                  class="field-input-text bg-gray-50 text-gray-500" 
                  disabled 
                />
              </div>

              <!-- Posting Date -->
              <div class="form-field-col">
                <label class="field-label">Posting Date</label>
                <input 
                  type="date" 
                  v-model="postingDate" 
                  class="field-input-text"
                  :disabled="documentState === 'approved'"
                />
              </div>

              <!-- Created By -->
              <div class="form-field-col">
                <label class="field-label">Created By</label>
                <input 
                  type="text" 
                  v-model="createdBy" 
                  class="field-input-text bg-gray-50 text-gray-500" 
                  disabled 
                />
              </div>

              <!-- Approved By -->
              <div class="form-field-col">
                <label class="field-label">Approved By</label>
                <input 
                  type="text" 
                  v-model="approvedBy" 
                  class="field-input-text bg-gray-50 text-gray-500" 
                  disabled 
                />
              </div>

              <!-- External Reference No -->
              <div class="form-field-col">
                <label class="field-label">External Reference No.</label>
                <input 
                  type="text" 
                  v-model="externalReference" 
                  placeholder="e.g. SO-REF-8902" 
                  class="field-input-text"
                  :disabled="documentState === 'approved'"
                />
              </div>

              <!-- Can Be Referenced -->
              <div class="form-field-col" style="justify-content: center;">
                <label class="checkbox-field-label">
                  <input 
                    type="checkbox" 
                    v-model="canBeReferenced" 
                    class="checkbox-input"
                    :disabled="documentState === 'approved'"
                  />
                  <span>Can Act as Reference</span>
                </label>
              </div>

              <!-- Remarks -->
              <div class="form-field-col span-full">
                <label class="field-label">Remarks</label>
                <textarea 
                  v-model="remark" 
                  rows="3" 
                  placeholder="Write internal notes about this stock reservation..." 
                  class="field-input-textarea"
                  :disabled="documentState === 'approved'"
                ></textarea>
              </div>

            </div>
          </div>
        </div>

        <!-- Product Table Block -->
        <div class="products-table-card">
          
          <div class="table-card-header">
            <h3 class="table-card-title">Reserved Products</h3>
            <div class="table-actions" v-if="documentState !== 'approved'">
              <button @click="deleteSelectedRows" class="btn-table-action text-red-600" :disabled="!hasSelectedRows">
                <Trash2 :size="16" /> Delete
              </button>
              <button @click="addRow" class="btn-table-action text-blue-600">
                <Plus :size="16" /> Add Product
              </button>
            </div>
          </div>
          
          <div class="table-responsive">
            <table class="products-editor-table">
              <thead>
                <tr>
                  <th width="40" class="text-center" v-if="documentState !== 'approved'">
                    <input type="checkbox" :checked="isAllSelected" @change="toggleAll" class="table-checkbox" />
                  </th>
                  <th width="60">No.</th>
                  <th>Product <span class="required">*</span></th>
                  <th width="140">Batch No</th>
                  <th width="100">UOM</th>
                  <th width="120" class="text-right">Available Qty</th>
                  <th width="140" class="text-right">Reserved Qty <span class="required">*</span></th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, index) in reservationRows" :key="row.id">
                  
                  <td class="text-center" v-if="documentState !== 'approved'">
                    <input type="checkbox" v-model="row.selected" class="table-checkbox" />
                  </td>
                  
                  <td>{{ index + 1 }}</td>
                  
                  <!-- Product dropdown selector -->
                  <td class="relative">
                    <div class="product-input-wrapper" v-if="documentState !== 'approved'">
                      <input 
                        type="text" 
                        v-model="row.product" 
                        placeholder="Search/Select product..." 
                        @focus="activeProductDropdownId = row.id"
                        @blur="closeProductDropdown(row.id)"
                        class="table-cell-input"
                      />
                      <div class="product-dropdown-list" v-if="activeProductDropdownId === row.id">
                        <div @mousedown="selectProduct(row, 'Notebook A5 (STN-4003)')" class="product-option">Notebook A5 (STN-4003)</div>
                        <div @mousedown="selectProduct(row, 'Printer Ink (CY-120)')" class="product-option">Printer Ink (CY-120)</div>
                        <div @mousedown="selectProduct(row, 'Office Chair (ERG-202)')" class="product-option">Office Chair (ERG-202)</div>
                        <div @mousedown="selectProduct(row, 'Bluetooth Speaker (SPK-3005)')" class="product-option">Bluetooth Speaker (SPK-3005)</div>
                        <div @mousedown="selectProduct(row, 'Wireless Mouse (MOU-9001)')" class="product-option">Wireless Mouse (MOU-9001)</div>
                      </div>
                    </div>
                    <span v-else class="text-gray-800 font-medium">{{ row.product || 'Unnamed Product' }}</span>
                  </td>
                  
                  <!-- Batch -->
                  <td>
                    <input 
                      v-if="documentState !== 'approved'"
                      type="text" 
                      v-model="row.batch" 
                      placeholder="e.g. BCH-1001" 
                      class="table-cell-input"
                    />
                    <span v-else class="text-gray-600">{{ row.batch || '-' }}</span>
                  </td>
                  
                  <!-- UOM -->
                  <td>
                    <select 
                      v-if="documentState !== 'approved'"
                      v-model="row.uom" 
                      class="table-cell-select"
                    >
                      <option value="Pcs">Pcs</option>
                      <option value="Box">Box</option>
                      <option value="Kg">Kg</option>
                    </select>
                    <span v-else class="text-gray-600">{{ row.uom || 'Pcs' }}</span>
                  </td>
                  
                  <!-- Available Qty -->
                  <td class="text-right text-gray-500 font-medium">
                    {{ row.available }}
                  </td>
                  
                  <!-- Reserved Qty -->
                  <td>
                    <input 
                      v-if="documentState !== 'approved'"
                      type="number" 
                      v-model="row.reserved" 
                      placeholder="0" 
                      class="table-cell-input text-right font-semibold"
                    />
                    <span v-else class="text-gray-800 font-semibold block text-right">{{ row.reserved }}</span>
                  </td>
                  
                </tr>
                
                <tr v-if="reservationRows.length === 0">
                  <td colspan="7" class="empty-table-placeholder">
                    No products added yet. Click 'Add Product' or select a reference document to populate reservation rows.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

      </div>
      
      <!-- Right Sidebar Summary Panel (appears after save as draft or approved) -->
      <aside class="sidebar-summary-panel" v-if="documentState !== 'new_unsaved'">
        <div class="summary-card">
          
          <div class="summary-header">
            <span class="summary-doc-type">Stock Reservation</span>
            <button class="btn-print-link" @click="handlePrint">
              Print <Printer :size="15" />
            </button>
          </div>
          
          <div class="summary-main-info">
            <span class="summary-location-label">To: {{ reservedFor || 'Customer / Client' }}</span>
            <h4 class="summary-location-title">{{ sourceLocation || 'Unassigned Location' }}</h4>
          </div>
          
          <div class="summary-divider"></div>
          
          <!-- Key Indicators -->
          <div class="summary-indicator-row">
            <span class="indicator-label">Source Warehouse</span>
            <span class="indicator-value">{{ sourceLocation || '-' }}</span>
          </div>
          <div class="summary-indicator-row">
            <span class="indicator-label">Total Unique Products</span>
            <span class="indicator-value font-bold">{{ totalProducts }}</span>
          </div>
          <div class="summary-indicator-row">
            <span class="indicator-label">Total Quantity</span>
            <span class="indicator-value font-bold">{{ totalQuantity }}</span>
          </div>
          <div class="summary-indicator-row">
            <span class="indicator-label">Batch Count</span>
            <span class="indicator-value">{{ batchCount }}</span>
          </div>
          
          <div class="summary-divider"></div>
          
          <!-- State Badge -->
          <div class="summary-status-section">
            <span class="status-label">Status</span>
            <span v-if="documentState === 'approved'" class="status-badge badge-approved">Approved</span>
            <span v-else class="status-badge badge-draft">Draft</span>
          </div>
          
          <div class="summary-divider"></div>
          
          <!-- Barcode Generation -->
          <div class="summary-barcode-section">
            <span class="barcode-label">Barcode</span>
            <div class="barcode-box">
              <div class="barcode-lines">
                <!-- Styled line representation of a barcode -->
                <span class="bar thickness-1"></span>
                <span class="bar thickness-2"></span>
                <span class="bar thickness-1"></span>
                <span class="bar thickness-3"></span>
                <span class="bar thickness-1"></span>
                <span class="bar thickness-2"></span>
                <span class="bar thickness-4"></span>
                <span class="bar thickness-1"></span>
                <span class="bar thickness-2"></span>
                <span class="bar thickness-3"></span>
                <span class="bar thickness-1"></span>
                <span class="bar thickness-2"></span>
                <span class="bar thickness-1"></span>
              </div>
              <span class="barcode-text">{{ docNumber }}</span>
            </div>
            <span class="scan-helper text-center block text-gray-400 mt-2">Scan at Gate / Warehouse</span>
          </div>

        </div>
      </aside>
      
    </div>
    
    <!-- HIGH FIDELITY PRINT SETTINGS MODAL/DRAWER OVERLAY -->
    <div v-if="showPrintPreview" class="print-preview-overlay" @click.self="showPrintPreview = false">
      
      <div class="print-preview-card">
        
        <!-- Modal Header -->
        <header class="print-modal-header">
          <div class="header-left">
            <h2>Print Settings</h2>
            <p>Configure Document layout and Visibility</p>
          </div>
          <button class="btn-close-circle" @click="showPrintPreview = false">
            <X :size="20" />
          </button>
        </header>
        
        <!-- Modal Split Body -->
        <div class="print-modal-body">
          
          <!-- Left: Scrollable Printable Preview sheet -->
          <div class="print-preview-pane">
            <div class="zoom-controls">
              <button class="btn-zoom" @click="zoomOut" title="Zoom Out"><ZoomOut :size="16" /></button>
              <span class="zoom-text">{{ Math.round(zoomLevel * 100) }}%</span>
              <button class="btn-zoom" @click="zoomIn" title="Zoom In"><ZoomIn :size="16" /></button>
            </div>
            
            <div class="sheets-scroll-container">
              
              <!-- Printable A4 page replica -->
              <div 
                class="a4-sheet-wrapper"
                :style="{ transform: `scale(${zoomLevel})` }"
              >
                <!-- Rendered print page -->
                <div 
                  v-for="page in printPages" 
                  :key="page.pageNumber" 
                  class="a4-page-sheet"
                >
                  
                  <!-- Page Header -->
                  <div class="sheet-header">
                    
                    <!-- Company Info -->
                    <div class="company-branding" v-if="printSettings.showCompanyLogo">
                      <div class="company-logo-preview">
                        <span class="logo-text-short">H</span>
                      </div>
                      <div class="company-details">
                        <h4 class="company-name">Haleta ERP</h4>
                        <p class="company-sub">Inventory Systems</p>
                      </div>
                    </div>
                    <div v-else class="company-branding-placeholder"></div>
                    
                    <!-- Doc ID & Barcode -->
                    <div class="sheet-doc-identity">
                      <div class="sheet-barcode-box">
                        <div class="sheet-barcode-lines">
                          <span class="bar thickness-1"></span>
                          <span class="bar thickness-2"></span>
                          <span class="bar thickness-1"></span>
                          <span class="bar thickness-3"></span>
                          <span class="bar thickness-1"></span>
                          <span class="bar thickness-2"></span>
                          <span class="bar thickness-4"></span>
                          <span class="bar thickness-1"></span>
                          <span class="bar thickness-2"></span>
                          <span class="bar thickness-3"></span>
                        </div>
                        <span class="sheet-barcode-num">{{ docNumber }}</span>
                      </div>
                    </div>
                    
                  </div>
                  
                  <!-- Document title -->
                  <div class="sheet-doc-title-block" v-if="printSettings.showDocumentName">
                    <h1 class="sheet-doc-title">Stock Reservation Voucher</h1>
                    <p class="sheet-doc-subtitle">Official Inventory Allocation Record</p>
                  </div>
                  
                  <!-- Meta Details Grid -->
                  <div class="sheet-meta-card">
                    <div class="meta-card-col" v-if="printSettings.showWarehouseLocation">
                      <span class="meta-card-value">{{ sourceLocation || 'Main Warehouse' }}</span>
                      <span class="meta-card-label">Warehouse Location</span>
                    </div>
                    <div class="meta-card-col" v-if="printSettings.showCustomerName">
                      <span class="meta-card-value">{{ reservedFor || 'General Customer' }}</span>
                      <span class="meta-card-label">Reserved For</span>
                    </div>
                    <div class="meta-card-col">
                      <span class="meta-card-value">{{ reservationType || 'General Reservation' }}</span>
                      <span class="meta-card-label">Reservation Type</span>
                    </div>
                    <div class="meta-card-col">
                      <span class="meta-card-value">{{ documentDate }}</span>
                      <span class="meta-card-label">Document Date</span>
                    </div>
                  </div>

                  <!-- Optional Info Rows: Remarks -->
                  <div v-if="printSettings.showRemark && remark" class="sheet-optional-info">
                    <div class="optional-info-item span-full">
                      <span class="optional-label">Remarks / Instructions:</span>
                      <span class="optional-value">{{ remark }}</span>
                    </div>
                  </div>

                  <!-- Product List / Table Section -->
                  <div class="sheet-products-section">
                    
                    <!-- Summary Mode -->
                    <div v-if="printSettings.productDisplayMode === 'summary'" class="sheet-summary-card">
                      <div class="summary-card-title">Reservation Summary</div>
                      <div class="summary-card-grid">
                        <div class="summary-card-item">
                          <span class="summary-label">Total Unique Products</span>
                          <span class="summary-value">{{ reservationRows.length || 2 }}</span>
                        </div>
                        <div class="summary-card-item">
                          <span class="summary-label">Total Quantity</span>
                          <span class="summary-value">{{ totalQuantity || 25 }}</span>
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
                        <template v-if="reservationRows.length > 0">
                          <tr v-for="(row, idx) in reservationRows" :key="row.id">
                            <td>{{ idx + 1 }}</td>
                            <td class="font-medium">{{ row.product || 'Unnamed Product' }}</td>
                            <td>{{ row.batch || '-' }}</td>
                            <td>{{ row.uom || '-' }}</td>
                            <td class="text-right font-medium">{{ row.reserved || '0' }}</td>
                          </tr>
                        </template>
                        <template v-else>
                          <tr>
                            <td>1</td>
                            <td class="font-medium">Bluetooth Speaker (SPK-3005)</td>
                            <td>BCH-1001</td>
                            <td>Pcs</td>
                            <td class="text-right font-medium">15</td>
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
                      <span class="sig-label">Warehouse Officer</span>
                    </div>
                    <div class="signature-line">
                      <span class="sig-label">Approving Manager</span>
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

            <!-- Warehouse Location Toggle -->
            <div class="setting-row">
              <span class="setting-title">Warehouse Location</span>
              <label class="switch">
                <input type="checkbox" v-model="printSettings.showWarehouseLocation" />
                <span class="slider round"></span>
              </label>
            </div>

            <!-- Customer Name Toggle -->
            <div class="setting-row">
              <span class="setting-title">Customer Name</span>
              <label class="switch">
                <input type="checkbox" v-model="printSettings.showCustomerName" />
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
.reservation-create-page {
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
  background: #0284c7;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  color: white;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-approve-primary:hover {
  background: #0369a1;
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
  border: 1px solid #fef3c7;
  background: #fffbeb;
  display: flex;
  align-items: center;
  margin-bottom: 8px;
}
.text-amber-600 { color: #d97706; }
.text-amber-800 { color: #92400e; }
.mr-2 { margin-right: 8px; }
.text-sm { font-size: 13px; }

/* Main Layout Grid */
.main-layout-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px;
  align-items: start;
}
@media (min-width: 1024px) {
  .main-layout-grid {
    grid-template-columns: 1fr 300px;
  }
}

/* Form Area */
.form-content-area {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 2px rgba(0,0,0,0.01);
}

.card-header {
  padding: 16px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  user-select: none;
  background: white;
  border-bottom: 1px solid #f3f4f6;
}
.card-header:hover {
  background-color: #fafafa;
}
.card-title {
  font-size: 15px;
  font-weight: 700;
  color: #111827;
}
.chevron-icon {
  color: #9ca3af;
  transition: transform 0.25s ease;
}
.chevron-icon.rotate {
  transform: rotate(-90deg);
}

.card-body {
  padding: 20px;
  background: white;
}

/* Grid columns layout */
.form-grid-three {
  display: grid;
  grid-template-columns: 1fr;
  gap: 20px 24px;
}
@media (min-width: 768px) {
  .form-grid-three {
    grid-template-columns: repeat(3, 1fr);
  }
}

.form-field-col {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.span-full {
  grid-column: 1 / -1;
}

.field-label {
  font-size: 13px;
  font-weight: 600;
  color: #374151;
}
.required {
  color: #dc2626;
}

.field-input-text, .field-input-select, .field-input-textarea {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  outline: none;
  background: white;
  transition: border-color 0.15s, box-shadow 0.15s;
}
.field-input-text:focus, .field-input-select:focus, .field-input-textarea:focus {
  border-color: #0284c7;
  box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.1);
}
.field-input-text:disabled, .field-input-select:disabled, .field-input-textarea:disabled {
  background-color: #f9fafb;
  color: #6b7280;
  cursor: not-allowed;
}

.field-helper-text {
  font-size: 11px;
  color: #6b7280;
}

/* Checkbox alignment helper */
.checkbox-field-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  font-weight: 600;
  color: #374151;
  cursor: pointer;
  margin-top: 18px;
  user-select: none;
}
.checkbox-input {
  width: 16px;
  height: 16px;
  border-radius: 4px;
  border: 1px solid #d1d5db;
  accent-color: #0284c7;
  cursor: pointer;
}
.checkbox-input:disabled {
  cursor: not-allowed;
}

/* Custom dropdown select styles */
.custom-select-wrapper {
  position: relative;
}
.custom-select-trigger {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 13px;
  background: white;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  text-align: left;
  outline: none;
}
.custom-select-trigger:disabled {
  background-color: #f9fafb;
  color: #6b7280;
  cursor: not-allowed;
}
.custom-select-options {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  margin-top: 4px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
  z-index: 100;
  max-height: 200px;
  overflow-y: auto;
}
.custom-option-item {
  padding: 10px 12px;
  font-size: 13px;
  cursor: pointer;
}
.custom-option-item:hover {
  background-color: #f3f4f6;
}

/* Products editor card */
.products-table-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 2px rgba(0,0,0,0.01);
}
.table-card-header {
  padding: 16px 20px;
  border-bottom: 1px solid #f3f4f6;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.table-card-title {
  font-size: 15px;
  font-weight: 700;
  color: #111827;
}
.table-actions {
  display: flex;
  gap: 12px;
}
.btn-table-action {
  background: none;
  border: none;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 8px;
  border-radius: 6px;
  transition: background 0.15s;
}
.btn-table-action:hover {
  background-color: #f9fafb;
}
.btn-table-action:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.table-responsive {
  overflow-x: auto;
}
.products-editor-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
  font-size: 13px;
}
.products-editor-table th {
  background: #fafafa;
  color: #4b5563;
  font-weight: 600;
  padding: 12px 16px;
  border-bottom: 1px solid #e5e7eb;
}
.products-editor-table td {
  padding: 12px 16px;
  border-bottom: 1px solid #f3f4f6;
  vertical-align: middle;
}
.table-checkbox {
  width: 15px;
  height: 15px;
  accent-color: #0284c7;
  cursor: pointer;
}
.table-cell-input {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  font-size: 13px;
  outline: none;
}
.table-cell-input:focus {
  border-color: #0284c7;
}
.table-cell-select {
  padding: 8px 10px;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  font-size: 13px;
  background: white;
  outline: none;
}

/* Product dropdown editor suggestions */
.product-input-wrapper {
  position: relative;
  width: 100%;
}
.product-dropdown-list {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  box-shadow: 0 4px 10px rgba(0,0,0,0.1);
  z-index: 105;
  max-height: 180px;
  overflow-y: auto;
}
.product-option {
  padding: 8px 12px;
  cursor: pointer;
}
.product-option:hover {
  background-color: #f3f4f6;
}

.empty-table-placeholder {
  text-align: center;
  color: #9ca3af;
  padding: 40px 20px;
  font-style: italic;
}

/* Right Sidebar Summary */
.sidebar-summary-panel {
  width: 100%;
}
.summary-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 1px 2px rgba(0,0,0,0.01);
}
.summary-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}
.summary-doc-type {
  font-size: 12px;
  font-weight: 700;
  color: #9ca3af;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.btn-print-link {
  background: none;
  border: none;
  color: #0284c7;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
}
.btn-print-link:hover {
  text-decoration: underline;
}

.summary-main-info {
  margin-bottom: 16px;
}
.summary-location-label {
  font-size: 11px;
  color: #6b7280;
}
.summary-location-title {
  font-size: 18px;
  font-weight: 700;
  color: #111827;
  margin: 4px 0 0 0;
}

.summary-divider {
  height: 1px;
  background-color: #f3f4f6;
  margin: 16px 0;
}

.summary-indicator-row {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  margin-bottom: 10px;
}
.indicator-label {
  color: #6b7280;
}
.indicator-value {
  color: #111827;
  font-weight: 500;
}

.summary-status-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.status-label {
  font-size: 13px;
  color: #6b7280;
}

.summary-barcode-section {
  display: flex;
  flex-direction: column;
}
.barcode-label {
  font-size: 11px;
  font-weight: 700;
  color: #9ca3af;
  text-transform: uppercase;
  margin-bottom: 10px;
}
.barcode-box {
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}
.barcode-lines {
  display: flex;
  height: 38px;
  align-items: flex-start;
}
.bar {
  background-color: #111827;
  height: 100%;
  margin-right: 2px;
}
.thickness-1 { width: 1.5px; }
.thickness-2 { width: 3px; }
.thickness-3 { width: 4.5px; }
.thickness-4 { width: 6px; }

.barcode-text {
  font-size: 12px;
  font-weight: 600;
  color: #374151;
  font-family: monospace;
}
.scan-helper {
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

/* HIGH FIDELITY PRINT MODAL OVERLAY */
.print-preview-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9000;
  padding: 24px;
}

.print-preview-card {
  background: #f1f5f9;
  border-radius: 16px;
  box-shadow: 0 25px 50px -12px rgba(0,0,0,0.15);
  width: 100%;
  height: 100%;
  max-width: 1280px;
  max-height: 840px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  border: 1px solid rgba(255,255,255,0.7);
}

.print-modal-header {
  background: white;
  padding: 16px 24px;
  border-bottom: 1px solid #e2e8f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.print-modal-header h2 {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
  margin: 0;
}
.print-modal-header p {
  font-size: 12px;
  color: #64748b;
  margin: 2px 0 0 0;
}
.btn-close-circle {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 6px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
}
.btn-close-circle:hover {
  background-color: #f1f5f9;
  color: #0f172a;
}

.print-modal-body {
  flex: 1;
  display: grid;
  grid-template-columns: 1fr 300px;
  overflow: hidden;
}

/* Print preview sheet pane */
.print-preview-pane {
  background: #cbd5e1;
  overflow: hidden;
  position: relative;
  display: flex;
  flex-direction: column;
}
.zoom-controls {
  position: absolute;
  top: 16px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(15, 23, 42, 0.85);
  backdrop-filter: blur(4px);
  padding: 6px 12px;
  border-radius: 20px;
  display: flex;
  align-items: center;
  gap: 12px;
  z-index: 100;
}
.btn-zoom {
  background: none;
  border: none;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  padding: 2px;
  opacity: 0.8;
  transition: opacity 0.15s;
}
.btn-zoom:hover { opacity: 1; }
.zoom-text { color: white; font-size: 12px; font-weight: 600; min-width: 40px; text-align: center; }

.sheets-scroll-container {
  flex: 1;
  overflow-y: auto;
  padding: 70px 20px 40px 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 24px;
  scroll-behavior: smooth;
}

/* A4 Sheet physical styling */
.a4-sheet-wrapper {
  transform-origin: top center;
  transition: transform 0.2s ease-out;
}
.a4-page-sheet {
  background: white;
  width: 210mm;
  height: 297mm;
  padding: 20mm;
  box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1), 0 8px 10px -6px rgba(0,0,0,0.1);
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  position: relative;
}

.sheet-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
}
.company-branding {
  display: flex;
  align-items: center;
  gap: 12px;
}
.company-logo-preview {
  width: 40px;
  height: 40px;
  background-color: #0284c7;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: 850;
  font-size: 20px;
}
.company-name { font-size: 16px; font-weight: 700; color: #0f172a; margin: 0; }
.company-sub { font-size: 11px; color: #64748b; margin: 0; }
.company-branding-placeholder { height: 40px; }

.sheet-barcode-box {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
}
.sheet-barcode-lines {
  display: flex;
  height: 28px;
}
.sheet-barcode-lines .bar { background-color: #0f172a; }
.sheet-barcode-num { font-size: 10px; font-family: monospace; color: #475569; }

.sheet-doc-title-block {
  margin-bottom: 24px;
  border-bottom: 2px solid #f1f5f9;
  padding-bottom: 12px;
}
.sheet-doc-title { font-size: 22px; font-weight: 800; color: #0f172a; margin: 0; letter-spacing: -0.025em; }
.sheet-doc-subtitle { font-size: 12px; color: #64748b; margin: 2px 0 0 0; }

.sheet-meta-card {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px;
  margin-bottom: 24px;
}
.meta-card-col { display: flex; flex-direction: column; gap: 4px; }
.meta-card-value { font-size: 12px; font-weight: 700; color: #0f172a; }
.meta-card-label { font-size: 10px; font-weight: 600; color: #64748b; text-transform: uppercase; }

.sheet-optional-info {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 12px 16px;
  display: grid;
  grid-template-columns: 1fr;
  gap: 8px;
  margin-bottom: 24px;
}
.optional-info-item { display: flex; align-items: flex-start; gap: 6px; font-size: 11px; }
.optional-label { font-weight: 700; color: #64748b; }
.optional-value { color: #0f172a; }

.sheet-products-section { flex: 1; }

.sheet-summary-card {
  border: 1.5px dashed #cbd5e1;
  border-radius: 12px;
  padding: 24px;
  background-color: #f8fafc;
}
.summary-card-title { font-size: 14px; font-weight: 700; color: #0f172a; margin-bottom: 16px; text-transform: uppercase; letter-spacing: 0.05em; }
.summary-card-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
.summary-card-item { display: flex; flex-direction: column; gap: 4px; }
.summary-label { font-size: 11px; color: #64748b; font-weight: 600; }
.summary-value { font-size: 20px; font-weight: 800; color: #0284c7; }

.sheet-products-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 11px;
}
.sheet-products-table th {
  background: #f8fafc;
  border-bottom: 2px solid #cbd5e1;
  color: #475569;
  font-weight: 700;
  padding: 10px 8px;
  text-align: left;
}
.sheet-products-table td {
  padding: 12px 8px;
  border-bottom: 1px solid #f1f5f9;
  color: #334155;
}

.sheet-signatures {
  margin-top: auto;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 40px;
  padding-top: 40px;
}
.signature-line {
  border-top: 1px solid #cbd5e1;
  padding-top: 8px;
  text-align: center;
}
.sig-label { font-size: 10px; font-weight: 600; color: #64748b; text-transform: uppercase; }

.sheet-page-badge {
  position: absolute;
  bottom: 20mm;
  right: 20mm;
  font-size: 10px;
  color: #94a3b8;
}

/* Print Settings Right Sidebar */
.print-sidebar-menu {
  background: white;
  border-left: 1px solid #e2e8f0;
  padding: 24px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.setting-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.setting-title { font-size: 13px; font-weight: 600; color: #334155; }

/* Switch design */
.switch {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
}
.switch input { opacity: 0; width: 0; height: 0; }
.slider {
  position: absolute;
  cursor: pointer;
  top: 0; left: 0; right: 0; bottom: 0;
  background-color: #cbd5e1;
  transition: .2s;
}
.slider:before {
  position: absolute;
  content: "";
  height: 18px; width: 18px;
  left: 3px; bottom: 3px;
  background-color: white;
  transition: .2s;
}
input:checked + .slider { background-color: #0284c7; }
input:checked + .slider:before { transform: translateX(20px); }
.slider.round { border-radius: 24px; }
.slider.round:before { border-radius: 50%; }

/* Segmented radio options */
.layout-selector-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
  border-top: 1px solid #f1f5f9;
  padding-top: 16px;
}
.section-label { font-size: 11px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.radio-option {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 10px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
}
.radio-option:hover { background-color: #f8fafc; }
.radio-circle {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 1px solid #cbd5e1;
  margin-top: 2px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}
.radio-option input { display: none; }
.radio-option input:checked + .radio-circle {
  border-color: #0284c7;
  background-color: #0284c7;
  box-shadow: inset 0 0 0 3px white;
}
.radio-text { display: flex; flex-direction: column; gap: 2px; }
.radio-title { font-size: 13px; font-weight: 600; color: #334155; }
.radio-desc { font-size: 11px; color: #64748b; line-height: 1.4; }

/* Modal Footer */
.print-modal-footer {
  background: white;
  padding: 16px 24px;
  border-top: 1px solid #e2e8f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.btn-close {
  height: 40px;
  padding: 0 16px;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #334155;
  font-weight: 600;
  font-size: 13px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-close:hover { background-color: #f8fafc; }

.footer-right-actions { display: flex; gap: 12px; }
.btn-pdf {
  height: 40px;
  padding: 0 16px;
  background: white;
  border: 1px solid #0284c7;
  border-radius: 8px;
  color: #0284c7;
  font-weight: 600;
  font-size: 13px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-pdf:hover { background-color: rgba(2, 132, 199, 0.04); }
.btn-print {
  height: 40px;
  padding: 0 24px;
  background: #0284c7;
  border: none;
  border-radius: 8px;
  color: white;
  font-weight: 600;
  font-size: 13px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-print:hover { background-color: #0369a1; }

/* Print Media Queries */
@media print {
  body * { visibility: hidden; }
  .a4-page-sheet, .a4-page-sheet * { visibility: visible; }
  .a4-page-sheet {
    position: absolute;
    left: 0; top: 0;
    width: 210mm; height: 297mm;
    margin: 0; padding: 20mm;
    box-shadow: none !important;
  }
}
</style>
