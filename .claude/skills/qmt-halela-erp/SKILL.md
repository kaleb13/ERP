---
name: qmt-halela-erp
description: Use when designing, implementing, reviewing, or correcting Haleta ERP web screens and components. Enforces schema-first workflows, QMT design tokens, shared Vue components, and ERP interaction patterns.
---

# QMT Haleta ERP — Web Design & Implementation

Use this skill for Haleta ERP web UI work: Vue pages, components, forms, tables, dialogs, workflows, and design reviews. The goal is not merely to make a screen look similar to QMT; it is to interpret the ERP domain correctly, use schema-backed data, and reuse the actual QMT-aligned product components.

## Source of truth and maintenance

Before changing a screen, inspect the current repository guidance relevant to the files being changed. Start with `AGENTS.md`, then read applicable files under `.github/instructions/`. For schema-backed work, inspect the authoritative schema for the owning domain; for HR, use `HR/HR_Schema_final-v4.sql` unless the task names a newer source. Existing implementations and component APIs are also evidence: inspect them rather than assuming this skill describes their latest state.

Project instructions, current schemas, and verified component APIs take precedence over this installed skill if they have changed. Never invent columns, enum values, routes, component props, or business rules. If authoritative sources conflict in a way that changes behavior, ask before choosing. Keep this skill maintainable by updating its `SKILL.md` when durable design rules change; do not rely on an installed copy as the repository's only source of truth.

## Required workflow

1. Identify the owning ERP domain, target screen, and requested behavior.
2. Read applicable project instructions, schema, existing page patterns, and shared component implementations before editing.
3. Map each displayed or editable field to a schema attribute or documented business rule. Use the existing relationship, enum, and null semantics. Do not add phantom fields or expose unrelated schema columns.
4. Reuse shared components and established helpers. Do not create a parallel component or visual pattern when a suitable product component exists.
5. Make the smallest coherent change that solves the request. Preserve behavior outside the requested scope and surface errors through project-standard feedback.
6. Run the smallest relevant test, build, or type-check. Report the exact validation and any limitation.

## QMT visual language

- Use the QMT palette and existing design tokens: brand `#0B529C`, secondary `#404040`, tertiary `#737373`, canvas `#FAFAFA`, subtle border `#E5E5E5`, success `#009966`, error `#E7000B`, warning `#E17100`, and info `#0084D1`.
- `#404040` is the darkest standard text and icon color. Do not use `#262626` or generic slate/blue colors such as `#0f172a`, `#334155`, `#475569`, or `#2563eb`.
- Prefer QMT token names over hard-coded colors when the component system provides them. Use official icon color tokens such as `icon-brand`, `icon-secondary`, `icon-tertiary`, `icon-success`, `icon-error`, `icon-warning`, and `icon-info`.
- Use `lucide-vue-next` named components for functional icons. Do not create inline or ad-hoc SVG icons; `IconColumnSolid.vue` is the approved column-toggle exception.
- Keep user-facing copy in English. Do not introduce Amharic UI or seed text.

## Reuse the product component system

Inspect `frontend/src/components/` and use the actual API of shared components. Common components include `AppBreadcrumb`, `AppDataTable`, `BaseTable`, `BasePagination`, `BaseButton`, `AppButton`, `BaseTabs`, `FormInput`, `FormSelect`, `FormCheckbox`, `QuickCreateModal`, `DynamicSubTable`, `BaseBadge`, `SaveStateBadge`, and `useToast`.

- Never replace an available shared control with ad-hoc HTML/CSS.
- Never use native `<select>` controls or hidden native select overlays. Use `FormSelect` or the established teleported QMT popover.
- Never construct raw status pills. Use `BaseBadge` with its real API and bind semantic color with `:color`, not a made-up `variant` prop.
- Use only supported component props, slots, and variants verified in source.

## Domain, schema, and form behavior

- Schema fields and relationships determine what the UI can collect and persist. Do not add manual codes, status/state toggles, descriptions, or other fields to a creation flow unless schema and domain rules support them.
- For create flows with five or fewer essential required fields, use the existing `QuickCreateModal` pattern when the entity supports quick creation. Keep quick forms essential; no notes/descriptions or “Save as draft.” Offer “Expand Full Form” when a real full-form route exists and preserve entered values when transitioning.
- For complex or multi-stage creation with more than five required fields, use the dedicated page or wizard pattern already established in the repository.
- Never add “Save as Draft” unless the schema-backed lifecycle supports a draft state.
- Use concise, action-led form selector placeholders: `Select [core noun]`. Keep the full meaning in the label: `Statutory Purchase Method` → `Select Method`; `Category Scope` and `Buying Desk Scope` → `Select Scope`. Do not repeat long labels or use global-scope explanations as form placeholders. `All ...` wording is for filters.
- If an entity has 1:N child records in a full creation page, separate master details and child records into primary tabs. Use the established dynamic table pattern and its non-empty initial row where appropriate. Route validation failures back to the master tab. Do not invent a child-table schema.
- Avoid silently swallowing failures, broad catches, or success-shaped fallbacks. Use repository-standard validation and notifications.

## Directory and data-table standards

- Standard directory composition is breadcrumb followed by the table card. Put title/description inside the table header and the primary create action in the toolbar. Operational/workflow pages may require metrics as described by `status-metrics.instructions.md`; governance/reference directories generally do not.
- Use `AppDataTable`/`BaseTable` and shared pagination. Keep the table full-bleed and fit to the container; do not introduce horizontal-scroll wrappers for standard desktop directories.
- Keep 5–8 high-signal columns. Make secondary columns available through the existing column hider. A column represents one attribute; do not combine unrelated fields.
- The identity/name column is first. Integrate row selection into that column with `FormCheckbox`; do not add a checkbox-only column. Keep this column visible.
- The Actions header must be labeled. Use the standard single `MoreVertical` kebab menu, not loose inline row actions. Follow existing menu behavior for inspect, edit, state changes where supported, and destructive actions; dismiss on outside click and Escape.
- Sort and Filter controls use the secondary-button treatment. Their icons use the established bold icon style.
- On a top-level directory, show only the exact page name in the breadcrumb. Expand breadcrumbs only for detail/inspection navigation. Place save-state badges only in the breadcrumb badge slot.

## Status, state, and lookup presentation

- Status and mechanical State are distinct concepts and always use badges.
- Never label a business status “Active” or “Inactive” when that collides with the separate mechanical State field. Translate schema values to domain terms where project guidance requires it (for example employee status `active` may display as “In Service”).
- Other schema lookups may be plain tertiary text or badges. Decide based on operational salience and table density; do not badge every lookup.
- Do not give every lookup the same badge color. When a badge is useful, choose a QMT semantic color that communicates meaning. Gray is reserved for inactive/dormant state, not active functional options. Preserve distinctions such as Mandatory vs. Permissive.
- Use `BadgeGroup` for longer compound badges when the product requires the compound treatment. Never badge raw numbers, dates, counts, or simple booleans.

## Page hierarchy and navigation

- Breadcrumb ancestors/dividers use tertiary color; the active item uses secondary color. Top-level directories use only their exact page label.
- Use primary pill tabs for a standalone tab group. Use secondary underline tabs only as a subordinate tier beneath primary tabs.
- Keep page title/description and primary action together in the page header; tabs sit on their own row below.
- For calendar/date navigation, reuse the established rectangular Today button, circular arrow buttons, and centered date title rather than inventing a new header pattern.

## Completion checklist

- Schema and domain semantics verified; no phantom fields or guessed values.
- Existing shared components and patterns reused with verified APIs.
- QMT hierarchy, icon, badge, table, breadcrumb, and selector rules followed.
- Relevant behavior checked, including error and empty states where applicable.
- Targeted validation run and honestly reported.
