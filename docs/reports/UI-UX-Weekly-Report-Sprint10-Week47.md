# UI / UX Team - Weekly Report

## 1. Portfolio summary
| Project / Module | Sprint # / Week (dates) | Team Lead | Capacity (person-days or SP) | Overall RAG (G / A / R) |
| :--- | :--- | :--- | :--- | :--- |
| **Haleta ERP / Procurement** | **Sprint 10 (Part 1) / Week 47 (17–20 Nov 2026)** | Muluken Z. | 10 person-days | **G** |

---

## A. Sprint / weekly goal and commitment
| Sprint / weekly goal (one outcome + measure + date) | Planned (SP / items) | Done (meets DoD) | Carried over | Added mid-sprint | Completion % (Done / Planned) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Deliver and get sign-off on the full Section #1: Foundation, Policy and Configuration [PRMS01-01] UI package (40+ screens in Figma, usability-checked, QMT design system compliant) by 20 Nov** | 42 screens | 42 screens | 0 | 0 | **100%** |

---

## B. Deliverables per designer
*Only items that meet the Definition of Done count as Delivered*

| Designer name | Committed this week (Task IDs + outcome) | Delivered (meets DoD / accepted) | Done % | Status (G / A / R) | Blocked by |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Kaleb T.** | **DSN-PRMS-01: Foundation, Policy and Configuration UI Package**<br>• Procurement Categories (`ProcurementCategory`)<br>• Purchase Methods & Thresholds (`PurchaseMethod` + `PurchaseMethodThreshold`)<br>• Procurement Units & Members (`ProcurementUnit` + `ProcurementUnitMember`)<br>• Committee Mandates (`ProcurementCommitteeMandate`)<br>• Approval Routes (`ProcurementApprovalRoute`)<br>• Assignment Rules (`ProcurementAssignmentRule`)<br>• Receipt Tolerances (`ReceiptToleranceRule`)<br>• Matching Tolerances (`MatchingToleranceRule`)<br>• Approval Delegations (`ApprovalDelegation`) | **Completed 42 screens in Figma.** All master directories, tabular master-child forms, inspection dossiers, quick create modals, bulk bars, column hiders, and lifecycle states meet DoD and adhere strictly to QMT tokens and `procurement-v4.sql`. Ready for developer handover. | **100%** | **G** | **None** |
| **Muluken Z. (Lead)** | Sprint 10 coordination, architecture alignment & developer review | Reviewed Section #1 component inventory and design token compliance | 100% | **G** | - |
| **Yohannes B.** | Field catalog & cross-module integration check | Confirmed spend class lookups and inventory category mapping | 100% | **G** | - |

---

## C. Numbers (2 only)
*Count first, then divide*

| Metric | How to measure | Target | Actual | Status (G / A / R) |
| :--- | :--- | :--- | :--- | :--- |
| **Open critical design issues** | Count of critical usability / design issues still open at week end | 0 | **0** | **G** |
| **Finished on time** | Designs delivered by due date / designs planned | $\ge$ 80% | **100%** (42 / 42) | **G** |

---

## D. Blockers, risks and decisions needed
| Type (Blocker / Risk / Decision) | Description | Impact (H / M / L) | Action or help needed | Owner | Due date |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **None** | No active blockers or dependencies. All 11 domain entity schemas and business logic verified against authoritative `procurement-v4.sql`. | L | Proceed directly to frontend engineering handover | Kaleb T. | Closed |

---

## E. Next week's commitments
*Each one is a deliverable, not an activity*

| # | Next-week outcome (one deliverable, not an activity) | Done when (measurable, testable check) | Owner | Due date |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Section #2: Procurement Planning & Requisition [PRMS01-02] UI Design** | Annual Plan cockpit, Requisition form, item catalog lookups, and PR approval ladder screens completed in Figma | Kaleb T. | 27 Nov |
| **2** | **Section #1 Frontend Developer Walkthrough & Token Handover** | Walkthrough session with frontend engineers; Vue components and Figma token mappings signed off | Kaleb T. / Muluken Z. | 24 Nov |

---

## F. Team lead's conclusion
| Lead's conclusion (circle one) | Note |
| :--- | :--- |
| **[ On track ]** \| At risk \| Escalate now | Section #1 (Foundation, Policy and Configuration) was delivered ahead of schedule with 40+ comprehensive screens covering all 11 tables. Designs strictly follow the QMT component-first system and database schema with zero open design blockers. Ready for development sprint planning. |

