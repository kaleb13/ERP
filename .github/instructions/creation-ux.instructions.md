---
description: "Use when creating or editing ERP quick-create modals, dedicated creation pages, or form flows. Covers field-count decisions, data preservation, controls, and save actions."
---

# ERP Creation UX & Modal Standard Rule

This document defines the mandatory creation pattern across all modules (Human Resources, Procurement, Inventory, Sales, Company Setup) in Haleta ERP.

---

## 1. The Core Philosophy of Quick Create vs. Direct Create Form

### **Why Was Quick Create Needed?**
The Quick Create Modal exists to provide a high-velocity, frictionless entry path when an entity is **simple enough to be created with a small number of essential inputs (3 to 5 fields)**. Instead of burdening the user with ten, twelve, or more secondary parameters, policy flags, audit memo boxes, or validity windows upfront, the quick create modal captures *only* the minimum viable data needed to instantiate an operative record immediately. 

The user will find all remaining, secondary, specialized, and full inputs **once they expand the full form** via the **"Expand Full Form"** (`<Maximize2 />`) button.

### **When the Quick Create Modal is NOT Needed (Direct Page Rule)**
If an entity inherently requires **full information—such as several, ten, or more inputs, multi-stage configurations, statutory compliance profiles, or 1:N relational child lines—in order to even be created or operative, the quick modal is NOT needed at all.**
- In these scenarios, placing a quick modal creates an artificial, frustrating double-step for the user.
- Clicking the primary **"+ Create [Entity]"** button MUST **go straight to the dedicated creation page/route** (`[Entity]Create.vue`).

---

## 2. Schema Representation & Design Decision Matrix

Our schema interpretation directly dictates the creation architecture:

| Schema Characteristics | Creation Flow | UI Representation & Flow | Examples |
| :--- | :--- | :--- | :--- |
| **Simple Flat & Essential-Field Entities**<br>($\le 5$ required `NOT NULL` user fields, no mandatory child tables; optional overrides live in full form) | **Quick Create Modal**<br>(with "Expand Full Form") | Clicking `+ Create` opens `<QuickCreateModal />` with 3–5 core inputs. Bottom-left footer has **"Expand Full Form"** (`<Maximize2 />`) which navigates to `[Entity]Create.vue` passing already-typed values via `route.query`. | `ProcurementCategory`<br>`ProcurementApprovalRoute`<br>`ProcurementAssignmentRule`<br>`ProcurementCommitteeMandate`<br>`LeaveType`<br>`JobPosition`<br>`Customer`<br>`Warehouse` |
| **Comprehensive / Full Information Entities**<br>($> 5$ required inputs, multi-parameter tolerances, or multi-field dependencies required upfront) | **Direct Create Page**<br>(Immediate Route Navigation) | Clicking `+ Create` **bypasses any modal entirely** and navigates directly to `[Entity]Create.vue`. Form is laid out in a clean master card with collapsible cards for rich text descriptions. | `ReceiptToleranceRule`<br>`MatchingToleranceRule`<br>`LeavePolicy`<br>`WorkCalendar` |
| **Aggregate Roots with Child Schemas**<br>(1:N lines, threshold bands, rosters, committee members) | **Direct Tabular Create Page**<br>(Unified Master-Child Tabs) | Clicking `+ Create` navigates directly to `[Entity]Create.vue`. Tab 1 hosts master entity configuration; Tab 2+ hosts `<DynamicSubTable />` for child records with row expansion modal. | `PurchaseMethod` (+ Thresholds)<br>`ProcurementUnit` (+ Members)<br>`WorkShift` (+ Patterns)<br>`Employee` (+ Details) |

---

## 3. The Core Creation Rules ($\le 5$ vs. $> 5$ Required Fields)

Every entity creation flow MUST adhere to the following rule based on the number of required fields:

### **Case A: $\le 5$ Essential / Required Fields $\rightarrow$ Quick Create Modal (`<QuickCreateModal />`)**
When an entity can be created with 5 or fewer essential fields (e.g. Customer, Organization Unit, Job Title, Leave Type, Shift, Supplier, Product Group):
1. Clicking the **"+ Add / Create"** button MUST open a **`<QuickCreateModal />`**.
2. The modal presents only schema-backed essential fields (e.g. Name, Type, Primary Identifier). Do not add manual business-code inputs or lifecycle-state controls to create forms.
3. **No Notes/Descriptions in Quick Modals**: Descriptions, remarks, long texts, or note sections MUST NEVER appear in `<QuickCreateModal />`. They belong strictly in dedicated expanded full-form creation pages.
4. **"Save as draft" Prohibition in Quick Modals**: The "Save as draft" action will NEVER appear in a quick create modal. It is strictly reserved for expanded full creation pages.
5. **Footer Action Hierarchy:**
   - **Bottom-Left**: **"Expand Full Form"** styled as a **Secondary Button** (`<Maximize2 />` icon) $\rightarrow$ Navigates/switches to the dedicated full creation page/drawer, carrying over any already-typed state.
   - **Bottom-Right**: **"Save"** styled as the **Primary Button** (strictly plain text **"Save"**, **ZERO icons**) $\rightarrow$ Instantly validates, creates the record, adds it to the table/directory, and closes the modal. (Cancel button is omitted; modal dismisses via Esc/Close/Backdrop).

### **Case B: $> 5$ Required Fields or Full Information Required $\rightarrow$ Direct Page / Wizard Form**
When an entity fundamentally requires more than 5 complex inputs or full information (several, ten, or more inputs, 1:N relations, or statutory compliance profiles):
1. Clicking **"+ Add / Create"** goes **directly to the dedicated creation page/route** (e.g. `/procurement/methods/create`, `/procurement/units/create`, `/hr/employees/create`, `/stock-reservation/create`).
2. The modal is completely omitted.
3. The page utilizes a multi-step tabbed interface (`<BaseTabs />`) or clean form card with collapsible cards for notes (`<FormRichText />`).

---

## 2. Standardized Modal Component Reference: `<QuickCreateModal />`

Located at: `frontend/src/components/QuickCreateModal.vue`

### **Component API:**
```typescript
interface Props {
  show: boolean;                     // v-model:show
  title: string;                     // e.g. 'Create Customer'
  expandRoute?: string | object;     // Route for "Expand Full Form" (e.g. '/sales/customers/create')
  expandLabel?: string;              // Default: 'Expand Full Form'
  showExpandButton?: boolean;        // Default: true
  showExpand?: boolean;             // Backwards-compatible alias
  isOpen?: boolean;                 // Backwards-compatible visibility alias
  saveLabel?: string;                // Default: 'Save'
  cancelLabel?: string;              // Default: 'Cancel'
  loading?: boolean;                 // Spinner state
  disabled?: boolean;                // Disable save button
  width?: 'sm' | 'md' | 'lg';        // Modal width (default: 'md')
}

// Emits:
// - 'update:show': (value: boolean)
// - 'update:isOpen': (value: boolean)
// - 'save': ()
// - 'cancel': ()
// - 'close': ()
// - 'expand': ()
```

### **Template Implementation Structure:**
```html
<QuickCreateModal
  v-model:show="showQuickModal"
  title="Create Customer"
  expandRoute="/sales/customers/create"
  @save="handleQuickSave"
>
  <div class="form-grid">
    <FormInput v-model="quickForm.party_name" label="Party Name" required />
    <FormInput v-model="quickForm.phone" label="Phone Number" required />
    <FormSelect
      v-model="quickForm.group"
      label="Customer Group"
      placeholder="Select Group"
      :options="customerGroupOptions"
    />
    <FormCheckbox
      v-model="quickForm.is_walk_in"
      label="Walk-in Customer"
      description="Identify customers who purchase without a registered account."
    />
  </div>
</QuickCreateModal>
```

Use the shared `FormInput`, `FormSelect`, and `FormCheckbox` components shown above (import them where required). **Non-select inputs (`<FormInput />` text, number, and date fields) MUST NEVER have a `placeholder` attribute.** Select placeholders (`<FormSelect />`) must be concise and action-led: use `Select [core noun]`, not the full field label (for example, `Statutory Purchase Method` uses `Select Method`, and both `Category Scope` and `Buying Desk Scope` use `Select Scope`). Do not use explanatory text such as `All Categories (Global Scope)` as a form placeholder; use `All ...` prompts for filters only.

- **2-Column Input Pairs in Quick Create Modals**: When a `<QuickCreateModal />` has 2 inputs (for example, `Method Name` and `Minimum Quotations Required`), place them side-by-side in a single 2-column `.modal-grid-2` row rather than stacking a lone input in a half-empty row.

- **2-Column Checkbox Grid in Quick Create Modals**: When a `<QuickCreateModal />` contains 2 or more `<FormCheckbox />` controls, arrange them in a **2-column side-by-side grid** (`display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px;`) rather than stacking them in a single vertical column. If there is an odd number (e.g. 3 checkboxes), the first 2 sit side-by-side on row 1 and the 3rd wraps to row 2 left column (`2 + 1`). In Figma, mirror this with 2-column horizontal rows (`gap: 12px`) inside the `Policy Checkboxes` container.

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
   - **Strict Canvas Background**: The top bar (`.create-header-bar`, `.top-nav-bar`) MUST ALWAYS be transparent on the page canvas (`background: transparent; border: none; box-shadow: none; padding: 0;`). **NEVER** wrap the breadcrumbs and top actions in a white card box (`background-color: #ffffff; border: 1px solid #e5e5e5; border-radius: 12px; padding: 14px 24px;`).
   - Breadcrumbs: `[Monitor Root Icon] > [Module / Directory Link] > Create [Entity]`.
   - Save state: use `<SaveStateBadge />` and let the shared `SaveStateBadge` / `BaseBadge` components control status text and colors. Do not recreate the badge with ad-hoc markup or hardcoded colors.
   - Right Actions:
     - **Dynamic 3-Dots More Menu `[ ⋮ ]`**: Placed on the far left of the actions block (`[ ⋮ ] [ ✕ Clear Form ] [ Save ]`). This 3-dots button **MUST ONLY appear on creation pages where the schema entity supports a `draft` lifecycle state** (e.g. `EmployeeCreate` for `EMPLOYMENT_STATUS = draft`, `OrgStructureCreate` for `ORG_STRUCTURE_STATE = draft`, `LeaveRequest`, `LeaveAllocation`, `OvertimeRequest`, `HeadcountBudget`). Clicking `[ ⋮ ]` opens a popup dropdown containing `"Save as Draft"`. Pages without draft in their schema enum omit this 3-dots button and display only `[ ✕ Clear Form ] [ Save ]`.
     - `✕ Clear Form`: Secondary outline button with `<X />` icon (resets form).
     - `Save`: Primary `#0B529C` brand-blue button (validates, compiles, and persists record).
2. **Top-Level Tabs (`<BaseTabs />`)**:
   - Capsule/Pill shaped tabs with active white elevated pill across top to switch between primary entity details and 1:N relations (e.g. `Party Details`, `Addresses`, `Dependents`, `Qualifications`, `Work Experience`, `Skills & Languages`).
3. **Master Creation Card (`border-radius: 16px`, `border: 1px solid #f1f5f9`)**: Include only identity and profile fields required by this entity's domain and schema. The Party/individual identity example below is not a universal template for other entities.
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
     - Rich-text editing surface (not a plain textarea).
     - Footer character counter: dynamic `0 / 5,000 Characters`.
4. **Sub-Record Panels on Subsequent Tabs (Strict Tabular Separation Standard)**:
   - **Never Stack on Same Scrollable Page**: When an entity includes related lines, child schemas, or 1:N associations (e.g. `ProcurementUnitMember` lines for a `ProcurementUnit`, purchase order lines, committee members, addresses, qualifications), **THEY MUST NEVER BE RENDERED ON THE SAME PAGE AS THE MASTER FORM CARD**. Stacking child tables below master forms on a single page degrades UX and breaks our design system.
   - **Mandatory Dedicated Tabs (`<BaseTabs />`)**: All child line tables and related sub-schemas MUST be isolated into their own dedicated tabs using the primary capsule `<BaseTabs />`.
     - **Tab 1**: Master entity information & parameters (`[Entity] Details`).
     - **Tab 2+**: Related lines, child rosters, or line item tables (`[Line/Member] Roster` using `<DynamicSubTable />`).
   - **Reactive Tab Counters**: Subsequent tab labels must display reactive item counts (e.g. `Unit Members (3)`, `Addresses (2)`).
   - **Validation Route-Back**: If the user clicks "Save" while on a sub-record tab and master fields in Tab 1 fail validation, the system MUST automatically switch `activeTab` back to Tab 1 and display the validation toasts/errors.
   - **Mandatory Default 1-Row Initial State**: In every dynamic child table tab (`<DynamicSubTable />`), the initial design state MUST NEVER be blank or empty (`[]`). Always provide at least **one pre-populated default row** (`defaultInitialRow: true`) so that column definitions, interactive cell inputs, action buttons, and table alignments are immediately visible and testable, directly mirroring the Figma design representation.
   - **Zero Raw Browser Selects**: All dropdowns, options, and filter pickers across master cards, modal dialogs, and dynamic tables MUST use `<FormSelect>` or teleported QMT dropdown popovers. Never use raw HTML `<select>` elements.

---

## 5. Dedicated Rich Text Description Cards & Dynamic Table Container Invariants

- **Zero "Solutionary Explanations" in Form Sections**: Creation form cards and blueprint specification sections must NEVER include verbose, multi-sentence narrative banners or redundant section headers (e.g. `.config-header`). Form cards must remain clean, focused, and immediately actionable.
- **Dedicated Collapsible Rich Text Description Card (Zero Sharp Edges)**:
  - **Zero `<textarea>` in Master Card**: Operational narratives, statutory guidelines, procedural notes, and descriptions MUST NEVER be placed as a `<textarea>` or `<FormTextarea>` inside the master parameters grid card.
  - **Separate Collapsible Card**: Place inside `<div class="clean-card accordion-card">` positioned beneath the master card, rendered strictly with `<FormRichText v-model="form.description" />`.
  - **Single Explanatory Title (No Stacked Title + Subtitle)**: The header `.card-accordion-header` MUST declare a single, concise, explanatory title (e.g., `<span>Description</span>`, `<span>Mandate Guidelines</span>`, `<span>Routing Rationale</span>`) directly beside the chevron. NEVER stack a title and secondary description/subtitle inside the accordion header.
  - **Zero Label on `<FormRichText />`**: Inside the accordion body, `<FormRichText />` MUST NOT have a `label` prop. The collapsible header title already identifies the section; adding a label on the rich text editor causes redundant double labeling. Use `placeholder="..."` for input instructions.
  - **Mandatory `overflow: hidden`**: Both `.clean-card` and `.clean-card.accordion-card` MUST have `overflow: hidden; border-radius: 12px;`. The header `.card-accordion-header` and body `.card-accordion-body` must explicitly respect and clip to this border radius (via `overflow: hidden` and `border-radius: inherit`) so child element backgrounds NEVER bleed past card boundaries or create square 90° corners when open or collapsed.
- **Dynamic SubTable Inset & Scanning Column Invariants**:
  - **3 to 5 Scanning Columns Only**: Inline dynamic tables (`<DynamicSubTable />`) must ONLY display 3 to 5 mandatory scanning attributes. Secondary/scope attributes (e.g. scopes, units, categories, validity dates) belong inside the `#expand-modal` slot (`<DynamicTableModal>`).
  - **Mandatory 24px Container Padding**: Cards hosting `<DynamicSubTable />` MUST have `padding: 24px; display: flex; flex-direction: column; gap: 16px;`. NEVER wrap `<DynamicSubTable />` in a zero-padding wrapper (`.subtable-body { padding: 0 }`).
- **Subtle Hints Only**: Where a field or subsection genuinely requires explanation, use a concise, single-line explanation (e.g. `hint="..."` or `.card-plain-desc`), never multi-sentence instructional paragraphs.

---

## 6. No Governance / Status Lookups in Create Forms (`status_lookup_value_id`)

- **Never Expose Status / Governance Scope on Create Forms**: Schema status lookup fields (`status` / `status_lookup_value_id`, e.g., `Governance Sharing Scope`: `Approved for All Entities`, `Approved for This Entity Only`, `Pending Approval`, `Rejected`) are workflow/review-stage states, **NOT** creation inputs.
- **Applies to Both ERP Code & Figma**: Do NOT render `Governance Sharing Scope` or any `status_lookup_value_id` selector in `<QuickCreateModal />` or dedicated `[Entity]Create.vue` pages (nor in their Figma counterparts). New records default to their initial workflow status (`pending`) on save.

---

## 7. Conditional Expandable Checkbox Cards (`<FormCheckboxCard />`)

**Component**: `frontend/src/components/FormCheckboxCard.vue`  
**Figma Reference**: `10415:37682` (Collapsed) & `10415:37687` (Expanded) in `Haleta-ERP---Procurement-Module`.

### When to Use
Use `<FormCheckboxCard />` whenever a checkbox controls whether one or more dependent input fields are active or omitted:
1. **Nullable Limit / Sentinel Columns** (e.g., `minimum_amount` with *"No Minimum Floor"*, `maximum_amount` with *"Unlimited / Open Ceiling"*, `authority_ceiling`, `effective_to`):
   - Set `:expand-when-checked="false"` (inverted):
     - **Checked = Collapsed** (`#FAFAFA` primary background + `1px solid #E5E5E5` subtle border) $\rightarrow$ field is omitted (`null`).
     - **Unchecked = Expanded** (`#FFFFFF` card white background + `1px solid #E5E5E5` subtle border) $\rightarrow$ reveals the nested input(s) cleanly inside the card.
2. **Boolean-Gated Feature Columns** (e.g., `requires_guarantee` revealing guarantee percentage/type, `auto_match_enabled` revealing variance limits):
   - Keep `:expand-when-checked="true"` *(default)*:
     - **Unchecked = Collapsed** (`#FAFAFA` + `#E5E5E5`).
     - **Checked = Expanded** (`#FFFFFF` + `#E5E5E5`) $\rightarrow$ reveals the nested input(s).

### Visual Contract (Strict QMT Tokens)
- **Collapsed State**: `background-color: #FAFAFA;` (`var(--alias-color-background-primary)`), `border: 1px solid #E5E5E5;`, `border-radius: 12px;`, `padding: 16px;`.
- **Expanded State**: `background-color: #FFFFFF;` (matches the white card surface behind it), `border: 1px solid #E5E5E5;`, `border-radius: 12px;`, clean `16px` vertical gap between the checkbox header and the slot inputs (NO internal horizontal divider line).
- **Anti-Pattern**: ❌ Never leave disabled `<FormInput :disabled="..." />` fields sitting detached above or beside a separate checkbox row when `<FormCheckboxCard />` can encapsulate them.

### Template Example
```html
<div class="checkbox-cards-grid">
  <FormCheckboxCard
    v-model="form.no_floor"
    :expand-when-checked="false"
    label="No Minimum Floor"
    description="Mandate applies starting from any event value with no lower threshold."
  >
    <FormInput
      v-model.number="form.minimum_amount"
      type="number"
      label="Minimum Event Value (ETB)"
      :error="fieldErrors.minimum_amount"
      required
    />
  </FormCheckboxCard>

  <FormCheckboxCard
    v-model="form.is_unlimited"
    :expand-when-checked="false"
    label="Unlimited / Open Ceiling"
    description="Mandate covers all event values at or above the floor with no upper limit."
  >
    <FormInput
      v-model.number="form.maximum_amount"
      type="number"
      label="Maximum Event Value (ETB)"
      :error="fieldErrors.maximum_amount"
      required
    />
  </FormCheckboxCard>
</div>
```
