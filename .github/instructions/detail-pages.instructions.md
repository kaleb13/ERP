# Detail & Inspection Pages Architecture

Haleta ERP organizes all entity inspection, review, and approval interfaces into three standardized architectural archetypes based on data hierarchy and operational intent.

---

## 1. The Three Architectural Archetypes

### Archetype 1: Two-Column Split Workflow Detail (The "Dossier + Approval Rail")
*Authoritative References: Figma `7009:114552`, `9066:90379` (Leave Requests), `6624:99849` (Employee Movements)*

Used for transactional entities subject to multi-stage human approval, review, or operational sign-off (Leave Requests, Employee Movements, Separations, Encashments, Overtime Requests).

* **Breadcrumb Navigation**:
  * Sits directly on the transparent canvas background (`background: transparent; border: none; padding: 0;`).
  * Format: `[Parent Listing Page] > [Entity Code]` (e.g. `Leave Requests > LVR-2026-1002`, `Employee Movement > MOV-2026-1002`).
  * Never place back buttons, "Back to List" links, or white container boxes around the breadcrumbs.
* **Layout Grid**:
  * Default: `grid-template-columns: minmax(0, 1fr) 360px; gap: 24px;`
  * Focus Mode (Sidebar Minimized): `grid-template-columns: minmax(0, 1fr) 68px; gap: 24px;`
* **Left Dossier Column (`minmax(0, 1fr)`)**:
  1. **Top Identity / Hero Card** (`.hero-card`):
     * Left: Circular photo avatar (`76px` with concentric border shadow) or styled colored avatar, Name (`16px font-semibold text-[#414651]`), Code (`EMP-00124`), Role badge (`BaseBadge color="neutral"` / `#f5f5f5`), Location (`Works at [Branch] - [Department]`).
     * Right: Operational classification badges & metadata (`Movement Type / Leave Type`, `Effective Date / Duration`, `Request ID / Movement ID`).
  2. **Core Domain Blueprint Card(s)**:
     * High-contrast operational panels (e.g. side-by-side Current vs. Proposed assignment comparison in movements; 4 Entitlement Balance Quota cards in leave).
     * Card title (`16px font-semibold text-[#262626]`) + 1-line subtitle (`14px text-[#737373]`).
  3. **Operational Narrative & Delta Callout Card**:
     * Formal justification quote container (`bg-[#fafafa]` or `bg-[#f5f5f5]`, rounded 8px–16px, subtle border `#e5e5e5`).
     * Delta or Impact Banner (e.g. Compensation Delta `+ETB 3,350 (+46.9%)` in tinted blue `bg-[#f1f7fe]` with border `#83bff6` and `Info` icon).
  4. **Granular Breakdown / Sub-table**:
     * Embedded child table (e.g. `Daily Attendance Schedule`) structured cleanly with `No.`, `Date`, `Day of the Week`, `Shift Portion`.
* **Right Approval Rail (`ApprovalWorkflowRail` — `360px` default, collapsible to `68px`)**:
  * **Mandatory Shared Component**: ALWAYS reuse `<ApprovalWorkflowRail />` (`frontend/src/components/ApprovalWorkflowRail.vue`, Figma `7009:114669`, `9066:90379`, `10944:42263`) for every Archetype 1 workflow detail page. NEVER hand-roll bare `<ol>` step lists without card surfaces.
  1. **Focus Toggle Button (`.btn-focus` / `.btn-sidebar-collapsed`)**:
     * **Authoritative Library Icon (`PanelLeft`)**: ALWAYS use **`PanelLeft`** (`sidebar open` in QMT Team Library / `DashboardLayout.vue`) for BOTH the expanded `Focus` button and the collapsed rail expand button. **NEVER** use `PanelRightClose`, `PanelRightOpen`, `PanelLeftClose`, or `PanelLeftOpen` (those chevron-arrow icons are NOT in the QMT Team Library).
     * Expanded: White rounded `8px` button (`padding: 8px 14px; border: 1px solid #d4d4d4; box-shadow: 0 1px 2px rgba(10,13,18,0.05); font-semibold 14px text-[#404040]`) with `<PanelLeft :size="18" />` and text `Focus`.
     * Collapsed: Card shrinks to `68px` width (`padding: 20px 16px; min-height: 520px;`) with a single square `36px` button containing `<PanelLeft :size="20" />`.
     * When toggled to Focus mode, the sidebar minimizes to the slim rail, allowing the left dossier to expand smoothly to `100%` of the remaining viewport width.
  2. **Section 1: Approver Decision (or Status Summary Card)**:
     * Header: `Approver Decision` (`20px font-semibold text-[#404040]`) + helper subtitle (`14px text-[#737373]`).
     * Form inputs (when `canDecide`): `Resolution *` (QMT `FormSelect`), `Remark` (`FormTextarea` with `placeholder="Enter your decision reason..."`), and full-width `Submit Decision` button (`AppButton`, primary brand blue or destructive red for rejection).
     * When decided / waiting (`!canDecide`): render a structured Status Summary card (`approved` green seal card, `rejected` red card, `returned` warning card, or `waiting` neutral card) — never a floating raw paragraph without context.
  3. **Rail Divider**: Subtle `1px` divider (`border-top: 1px solid #e5e5e5; margin: 4px 0;`) whenever multi-stage steps are present.
  4. **Section 2: Approval / Progress Steps (Living Multi-Stage Stepper)**:
     * Header: e.g. `Approval Steps` / `Registration Steps` (`20px font-semibold #404040`) with subtitle (`14px #737373`).
     * **Mandatory Step Card Background Surface (`.step-card`)**: Every step item MUST render inside a distinct rounded card surface (`background: #fafafa; border: 1px solid #e5e5e5; border-radius: 16px; padding: 12px 18px;`), with optional remark quote box (`background: #f5f5f5; border: 1px solid #e5e5e5; border-radius: 8px; padding: 8px 12px;`). **NEVER** render step text naked on the white rail background without a `.step-card` surface.
     * **Step Circles (`44px × 44px`, dynamically Y-centered on each `.step-card` via `ResizeObserver`)**:
       * `done` / Approved: Background `#0b529c` (Brand Blue), white `Check` (`20px`).
       * `active` / Pending Review: Background `#fe9a00` (Warning 500 Amber), white `Clock` (`20px`).
       * `error` / Rejected: Background `#e7000b` (Error Red), white `X` (`20px`).
       * `queued` / Waiting: Background `#e5e5e5`, border `1px solid #d4d4d4`, muted white `Clock` (`20px`), muted `#a1a1a1` card text.
     * **Linear Gradient Connector Lines (`2px` wide, connecting circle-to-circle edge-to-edge)**:
       * Same-state steps use solid color (`#0b529c` or `#d4d4d4`).
       * Transitioning steps use vertical linear gradients (`#0b529c → #fe9a00`, `#fe9a00 → #d4d4d4`, `#0b529c → #e7000b`, etc.).

---

### Archetype 2: 360° Master Record Dossier (The "Hero + KPI + Tabs + 2x2 Grid")
*Authoritative Reference: Figma `4965:57240` (Employee Directory Detail)*

Used for master entity profiles containing broad relational data spanning multiple domains (Employee Directory, Organization Unit, Job Position).

* **Breadcrumb Navigation**:
  * Sits directly on the transparent canvas background: `Employee Directory > EMP-00124 - Almaz Ayana`.
* **Card 1: Top Identity / Hero Banner**:
  * Left: Hero avatar (`76px` circular clip with concentric white border and drop shadow), Name (`18px font-semibold text-[#404040]`), Code & Job Title badge (`EMP-00124 - [Senior Accountant]`), Location (`Works at Bole Branch - Finance Department`).
  * Right: Direct contact group with Lucide icons (Email link, Phone, Reports-to manager).
* **Card 2: Master Workspace & Navigation Card**:
  * **Row of 4 Metric Cards**: Full-width 4-column metric grid (`Total Leave Balance`, `Attendance (This Month)`, `Performance Rating`, `Current Gross Package` with `%` trends).
  * **Explanatory Narrative with Inline Action Link**:
    `"All records and documentation for this employee are centralized below. While the Overview tab presents high-level highlights and key indicators, you can access detailed, granular information by navigating through each specific tab. If any details are outdated or need to be updated in any way, please click on the [Edit Record] to make the necessary changes."`
    * `[Edit Record]` is styled as a brand blue text link (`text-[#0b529c] font-semibold underline`) that triggers the edit workflow.
  * **Secondary Underline Tabs** (`UnderlineTabs`):
    * Tabs: `Overview | Personal | Employment | Compensation (2) | Qualifications (4) | Compliance (5) | Family (4)`.
    * Counter pills use secondary gray styling.
* **Overview Tab Content (2x2 Balanced Section Grid)**:
  * Grid: 2 columns, 2 rows of modular white cards with subtle borders (`#e5e5e5`) and `16px` border-radius:
    * Card 1: `Identity & Location` (Legal Name, Gender, National ID, Marital Status, Residence Address).
    * Card 2: `Employment & Placement` (Department, Position Title, Contract Type, Work Schedule, Hire Date, Probation Confirmation).
    * Card 3: `Compensation & Bank Accounts` (Monthly Base Salary, Monthly Allowance, National ID, Bank Disbursement sub-card).
    * Card 4: `Compliance & Statutory` (TIN Number, POESSA Pension No, Guarantor, Emergency Contact).

---

### Archetype 3: In-Place Sanction & Progressive Plan (The "Progressive Cards + Audit Trail")
*Authoritative Reference: Figma `6814:162139` (Approve Headcount Plan)*

Used for structural, policy, or budgetary master plans where an authorized director or executive reviews submitter justification, can edit designated parameters in-place, and directly sanctions or cancels the plan.

* **Top Breadcrumb & Action Row**:
  * Left: `[Parent Module] > [Action Title]` (e.g. `Headcount Planning > Approve Headcount Plan`) with status badge embedded in the breadcrumb (`BaseBadge color="warning"` for `Draft`).
  * Right: Header Action Buttons: `Cancel` (Secondary outline button) and `Approve` (Primary brand blue button).
  * Bar sits on transparent canvas with zero card padding.
* **Card 1: Submitter Context & Justification Banner**:
  * Submitter Identity: Avatar photo, Name (`Almaz Ayana`), Title gray badge (`Head of People & Operation`), Department blue badge (`People & Culture (HR-PEOPLE)`).
  * Subtitle Metadata Row: `Submitted on [Date/Time] • Fiscal Target: [FY] • Branch: [Branch]`.
  * Key Metrics Capsule Bar: Single horizontal pill container with separated metric stats: `Derived Monthly Run-Rate Cap: [Amount]`, `Position Line Allocations: [X/Y]`, `Unallocated Seat Buffer: [Z]`.
  * Capacity Justification Callout: Nested card with `Capacity Justification` header (`FileText` icon) and formal submitter rationale.
* **Card 2: Approver-Editable Specifications Card**:
  * Title: `[Plan Name] Specifications - Approver Editable`.
  * 3-Column Input Grid: Dates with `GC` Ethiopian calendar badge, `Fiscal Year` text with helper explanation, `Capacity Seats` number input, `Currency` dropdown, `Annual Rolled-up Salary Budget` number input.
* **Card 3: Audit Trail**:
  * Title: `[Entity] Audit Trail`.
  * Vertical timeline with solid black bullet dots (`w-2.5 h-2.5 rounded-full bg-slate-900`) and vertical connector lines (`border-l-2 border-slate-200`), displaying historical milestones: Submissions, Sanctions, Signatures, and Pending Authority Actions.

---

## 2. Universal Data Hierarchy Rules for Detail Pages

1. **Identity First (Hero Standard)**:
   * Every detail page MUST begin with a dedicated Hero Card establishing the subject's identity, role, primary operational codes, and current lifecycle state.
   * Never start a detail page directly with raw tables or tabs without an identity anchor.
2. **Key High-Level Indicators Before Granular Tabs**:
   * Metrics, quotas, and high-level variances MUST be presented in prominent cards immediately below the identity banner before drilling into detailed tabs or sub-tables.
3. **Strict Approval Rail Positioning & Shared Component Law**:
   * For workflow-driven entities (Archetype 1), ALWAYS use `<ApprovalWorkflowRail />` (`frontend/src/components/ApprovalWorkflowRail.vue`) in the **Right Column** (`360px`).
   * NEVER place the approval sidebar on the left side (as in legacy `EmployeeSeparationDetail.vue`).
   * The Focus collapse/expand button MUST use the QMT library icon **`PanelLeft`** (`sidebar open`) — NEVER `PanelRightClose`, `PanelRightOpen`, `PanelLeftClose`, or `PanelLeftOpen`.
   * Every workflow step MUST sit inside a `.step-card` background surface (`#fafafa`, `1px solid #e5e5e5`, `16px` radius) with dynamically centered `44px` circles and dual linear-gradient connector lines.
4. **Authoritative Dual Linear Gradient Stepper Lines**:
   * In all workflow approval steppers, connector lines between steps MUST follow the exact Figma dual linear gradient:
     * Approved to Pending: `linear-gradient(180deg, #0b529c 0%, #fe9a00 100%)`.
     * Pending to Disabled: `linear-gradient(180deg, #fe9a00 0%, #d4d4d4 100%)`.
   * Never use plain solid gray lines for active multi-stage workflow steppers.
5. **Zero Back Buttons & Clickable Transparent-Canvas Breadcrumbs**:
   * Never render back buttons or white container cards around breadcrumb bars. Breadcrumbs sit on the transparent canvas as the sole traversal mechanism.
   * **Every parent/intermediate breadcrumb (`index < items.length - 1`) MUST be clickable** — supply `to` (for route navigation) and/or `onClick` (for closing in-page inspection views). `AppBreadcrumb` supports both `<router-link>` (`to`) and `<button>` (`onClick`-only). Never leave an intermediate breadcrumb non-clickable.
6. **Strict White Card Container Law (Zero Naked Canvas Content)**:
   * **Only Two Elements Sit on the Primary Canvas (`#fafafa`)**: The top breadcrumb bar (with its sealed status badge) and dedicated bottom audit logs / stock ledger explorers.
   * **Every Other Section MUST Have a Solid White Card Container (`background: #ffffff; border: 1px solid var(--alias-color-border-subtle, #e5e5e5); border-radius: 16px;`)**:
     * Hero cards (Identity, titles, and owning entity/calendar metadata).
     * Master Workspace cards (4 metric KPI cards, narrative directives, and underline tabs).
     * All child tables, blueprint cards, and simulator cards.
   * **Zero Floating Naked Sections**: NEVER allow metadata rows, section titles, or listings (e.g. Owning Entity, Work Calendar, Period Effective) to float nakedly on the canvas without their card container.
7. **Authoritative Figma Spacing & Padding Law (24px, 20px, 16px)**:
   * **24px (`var(--spacing/3xl, 24px)`)**:
     * Outer container padding for all major white cards (`padding: 24px`).
     * Horizontal padding on table header bars and card title sections (`padding: 20px 24px`).
     * Column gap between the left dossier and right approval rail in Archetype 1 (`gap: 24px`).
   * **20px (`var(--spacing/2xl, 20px)`)**:
     * Vertical stack gap between major page cards (`gap: 20px` in page layout / `policy-detail-content`).
     * Internal padding inside each of the 4 individual KPI metric cards (`padding: 20px`).
     * Grid gap between the 4 metric cards (`grid-template-columns: repeat(4, 1fr); gap: 20px;`).
     * Gap between multi-column cards (e.g. 3-column blueprint cards `gap: 20px`, 2x2 section cards `gap: 20px`).
     * Vertical padding on card title bars and directory table headers (`padding: 20px 24px`).
     * Internal vertical gap between card subsections (e.g. between the KPI grid, narrative row, and tabs).
   * **16px (`var(--spacing/xl, 16px)`)**:
     * Border radius on all card containers, metric items, and modals (`border-radius: 16px`).
     * Horizontal padding inside table header and body cells (`padding: 0 16px`).
     * Spacing between small clusters, avatar-to-text, and metadata item rows.
8. **Action Placement on Detail & View Pages (Zero Header Action Buttons)**:
   * The top breadcrumb row on read-only detail/view pages contains **ZERO action buttons** (`Edit`, `Mark Inactive`, `Delete`).
   * **"Mark Inactive"**: Belongs strictly on the edit/create form, NEVER in the view/detail page header.
   * **"Edit Record" / "Edit Policy"**: Belongs exclusively as an **inline semi-bold brand-blue text link** (`[Edit Record]` / `[Edit Policy]`) within the narrative statement inside the Master Workspace Card.
9. **Secondary Underline Tabs Integration (Zero Extra Box, Zero Gap)**:
   * `UnderlineTabs` sit directly inside the Master Workspace Card at the bottom, flush with its bottom border.
   * NEVER wrap `UnderlineTabs` in a separate bordered box (`border: 1px solid #e2e8f0; border-radius: 10px`) or add artificial margin/padding gaps around them.
   * The underline border of `UnderlineTabs` spans cleanly across the card.
10. **Persistent Workspace & Independent Tab Content**:
    * The Hero Card and the Master Workspace Card (with 4 KPIs, narrative directive, and tabs) remain permanently mounted and visible above the tabs across all tab switches.
    * Switching tabs toggles ONLY the child content below the Master Workspace Card with a clean `20px` vertical gap.
    * Child content across all tabs (Tables, Blueprint cards, Simulators) renders within standardized white cards adhering strictly to the 24px/20px/16px padding and border-radius rules.
11. **Zero In-Page Toast Banners (Strict Centralized Toast Standard)**:
    * System notifications, action confirmations, copy-to-clipboard feedback, and operational toggles (such as Focus mode enabling/disabling) MUST NEVER render as inline `.toast-bar` banners or pills inside the page body.
    * ALWAYS dispatch feedback via the centralized `useToast()` composable (`import { useToast } from '@/composables/useToast'; const { toast } = useToast();`).
    * Notifications display exclusively in the global fixed top-right `<BaseToaster />` / `<BaseToast />` container, preventing layout shifts, visual clutter, or content displacement.
