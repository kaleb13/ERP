# Haleta ERP — Engineering & UI Architecture Guidelines

## 1. Tab System Standard
- **Primary Tab**: `<BaseTabs />` (`src/components/BaseTabs.vue`) — Capsule/Pill shape container with white elevated active pill. Used for all Top-level creation forms and page switchers.
- **Secondary Tab**: `<UnderlineTabs />` (`src/components/UnderlineTabs.vue`) — Underline border-bottom with active brand-blue `#0B529C` indicator and count badges. Used for all sub-sections, matrices, and filter views.
- **Rule**: No other tab designs or raw HTML `<button class="tab-btn">` are permitted.

## 2. KPI / Metrics Card Standard
- **Component**: `<MetricCard />` (`src/components/MetricCard.vue`).
- **Typography & Colors**:
  - Top Label: `#737373`, Medium (`500`), `12.5px`.
  - Main Number (Value): `#404040`, Semi-Bold (`600`), `24px`.
  - Bottom Subtext: `#737373`, Medium (`500`), `12px`.
  - Padding: `15px 18px`, Min-height `106px`.

## 3. Breadcrumb Navigation Standard
- **Component**: `<AppBreadcrumb />` (`src/components/AppBreadcrumb.vue`).
- **Rule 1: Desktop/Monitor Root Navigation**: The root Desktop/Monitor icon MUST always navigate to the Home page (`/home`).
- **Rule 2: ZERO Sidebar Section Titles**:
  - Sidebar group headers and category section titles (e.g. `Job Architecture`, `Job & Position Architecture`, `Organization & Structure`, `Workforce & Profile`, `Compensation & Pay`) **MUST NEVER appear in the breadcrumb trail**.
  - Crumb items represent reachable pages, never navigational grouping headers.
- **Rule 3: First Navigation Breadcrumb = Exact Sidebar Page Name Only**:
  - When navigating to any primary page/directory, the breadcrumb trail MUST consist of strictly **the root Monitor icon and the exact Page Name as written in the sidebar** — nothing else.
  - Correct Examples on Directory/Listing Pages:
    - `[Monitor] > Headcount Budgets` (NOT `[Monitor] > Job Architecture > Headcount & Position Budgets`)
    - `[Monitor] > Job Positions` (NOT `[Monitor] > Job Architecture > Job Positions`)
    - `[Monitor] > Job Titles & Roles` (NOT `[Monitor] > Job Architecture > Job Titles`)
    - `[Monitor] > Job Levels`
    - `[Monitor] > Org Structures` (NOT `[Monitor] > Organization > Organization Structures`)
    - `[Monitor] > Organization Units`
    - `[Monitor] > Salary Scales`
    - `[Monitor] > Salary Matrices`
    - `[Monitor] > Employee Directory`
- **Rule 4: Child Page Breadcrumb (If and Only If Inside a Sub-page)**:
  - If and ONLY if the user navigates into an expanded full creation page (`.../create`), a detail profile view, or an inspection mode, a subsequent crumb appears:
    - Expanded Creation Pages: `[Monitor] > [Parent Page Name] > Create [Entity]`
      - e.g. `[Monitor] > Headcount Budgets > Create Headcount Budget`
      - e.g. `[Monitor] > Job Positions > Create Job Position`
      - e.g. `[Monitor] > Job Titles & Roles > Create Job Title`
      - e.g. `[Monitor] > Org Structures > Create Org Structure`
      - e.g. `[Monitor] > Salary Scales > Create Salary Scale`
      - e.g. `[Monitor] > Employee Directory > Create Employee`
    - Detail & Profile Views: `[Monitor] > [Parent Page Name] > [Entity Identifier / Name]`
      - e.g. `[Monitor] > Salary Scales > Haleta Addis Ababa`
      - e.g. `[Monitor] > Employee Directory > EMP-001 - Abebe Kebede`
      - e.g. `[Monitor] > Organization Units > Human Resources`
      - e.g. `[Monitor] > Org Structures > Corporate 2027`

## 4. Creation Flow Standard (<= 5 vs. > 5 Required Fields)
- **Entities with <= 5 Required Fields**: Clicking "+ Add / Create" MUST open `<QuickCreateModal />` (`src/components/QuickCreateModal.vue`) featuring:
  - **Header**: Title ONLY (no descriptions/subtitles) and **NO bottom divider line** (`#404040`, `18px`, semi-bold `600`).
  - **Bottom-Left**: "Expand Full Form" as a **Secondary Button** (`<Maximize2 />`).
  - **Bottom-Right**: "Save" as the **Primary Button** (Cancel button is omitted; modal dismisses via Esc/Close/Backdrop).
- **Entities with > 5 Required Fields**: Clicking "+ Add / Create" navigates directly to the dedicated creation page/wizard.
- **Dedicated Full Creation Page Architecture (Expand Full Form Flow)**:
  - **Entity Domain Naming Rule**: Always name pages, breadcrumbs, tabs, and form blocks using the exact entity domain name (e.g. `Party`, `Party Details`, `Create Party`, `Party Information`, `Create Customer`). **NEVER** use generic terms like `User` or `User Details` because a Party represents either an individual person or an organization/company.
  - When "Expand Full Form" is clicked from `<QuickCreateModal />`, navigate to the dedicated creation route (e.g. `/hr/parties/create`), preserving any typed values via route query.
  - **Top Bar**: Breadcrumbs (`[Monitor] > Entity Management > Create [Entity]`) + `Not Saved` / `Saved` status pill + Right Actions:
    - **Dynamic 3-Dots More Menu `[ ⋮ ]`**: Placed on the far left of the actions block (`[ ⋮ ] [ ✕ Clear Form ] [ Save ]`). This 3-dots button **MUST ONLY appear on creation pages where the schema entity supports a `draft` lifecycle state** (e.g., `EmployeeCreate` for `EMPLOYMENT_STATUS = draft`, `OrgStructureCreate` for `ORG_STRUCTURE_STATE = draft`, `LeaveRequest`, `LeaveAllocation`, `OvertimeRequest`, `HeadcountBudget`). Clicking `[ ⋮ ]` opens a popup dropdown containing `"Save as Draft"`. Pages without draft in their schema enum omit this 3-dots button and display only `[ ✕ Clear Form ] [ Save ]`.
    - `✕ Clear Form` secondary button + `Save` primary blue `#0B529C` button.
  - **Top Tabs**: `<BaseTabs />` capsule pills across top for switching between primary details and 1:N relations (e.g. `Party Details`, `Addresses`, `Dependents`, `Qualifications`, `Work Experience`, `Skills & Languages`).
  - **Master Creation Card**:
    - Avatar / Logo circular preview (90px diameter with "No Media" fallback state) + "Upload New Photo / Logo" button + resolution advice text.
    - Identification / Verification row (e.g., National ID or Tax ID) with inline green checkmark and "Verify ID" button + "ID Verified Successfully." subtext.
    - 3-column name grid (`First name`, `Middle name`, `Last name` for individuals) or entity title.
    - Phone input with country code dropdown (`[ET ⌵] +251`) + Email.
    - Gender select + Date of Birth with `[GC]` calendar badge.
    - Extended demographics (Town of Birth, Blood Group, Marital Status, Nationality Country, Nationality Type).
    - Biography / Description WYSIWYG rich text editor with toolbar and 5,000 character counter.
- **Rule**: Documented in `.agents/rules/creation_ux_flow_rule.md`.

## 5. Input Field & Form Control Standard
- **Components**: `<FormInput />`, `<FormSelect />`, `<FormCheckbox />`, `<FormTextarea />` (`src/components/`).
- **Input / Select Height**: Compact `38px` (`height: 38px`, `padding: 0 12px`).
- **Font Size**: `13.5px` (clean readable proportions, not oversized 15px/16px).
- **Border & Radius**: `1px solid #e2e8f0`, `border-radius: 8px`.
- **Focus State**: `border-color: #0B529C`, `box-shadow: 0 0 0 3px rgba(11, 82, 156, 0.08)`.
- **Form Label**: `12.5px`, Medium (`font-weight: 500`), `#404040`, `margin-bottom: 3px` to `4px` (compact gap to input).
- **Placeholder Rule**: **Text inputs (`<FormInput />`, `<input>`, `<textarea>`) MUST NEVER contain placeholder text.** ONLY dropdown selections (`<FormSelect />`) display a placeholder saying `"Select"`.
- **Boolean & Checkbox Standard**: **All form booleans, toggles, and modal flags MUST use `<FormCheckbox />` with BOTH a clear Title (`label`) and an explanatory business Description (`description`).** (For example: explaining what designating an address as primary or a dependent as eligible accomplishes). Standalone or bare checkboxes without description text are strictly prohibited in creation forms, sub-tables, and expansion modals.
- **Contextual Input Hint Text Standard (Strict Selectivity & Zero Redundancy)**:
  - **Selective Ambiguity Only**: **NEVER put hint text on self-evident, simple, or clear inputs** (such as standard date pickers like `Approval Date`, `Effective From / Until Date`, `Date of Birth`, or basic selectors like `Gender`, `Currency`, `Owning Entity`, `Organization Unit`, standard names, phones, or emails). Blanket or indiscriminate hint placement creates silly visual clutter and is strictly prohibited.
  - **When to Use**: Reserve hint text **strictly and exclusively** for inputs that might genuinely confuse the user or require specific formatting guidance (e.g. `Fiscal Year` requiring statutory format context like `2026/27 or 2026`, specific quota ceilings vs limits, statutory tax identifiers, or non-obvious business calculations). Most form fields MUST remain clean without any hint text.
  - **Component Support**: Use `:hint="..."` on `<FormInput />` and `<FormSelect />`, or `<p class="field-hint-text">...</p>` below custom inputs when genuinely warranted.
  - **Typography & Color**: `font-size: 11.5px`, `color: #737373` (`--alias-color-text-tertiary`), `line-height: 1.4` to `1.45`, `margin-top: 4px` (or `2px` inside compact wrappers).
  - **Content Rule**: When used, hint text must be concise, crisp, and directly clarify the ambiguous aspect. Never use filler or developer jargon.

## 6. Button & Corner Radius Standard
- **Buttons (Primary, Secondary, Action, Modal buttons)**: MUST have a **well-rounded rectangle shape** (`border-radius: 8px` to `10px`).
- **Tabs**: **ONLY Primary Tabs (`<BaseTabs />`)** use the 100% fully rounded capsule/pill shape (`border-radius: 30px`).
- **Rule**: Buttons are NEVER fully rounded pills. They must strictly maintain the well-rounded rectangular shape (`8px` - `10px`).

## 7. Global Dark Text Standard
- **Primary Dark Color**: **`#404040`** (`--alias-color-text-dark`, `--primitive-color-neutral-700`).
- **Rule**: Pure black (`#000` / `#000000`) must NOT be used. All dark text, form labels, and headings use `#404040`.

## 8. Table Cell & Row Height Standard
- **Component**: `<BaseTable />` / `<AppDataTable />` (`.erp-table`).
- **Data Cell (`<td>`)**: Compact `38px` height (`padding: 8px 16px`), `font-size: 13px`, text color `#404040`.
- **Header Cell (`<th>`)**: `34px` height (`padding: 8px 16px`), `font-size: 12px`, `#737373`, `#fafafa` background.
- **Action Buttons (`.btn-action-dots`)**: `28px x 28px`, `border-radius: 6px`.
- **Status Pills (`.status-pill`)**: `padding: 2px 10px`, `font-size: 11.5px`.

## 9. Table Column Architecture & Single-Information Standard
- **Rule 1: Atomic Columns (One Column = One Information)**:
  - Table columns MUST be strictly atomic. **NEVER combine distinct or unrelated data attributes** (such as grouping age, gender, blood group, or marital status under a generic "Demographics" column, or grouping nationality and country under "Nationality & Status", or grouping birth date and birth place).
  - Every individual data attribute MUST have its own dedicated column (e.g., `Gender`, `Phone`, `Email`, `Marital Status`, `Blood Group`, `Date of Birth`, `Country`).
  - A single column cell may ONLY contain multiple values **if and only if** that specific field itself is a multi-item collection of the same data type (e.g. an array of phone numbers, multiple role badges, or a list of tags).
- **Rule 2: Minimalist Default View & Column Hider Standard**:
  - Default table views MUST be minimalist, clean, and uncluttered. Show ONLY the essential 4 to 6 columns needed for immediate recognition and primary workflows (typically: `Identity`, `Gender`/`Type`, primary identifier/contact like `Phone` or `Fayda ID`, `State`, and `Actions`).
  - All secondary, supplemental, or detailed data attributes MUST be defined in the component's `columns` array with `visible: false` by default. Users can selectively toggle them on demand using the Column Hider dropdown menu (`<Columns />`).
- **Rule 3: Mandatory Component Usage**:
  - **ALWAYS** use `<AppDataTable />` (`src/components/AppDataTable.vue`) or `<BaseTable />` (`src/components/BaseTable.vue`) for all data tables.
  - Wire `:columns="tableColumns"` and `@toggleColumn="handleToggleColumn"` to properly support column hiding.
  - **NEVER** build custom, ad-hoc table toolbars or bypass the standard component controls.
- **Rule 4: Zero Standalone "Code" Column & Mandatory Name-First Order**:
  - `Code` MUST NEVER have its own standalone column in tables.
  - The first data column immediately following selection checkboxes MUST always be the **Name** column.
  - If the code is important enough to display, write the Name on top and Code at the bottom as sub-text (`<span class="table-name-primary">{{ item.name }}</span><span class="table-code-subtext">{{ item.code }}</span>`). If not that important, omit code entirely.
- **Rule 5: Table Text Color Hierarchy (Secondary for Name, Tertiary for Right Columns)**:
  - The first data column (the Name column) MUST be styled in the **Secondary Color** (`#404040` / `--alias-color-text-secondary`, font-weight `500` or `600`).
  - ALL texts in all subsequent columns to the right MUST strictly be styled in the **Tertiary Color** (`#737373` / `--alias-color-text-tertiary` / `--primitive-color-neutral-500`), NOT the secondary color.
  - This ensures a crisp scanning hierarchy where the primary entity stands out clearly, while all secondary details (entities, dates, parents, counts, metadata) recede harmoniously.
- **Rule 6: Strict Anti-Badge Standard (Plain Text Default)**:
  - Table data cells MUST default to clean, readable plain text in tertiary color (`#737373`).
  - **NEVER** wrap regular content (such as counts like `16 Units`, entity types like `Department`, categories, or codes) in decorative badge containers, colored tags, or pills.
  - **Badges/Pills are strictly reserved for lifecycle status and states** (e.g. `Active`, `Inactive`, `Draft`, `Pending`), and even then, only if genuinely needed. If the information can simply be written as clear content, write it as plain text without badges.
- **Rule 7: Zero Extraneous Decorative Icons in Table Cells**:
  - Table data cells MUST NOT contain decorative or redundant icons (e.g., building icons before entity names, layer icons before unit counts, folder icons before types, calendar icons in date cells).
  - Icons in table listings are permitted ONLY when strictly functional (e.g., sort arrows in headers, 3-dots action dropdown buttons, row selection checkboxes, or expandable row chevrons).
- **Rule 8: Cross-Entity Reference Standard (Zero Foreign Avatars in Middle Columns)**:
  - When a table row references an external or linked entity (e.g., a Current Manager, Unit Head, Approver, or Owning Entity):
    - **NEVER** render an avatar image, thumbnail, employee ID, or compound profile card inside middle columns of a table.
    - Avatars belong **exclusively** on the far-left primary identity column of that entity's *own* primary directory table (e.g., in `EmployeesView.vue`).
    - In referencing tables, simply render the plain text name of the person or entity in the tertiary color (`#737373`).
    - Deep details (photo, ID, job title) are inspected on-demand by clicking into the detail view.
- **Rule 9: Strict Separation of "State" vs "Status" & Absolute Prohibition of Active/Inactive on Status Columns**:
  - `Active` and `Inactive` are strictly and exclusively reserved for the **State** column (`state`).
  - The **Status** column (lifecycle, employment status, approval status, etc.) MUST NEVER display "Active" or "Inactive" badges.
  - When the underlying database schema defines `active` as an enum/lookup value for a status column (e.g. `EMPLOYMENT_STATUS = active`), the UI MUST map it to a domain-appropriate business term (e.g. `In Service` for staff/employees, `Approved` for governance, `Published` / `Current` for versioned blueprints), keeping `Active` and `Inactive` solely on `State`.

## 10. Entity Directory Page & Table Header Architecture Standard
- **Rule 1: Unified Table Card Layout (No Redundant Outer Headers / Metrics)**:
  - Standard entity management/directory pages (Parties, Customers, Suppliers, etc.) MUST consist of: **Breadcrumb Navigation -> Single Table Card (`<AppDataTable />`)**.
  - **NEVER** render an outer `<h1>` title row, subtitle, or external action buttons above the table card.
  - **NEVER** render unrequested KPI / Metric cards above directory tables.
  - The entity title (`Party Management`) and rich multi-line explanatory description MUST be placed **inside** `<AppDataTable title="..." subtitle="...">`.
- **Rule 2: Primary Action Inside Table Toolbar**:
  - The primary create action (`+ Create [Entity]`) MUST reside inside the table toolbar's `#actions` slot on the top right.
- **Rule 3: Master-to-Detail Navigation (Never use Top-Level Tabs)**:
  - **NEVER** use `<BaseTabs />` to toggle between a Directory list table and a Detail profile view.
  - The table view is the canonical, default page view.
  - Detail profile views are accessed on-demand when the user clicks a row or selects "View Details" from the action menu.
  - When in Detail view, provide clear back navigation (`← Back to [Entities]` button and clickable breadcrumbs).
- **Rule 4: Standard Row Layout & Identity Cell**:
  - Selection Checkbox: Include row selection checkboxes with select-all header.
  - Name Column: Circular avatar + Full Name in bold + Email / Subtitle underneath (or `-`).
  - State Column: Sortable header (`State ↓`) with rounded status pills (`Active` in green tint `#ecfdf5`/`#059669`, `Inactive` in neutral gray tint `#f1f5f9`/`#64748b`).
- **Rule 5: Strict Data Isolation in Detail Views (Zero Cross-Entity Switchers)**:
  - Once navigated into the Detail view of a specific entity, that page MUST be strictly isolated and dedicated **exclusively** to the selected entity.
  - **NEVER** render quick-switch tabs, horizontal pill strips, carousels, or multi-user selectors listing other database records across the top of a detail page.
  - To switch to another entity, the user must navigate back to the canonical directory table via `← Back to [Entities]` or clickable breadcrumbs.

## 11. Dynamic Child Sub-Tables (Mandatory Default Pattern)
- **Mandatory Default for 1:N Relations**: Dynamic child sub-tables are the primary and mandatory pattern for standard 1:N relations (e.g., Allowances / Compensation Components, Bank Accounts, Academic Qualifications, Professional Certifications, Prior Work Experience, Technical Skills, Spoken Languages, Dependents, Emergency Contacts).
- **Rule 1: Minimalist Inline Child Tables (High-Frequency Scanning Columns Only)**:
  - Dynamic child sub-tables MUST show ONLY the essential 3 to 5 core columns necessary for fast visual scanning and rapid primary entry.
  - Secondary attributes, line-level effectivity dates, detailed descriptions, attachments, notes, and internal override rules MUST NOT crowd the inline table row. They belong strictly inside the Expand Row modal (`<Expand />`).
- **Rule 2: Child Table Toolbar & Selection**:
  - Provide select-all header checkboxes (`child-th-check`) and row selection checkboxes (`table-checkbox`).
  - Row numbering column (`child-th-no`) with sequential index (`idx + 1`).
  - Action column (`child-th-col-icon`) with 14px `<Expand />` action button per row.
  - Clear `+ Add [Record]` action button below table (`.btn-add-row`).
- **Rule 3: Floating Batch Action Bar**:
  - When rows are selected, render `<TableFloatingBar :count="selectedCount" @delete="handleBatchDelete" />` anchored at the bottom of the viewport for instantaneous batch actions.

## 12. Stacked Card Repeater Pattern (Alternative for High-Complexity / Hierarchical Entities)
- **When to Use**: When a repeatable 1:N entity possesses high layout complexity, deep cascading dropdown dependencies, multiple sub-groupings, or multi-line business notes that cannot cleanly fit into a flat inline horizontal table row without severe UX degradation (e.g. `Address` with Country ➔ Region ➔ Zone ➔ Woreda ➔ Kebele, House Number, Street, Postal Code, and statutory tax routing descriptions).
- **Structure & Layout Standard**:
  - **Outer Container**: Stack of distinct cards (`.address-cards-stack`) inside the accordion section (`.clean-card`).
  - **Card Header**:
    - **Pill Badge (Top-Left)**: Soft blue pill badge (`.address-card-badge`, e.g. `Address 1`, `Address 2`) with `#e0f2fe` background, `#0284c7` text, `border-radius: 9999px`, padding `3px 12px`, font-size `12px`, font-weight `500`.
    - **Delete Button (Top-Right)**: Outline trash can icon button (`<Trash2 :size="16" />`) with `#94a3b8` color and `#ef4444` hover state.
  - **Form Grid Inside Card**:
    - Clean 3-column responsive grid (`grid-template-columns: repeat(3, minmax(0, 1fr))`, collapses to 1 column on mobile).
    - Compact 38px inputs and selects with 8px radius and `#404040` text.
    - Zero placeholder on text inputs; contextual `Select [Context]` (e.g. `Select Type`, `Select Country`, `Select Region`) on dropdowns.
    - Contextual helper hints (e.g. *"Used for legal address records and official correspondence."*) in `#737373`, 11.5px.
  - **Standalone Checkbox Row (Bottom of Card)**:
    - Always use `<FormCheckbox />` with BOTH Title and Description (e.g. `Primary Address` with explanation of legal domicile and tax remittance routing).
  - **Add Action Button (Below Stack)**:
    - `+ Add [Entity]` button (`.btn-add-address-card`) with 8px radius, white background, 1px `#e2e8f0` border, `#404040` text, and `Plus` icon.
  - **Empty State**:
    - If all items are deleted, render a clean dashed empty container (`.address-empty-state`) with guiding text and the Add button.

## 13. Exact Location & Administrative Geography Standard
- **Rule 1: Human-Centric Terminology (Zero Database Jargon)**:
  - **NEVER** use database column names or developer jargon like `Admin Unit` in user-facing UI, table headers, breadcrumbs, or modals.
  - **ALWAYS** use clear, human-friendly labels: `Exact Location`, `Exact Location (Region & Sub-City)`, or specific domain field names (`Address`, `Country`, `Region`, `Zone`, `Woreda`, `Kebele`).
- **Rule 2: Cascading Geographic Hierarchy**:
  - Standard hierarchy: `Country ➔ Region / Chartered City ➔ Zone / Sub-City ➔ Woreda / District ➔ Kebele`.
  - Upstream changes reactively reset and repopulate downstream dependent dropdowns (e.g., selecting `Ethiopia` sets regions; selecting `Addis Ababa` populates its 11 municipal sub-cities; selecting `Bole Sub-City` populates Woredas 01–14).
- **Rule 3: Schema Synchronization & Composite Synthesis**:
  - Automatically synthesize the composite geographic hierarchy into the schema's foreign key / representation (`admin_unit = 'Region > Zone > Woreda > Kebele'`) so database payloads, profile mini-tables, and directory listings stay 100% in sync without schema deviation.

## 14. Strict Schema Alignment & The Authoritative Role of the Database Schema
- **Rule 1: Schema is the Law (`HR_Schema_final-v4.sql`)**:
  - Every form input, select option, sub-table column, and card attribute MUST map directly to an actual database column in the authoritative schema.
- **Rule 2: ZERO Phantom Fields**:
  - NEVER invent fictitious attributes (e.g. arbitrary `notes`, `internal_remarks`, `temp_status`, `card_details`) where no corresponding column exists in the database schema.
- **Rule 3: Strict Data Minimization & Anti-Bloat**:
  - When pulling data from parent or related entities (e.g. importing Party records into Employee, or linking Party to Dependents / Beneficiaries), bring ONLY high-value essential business fields (e.g. Full Name, Primary Phone, ID, Birth Date, Relationship).
  - Omit redundant or non-essential fields (such as secondary telephone, secondary email, or arbitrary remarks) unless explicitly mandated by business workflow.
- **Rule 4: Zero Lifecycle `state` / Status in Creation Forms & Sub-Tables**:
  - Entities and child records created in a creation form/modal are active by definition.
  - Lifecycle state selectors (`state`, `status`, `Active / Inactive` toggles) MUST NEVER appear on create forms, child table rows, child cards, or child expansion modals. State belongs exclusively to directory listings, detail profile views, edit pages, and explicit workflow transitions.
- **Rule 5: Professional Enterprise Context & Clean Hint Text**:
  - Tooltips, subtexts, and helper hints must provide clean, professional business context.
  - NEVER include developer-centric or schema internal references (such as database table names, foreign keys, or line numbers like "Line 2284") in user-facing helper text.
- **Rule 6: Strict Placeholder Compliance on Inputs**:
  - Reiterate Rule 5: Text inputs (`<FormInput />`, `<input>`, `<textarea>`) MUST NEVER contain placeholder text. ONLY dropdown selections (`<FormSelect />`, `<FormCombobox />`, `<select>`) display a placeholder saying `"Select"` or contextual `"Select [Entity]"`.

## 15. The Canonical Three-View Architecture (Golden Triad)
Every core business domain in Haleta ERP is structured around three canonical, complementary views:
- **1. Directory / Listing View** (e.g., `EmployeesView.vue`, `PartiesView.vue`):
  - **Single Table Card**: Layout consists strictly of `Breadcrumb Navigation ➔ Single Table Card (<AppDataTable />)`. No redundant outer `<h1>` title row, subtitle, or unrequested KPI cards.
  - **Toolbar**: Contains Search, Filters, Column Hider (`<Columns />`), and Primary Action (`+ Create [Entity]`) in `#actions` slot.
  - **Atomic Columns**: One column = one information point. Minimalist default view showing only essential 4–6 columns; secondary columns toggleable via Column Hider.
- **2. Master Dedicated Creation Page** (e.g., `EmployeeCreate.vue`, `PartyCreate.vue`):
  - **Top Bar**: Breadcrumbs (`[Monitor] > Domain > Create [Entity]`) + Status indicator (`Not Saved` / `Saved`) + Right Actions (`✕ Clear Form` + `Save` primary button).
  - **Top Navigation**: `<BaseTabs />` capsule pills across top for switching between primary domain tabs.
  - **Master Identity Card**: Avatar / Logo circular upload preview, Government ID verification row with inline checkmark and verification subtext, 3-column name grid, contact, and core demographics.
  - **Child Accordion Cards (`.clean-card`)**: Organized collapsible accordion panels using **Dynamic Sub-Tables** for high-frequency scanning relations or **Stacked Card Repeaters** for complex multi-level hierarchical entities.
- **3. Detail Profile / Master View** (e.g., `EmployeeProfile.vue`, `PartyProfile.vue`):
  - **Strict Data Isolation**: Once navigated to an entity's profile, the page is strictly dedicated to that specific record. Zero cross-entity switchers, tabs, or carousels.
  - **Back Navigation**: Prominent `← Back to [Entities]` button and clickable breadcrumbs.
  - **Split Layout**: Left sticky identity sidebar (hero squircle avatar, name, badges, core identifiers, quick actions) + Right content area.
  - **Nested Mini-Tables (`.nested-mini-table`)**: Clean compact sub-tables displaying 1:N relations matching the schema.

## 16. Zero Manual "Code" Inputs Across All Creation Forms
- **Rule**: Creation forms (dedicated pages and `<QuickCreateModal>`) MUST NEVER contain manual text inputs for business codes (`code`, e.g. `Structure Code`, `Unit Code`, `Grade Code`, `Title Code`, `Position Code`).
- **Rationale**: Human-readable codes in Haleta ERP are either auto-generated by the system or derived systematically from the entity's name and sequence.
- **Display**: The code is rendered strictly in directory tables and detail views (underneath the primary Name as tertiary sub-text `#737373`), never asked from the user during creation.

## 17. Calendar Inputs with `[GC]` Gregorian Pill Badge
- **Rule**: Date inputs in master creation cards must feature a left-aligned calendar icon (`<Calendar :size="15" />`) and a right-aligned soft Gregorian pill tag (`<span class="gc-pill-tag">GC</span>`).
- **Styling**: Compact 38px height, 8px border radius, border `#e2e8f0`, with focus glow.

## 18. Strategic Description & Rich Text Editor Standard
- **Rule**: Descriptions and scopes longer than simple notes use the standardized Haleta ERP rich text editor component (`.rich-editor-container`).
- **Toolbar**: Contains `Paragraph ⌵`, `Font Type ⌵`, lists, formatting (`B`, `I`, `U`, `S`), code `<>`, table, color box, link, image, and undo/redo buttons.
- **Footer**: Always renders character counter (`0 / 5,000 Characters`) and resize handle `//`.

## 19. Critic-Aligned Dynamic Sub-Table ("Add Row" Pattern)
- **Header**: Enclosed inside a clean accordion header (e.g. `Unit Placement ⌵`).
- **Table Columns**: Essential scanning columns + rightmost Column Selector icon (`<Columns :size="14" />`).
- **Empty State**: Centered clean `No Row` placeholder text (`.child-td-empty`).
- **Add Action**: Single `+ Add Row` button (`.btn-add-row`) positioned directly beneath the table container.

## 20. Descriptions Strictly in Expanded Forms Standard (Zero Descriptions in Quick Create Modals)
- **Rule**: Textareas, biography blocks, and description/scope inputs MUST NEVER appear inside `<QuickCreateModal />`.
- **Placement**: Descriptions belong exclusively to **Expanded Forms** (such as dedicated master creation pages like `OrgStructureCreate.vue`, `SalaryScaleCreate.vue`, `EmployeeCreate.vue`, `PartyCreate.vue`, or dedicated full edit pages) featuring the standardized rich text editor (`.rich-editor-container`) with toolbar and character counter.
- **Rationale**: Quick Create Modals are strictly optimized for rapid, compact creation using the core <= 5 scanning attributes. Extended narratives, legal scopes, and rich descriptions belong naturally in the expanded full form.

## 21. Status Lookup Classification & Metric Card Mandate
- **Two Distinct Status Types in Schema**:
  - **Type A: Admin Multi-Entity Governance Status (`acceptForAll`, `acceptForThis`, `pending`, `reject`)**:
    - Appears on multi-tenant catalogs and master definitions (e.g. `JobLevel`, `JobTitle`, `FieldOfStudy`, `Institution`).
    - Managed centrally by system administrators.
    - **UI Standard**: Render standard canonical directory table card (`<AppDataTable />`) **WITHOUT** top KPI / Metric Cards.
  - **Type B: Entity Operational / Workflow Lifecycle Status (`draft`, `approved`, `active` / `Published`, `closed`, `probation`, `in_service`, `suspended`, `on_leave`, `separated`, `deactivated`)**:
    - Appears on entity-managed operational workforce entities and fiscal capacity records (e.g. `HeadcountBudget`, `EmployeeDetail` / `EmployeeProfile`, `LeaveRequest`, `OvertimeRequest`).
    - Managed and approved by the entity/organization itself.
    - **UI Standard**: **MUST include a Top KPI / Metric Cards Grid (`<MetricCard />`)** directly above the `<AppDataTable />`, summarizing key capacities, active utilization, pipeline requisitions/probations, and total rolled-up financial amounts.
- **Documented Rule**: `.agents/rules/status_classification_and_metrics_rule.md`.

## 22. Universal Date Formatting Standard (`MMM D, YYYY`)
- **Rule**: ALL dates displayed across the UI (tables, detail views, mini-tables, audit stamps, subtexts, and profile headers) MUST strictly follow the standardized business date format: **`MMM D, YYYY`** (short month name, day of month, full 4-digit year).
- **Examples**:
  - `Sep 23, 2026`
  - `Jul 8, 2026`
  - `Jan 15, 2027`
  - Date ranges: `Jul 8, 2026 – Jul 7, 2027`
- **Prohibited**: Raw ISO timestamps (`2026-07-08`), numeric slashes (`08/07/2026` or `07/08/2026`), or unformatted database strings.
- **Helper**: Always use a standard formatter `formatDate(str)` with `{ month: 'short', day: 'numeric', year: 'numeric' }` in `en-US` locale.

## 23. Calendar Input Single Left Icon Standard
- **Rule**: Calendar and date inputs MUST ONLY have a calendar icon on the left section (`<Calendar :size="15" class="date-icon" />`).
- **Suppression of Right Indicator**: Any duplicate calendar icon on the right section (including native browser WebKit calendar picker indicators `input[type="date"]::-webkit-calendar-picker-indicator` or duplicate right icons) MUST be suppressed and removed.
- **Right Area Reserved for `[GC]`**: The right section of date inputs is reserved strictly for the Gregorian pill tag (`<span class="gc-pill-tag">GC</span>`), never a calendar icon.

## 24. Mini Creation Form & Quick Create Modal Notes/Text Prohibition
- **Rule**: In a mini creation form / `<QuickCreateModal />`, if an entity has a description section, a text block, remarks, or a note section, it **WILL NOT appear** in the modal.
- **Placement**: Notes, descriptions, and extended texts belong **EXCLUSIVELY** to the expandable section / dedicated full creation page (`.../create`).
- **Rationale**: Keeps the quick create modal ultra-compact, focused, and frictionless for the $\le 5$ core fields.

## 25. Mandatory Rich Text Editor for All Notes & Descriptions
- **Rule**: ALL note, description, remarks, scope, and extended text inputs across the entire Haleta ERP system MUST use the standardized Haleta ERP rich text editor component (`.rich-editor-container`), NEVER a plain text input or bare `<textarea>`.
- **Standard Layout**: Features a top formatting toolbar (Paragraph, Font Type, Bullet Lists, B, I, U, S, Code, Table, Color Box, Link, Image, Undo, Redo), a clean text editing area, and a bottom footer with live character counter (`0 / 5,000 Characters`) and resize handle `//`.

## 26. "Save as Draft" Prohibition in Quick Forms
- **Rule**: The "Save as draft" button will **NEVER appear in quick create forms or quick create modals**.
- **Placement**: "Save as draft" is strictly reserved for expanded full-form pages (via the dynamic 3-dots more menu `[ ⋮ ]` in the top action bar, and ONLY where the underlying schema entity supports a `draft` lifecycle state).

## 27. Save Button Zero-Icon Standard
- **Rule**: The Save button across the entire system (in top action bars, modals, child drawers, expansion dialogs, or sub-forms) MUST NEVER have an icon (no checkmarks `<Check />`, pluses, floppy disks, or symbols).
- **Text Standard**: It MUST strictly display the plain text **`"Save"`**, no icons.

## 28. Table Header Sort Arrow Inline Alignment Standard
- **Rule**: In table headers, the append down arrow / sorting icon (`<ArrowUpDown>`, `<ChevronDown>`) will **ONLY appear if it is needed** (i.e. when that column is actively sorted `v-if="currentSort === colKey"`, or on hover). Unconditional sorting arrows on every inactive column are strictly prohibited.
- **Inline Alignment**: When the sort arrow appears, it MUST appear strictly on the **right side of the text, inline with the header title (`.th-content`)**, NEVER on a separate line or wrapped below the title (as previously occurred on "Organization Unit" in headcount tables).
- **CSS Architecture**: Enforce `.th-content { display: inline-flex !important; align-items: center !important; gap: 5px !important; white-space: nowrap !important; vertical-align: middle !important; }`.

## 29. Top Action & Breadcrumb Navigation Bar Zero-Background Standard
- **Rule**: The top header section containing breadcrumb navigation and right-hand action controls (`Clear Form`, `Save`, 3-dots draft menu) **MUST NEVER have a background card, border, or box-shadow** (`background: transparent; border: none; box-shadow: none; padding: 0;`).
- **Placement**: It sits directly and cleanly on the page background, seamlessly separated from the cards/tabs below.

## 30. Inline "Saved / Not Saved" Status Badge Standard (<SaveStateBadge />)
- **Component**: `<SaveStateBadge :isSaved="isSaved" :isDraft="isDraft" />` (`src/components/SaveStateBadge.vue`).
- **Rule**: Every create page and expanded creation form requiring a "Not Saved" / "Saved" status badge MUST use `<SaveStateBadge />`. Ad-hoc HTML/CSS badges are strictly prohibited.
- **Placement**: Sits immediately following the current page title in the breadcrumb navigation bar (`margin-left: 10px`), inline with the text.
- **Strict Appearance**:
  - Pill shape: Fully rounded (`border-radius: 9999px`), compact padding (`2.5px 11px`), `font-size: 11.5px`, `font-weight: 500`.
  - Zero border (`border: none;`).
  - **Not Saved**: Background color **`#FEF3C6`**, Text color **`#BB4D00`**.
  - **Saved**: Background color **`#ecfdf5`**, Text color **`#059669`**.
  - **Draft**: Background color **`#eff6ff`**, Text color **`#1d4ed8`**.

## 31. Action Button Sizing Standard (Expanded Forms & Directory Toolbar)
- **Rule**: Master action buttons across top creation bars and directory table toolbars must maintain comfortable enterprise sizing:
  - Primary Save Button (`.btn-primary-save`) and Create Button (`.btn-primary-create`): `height: 38px`, `padding: 0 18px` to `0 22px`, `font-size: 13.5px`, `font-weight: 500` or `600`, `border-radius: 8px`.
  - Secondary Clear Action Button (`.btn-secondary-clear`): `height: 38px`, `padding: 0 16px`, `font-size: 13px`, `border-radius: 8px`.
  - Dynamic 3-Dots Action Button (`.btn-icon-more`): `width: 38px`, `height: 38px`, `border-radius: 8px`.

## 32. Creation Form Section Risers Standard (Zero Page-Level Header Redundancy)
- **Rule**: Master creation cards MUST NOT include giant page-level `<h2>` titles and redundant paragraph descriptions that repeat the tab or page header.
- **Structure**: Render a concise card title row (`<span class="card-section-title">Budget Details</span>`), followed by structured **Section Risers** (`.form-section-riser`) separating distinct functional clusters:
  - Clear section title (e.g. `Work Location & Unit Allocation`, `Fiscal Capacity & Period`, `Financial Authorization & Ceilings`, `Budget Justification & Scope`).
  - Subtle horizontal divider line (`.riser-line`) extending across the card.
  - Logical 2-column or 3-column input grids nestled directly under each section riser.