<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { 
  Monitor, ChevronRight, X, Check, Loader2, Image as ImageIcon,
  User, MapPin, Heart, GraduationCap, Award, Briefcase, Sparkles,
  Bold, Italic, Underline, Strikethrough, Code, Table, Square,
  Link, Undo2, Redo2, ChevronDown, List, Calendar, Plus, Trash2
} from 'lucide-vue-next';
import BaseTabs from '../../components/BaseTabs.vue';
import BaseButton from '../../components/BaseButton.vue';
import FormInput from '../../components/FormInput.vue';
import FormSelect from '../../components/FormSelect.vue';
import FormCheckbox from '../../components/FormCheckbox.vue';

const router = useRouter();
const route = useRoute();

// ─── Document State ───
const isSaved = ref(false);
const isVerifying = ref(false);
const isIdVerified = ref(false);
const fileInput = ref<HTMLInputElement | null>(null);

// ─── Active Tab ───
type TabId = 'details' | 'addresses' | 'dependents' | 'qualifications' | 'certifications' | 'experiences' | 'skills_languages';
const activeTab = ref<TabId>('details');

const tabs = [
  { id: 'details' as const, label: 'Party Details', icon: User },
  { id: 'addresses' as const, label: 'Addresses', icon: MapPin },
  { id: 'dependents' as const, label: 'Dependents', icon: Heart },
  { id: 'qualifications' as const, label: 'Qualifications', icon: GraduationCap },
  { id: 'certifications' as const, label: 'Certifications', icon: Award },
  { id: 'experiences' as const, label: 'Work Experience', icon: Briefcase },
  { id: 'skills_languages' as const, label: 'Skills & Languages', icon: Sparkles }
];

// ─── Main Form Model ───
const form = ref({
  avatar: '',
  fayda_id: '',
  first_name: '',
  middle_name: '',
  last_name: '',
  phone: '',
  email: '',
  gender: 'Female',
  birth_date: '02/12/2000',
  birth_place: 'Addis Ababa',
  marital_status: 'Single',
  blood_group: 'O+',
  nationality_country: 'Ethiopia',
  nationality_type: 'Citizen',
  biography: `Sarah Jenkins is a Lead ERP Consultant & Inventory Strategist based in Seattle, Washington, with over seven years of experience in enterprise software. She specializes in supply chain forecasting and SAP Inventory Management rollouts, consistently striving to help retail brands streamline their stock control and minimize waste.

Sarah began her career after earning a Master's degree in Operations Management from the University of Washington. Since then, she has guided mid-sized e-commerce businesses through complex digital transformations.

One of her proudest achievements was leading a Microsoft Dynamics 365 migration for a national apparel brand, which synchronized stock across 50+ warehouses and reduced order processing times by 30%. Outside of her professional consulting, Sarah is passionate about open-water swimming and mentors young women pursuing careers in STEM.`
});

// ─── 1:N Sub-Entity Models ───
const newAddresses = ref<Array<{
  id: number;
  address_type: string;
  admin_unit: string;
  line: string;
  house_number: string;
  kebele: string;
  postal_code: string;
  is_primary: boolean;
}>>([
  { id: 1, address_type: 'residence', admin_unit: '305 (Bole)', line: 'Cameroon St.', house_number: '214', kebele: '08', postal_code: '1000', is_primary: true }
]);

const newDependents = ref<Array<{
  id: number;
  dependent_name: string;
  relation: string;
  birth_date: string;
  is_beneficiary: boolean;
  benefit_notes: string;
}>>([]);

const newQualifications = ref<Array<{
  id: number;
  level: string;
  field_of_study: string;
  institution: string;
  graduation_date: string;
  gpa: string;
}>>([]);

const newCertifications = ref<Array<{
  id: number;
  certification_name: string;
  issuing_institution: string;
  license_number: string;
  expiry_date: string;
}>>([]);

const newExperiences = ref<Array<{
  id: number;
  position_title: string;
  employer_name: string;
  employment_type: string;
  start_date: string;
  end_date: string;
  responsibilities: string;
}>>([]);

const newSkills = ref<Array<{
  id: number;
  skill_name: string;
  proficiency: string;
  years: number;
}>>([]);

const newLanguages = ref<Array<{
  id: number;
  language_name: string;
  proficiency: string;
  is_native: boolean;
}>>([]);

// ─── Initialize from Query if passed from QuickCreateModal ───
onMounted(() => {
  if (route.query.fayda_id) form.value.fayda_id = String(route.query.fayda_id);
  if (route.query.phone) form.value.phone = String(route.query.phone);
  if (route.query.gender) form.value.gender = String(route.query.gender);
  if (route.query.name) {
    const parts = String(route.query.name).trim().split(' ');
    form.value.first_name = parts[0] || '';
    form.value.middle_name = parts[1] || '';
    form.value.last_name = parts.slice(2).join(' ') || '';
  }
  if (form.value.fayda_id) {
    isIdVerified.value = true;
  }
});

// ─── Photo Upload ───
const triggerUpload = () => {
  fileInput.value?.click();
};

const handlePhotoUpload = (e: Event) => {
  const target = e.target as HTMLInputElement;
  if (target.files && target.files[0]) {
    const reader = new FileReader();
    reader.onload = (event) => {
      form.value.avatar = event.target?.result as string;
    };
    reader.readAsDataURL(target.files[0]);
  }
};

// ─── National ID Verification ───
const verifyNationalId = () => {
  if (!form.value.fayda_id) return;
  isVerifying.value = true;
  setTimeout(() => {
    isVerifying.value = false;
    isIdVerified.value = true;
  }, 600);
};

// ─── Clear Form Action ───
const clearForm = () => {
  form.value = {
    avatar: '',
    fayda_id: '',
    first_name: '',
    middle_name: '',
    last_name: '',
    phone: '',
    email: '',
    gender: 'Female',
    birth_date: '',
    birth_place: '',
    marital_status: 'Single',
    blood_group: 'O+',
    nationality_country: 'Ethiopia',
    nationality_type: 'Citizen',
    biography: ''
  };
  isIdVerified.value = false;
  newAddresses.value = [];
  newDependents.value = [];
  newQualifications.value = [];
  newCertifications.value = [];
  newExperiences.value = [];
  newSkills.value = [];
  newLanguages.value = [];
};

// ─── Sub-Item Helpers ───
const addAddressRow = () => {
  newAddresses.value.push({
    id: Date.now(),
    address_type: 'residence',
    admin_unit: '305 (Bole)',
    line: '',
    house_number: '',
    kebele: '',
    postal_code: '',
    is_primary: newAddresses.value.length === 0
  });
};

const addDependentRow = () => {
  newDependents.value.push({
    id: Date.now(),
    dependent_name: '',
    relation: 'spouse',
    birth_date: '',
    is_beneficiary: true,
    benefit_notes: ''
  });
};

const addQualificationRow = () => {
  newQualifications.value.push({
    id: Date.now(),
    level: 'bachelors',
    field_of_study: 'Accounting',
    institution: 'AAU',
    graduation_date: '',
    gpa: '3.50'
  });
};

const addCertificationRow = () => {
  newCertifications.value.push({
    id: Date.now(),
    certification_name: 'ACCA',
    issuing_institution: 'ACCA Global',
    license_number: '',
    expiry_date: ''
  });
};

const addExperienceRow = () => {
  newExperiences.value.push({
    id: Date.now(),
    position_title: '',
    employer_name: '',
    employment_type: 'permanent',
    start_date: '',
    end_date: '',
    responsibilities: ''
  });
};

const addSkillRow = () => {
  newSkills.value.push({
    id: Date.now(),
    skill_name: 'IFRS Reporting',
    proficiency: 'advanced',
    years: 3
  });
};

const addLanguageRow = () => {
  newLanguages.value.push({
    id: Date.now(),
    language_name: 'Amharic',
    proficiency: 'fluent',
    is_native: false
  });
};

// ─── Save Full Party ───
const handleSave = () => {
  const partyFullName = [form.value.first_name, form.value.middle_name, form.value.last_name]
    .filter(Boolean)
    .join(' ') || 'New Party Profile';

  // 1. Fetch existing parties
  const storedPartiesStr = localStorage.getItem('haleta_erp_parties');
  let currentParties = storedPartiesStr ? JSON.parse(storedPartiesStr) : [];
  
  const newPartyId = currentParties.length ? Math.max(...currentParties.map((p: any) => p.party_id || 0)) + 1 : 101;
  const newId = currentParties.length ? Math.max(...currentParties.map((p: any) => p.id || 0)) + 1 : 1;

  const newPartyRecord = {
    id: newId,
    uuid: `pty_${Date.now()}`,
    party_id: newPartyId,
    party_name: partyFullName,
    code: `PTY-${newPartyId}`,
    avatar: form.value.avatar || 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    email: form.value.email,
    phone: form.value.phone,
    fayda_id: form.value.fayda_id,
    gender_lookup_value_id: form.value.gender.toLowerCase(),
    blood_group_lookup_value_id: form.value.blood_group.toLowerCase().replace('+', '_pos').replace('-', '_neg'),
    birth_date: form.value.birth_date,
    birth_place: form.value.birth_place,
    nationality_country_id: form.value.nationality_country === 'Ethiopia' ? 'ET' : 'KE',
    nationality_type_lookup_value_id: form.value.nationality_type.toLowerCase().replace(' ', '_'),
    marital_status_lookup_value_id: form.value.marital_status.toLowerCase(),
    state: 'active'
  };

  // Prepend new party to top of table
  currentParties.unshift(newPartyRecord);
  localStorage.setItem('haleta_erp_parties', JSON.stringify(currentParties));

  // 2. Save 1:N sub-records
  if (newAddresses.value.length) {
    const stored = JSON.parse(localStorage.getItem('haleta_erp_addresses') || '[]');
    newAddresses.value.forEach((a, idx) => {
      stored.push({
        id: Date.now() + idx,
        uuid: `addr_${Date.now()}_${idx}`,
        party_id: newPartyId,
        address_type_lookup_value_id: a.address_type,
        admin_unit_id: a.admin_unit,
        line: a.line,
        house_number: a.house_number,
        kebele: a.kebele,
        postal_code: a.postal_code,
        is_primary: a.is_primary,
        state: 'active'
      });
    });
    localStorage.setItem('haleta_erp_addresses', JSON.stringify(stored));
  }

  isSaved.value = true;

  // Navigate back to the party directory
  setTimeout(() => {
    router.push('/hr/parties');
  }, 400);
};
</script>

<template>
  <div class="party-create-page">
    <!-- Top Action & Breadcrumb Navigation Bar -->
    <div class="top-nav-bar">
      <div class="nav-breadcrumbs-left">
        <!-- Root Monitor Icon Link -->
        <router-link to="/home" class="crumb-root" title="Home">
          <Monitor :size="15" />
        </router-link>

        <ChevronRight :size="13" class="crumb-sep" />
        
        <router-link to="/hr/parties" class="crumb-link">
          Party Management
        </router-link>

        <ChevronRight :size="13" class="crumb-sep" />

        <span class="crumb-current">Create Party</span>

        <!-- Status Pill Tag (e.g. Not Saved) -->
        <span :class="['state-pill', isSaved ? 'state-saved' : 'state-unsaved']">
          {{ isSaved ? 'Saved' : 'Not Saved' }}
        </span>
      </div>

      <!-- Right Action Buttons -->
      <div class="top-actions-right">
        <button type="button" class="btn-clear-form" @click="clearForm">
          <X :size="14" />
          <span>Clear Form</span>
        </button>

        <button type="button" class="btn-save-primary" @click="handleSave">
          <span>Save</span>
        </button>
      </div>
    </div>

    <!-- Capsule / Pill Tabs Navigation Standard (BaseTabs) -->
    <div class="tabs-container-wrapper">
      <BaseTabs 
        v-model="activeTab" 
        :tabs="tabs" 
        size="md" 
      />
    </div>

    <!-- TAB 1: User Details / Party Details Master Card -->
    <div v-show="activeTab === 'details'" class="create-card">
      <!-- 1. Profile Photo Section -->
      <div class="photo-section">
        <div class="avatar-preview-box">
          <img v-if="form.avatar" :src="form.avatar" class="avatar-img" />
          <div v-else class="no-media-box">
            <ImageIcon :size="26" class="no-media-icon" />
            <span class="no-media-text">No Media</span>
          </div>
        </div>

        <div class="photo-details-col">
          <input 
            type="file" 
            ref="fileInput" 
            class="hidden-file-input" 
            accept="image/*" 
            @change="handlePhotoUpload" 
          />
          <button type="button" class="btn-upload-photo" @click="triggerUpload">
            Upload New Photo / Logo
          </button>
          <p class="photo-hint-text">
            At least 800×800 px recommended and size should be less than 10MB. JPG or PNG is allowed
          </p>
        </div>
      </div>

      <div class="section-divider" />

      <!-- 2. National ID Verification Section -->
      <div class="national-id-section">
        <label class="form-label">National ID</label>
        <div class="id-input-row">
          <div class="id-input-wrapper">
            <input 
              type="text" 
              v-model="form.fayda_id" 
              class="id-text-input" 
              @input="isIdVerified = false"
            />
            <Check v-if="isIdVerified" :size="16" class="id-check-icon" />
          </div>

          <button 
            type="button" 
            class="btn-verify-id" 
            :disabled="!form.fayda_id || isVerifying"
            @click="verifyNationalId"
          >
            <Loader2 v-if="isVerifying" :size="14" class="animate-spin" />
            <span v-else>Verify ID</span>
          </button>
        </div>

        <p v-if="isIdVerified" class="id-verified-msg">
          ID Verified Successfully.
        </p>
      </div>

      <div class="section-divider" />

      <!-- 3. Party Information Header & 3-Column Names -->
      <div class="personal-info-block">
        <h4 class="section-subtitle">Party Information</h4>

        <!-- Name 3 Columns -->
        <div class="form-grid-three">
          <FormInput 
            label="First name" 
            v-model="form.first_name" 
            required 
          />
          <FormInput 
            label="Middle name" 
            v-model="form.middle_name" 
          />
          <FormInput 
            label="Last name" 
            v-model="form.last_name" 
            required 
          />
        </div>

        <!-- Phone & Email 2 Columns -->
        <div class="form-grid-two">
          <div class="phone-control-wrapper">
            <label class="form-label">Phone number</label>
            <div class="phone-input-composite">
              <div class="phone-prefix-box">
                <span class="country-code">ET</span>
                <ChevronDown :size="12" class="prefix-chevron" />
              </div>
              <input 
                type="text" 
                v-model="form.phone" 
                class="phone-actual-input" 
              />
            </div>
          </div>

          <FormInput 
            label="Email" 
            v-model="form.email" 
            type="email" 
          />
        </div>

        <!-- Gender & Date of Birth 2 Columns -->
        <div class="form-grid-two">
          <FormSelect 
            label="Gender" 
            v-model="form.gender" 
            :options="['Female', 'Male']" 
            placeholder="Select" 
          />

          <div class="dob-control-wrapper">
            <label class="form-label">Date of Birth</label>
            <div class="dob-input-composite">
              <Calendar :size="15" class="dob-cal-icon" />
              <input 
                type="text" 
                v-model="form.birth_date" 
                class="dob-actual-input" 
                placeholder="mm/dd/yyyy" 
              />
              <span class="gc-badge">GC</span>
            </div>
          </div>
        </div>

        <!-- Demographics Row 2 (Town, Blood Group, Marital Status) -->
        <div class="form-grid-three">
          <FormInput 
            label="Town of Birth" 
            v-model="form.birth_place" 
          />
          <FormSelect 
            label="Blood Group" 
            v-model="form.blood_group" 
            :options="['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']" 
            placeholder="Select" 
          />
          <FormSelect 
            label="Marital Status" 
            v-model="form.marital_status" 
            :options="['Single', 'Married', 'Divorced', 'Widowed']" 
            placeholder="Select" 
          />
        </div>

        <!-- Demographics Row 3 (Country, Nationality Type) -->
        <div class="form-grid-two">
          <FormSelect 
            label="Nationality Country" 
            v-model="form.nationality_country" 
            :options="['Ethiopia', 'Kenya', 'Djibouti', 'Sudan', 'United States', 'United Kingdom', 'Germany']" 
            placeholder="Select" 
          />
          <FormSelect 
            label="Nationality Type" 
            v-model="form.nationality_type" 
            :options="['Citizen', 'Resident Foreigner', 'Non-Resident Foreigner', 'Dual Citizen']" 
            placeholder="Select" 
          />
        </div>

        <!-- 4. Biography WYSIWYG Editor Component -->
        <div class="biography-wrapper">
          <label class="form-label">Biography</label>
          <div class="wysiwyg-editor-box">
            <!-- Toolbar -->
            <div class="wysiwyg-toolbar">
              <div class="tb-dropdown-btn">
                <span>Paragraph</span>
                <ChevronDown :size="12" class="tb-chevron" />
              </div>

              <div class="tb-dropdown-btn">
                <span>Font Type</span>
                <ChevronDown :size="12" class="tb-chevron" />
              </div>

              <div class="tb-dropdown-btn">
                <List :size="14" />
                <ChevronDown :size="12" class="tb-chevron" />
              </div>

              <div class="tb-v-divider" />

              <button type="button" class="tb-icon-btn" title="Bold"><Bold :size="14" /></button>
              <button type="button" class="tb-icon-btn" title="Italic"><Italic :size="14" /></button>
              <button type="button" class="tb-icon-btn" title="Underline"><Underline :size="14" /></button>
              <button type="button" class="tb-icon-btn" title="Strikethrough"><Strikethrough :size="14" /></button>
              <button type="button" class="tb-icon-btn" title="Code"><Code :size="14" /></button>
              <button type="button" class="tb-icon-btn" title="Table"><Table :size="14" /></button>

              <div class="tb-v-divider" />

              <button type="button" class="tb-icon-btn" title="Color"><Square :size="13" class="color-swatch-icon" /></button>
              <button type="button" class="tb-icon-btn" title="Link"><Link :size="14" /></button>
              <button type="button" class="tb-icon-btn" title="Image"><ImageIcon :size="14" /></button>

              <div class="tb-spacer" />

              <button type="button" class="tb-icon-btn" title="Undo"><Undo2 :size="14" /></button>
              <button type="button" class="tb-icon-btn" title="Redo"><Redo2 :size="14" /></button>
            </div>

            <!-- TextArea Body -->
            <textarea 
              v-model="form.biography" 
              class="wysiwyg-textarea" 
              rows="7"
              maxlength="5000"
            ></textarea>

            <!-- Character Counter Footer -->
            <div class="wysiwyg-footer">
              <span class="char-counter-text">
                {{ form.biography.length }} / 5,000 Characters
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- TAB 2: Addresses Tab Panel -->
    <div v-show="activeTab === 'addresses'" class="create-card">
      <div class="tab-panel-header">
        <div>
          <h3 class="panel-title">Party Addresses</h3>
          <p class="panel-sub">Residential, postal, and emergency contact locations.</p>
        </div>
        <BaseButton variant="primary" size="sm" @click="addAddressRow">
          <Plus :size="14" />
          <span>Add Address</span>
        </BaseButton>
      </div>

      <div class="sub-records-list">
        <div v-for="(addr, idx) in newAddresses" :key="addr.id" class="sub-record-card">
          <div class="sub-card-header">
            <span class="sub-record-num">Address #{{ idx + 1 }}</span>
            <button type="button" class="btn-del-record" @click="newAddresses.splice(idx, 1)">
              <Trash2 :size="14" />
            </button>
          </div>
          <div class="form-grid-three">
            <FormSelect 
              label="Address Type" 
              v-model="addr.address_type" 
              :options="['residence', 'postal', 'work', 'emergency']" 
            />
            <FormInput label="Admin Unit / Sub-City" v-model="addr.admin_unit" />
            <FormInput label="Street / Line" v-model="addr.line" />
          </div>
          <div class="form-grid-three pt-2">
            <FormInput label="House Number" v-model="addr.house_number" />
            <FormInput label="Kebele" v-model="addr.kebele" />
            <FormInput label="Postal Code" v-model="addr.postal_code" />
          </div>
        </div>

        <div v-if="newAddresses.length === 0" class="empty-panel-box">
          <MapPin :size="32" class="empty-box-icon" />
          <p>No addresses added yet.</p>
          <BaseButton variant="outline" size="sm" @click="addAddressRow">
            <Plus :size="14" />
            <span>Add Address</span>
          </BaseButton>
        </div>
      </div>
    </div>

    <!-- TAB 3: Dependents Tab Panel -->
    <div v-show="activeTab === 'dependents'" class="create-card">
      <div class="tab-panel-header">
        <div>
          <h3 class="panel-title">Family & Dependents</h3>
          <p class="panel-sub">Spouses, children, and eligible beneficiaries for coverage and benefits.</p>
        </div>
        <BaseButton variant="primary" size="sm" @click="addDependentRow">
          <Plus :size="14" />
          <span>Add Dependent</span>
        </BaseButton>
      </div>

      <div class="sub-records-list">
        <div v-for="(dep, idx) in newDependents" :key="dep.id" class="sub-record-card">
          <div class="sub-card-header">
            <span class="sub-record-num">Dependent #{{ idx + 1 }}</span>
            <button type="button" class="btn-del-record" @click="newDependents.splice(idx, 1)">
              <Trash2 :size="14" />
            </button>
          </div>
          <div class="form-grid-three">
            <FormInput label="Dependent Name" v-model="dep.dependent_name" />
            <FormSelect label="Relationship" v-model="dep.relation" :options="['spouse', 'child', 'parent', 'sibling', 'other']" />
            <FormInput label="Birth Date" v-model="dep.birth_date" type="date" />
          </div>
          <div class="pt-2">
            <FormInput label="Benefit / Insurance Policy Notes" v-model="dep.benefit_notes" />
          </div>
        </div>

        <div v-if="newDependents.length === 0" class="empty-panel-box">
          <Heart :size="32" class="empty-box-icon" />
          <p>No dependents added yet.</p>
          <BaseButton variant="outline" size="sm" @click="addDependentRow">
            <Plus :size="14" />
            <span>Add Dependent</span>
          </BaseButton>
        </div>
      </div>
    </div>

    <!-- TAB 4: Qualifications & Certifications -->
    <div v-show="activeTab === 'qualifications'" class="create-card">
      <div class="tab-panel-header">
        <div>
          <h3 class="panel-title">Academic Qualifications</h3>
          <p class="panel-sub">Formal education degrees, diplomas, and TVET credentials.</p>
        </div>
        <BaseButton variant="primary" size="sm" @click="addQualificationRow">
          <Plus :size="14" />
          <span>Add Qualification</span>
        </BaseButton>
      </div>

      <div class="sub-records-list">
        <div v-for="(q, idx) in newQualifications" :key="q.id" class="sub-record-card">
          <div class="sub-card-header">
            <span class="sub-record-num">Qualification #{{ idx + 1 }}</span>
            <button type="button" class="btn-del-record" @click="newQualifications.splice(idx, 1)">
              <Trash2 :size="14" />
            </button>
          </div>
          <div class="form-grid-three">
            <FormSelect label="Level" v-model="q.level" :options="['bachelors', 'masters', 'phd', 'diploma', 'tvet_certificate', 'secondary']" />
            <FormInput label="Field of Study" v-model="q.field_of_study" />
            <FormInput label="Awarding Institution" v-model="q.institution" />
          </div>
        </div>

        <div v-if="newQualifications.length === 0" class="empty-panel-box">
          <GraduationCap :size="32" class="empty-box-icon" />
          <p>No qualifications added yet.</p>
          <BaseButton variant="outline" size="sm" @click="addQualificationRow">
            <Plus :size="14" />
            <span>Add Qualification</span>
          </BaseButton>
        </div>
      </div>
    </div>

    <!-- TAB 5: Certifications -->
    <div v-show="activeTab === 'certifications'" class="create-card">
      <div class="tab-panel-header">
        <div>
          <h3 class="panel-title">Certifications & Licenses</h3>
          <p class="panel-sub">Professional credentials, board licenses, and safety certifications.</p>
        </div>
        <BaseButton variant="primary" size="sm" @click="addCertificationRow">
          <Plus :size="14" />
          <span>Add Certification</span>
        </BaseButton>
      </div>

      <div class="sub-records-list">
        <div v-for="(c, idx) in newCertifications" :key="c.id" class="sub-record-card">
          <div class="sub-card-header">
            <span class="sub-record-num">Certificate #{{ idx + 1 }}</span>
            <button type="button" class="btn-del-record" @click="newCertifications.splice(idx, 1)">
              <Trash2 :size="14" />
            </button>
          </div>
          <div class="form-grid-three">
            <FormInput label="Certification Name" v-model="c.certification_name" />
            <FormInput label="Issuing Body / Regulator" v-model="c.issuing_institution" />
            <FormInput label="License ID" v-model="c.license_number" />
          </div>
        </div>

        <div v-if="newCertifications.length === 0" class="empty-panel-box">
          <Award :size="32" class="empty-box-icon" />
          <p>No certifications added yet.</p>
          <BaseButton variant="outline" size="sm" @click="addCertificationRow">
            <Plus :size="14" />
            <span>Add Certification</span>
          </BaseButton>
        </div>
      </div>
    </div>

    <!-- TAB 6: Work Experience -->
    <div v-show="activeTab === 'experiences'" class="create-card">
      <div class="tab-panel-header">
        <div>
          <h3 class="panel-title">Employment & Work Experience</h3>
          <p class="panel-sub">Prior job roles, responsibilities, and professional history.</p>
        </div>
        <BaseButton variant="primary" size="sm" @click="addExperienceRow">
          <Plus :size="14" />
          <span>Add Experience</span>
        </BaseButton>
      </div>

      <div class="sub-records-list">
        <div v-for="(exp, idx) in newExperiences" :key="exp.id" class="sub-record-card">
          <div class="sub-card-header">
            <span class="sub-record-num">Experience #{{ idx + 1 }}</span>
            <button type="button" class="btn-del-record" @click="newExperiences.splice(idx, 1)">
              <Trash2 :size="14" />
            </button>
          </div>
          <div class="form-grid-three">
            <FormInput label="Job Title" v-model="exp.position_title" />
            <FormInput label="Employer Name" v-model="exp.employer_name" />
            <FormSelect label="Employment Type" v-model="exp.employment_type" :options="['permanent', 'contract', 'temporary', 'part_time', 'intern']" />
          </div>
          <div class="pt-2">
            <FormInput label="Key Responsibilities" v-model="exp.responsibilities" />
          </div>
        </div>

        <div v-if="newExperiences.length === 0" class="empty-panel-box">
          <Briefcase :size="32" class="empty-box-icon" />
          <p>No work experience added yet.</p>
          <BaseButton variant="outline" size="sm" @click="addExperienceRow">
            <Plus :size="14" />
            <span>Add Experience</span>
          </BaseButton>
        </div>
      </div>
    </div>

    <!-- TAB 7: Skills & Languages -->
    <div v-show="activeTab === 'skills_languages'" class="create-card">
      <div class="tab-panel-header">
        <div>
          <h3 class="panel-title">Skills & Languages</h3>
          <p class="panel-sub">Technical skill proficiencies and multi-language capabilities.</p>
        </div>
        <div class="flex gap-2">
          <BaseButton variant="outline" size="sm" @click="addSkillRow">
            <Plus :size="14" />
            <span>Add Skill</span>
          </BaseButton>
          <BaseButton variant="primary" size="sm" @click="addLanguageRow">
            <Plus :size="14" />
            <span>Add Language</span>
          </BaseButton>
        </div>
      </div>

      <div class="sub-records-list">
        <!-- Skills -->
        <h4 class="sub-section-title">Skills</h4>
        <div v-for="(skl, idx) in newSkills" :key="skl.id" class="sub-record-card">
          <div class="sub-card-header">
            <span class="sub-record-num">Skill #{{ idx + 1 }}</span>
            <button type="button" class="btn-del-record" @click="newSkills.splice(idx, 1)">
              <Trash2 :size="14" />
            </button>
          </div>
          <div class="form-grid-three">
            <FormInput label="Skill Name" v-model="skl.skill_name" />
            <FormSelect label="Proficiency" v-model="skl.proficiency" :options="['beginner', 'intermediate', 'advanced', 'expert']" />
            <FormInput label="Years Experience" v-model="skl.years" type="number" />
          </div>
        </div>

        <!-- Languages -->
        <h4 class="sub-section-title mt-4">Languages</h4>
        <div v-for="(lng, idx) in newLanguages" :key="lng.id" class="sub-record-card">
          <div class="sub-card-header">
            <span class="sub-record-num">Language #{{ idx + 1 }}</span>
            <button type="button" class="btn-del-record" @click="newLanguages.splice(idx, 1)">
              <Trash2 :size="14" />
            </button>
          </div>
          <div class="form-grid-three">
            <FormInput label="Language" v-model="lng.language_name" />
            <FormSelect label="Proficiency" v-model="lng.proficiency" :options="['basic', 'conversational', 'fluent', 'native']" />
            <FormCheckbox label="Is Native Language" v-model="lng.is_native" class="mt-6" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.party-create-page {
  padding: 20px 28px 40px 28px;
  background-color: #fafafa;
  min-height: 100%;
  box-sizing: border-box;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

/* ─── Top Bar & Breadcrumbs ─── */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 24px;
}

.nav-breadcrumbs-left {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13.5px;
}

.crumb-root {
  color: #64748b;
  display: inline-flex;
  align-items: center;
  padding: 4px;
  border-radius: 6px;
  transition: all 0.15s ease;
}
.crumb-root:hover {
  color: #0f172a;
  background-color: #f1f5f9;
}

.crumb-sep {
  color: #94a3b8;
}

.crumb-link {
  color: #64748b;
  text-decoration: none;
  font-weight: 450;
  transition: color 0.15s;
}
.crumb-link:hover {
  color: #0f172a;
}

.crumb-current {
  color: #0f172a;
  font-weight: 600;
}

.state-pill {
  padding: 2px 10px;
  border-radius: 6px;
  font-size: 11.5px;
  font-weight: 550;
  margin-left: 6px;
  display: inline-block;
}
.state-unsaved {
  background-color: #fef3c7;
  color: #d97706;
}
.state-saved {
  background-color: #ecfdf5;
  color: #059669;
}

/* Top Actions Right */
.top-actions-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.btn-clear-form {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 36px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #334155;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
  transition: all 0.15s ease;
}
.btn-clear-form:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
  color: #0f172a;
}

.btn-save-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 36px;
  padding: 0 22px;
  background-color: #0B529C;
  border: none;
  border-radius: 8px;
  font-size: 13.5px;
  font-weight: 600;
  color: #ffffff;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(11, 82, 156, 0.15);
  transition: all 0.15s ease;
}
.btn-save-primary:hover {
  background-color: #09427D;
  box-shadow: 0 3px 6px rgba(11, 82, 156, 0.25);
  transform: translateY(-0.5px);
}

/* ─── Tabs Bar ─── */
.tabs-container-wrapper {
  margin-bottom: 20px;
}

/* ─── Main White Surface Card ─── */
.create-card {
  background-color: #ffffff;
  border: 1px solid #f1f5f9;
  border-radius: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
  padding: 32px 36px;
}

/* 1. Photo Section */
.photo-section {
  display: flex;
  align-items: center;
  gap: 24px;
}

.avatar-preview-box {
  width: 90px;
  height: 90px;
  border-radius: 50%;
  overflow: hidden;
  flex-shrink: 0;
  background-color: #f8fafc;
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.no-media-box {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  background-color: #f1f5f9;
  border-radius: 50%;
}
.no-media-icon {
  color: #94a3b8;
}
.no-media-text {
  font-size: 11px;
  color: #64748b;
  font-weight: 500;
}

.photo-details-col {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.hidden-file-input {
  display: none;
}

.btn-upload-photo {
  align-self: flex-start;
  height: 34px;
  padding: 0 14px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #334155;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
  transition: all 0.15s ease;
}
.btn-upload-photo:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
  color: #0f172a;
}

.photo-hint-text {
  font-size: 12px;
  color: #64748b;
  margin: 0;
  line-height: 1.4;
}

.section-divider {
  height: 1px;
  background-color: #f1f5f9;
  margin: 24px 0;
}

/* 2. National ID Section */
.national-id-section {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-label {
  font-size: 12.5px;
  font-weight: 500;
  color: #404040;
}

.id-input-row {
  display: flex;
  align-items: center;
  gap: 12px;
  max-width: 480px;
}

.id-input-wrapper {
  position: relative;
  flex: 1;
  display: flex;
  align-items: center;
}

.id-text-input {
  width: 100%;
  height: 38px;
  padding: 0 34px 0 12px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13.5px;
  color: #1e293b;
  outline: none;
  transition: all 0.15s ease;
}
.id-text-input:focus {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.id-check-icon {
  position: absolute;
  right: 10px;
  color: #059669;
}

.btn-verify-id {
  height: 38px;
  padding: 0 16px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 550;
  color: #0B529C;
  cursor: pointer;
  transition: all 0.15s ease;
  white-space: nowrap;
}
.btn-verify-id:hover:not(:disabled) {
  background-color: #eff6ff;
  border-color: #93c5fd;
}
.btn-verify-id:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.id-verified-msg {
  font-size: 12px;
  color: #059669;
  font-weight: 500;
  margin: 2px 0 0 0;
}

/* 3. Personal Information Block */
.personal-info-block {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.section-subtitle {
  font-size: 13px;
  font-weight: 500;
  color: #64748b;
  margin: 0 0 4px 0;
}

.form-grid-three {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

.form-grid-two {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

/* Phone Composite Input */
.phone-control-wrapper {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.phone-input-composite {
  display: flex;
  align-items: center;
  height: 38px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  transition: border-color 0.15s ease;
}
.phone-input-composite:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.phone-prefix-box {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 0 10px;
  height: 100%;
  background-color: #f8fafc;
  border-right: 1px solid #e2e8f0;
  font-size: 12.5px;
  font-weight: 500;
  color: #475569;
  user-select: none;
}
.prefix-chevron {
  color: #94a3b8;
}

.phone-actual-input {
  flex: 1;
  height: 100%;
  border: none;
  outline: none;
  padding: 0 12px;
  font-size: 13.5px;
  color: #1e293b;
  background: transparent;
}

/* Date of Birth Composite */
.dob-control-wrapper {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.dob-input-composite {
  display: flex;
  align-items: center;
  height: 38px;
  background-color: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 0 10px;
  transition: border-color 0.15s ease;
}
.dob-input-composite:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.dob-cal-icon {
  color: #64748b;
  flex-shrink: 0;
  margin-right: 8px;
}

.dob-actual-input {
  flex: 1;
  border: none;
  outline: none;
  font-size: 13px;
  color: #1e293b;
  background: transparent;
}

.gc-badge {
  font-size: 11px;
  font-weight: 600;
  color: #64748b;
  background-color: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
  user-select: none;
}

/* 4. Biography WYSIWYG Box */
.biography-wrapper {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-top: 4px;
}

.wysiwyg-editor-box {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background-color: #ffffff;
  overflow: hidden;
  transition: border-color 0.15s ease;
}
.wysiwyg-editor-box:focus-within {
  border-color: #0B529C;
  box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08);
}

.wysiwyg-toolbar {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px 10px;
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  flex-wrap: wrap;
}

.tb-dropdown-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 8px;
  font-size: 12px;
  font-weight: 500;
  color: #475569;
  border-radius: 5px;
  cursor: pointer;
  user-select: none;
  transition: background 0.1s;
}
.tb-dropdown-btn:hover {
  background-color: #edf2f7;
}
.tb-chevron {
  color: #94a3b8;
}

.tb-v-divider {
  width: 1px;
  height: 18px;
  background-color: #cbd5e1;
  margin: 0 4px;
}

.tb-icon-btn {
  width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 5px;
  color: #475569;
  cursor: pointer;
  transition: all 0.1s ease;
}
.tb-icon-btn:hover {
  background-color: #edf2f7;
  color: #0f172a;
}

.color-swatch-icon {
  fill: #1e293b;
}

.tb-spacer {
  margin-left: auto;
}

.wysiwyg-textarea {
  width: 100%;
  padding: 14px 16px;
  border: none;
  outline: none;
  resize: vertical;
  font-family: inherit;
  font-size: 13px;
  line-height: 1.6;
  color: #334155;
  box-sizing: border-box;
}

.wysiwyg-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 14px;
  border-top: 1px solid #f8fafc;
  background-color: #ffffff;
}

.char-counter-text {
  font-size: 11.5px;
  color: #94a3b8;
}

/* ─── Sub-Tab Panels (Addresses, Dependents, Qualifications, etc.) ─── */
.tab-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
  gap: 16px;
}

.panel-title {
  font-size: 16px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 2px 0;
}

.panel-sub {
  font-size: 12.5px;
  color: #64748b;
  margin: 0;
}

.sub-records-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.sub-record-card {
  padding: 16px 20px;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  background-color: #ffffff;
}

.sub-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.sub-record-num {
  font-size: 12.5px;
  font-weight: 600;
  color: #0B529C;
}

.btn-del-record {
  background: transparent;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 4px;
  border-radius: 6px;
  transition: all 0.15s ease;
}
.btn-del-record:hover {
  color: #e11d48;
  background-color: #fee2e2;
}

.sub-section-title {
  font-size: 13.5px;
  font-weight: 600;
  color: #1e293b;
  margin: 0;
}

.empty-panel-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 48px 24px;
  background-color: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 12px;
  color: #64748b;
  font-size: 13px;
}
.empty-box-icon {
  color: #94a3b8;
}

@media (max-width: 768px) {
  .form-grid-three, .form-grid-two {
    grid-template-columns: 1fr;
  }
  .photo-section {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
