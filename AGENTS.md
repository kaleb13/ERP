# Haleta ERP — Agent Guidelines

## Project map

- Frontend application: `frontend/src/`
- Shared Vue components: `frontend/src/components/`
- Authoritative HR schema: `HR/HR_Schema_final-v4.sql`
- Task-specific frontend standards: `.github/instructions/`
- Figma design edits: follow the [component-first workflow](.agents/skills/figma-component-first/SKILL.md).

## Engineering workflow

- Inspect existing implementations and reuse established components, helpers, naming, and patterns before adding new ones.
- **Strict QMT Design System Alignment**: Always use the predefined QMT colors (`#0B529C` brand blue, `#404040` secondary, `#737373` tertiary, `#FAFAFA` canvas, `#E5E5E5` subtle border, `#009966` success, `#E7000B` error, `#E17100` warning) and official QMT icon color token names (`icon-brand`, `icon-secondary`, `icon-tertiary`, `icon-success`, `icon-error`, `icon-warning`, `icon-info`). Never use generic slate/blue colors (`#0f172a`, `#334155`, `#475569`, `#2563eb`).
- **Dark Color & Hierarchy Rules**:
  - **Secondary (`#404040`) is the Darkest Color**: The darkest color for text and icons across the system is **Secondary** (`#404040` / `icon-secondary`). Do NOT use primary text color or primary icon color (`#262626`) anywhere unless explicitly instructed for a specific section.
  - **Breadcrumbs**: Inactive / previous breadcrumbs and dividers use **Tertiary** (`#737373`). Active / current breadcrumb uses **Secondary** (`#404040`). On top-level directory/listing pages, the breadcrumb MUST contain **only the exact page name** (`[{ label: 'Exact Page Name' }]`), NEVER prefixed with the parent module name (`Procurement`) or sibling pages. It expands to `[{ label: 'Page Name', onClick: ... }, { label: 'Item Name' }]` only when drilling into a detail or inspection drawer.
  - **Zero Background / Zero Card Container for Breadcrumbs (Strict Canvas Standard)**:
    - The breadcrumb bar and top navigation row (`.create-header-bar`, `.top-nav-bar`, `.top-header-action-bar`, `.breadcrumb-bar`) **MUST ALWAYS sit directly on the transparent canvas background** (`background: transparent; border: none; box-shadow: none; padding: 0;`).
    - **NEVER** wrap the breadcrumb or top action row in a white card box (`background-color: #ffffff`), card container, rounded box, or bordered frame (`border: 1px solid #e5e5e5; border-radius: 12px; padding: 14px 24px;`).
    - Breadcrumb navigation sits cleanly on the canvas on the left, with top action buttons (e.g. `Save`, `Clear Form`, or `MoreVertical`) aligned on the right in a transparent flex row directly above the form cards.
  - **Zero Background on Texts & Text-Wrapper Frames (Strict Transparent Text Rule)**:
    - Text nodes and inner text-grouping frames (label/value rows, inline text stacks, bank name + account wrappers inside a pill box, title containers) **MUST NEVER have their own background fill** (`fills = []` in Figma; `background: transparent` on Web).
    - Only the outer semantic surface (card, pill container, badge, button) carries a background fill — never paint a white or colored fill behind inner text wrappers sitting on top of another background.
    - **Figma API Guardrail**: `figma.createFrame()` and `figma.createAutoLayout()` initialize with a default `#FFFFFF` fill. ALWAYS set `fills = []` immediately on every structural/text-wrapper frame unless it is explicitly a card, pill, badge, or button.
  - **Dynamic Table Vertical Column/Cell Divider Strokes (Figma Rule)**:
    - In Figma, editable **Dynamic Tables** (`DynamicSubTable`) MUST show **`1px` vertical divider strokes** (`color/border/subtle` `#E5E5E5`) separating columns/cells. Because QMT `Table header cell` / `Table cell` components only include a bottom stroke by default (`left = 0`, `right = 0`), ALWAYS apply a **`1px` left-side stroke** (`strokeLeftWeight = 1`, `color/border/subtle`) to columns/cells after the first column whenever creating or editing a Dynamic Table (if not already present).
  - **Zero Back Buttons (Strict Breadcrumb-Only Navigation Rule)**:
    - **NEVER** place a "Back" button, back arrow button, or "Back to [List]" link anywhere in the system (`← Back to ...`, `btn-back`, `router-link` back buttons).
    - The **ONLY** way users navigate back or traverse the hierarchy is through the **Breadcrumb** (`AppBreadcrumb`).
    - When drilling down into details, inspect views, or child forms, the parent page link in the breadcrumb is clickable (`onClick: () => ...` or `to: '...'`). Redundant back buttons clutter the UI and violate Haleta ERP minimalist architecture.
  - **Zero Floating Action Buttons on View & Detail Pages (Strict Clean Header Standard)**:
    - **NEVER** place floating action buttons (such as `Edit`, `Edit Record`, `Deactivate`, `Activate`, or `Delete` inside `.detail-top-actions` or `.detail-right-actions`) in a separate row floating above cards in view, detail, or inspection pages.
    - View and inspection detail pages MUST present a clean, uninterrupted hierarchy: breadcrumb sitting directly on the canvas, immediately followed by the solid white profile/dossier card.
    - State changes and edits belong in the directory table's 3-dot kebab menu (`MoreVertical`), dedicated edit routes/modals, or workflow rails—never floating nakedly above detail view cards.
  - **Zero In-Page Toast Banners (Strict Centralized Toast Standard)**:
    - **NEVER** create inline `.toast-bar`, in-page alert banners, or `<Transition><div v-if="toastMessage">...</div></Transition>` inside views or components.
    - Notifications, success messages, errors, copy-to-clipboard alerts, and mode changes (e.g. Focus mode toggle) MUST ALWAYS be dispatched exclusively through the centralized `useToast()` composable (`import { useToast } from '../../composables/useToast'; const { toast } = useToast();`).
    - Toasts render globally via `<BaseToaster />` / `<BaseToast />` (`toast.success()`, `toast.info()`, `toast.warning()`, `toast.error()`).
    - Never distort or push page layouts with temporary in-page feedback pills.
  - **Breadcrumb Badges Sealing**: Status badges in the breadcrumb bar (e.g. `SaveStateBadge`) MUST ALWAYS be placed strictly inside `<AppBreadcrumb><template #badge><SaveStateBadge ... /></template></AppBreadcrumb>`. Never place them outside as an unsealed flex sibling.
  - **Badge System & Component API Contract**: Never construct raw `<span class="status-pill">` or `<span class="status-dot">` tags. Always reuse `BaseBadge` (Figma `3345:21147`).
    - **Mandatory Prop**: ALWAYS bind via `:color="..."` (NEVER `:variant="..."`, which causes component fallback to identical monochrome gray).
    - **Valid Semantic Colors**:
      - `color="success"`: Active state, approved governance, completed (`#009966`).
      - `color="gray"`: **Strictly reserved for Inactive / Dormant states** (`state === 'inactive'`). **NEVER** use `gray` for active functional lookups or options (such as `Permissive`), because doing so makes active records appear dead, disabled, or inactive.
      - `color="indigo"`: Statutory policy rules, mandatory compliance, and legal enforcement (`#432DD7` / `#EEF2FF`).
      - `color="blue"`: Permissive alternatives, secondary scopes, and informational lookup options (`#0069A8` / `#F0F9FF`).
      - `color="purple"`: Specialized operational modes or classifications (`#8200DB` / `#FAF5FF`).
      - `color="warning"`: Pending review, cautionary thresholds (`#E17100` / `#FEF3C6`).
      - `color="error"`: Rejected, failed, strict breach (`#E7000B` / `#FEE2E2`).
      - `color="primary"`: Brand blue anchor (`#0B529C` / `#E1EEFD`).
      - Never pass `'neutral'`; use `'gray'` only for mechanical inactive states.
    - **No Inactive Gray on Active Lookups**: Active operational options (e.g. `Permissive` vs `Mandatory`) must NEVER be styled with inactive gray. Use distinct QMT library colors (`indigo` and `blue`).
    - **No Monochrome Lookups**: Never paint different lookup categories or states with the same badge color across a table row.
    - **Compound Badges**: For all compound or longer badges, ALWAYS reuse the authoritative `BadgeGroup` component ([Figma `5221:28673`](https://www.figma.com/design/EVkNwnkJXcHROkdv2QqXoU/QMT-team-library?node-id=5221-28673&t=0vdo4adqS3KKDEy8-4)) with inner pill, message, and action arrow.
  - **Date & Calendar Top Navigation**: Headers with date switching (e.g. `CalendarView.vue`, `AttendanceView.vue`) must use the standard rectangular "Today" button (`.btn-today-pill` with `Calendar` icon `18px`), circular arrow buttons (`.btn-circle-nav` `40px` circular buttons), and centered date title.
  - **Date Display Format Standard (`MMM D, YYYY`)**: All displayed dates in table columns, detail dossiers, context strips, and timelines MUST use the short-month, day, year format (e.g. `Jul 1, 2026`, or `Jul 1, 2026 → Jun 30, 2027`) via `formatDisplayDate()` / `formatDisplayDateRange()` from `frontend/src/utils/dateFormat.ts`—never raw numeric `YYYY-MM-DD`. (Native `<input type="date">` controls keep `YYYY-MM-DD` internally.)
  - **Detail Page Activity & Version Log Standard ([Figma `10679:31692`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10679-31692))**:
    - Whenever a detail page has logs, audit trails, or version histories, use the canonical **Activity Log** layout (`Activity Section - To Copy`):
      - **Header**: Section title **`Activity Log`** (or contextual log title — avoid "Recent Activity" when entries span older history) on the left (`20px` SemiBold `#404040`); secondary icon-only Filter button (`Filter`) and 3-dot `MoreVertical` button (`gap: 8px`) on the right, both opening the authoritative **`BaseDropdownMenu`** component (omit date/period dropdowns unless explicitly required).
      - **Progress Track**: `5px × 5px` circular `Dot` (`#0B529C` brand primary for the most recent entry; `#404040` `icon-secondary` for older entries) separated by `8px` gaps from `1px` `#E5E5E5` vertical connector lines.
      - **Activity Rows**: `16px` Regular/Medium `#737373` (`tertiary`) text + secondary action button (`<AppButton variant="secondary-gray" size="sm">` with trailing icon, e.g., `See Change Preview` to compare current vs. previous version, or `Open ... Document`).
  - **Single-Line Table Columns Standard**:
    - Supporting 2-line text (primary label + secondary subtitle/description) is recommended **only for the first lead/identity column** (e.g. `Plan` or `Item / Description`).
    - All subsequent data columns (`Category`, `Coverage Window`, `Planned Qty`, `Est. Amount`, etc.) MUST display **single-line values only** to keep tables clean and scannable.
  - **Detail Page Status vs. Approval Workflow**:
    - Do NOT add standalone "Approval Workflow" cards or floating `Close Plan` / `Cancel Plan` buttons onto detail pages when approval is represented by the status badge on the dossier header card.
  - **Side-by-Side Comparison Section & Transition Form Standard ([Figma `10716:32900`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10716-32900) & [`10703:39712`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10703-39712))**:
    - Whenever a detail page compares **Current vs. Proposed** state (e.g., Employee Movement, `SupplierChangeRequest`, Contract Amendment, Grade/Price Revision), ALWAYS reuse the canonical side-by-side Comparison Section layout:
      - **Left Card (Current)**: Clean white `#FFFFFF` surface, `1px solid #E5E5E5` border, `12px` radius, `#737373` labels on left, `#404040` SemiBold values on right (no thick left accent stripe).
      - **Right Card (Proposed Target)**: QMT Brand Blue surface (`#F1F7FE` background, `1px solid #BDDBFA` border, `12px` radius), `#737373` labels on left, `#0B529C` SemiBold values on right.
      - **Optional Policy Mandate Callout**: QMT Warning surface (`#FFFBEB`, `1px solid #FFD230`, `#E17100` icon + `<BaseBadge color="warning" size="sm">`).
      - **Delta Summary Banner**: Placed at the bottom of the Description/Rationale card in QMT Brand Blue (`#F1F7FE`, `1px solid #BDDBFA`, `#0B529C` `Info` icon & title).
    - Copy directly from `10716:32900` and `10703:39712` in `05qJWp6THRmHsOuLX8oc5U` for future Figma designs and follow the same pattern for create forms with live preview + delta calculation (like `EmployeeMovementCreate.vue`).
  - **Borders & Aura**: Use **Secondary** (`#404040`) for prominent border color and focus aura.
  - **Inactive / Previous Sections**: Use **Tertiary** (`#737373`) to show inactive sections, previous steps, unselected states, and helper metadata.
- For UI work, follow the scoped frontend instructions and verify the actual screen and states involved.
- For schema-backed features, inspect the authoritative schema before designing fields or payloads; do not invent columns.
- Run the smallest relevant test, build, or type-check for code changes. Report what was run and any validation that remains.
- If instructions conflict or a design decision would change user-facing behavior, explain the conflict and ask before choosing.

## Authoritative Component Decision Matrix: What to Use & Scenario Catalog

**Zero Component Deletion Rule**: NEVER delete or bypass existing shared components in `frontend/src/components/`. Every component serves a specific purpose, place, and scenario. Adhere strictly to the matrix below:

| Component Category | Primary Standard | Alternative / Specialized Component | When to Use Primary Standard | When to Use Alternative / Specialized | Strict Anti-Patterns (When NOT to Use) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Navigation & Header** | `AppBreadcrumb` | — | **Every page & view** across the system. Placed directly on transparent canvas background. | — | ❌ Never wrap inside a white card or bordered container.<br>❌ Never add a "Back" button next to breadcrumbs or on view pages. |
| **Tabs & Views** | `BaseTabs` (`type="rounded"`) | `UnderlineTabs` (or `BaseTabs type="underline"`) | **Primary navigation**: Single tab bar on directory pages, Tabular Create Forms (Tab 1: Master Details, Tab 2: Child lines). | **Secondary sub-navigation**: Inside dossier cards (e.g. Employee profile: Personal, Job, Pay), or Level-2 tabs nested under Primary tabs. | ❌ Never use `UnderlineTabs` as top-level page tabs or for Tabular Create forms.<br>❌ Never place primary creation CTAs inside tab slots. |
| **Directory Tables** | `AppDataTable` | `BaseTable` | **Top-level module directory pages** (Employees, Purchase Methods, Categories, Shifts). Pre-wires search, filter, sort, column hider, pagination, and bulk bar. | **Custom or deeply embedded tables** where the parent view completely customizes the search/filter controls or layout. | ❌ Never build ad-hoc pagination or custom search inputs from scratch.<br>❌ Never omit standard table filter section. |
| **Child Schemas & Lines** | `DynamicSubTable` | `DynamicTableModal` | **All 1:N relations, child schemas, rosters, and line items** (Threshold bands, committee members, shift patterns, PO lines). Always inside Tab 2+ of Create Forms. | **Row expansion modal**: Opened automatically via `↗` button on `DynamicSubTable` rows to view/edit secondary or scope fields. | ❌ NEVER isolate child lines into flat orphan pages.<br>❌ Never display all fields as columns in table (max 3-4 scanning columns; rest in modal).<br>❌ Never omit 24px container padding. |
| **Entity Creation** | Dedicated Tabular Create Page (`[Entity]Create.vue`) | `QuickCreateModal` | **Entities requiring full information** (several, ten, or more inputs), aggregate roots with child schemas, multi-stage forms, or entities needing rich descriptions and child lines. Clicking `+ Create` goes straight to the dedicated create form. | **Simple flat entities only** where a valid record can be created with a small number of essential inputs (max 3-5 fields) without burdening the user with all inputs upfront. All remaining inputs are found when the user clicks "Expand Full Form". | ❌ Never use `QuickCreateModal` when an entity requires full information, 1:N relations, or thresholds.<br>❌ Never place rich text descriptions or sub-tables inside `QuickCreateModal`. |
| **Text Inputs** | `FormInput` | `FormCombobox` | **Standard single-line text, numbers, dates, emails, and codes**. | **Searchable selector with inline "Create and Continue"** capability for dynamic lookups. | ❌ Never use `FormInput` for multi-line text or rich descriptions.<br>❌ Never use raw `<input>` elements. |
| **Dropdown Selectors** | `FormSelect` | `FormCombobox` | **The authoritative dropdown for ALL lookups, enums, status pickers, and entity selectors**. Teleported, searchable, multi-select capable. | **Searchable combobox where users can type a query and create a missing entity inline** without leaving the form. | ❌ NEVER use native HTML `<select>` tags or invisible select overlay tricks.<br>❌ Never use long explanatory placeholders (`Select Scope`, not `All Categories`). |
| **Dropdown & Action Menus** | `BaseDropdownMenu` | — | **All Filter menus, 3-dot (`MoreVertical`) menus, and popover action menus** (Activity Log headers, table row actions, top bar menus). Uses QMT `--qmt-dropdown-*` tokens and `<Teleport to="body">`. | — | ❌ NEVER hand-roll ad-hoc `.action-dropdown` / `.activity-dropdown` divs inside cards with `overflow: hidden`. |
| **Descriptions & Notes** | `FormRichText` | `FormTextarea` | **All entity descriptions, operational guidelines, statutory rules, and circular memos**. Must be inside a dedicated collapsible card (`overflow: hidden; border-radius: 12px;`). | **Short, unformatted multi-line notes in quick utility dialogs** (rejection reason drawer, quick cancellation memo, audit comments). | ❌ NEVER place `<textarea>` or `<FormTextarea>` as an inline field inside master configuration cards.<br>❌ Never use `FormTextarea` when formatted text/lists are needed. |
| **Boolean Flags & Switches** | `FormCheckbox` | `FormCheckboxCard` / `FormToggle` | **Form data models, statutory policy conditions, compliance flags**, settings with Title + Description, table row selection (`th-lead` / `td-lead`). **Layout Standard**: Must sit in a dedicated bottom `Policy Checkboxes` container taking half the width (`repeat(2, 1fr)` / `width: FILL`), with **`16px` horizontal gap** between pairs and **`20px` vertical gap** between rows. | **`FormCheckboxCard`** (Figma `10415:37682` / `10415:37687`): Conditional checkbox sections that reveal nested inputs (`#FAFAFA` + `#E5E5E5` when collapsed, `#FFFFFF` + `#E5E5E5` when expanded; supports both `expandWhenChecked` true/false). **`FormToggle`**: Instant-apply runtime UI preferences (column hider, focus mode). | ❌ Never use `FormToggle` for standard form fields that require clicking "Save" to persist.<br>❌ Never shoehorn checkboxes inline next to text/date inputs as half-row flex siblings.<br>❌ Never render disabled orphan inputs next to checkboxes when `FormCheckboxCard` can reveal them conditionally.<br>❌ Never use raw browser `<input type="checkbox">`. |
| **Badges & Status** | `BaseBadge` (`:color="..."`) | `BadgeGroup` | **Standard status badges, state pills (`active`/`inactive`), lifecycle states, and lookup tags** across all tables, cards, and drawers. | **Longer compound notifications, announcements, and metric highlights** with inner badge, descriptive text, and action arrow. | ❌ NEVER pass `:variant="..."` (always `:color="..."`).<br>❌ NEVER use `gray` for active functional lookups (strictly reserved for inactive states). |
| **Avatars & Collaboration** | `BaseAvatar` | `AvatarGroup` | **Single user, employee, or contact representation**. Used in profile headers, table leader cells, comment authors, assignees. | **Rosters of multiple stakeholders** (evaluation committees, tender opening boards, joint sign-off lists, approval chains). | ❌ Never use `AvatarGroup` for single employee profiles.<br>❌ Never use bare unstyled images for user avatars. |
| **Buttons & CTAs** | `BaseButton` / `AppButton` | — | **All action buttons across the ERP**. Primary brand blue (`Save`, `Create`), Secondary gray (`Filter`, `Sort`, `Clear`), Error red (`Delete`). | — | ❌ Never put icons on primary top `Save` buttons.<br>❌ Never style Sort button as brand blue (must be `secondary-gray`). |
| **Tooltips & Hints** | `BaseTooltip` | `helper-text` / `hint` prop | **Contextual hover microcopy on interactive icons, compact buttons, or truncated text** (3-dot kebab menu, column hider icon, refresh button). | **Permanent instructions and guidelines below form inputs**. | ❌ Never use `BaseTooltip` for primary field explanations (use `helper-text` instead).<br>❌ Never hide critical form requirements inside hover tooltips. |
| **Bulk Actions** | `TableFloatingBar` | 3-Dot Actions Menu (`MoreVertical`) | **Batch operations when 1 or more rows are selected via table checkboxes** (Bulk Change Status, Bulk Duplicate, Bulk Export, Bulk Delete). | **Row-level individual actions** inside the standard 3-dot kebab menu in the table Actions column. | ❌ Never display floating bulk bar when 0 rows are selected.<br>❌ Never place loose inline action buttons (View, Edit, Delete) side-by-side in table cells. |
| **Metrics & KPIs** | `MetricCard` | Inline Badges | **Top summary KPI cards above directory tables or dashboards** (Total Methods, Active Employees, Breach Count). Includes label, value, trend, icon, 3-dots. | **Compact row-level or card-level numbers**. | ❌ Never place large `MetricCard` components inside create forms or row detail modals. |
| **User Feedback** | `useToast()` (`BaseToaster`) | Form `error` prop | **Platform-wide notification banners for completed actions, errors, and system alerts** (dispatched via `toast.success()`, `toast.error()`). | **Field-level validation error messages** bound to `error` prop on `FormInput`, `FormSelect`, etc. | ❌ NEVER create inline in-page `.toast-bar` banners or custom transition alert divs that push page layouts. |

## Creation Architecture Law: The Philosophy of Quick Create vs. Direct Create Form

- **Why Quick Create Was Needed**:
  - The Quick Create Modal (`<QuickCreateModal />`) exists specifically for entities that are **simple enough to be created with a small number of essential inputs (3 to 5 fields)**. It spares the user from being burdened with all inputs, secondary parameters, and rich text descriptions upfront.
  - The user can instantiate the record immediately with just those necessary inputs, while knowing that **all remaining inputs, full policies, and extended configurations will be found once they expand the full form** via the **"Expand Full Form"** (`<Maximize2 />`) action.
- **When Quick Create is NOT Needed (Direct Create Page Standard)**:
  - **If an entity fundamentally requires full information**—such as several, ten, or more inputs, multi-stage configurations, statutory compliance profiles, or 1:N relational child lines—in order to even be created or operative, **the quick modal is NOT needed at all.**
  - In such cases, creating a quick modal introduces a frustrating, artificial double-step.
  - The directory page's primary action button (`+ Create [Entity]`) MUST **go straight to the dedicated creation page/route** (`[Entity]Create.vue`).
- **Schema Representation $\rightarrow$ Creation Flow Mapping** *(decided by **required `NOT NULL` user fields**, not total nullable columns)*:
  - **Tier 1: Simple Flat & Essential-Field Entities ($\le 5$ required fields)**: Supported by `<QuickCreateModal />` with state transfer to full form for optional overrides & notes (e.g., `ProcurementCategory`, `ProcurementApprovalRoute`, `ProcurementAssignmentRule`, `ProcurementCommitteeMandate`, `LeaveType`, `JobPosition`).
  - **Tier 2: Comprehensive / Full-Information Entities ($> 5$ required inputs or multi-parameter rules required upfront)**: Bypass modal entirely; direct navigation to `[Entity]Create.vue` (e.g., `ReceiptToleranceRule`, `MatchingToleranceRule`, `LeavePolicy`, `WorkCalendar`).
  - **Tier 3: Aggregate Roots with 1:N Child Schemas**: Direct navigation to `[Entity]Create.vue` with tabular master-child layout and `<DynamicSubTable />` (e.g., `PurchaseMethod` + thresholds, `ProcurementUnit` + members, `ProcurementPlan` + versions/lines).
- **Workflow-Driven Primary CTA & Draft 3-Dot Menu Rule**:
  - Whenever an entity has a status lookup with workflow/transmission states (e.g., `submitted`, `requested`, `pending_approval`) rather than simple master-data persistence:
    - The primary top-bar action button MUST say **`Submit`** (for `submitted` workflows) or **`Request`** (for `requested` workflows)—NEVER generic `"Save"`.
    - When the status lookup includes **`draft`**, place a secondary 3-dot kebab button (`MoreVertical`) **to the left of `Clear Form`** in `.top-bar-actions`, housing **`Save as Draft`** inside its dropdown menu.
    - Top-right `.top-bar-actions` order: `[ ⋮ MoreVertical ("Save as Draft") ]  [ ✕ Clear Form ]  [ Submit / Request ]`.
- **Auto-Generated Sequence Numbers (`DocumentSequence`)**:
  - Fields populated from `DocumentSequence` (e.g., `plan_number`) MUST NOT be rendered as disabled inputs in create forms; generate them on save.
- **Strict 3-Column Form Grid Rule**:
  - In `.form-card-body`, rows use `.form-grid-3` (`repeat(3, minmax(0, 1fr))`). When a row has 1 or 2 inputs, it occupies 1 or 2 slots of the 3-column grid and leaves the remaining slot(s) empty—never stretching to fill the extra space.

## Master-Child Relational Integrity & Schema Naming Law (Zero Orphan Child Pages)

- **Strict Schema Backing Across All Modules**: Inspect the owning domain's authoritative schema before designing fields, views, routes, or payloads (HR: `HR/HR_Schema_final-v4.sql`, Procurement: `procurement-v4.sql`, Inventory: `Inventory and its related schema.md`). Do not invent columns, phantom enums, or disconnected marketing names.
- **Master-Child Relational Integrity (Zero Orphan Child Pages)**:
  - **NEVER isolate a child line schema** (e.g. `PurchaseMethodThreshold`, `ProcurementUnitMember`) into a flat, independent directory table that severs it from its parent aggregate root (`PurchaseMethod`, `ProcurementUnit`).
  - When an aggregate root has child lines or scope bands, **both sections MUST be represented in a unified view**:
    - **Unified Directory Views (`<BaseTabs />`)**: Use primary capsule tabs to present both the Master Entity catalog (Tab 1, e.g. `Purchase Methods`) and the global Child Line matrix (Tab 2, e.g. `Value Threshold Bands`) in one cohesive screen.
    - **Tabular Create Forms (`<DynamicSubTable />`)**: All 1:N relations MUST be represented in their own dedicated tab hosting `<DynamicSubTable />` with at least 1 pre-populated default row. The primary action button below `<DynamicSubTable />` MUST ALWAYS be labeled **`Add Row`** (`+ Add Row`)—never entity-specific labels like `"Add Planned Item"` or `"Add Threshold Band"`.
- **Exact Schema Naming Fidelity (Zero Ad-Hoc Marketing Jargon)**:
  - UI page titles, navigation labels, breadcrumbs, and route names MUST directly reflect the SQL schema entity names:
    - `PurchaseMethod` + `PurchaseMethodThreshold` -> **`Purchase Methods`** / **`Purchase Methods & Thresholds`** (NEVER colloquial marketing phrases like "Spend Threshold Bands").
    - `ProcurementCategory` -> **`Procurement Categories`**.
    - `ProcurementUnit` + `ProcurementUnitMember` -> **`Procurement Units`**.
    - `JobPosition` -> **`Job Positions`**.
    - `WorkShift` + `ShiftPattern` -> **`Work Shifts & Shift Patterns`**.
    - `LeavePolicy` + `LeaveAllocation` -> **`Leave Policies & Allocations`**.
  - Traceability from SQL schema to UI code is mandatory.

## Policy Checkbox & Grid Architecture (Quick Create Modals, Create Forms & Detail Cards)

- **Dedicated Bottom Section Standard (Zero Inline Squeezing)**:
  - Checkboxes that control policies, statutory conditions, or input flags (e.g., `Unlimited / Open Ceiling`, `Requires Procurement Committee Evaluation`, `Allows Single Source Supplier`) must **NEVER be shoehorned inline into an input row** as a half-row flex sibling alongside a text, number, or date input.
  - Policy checkboxes MUST always sit in their own **dedicated `Policy Checkboxes` container** at the bottom of the card/modal body.
- **Strict 2-Column Half-Width Grid Layout**:
  - Each checkbox MUST take **exactly half of the container width** (`repeat(2, 1fr)` in CSS / `width: FILL` inside a 2-column horizontal auto-layout frame in Figma).
  - **Horizontal gap between checkbox pairs**: **`16px`** (`gap: 16px` / `itemSpacing: 16`).
  - **Vertical gap between checkbox rows**: **`20px`** (`gap: 20px` / `itemSpacing: 20`).
  - When an odd number of checkboxes or a single checkbox is present, it occupies the left column (half-width), leaving the right column as an empty spacer frame. It must NEVER stretch across the full width or squeeze into an unrelated input row.
- **Quick Create Modals (`<QuickCreateModal />`)**:
  - Top section: Input rows structured in 2-column pairs (`.modal-form-row` with `gap: 16px`).
  - Bottom section: Dedicated `.modal-checkbox-grid` (`display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px 16px;`) housing policy checkboxes.
- **Dedicated Create Pages (`[Entity]Create.vue`)**:
  - Form card body organizes inputs into standard `.form-grid-3` / `.form-grid-2` rows.
  - Dedicated policy checkboxes section: `.controls-checkbox-grid` (`display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px 16px; padding-top: 16px; border-top: 1px solid #f0f0f0;`).

## Standard Directory Tables

- Follow `.github/instructions/table-architecture.instructions.md` for both ERP tables and their Figma counterparts.
- Use a title block with `20px` vertical and `24px` horizontal padding, followed by the linked QMT **Table Top Filter Section**; only override its search text and primary action label.
- Keep table content full-bleed to the card edges. Use the linked QMT **Pagination** footer, not a custom text footer.
- Integrate row selection into the first identity column: the header cell has text and checkbox enabled, and body cells use the **Lead checkbox** variant. Do not add a checkbox-only column.
- Keep the identity column visible when it hosts selection controls. In Vue, use `AppDataTable`/`BaseTable`, `FormCheckbox`, and the shared pagination.
- **Table Sort Button & Secondary Button Standard**: The Sort button in the Table Top Filter Section MUST ALWAYS be styled as our **Secondary Button** (`secondary-gray`: white background `#ffffff`, subtle border `#e5e5e5`, secondary text `#404040`), identical to the Filter button. It must NEVER be styled as a colored/brand-blue button. Both Filter (`Filter`) and Sort (`ArrowUpDown`) button icons MUST use `stroke-width="2.5"` (`class="icon-bold"`).
- **Mandatory Table Header Standard (`Table header gray`)**:
  - In all tables across both Vue and Figma, table headers MUST use the gray background (`#FAFAFA` / `var(--color-background-primary)`).
  - In Figma, ALWAYS use the linked **`Table header gray`** component; **NEVER** use `Table header white`.
  - The first header cell uses `Table header gray` with `Checkbox=True, Text=True`.
- **Mandatory Column-First Table Construction in Figma (Zero Row-Based Assembly)**:
  - In Figma, tables MUST ALWAYS be constructed vertically by **Columns**, NEVER horizontally by **Rows** ([Figma `10015:10134`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10015-10134) & [`5520:79511`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=5520-79511)).
  - **Outer Table Body Container (`Card Content` / `Content`)**: Horizontal Auto-Layout (`layoutMode: 'HORIZONTAL'`, `itemSpacing: 0`, `padding: 0`, `width: FILL`).
  - **Column Children (`Column` frames)**: Each column is an independent vertical Auto-Layout frame (`layoutMode: 'VERTICAL'`, `itemSpacing: 0`, `padding: 0`).
  - **Cells Inside Each Column**:
    - **Child 0 (Header)**: Linked instance of `Table header gray` (height `44px`, `width: FILL` / `layoutAlign: 'STRETCH'`).
    - **Child 1..N (Body)**: Linked instances of `Table cell / [Variant]` (height `72px`, `width: FILL` / `layoutAlign: 'STRETCH'`).
  - **Why Row-Based Assembly is Forbidden**:
    - ❌ **NEVER create horizontal Row frames** (`Row 1`, `Row 2`, `Row 3`...): In row-based layouts, adding, reordering, resizing, or hiding a column requires manually editing every individual row frame across the entire table.
    - ✅ **Column-First Benefits**: Adding a column requires only duplicating or inserting ONE `Column` vertical frame. Reordering is instant drag-and-drop. Resizing the `Column` automatically adapts all rows via `width: FILL`. Hiding a column directly mirrors the ERP Column Hider toggle.
  - **Column Width Guidelines**: Lead column `300px–340px` (or `width: FILL`), categorical columns `160px–220px` (Org Unit `190px`, Reports To `176px`), monetary/numeric `130px–160px` (Guarantee `137px`), codes/grades `110px–130px` (Pay Grade `122px`), state/status `120px–140px` (State `127px`), actions column `100px–110px` (`109px`, centering `Table cell / Action 3-dots`).
- **Mandatory Table Cell Component Taxonomy (Zero Ad-Hoc Cell Frames)**:
  - In Figma, tables MUST be composed using the official linked **`Table cell / [Variant]`** component family from the QMT Team Library. Never draw bare auto-layout frames as table cells:
    - **`Table cell / Lead checkbox`**: First identity column. Contains the row-selection checkbox, primary entity title (`#404040`), and optional code subtext (`#737373`).
    - **`Table cell / Single badge`**: For Status (`status_lookup_value_id`), State (`active` / `inactive`), and high-salience lookups. Houses a linked `BaseBadge` instance with semantic token color.
    - **`Table cell / Multiple badge`**: When a cell houses a collection/array of tags (e.g. multiple roles, scopes, or categories).
    - **`Table cell / Text`**: Standard text cells. Secondary (`#404040`) for primary identifiers; Tertiary (`#737373`) for secondary metadata, dates, and foreign keys.
    - **`Table cell / Currency` / `Amount`**: Formatted monetary or numeric values with standard currency notation (ETB).
    - **`Table cell / Toggle`** ([Figma `10178:34635`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10178-34635) — `Column Presets Strip 3 - To Copy`): Fast inline boolean toggle column (`36px × 20px` QMT `Toggle` + `12px` gap + `Yes` / `No` `14px` Medium `#404040`). In web code: use `type: 'switch'` in `<DynamicSubTable />` and `<TableToggleCell />` (`frontend/src/components/TableToggleCell.vue`) in standard directory tables (`AppDataTable` / `BaseTable`). Always copy `10178:34635` in Figma when adding toggle columns to tables or dynamic sub-tables.
    - **`Table cell / Progress bar`**: For visual quota consumption, allocation percentages, or completion rates.
    - **`Table cell / Trending positive` & `Trending negative`**: For performance indicators and percentage variances.
    - **`Table cell / Leader avatar` & `Avatar group`**: Profile avatars for staff profiles (only on an entity's own directory) or team/committee rosters.
    - **`Table cell / Action 3-dots`**: Standard 3-dot kebab menu button (`MoreVertical`).
- **No Scrollable Tables (Full-Bleed 100% Fit Standard)**:
  - Tables across all standard ERP directory and listing views MUST fit 100% of the container width naturally without horizontal scrollbars (`overflow-x: auto;` or horizontal scroll containers).
  - Never overload directory tables with excessive columns (maintain 5 to 8 high-signal scanning columns). Never wrap tables in artificial horizontal scroll wrappers on standard desktop displays.
- **Mandatory Action Column Header Label**:
  - The Actions column header MUST ALWAYS display an explicit column title (`Action` or `Actions`), matching Figma specifications. Never leave the Action column header empty (`label: ''` or empty `<th>`).
- **Zero Focus Outline on Action Buttons (`MoreVertical` / `.btn-action-dots`)**:
  - Clicking the 3-dot action menu button must NEVER display a browser focus outline or halo ring (`outline: none !important; box-shadow: none !important; -webkit-tap-highlight-color: transparent !important;`).
- **Mandatory 3-Dot Actions Column Standard (`MoreVertical`)**:
  - In all directory tables, data tables, and sub-tables across the entire ERP, the **Actions** column MUST ALWAYS be represented as a **3-dot kebab menu button** (`MoreVertical` icon from `lucide-vue-next` with `.btn-action-dots`).
  - **NEVER** render loose, bare, or inline action buttons (such as View/Eye, Edit, and Trash side-by-side in the table cell).
  - Clicking the 3-dot button opens the standardized action popover menu (`.action-menu-popup` / `.action-dropdown`) containing:
    1. Inspect / View Details (`Eye` icon)
    2. Edit Record (`Edit2` icon)
    3. State toggle (Activate / Deactivate with `Check` icon)
    4. `.menu-divider`
    5. Delete / Destructive Action (`Trash2` icon with danger color `#E7000B`)
  - The menu must dismiss on outside click and Escape key.
- **Lookup Values Representation Standard (Discretionary Badges vs. Plain Text)**:
  - **Status and State are Always Badges**: In all tables, sections, and views across the entire system, **Status** (`status_lookup_value_id`, governance status, workflow status) and **State** (`active` / `inactive`) MUST ALWAYS be represented with badges (`BaseBadge` / status pills).
  - **Dual Appearance for Schema Lookups**: All other schema lookups (e.g., operation modes, spend classes, receipt modes, unit types, procurement methods) have two valid visual representations:
    1. **Plain Tertiary Text** (`#737373` / `.tertiary-plain-text`): Quiet, clean typography for secondary, informational, or high-density categorical columns.
    2. **Badges** (`BaseBadge`): Visually anchored pills for high-salience operational classifications.
  - **Agent Decision Authority & Balancing Principle**: The agent/designer has the discretion and responsibility to decide whether each lookup column is best rendered as plain text or as a badge:
    - *Avoid Badge Clutter*: Carefully inspect the table's visual density. Never overload a table row with badges across multiple columns, which creates visual noise and degrades scanability.
    - *Avoid Hidden Information*: Never bury critical operational distinctions in plain text if doing so conceals vital workflow differences or routing categories from quick visual identification.
    - *Decision Criteria*: Evaluate the operational impact, cardinality, and column count of the specific table. If a lookup represents a critical operational mode (e.g. `Centralized` vs `Decentralized` procurement unit mode) in a moderate table, a badge may be optimal; if the table already has several badged/highlighted columns or the lookup is secondary metadata, render it in clean plain tertiary text.

## Tabular Create Forms for 1:N Lines & Child Schemas

- **Strict Tabular Separation for Related Lines**: Whenever an entity creation form (`Expand Full Form` / dedicated creation page) includes related lines, child schemas, or 1:N relationships (e.g., `ProcurementUnitMember` lines on `ProcurementUnit`, PO lines, committee members, addresses, qualifications), **NEVER place them on the same page below the master card**.
- **Mandatory Dedicated Tabs (`<BaseTabs />`)**: Related line schemas MUST ALWAYS be represented inside their own dedicated tab using `<BaseTabs />` (Primary pill capsule standard).
  - **Tab 1**: Master entity information & parameters (`[Entity] Details`).
  - **Tab 2+**: Related lines, child rosters, or sub-tables (`[Line/Member] Roster` using `<DynamicSubTable />`).
  - Tab headers should display reactive item counters (e.g. `Unit Members (3)`).
  - Validation failure in Tab 1 must automatically switch active tab back to Tab 1.
- **Dynamic Table Default Non-Empty Initial State (1 Row Minimum)**:
  - When creating or designing dynamic tables (`DynamicSubTable.vue` and parent create models), the default design MUST NEVER be an empty state (`[]`).
  - There MUST ALWAYS be at least **one default row** pre-populated in the initial state (`defaultInitialRow: true`). This ensures column structures, cell controls, inputs, and layout behavior are immediately visible, testable, and directly reproducible in Figma without requiring manual add-row clicks.
- **Unified DynamicSubTable Component Standard (Zero Bespoke Modals)**:
  - Across all modules (HR, Procurement, Inventory, Sales), ALL dynamic lines, child schemas, rosters, and 1:N relations MUST use the single authoritative `<DynamicSubTable />` component (`frontend/src/components/DynamicSubTable.vue`).
  - **Zero Bespoke Modals or Ad-Hoc Overlays**: NEVER write custom row modal overlays or bypass `<DynamicSubTable />` with ad-hoc `:use-custom-modal="true"`. Always use the native `<DynamicTableModal />` row expansion engine built into `<DynamicSubTable />`.
  - **Full Column Typing**: Columns must use explicit QMT types (`type: 'select'` with searchable option arrays, `type: 'date'`, `type: 'switch'`, `type: 'text'`, `type: 'number'`, `type: 'checkbox'`). Do not use ad-hoc HTML `<datalist>` or unstyled `<input>` wrappers inside custom template slots.
- **Dynamic Table Lead Column & Expand Row Detail Modal Standard (Figma `6095:96369` & `6095:96370`)**:
  - **Lead Column Integration & Alignment Standard (Figma `7009:114120`)**:
    - In dynamic sub-tables (`<DynamicSubTable />`), the first column combines the checkbox and sequence number into a single lead column (`th-lead` / `td-lead`, exactly 68px wide: `width: 68px; min-width: 68px; max-width: 68px;`). Never duplicate the sequence number as a separate user-defined column in the `columns` prop.
    - **Pixel-Perfect Alignment Guarantee**:
      - Both header (`.dynamic-table th.th-lead`) and body (`.dynamic-table td.td-lead`) cells MUST share identical horizontal padding (`padding: 0 11px !important;`) and height (`44px`).
      - `.td-cell { padding: 0 }` must NEVER override `.td-lead` (enforce via `.dynamic-table td.td-lead`).
      - Both flex containers (`.lead-th-content` and `.lead-td-content`) MUST use `display: flex; align-items: center; gap: 12px;`.
      - Checkboxes inside lead cells MUST have wrapper padding/margins neutralized (`padding: 0 !important; margin: 0 !important; width: 16px; height: 16px;`).
      - This guarantees both the header checkbox and row checkboxes start at the exact same horizontal coordinate (`x = 11px`), and the header text (`No.`) and sequence numbers (`1`, `2`) start on the exact same vertical guide (`x = 40px`), perfectly matching Figma `7009:114120`.
    - Table header row background is always `#FAFAFA` (`var(--color-background-primary, #fafafa)`).
  - **Authoritative Expand Row Detail Modal Standard (`<DynamicTableModal />`)**: When a row is expanded via the `↗` icon (`Maximize2`), the modal MUST strictly adhere to Figma frame `6095:96370`:
    1. **Header**: Contains the entity title (e.g. `Create Item`, `Edit Schedule Day`) with `(Row X)` in tertiary text (`#737373`), and a circular top-right close `X` button.
    2. **Body**: Clean white background (`#ffffff`), 24px padding, 2-column input grid (`gap: 20px`). `type: 'readonly'` fields render as formatted text blocks (`#FAFAFA` background, 44px height, 12px border radius). Supports custom slot `#expand-modal="{ row, index }"`.
       - **Full-Row Completeness**: `#expand-modal` MUST include **all** fields for the row—both the primary scanning columns shown inline in the table AND all secondary/scope fields. Never omit the inline table fields from the expanded row modal.
       - **Description Always Last**: Any description or notes field (`<FormTextarea>` in modals, `<FormRichText>` accordion in pages) MUST ALWAYS be placed **at the bottom below all structured form inputs and checkboxes**, never at the top.
    3. **Footer**: Height 74px, canvas background (`#FAFAFA` / `var(--color/background/primary)`), subtle border-top (`#E5E5E5`).
       - **Bottom-Left**: Red error/destructive button **`Delete`** (`bg-[#fb2c36]`, rounded 8px, semi-bold white text).
       - **Bottom-Right**: Group of standardized secondary buttons (`bg-white`, border `#D9D9D9`, rounded 8px, secondary text `#404040`):
         - `ArrowDown` icon button: Navigates down to the next row.
         - `ArrowUp` icon button: Navigates up to the previous row.
         - `Duplicate Row` button: `Copy` icon + "Duplicate Row". Duplicates current row.
         - `Insert Above` button: `Plus` icon + "Insert Above". Inserts a blank row above current row.
         - `Insert Below` button: `Plus` icon + "Insert Below". Inserts a blank row below current row.
    4. **Zero Ad-Hoc Modals**: NEVER use `QuickCreateModal` for dynamic table rows. Always use the authoritative `<DynamicTableModal />` via `<DynamicSubTable />`.
- **Dynamic SubTable Scanning Columns & Inset Invariant (Strict 3–5 Columns & 24px Padding)**:
  - **3 to 5 Scanning Columns Only**: In-table columns for `<DynamicSubTable />` MUST be strictly restricted to **3 to 5 core mandatory scanning attributes**. NEVER dump all entity fields or secondary attributes into the table header.
  - **Scope & Secondary Fields Inside Row Modal**: All secondary attributes, scopes, validity ranges, and optional metadata MUST be housed exclusively inside the `#expand-modal="{ row, index }"` slot (`<DynamicTableModal>` accessed via the `↗` Maximize icon).
  - **Mandatory 24px Container Inset**: The container card hosting `<DynamicSubTable />` MUST declare `padding: 24px; display: flex; flex-direction: column; gap: 16px;`. **NEVER** wrap `<DynamicSubTable />` in a zero-padding wrapper (`.subtable-body { padding: 0 }`), which jams the dynamic table and the `+ Add Row` action button against the outer card borders.
- **Collapsible Description Card Invariant (Zero Sharp Edges & Zero Inline `<textarea>`)**:
  - **Zero Inline Textarea**: Operational narratives, statutory guidelines, procedural notes, and descriptions MUST NEVER be placed as a `<textarea>` or `<FormTextarea>` inside the master parameters grid card.
  - **Dedicated Collapsible Accordion Card**: Descriptions MUST be placed in their own separate `<div class="clean-card accordion-card">` beneath the master card.
  - **Mandatory `overflow: hidden` (Sharp Edge Prevention)**: Both `.clean-card` and `.clean-card.accordion-card` MUST declare `overflow: hidden; border-radius: 12px;`. The header (`.card-accordion-header`) and body (`.card-accordion-body`) must explicitly respect and clip to this border radius (via `overflow: hidden` and `border-radius: inherit`) so child element backgrounds NEVER bleed past card boundaries or create square 90° corners when open or collapsed.
  - **Editor Component**: Rendered strictly with `<FormRichText v-model="form.description" />`. Inside the accordion body, `<FormRichText>` MUST NOT declare a `label` prop (the collapsible header already identifies the section; adding an inner label causes redundant double labeling), and MUST use the standard default height (`220px` — NEVER shrink it with `:minHeight="140"`).
  - **Single Explanatory Header Title (No Stacked Title + Subtitle)**: The header `.card-accordion-header` MUST declare a single, concise, explanatory title (e.g. `<span>Description</span>`, `<span>Mandate Guidelines</span>`, `<span>Routing Rationale</span>`). NEVER stack a title and secondary description/subtitle inside the accordion header.
- **No Verbose Section Headers or "Solutionary Explanations" in Forms**:
  - Configuration blueprint cards and form sections must NEVER contain oversized, redundant section title/subtitle headers (e.g. `.config-header`) or multi-sentence "solutionary explanations". Keep section cards clean and focused purely on form inputs.
  - Operational rules, policy context, and narrative descriptions MUST be placed in their own separate card/section using `<FormRichText />` (`FormRichText.vue`).
  - When explanation is necessary, provide only a small, concise 1-line hint or metadata label (`hint="..."` or `.card-plain-desc`), never large explanatory banners.

## Dropdown & Popover Standard: Zero Raw Browser Selects

- **Zero Raw Browser `<select>` Tags or Overlays**: NEVER use HTML `<select>` tags or native select overlay tricks (`opacity: 0; position: absolute; inset: 0`).
- **Mandatory QMT Popover Dropdowns**: ALL dropdowns, per-page selectors, filters, header calendar switchers, and form selectors across the entire ERP MUST use custom QMT design system popovers (`FormSelect.vue` or custom teleported QMT dropdown popovers as in `BasePagination.vue`).
- **Behavior & Positioning**: Dropdown menus must render with custom listbox options, dynamic fixed positioning via `<Teleport to="body">`, scroll/resize sync, search capabilities where applicable, and custom checkmarks (`#0B529C` brand blue active background `#e1eefd`). Dropdown menus must never shrink inside overflow-hidden parent containers or summon native OS popup chrome.
- **Short Selection Placeholders**: Keep the full field meaning in the label and use a concise, action-led `Select [core noun]` placeholder: `Statutory Purchase Method` → `Select Method`; `Category Scope` and `Buying Desk Scope` → `Select Scope`. Do not repeat long labels or use explanatory phrases such as `All Categories (Global Scope)` as form placeholders. `All ...` prompts are appropriate for filters because they describe filter behavior.

## QMT Icon Standardization & Zero Ad-Hoc SVGs

- **Zero Ad-Hoc or Generated SVGs**: NEVER create inline `<svg>` tags or generate arbitrary SVG vectors for UI icons. All icons throughout the entire system MUST use official, standardized icon components with exact naming corresponding to the QMT Team Library (`EVkNwnkJXcHROkdv2QqXoU`).
- **Lucide Icon Mapping**: Standard QMT icons map 1:1 to named components from `lucide-vue-next` (e.g. `Search`, `Filter`, `ArrowLeft`, `ArrowRight`, `ChevronDown`, `ChevronUp`, `Check`, `Plus`, `Trash2`, `Edit`, `MoreVertical`, `Calendar`, `User`, `Users`, `Settings`, `PanelLeft`, `GripVertical`, `Clock`, `Sparkles`, etc.). Always import them by name from `lucide-vue-next`.
- **Authoritative Custom Icon Components**: The only authorized custom vector component is `IconColumnSolid.vue` (Figma `6095:96606` / `column-solid`), which is strictly used for the 3-column solid column-toggle trigger icon in data tables and sub-tables. Never replace it with inline SVGs or outline `Columns` icons.
- **Official QMT Icon Color Tokens**: Always color icons using the predefined QMT icon color token names (`icon-brand` `#0B529C`, `icon-secondary` `#404040`, `icon-tertiary` `#737373`, `icon-success` `#009966`, `icon-error` `#E7000B`, `icon-warning` `#E17100`, `icon-info` `#0084D1`). Remember: `icon-secondary` (`#404040`) is the darkest standard icon color across the system.
- **Non-Icon SVGs Permitted Only for Graphics & Charts**: Inline `<svg>` elements are strictly limited to data charts (e.g. circular donut charts), document letterhead brand marks/seals, and decorative ambient blur assets. Any functional or interactive UI icon MUST be a named component.

## Canonical Figma Ground Truth Reference Artboard (`10178:21881`) & Page Composition Standard

**MANDATORY RULE FOR ALL FIGMA WORK**: Before designing, creating, or modifying any page or frame in Figma, ALL AI agents MUST use the authoritative reference artboard:
- **File**: Haleta ERP — Procurement Module (`05qJWp6THRmHsOuLX8oc5U`)
- **Canonical Node**: [`10178:21881`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10178-21881) — **`Resources - To Copy AnD Edit`**

### 1. Authoritative Templates Available to Copy (Never Build from Scratch)
Never construct a screen or major section from scratch using raw shapes. ALWAYS copy and edit the exact matching template frame from node `10178:21881`:
1. **Directory Page Without Metrics Card** (`10178:30728` — `Page Without metrics card Example`):
   - Gold standard 1440px desktop shell for standard listings (Title Block, Filter Bar, Column-First Table, Pagination).
2. **Directory Page With Metrics Cards** (`10178:31133` — `Page With metrics card Example`):
   - Gold standard 1440px desktop shell with top KPI summary metric cards above the data table.
3. **Tabular Create Page** (`10178:31718` — `Tabular Create Page - To Copy`):
   - Dedicated master-detail creation form with sticky header actions, master information cards, and `<BaseTabs />` hosting child `<DynamicSubTable />` rosters.
4. **Multi-Stage Workflow Detail Page** (`10178:33649` — `Workflow Detail Page - To Copy`):
   - Complex inspection page featuring stage progression steppers, multi-tier approvals, action audit trail, and comments.
5. **Single Approval Detail Page** (`10178:33832` — `Not Workflow Single Approval  Detail Page - To Copy`):
   - Streamlined detail view for records with direct single-tier approval/reject governance.
6. **Table Top Filter Section** (`10178:34537` — `Table Top Filter Section - To Copy`):
   - Pre-assembled filter bar instance with 400px search input, filter popover button, secondary sort button, and action controls.
7. **Dynamic Sub-Table** (`10178:23032` — `Dynamic Table - To Copy`):
   - The authoritative 1:N line items table with sequence lead column and inline row actions.
8. **Dynamic Table Expanded Row Modal** (`10178:22759` — `Dynamic Tables Expanded Modal - To Copy`):
   - 2-column input modal with standard footer controls (Delete, Up/Down navigation, Duplicate, Insert Above/Below).
9. **Quick Create Modal** (`10178:23168` — `Quick Create Modal - To Copy`):
   - Lightweight modal for on-the-fly lookup and category creation.
10. **Column Presets Strips** (`10178:34623` through `10178:34653`):
    - Pre-built vertical column blocks for Lead Checkboxes, Text, Monetary, Single/Multi Badges, and 3-Dot Actions.

### 2. Strict Execution Protocol for AI Agents
1. **Copy Before Editing**: Duplicate the target template frame into your working destination. Retain all component links, auto-layout paddings, and layer structures.
2. **Never Call `get_design_context` on the Entire Artboard**:
   - Calling `get_design_context` on the root artboard (`10178:21881`) will exceed payload limits or time out.
   - **Correct Approach**: Call `get_metadata` on `10178:21881` first to obtain shallow layer metadata, then call `get_design_context` ONLY on the specific sub-frame ID you need to inspect.
3. **Zero Detached Components / Zero Raw Shapes**:
   - Never replace a missing component with raw rectangles, ad-hoc SVGs, or unlinked text layers.
   - If a specific variant or library item cannot be resolved, **STOP and ask the user for guidance**. Hallucinating raw shapes is a strict violation of ERP standards.
4. **NEVER Use Internal `_` Base Components (Strictly `Input field`, NEVER `_Input field base`)**:
   - **NEVER** place, clone, or swap to `_Input field base`, `_Button base`, `_Checkbox base`, or any internal sub-component prefixed with an underscore (`_`).
   - Always use the public outer wrapper component **`Input field`** (which properly exposes `Required indicator *`, `Hint text`, `Help icon`, `Label`, and `State` variants) — even when cloning from a template that happened to contain `_Input field base`. If a template contains `_Input field base`, replace it with the public **`Input field`** component.

## Canonical Desktop Screen Layout & Geometry Specification (1440px Canvas)

Every desktop screen in Figma MUST be constructed using the authoritative layout hierarchy and geometry established in canonical frame [Figma `5520:79458`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=5520-79458):

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Screen Frame: 1440px Wide (Canvas: #FAFAFA)                                                                 │
├──────────────────┬──────────────────────────────────────────────────────────────────────────────────────────┤
│ Sidebar (284px   │ Top Header (1156px wide, 86px high, border-b #E5E5E5)                                    │
│  x 800px FIXED)  │ [Toggle 40px]  [Global Search: 562px pill with ⌘K]  [Actions: 40px circular] [Profile]  │
│                  ├──────────────────────────────────────────────────────────────────────────────────────────┤
│ [Module Switcher │ Main Content Container (Fluid 100% / 1108px wide with 24px margins, gap 24px)             │
│  72px, r: 16px]  │                                                                                          │
│                  │ AppBreadcrumb (Sits directly on #FAFAFA canvas, zero container box, zero border)         │
│ Nav Items        │                                                                                          │
│ (px: 16px)       │ ┌──────────────────────────────────────────────────────────────────────────────────────┐ │
│ Item: 12px x 8px │ │ Data Table Card (Full Width 100%, bg-white, border #E5E5E5, rounded-12px)            │ │
│                  │ │ ├──────────────────────────────────────────────────────────────────────────────────┤ │
│                  │ │ │ Card Title & Subtitle Block (px: 24px, py: 16px)                                 │ │
│                  │ │ │ Title: 20px semi-bold (#404040), Subtitle: 14px regular (#737373)                │ │
│                  │ │ ├──────────────────────────────────────────────────────────────────────────────────┤ │
│                  │ │ │ Table Top Filter Section (pt: 20px, pb: 19px, px: 24px)                          │ │
│                  │ │ │ [Search: 400px x 44px] [Filter: 44px] [Sort: 44px] | [Cols] [Max] [Create CTA]  │ │
│                  │ │ ├──────────────────────────────────────────────────────────────────────────────────┤ │
│                  │ │ │ Table Header Row (bg #FAFAFA, h: 44px, px: 24px, text: 12px Medium #737373)     │ │
│                  │ │ ├──────────────────────────────────────────────────────────────────────────────────┤ │
│ [Settings / Help │ │ │ Table Body Rows (h: 72px, px: 24px, py: 16px, border-b #E9EAEB)                  │ │
│  Footer px: 16px]│ │ │ [Lead Column: 300–340px] [Data Columns: flex 1 0 0] [Actions: 3-dots 60–80px]  │ │
│                  │ │ ├──────────────────────────────────────────────────────────────────────────────────┤ │
│                  │ │ │ Pagination Footer (h: 68px, px: 24px, py: 16px, border-t #E9EAEB, bg-white)      │ │
│                  │ │ │ [Showing results text]                     [ButtonGroup: Prev, 40px Pages, Next]│ │
│                  │ │ └──────────────────────────────────────────────────────────────────────────────────┘ │
└──────────────────┴──────────────────────────────────────────────────────────────────────────────────────────┘
```

### Exact Dimensional & Structural Rules:
1. **Root Screen Frame**:
   - Canvas Width: **1440px** (`w-[1440px]`).
   - Height: **900px** desktop default, or content-driven auto-layout (`min-height: 900px`).
   - Canvas Background: `#FAFAFA` (`var(--color/background/primary)`).
2. **Sidebar Navigation (`AppSidebar` / Figma `5520:79538`)**:
   - **Expanded Width**: Exactly **284px** (`w-[284px]`). Background `#FFFFFF`, right border `1px solid #E5E5E5`.
   - **Collapsed Width**: Exactly **68px** (`w-[68px]`).
   - Top Header Wrapper: Height **72px**, `px-16px pt-16px pb-0`, `margin-bottom: 20px`. Contains module selector card (`rounded-16px`, border `1px solid #E5E5E5`, bg `#FAFAFA`, icon 24px, title 16px semi-bold `#404040`).
   - Navigation Item Area: `px-16px`, vertical `gap: 4px`. Nav items: `px-12px py-8px`, `rounded-8px`.
   - Bottom Footer Actions: `pb-24px px-16px`, top divider `1px solid #E5E5E5`. Houses Settings and Help nav items.
3. **Top Header Bar (`Header` / Figma `5520:79563`)**:
   - **Width**: **1156px** (`1440px - 284px = 1156px` when expanded) or **1372px** (`1440px - 68px = 1372px` when collapsed).
   - **Height**: **86px** (`h-[86px]`), `px-24px py-20px`, background `#FFFFFF`, bottom border `1px solid #E5E5E5`.
   - Left: Sidebar toggle button (`40px × 40px`, `rounded-20px`, `bg-[#F5F5F5]`, with `sidebar open` icon `20px`).
   - Center: Global Search input: **width 562px**, **height 40px**, fully rounded pill (`rounded-[9999px]`), with search icon (`20px`), placeholder "Search Everything...", and shortcut badge `⌘K` (`20px` height, `px-4px py-3px`, `rounded-6px`, border `#E5E5E5`, bg `#FAFAFA`).
   - Right: Circular action buttons (`40px × 40px`, `rounded-[9999px]`, `bg-white`): Maximize icon, Dark/Light mode Moon icon, Translate icon, Notification Bell with red counter badge (`13px`, `bg-[#E7000B]`). Followed by vertical divider (`25px` height) and User Profile capsule (`32px` circular avatar, user name "Marta Tadesse" `#404040`, dropdown chevron).
4. **Main Content Container (Canvas Area)**:
   - Position & Padding: Sits directly in the remaining canvas area with **24px horizontal and vertical padding** (`left: calc(16.67% + 63px)` / `top: 107px`, width **1108px** inside 1156px).
   - Gap: **24px** vertical stack between breadcrumbs, metric cards, and table cards (`gap: 24px`).
5. **Breadcrumb / Top Navigation Row**:
   - Sits directly on `#FAFAFA` transparent canvas. **Zero card container, zero white box, zero border**.
   - Previous breadcrumbs & dividers use Tertiary `#737373`; active item uses Secondary `#404040` (14px).
6. **Data Table Card & Filter Section (`AppDataTable` / Figma `8957:94541`)**:
   - Container: `bg-white`, border `1px solid #E5E5E5` / `#E9EAEB`, `rounded-[12px]`, shadow `0px 1px 3px rgba(10,13,18,0.1)`. Full width of content area (`100%`).
   - Card Title Block: `px-24px py-16px`. Title 20px semi-bold (`#404040`), subtitle 14px regular (`#737373`).
   - Top Filter Bar (`Table Top Filter Section`): `pt-20px pb-19px px-24px`.
     - **Search Input**: **width 400px**, **height 44px**, `rounded-8px`, border `1px solid #D5D7DA`, search icon `20px`.
     - **Filter Button**: **height 44px**, `px-18px py-10px`, `rounded-8px`, `secondary-gray` (`#FFFFFF`, border `#D9D9D9`), bold Filter icon (`20px`, `stroke-width="2.5"`).
     - **Sort Button**: **height 44px**, `px-12px py-10px`, `rounded-8px`, `secondary-gray` (`#FFFFFF`, border `#D9D9D9`), bold Sort icon (`20px`, `stroke-width="2.5"`).
     - **Column Toggle**: **height 44px**, **width 44px** (`p-10px`), `rounded-8px`, border `1px solid #D5D7DA`, icon `<IconColumnSolid>` `20px`.
     - **Maximize Button**: **height 44px**, **width 44px** (`p-10px`), `rounded-8px`, border `1px solid #D5D7DA`, icon `maximize` `20px`.
     - **Primary Action Button**: **height 44px**, `px-16px py-10px`, `rounded-8px`, `bg-[#0B529C]`, semi-bold white text (14px), Plus icon `20px`.
7. **Table Grid, Headers & Rows**:
   - **Header Row (`Table header gray`)**: **height 44px**, `bg-[#FAFAFA]`, bottom border `1px solid #E9EAEB`, `px-24px py-12px`. Header labels: 12px Medium, `#737373`.
   - **Body Rows**: **height 72px**, bottom border `1px solid #E9EAEB`, `px-24px py-16px`.
     - **Lead Identity Column**: **width 300px–340px** (`331px` in canonical Figma frame `5520:79458`), housing row checkbox (`20px`) + entity name (14px Medium, `#404040`) + code subtext (12px Regular, `#737373`).
     - **Data Columns**: `flex: 1 0 0` (proportional distribution across remaining width, min-width 120px–200px).
     - **Actions Column**: `Table cell / Action 3-dots` (`MoreVertical`), **width 60px–80px**.
8. **Pagination Footer (`BasePagination` / Figma `8948:56247`)**:
   - **Height**: **68px**, `px-24px py-16px`, top border `1px solid #E9EAEB`, `bg-white`.
   - Left: Page result summary ("Showing 1 to 10 of 42 results").
   - Right: Square button group: Previous button, individual page buttons (**40px × 40px**, active is `bg-[#0B529C]` with white text, inactive has `#E5E5E5` borders and `#737373` text), Next button.

## Canonical QMT Library Component & Icon Translation Dictionary

Whenever creating or reviewing designs in Figma or implementing them in the ERP codebase, EVERY control must use the exact component name and variant specified below without substitution:

### 1. Buttons & Actions
| ERP Code Component | Canonical QMT Figma Component / Variant | Visual & Behavioral Contract |
| :--- | :--- | :--- |
| `<AppButton variant="primary">` | **`Button / Primary`** | Solid brand blue (`#0B529C`), semi-bold white text, 8px radius. Primary page CTA. |
| `<AppButton variant="secondary">` | **`Button / Secondary`** (`secondary-gray`) | White background (`#FFFFFF`), subtle border (`#E5E5E5`), secondary text (`#404040`). Used for Table Filter, Sort, Cancel, Close. |
| `<AppButton variant="destructive">` | **`Button / Destructive`** | Vibrant red (`#E7000B` / `#FB2C36`), white text. Delete and reject actions. |
| `<AppButton variant="outline">` | **`Button / Outline`** | Transparent background, subtle border (`#E5E5E5`), secondary text (`#404040`). |
| `<AppButton variant="ghost">` | **`Button / Ghost`** | Zero border, transparent background, secondary text. |
| `.btn-circle-nav` | **`Button / Circular Icon`** | 40px circular button (`border-radius: 9999px`) for date/calendar navigators. |
| `.btn-action-dots` | **`Table cell / Action 3-dots`** | 3-dot kebab menu button (`MoreVertical`) opening standardized action dropdown. |

### 2. Badges, Status & Metrics
| ERP Code Component | Canonical QMT Figma Component / Variant | Visual & Behavioral Contract |
| :--- | :--- | :--- |
| `<BaseBadge :color="...">` | **`Badge`** ([Figma `3345:21147`](https://www.figma.com/design/EVkNwnkJXcHROkdv2QqXoU/QMT-team-library?node-id=3345-21147)) | 100% fully rounded pill, zero border strokes. Tinted background surface: `success` (`#D0FAE5`), `gray` (`#E5E5E5` - inactive only), `indigo` (`#EEF2FF`), `blue` (`#F0F9FF`), `warning` (`#FEF3C6`), `error` (`#FFE2E2`), `primary` (`#E1EEFD`). |
| `<BadgeGroup>` | **`BadgeGroup`** ([Figma `5221:28673`](https://www.figma.com/design/EVkNwnkJXcHROkdv2QqXoU/QMT-team-library?node-id=5221-28673)) | Compound badge: inner pill (`badgeLabel`), outer text (`message`), optional trailing action arrow (`arrow`). |
| `<SaveStateBadge>` | **`Save state badge`** | Placed strictly inside `<AppBreadcrumb><template #badge>` to indicate cloud synchronization status. |
| `<MetricCard>` | **`MetricCard`** | Top KPI cards on operational pages: label (`#737373`, 12.5px), value (`#404040`, 24px), subtext (`#737373`, 12px), 14px radius. |

### 3. Form Controls & Inputs
| ERP Code Component | Canonical QMT Figma Component / Variant | Visual & Behavioral Contract |
| :--- | :--- | :--- |
| `<FormInput>` | **`Input / Default`** | Height 44px, background `#FFFFFF`, border `#E5E5E5`, focus ring `#404040`. |
| `<FormSelect>` | **`Select / Popover`** | Custom QMT popover listbox with search and brand blue checkmark. Never raw browser `<select>`. Concise `Select [Noun]` placeholder. |
| `<FormCheckbox>` | **`Checkbox`** ([Figma `3345:24771`](https://www.figma.com/design/EVkNwnkJXcHROkdv2QqXoU/QMT-team-library?node-id=3345-24771)) | Authoritative checkbox for table selection, column hider, and forms. |
| `<FormToggle>` / `<AppSwitch>` | **`Toggle`** / **`Switch`** | Inline boolean active/inactive switch control. |
| `<FormCombobox>` | **`Combobox / Searchable`** | Searchable multi-entity dropdown with async query support. |
| `<FormTextarea>` | **`Textarea / Multi-line`** | Multi-line text field for descriptions and remarks. |
| `<FormRichText>` | **`Rich text editor / Content block`** | Standalone card section for formatted narrative, operational policies, and bylaws. |

### 4. Navigation & Layout Structures
| ERP Code Component | Canonical QMT Figma Component / Variant | Visual & Behavioral Contract |
| :--- | :--- | :--- |
| `<AppBreadcrumb>` | **`Breadcrumb`** | Sits directly on `#FAFAFA` transparent canvas. Zero card container box, zero border. Previous items/dividers `#737373`, active `#404040`. |
| `<BaseTabs>` | **`Tabs / Primary (Pill capsule)`** | Primary tab switcher with fully rounded pill capsule buttons (`#0B529C` active). |
| `<UnderlineTabs>` | **`Tabs / Secondary (Underline)`** | Secondary tier tabs placed strictly beneath primary pill tabs. |
| `<AppSidebar>` | **`Sidebar / Expanded` & `Collapsed`** ([Figma `6814:162139`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=6814-162139) / [`6624:99849`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=6624-99849) / [`5520:79458`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=5520-79458)) | Collapsed: 68px width with portal flyout tooltips; Expanded: 284px width. |
| `<AppDataTable>` / `<BaseTable>` | **`Table Top Filter Section`** ([Figma `8957:94541`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=8957-94541)) | Title block (20px V, 24px H), search input, secondary Filter, secondary Sort with bold icons, column hider, primary CTA. |
| `<BasePagination>` | **`Pagination`** ([Figma `8948:56247`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=8948-56247)) | Square button group pagination footer with per-page dropdown popover. |
| `<TableFloatingBar>` | **`Table floating batch action bar`** | Fixed bottom floating bar showing selected count and batch action buttons. |

### 5. Dynamic Sub-Tables, Drawers & Modals
| ERP Code Component | Canonical QMT Figma Component / Variant | Visual & Behavioral Contract |
| :--- | :--- | :--- |
| `<DynamicSubTable>` | **`Dynamic sub-table`** ([Figma `6095:96369`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=6095-96369) / [`7009:114120`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=7009-114120)) | Combined 68px lead column (`th-lead` / `td-lead`), 1 default visible pre-populated row minimum. Zero empty states. |
| `<DynamicTableModal>` | **`Dynamic table row detail modal`** ([Figma `6095:96370`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=6095-96370)) | Header with row number + close X; 2-column input body; 74px footer with red Delete button on left, secondary navigation/duplicate/insert buttons on right. |
| `<PrintPreviewDrawer>` | **`Print preview bottom drawer`** ([Figma `5005:78527`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=5005-78527)) | Dynamic configuration on left, sheet preview canvas with page indicator on right; footer with secondary Close & Download, primary Print. |
| `<QuickCreateModal>` | **`Quick create modal`** | Lightweight modal for simple entities (<= 5–7 fields). |

### 6. Icon Component & Color Token Standardization
| Icon Token / Category | Standard Implementation | Contract Rule |
| :--- | :--- | :--- |
| **Standard UI Icons** | Exact 1:1 named mapping from `lucide-vue-next` (`Search`, `Filter`, `ArrowUpDown`, `ChevronDown`, `Check`, `Plus`, `Trash2`, `Edit2`, `Eye`, `MoreVertical`, `Calendar`, `User`, `Users`, `Scale`, etc.) | **Zero arbitrary SVGs**. All functional icons must use official named components. |
| **Custom Column Toggle Icon** | `<IconColumnSolid>` ([Figma `6095:96606`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=6095-96606)) | The ONLY authorized custom vector component, strictly used for the 3-column table column-hider trigger. |
| **Bold Icon Property** | `stroke-width="2.5"` / `class="icon-bold"` | Mandatory on Filter and Sort button icons. |
| **`icon-brand`** | `#0B529C` | Brand blue icon color. |
| **`icon-secondary`** | `#404040` | **The darkest icon color standard** across the entire system. |
| **`icon-tertiary`** | `#737373` | Muted, inactive, or secondary metadata icon color. |
| **`icon-success`** | `#009966` | Active state and verified action icon color. |
| **`icon-error`** | `#E7000B` | Destructive action and error icon color. |
| **`icon-warning`** | `#E17100` | Cautionary threshold and pending action icon color. |
| **`icon-info`** | `#0084D1` | Informational callout icon color. |

## Designing on the Web Scale

- **Primary vs Secondary Tab Hierarchy Standard**:
  - **Single Tab Rule**: Whenever a page, view, or section contains only a single tab group (standalone tabs without a parent tab above it), it **MUST ALWAYS use the Primary Tab** (`<BaseTabs type="rounded" />` / Figma `5603:2799` pill capsule). This applies to views like `OrgStructuresView.vue`, `ShiftSwapsView.vue`, `AttendanceView.vue`, `ShiftPatternCreate.vue`, etc.
  - **Consecutive / Two-Tier Tabs Rule**: The **ONLY** place a Secondary Tab (`<UnderlineTabs />` / `BaseTabs type="underline"` / Figma `5578:110`) is used is when there is already a Primary Tab at the top. If two tab tiers appear consecutively (one below the other or side by side), the top/outer is Primary and the sub-tier below it is Secondary.
- **Top Banner & Primary Action Alignment**: In top page header cards, the primary creation or major action button (e.g., "Create Structure", "Create Pattern", "Create Shift Swap", "Create Employee") MUST ALWAYS be aligned on the top right parallel to the page title and description (header text block) using flexbox (`display: flex; justify-content: space-between; align-items: flex-start;`).
- **Tabs Separation**: Tabs must NEVER house or share their row with the primary page creation CTA. Tabs reside in their own standalone row beneath the title and action header block.
- **Tab Number Badge Standard (`count` / Number Badges in Tabs)**:
  - **Directory & Listing Tabs (Strictly PROHIBITED)**: When tabs switch between distinct tables, entities, or categories on high-level directory pages (e.g. `Approval Routes` vs. `Assignment Rules` in `ProcurementRoutingRulesView.vue`), **NEVER enable or display number badges on tabs** (`count` / `badge` omitted). High-level rows are already paginated and counted via standard directory metrics and pagination footers (`Showing 1–10 of X`). Placing count badges on primary directory tabs creates visual clutter without actionable value.
  - **Create & Edit Forms with Dynamic Sub-Tables (MANDATORY)**: Number badges on tabs are **strictly intended for creation/edit forms with 1:N relations and dynamic child tables (`<DynamicSubTable />`)**, e.g.:
    - `ProcurementUnitCreate.vue` $\rightarrow$ `Unit Members (3)`
    - `ProcurementMethodCreate.vue` $\rightarrow$ `Threshold Bands (4)`
    - `WorkShiftCreate.vue` $\rightarrow$ `Shift Patterns (2)`
    This provides immediate, high-signal visibility into how many child items/lines have been attached to that specific record without clicking into the child tab.
  - **Discretionary Use**: Number badges outside creation forms are reserved exclusively for critical, high-urgency operational queues (e.g. action-required inbox tabs like `Pending Approvals (5)`), NEVER for passive directory catalogs.
- **Visual Consistency Across Screens**: Mirror the canonical layout established in Organization Structures (`OrgStructuresView.vue`), Shift Patterns (`ShiftPatternsView.vue`), and Shift Swaps (`ShiftSwapsView.vue`) — the top card encapsulates the title, subtitle, and primary CTA on row 1, followed cleanly by primary tabs, sub-views, or metric rows below.

## Standard Detail & Inspection Pages (The Three Archetypes)

- Follow `.github/instructions/detail-pages.instructions.md` for all entity detail, inspection, and approval interfaces.
- **Archetype 1: Two-Column Split Workflow Detail** (`LeaveRequestDetail`, `EmployeeMovementDetail`):
  - Used for approval/review workflows. Left column (`minmax(0, 1fr)`) holds the dossier (Hero identity card, operational blueprints, narrative/delta callouts, and sub-tables).
  - Right column (`360px`, collapsible to `68px`) holds the approval rail with the top **Focus** button (`PanelRightClose` / `PanelRightOpen`), Approver Decision form, and living multi-stage stepper with **authoritative dual linear gradient connector lines** (`#0b529c` -> `#fe9a00` -> `#d4d4d4`).
  - The approval rail MUST always reside on the right, NEVER on the left.
- **Archetype 2: 360° Master Record Dossier** (`EmployeeProfile` / Employee Directory Detail):
  - Used for master entity records with wide relational breadth across domains.
  - Structure: Hero identity card -> Master workspace card (4 metric cards + narrative with inline `[Edit Record]` link + Secondary underline tabs) -> 2x2 modular section cards in Overview (`Identity & Location`, `Employment & Placement`, `Compensation & Bank Accounts`, `Compliance & Statutory`).
  - **Strict White Card Container Law**: The ONLY element that sits directly on the transparent `#fafafa` canvas is the breadcrumb row (and bottom audit logs / stock ledger). Hero identity, metadata pillars, workspaces, metric boxes, narrative directives, tabs, tables, and simulators MUST reside in solid white card containers (`background: #ffffff; border: 1px solid #e5e5e5; border-radius: 16px;`). NEVER allow metadata rows or section titles to float nakedly on the canvas.
  - **Authoritative Figma Spacing Law (24px, 20px, 16px)**:
    - **24px**: Outer padding on major white cards (`padding: 24px`), horizontal padding on table header bars (`padding: 20px 24px`).
    - **20px**: Vertical stack gap between major page cards (`gap: 20px`), internal padding inside each of the 4 KPI metric cards (`padding: 20px`), grid gap between metric cards (`gap: 20px`), and gap between multi-column child cards.
    - **16px**: Border radius on all card containers and metric items (`border-radius: 16px`), table cell horizontal padding (`padding: 0 16px`).
  - **Zero Action Buttons in Top Navbar**: The top breadcrumb row has ZERO buttons (`Edit`, `Mark Inactive`). `Mark Inactive` is strictly on the edit/create form. The ONLY way to trigger edit is the inline semi-bold brand-blue link `[Edit Policy]` inside the workspace narrative text.
  - **Zero-Gap Secondary Tabs**: `UnderlineTabs` sit directly inside the Master Workspace Card at the bottom with NO extra wrapper box or borders.
  - **Persistent Workspace Across Tabs**: The Hero Card and Master Workspace Card (with 4 KPIs, narrative, and tabs) remain permanently visible at the top across all tab switches. Tab switching toggles only the child content below with a clean 20px gap.
- **Archetype 3: In-Place Sanction & Progressive Plan** (`ApproveHeadcountPlan`):
  - Used for structural or budgetary master plans reviewed by authorized directors.
  - Structure: Breadcrumb with embedded status badge + top header action buttons (`Cancel` outline & `Approve` brand blue) -> Submitter context banner with derived metrics capsule and justification quote box -> Approver-editable 3-column input grid -> Vertical progressive bullet audit trail.

## Detailed UI policies

The applicable files in `.github/instructions/` load by file pattern or task:

- [Frontend components](.github/instructions/frontend-components.instructions.md)
- [Creation UX](.github/instructions/creation-ux.instructions.md)
- [Detail & Inspection pages](.github/instructions/detail-pages.instructions.md)
- [Table architecture](.github/instructions/table-architecture.instructions.md)
- [Dynamic relations](.github/instructions/dynamic-relations.instructions.md)
- [Status and metrics](.github/instructions/status-metrics.instructions.md)
- [UI copy](.github/instructions/ui-copy.instructions.md)
- [Schema alignment](.github/instructions/schema-alignment.instructions.md)
