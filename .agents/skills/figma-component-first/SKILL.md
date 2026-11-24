---
name: figma-component-first
description: "Use for creating or editing Figma screens, frames, forms, sidebars, or components. Requires verified reuse of existing Figma components and a user decision before any substitute."
---

# Figma Component-First Workflow

Use this workflow for every Figma design edit in the Haleta ERP file.

## 0. Canonical Reference Artboard (`10178:21881`) — Always Copy, Never Build from Scratch

Before creating any new screen or editing existing layouts, AI agents MUST refer to the official **Resources - To Copy AnD Edit** artboard:
- **File**: Haleta ERP — Procurement Module (`05qJWp6THRmHsOuLX8oc5U`)
- **Canonical Node**: [`10178:21881`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10178-21881) — **`Resources - To Copy AnD Edit`**

### Pre-Assembled Page Templates to Duplicate:
- **Standard Listing / Directory (No Metrics)**: Frame `10178:30728` (`Page Without metrics card Example`)
- **Standard Listing / Directory (With Metrics)**: Frame `10178:31133` (`Page With metrics card Example`)
- **Tabular Create Page (1:N Sub-table Tabs)**: Frame `10178:31718` (`Tabular Create Page - To Copy`)
- **Workflow Detail & Multi-Stage Approval**: Frame `10178:33649` (`Workflow Detail Page - To Copy`)
- **Single Approval / Direct Inspection Detail**: Frame `10178:33832` (`Not Workflow Single Approval  Detail Page - To Copy`)
- **Table Top Filter Section Instance**: Instance `10178:34537` (`Table Top Filter Section - To Copy`)
- **Dynamic Sub-Table Instance**: Frame `10178:23032` (`Dynamic Table - To Copy`)
- **Dynamic Sub-Table Row Expand Modal**: Frame `10178:22759` (`Dynamic Tables Expanded Modal - To Copy`)
- **Quick Create Modal**: Frame `10178:23168` (`Quick Create Modal - To Copy`)
- **Activity Log / Version History Section**: Frame `10679:31692` (`Activity Section - To Copy`)
- **Comparison Section & Transition Detail / Create Templates (Employee Movement Pattern)**:
  - Frame [`10716:32900`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10716-32900) — Reusable Comparison / Transition reference (Current white card vs. Proposed QMT brand-blue `#F1F7FE` / `#BDDBFA` / `#0B529C` card, policy warning callout, brand-blue delta summary)
  - Frame [`10703:39712`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10703-39712) — Reusable Transition / Change Proposal Create & Detail reference
- **Column Presets Strips**: Frames `10178:34623` to `10178:34653` (Column-First pre-styled vertical columns)

### Mandatory Execution Protocol:
1. **Never build a screen from scratch**: Duplicate the appropriate base template above. This ensures 100% of the QMT component links, 1440px desktop constraints, 284px sidebar, 86px header, auto-layout paddings, and typography styles are already linked and pixel-perfect.
2. **Never call `get_design_context` on the whole canvas/artboard**: Always call `get_metadata` on node `10178:21881` first, find the specific child frame ID, and call `get_design_context` ONLY on that child frame. Calling `get_design_context` on the root artboard will time out or exceed context window limits.

## 1. Inspect before editing

1. Confirm the target Figma file, page, and frame. Do not edit a nearby reference frame.
2. Inspect the target screenshot and layer/component metadata.
3. Inspect approved nearby screens and search the file's subscribed libraries for matching components.
4. Record the source component and variant for each shared control: buttons, inputs, selects, checkboxes, badges, sidebar/navigation, and icons.

## 2. Use real component instances

- Insert an instance linked to the source component; visual similarity alone is not component reuse.
- Preserve the component link and use supported text/variant overrides. Do not detach, redraw, or replace a missing asset with ordinary shapes or text.
- Keep task-specific labels and values while using the closest semantically correct component variant.
- If a component's dimensions do not fit, do not silently distort it or alter the page. Ask whether to reflow/expand the frame, use a supplied component, or approve a reusable component.

## 3. Stop when a component is unavailable

If no suitable component is found, or the library component cannot be imported:

1. Stop before building that control.
2. Tell the user what component names/variants and libraries were searched, and what prevented reuse.
3. Ask the user to provide a component link, approve a reusable auto-layout component, or choose an existing alternative.
4. Continue only after the user chooses. Do not treat an unsuccessful search or import as permission to approximate.

## 4. ERP Layout & Creation Form Standards

- **Tabular Create Forms for 1:N Lines & Child Schemas**:
  - Whenever designing an expanded full creation form with related lines or child schemas (e.g. `ProcurementUnitMember` lines for `ProcurementUnit`, PO lines, committee members, addresses), **NEVER place child tables on the same page underneath the master card**.
  - Always use **Primary Tabs (`<BaseTabs />` pill capsule)**: Tab 1 for master entity details, Tab 2+ for related child lines and sub-tables.
- **Dynamic Table Default Non-Empty Initial State (1 Row Minimum)**:
  - When designing dynamic sub-tables (`DynamicSubTable` / Figma `6095:96580`), the default design state MUST NEVER be blank or empty.
  - ALWAYS provide at least **one pre-populated default row** in the initial design state. This ensures column layouts, text inputs, selects, numeric alignments, and interactive action controls are immediately visible and testable.
- **Dynamic Table Vertical Cell Divider Strokes (Figma Rule)**:
  - Unlike normal read-only directory tables, **Dynamic Tables** (`DynamicSubTable`) are editable grid tables and MUST display **`1px` subtle vertical divider strokes** (`color/border/subtle` `#E5E5E5`) between columns/cells.
  - Because QMT `Table header cell` and `Table cell` components only ship with a bottom stroke (`strokeBottomWeight = 1`) and `0` left/right strokes by default, whenever you assemble or edit a Dynamic Table in Figma, always set a **`1px` left-side stroke (`strokeLeftWeight = 1`, bound to `color/border/subtle`)** on every column/cell after the first column (or `1px` right-side stroke when missing) so the editable grid columns are clearly separated.
- **Dropdown & Popover Standard (Zero Native Browser Selects)**:
  - All dropdown selectors, per-page selectors, and filter pickers must use official QMT popover components (`FormSelect` / linked QMT select menus). Never use raw OS select popups or unstyled select menus.
  - **Short Selection Placeholders**: Keep the complete field name in the label; use concise `Select [core noun]` placeholder copy (for example, `Statutory Purchase Method` → `Select Method`, `Category Scope` → `Select Scope`). Avoid repeating the full label or using explanatory/global-scope text as a form placeholder. `All ...` prompts are for filters.
- **Mandatory Table Header Standard (`Table header gray`)**:
  - In all Figma directory tables and data frames, ALWAYS use the linked **`Table header gray`** component (`#FAFAFA` canvas background, subtle border `#E5E5E5`).
  - **NEVER** use `Table header white`.
  - The first header cell uses `Table header gray` with `Checkbox=True, Text=True` (combines select-all checkbox and identity label).
- **Mandatory Column-First Table Construction (Zero Row-Based Assembly)**:
  - In Figma, tables MUST ALWAYS be constructed vertically by **Columns**, NEVER horizontally by **Rows** ([Figma `10015:10134`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10015-10134) & [`5520:79511`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=5520-79511)).
  - **Outer Table Body Container (`Card Content` / `Content`)**: Horizontal Auto-Layout (`layoutMode: 'HORIZONTAL'`, `itemSpacing: 0`, `padding: 0`, `width: FILL`).
  - **Column Children (`Column` frames)**: Each column is a vertical Auto-Layout frame (`layoutMode: 'VERTICAL'`, `itemSpacing: 0`, `padding: 0`).
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
    - **`Table cell / Single badge`**: For Status (`status_lookup_value_id`), State (`active` / `inactive`), and high-salience lookups (e.g. `Mandatory` vs `Permissive`). Houses a linked `BaseBadge` instance with semantic token color.
    - **`Table cell / Multiple badge`**: When a cell houses a collection/array of tags (e.g., multiple roles, permission scopes, or assigned categories).
    - **`Table cell / Text`**: Standard text cells. Uses Secondary (`#404040`) for primary identifiers, or Tertiary (`#737373`) for secondary metadata, dates, and foreign entity names.
    - **`Table cell / Currency` / `Amount`**: Formatted monetary or numeric values with standard currency notation (ETB).
    - **`Table cell / Toggle`**: For inline boolean active/inactive or enable/disable switches.
    - **`Table cell / Progress bar`**: For visual quota consumption, allocation percentages, or completion rates.
    - **`Table cell / Trending positive` & `Trending negative`**: For performance indicators and percentage variances.
    - **`Table cell / Leader avatar` & `Avatar group`**: Avatar thumbnails for staff profiles (only on an entity's own directory) or team/committee rosters.
    - **`Table cell / Action 3-dots`**: Standard 3-dot kebab menu button (`MoreVertical`).
- **Table Top Filter Section Controls**:
  - The Sort button in data tables MUST ALWAYS be the clean **Secondary Button** (`secondary-gray`), matching the Filter button. It must NEVER be colored or brand-blue.
  - Both Filter and Sort buttons MUST use icons with `stroke-width="2.5"` (`class="icon-bold"`).
- **Table Data Representation: Status, State, and Dual-Lookup Standard (Badges vs. Plain Text)**:
  - **Status and State are Always Badged**: In all tables, directory frames, and sub-tables, `status` and `state` MUST always use linked badge component instances (`BaseBadge`).
  - **Dual Representation for Schema Lookups**: Lookups (e.g. operation mode, spend class, receipt mode, unit type, category type) have two valid visual representations:
    1. **Plain Tertiary Text** (`#737373`): Clean, quiet typography for secondary, informational, or high-density columns.
    2. **Badges** (`BaseBadge`): Visually anchored badge pills for high-salience operational classifications.
  - **Designer Discretion & Balancing Rule**: The designer/agent must evaluate the overall table composition and decide whether to represent a lookup in text or as a badge:
    - *Avoid Badge Clutter*: Do not place badges in every column. Having too many badges across multiple columns creates visual noise, eye fatigue, and destroys table scanability.
    - *Avoid Hidden Information*: Do not make critical, high-impact operational distinctions plain text if doing so conceals vital functional modes or routing workflows from quick scanning.
    - *Decision Criteria*: Weigh the operational importance, cardinality, and row density of the specific table. If a lookup represents a critical operational distinction (such as `Centralized` vs `Decentralized` in Procurement Units), a badge is effective; if the table is dense or the lookup is secondary metadata, render it as clean plain tertiary text.
    - *Badge Color*: Do not apply one badge color to every lookup for visual uniformity. When a badge is warranted, select its color for the value's meaning and contrast. **NEVER use the inactive Gray color for active lookups or options (such as Permissive)**; Gray is strictly reserved for Inactive system states (`state === 'inactive'`). Active policy and category lookups in Figma MUST use the authoritative QMT Team Library colors (`Color=Indigo` for Mandatory rules, `Color=Blue` for Permissive alternatives, `Color=Purple` or `Color=Orange` for specialized classifications). Keep State/status colors semantically distinct from ordinary classifications.
- **Mandatory 3-Dot Actions Column Standard (`MoreVertical`)**:
  - In all Figma directory tables, data frames, and sub-tables, the Actions column MUST ALWAYS use the 3-dot kebab menu button instance (`MoreVertical` / QMT 3-dot action button instance).
  - NEVER design loose inline action icons (e.g. View, Edit, and Delete icons side-by-side in the table cell). The cell strictly houses the 3-dot menu trigger.

## 5. Canonical Desktop Screen Layout & Geometry Specification (1440px Canvas)

Every desktop screen in Figma MUST be constructed using the authoritative layout hierarchy and geometry established in canonical frame [Figma `5520:79458`](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=5520-79458):

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Screen Frame: 1440px Wide (Canvas: #FAFAFA)                                                                 │
├──────────────────┬──────────────────────────────────────────────────────────────────────────────────────────┤
│ Sidebar (284px)  │ Top Header (1156px wide, 86px high, border-b #E5E5E5)                                    │
│                  │ [Toggle 40px]  [Global Search: 562px pill with ⌘K]  [Actions: 40px circular] [Profile]  │
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

## 6. Canonical QMT Library Component & Icon Translation Dictionary

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

### Conditional Expandable Checkbox Card (`FormCheckboxCard`)
- **Figma Reference Nodes**: Collapsed [`10415:37682`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10415-37682) · Expanded [`10415:37687`](https://www.figma.com/design/05qJWp6THRmHsOuLX8oc5U/Haleta-ERP---Procurement-Module?node-id=10415-37687).
- **Collapsed State**: Primary background (`#FAFAFA`) with subtle border (`1px solid #E5E5E5`), `12px` radius, containing only the checkbox with title & description.
- **Expanded State**: White card background (`#FFFFFF`) with subtle border (`1px solid #E5E5E5`), `12px` radius, revealing the conditional input(s) inside.
- **Reversible Behavior**: Depending on the schema meaning, the checkbox may either be **unchecked when collapsed / checked when expanded** (boolean-gated feature) or **checked when collapsed / unchecked when expanded** (nullable sentinel like *"No Minimum Floor"* or *"Unlimited / Open Ceiling"*).

---

## 7. Verify the result

Before reporting completion:

- Check each shared control's node type and source component/variant metadata; verify it is an instance linked to the intended component.
- Capture and inspect the complete target frame at its final size. Check clipping, wrapping, alignment, spacing, and visible states.
- Confirm the reference frame is unchanged and no unapproved substitute remains.
- Report the target frame link, component sources/variants used, any unresolved control, and any layout decision made by the user.

## Figma MCP notes

- Load the official Figma-use and Figma-generate-design guidance before mutating a file, and include both skill names on mutating Figma calls.
- Design-system search results are candidates, not proof of reuse. Verify that the component can be imported and that the final node links to its source.
- `$fig` handles are plan nodes until `await $fig.done()` materializes them. Do not read `.node` or pass a plan node to raw Plugin API methods before materialization.
- **Zero Background on Text & Text-Wrapper Frames (`fills = []`)**: Texts and inner text-grouping auto-layout frames (e.g. bank name + account wrappers inside a `#FAFAFA` pill, label/value stacks, title rows) MUST NEVER carry their own background fill. Because `figma.createFrame()` and `figma.createAutoLayout()` default to a white `#FFFFFF` fill, ALWAYS explicitly set `fills = []` immediately on every non-surface layout/text wrapper frame.
