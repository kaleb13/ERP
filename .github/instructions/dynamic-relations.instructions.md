---
description: "Use when implementing ERP forms with repeatable one-to-many child records, inline tables, stacked cards, row expansion, or schema-backed child data."
---

# Dynamic Sub-Tables vs. Stacked Card Repeaters Architecture Standard

This rule defines the engineering and UI criteria for choosing between **Dynamic Inline Sub-Tables** and **Stacked Card Repeaters** for all 1:N relations across Haleta ERP.

---

## 1. Core Paradigm: The Dynamic Sub-Table (The Default Standard)

The **Dynamic Child Sub-Table** (`.child-table` inside `.child-table-wrapper`) is the mandatory default pattern for high-frequency 1:N relations.

### When to Use
Use dynamic sub-tables for all standard list-like child data where rows share a consistent structure and users need to scan or enter multiple items rapidly:
- Allowances & Compensation Components
- Bank Accounts
- Academic Qualifications
- Professional Certifications & Licenses
- Prior Work Experiences
- Technical Skills
- Spoken Languages
- Dependents & Beneficiaries
- Emergency Contacts
- Statutory Exemptions

### Layout & Behavior (Authoritative Figma Spec: `6095:96580` & Cell Library: `3345:71204`)

Reference URLs:
- **Dynamic Table Structure**: [Figma Frame 6095:96580](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=6095-96580)
- **Dynamic Table Modal & Actions**: [Figma Frame 6095:96369](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=6095-96369) & [Figma Frame 6095:96370](https://www.figma.com/design/Zo2sdiJUDpOdTRMjnswMXw/Haleta-ERP---HR-Module?node-id=6095-96370)
- **QMT Table Cells Library**: [Figma Frame 3345:71204](https://www.figma.com/design/EVkNwnkJXcHROkdv2QqXoU/QMT-team-library?node-id=3345-71204)
- **Authoritative Shared Component**: `<DynamicSubTable />` (`frontend/src/components/DynamicSubTable.vue`). This is the single unified dynamic table component across all modules in Haleta ERP. Never construct ad-hoc custom table templates or fork separate sub-table logic.
- **Zero Bespoke Modals**: Never build custom row modal overlays or bypass `<DynamicSubTable />` with ad-hoc `:use-custom-modal="true"`. Always use the native `<DynamicTableModal />` (`frontend/src/components/DynamicTableModal.vue`) row expansion engine built into `<DynamicSubTable />`.

1. **Compact Cell Standard & ERPNext Grid Cell Pattern (QMT `3345:71204`)**:
   - **Cell-As-Input Paradigm (ERPNext Grid Pattern)**:
     - Instead of floating small, bordered input boxes inside table cells, the table cell (`<td>`) **itself is the input container** (`.td-editable`).
     - The cell container has `padding: 0; min-height: 42px; position: relative; border-right: 1px solid var(--alias-color-border-subtle, #e5e5e5);`.
     - On focus or active typing, the cell itself receives the active cell outline via inner box shadow: `box-shadow: inset 0 0 0 2px var(--alias-color-brand-default, #0B529C); z-index: 5;`.
     - The inner input (`.cell-grid-input` or `.cell-inline-input`) stretches edge-to-edge across the cell (`width: 100%; height: 100%; min-height: 42px; padding: 8px 14px; border: none; outline: none; background: transparent;`) so text aligns seamlessly with column header titles.
     - **Fast Data Entry (Enter Key Traversal)**: Pressing `Enter` on any editable cell commits the value and automatically advances focus to the same column on the row below, automatically appending a fresh row if currently on the final row.
   - **Unified Table Cell Variants**:
     - *Text / Lead Text*: Edge-to-edge text cell with optional supporting subtitle (`.cell-supporting-text` in `#737373`).
     - *Number Input*: Tabular numbers, right-aligned edge-to-edge cell input.
     - *Select Dropdown (`<FormSelect variant="cell" :teleport="true" />`)*: Mandatory use of the authoritative product `<FormSelect>` component with edge-to-edge cell variant, body teleportation to prevent table overflow clipping, search filtering, option grouping, and right-aligned checkmarks (`<Check :size="16" />`). Never render raw `<select>` elements.
     - *Checkbox Cell (`<FormCheckbox />`)*: Product checkbox centered in the cell for boolean attributes.
     - *Date Cell*: Edge-to-edge date input (`.cell-grid-date`).
     - *Pill Switch*: Clean Yes / No pill switch (`.qmt-switch`, QMT `3345:71204`).
     - *Status Badge*: Fully rounded pill badge (`.cell-badge-pill`).
     - *Readonly Text*: Non-editable formatted text display.
     - *Action Icons*: Expand icon (`↗` `<Maximize2 :size="13" />`).

2. **Atomic Scanning Columns & Interactive Column Hide/Show**:
   - Display strictly 3 to 5 core mandatory scanning columns inline.
   - Column headers display optional help icons (`🛈`) which render a dark tooltip bubble on hover (`#0F172A`, title + concise description, downward caret pointer).
   - **Column Hide/Show Header Icon** (`<IconColumnSolid :size="16" />`): Clicking the header icon opens an interactive dropdown popover checklist allowing users to dynamically hide and show columns. Must use the exact 3-column solid SVG icon from Figma (`6095:96606` / `column-solid`), never generic Lucide `<Columns />`.
   - **Mandatory Default Non-Empty Initial State (1 Row Minimum)**:
     - Dynamic tables in creation forms and initial designs **MUST NEVER default to an empty state** (`[]`).
     - Always pre-populate at least **one default row** (`defaultInitialRow: true`). This ensures column structure, interactive inputs, cell dropdowns, and formatting are immediately visible and testable for users and directly mirrors how tables are presented in Figma.
     - The centered `No rows` empty state only appears if the user explicitly deletes every single row.

3. **Table Action Bar & Standardized `<AppButton>` (Always Below Table)**:
   - **Mandatory 24px Container Padding**: The outer card wrapper hosting `<DynamicSubTable />` MUST declare `padding: 24px; display: flex; flex-direction: column; gap: 16px;`. NEVER wrap `<DynamicSubTable />` in a zero-padding wrapper (`.subtable-body { padding: 0 }`), which jams the dynamic table and the `+ Add Row` action button against the outer borders.
   - **Mandatory System Button**: All dynamic table buttons MUST use the authoritative `<AppButton>` component (`variant="secondary"`, `size="sm"` with `#icon-left` slot). Never render raw HTML `<button>` or ad-hoc button classes.
   - **Default Visibility (Only Add Row)**:
     - **`+ Add Row`** is the **ONLY** button that always appears by default.
     - **Secondary Actions (`+ Add Multiple`, `Export`, `Import`)**: Must default to **hidden** (`canAddMultiple: false`, `canExport: false`, `canImport: false`) and appear dynamically ONLY on sections that explicitly require them.
   - **Left Group**:
     - `+ Add Row` (`<AppButton variant="secondary" size="sm">`): Appends a single inline blank row immediately below for instant typing.
     - `+ Add Multiple` (Dynamically enabled): Triggers the Multi-Selection Modal for batch item selection.
   - **Right Group (Dynamically Enabled Only)**:
     - `Export`: Exports table rows in **CSV format**.
     - `Import`: Imports table rows from a **CSV format** file.

4. **Distinct Cell Separation (Mandatory Right Stroke)**:
   - Every column cell (`.th-cell` and `.td-cell`) must have a distinct right stroke (`border-right: 1px solid var(--alias-color-border-subtle, #e5e5e5)`) to provide crisp, visible column boundaries and section separation.
   - The right border is omitted strictly on `:last-child`.

5. **Selection & Floating Batch Deletion Bar (`<TableFloatingBar />`)**:
   - **Lead Column Integration & Alignment Standard (Figma `7009:114120`)**:
     - The first column combines the checkbox and sequence number into a single lead column (`th-lead` / `td-lead`, exactly 68px: `width: 68px; min-width: 68px; max-width: 68px;`).
     - Never duplicate the sequence number as a separate user-defined column in the `columns` configuration.
     - **Pixel-Perfect Alignment Guarantee**:
       - Both header (`.dynamic-table th.th-lead`) and body (`.dynamic-table td.td-lead`) cells MUST share identical horizontal padding (`padding: 0 11px !important;`) and height (`44px`).
       - `.td-cell { padding: 0 }` must NEVER override `.td-lead` (enforce via `.dynamic-table td.td-lead`).
       - Both flex containers (`.lead-th-content` and `.lead-td-content`) MUST use `display: flex; align-items: center; gap: 12px;`.
       - Checkboxes inside lead cells MUST have wrapper padding/margins neutralized (`padding: 0 !important; margin: 0 !important; width: 16px; height: 16px;`).
       - This guarantees both the header checkbox and row checkboxes start at the exact same horizontal coordinate (`x = 11px`), and the header text (`No.`) and sequence numbers (`1`, `2`) start on the exact same vertical guide (`x = 40px`), perfectly matching Figma `7009:114120`.
     - Table header row background is always `#FAFAFA` (`var(--color-background-primary, #fafafa)`).
   - **Mandatory Product Checkbox Component**: Row checkboxes and Select-All header checkbox MUST use the authoritative product checkbox component (`<FormCheckbox />`) from QMT (`3345:24771` / `frontend/src/components/FormCheckbox.vue`). Never use raw `<input type="checkbox">`.
   - Both header ("select all") and row checkboxes, as well as the column visibility popover checklist and catalog selection checklist, use `<FormCheckbox />`.
   - To delete rows from the dynamic table, users check the row checkbox(es), which displays the bottom-anchored floating pill bar (`<TableFloatingBar />`):
     - Drag grip handle (`⠿` 6 dots).
     - Divider (`|`).
     - Counter: `[N] Selected • Select all [Total]`.
     - Divider (`|`).
     - Destructive batch action: `🗑 Delete` (in `#E7000B` red). Clicking Delete removes the selected rows and triggers the batch deletion callback.

6. **Expand Row Modal ("EXPAND ICON ACTION", Figma `6095:96369` & `6095:96370`)**:
   - Triggered by clicking the `↗` expand icon (`<Maximize2 :size="13" />`) on any row.
   - Secondary attributes (effectivity dates, calculations, certificates, attachments, notes, rollover rules) belong in this modal.
   - **Authoritative Modal Standard (`<DynamicTableModal />`)**:
     - MUST use the authoritative `<DynamicTableModal />` component (`frontend/src/components/DynamicTableModal.vue`).
     - **Header**: Titled `[Action/Entity]` with `(Row [Index])` in tertiary text (`#737373`), and circular `(X)` close button on the top right.
     - **Body Representation**:
       - 2-column input grid (`display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px;`) on a clean white background (`#ffffff`).
       - `type: 'readonly'` fields MUST be rendered as non-editable formatted text blocks (`.modal-readonly-block` with subtle surface background `#FAFAFA`, height 44px, border-radius 12px), NEVER as raw editable text inputs.
       - Entity-specific or custom layouts can provide a dedicated `<template #expand-modal="{ row, index }">` slot.
     - **Footer (Figma `6095:96395`)**:
       - Canvas background (`#FAFAFA` / `var(--color/background/primary)`), height 74px, subtle border-top (`#E5E5E5`), padding 0 24px.
       - **Bottom-Left**: Red error/destructive button **`Delete`** (`bg-[#fb2c36]`, rounded 8px, semi-bold white text).
       - **Bottom-Right**: Group of standardized secondary buttons (`bg-white`, border `#D9D9D9`, rounded 8px, secondary text `#404040`):
         1. `ArrowDown` icon button: Navigates down to the next row.
         2. `ArrowUp` icon button: Navigates up to the previous row.
         3. `Duplicate Row` button: `Copy` icon + "Duplicate Row". Duplicates the currently opened row.
         4. `Insert Above` button: `Plus` icon + "Insert Above". Inserts a blank row above the current row.
         5. `Insert Below` button: `Plus` icon + "Insert Below". Inserts a blank row below the current row.
     - **Zero Ad-Hoc Modal Dialogs**: Never build raw custom modal shells or misuse `QuickCreateModal` for dynamic table rows.

7. **Dropdown & Popover Teleportation Standard (Anti-Clipping & Anti-Scrollbar Rule)**:
   - **Column Hider Dropdown (`<IconColumnSolid />`)**: The column hide/show popover MUST ALWAYS be teleported to `body` (`<Teleport to="body">`) with dynamic fixed positioning (`getBoundingClientRect()`). It must NEVER be rendered inside the table header (`<th>`) or table scroll container, which would cause horizontal scrollbars or clipping.
   - **Select Menus (`<FormSelect />`)**: All dropdowns across dynamic tables and forms MUST default to `teleport: true` so their popovers float above cards, accordions, and modals without being hidden or clipped by parent containers with `overflow: hidden`.
8. **Multi-Selection Modal & Search Dropdown ("+ Add Multiple", Figma `6095:96639` & `6095:96649`)**:
   - Triggered by the `+ Add Multiple` button.
   - **Modal**: Titled `Select [Entities]` (e.g. `Select Customers`) with `Select... ⌵` multi-select field, embedded search bar (`🔍 Search...`), scrollable checklist with rounded checkboxes, and `Close` button.
   - Selected items highlighted with subtle surface background (`#F5F5F5`).
   - Bottom persistent action: `+ Create a new [Entity]` link (in `#0B529C` brand blue with `+` icon).

---

## 2. The Stacked Card Repeater (Alternative for High-Complexity / Hierarchical Entities)

When an entity possesses high layout complexity, multi-level cascading dropdowns, or multi-line descriptions that would suffer from extreme horizontal clutter in a flat table row, the **Stacked Card Repeater** (`.address-cards-stack`) MUST be used.

### When to Use
- Repeatable entities with deep cascading dependencies (e.g. Geographic Hierarchy: Country ➔ Region ➔ Zone ➔ Woreda ➔ Kebele).
- Multi-row groupings per entity item (e.g., Row 1: Administrative location; Row 2: District specifics; Row 3: Physical plaque / House number / Street; Row 4: Statutory tax routing checkboxes).
- Rich contextual business descriptions accompanying individual line items.

### Card Architecture & Layout Specification
1. **Outer Container**: Stacked list of `.address-item-card` containers (`border: 1px solid #e2e8f0; border-radius: 12px; padding: 22px 24px; background: #ffffff;`).
2. **Card Header**:
   - **Pill Badge (Top-Left)**: Soft blue pill badge (`.address-card-badge`, e.g. `Address 1`, `Address 2`) with `#e0f2fe` background, `#0284c7` text, `border-radius: 9999px`, font-size `12px`, font-weight `500`.
   - **Delete Action (Top-Right)**: Subtle outline trash can button (`<Trash2 :size="16" />`) with `#94a3b8` color and `#ef4444` hover state.
3. **Form Grid**:
   - Clean 3-column responsive grid (`grid-template-columns: repeat(3, minmax(0, 1fr))`, collapsing to 1 column on mobile).
   - Compact 38px controls, 8px radius, `#404040` text.
   - Text inputs MUST NEVER have placeholder text. Dropdowns display contextual placeholder (e.g. `Select Type`, `Select Country`, `Select Region`).
4. **Boolean Row**:
   - Mandatory use of `<FormCheckbox />` with BOTH Title and Description (e.g. `Primary Address` with statutory tax and domicile routing explanation).
5. **Add Button**:
   - `+ Add [Entity]` button (`.btn-add-address-card`) positioned directly below the card stack.

---

## 3. Strict Schema Backing & Zero Phantom Fields

1. **Use the owning domain's authoritative schema**: Every control in sub-tables or card repeaters must map directly to a real column. For HR, use `HR/HR_Schema_final-v4.sql`; for other domains, inspect that domain's schema rather than applying the HR schema globally.
2. **Zero Phantom Fields**: Never invent arbitrary unbacked fields (`remarks`, `internal_notes`, `temp_status`).
3. **Data Minimization**: Bring only high-value essential fields when pulling from related entities (omit unnecessary alternate phones, secondary emails, etc.).
4. **Zero Lifecycle `state` in Creation**: Entities created are active by definition. Never render `state`, `status`, or `Active / Inactive` toggles in creation forms or sub-tables.
