<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  GraduationCap, Info, FileText, Check, ArrowLeft,
  Globe, Building2, Shield, Layers, HelpCircle
} from 'lucide-vue-next';
import AppBreadcrumb from '../../components/AppBreadcrumb.vue';
import BaseTabs from '../../components/BaseTabs.vue';
import BaseButton from '../../components/BaseButton.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormTextarea from '../../components/FormTextarea.vue';

// ─── Interfaces ───
export type GovernanceStatus = 'acceptForAll' | 'acceptForThis' | 'pending' | 'reject';
export type RowState = 'active' | 'inactive';

export interface FieldOfStudyItem {
  id: number;
  uuid: string;
  code: string;
  name: string;
  parent_id: number | null;
  entity_id: string | null;
  is_system: boolean;
  status_lookup_value_id: GovernanceStatus;
  state: RowState;
  description?: string;
  created_at?: string;
}

const router = useRouter();
const route = useRoute();

const STORAGE_KEY = 'haleta_erp_field_of_study_v3';
const fieldsOfStudy = ref<FieldOfStudyItem[]>([]);

// State
const isEdit = computed(() => !!route.params.id || !!route.query.id);
const targetId = computed(() => {
  if (route.params.id) return Number(route.params.id);
  if (route.query.id) return Number(route.query.id);
  return null;
});

const isSaved = ref(false);

// Form Fields
const form = ref({
  code: '',
  name: '',
  parent_id: '' as string | number,
  entity_id: 'Haleta Enterprise Group',
  is_system: false,
  status_lookup_value_id: 'acceptForAll' as GovernanceStatus,
  state: 'active' as RowState,
  description: '',
  uuid: ''
});

// Primary Tabs for full creation page
type TabId = 'basic' | 'governance' | 'scope';
const activeTab = ref<TabId>('basic');
const tabs: { id: TabId; label: string; icon: any }[] = [
  { id: 'basic', label: 'Basic Information', icon: Info },
  { id: 'governance', label: 'Governance & Ownership', icon: Shield },
  { id: 'scope', label: 'Syllabus & Qualification Scope', icon: FileText }
];

// Load dataset and prefill form
onMounted(() => {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved) {
    try {
      fieldsOfStudy.value = JSON.parse(saved);
    } catch {
      fieldsOfStudy.value = [];
    }
  }

  // If edit mode, populate from existing record
  if (isEdit.value && targetId.value) {
    const existing = fieldsOfStudy.value.find(i => i.id === targetId.value);
    if (existing) {
      form.value = {
        code: existing.code,
        name: existing.name,
        parent_id: existing.parent_id !== null ? existing.parent_id.toString() : '',
        entity_id: existing.entity_id || 'Haleta Enterprise Group',
        is_system: existing.is_system,
        status_lookup_value_id: existing.status_lookup_value_id,
        state: existing.state,
        description: existing.description || '',
        uuid: existing.uuid
      };
      return;
    }
  }

  // If query params passed from quick modal expansion
  if (route.query.name) form.value.name = String(route.query.name);
  if (route.query.code) form.value.code = String(route.query.code);
  if (route.query.parent_id) form.value.parent_id = String(route.query.parent_id);
  if (route.query.status) form.value.status_lookup_value_id = route.query.status as GovernanceStatus;
  if (route.query.state) form.value.state = route.query.state as RowState;
});

// Root domains for parent select
const rootDomainOptions = computed(() => {
  return [
    { value: '', label: '-- None (Root Academic Domain) --' },
    ...fieldsOfStudy.value
      .filter(r => r.parent_id === null && (targetId.value ? r.id !== targetId.value : true))
      .map(r => ({
        value: r.id.toString(),
        label: `${r.name} (${r.code})`
      }))
  ];
});

// Save Handler
const handleSave = () => {
  if (!form.value.name.trim()) {
    alert('Please fill out the Discipline Name.');
    activeTab.value = 'basic';
    return;
  }
  if (!form.value.code.trim()) {
    alert('Please fill out the Business Code.');
    activeTab.value = 'basic';
    return;
  }

  const cleanCode = form.value.code.trim().toUpperCase().replace(/\s+/g, '_');
  const parentVal = form.value.parent_id !== '' ? Number(form.value.parent_id) : null;

  // Validate unique code
  const duplicate = fieldsOfStudy.value.find(
    i => i.code.toUpperCase() === cleanCode && (targetId.value ? i.id !== targetId.value : true)
  );
  if (duplicate) {
    alert(`Code "${cleanCode}" is already in use by "${duplicate.name}". Codes must be unique.`);
    return;
  }

  if (isEdit.value && targetId.value) {
    const idx = fieldsOfStudy.value.findIndex(i => i.id === targetId.value);
    if (idx !== -1) {
      fieldsOfStudy.value[idx] = {
        ...fieldsOfStudy.value[idx],
        code: cleanCode,
        name: form.value.name.trim(),
        parent_id: parentVal,
        entity_id: form.value.is_system ? null : form.value.entity_id,
        is_system: form.value.is_system,
        status_lookup_value_id: form.value.status_lookup_value_id,
        state: form.value.state,
        description: form.value.description.trim() || undefined
      };
    }
  } else {
    const newId = Math.max(...fieldsOfStudy.value.map(i => i.id), 0) + 1;
    const newUuid = `fos_${crypto.randomUUID ? crypto.randomUUID() : 'gen-' + Date.now()}`;

    fieldsOfStudy.value.push({
      id: newId,
      uuid: newUuid,
      code: cleanCode,
      name: form.value.name.trim(),
      parent_id: parentVal,
      entity_id: form.value.is_system ? null : form.value.entity_id,
      is_system: form.value.is_system,
      status_lookup_value_id: form.value.status_lookup_value_id,
      state: form.value.state,
      description: form.value.description.trim() || undefined,
      created_at: new Date().toISOString()
    });
  }

  localStorage.setItem(STORAGE_KEY, JSON.stringify(fieldsOfStudy.value));
  isSaved.value = true;
  router.push('/hr/field-of-study');
};

const handleCancel = () => {
  router.push('/hr/field-of-study');
};
</script>

<template>
  <div class="field-of-study-create-page">
    <!-- Top Action Bar & Breadcrumbs -->
    <div class="page-top-bar">
      <AppBreadcrumb 
        :items="[
          { label: 'Human Resources' },
          { label: 'Field of Study', to: '/hr/field-of-study' },
          { label: isEdit ? 'Edit Field of Study' : 'Create Field of Study' }
        ]"
      >
        <template #extra>
          <span class="status-badge-unsaved">
            {{ isSaved ? 'Saved' : 'Not Saved' }}
          </span>
        </template>
      </AppBreadcrumb>

      <div class="top-actions">
        <BaseButton variant="secondary" @click="handleCancel">
          <ArrowLeft :size="15" class="mr-1.5" />
          <span>Cancel</span>
        </BaseButton>
        <BaseButton variant="primary" @click="handleSave">
          <Check :size="15" class="mr-1.5" stroke-width="2.5" />
          <span>{{ isEdit ? 'Save Changes' : 'Save Field of Study' }}</span>
        </BaseButton>
      </div>
    </div>

    <!-- Navigation Tabs Standard (<BaseTabs /> Capsule Pill) -->
    <div class="tabs-container">
      <BaseTabs 
        v-model="activeTab" 
        :tabs="tabs" 
      />
    </div>

    <!-- Main Form Content Card -->
    <div class="content-card">
      <!-- TAB 1: BASIC CLASSIFICATION -->
      <div v-show="activeTab === 'basic'" class="tab-pane-content">
        <div class="form-section-title-wrap">
          <h3 class="section-title">Academic Discipline Classification</h3>
          <p class="section-subtitle">
            Define the primary academic title, human-readable business code, and domain hierarchy.
          </p>
        </div>

        <div class="form-grid-two">
          <FormInput
            v-model="form.name"
            label="Discipline Name"
            required
          />

          <FormInput
            v-model="form.code"
            label="Business Code (Unique Uppercase)"
            required
          />
        </div>

        <div class="form-group mt-4">
          <FormSelect
            v-model="form.parent_id"
            label="Parent Domain Hierarchy"
            :options="rootDomainOptions"
          />
          <span class="field-helper-text">
            Select a parent faculty to make this a specialized sub-discipline (e.g. Business Administration &rarr; Accounting). Leave empty to establish a new root domain.
          </span>
        </div>

        <div v-if="isEdit && form.uuid" class="form-group mt-4">
          <FormInput
            v-model="form.uuid"
            label="Public UUID (Read-Only)"
            disabled
          />
        </div>
      </div>

      <!-- TAB 2: GOVERNANCE & OWNERSHIP -->
      <div v-show="activeTab === 'governance'" class="tab-pane-content">
        <div class="form-section-title-wrap">
          <h3 class="section-title">Governance & System Provenance</h3>
          <p class="section-subtitle">
            Configure tenant ownership, core governance approval status, and operational availability.
          </p>
        </div>

        <div class="form-grid-two">
          <FormSelect
            v-model="form.status_lookup_value_id"
            label="Core Governance Status"
            :options="[
              { value: 'acceptForAll', label: 'Accepted for All Tenants (Global Reference)' },
              { value: 'acceptForThis', label: 'Accepted for This Tenant Only' },
              { value: 'pending', label: 'Pending Governance Review' },
              { value: 'reject', label: 'Rejected' }
            ]"
          />

          <FormSelect
            v-model="form.state"
            label="Operational State"
            :options="[
              { value: 'active', label: 'Active (Available for Qualifications & Job Postings)' },
              { value: 'inactive', label: 'Inactive (Archived)' }
            ]"
          />
        </div>

        <div class="form-grid-two mt-4">
          <FormInput
            v-model="form.entity_id"
            label="Owning Tenant / Entity"
            :disabled="form.is_system"
          />

          <div class="provenance-radio-box">
            <label class="provenance-title">Provenance Type</label>
            <div class="flex items-center gap-4 mt-2">
              <label class="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                <input type="radio" :value="false" v-model="form.is_system" />
                <span>Tenant Addition</span>
              </label>
              <label class="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                <input type="radio" :value="true" v-model="form.is_system" />
                <span>Platform Seed (System Classification)</span>
              </label>
            </div>
          </div>
        </div>
      </div>

      <!-- TAB 3: SYLLABUS & SCOPE -->
      <div v-show="activeTab === 'scope'" class="tab-pane-content">
        <div class="form-section-title-wrap">
          <h3 class="section-title">Syllabus Scope & Academic Description</h3>
          <p class="section-subtitle">
            Provide details on the academic scope, curriculum coverage, and qualification requirements.
          </p>
        </div>

        <div class="form-group">
          <FormTextarea
            v-model="form.description"
            label="Discipline Description & Syllabus Notes"
            :rows="5"
          />
          <span class="field-helper-text">
            Outlines the expected degree qualifications, certification scopes, and relevant position requirements associated with this discipline.
          </span>
        </div>
      </div>

      <!-- Card Bottom Actions -->
      <div class="form-footer-bar">
        <BaseButton variant="secondary" @click="handleCancel">
          Cancel
        </BaseButton>
        <BaseButton variant="primary" @click="handleSave">
          <Check :size="15" class="mr-1.5" stroke-width="2.5" />
          <span>{{ isEdit ? 'Save Changes' : 'Save Field of Study' }}</span>
        </BaseButton>
      </div>
    </div>
  </div>
</template>

<style scoped>
.field-of-study-create-page {
  padding: 0;
  animation: fadeIn 0.2s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(4px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Top Action Bar */
.page-top-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  flex-wrap: wrap;
  gap: 12px;
}

.top-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.status-badge-unsaved {
  font-size: 11px;
  font-weight: 600;
  color: #92400e;
  background-color: #fef3c7;
  border: 1px solid #fde68a;
  padding: 2px 8px;
  border-radius: 100px;
}

/* Tabs */
.tabs-container {
  margin-bottom: 20px;
}

/* Content Card */
.content-card {
  background-color: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.04);
  padding: 24px;
}

.tab-pane-content {
  display: flex;
  flex-direction: column;
}

.form-section-title-wrap {
  margin-bottom: 20px;
  padding-bottom: 12px;
  border-bottom: 1px solid #f1f5f9;
}

.section-title {
  font-size: 15px;
  font-weight: 700;
  color: #404040;
  margin: 0;
}

.section-subtitle {
  font-size: 12.5px;
  color: #737373;
  margin: 4px 0 0 0;
}

.form-grid-two {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

@media (max-width: 768px) {
  .form-grid-two {
    grid-template-columns: 1fr;
  }
}

.field-helper-text {
  font-size: 11.5px;
  color: #94a3b8;
  margin-top: 4px;
  display: block;
}

.provenance-radio-box {
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.provenance-title {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.form-footer-bar {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 10px;
  margin-top: 28px;
  padding-top: 16px;
  border-top: 1px solid #f1f5f9;
}
</style>
