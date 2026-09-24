# ERP Creation UX & Modal Standard Rule

This document defines the mandatory creation pattern across all modules (Human Resources, Sales, Inventory, Buying, Company Setup) in Haleta ERP.

---

## 1. The Core Creation Rule ($\le 5$ vs. $> 5$ Required Fields)

Every entity creation flow MUST adhere to the following rule based on the number of required fields:

### **Case A: $\le 5$ Essential / Required Fields $\rightarrow$ Quick Create Modal (`<QuickCreateModal />`)**
When an entity can be created with 5 or fewer essential fields (e.g. Customer, Organization Unit, Job Title, Leave Type, Shift, Supplier, Product Group):
1. Clicking the **"+ Add / Create"** button MUST open a **`<QuickCreateModal />`**.
2. The modal presents only the essential fields (e.g. Name, Code, Type, Status, Primary Identifier).
3. **No Notes/Descriptions in Quick Modals**: Descriptions, remarks, long texts, or note sections MUST NEVER appear in `<QuickCreateModal />`. They belong strictly in dedicated expanded full-form creation pages.
4. **"Save as draft" Prohibition in Quick Modals**: The "Save as draft" action will NEVER appear in a quick create modal. It is strictly reserved for expanded full creation pages.
5. **Footer Action Hierarchy:**
   - **Bottom-Left**: **"Expand Full Form"** styled as a **Secondary Button** (`<Maximize2 />` icon) $\rightarrow$ Navigates/switches to the dedicated full creation page/drawer, carrying over any already-typed state.
   - **Bottom-Right**: **"Save"** styled as the **Primary Button** (strictly plain text **"Save"**, **ZERO icons**) $\rightarrow$ Instantly validates, creates the record, adds it to the table/directory, and closes the modal. (Cancel button is omitted; modal dismisses via Esc/Close/Backdrop).

### **Case B: $> 5$ Required Fields $\rightarrow$ Direct Page / Wizard Form**
When an entity fundamentally requires more than 5 complex or multi-stage required fields (e.g. Full Employee Onboarding with statutory Fayda/Pension/Bank/Contract, Gate Pass with multi-item packing slips, Complex Product with Matrix Variants):
1. Clicking **"+ Add / Create"** goes **directly to the dedicated creation page/route** (e.g. `/hr/employees/create`, `/gate-pass/create`, `/stock-reservation/create`).
2. The page utilizes a multi-step tabbed interface (`<BaseTabs />` or `<StepWizard />`).

---

## 2. Standardized Modal Component Reference: `<QuickCreateModal />`

Located at: `src/components/QuickCreateModal.vue`

### **Component API:**
```typescript
interface Props {
  show: boolean;                     // v-model:show
  title: string;                     // e.g. 'Create Customer'
  subtitle?: string;                 // e.g. 'Enter essential details or expand to full form.'
  expandRoute?: string | object;     // Route for "Expand Full Form" (e.g. '/sales/customers/create')
  expandLabel?: string;              // Default: 'Expand Full Form'
  showExpandButton?: boolean;        // Default: true
  saveLabel?: string;                // Default: 'Save'
  cancelLabel?: string;              // Default: 'Cancel'
  loading?: boolean;                 // Spinner state
  disabled?: boolean;                // Disable save button
  width?: 'sm' | 'md' | 'lg';        // Modal width (default: 'md')
}

// Emits:
// - 'update:show': (value: boolean)
// - 'save': ()
// - 'cancel': ()
// - 'expand': ()
```

### **Template Implementation Structure:**
```html
<QuickCreateModal
  v-model:show="showQuickModal"
  title="Create Customer"
  subtitle="Quickly register a customer with basic details, or expand for credit and loyalty configurations."
  expandRoute="/sales/customers/create"
  @save="handleQuickSave"
>
  <div class="form-grid">
    <div class="form-group">
      <label class="form-label">Party / Name <span class="text-red-500">*</span></label>
      <input v-model="quickForm.party_name" class="form-input" placeholder="e.g. Abebe Kebede" />
    </div>

    <div class="form-group">
      <label class="form-label">Phone Number <span class="text-red-500">*</span></label>
      <input v-model="quickForm.phone" class="form-input" placeholder="+251 91 234 5678" />
    </div>

    <div class="form-group">
      <label class="form-label">Customer Group</label>
      <select v-model="quickForm.group" class="form-select">
        <option>Retail Customers</option>
        <option>Wholesale</option>
      </select>
    </div>

    <div class="form-group checkbox-row">
      <label class="checkbox-label">
        <input type="checkbox" v-model="quickForm.is_walk_in" />
        <span>Walk-in Customer</span>
      </label>
    </div>
  </div>
</QuickCreateModal>
```

---

## 3. Strict Rules for All New HR & ERP Pages

1. **Never create ad-hoc modal dialogs** with raw HTML/CSS. Always use `<QuickCreateModal />`.
2. **Never hide the "Expand Full Form" option** unless an entity truly has no full form page.
3. **Always preserve form state** when transitioning from the quick modal to the full creation page.
4. **All action and modal buttons** must strictly use a **well-rounded rectangle shape (`border-radius: 8px` to `10px`)**. ONLY Primary Tabs (`<BaseTabs />`) use the 100% fully rounded capsule/pill shape.

---

## 4. Dedicated Full Creation Page Architecture (Expand Full Form Standard)

When the user clicks **"Expand Full Form"** from `<QuickCreateModal />` (or navigates to a dedicated `.../create` route):

### **A. Entity Domain Naming Standard**
- Always name the page, breadcrumb, primary tab, and form labels after the specific entity domain (e.g. `Party`, `Create Party`, `Party Details`, `Party Information`, `Create Customer`, `Customer Details`).
- **NEVER use generic "User" or "Create User" naming** unless the record is explicitly a platform user account. For example, a Party in Haleta ERP can be an individual person or an organization/company.

### **B. Page Layout Structure**
1. **Top Bar & Action Strip**:
   - Breadcrumbs: `[Monitor Root Icon] > [Module / Directory Link] > Create [Entity]`.
   - Status Pill: `Not Saved` (amber background `#fef3c7`, text `#d97706`) in draft state, dynamically switching to `Saved` (`#ecfdf5`, `#059669`) once saved.
   - Right Actions:
     - **Dynamic 3-Dots More Menu `[ ⋮ ]`**: Placed on the far left of the actions block (`[ ⋮ ] [ ✕ Clear Form ] [ Save ]`). This 3-dots button **MUST ONLY appear on creation pages where the schema entity supports a `draft` lifecycle state** (e.g. `EmployeeCreate` for `EMPLOYMENT_STATUS = draft`, `OrgStructureCreate` for `ORG_STRUCTURE_STATE = draft`, `LeaveRequest`, `LeaveAllocation`, `OvertimeRequest`, `HeadcountBudget`). Clicking `[ ⋮ ]` opens a popup dropdown containing `"Save as Draft"`. Pages without draft in their schema enum omit this 3-dots button and display only `[ ✕ Clear Form ] [ Save ]`.
     - `✕ Clear Form`: Secondary outline button with `<X />` icon (resets form).
     - `Save`: Primary `#0B529C` brand-blue button (validates, compiles, and persists record).
2. **Top-Level Tabs (`<BaseTabs />`)**:
   - Capsule/Pill shaped tabs with active white elevated pill across top to switch between primary entity details and 1:N relations (e.g. `Party Details`, `Addresses`, `Dependents`, `Qualifications`, `Work Experience`, `Skills & Languages`).
3. **Master Creation Card (`border-radius: 16px`, `border: 1px solid #f1f5f9`)**:
   - **Profile Photo / Logo Section**:
     - 90px circular avatar with "No Media" fallback state (image icon + `#94a3b8` label).
     - `"Upload New Photo / Logo"` outline button connected to hidden file input.
     - Dimension advice text: *"At least 800×800 px recommended and size should be less than 10MB. JPG or PNG is allowed"*.
   - **Identification & Verification Row**:
     - Label: Primary identifier (e.g. `National ID`, `Fayda ID`, `Tax ID / TIN`).
     - Input field with green `<Check />` checkmark indicator when verified.
     - `"Verify ID"` action button.
     - Confirmation subtext: *"ID Verified Successfully."* in green (`#059669`).
   - **Entity Information Fields Grid**:
     - 3-column name grid (`First name`, `Middle name`, `Last name` for individuals) or entity name input (no placeholder text per Haleta ERP rule).
     - Contact row: Phone input with country code dropdown (`[ET ⌵] +251`) + Email input.
     - Demographics row: Gender dropdown (`placeholder="Select"`) + Date of Birth with `<Calendar />` prefix and `[GC]` badge suffix.
     - Extended domain fields (Place of Birth, Blood Group, Marital Status, Nationality Country, Nationality Type).
   - **Biography / Narrative WYSIWYG Editor**:
     - Label: `Biography` or `Entity Remarks`.
     - Rich text toolbar: Paragraph dropdown, Font Type dropdown, List dropdown, Bold, Italic, Underline, Strikethrough, Code, Table, Color, Link, Image, Undo, Redo.
     - Textarea body.
     - Footer character counter: dynamic `0 / 5,000 Characters`.
4. **Sub-Record Panels on Subsequent Tabs**:
   - Multi-record cards for adding 1:N child entities directly during creation.

