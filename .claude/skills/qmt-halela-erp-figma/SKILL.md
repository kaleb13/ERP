---
name: qmt-halela-erp-figma
description: Use when creating, reviewing, or editing Haleta ERP screens in Figma. Requires verified reuse of linked QMT library components, schema-aware design, and final-frame validation.
---

# QMT Haleta ERP — Figma Design

Use this skill for Haleta ERP Figma screens, frames, forms, tables, and component changes. A visually similar drawing is not QMT component reuse: shared controls must remain real instances linked to the approved source components.

## Canonical Reference Artboard (`10178:21881`) — Always Copy, Never Build from Scratch

Before designing or modifying any screen in Figma, ALL agents MUST refer to the official **Resources - To Copy AnD Edit** artboard:
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
- **Column Presets Strips**: Frames `10178:34623` to `10178:34653` (Column-First pre-styled vertical columns)

### Mandatory Execution Protocol:
1. **Never build a screen from scratch**: Duplicate the appropriate base template above. This ensures 100% of the QMT component links, 1440px desktop constraints, 284px sidebar, 86px header, auto-layout paddings, and typography styles are already linked and pixel-perfect.
2. **Never call `get_design_context` on the whole canvas/artboard**: Always call `get_metadata` on node `10178:21881` first, find the specific child frame ID, and call `get_design_context` ONLY on that child frame. Calling `get_design_context` on the root artboard will time out or exceed context window limits.

## Source of truth and maintenance

Before designing, inspect the current repository guidance relevant to the screen, including `AGENTS.md` and applicable files under `.github/instructions/`. For schema-backed screens, inspect the owning domain's authoritative schema; HR uses `HR/HR_Schema_final-v4.sql` unless a newer source is explicitly identified. Check existing product screens and component implementations for current behavior and naming.

Project instructions, live schema, verified Figma library components, and current product implementations take precedence over this installed skill if they have changed. Do not invent fields, enum values, or component variants. Keep this skill maintainable by updating its `SKILL.md` when durable design rules change.

## Component-first workflow

1. Confirm the exact target Figma file, page, and frame. Do not edit a nearby reference frame.
2. Inspect the target screenshot, layers, dimensions, and component metadata; inspect relevant approved screens.
3. Search the subscribed QMT libraries for the correct component and semantically correct variant for every shared control: navigation, buttons, inputs, selects, checkboxes, badges, tables, pagination, tabs, and icons.
4. Insert linked component instances. Verify the source component and variant from metadata; visual resemblance alone does not count. Preserve component links and use only supported overrides.
5. If the required component is absent or cannot be imported, stop before drawing a substitute. Tell the user what library/component was searched and why reuse failed; ask for a component link, approval to create a reusable component, or an approved alternative.
6. Inspect the complete final frame at its intended size. Check clipping, wrapping, alignment, spacing, hierarchy, and meaningful states. Confirm reference frames were not changed and no unapproved substitute remains.
7. Report the target frame, linked components/variants used, unresolved components, and any user-approved layout decisions.

If Figma tools are available, read their current tool instructions before use. Search results are candidates, not proof of reuse. Do not claim a frame was changed or verified unless the tool confirms it.

## QMT design language

- Follow the QMT palette and tokens: brand `#0B529C`, secondary `#404040`, tertiary `#737373`, canvas `#FAFAFA`, subtle border `#E5E5E5`, success `#009966`, error `#E7000B`, warning `#E17100`, and info `#0084D1`.
- `#404040` is the darkest standard text and icon color. Do not use `#262626` or generic slate/blue colors such as `#0f172a`, `#334155`, `#475569`, or `#2563eb`.
- Use official QMT icon color tokens. Functional icons must use linked QMT icon components; do not draw arbitrary vectors. In code handoff, use the official named `lucide-vue-next` component mapping. `IconColumnSolid` is the approved table column-toggle icon.
- User-facing copy is English-only.

## Schema and form design

- Map fields, relationships, and lifecycle options to the owning schema and domain behavior before designing controls. Do not add phantom fields, manual codes, or unsupported status/state controls.
- Keep form labels complete and selector placeholders concise and action-led: `Select [core noun]`. Examples: `Statutory Purchase Method` → `Select Method`; `Category Scope` and `Buying Desk Scope` → `Select Scope`. Do not repeat the entire field label or use explanatory/global-scope copy as a form placeholder. “All ...” is for filter prompts.
- Use the QMT select/popover component, not a native browser select visual.
- Quick-create forms are for entities with five or fewer essential required fields; show only schema-backed essentials, no notes/descriptions or “Save as Draft.” Use an expand action only when the full form route exists and preserve entered values.
- Use a dedicated page or wizard for complex creation. For 1:N child records, separate master details and child rosters into primary tabs; show reactive counts and a default visible row in dynamic child tables when creating a design.
- Only show “Save as Draft” when the schema supports a draft lifecycle.

## Directory and table composition

- Standard directory: exact page breadcrumb, then a linked QMT table card. Place title/description inside its title block, the primary CTA in the toolbar, and shared pagination in the footer. Operational pages may include the required metric grid; governance/reference directories do not by default.
- **Mandatory Table Header Standard (`Table header gray`)**:
  - ALWAYS use the linked **`Table header gray`** component (`#FAFAFA` canvas background, subtle border `#E5E5E5`).
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
- Use 5–8 high-signal default columns, with secondary columns available through the column hider. Keep tables full-width without horizontal scrolling on standard desktop layouts.
- Keep columns atomic: one field per column. The first identity column contains row-selection controls; do not add a checkbox-only column. Keep the identity column visible.
- Label the Actions header. Its cells use one linked 3-dot kebab action-button instance (`Table cell / Action 3-dots`), not loose View/Edit/Delete icons.
- Sort and Filter use matching secondary-button variants and bold icons.
- Status and State are badges. Do not conflate business status with mechanical Active/Inactive state; use domain terminology where specified by the schema guidance.
- Other lookups may be plain tertiary text or badges according to operational importance and visual density. Do not badge every lookup or use one color for every category. Gray is only for inactive/dormant state. Use semantic QMT colors for high-salience distinctions; e.g., Mandatory and Permissive must remain distinct.
- Do not badge raw counts, dates, numbers, or simple booleans. Use the linked BadgeGroup component for longer compound badges where appropriate.

## Layout hierarchy

- Use the canonical linked breadcrumb component. Top-level directory breadcrumbs contain exactly the page name; detail views may add a linked parent. Previous items/dividers are tertiary; current item is secondary. A save-state badge belongs inside the breadcrumb's badge slot.
- A lone tab row is primary pill tabs. Underline tabs are only for a secondary tier beneath primary tabs.
- Keep the page title/description and main action together in the header; place tabs on a separate row below.
- Use the established QMT calendar header pattern: rectangular Today button, circular directional controls, centered date title.
- For 1:N creation, never stack the child table below the master card on the same form page; use dedicated primary tabs.

## Canonical Desktop Screen Layout & Geometry Specification (1440px Canvas)

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

---

## Final validation checklist

- Correct target file/page/frame confirmed.
- Every shared control is a verified linked instance of the correct component and variant.
- Schema/domain fields, labels, and lifecycle states are valid.
- QMT color, typography, hierarchy, table, badge, breadcrumb, and placeholder rules are followed.
- Final frame checked at intended size; no clipping or unapproved substitute remains.
- Report the frame link, component sources/variants, validation, and any unresolved decision.
