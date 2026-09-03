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
- **Rule**: Desktop/Monitor root icon MUST always navigate to the Home page (`/home`).

## 4. Creation Flow Standard (<= 5 vs. > 5 Required Fields)
- **Entities with <= 5 Required Fields**: Clicking "+ Add / Create" MUST open `<QuickCreateModal />` (`src/components/QuickCreateModal.vue`) featuring:
  - **Header**: Title ONLY (no descriptions/subtitles) and **NO bottom divider line** (`#404040`, `18px`, semi-bold `600`).
  - **Bottom-Left**: "Expand Full Form" as a **Secondary Button** (`<Maximize2 />`).
  - **Bottom-Right**: "Save" as the **Primary Button** (Cancel button is omitted; modal dismisses via Esc/Close/Backdrop).
- **Entities with > 5 Required Fields**: Clicking "+ Add / Create" navigates directly to the dedicated creation page/wizard.
- **Dedicated Full Creation Page Architecture (Expand Full Form Flow)**:
  - **Entity Domain Naming Rule**: Always name pages, breadcrumbs, tabs, and form blocks using the exact entity domain name (e.g. `Party`, `Party Details`, `Create Party`, `Party Information`, `Create Customer`). **NEVER** use generic terms like `User` or `User Details` because a Party represents either an individual person or an organization/company.
  - When "Expand Full Form" is clicked from `<QuickCreateModal />`, navigate to the dedicated creation route (e.g. `/hr/parties/create`), preserving any typed values via route query.
  - **Top Bar**: Breadcrumbs (`[Monitor] > Entity Management > Create [Entity]`) + `Not Saved` / `Saved` status pill + Right Actions (`✕ Clear Form` secondary button + `Save` primary blue `#0B529C` button).
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

