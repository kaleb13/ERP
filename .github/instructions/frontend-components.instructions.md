---
description: "Use when building or changing Haleta ERP frontend screens, Vue components, styles, or form controls. Covers reuse of shared components, QMT design tokens, QMT icon colors, and scoped UI policies."
applyTo: "frontend/src/**"
---

# Frontend Component Rules & QMT Design System Standards

## 1. QMT Predefined Color Palette (Authoritative Figma 3328:2)

All pages, views, cards, forms, and components in this repository MUST strictly use the predefined colors from the QMT Team Library (`EVkNwnkJXcHROkdv2QqXoU`):

- **Brand Blue (Primary Brand)**:
  - Base / Primary CTA: `#0B529C` (`brand-blue-700` / `var(--primitive-color-brand-blue-700)` / `var(--alias-color-brand-blue-primary)`)
  - Hover: `#0D457F` (`brand-blue-800` / `var(--primitive-color-brand-blue-800)`)
  - Subtle (Active Tab/Highlight): `#E1EEFD` (`brand-blue-100` / `var(--primitive-color-brand-blue-100)`)
  - Surface (Soft Tint / Avatar Bg): `#F1F7FE` (`brand-blue-50` / `var(--primitive-color-brand-blue-50)`)
  - Active Border: `#83BFF6` (`brand-blue-300`)
- **Neutrals (Text & Surfaces)**:
  - Page Canvas: `#FAFAFA` (`neutral-50` / `var(--alias-color-background-primary)`)
  - Card & Container Surface: `#FFFFFF` (white / `var(--alias-color-background-surface-elevated)`)
  - Subtle Surface / Row Hover: `#F5F5F5` (`neutral-100` / `var(--alias-color-background-hover)`)
  - Border Subtle / Divider: `#E5E5E5` (`neutral-200` / `var(--alias-color-border-subtle)`)
  - Border Primary / Input Outlines: `#D4D4D4` (`neutral-300` / `var(--alias-color-border-primary)`)
  - Disabled Text / Placeholder: `#A1A1A1` (`neutral-400` / `var(--alias-color-text-disabled)`)
  - Tertiary / Muted Text: `#737373` (`neutral-500` / `var(--alias-color-text-tertiary)`) — Used for inactive sections, previous breadcrumbs, unselected states, and metadata.
  - Secondary Text / Form Labels / Headers: `#404040` (`neutral-700` / `var(--alias-color-text-secondary)`) — **The darkest color in the system** for text and icons.
  - Primary Text: Strictly mapped to `#404040`. Never use `#262626` anywhere in the application unless explicitly instructed.
  - Inverse Dark Surface: `#171717` (`neutral-900` / `var(--alias-color-background-inverse)`)
- **Feedback & Status**:
  - Success / Emerald: Text `#007A55` (`emerald-700`), Icon & Strong `#009966` (`emerald-600`), Subtle `#D0FAE5` (`emerald-100`), Surface `#ECFDF5` (`emerald-50`)
  - Danger / Error / Red: Text `#C10007` (`red-700`), Icon & Strong `#E7000B` (`red-600`), Subtle `#FFE2E2` (`red-100`), Surface `#FEF2F2` (`red-50`)
  - Warning / Amber: Text `#BB4D00` (`amber-700`), Icon & Strong `#E17100` (`amber-600`), Subtle `#FEF3C6` (`amber-100`), Surface `#FFFBEB` (`amber-50`)
  - Info / Sky: Text `#0069A8` (`sky-700`), Icon & Strong `#0084D1` (`sky-600`), Subtle `#DFF2FE` (`sky-100`), Surface `#F0F9FF` (`sky-50`)

### Authoritative Dark Color & Hierarchy Policy
1. **Darkest Color is Secondary (`#404040`)**:
   - The darkest color in this system for text is **Secondary Text** (`#404040`).
   - The darkest color in this system for icons is **Secondary Icon** (`#404040` / `icon-secondary`).
   - **Never use Primary text or Primary icon (`#262626`)** anywhere in the system unless explicitly instructed for a specific section.
2. **Breadcrumb Hierarchy**:
   - **Active / Current breadcrumb**: Must use **Secondary Text** (`#404040`).
   - **Inactive / Previous breadcrumbs & dividers**: Must use **Tertiary Text / Icon** (`#737373`).
3. **Borders & Aura**:
   - Use **Secondary color** (`#404040` or derived tokens) when a prominent border or focus aura is needed.
4. **Inactive & Previous Sections**:
   - Use **Tertiary color** (`#737373`) to display unselected tabs, inactive stages, historical breadcrumbs, or subtle secondary indicators.

❌ **Strictly Forbidden**:
- Never use `#262626` (Primary text/icon).
- Never use generic Tailwind slate/blue colors (`#0f172a`, `#1e293b`, `#334155`, `#475569`, `#64748b`, `#94a3b8`, `#cbd5e1`, `#e2e8f0`, `#2563eb`, `#3b82f6`, `#1d4ed8`).

---

## 2. Mandatory QMT Icon Standardization, Colors & Naming (Authoritative Figma 3328:3)

Whenever creating a page, component, or rendering icons in this repo:

1. **Zero Ad-Hoc / Inline SVGs**: NEVER write inline `<svg>` tags or create custom SVGs for UI icons. Every UI icon must be imported by its exact name from **`lucide-vue-next`** (which mirrors the QMT Team Library icons).
2. **Icon Library**: Use **`lucide-vue-next`** (direct 1:1 mapping with the QMT Icons catalog: `Search`, `Filter`, `ArrowLeft`, `ArrowRight`, `ChevronDown`, `ChevronUp`, `Check`, `Plus`, `Trash2`, `Edit`, `MoreVertical`, `Calendar`, `User`, `Users`, `Settings`, `PanelLeft`, `GripVertical`, `Clock`, `Sparkles`, etc.).
3. **Authoritative Table Column Icon**: The only authorized custom vector component is `IconColumnSolid.vue` (Figma `6095:96606` / `column-solid`), strictly used for the 3-column solid column-toggle trigger icon in data tables and child sub-tables. Never replace it with inline SVGs or outline `Columns` icons.
4. **Icon Color Token Names**: Always color icons using the predefined QMT Icon color names:
   - **`icon-brand`** (`#0B529C` / `text-qmt-icon-brand` / `var(--qmt-icon-brand)`): Primary action icons, brand indicators.
   - **`icon-secondary`** (`#404040` / `text-qmt-icon-secondary` / `var(--qmt-icon-secondary)`): **Darkest standard icon color** across the system (toolbar controls, navigation item icons, header actions, active states).
   - **`icon-tertiary`** (`#737373` / `text-qmt-icon-tertiary` / `var(--qmt-icon-tertiary)`): Inactive breadcrumbs, dividers, default helper icons, input search icons, metric icons, unselected state icons.
   - **`icon-disabled`** (`#A1A1A1` / `text-qmt-icon-disabled` / `var(--qmt-icon-disabled)`): Inactive or unclickable icons.
   - **`icon-success`** (`#009966` / `text-qmt-icon-success` / `var(--qmt-icon-success)`): Success confirmation, verified checks.
   - **`icon-warning`** (`#E17100` / `text-qmt-icon-warning` / `var(--qmt-icon-warning)`): Caution alerts, expiration warnings.
   - **`icon-error`** (`#E7000B` / `text-qmt-icon-error` / `var(--qmt-icon-error)`): Validation error indicators, delete/trash actions.
   - **`icon-info`** (`#0084D1` / `text-qmt-icon-info` / `var(--qmt-icon-info)`): Tooltip hints, information indicators.
   - **`icon-on-brand`** (`#FFFFFF`): Icons embedded inside solid brand buttons or filled badges.
   - **`icon-inverse`** (`#F5F5F5`): Icons on dark inverse surfaces.
   - *(Note: `icon-primary` is strictly remapped to `#404040`).*

---

## 3. Shared Component Reuse

- Inspect `frontend/src/components/` and reuse established components:
  - **Navigation & Tabs**: `AppBreadcrumb`, `BaseTabs`, `UnderlineTabs` (QMT `5577:151`)
  - **Tables & Pagination**: `AppDataTable`, `BaseTable`, `BasePagination` (QMT `3345:27403`)
  - **Buttons**: `BaseButton`, `AppButton` (QMT `4503:1152`)
  - **Badges**: `BaseBadge`, `SaveStateBadge` (QMT `3345:19141`)
  - **Inputs & Selection**: `FormInput`, `FormSelect`, `FormCombobox`, `FormTextarea`, `FormCheckbox`, `FormRadio`, `FormToggle`
  - **Toasts**: `BaseToast`, `BaseToaster`, `useToast` (QMT `4055:37`)
  - **Avatars & Tooltips**: `BaseAvatar`, `AvatarGroup`, `BaseTooltip` (QMT `3345:28608` / `3345:33314`)
- Do not build parallel ad-hoc replacements. Follow the task-specific UI policies in `.github/instructions/`.

### 3.1 AppBreadcrumb Specification & Figma Component Mapping (Node 6095:94972)
- **Figma Component Node**: `6095:94972` (Dev Handoff Breadcrumb / QMT `5577:151`)
- **Root Icon**: `Monitor` (Node `6095:94974`), 16–18px, color `#737373` (`icon-tertiary`), links to platform Home (`/`).
- **Dividers**: `ChevronRight` (Node `6095:94975`), 16px, color `#737373` (`icon-tertiary`).
- **Ancestors / Links**: `Text sm/Regular` (`14px` / `20px` line-height), color `#737373` (`color/text/tertiary`), clickable `<router-link>`.
- **Current / Active Item**: `Text sm/Medium` (`14px` / `20px` line-height, weight `500`), color `#404040` (`color/text/secondary`), semantic `aria-current="page"`.
- **Inline Badge**: Optional `#badge` slot directly adjacent to the active page title for `<SaveStateBadge />` (Node `6095:94979`).
- **Spacing**: `gap: 6px` between root icon, chevrons, text items, and badge.
- **Zero Card Background (Canvas Standard)**: The breadcrumb component and its parent navigation row (`.create-header-bar`, `.top-nav-bar`, `.top-header-action-bar`, `.breadcrumb-bar`) **MUST ALWAYS sit directly on the transparent canvas background** (`background: transparent; border: none; box-shadow: none; padding: 0;`). **NEVER** enclose the breadcrumb bar inside a white card box (`background-color: #ffffff`), card container, or bordered box (`border: 1px solid #e5e5e5; border-radius: 12px; padding: 14px 24px;`).
- **Figma Generation**: When an AI builds or modifies Figma frames from design, it MUST reuse the canonical Breadcrumb instance `6095:94972` instead of creating detached frames.

### 3.2 Badge & Badge Group Specification (Figma 3345:21147 & 5221:28673)
- **BaseBadge (`BaseBadge.vue` / Figma `3345:21147`)**:
  - Authoritative pill badge supporting variants: `Size` (`sm`, `md`, `lg`), `Type` (`pill-color`, `solid`, `modern`), `Color` (`primary`/`brand`, `gray`, `error`, `warning`, `success`, `blue`, `indigo`, `purple`, `pink`, `orange`), `Icon` (`false`, `dot`, `leading`, `trailing`, `avatar`, `closable` / `X close`).
  - **Mandatory Prop Contract**: Always pass the color via `:color="..."` (NEVER `:variant="..."`, which does not exist and causes the component to default to monochrome gray).
  - **Valid Semantic Colors**:
    - `color="success"`: Active lifecycle state, approved governance, completed (`#009966`).
    - `color="gray"`: **Strictly reserved for Inactive / Dormant states** (`state === 'inactive'`). **NEVER** use `gray` for active functional lookup values or options (e.g. `Permissive`), because doing so makes valid active records appear dead or disabled.
    - `color="indigo"`: Statutory policy rules, mandatory compliance, and legal enforcement (`#432DD7` / `#EEF2FF`).
    - `color="blue"`: Permissive alternatives, secondary scopes, and informational lookup options (`#0069A8` / `#F0F9FF`).
    - `color="purple"`: Specialized operational modes or classifications (`#8200DB` / `#FAF5FF`).
    - `color="warning"`: Pending review, cautionary thresholds (`#E17100` / `#FEF3C6`).
    - `color="error"`: Rejected, failed, strict breach (`#E7000B` / `#FEE2E2`).
    - `color="primary"`: Brand blue anchor (`#0B529C` / `#E1EEFD`).
    - Never pass `'neutral'`; use `'gray'` only for mechanical inactive states.
  - **No Inactive Gray on Active Lookups**: Active operational options (e.g. `Permissive` vs `Mandatory`) must NEVER be styled with inactive gray. Use distinct QMT library colors (`indigo` and `blue`).
  - **No Monochrome Uniformity**: Never paint multiple distinct lookups with the same badge color across a table row. Use semantic contrast.
  - **No ad-hoc status pills**: Never write inline `<span class="status-pill">` or `<span class="status-dot">`. Always use `<BaseBadge type="pill-color" :color="statusColor" :dot="true" size="sm">`.
  - **SaveStateBadge (`SaveStateBadge.vue`)**: Specialized `BaseBadge` strictly placed inside `<AppBreadcrumb><template #badge><SaveStateBadge ... /></template></AppBreadcrumb>`. Never place it as an unsealed external sibling.
- **BadgeGroup (`BadgeGroup.vue` / Figma `5221:28673`)**:
  - Authoritative component for **longer badges** and compound status pills across the platform.
  - Figma Team Library Reference: [QMT Team Library Node 5221:28673](https://www.figma.com/design/EVkNwnkJXcHROkdv2QqXoU/QMT-team-library?node-id=5221-28673&t=0vdo4adqS3KKDEy8-4).
  - Compound pill container housing an inner `BaseBadge`, a text message, and an action arrow button (`ArrowRight`).
  - Variants: `badgePosition` (`leading` | `trailing`), `size` (`md` [30px] | `lg` [32px]), `color` (`gray`, `primary`/`brand`, `warning`, `success`, `error`), `arrow` (`true` | `false`), `clickable` or `:to` (interactive hover state).
  - Used for announcements, system status summaries, live metric highlights, and inventory notices (e.g. `StockSummary.vue`). Single status pills with dot (like `Biometric Sync: 4 Devices Online` in `AttendanceView.vue` top bar and table status cells) use `BaseBadge` (Figma `3345:21147` / `7221:140247`).
  - **Rule for Longer Badges**: Whenever creating or editing longer badges or compound notifications in code or in Figma, you MUST ALWAYS use the canonical `Badge group` component (`5221:28673`). Never create ad-hoc pill divs.
- **Lookup Values Representation Standard (Discretionary Badges vs. Plain Text)**:
  - **Status and State are Always Badges**: In all tables, sections, and views across the entire system, **Status** (`status_lookup_value_id`, governance status, workflow status) and **State** (`active` / `inactive`) MUST ALWAYS be represented with badges (`BaseBadge` / status pills).
  - **Dual Appearance for Schema Lookups**: All other schema lookups (e.g., operation modes, spend classes, receipt modes, unit types, procurement methods) have two valid visual representations:
    1. **Plain Tertiary Text** (`#737373` / `.tertiary-plain-text`): Quiet, clean typography for secondary, informational, or high-density categorical columns.
    2. **Badges** (`BaseBadge`): Visually anchored pills for high-salience operational classifications.
  - **Agent Decision Authority & Balancing Principle**: The agent/designer has the discretion and responsibility to decide whether each lookup column is best rendered as plain text or as a badge:
    - *Avoid Badge Clutter*: Carefully inspect the table's visual density. Never overload a table row with badges across multiple columns, which creates visual noise and degrades scanability.
    - *Avoid Hidden Information*: Never bury critical operational distinctions in plain text if doing so conceals vital workflow differences or routing categories from quick visual identification.
    - *Decision Criteria*: Evaluate the operational impact, cardinality, and column count of the specific table. If a lookup represents a critical operational mode (e.g. `Centralized` vs `Decentralized` procurement unit mode) in a moderate table, a badge may be optimal; if the table already has several badged/highlighted columns or the lookup is secondary metadata, render it in clean plain tertiary text.

### 3.3 Date & Calendar Header Navigation Standard (Figma 6328:119469 & 6328:119471)
- **Today Button (`.btn-today-pill`)**:
  - `40px` height, `16px` padding-x, white background `#FFFFFF`, subtle border `1px solid #D9D9D9` / `#E5E5E5`, `8px` border radius, `#404040` semibold text with `Calendar` icon (`18px`), subtle shadow.
- **Circular Directional Navigators (`.btn-circle-nav`)**:
  - `40px × 40px` fully circular button (`50%` radius), white background, subtle border `1px solid #D9D9D9`, `#404040` icon (`ChevronLeft` / `ChevronRight` `18px`).
- **Date Title (`.nav-date-title`)**:
  - `16px` / `24px`, semibold `#404040`, centered between the left and right circular buttons with `16px` gap.
- Used consistently across `CalendarView.vue` and `AttendanceView.vue`.

### 3.4 Tab Hierarchy Specification: Primary vs Secondary Tabs (Figma 5603:2799 & 5578:110)
- **Primary Tabs (`BaseTabs` with `type="rounded"` / Figma `5603:2799`)**:
  - Pill capsule bar with `#F5F5F5` background, `1px solid #E5E5E5` border, and active white pill (`#FFFFFF`) with subtle shadow and `#404040` text.
  - **Single Tab Rule**: Whenever a page, view, or section contains a single tab bar (e.g. `OrgStructuresView.vue`, `ShiftSwapsView.vue`, `AttendanceView.vue`, `ShiftPatternCreate.vue`), it **MUST ALWAYS use Primary Tabs**.
- **Secondary Tabs (`UnderlineTabs` or `BaseTabs type="underline"` / Figma `5578:110`)**:
  - Horizontal bottom border `#D4D4D4` with `#0B529C` brand accent line indicator and `#E1EEFD` active background.
  - **Consecutive / Two-Tier Tabs Rule**: The **ONLY** place a Secondary Tab is used is directly beneath/nested within a Primary Tab at the top. When two levels of tabs appear consecutively (one below the other or side by side), Level 1 is always Primary and Level 2 is Secondary. Never use a secondary underline tab as an isolated/single tab on a page.

### 3.5 Form Select Placeholder Copy

- Keep the full field meaning in the label and make a form selector's placeholder a short action plus the core noun: `Statutory Purchase Method` → `Select Method`; `Category Scope` and `Buying Desk Scope` → `Select Scope`.
- Do not repeat long labels or place explanatory/global-scope copy in form placeholders. If an optional `null` value represents an all/global scope, let the empty control show `Select Scope`; use `All ...` wording for filters, where it describes filter behavior.

### 3.6 Actions Column Standard (3-Dot Kebab Menu / Figma 3345:21133)

- **Mandatory 3-Dot Kebab Menu**: In all directory and data tables across Haleta ERP, the Actions column MUST ALWAYS use a 3-dot icon button (`MoreVertical` from `lucide-vue-next`, size `15px` / `16px`, class `.btn-action-dots`).
- **Zero Loose Inline Buttons**: Never render bare inline action buttons (such as `Eye`, `Edit2`, and `Trash2` side-by-side) in table rows.
- **Action Dropdown Popover (`.action-menu-popup`)**: Clicking the 3-dot trigger button displays a floating popover with options:
  - Inspect / View Details (`Eye` icon `14px`)
  - Edit Record (`Edit2` icon `14px`)
  - Status/State Toggle (`Check` icon `14px`)
  - Separator line (`.menu-divider`)
  - Delete / Destructive (`Trash2` icon `14px` with `.danger` styling in `#E7000B`)
- **Outside-Click Dismissal**: Action menus must close on outside click and Escape key, with listener cleanup in `onUnmounted`.

---

## 4. QMT Typography, Font Size, Line Height, Font Weight & Alignment Standards

All typography across Haleta ERP must strictly mirror the authoritative styles defined in the QMT Team Library (`EVkNwnkJXcHROkdv2QqXoU` / Figma Text Styles).

### 4.1 Authoritative QMT Text Styles Scale

| Figma Style Name | Font Size | Line Height | Font Weight | Tailwind / CSS Utility Class | Typical Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`Text xs/Regular`** | `12px` | `18px` | `400` (Regular) | `.qmt-text-xs-regular` / `text-qmt-xs font-qmt-regular` | Helper text, breadcrumbs, tags, timestamps |
| **`Text xs/Medium`** | `12px` | `18px` | `500` (Medium) | `.qmt-text-xs-medium` / `text-qmt-xs font-qmt-medium` | Micro badges, secondary pill labels, compact chips |
| **`Text xs/Semibold`** | `12px` | `18px` | `600` (Semibold) | `.qmt-text-xs-semibold` / `text-qmt-xs font-qmt-semibold` | Status badges, table column headers, uppercase labels |
| **`Text sm/Regular`** | `14px` | `20px` | `400` (Regular) | `.qmt-text-sm-regular` / `text-qmt-sm font-qmt-regular` | Form input values, body copy, descriptions |
| **`Text sm/Medium`** | `14px` | `20px` | `500` (Medium) | `.qmt-text-sm-medium` / `text-qmt-sm font-qmt-medium` | Form labels, table cell text, dropdown menu items |
| **`Text sm/Semibold`** | `14px` | `20px` | `600` (Semibold) | `.qmt-text-sm-semibold` / `text-qmt-sm font-qmt-semibold` | Primary buttons, tabs, card headers, table header bold |
| **`Text md/Regular`** | `16px` | `24px` | `400` (Regular) | `.qmt-text-md-regular` / `text-qmt-md font-qmt-regular` | Dialog body text, spacious readable content |
| **`Text md/Medium`** | `16px` | `24px` | `500` (Medium) | `.qmt-text-md-medium` / `text-qmt-md font-qmt-medium` | Section headers, medium button labels |
| **`Text md/Semibold`** | `16px` | `24px` | `600` (Semibold) | `.qmt-text-md-semibold` / `text-qmt-md font-qmt-semibold` | Card titles, modal titles, sub-section headings |
| **`Text lg/Regular`** | `18px` | `28px` | `400` (Regular) | `.qmt-text-lg-regular` / `text-qmt-lg font-qmt-regular` | Subtitles, intro text |
| **`Text lg/Medium`** | `18px` | `28px` | `500` (Medium) | `.qmt-text-lg-medium` / `text-qmt-lg font-qmt-medium` | Prominent subheadings |
| **`Text lg/Semibold`** | `18px` | `28px` | `600` (Semibold) | `.qmt-text-lg-semibold` / `text-qmt-lg font-qmt-semibold` | Page section headers, panel title |
| **`Text xl/Regular`** | `20px` | `30px` | `400` (Regular) | `.qmt-text-xl-regular` / `text-qmt-xl font-qmt-regular` | Large banner body text |
| **`Text xl/Medium`** | `20px` | `30px` | `500` (Medium) | `.qmt-text-xl-medium` / `text-qmt-xl font-qmt-medium` | KPI card subheadings |
| **`Text xl/Semibold`** | `20px` | `30px` | `600` (Semibold) | `.qmt-text-xl-semibold` / `text-qmt-xl font-qmt-semibold` | Page main titles, top header titles |
| **`Text xl/Bold`** | `20px` | `30px` | `700` (Bold) | `.qmt-text-xl-bold` / `text-qmt-xl font-qmt-bold` | Strong headline titles, key metrics |
| **`Text 2xl/Semibold`**| `24px` | `32px` | `600` (Semibold) | `.qmt-text-2xl-semibold` / `text-qmt-2xl font-qmt-semibold` | Primary page titles, hero headers |
| **`Text 3xl/Semibold`**| `32px` | `40px` | `600` (Semibold) | `.qmt-text-3xl-semibold` / `text-qmt-3xl font-qmt-semibold` | Prominent statistics, dashboard counter numbers |
| **`bold/Desk`** | `60px` | `40px` | `700` (Bold) | `.qmt-bold-desk` / `text-qmt-desk font-qmt-bold` | Hero metrics, massive display numbers |

### 4.2 Text Alignment Standards

Always align text according to its semantic role:
- **`.qmt-text-left`** (`text-left`): Default for text, labels, descriptions, and string table columns.
- **`.qmt-text-center`** (`text-center`): Avatars, icons, status badges, and action columns.
- **`.qmt-text-right`** (`text-right`): Numeric columns, currency values, financial summaries, and pagination counters.
- **`.qmt-text-justify`** (`text-justify`): Multi-paragraph legal or policy content.

### 4.3 Text Color Tokens (Authoritative Figma `color/text/*`)

- **`color/text/primary`** (`#262626` / `text-qmt-text-primary` / `var(--alias-color-text-primary)`): Headings, titles, main data.
- **`color/text/secondary`** (`#404040` / `text-qmt-text-secondary` / `var(--alias-color-text-secondary)`): Form field labels, subheadings, supporting text.
- **`color/text/tertiary`** (`#737373` / `text-qmt-text-tertiary` / `var(--alias-color-text-tertiary)`): Captions, helper text, empty states, metadata.
- **`color/text/disabled`** (`#A1A1A1` / `text-qmt-text-disabled` / `var(--alias-color-text-disabled)`): Placeholders, disabled actions.
- **`color/text/brand-primary`** (`#0B529C` / `text-qmt-text-brand`): Brand links, active states.
- **`color/text/brand-secondary`** (`#BDDBFA` / `text-qmt-text-brand-secondary`): Secondary brand highlights on dark backdrops.
- **`color/text/on-brand`** (`#FFFFFF` / `text-qmt-text-on-brand`): Text on solid brand buttons or dark surfaces.
- **`color/text/success`** (`#007A55` / `text-qmt-text-success`): Positive status badges, approvals.
- **`color/text/error`** (`#C10007` / `text-qmt-text-error`): Error text, destructive badges.
- **`color/text/warning`** (`#BB4D00` / `text-qmt-text-warning`): Caution text, pending badges.
- **`color/text/info`** (`#0069A8` / `text-qmt-text-info`): Informational callouts.

---

## 5. Designing on the Web Scale: Header Layout & Action Alignment

To ensure rock-solid visual consistency and predictable layout hierarchy across all web pages and management views in Haleta ERP:

### 5.1 Primary Creation Button Alignment
- **Parallel to Page Title & Description**: The primary action or creation button (e.g., "Create Structure", "Create Pattern", "Create Shift Swap", "Create Employee") must ALWAYS be placed on the far right of the top header row, directly aligned with the page title and descriptive subtitle using flexbox (`display: flex; justify-content: space-between; align-items: flex-start;`).
- **Layout Architecture**:
  ```html
  <div class="master-header-card">
    <div class="header-top-row">
      <div class="header-text-block">
        <h1 class="header-main-title">{{ pageTitle }}</h1>
        <p class="header-subtitle">{{ pageDescription }}</p>
      </div>
      <button type="button" class="btn-primary-create" @click="handleCreate">
        <Plus :size="18" />
        <span>Create Entity</span>
      </button>
    </div>

    <!-- Tabs Row (Standalone) -->
    <div v-if="hasTabs" class="header-tabs-row">
      <BaseTabs v-model="activeTab" :tabs="tabs" type="rounded" size="sm" />
    </div>
  </div>
  ```

### 5.2 Strict Prohibition: Never Embed Primary CTA inside Tabs
- **Zero Primary Action inside Tabs**: NEVER put primary creation buttons into the `#right` slot or right-hand section of tabs.
- **Tabs Role**: Tabs are strictly dedicated to navigation and view-switching (e.g., Table vs. Tree/Diagram view). They must stretch cleanly across their own row without housing page-level creation actions.
- **Canonical Reference Implementations**:
  - `OrgStructuresView.vue`: `.master-header-card` with `.header-top-row` (title + description + Create Structure CTA) and `.header-tabs-row` (`<BaseTabs type="rounded" />`).
  - `ShiftPatternsView.vue`: `.patterns-top-card` aligns `.page-title` + `.page-subtitle` on the left and `.btn-create-pattern` on the right.
  - `ShiftSwapsView.vue`: `.swaps-header-row` aligns `.page-title` + `.page-subtitle` on the left and `.btn-create-swap` on the right, followed by `.swaps-primary-tabs-row` (`<BaseTabs type="rounded" />`).
  - `AttendanceView.vue`: `.attendance-top-card` with header metrics and `.top-card-tabs-wrapper` (`<BaseTabs type="rounded" />`).
