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

## Detailed UI policies

The applicable files in `.github/instructions/` load by file pattern or task:

- [Frontend components](.github/instructions/frontend-components.instructions.md)
- [Creation UX](.github/instructions/creation-ux.instructions.md)
- [Table architecture](.github/instructions/table-architecture.instructions.md)
- [Dynamic relations](.github/instructions/dynamic-relations.instructions.md)
- [Status and metrics](.github/instructions/status-metrics.instructions.md)
- [UI copy](.github/instructions/ui-copy.instructions.md)
- [Schema alignment](.github/instructions/schema-alignment.instructions.md)
