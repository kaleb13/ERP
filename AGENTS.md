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
  - **Breadcrumbs**: Inactive / previous breadcrumbs and dividers use **Tertiary** (`#737373`). Active / current breadcrumb uses **Secondary** (`#404040`).
  - **Breadcrumb Badges Sealing**: Status badges in the breadcrumb bar (e.g. `SaveStateBadge`) MUST ALWAYS be placed strictly inside `<AppBreadcrumb><template #badge><SaveStateBadge ... /></template></AppBreadcrumb>`. Never place them outside as an unsealed flex sibling.
  - **Badge System & Longer Badges Standard**: Never construct raw `<span class="status-pill">` or `<span class="status-dot">` tags. Always reuse `BaseBadge` (Figma `3345:21147`). For all compound or longer badges, ALWAYS reuse the authoritative `BadgeGroup` component ([Figma `5221:28673`](https://www.figma.com/design/EVkNwnkJXcHROkdv2QqXoU/QMT-team-library?node-id=5221-28673&t=0vdo4adqS3KKDEy8-4)) with inner pill, message, and action arrow.
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
