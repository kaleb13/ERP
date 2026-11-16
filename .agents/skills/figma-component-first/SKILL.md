---
name: figma-component-first
description: "Use for creating or editing Figma screens, frames, forms, sidebars, or components. Requires verified reuse of existing Figma components and a user decision before any substitute."
---

# Figma Component-First Workflow

Use this workflow for every Figma design edit in the Haleta ERP file.

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
- **Dropdown & Popover Standard (Zero Native Browser Selects)**:
  - All dropdown selectors, per-page selectors, and filter pickers must use official QMT popover components (`FormSelect` / linked QMT select menus). Never use raw OS select popups or unstyled select menus.
  - **Short Selection Placeholders**: Keep the complete field name in the label; use concise `Select [core noun]` placeholder copy (for example, `Statutory Purchase Method` → `Select Method`, `Category Scope` → `Select Scope`). Avoid repeating the full label or using explanatory/global-scope text as a form placeholder. `All ...` prompts are for filters.
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

## 5. Verify the result

Before reporting completion:

- Check each shared control's node type and source component/variant metadata; verify it is an instance linked to the intended component.
- Capture and inspect the complete target frame at its final size. Check clipping, wrapping, alignment, spacing, and visible states.
- Confirm the reference frame is unchanged and no unapproved substitute remains.
- Report the target frame link, component sources/variants used, any unresolved control, and any layout decision made by the user.

## Figma MCP notes

- Load the official Figma-use and Figma-generate-design guidance before mutating a file, and include both skill names on mutating Figma calls.
- Design-system search results are candidates, not proof of reuse. Verify that the component can be imported and that the final node links to its source.
- `$fig` handles are plan nodes until `await $fig.done()` materializes them. Do not read `.node` or pass a plan node to raw Plugin API methods before materialization.
