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
