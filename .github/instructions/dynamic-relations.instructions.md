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
- **QMT Table Cells Library**: [Figma Frame 3345:71204](https://www.figma.com/design/EVkNwnkJXcHROkdv2QqXoU/QMT-team-library?node-id=3345-71204)
- **Authoritative Shared Component**: `<DynamicSubTable />` (`frontend/src/components/DynamicSubTable.vue`)

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
   - Empty state: when no rows exist, display centered `No rows` in muted `#A3A3A3` across all visible columns.

3. **Table Action Bar & Standardized `<AppButton>` (Always Below Table)**:
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
   - **Mandatory Product Checkbox Component**: Row checkboxes and Select-All header checkbox MUST use the authoritative product checkbox component (`<FormCheckbox />`) from QMT (`3345:24771` / `frontend/src/components/FormCheckbox.vue`). Never use raw `<input type="checkbox">`.
   - Both header ("select all") and row checkboxes, as well as the column visibility popover checklist and catalog selection checklist, use `<FormCheckbox />`.
   - To delete rows from the dynamic table, users check the row checkbox(es), which displays the bottom-anchored floating pill bar (`<TableFloatingBar />`):
     - Drag grip handle (`⠿` 6 dots).
     - Divider (`|`).
     - Counter: `[N] Selected • Select all [Total]`.
     - Divider (`|`).
     - Destructive batch action: `🗑 Delete` (in `#E7000B` red). Clicking Delete removes the selected rows and triggers the batch deletion callback.

5. **Expand Row Modal ("EXPAND ICON ACTION")**:
   - Triggered by clicking the `↗` expand icon (`<Maximize2 :size="13" />`) on any row.
   - Secondary attributes (effectivity dates, calculations, certificates, attachments, notes, rollover rules) belong exclusively in this modal.
   - **Modal Header**:
     - Strictly titled `[Entity/Section Name] (Row [Index])`, e.g., `"Create Item (Row 1)"`, `"Academic Qualification (Row 1)"` (*"Tells the user on which row they are in"*).
     - Top-right close button `×`.
   - **Modal Body**: Organized cleanly in a 2-column grid (`.modal-grid-2`) with standard inputs, selects, multi-badge tag selectors, and checkboxes with descriptions.
   - **Canonical Row Controls Footer (`.row-modal-footer`)**:
     - **Left**: `Delete` button (`.btn-modal-delete`, solid red `#E7000B`).
     - **Center**: Row Navigation Controls (*"Used to navigate through the rows"*):
       - Down Arrow (`↓`, `<ArrowDown :size="15" />`, disabled on last row).
       - Up Arrow (`↑`, `<ArrowUp :size="15" />`, disabled on first row).
       - Seamlessly switches the modal to inspect/edit the adjacent row without closing.
     - **Right**:
       - `Duplicate Row` button (`<Copy :size="13" />`): Clones the active row.
       - `+ Insert Above` button (`<Plus :size="13" />`): Inserts a blank row directly above the active row in the parent table.
       - `+ Insert Below` button (`<Plus :size="13" />`): Inserts a blank row directly below the active row in the parent table.

6. **Multi-Selection Modal & Search Dropdown ("+ Add Multiple", Figma `6095:96639` & `6095:96649`)**:
   - Triggered by the `+ Add Multiple` button.
   - **Modal**: Titled `Select [Entities]` with embedded search bar (`🔍 Search...`), scrollable checklist with rounded checkboxes, and selected item counter.
   - Bottom persistent action: `+ Create a new [Entity]` link (in `#0B529C` brand blue with `+` icon).
   - Triggered by the `+ Add Multiple` button.
   - **Modal**: Titled `Select [Entities]` (e.g. `Select Customers`) with `Select... ⌵` multi-select field and `Close` button.
   - **Dropdown Panel**:
     - Embedded search bar: `🔍 Search...`
     - Scrollable checklist with rounded checkboxes.
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
