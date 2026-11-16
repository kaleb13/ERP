---
description: "Use when displaying ERP lifecycle or governance statuses, status badges, or KPI/metric cards on listing pages."
---

# Haleta ERP — Status Classification & Metric Card Standard

This document codifies the mandatory architectural distinction between **Admin Multi-Entity Governance Status** and **Operational / Workflow Lifecycle Status** across all schema tables, and defines when top KPI / Metric Cards (`<MetricCard />`) MUST be rendered.

---

## 1. The Core Distinction: Governance vs. Operational Workflow

Schema tables in Haleta ERP feature two distinct categories of `status_lookup_id` (or status enums):

### Category A: Admin Multi-Entity Governance Status
- **Lookup Enum Values**: `acceptForAll` (Approved for All Entities), `acceptForThis` (Approved for This Entity Only), `pending` (Pending Admin Review), `reject` (Rejected by Admin).
- **Entities**: Global catalogs, master classifications, and organizational taxonomies shared across tenants/entities (e.g. `JobLevel`, `JobTitle`, `FieldOfStudy`, `Institution`, `IndustrySector`).
- **Authority**: Central System Administrator.
- **UI Architecture**:
  - Render as a **standard canonical directory table** (`<AppDataTable />`).
  - **DO NOT render top KPI / Metric Cards** above these governance tables, as they represent reference taxonomies rather than operational workforce allocations.
  - Display the `Status` column with clear badges reflecting approval scope (`Approved (Global)`, `Approved (Entity)`, `Pending`, `Rejected`).

---

### Category B: Entity Operational / Workflow Lifecycle Status
- **Lookup Enum Values**: `draft`, `approved`, `active` / `Published`, `closed`, `probation`, `in_service`, `suspended`, `on_leave`, `separated`, `deactivated`, etc.
- **Entities**: Day-to-day organizational workforce records, fiscal capacity allocations, and transaction workflows managed directly by the entity (e.g. `HeadcountBudget`, `EmployeeDetail` / `EmployeeProfile`, `LeaveRequest`, `OvertimeRequest`, `AttendanceLog`, `PayrollRun`).
- **Authority**: Entity Department Heads, HR Managers, Finance Directors, and Executive Leadership.
- **UI Architecture**:
  - **MANDATORY**: Render a **Top KPI / Metric Cards Grid (`<MetricCard />`)** directly above `<AppDataTable />`.
  - This is the explicit exception to the standard directory layout's no-metrics default: operational/workflow directories require metrics; governance/reference directories do not.
  - The Metric Cards grid must provide instant executive visibility into critical operational aggregates, capacity utilization, budget rollups, active headcount, and pipeline alerts.
  - As rows are created, edited, or deleted, these metric cards reactively reflect the updated state.

---

## 2. Metric Cards Grid Standard for Operational Pages

When implementing or refining an Operational Lifecycle Status page:

1. **Placement**: Directly between `<AppBreadcrumb />` and `<AppDataTable />`.
2. **Grid Layout**: Responsive 4-column layout (`grid-template-columns: repeat(4, 1fr)` on desktop, 2 columns on tablet, 1 column on mobile).
3. **Card Metrics Content**:
   - **Card 1: Primary Ceiling / Volume** (e.g. *Total Approved Capacity*, *Total Workforce*).
   - **Card 2: Active Utilization / In-Service** (e.g. *Filled Headcount* with `% Capacity Utilized` trend badge, *Active In-Service Staff*).
   - **Card 3: Pipeline / In-Flight / Alert State** (e.g. *Open Requisitions*, *Staff on Probation / Pending Confirmation*).
   - **Card 4: Financial Ceiling / Exceptions** (e.g. *Annual Rolled-Up Salary Budget (ETB)*, *Separations / Absences*).

4. **Component Standard (`<MetricCard />`)**:
   - Top Label: `#737373`, Medium (`500`), `12.5px`.
   - Main Number (Value): `#404040`, Semi-Bold (`600`), `24px`.
   - Bottom Subtext: `#737373`, Medium (`500`), `12px`.
   - Card Padding: `15px 18px`, Min-height `106px`.
   - Border Radius: `14px`, Border: `1px solid #e2e8f0`.

---

## 3. Table Data Representation: Status, State, and Dual-Lookup Standard (Badges vs. Plain Text)

- **Status and State are Always Represented with Badges**:
  - In all sections, tables, and views across the system, **Status** (`status_lookup_value_id`, governance status, approval status, lifecycle status) and **State** (`active` / `inactive`) MUST ALWAYS be represented with badges (`BaseBadge` / status pills).
- **Dual Appearance for Schema Lookup Values**:
  - Schema lookup values (e.g., `mode_lookup_value_id`, `class_lookup_value_id`, `receipt_mode_lookup_value_id`, `unit_type_id`, `method_type_id`) have two valid representations:
    1. **Plain Tertiary Text** (`#737373` / `.tertiary-plain-text`): Clean typography for quiet, secondary, or high-density categorical columns.
    2. **Badges** (`BaseBadge`): Visually anchored badges for high-salience operational classifications.
- **Agent/Designer Decision Authority & Balancing Principle**:
  - The agent/designer has the discretion and responsibility to decide whether each lookup column is best rendered as plain text or as a badge:
    - **Avoid Badge Clutter**: Carefully inspect the table's visual density. Never overload a table row with badges across multiple columns, which creates visual noise and degrades scanability.
    - **Prevent Hidden Information**: Never bury critical operational distinctions in plain text if doing so conceals vital workflow differences or routing categories from quick visual identification.
    - **Decision Criteria**: Evaluate the operational impact, cardinality, and column count of the specific table. If a lookup represents a critical operational mode (e.g., `Centralized` vs `Decentralized` procurement unit mode) in a moderate table, a badge may be optimal; if the table already has several badged/highlighted columns or the lookup is secondary metadata, render it in clean plain tertiary text.
    - **Semantic Badge Colors**: Do not give every lookup badge the same color by default. Choose a color only when it communicates the value's business meaning; use neutral for non-emphasized alternatives and tertiary text for low-salience lookups. Keep lifecycle State colors distinct from other classifications (for example, Active uses success, while Inactive is neutral).
