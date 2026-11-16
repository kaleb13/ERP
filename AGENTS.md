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
  - **Zero Back Buttons (Strict Breadcrumb-Only Navigation Rule)**:
    - **NEVER** place a "Back" button, back arrow button, or "Back to [List]" link anywhere in the system (`← Back to ...`, `btn-back`, `router-link` back buttons).
    - The **ONLY** way users navigate back or traverse the hierarchy is through the **Breadcrumb** (`AppBreadcrumb`).
    - When drilling down into details, inspect views, or child forms, the parent page link in the breadcrumb is clickable (`onClick: () => ...` or `to: '...'`). Redundant back buttons clutter the UI and violate Haleta ERP minimalist architecture.
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
  - **Borders & Aura**: Use **Secondary** (`#404040`) for prominent border color and focus aura.
  - **Inactive / Previous Sections**: Use **Tertiary** (`#737373`) to show inactive sections, previous steps, unselected states, and helper metadata.
- For UI work, follow the scoped frontend instructions and verify the actual screen and states involved.
- For schema-backed features, inspect the authoritative schema before designing fields or payloads; do not invent columns.
- Run the smallest relevant test, build, or type-check for code changes. Report what was run and any validation that remains.
- If instructions conflict or a design decision would change user-facing behavior, explain the conflict and ask before choosing.

## Standard Directory Tables

- Follow `.github/instructions/table-architecture.instructions.md` for both ERP tables and their Figma counterparts.
- Use a title block with `20px` vertical and `24px` horizontal padding, followed by the linked QMT **Table Top Filter Section**; only override its search text and primary action label.
- Keep table content full-bleed to the card edges. Use the linked QMT **Pagination** footer, not a custom text footer.
- Integrate row selection into the first identity column: the header cell has text and checkbox enabled, and body cells use the **Lead checkbox** variant. Do not add a checkbox-only column.
- Keep the identity column visible when it hosts selection controls. In Vue, use `AppDataTable`/`BaseTable`, `FormCheckbox`, and the shared pagination.
- **Table Sort Button & Secondary Button Standard**: The Sort button in the Table Top Filter Section MUST ALWAYS be styled as our **Secondary Button** (`secondary-gray`: white background `#ffffff`, subtle border `#e5e5e5`, secondary text `#404040`), identical to the Filter button. It must NEVER be styled as a colored/brand-blue button. Both Filter (`Filter`) and Sort (`ArrowUpDown`) button icons MUST use `stroke-width="2.5"` (`class="icon-bold"`).
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
    3. **Footer**: Height 74px, canvas background (`#FAFAFA` / `var(--color/background/primary)`), subtle border-top (`#E5E5E5`).
       - **Bottom-Left**: Red error/destructive button **`Delete`** (`bg-[#fb2c36]`, rounded 8px, semi-bold white text).
       - **Bottom-Right**: Group of standardized secondary buttons (`bg-white`, border `#D9D9D9`, rounded 8px, secondary text `#404040`):
         - `ArrowDown` icon button: Navigates down to the next row.
         - `ArrowUp` icon button: Navigates up to the previous row.
         - `Duplicate Row` button: `Copy` icon + "Duplicate Row". Duplicates current row.
         - `Insert Above` button: `Plus` icon + "Insert Above". Inserts a blank row above current row.
         - `Insert Below` button: `Plus` icon + "Insert Below". Inserts a blank row below current row.
    4. **Zero Ad-Hoc Modals**: NEVER use `QuickCreateModal` for dynamic table rows. Always use the authoritative `<DynamicTableModal />` via `<DynamicSubTable />`.
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

## Designing on the Web Scale

- **Primary vs Secondary Tab Hierarchy Standard**:
  - **Single Tab Rule**: Whenever a page, view, or section contains only a single tab group (standalone tabs without a parent tab above it), it **MUST ALWAYS use the Primary Tab** (`<BaseTabs type="rounded" />` / Figma `5603:2799` pill capsule). This applies to views like `OrgStructuresView.vue`, `ShiftSwapsView.vue`, `AttendanceView.vue`, `ShiftPatternCreate.vue`, etc.
  - **Consecutive / Two-Tier Tabs Rule**: The **ONLY** place a Secondary Tab (`<UnderlineTabs />` / `BaseTabs type="underline"` / Figma `5578:110`) is used is when there is already a Primary Tab at the top. If two tab tiers appear consecutively (one below the other or side by side), the top/outer is Primary and the sub-tier below it is Secondary.
- **Top Banner & Primary Action Alignment**: In top page header cards, the primary creation or major action button (e.g., "Create Structure", "Create Pattern", "Create Shift Swap", "Create Employee") MUST ALWAYS be aligned on the top right parallel to the page title and description (header text block) using flexbox (`display: flex; justify-content: space-between; align-items: flex-start;`).
- **Tabs Separation**: Tabs must NEVER house or share their row with the primary page creation CTA. Tabs reside in their own standalone row beneath the title and action header block.
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
