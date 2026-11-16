---
name: qmt-halela-erp-figma
description: Use when creating, reviewing, or editing Haleta ERP screens in Figma. Requires verified reuse of linked QMT library components, schema-aware design, and final-frame validation.
---

# QMT Haleta ERP — Figma Design

Use this skill for Haleta ERP Figma screens, frames, forms, tables, and component changes. A visually similar drawing is not QMT component reuse: shared controls must remain real instances linked to the approved source components.

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
- Use 5–8 high-signal default columns, with secondary columns available through the column hider. Keep tables full-width without horizontal scrolling on standard desktop layouts.
- Keep columns atomic: one field per column. The first identity column contains row-selection controls; do not add a checkbox-only column. Keep the identity column visible.
- Label the Actions header. Its cells use one linked 3-dot kebab action-button instance, not loose View/Edit/Delete icons.
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

## Final validation checklist

- Correct target file/page/frame confirmed.
- Every shared control is a verified linked instance of the correct component and variant.
- Schema/domain fields, labels, and lifecycle states are valid.
- QMT color, typography, hierarchy, table, badge, breadcrumb, and placeholder rules are followed.
- Final frame checked at intended size; no clipping or unapproved substitute remains.
- Report the frame link, component sources/variants, validation, and any unresolved decision.
