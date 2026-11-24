---
description: "Authoritative architectural standard for schema alignment, relational integrity, aggregate roots, and exact schema naming across all ERP modules."
applyTo: "**/*.{sql,vue,ts,js,md}"
---

# Schema Alignment & Relational Integrity Standard

This standard governs how SQL schemas are translated into UI pages, navigation, components, and forms across all modules of Haleta ERP (HR, Procurement, Inventory, Finance, Sales).

---

## 1. Authoritative Domain Schemas

Always inspect the authoritative SQL schema before designing or modifying UI components, payloads, routes, or navigation:
- **HR Module**: `HR/HR_Schema_final-v4.sql`
- **Procurement Module**: `procurement-v4.sql`
- **Inventory Module**: `Inventory and its related schema.md` / `inventory-v4.sql`

Never guess columns, types, or relationships. If a field does not exist in the authoritative SQL schema, do NOT invent phantom columns in the UI.

---

## 2. The Master-Child Relational Integrity Law (Zero Orphan Child Pages)

In relational enterprise databases, entities are organized into **Aggregate Roots** (master configurations, reference templates) and **Child / Line Schemas** (amount bands, roster lines, items, allocations).

### Strict Anti-Pattern: The "Orphan Child Table" Trap
❌ **NEVER** isolate a child line schema into a flat, independent directory table while ignoring or erasing its master aggregate root.
- **Example of Failure**: Taking `PurchaseMethodThreshold` (`purchase_method_id -- FK PurchaseMethod`) and creating a standalone page called "Spend Threshold Bands", while completely omitting `PurchaseMethod` (which holds statutory legal rules: `minimum_quotations`, `requires_committee`, `requires_sealed_bid`, `allows_single_source`, `is_open_invitation`).
- This severs relational integrity, confuses users, and destroys the business model.

### Mandatory Pattern: Unified Master-Child Representation
✅ **ALWAYS** represent the Master Entity and its Child Lines in a unified, cohesive interface:
1. **Unified Multi-Tab Directory View (`<BaseTabs />`)**:
   - When both the master entity and the global child matrix need to be browsed, use primary pill tabs (`<BaseTabs />`):
     - **Tab 1 (Master Entity)**: Primary master entities (e.g. `Purchase Methods`) displaying master statutory rules, quotation minimums, governance badges, and a summary of active child lines.
     - **Tab 2 (Child Lines / Scope Matrix)**: Comprehensive cross-entity child roster (e.g. `Value Threshold Bands`) showing the full matrix across all categories, units, and ranges.
2. **Tabular Create Forms for 1:N Lines (`<DynamicSubTable />`)**:
   - Creation and edit views MUST use the Tabular Create standard (`creation-ux.instructions.md` & `dynamic-relations.instructions.md`):
     - **Tab 1**: Master entity parameters.
     - **Tab 2+**: Child lines entered via `<DynamicSubTable />` (e.g., threshold bands for the method, unit members for the buying desk).

---

## 3. Exact Schema Naming Fidelity Law (Zero Ad-Hoc Marketing Jargon)

UI page titles, sidebar navigation items, breadcrumb labels, TypeScript interfaces, and routes **MUST directly reflect the authoritative schema entity names**:

| Schema SQL Entities | Required Navigation & Page Title | Forbidden Ad-Hoc Naming |
| :--- | :--- | :--- |
| `PurchaseMethod` + `PurchaseMethodThreshold` | **Purchase Methods** / **Purchase Methods & Thresholds** | ❌ "Spend Threshold Bands", "Spending Limits" |
| `ProcurementCategory` | **Procurement Categories** | ❌ "Spend Classifications", "Item Groups" |
| `ProcurementUnit` + `ProcurementUnitMember` | **Procurement Units** | ❌ "Buying Desks", "Purchasing Teams" |
| `JobPosition` | **Job Positions** | ❌ "Role Profiles", "Openings" |
| `WorkShift` + `ShiftPattern` | **Work Shifts & Shift Patterns** | ❌ "Working Hours", "Timings" |
| `LeavePolicy` + `LeaveAllocation` | **Leave Policies & Allocations** | ❌ "Time-off Rules" |

**Why this is mandatory**:
Developers, database administrators, and AI agents must be able to trace every UI screen directly back to its SQL source table. When arbitrary colloquial phrases are used, traceability is lost, components are duplicated, and agents hallucinate incorrect models.

---

## 4. Pre-Flight Schema Relational Checklist (Mandatory for Every Screen)

Before creating or auditing any view, the agent MUST explicitly execute and verify this 4-step checklist:

1. **Identify the Aggregate Root**:
   - What is the primary parent entity in the schema? (`[REF]`, `[DIST]`, `[INH]`)
2. **Identify Dependent Child Lines**:
   - Does this entity have child line tables (`[LINE]`, 1:N FKs)?
   - Are those child lines represented in the UI via `<DynamicSubTable />` or a dedicated tab?
3. **Verify Master Statutory Attributes**:
   - Are the master entity's boolean flags, approval requirements, and governance constraints visible on the primary screen, or were they buried/omitted?
4. **Audit Naming Against SQL**:
   - Does the page title, sidebar label, and breadcrumb match the SQL table name 1:1?

---

## 5. Conditional & Nullable-Bound Schema Fields (`<FormCheckboxCard />`)

When reading a SQL schema, watch for **two recurring conditional column patterns**:

1. **Nullable Limit / Sentinel Columns** (where `NULL` means *"no limit / open-ended / applies to all"*):
   - Examples: `minimum_amount` (`NULL = no floor`), `maximum_amount` (`NULL = unlimited`), `authority_ceiling` (`NULL = unlimited`), `effective_to` (`NULL = still in force`).
   - **UI Mapping**: Use `<FormCheckboxCard :expand-when-checked="false" />`.
     - **Checked (`true`) = Collapsed** (`#FAFAFA` background + `#E5E5E5` border) → submits `NULL` to the schema.
     - **Unchecked (`false`) = Expanded** (`#FFFFFF` background + `#E5E5E5` border) → reveals the required numeric/date input inside the card.
2. **Boolean-Gated Feature Columns** (where a `bool` flag activates one or more companion parameters):
   - Examples: `requires_guarantee` + `guarantee_percent`, `auto_match_enabled` + tolerance thresholds, `has_probation` + `probation_days`.
   - **UI Mapping**: Use `<FormCheckboxCard :expand-when-checked="true" />` *(default)*.
     - **Unchecked (`false`) = Collapsed** (`#FAFAFA` background + `#E5E5E5` border) → hides irrelevant companion fields.
     - **Checked (`true`) = Expanded** (`#FFFFFF` background + `#E5E5E5` border) → reveals the companion inputs inside the card.

**Strict Anti-Pattern**: ❌ Do NOT render permanently visible disabled `<FormInput :disabled="..." />` fields detached from a separate checkbox row when `<FormCheckboxCard />` can cleanly enclose and toggle the conditional input.
