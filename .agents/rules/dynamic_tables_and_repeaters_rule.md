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

### Layout & Behavior
1. **Compact Cell Standard**: 38px cell height, padding `8px 16px`, text `#404040`, font size 13px.
2. **Atomic Scanning Columns**: Display strictly 3 to 5 core high-frequency scanning columns inline.
3. **Selection & Batch Actions**: Row checkboxes (`table-checkbox`) + Select-All header checkbox. When one or more rows are selected, render the bottom-anchored floating bar (`<TableFloatingBar />`) for instant batch deletion.
4. **Expand Modal (`<Expand />`)**: Secondary attributes (effectivity dates, calculations, certificates, attachments, notes) must NOT crowd the row; they belong exclusively in the Expand Row modal.
5. **Add Row Button**: Placed directly below the table (`.btn-add-row`).

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

1. **Schema is Law (`HR_Schema_final-v4.sql`)**: Every control in sub-tables or card repeaters must map directly to an authoritative schema column.
2. **Zero Phantom Fields**: Never invent arbitrary unbacked fields (`remarks`, `internal_notes`, `temp_status`).
3. **Data Minimization**: Bring only high-value essential fields when pulling from related entities (omit unnecessary alternate phones, secondary emails, etc.).
4. **Zero Lifecycle `state` in Creation**: Entities created are active by definition. Never render `state`, `status`, or `Active / Inactive` toggles in creation forms or sub-tables.
