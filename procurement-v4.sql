-- =============================================================================
--  Haleta ERP -- Procurement (PRMS) Module Schema
--  Procure-to-pay up to approved AP handover: policy and thresholds, planning,
--  supplier registration, qualification and lifecycle, requisition, RFQ / tender /
--  bid, purchase order and framework agreement, delivery, receipt, inspection and
--  service acceptance, invoice matching and AP handover, contract, guarantee,
--  return and claim, import, supplier performance, procurement period control.
--  Specs: docs/Procument/docs/ and docs/Procument/docs/additionals/.
--  Changes against v2 and the reasons: procurement-v4-review.md (marked copy: procurement-v4-marked.sql).
--  Section numbers follow the PRMS epics (PRMS01-01 .. 14).
--
--  RULES
--    1. Procurement owns the PROCESS, never a master and never a ledger: what is
--       listed under REUSED is referenced, never re-modelled.
--    2. Spend class (goods, service, capital asset, project, non-stock) is a column
--       of ProcurementCategory; local vs foreign is PROCUREMENT_ORIGIN.
--    3. RFQ and tender share one Rfq header; a tender adds the 1:1 RfqTenderDetail.
--    4. state = active / inactive only. Workflow = <type>_status_lookup_value_id,
--       legal moves = lookup_transitions, approval = core Document + Workflow.
--    5. Quantities are kept in ORDER uom and STOCK uom; the conversion factor is
--       frozen at line creation.
--    6. One fact, one place: no header sum or count of a document's own lines, no
--       boolean twin of a status, timestamp or FK, no copy of a value another row
--       holds, no lookup value that another column already implies. Line-level
--       progress counters (received, invoiced, converted ...) are the exception.
--    7. Configuration is effective-dated or versioned and never edited once used,
--       so a document points at the row it applied instead of snapshotting it.
--       Snapshots remain only for EXTERNAL facts: the delivery address on an issued
--       PO, stock and budget figures at request, a document's before-image.
--
--  CONVENTIONS
--    id, uuid                 BIGSERIAL PK; varchar(50), UNIQUE (tenant_id, uuid)
--    code                     configuration and catalogue rows, backend-generated
--    <x>_number               transactional documents: the number core mints for the row's
--                             Document from its type's DocumentSequence, kept on the row for
--                             lists and search as Sales order_number is; no separate code
--    name, description,       jsonb { en, am }
--      title, body
--    <thing>_id               FK to a procurement table
--    XFK <Thing>              FK to a table in ANOTHER schema (core, hr, accounting,
--                             inventory) -- still a real constraint:
--                             ->constrained(schemaTable(X::class)). whereHas across
--                             connections fails on search_path: resolve ids, then whereIn
--    <x>_lookup_value_id      FK LookupValue, typed by the LookupType named in #0. A workflow
--                             status is named after its type: GOODS_RECEIPT_STATUS ->
--                             goods_receipt_status_lookup_value_id
--    status_lookup_value_id   reserved for core LOOKUP_VALUE_STATUS (PENDING | ACCEPT_FOR_ALL |
--                             ACCEPT_FOR_THIS | REJECT): the sharing decision on a catalogue row
--    document_id              XFK core Document: number, status, approval ladder,
--                             signatures, attachments and notes ride it
--    document_attachment_id   XFK core DocumentAttachment: one evidence FILE on the
--                             parent's document (checklist rows carry this, not a Document)
--    approved_at              list stamp; the approver is documents.approved_by
--    tenant_id, entity_id     FK Entity (tenant root), FK Entity (owning node)
--    user_id                  XFK User nullable, the acting user
--    state                    smallint, 1 active / 0 inactive, default 1
--    timestamps, soft delete  on every table except the status logs
--    money, quantity          numeric(18,4); rate, factor, percent, score numeric(18,6)
--    status logs              OrderStatusLog shape: id, uuid, reason text, changed_at,
--                             <parent>_id, from_ / to_status_lookup_value_id, changed_by,
--                             user_id; INDEX (<parent>_id, changed_at); no timestamps,
--                             state or soft delete
--    [FOLLOW-UP MIGRATION]    an FK to a table defined further down this file
--
--  TENANCY TAGS
--    [DIST]   tenant-owned; NOT NULL indexed tenant_id, stamped by ModelTrait
--    [INH]    on [DIST] configuration: a child entity uses its ancestors' rows
--             (forEntityOrAncestor); uniqueness, sums and writes stay exact
--    [REF]    shared catalogue; entity_id NULL = platform seed under core governance
--    [LINE]   entity_id and tenant_id copied from the header (Tenancy::LINES), not listed
--    UNIQUE lists the business key; the migration prepends tenant_id on [DIST] and [LINE].
--    CHECK (database) is a real constraint; CHECK (app-level) is enforced by the service.
--    102 tables: 47 [DIST] (18 of them [INH]) + 53 [LINE] + 2 [REF].
--
--  REUSED -- referenced, never redefined
--    core        Entity, Party, Supplier (SUPPLIER_TYPE local / international), Product,
--                Item, ItemCategory, Brand, ProductBatch, Measurement (+ Conversion),
--                Location, Country, Employee, User, Role, LookupType / LookupValue /
--                LookupTransition, Workflow / WorkflowStep, DocumentType /
--                DocumentTypeWorkflow / DocumentSequence / Document / DocumentApproval /
--                DocumentApprovalSignature / DocumentAttachment / DocumentNote,
--                CustomField*, Currency, PaymentTerm, TaxRate, TaxPolicy, WithholdPolicy,
--                WithholdRule, Committee / CommitteeMember, Asset / AssetDetail /
--                AssetCategory, DataExport, notification engine
--    hr          OrganizationUnit (the requesting department)
--    accounting  FiscalYear, AccountingPeriod, Budget / BudgetLine / BudgetCommitment,
--                Dimension (cost centre, project), ApInvoice / ApInvoiceMatch,
--                ApSupplierProfile (VAT, WHT), PaymentRequest, SupplierPayment,
--                SupplierPrepayment, SupplierDebitNote, BankAccount, BankGuarantee,
--                WithholdingTaxTransaction, LandedCost / LandedCostAllocationLine,
--                SegregationOfDutiesRule
--    inventory   StockOperation (receipts and returns POST through it; procurement keeps
--                the returned id and never writes a stock row), GatePass,
--                ProductInventoryPolicy (reorder point, lead time)
--    report      Kpi / KpiValue -- procurement KPIs are Report KPIs over these tables
--    audit       field history, events and sessions, incl. the supplier-portal trail
--    Inventory must seed STOCK_OPERATION_TYPE PURCHASE_RECEIPT (-> STOCK_IN) and
--    PURCHASE_RETURN (-> STOCK_OUT), with their map and requires-post entries.
--
--  EXAMPLE TENANT (as in sales.sql)
--    Sheraton Addis (BG 1) -> Sheraton Ethiopia (Org 2) -> Sheraton Addis Branch (3)
--      -> Gift Shop (4), Stockyard Restaurant (5), Le Spa (6)
--    Units      Central Procurement Unit 1 (entity 2), Branch Buying Desk 2 (entity 3)
--    Locations  Main Store 40, F&B Store 41, Cold Room 42
--    Suppliers  Alle Bejimla Trading 501 (local, VAT), Bekele Poultry Farm 502
--               (local, non-VAT), Winterhalter GmbH 503 (foreign)
--    People     Hanna Girma 88 (buyer), Yonas Alemu 90 (approver),
--               Meseret Tadesse 91 (storekeeper), Abebe Kassa 92 (import buyer)
-- =============================================================================


#0. Lookup values registry (seeded via LookupType / LookupValue)

	##0.0 Document types -- rows in core document_types, scoped by module_document_types
		-- PPLAN   procurement plan / plan version     DN      delivery notice
		-- SREG    supplier registration               PGRN    goods receipt (Inventory already seeds GRN)
		-- SQUAL   supplier qualification              INSP    goods inspection
		-- SSTAT   supplier suspension / blacklist     SRN     service acceptance
		-- SCHG    supplier change request             RTV     supplier return
		-- PREQ    purchase requisition                SINV    supplier invoice reference
		-- RFQ     rfq / tender                        MTCH    invoice match
		-- BIDANN  bid announcement                    APH     AP handover
		-- BID     bid submission receipt              CTR     procurement contract
		-- BIDOPN  bid opening minutes                 CTRAMD  contract amendment
		-- QUOT    supplier quotation                  GUAR    supplier guarantee
		-- EVAL    quotation evaluation                CLM     supplier claim
		-- AWD     award recommendation                IMP     import shipment
		-- FA      framework agreement                 SCARD   supplier scorecard
		-- PO      purchase order                      PEX     policy exception
		-- POAMD   purchase order amendment            DELEG   approval delegation
		-- PLOCK   procurement period reopen request

	##0.1 Foundation and policy
		- PROCUREMENT_CLASS             : goods | service | capital_asset | project | non_stock
		- PROCUREMENT_ORIGIN            : local | foreign
		- PROCUREMENT_RECEIPT_MODE      : goods_receipt | service_acceptance
		- PROCUREMENT_UNIT_MODE         : centralised | decentralised | hybrid
		- PROCUREMENT_UNIT_ROLE         : requester | buyer | unit_approver | receiver | viewer
		- PROCUREMENT_COMMITTEE_PURPOSE : bid_opening | technical_evaluation | financial_evaluation
		                                | combined_evaluation | award_review | inspection | contract_negotiation
		- PROCUREMENT_ATTENDEE_ROLE     : chair | member | secretary | technical_expert | observer | auditor
		                                | bidder_representative
		- RECEIPT_TOLERANCE_ACTION      : block | warn | require_approval | auto_close | keep_open
		- MATCH_TYPE                    : two_way | three_way | four_way
		- MATCH_EXCEPTION_ACTION        : block | require_approval | auto_accept
		- POLICY_EXCEPTION_TYPE         : over_budget | unplanned_purchase | threshold_override | single_source
		                                | below_minimum_quotations | sod_override | unqualified_supplier
		                                | missing_document | late_approval | backdated_document
		- POLICY_EXCEPTION_STATUS       : draft | submitted | approved | rejected | expired | cancelled
		- DELEGATION_TYPE               : planned_leave | sick_leave | travel | workload | vacancy | permanent_acting
		- DELEGATION_STATUS             : draft | pending_approval | active | expired | revoked | rejected
		- SUBMISSION_CHANNEL            : internal | supplier_portal

	##0.2 Planning
		- PLAN_PERIOD_TYPE              : annual | semi_annual | quarterly | monthly
		- PLAN_STATUS                   : draft | submitted | returned | approved | revised | rejected | closed
		                                | cancelled
		- PLAN_VERSION_STATUS           : submitted | approved | rejected
		- PLAN_LINE_STATUS              : pending | approved | on_hold | rejected

	##0.3 Supplier registration, qualification and lifecycle
		- SUPPLIER_REGISTRATION_STATUS  : draft | pending_verification | pending_review | returned | approved | rejected
		                                | inactive
		- SUPPLIER_BUSINESS_TYPE        : manufacturer | distributor | retailer | importer | service_provider
		                                | contractor | consultant
		- QUALIFICATION_TYPE            : new | renewal | category_extension | reinstatement
		- QUALIFICATION_STATUS          : draft | submitted | under_review | returned | approved | rejected | expired
		- SUPPLIER_DOCUMENT_TYPE        : trade_license | business_registration | tin_certificate | vat_certificate
		                                | tax_clearance | ppa_registration | professional_license | bank_statement
		                                | audited_financials | experience_letter | iso_certificate
		                                | manufacturer_authorization | power_of_attorney | technical_proposal
		                                | financial_proposal | other
		- DOCUMENT_REVIEW_RESULT        : pending | compliant | non_compliant | returned | waived
		- SUPPLIER_PROCUREMENT_STATUS   : active | suspended | blacklisted | reinstated | expired
		- SUPPLIER_RISK_TYPE            : financial | delivery | compliance
		- SUPPLIER_RISK_LEVEL           : low | medium | high | critical
		- SUPPLIER_RISK_EVENT_STATUS    : open | under_review | mitigated | accepted | closed
		- PRICE_LIST_SOURCE             : catalogue | quotation | contract | negotiated
		- PRICE_LIST_STATUS             : draft | active | superseded | expired
		- PORTAL_ACCOUNT_STATUS         : invited | active | suspended | expired | revoked
		- SUPPLIER_CHANGE_SCOPE         : identity | contact | address | tax | bank | categories | documents
		- SUPPLIER_CHANGE_STATUS        : draft | submitted | approved | rejected | applied | cancelled

	##0.4 Requisition and demand
		- REQUISITION_TYPE              : planning_need | purchase
		- REQUISITION_SOURCE            : manual | reorder | mrp_suggestion | plan | project | contract_renewal | portal
		- REQUISITION_URGENCY           : normal | urgent | emergency
		- REQUISITION_STATUS            : draft | submitted | under_review | returned | on_hold | approved
		                                | partially_converted | converted | rejected | cancelled | closed
		- REQUISITION_LINE_STATUS       : pending | on_hold | approved | rejected | converted | cancelled
		- CONSOLIDATION_BASIS           : by_category | by_product | by_supplier | by_location | by_period
		- CONSOLIDATION_STATUS          : draft | confirmed | converted | cancelled

	##0.5 Sourcing, tender and award
		- EVALUATION_CRITERION_TYPE     : technical | financial | commercial | compliance | delivery | esg
		- EVALUATION_SCORING_METHOD     : manual | lowest_price | ratio | pass_fail
		- RFQ_STATUS                    : draft | approved | issued | open | closed | under_evaluation | awarded
		                                | cancelled | failed
		- RFQ_LINE_STATUS               : open | awarded | partially_awarded | cancelled | failed
		- TENDER_PUBLICATION_CHANNEL    : supplier_portal | company_website | newspaper | ppa_portal | notice_board
		                                | radio | television | email_broadcast
		- RFQ_INVITATION_METHOD         : portal | email | letter | walk_in
		- RFQ_SUPPLIER_STATUS           : invited | acknowledged | declined | responded | disqualified | no_response
		- BID_ENVELOPE_TYPE             : single | technical | financial
		- BID_SUBMISSION_STATUS         : received | opened | withdrawn | rejected_late | rejected_at_opening
		                                | disqualified
		- BID_OPENING_STATUS            : draft | finalised | corrected
		- QUOTATION_STATUS              : received | under_evaluation | non_responsive | shortlisted | negotiating
		                                | awarded | partially_awarded | rejected | superseded | expired
		- INCOTERM                      : exw | fob | cfr | cif | dap | ddp
		- EVALUATION_STAGE              : preliminary | technical | financial | combined
		- EVALUATION_STATUS             : draft | submitted | approved | returned | cancelled
		- AWARD_BASIS                   : lowest_evaluated | best_value | single_source | emergency | framework_call_off
		                                | direct_exception
		- AWARD_STATUS                  : draft | submitted | approved | returned | rejected | converted | cancelled

	##0.6 Purchase order and agreement
		- AGREEMENT_TYPE                : quantity_contract | value_contract | call_off | rate_contract
		- AGREEMENT_STATUS              : draft | approved | active | suspended | exhausted | expired | closed
		                                | cancelled
		- PURCHASE_ORDER_STATUS         : draft | pending_approval | approved | issued | acknowledged
		                                | partially_received | fully_received | partially_invoiced | closed
		                                | short_closed | cancelled
		- PURCHASE_ORDER_LINE_STATUS    : open | partially_received | fully_received | closed | short_closed | cancelled
		- PO_AMENDMENT_TYPE             : quantity | price | date | specification | cancellation | line_add
		                                | line_remove
		- PO_AMENDMENT_STATUS           : draft | submitted | approved | rejected | applied | cancelled
		- DELIVERY_SCHEDULE_STATUS      : pending | partially_delivered | delivered | overdue | cancelled
		- PO_EVENT_TYPE                 : accepted | accepted_with_changes | query | rejected | in_production
		                                | ready_for_dispatch | dispatched | in_transit | at_port | under_customs
		                                | arrived | delayed | other

	##0.7 Delivery, receipt, inspection and acceptance
		- DELIVERY_NOTICE_STATUS        : announced | in_transit | arrived | receiving | received | partially_received
		                                | cancelled | no_show
		- GOODS_RECEIPT_STATUS          : draft | received | pending_inspection | inspected | accepted
		                                | partially_accepted | posted | rejected | cancelled
		- GOODS_RECEIPT_LINE_STATUS     : received | quarantined | accepted | rejected | partially_accepted | returned
		- RECEIPT_TOLERANCE_RESULT      : within | over | under | over_approved | under_closed
		- RECEIPT_REJECTION_REASON      : damaged | defective | poor_quality | expired | spec_mismatch | short
		                                | wrong_item | missing_document
		- INSPECTION_TYPE               : visual | sampling | full | lab_test | third_party
		- INSPECTION_RESULT             : passed | failed | conditional
		- INSPECTION_DISPOSITION        : accept | return | rework | scrap | accept_with_concession
		- INSPECTION_STATUS             : draft | submitted | approved | rejected | cancelled
		- SERVICE_ACCEPTANCE_TYPE       : full | milestone | periodic | partial | final
		- SERVICE_ACCEPTANCE_STATUS     : draft | submitted | approved | returned | rejected | cancelled
		- SUPPLIER_RETURN_TYPE          : quality | over_delivery | wrong_item | damaged | expired | recall
		                                | receipt_reversal
		- SUPPLIER_RETURN_STATUS        : draft | approved | dispatched | acknowledged | replaced | credited | closed
		                                | cancelled

	##0.8 Invoice matching and AP handover
		- SUPPLIER_INVOICE_TYPE         : standard | credit_note | debit_note | advance | final
		- SUPPLIER_INVOICE_STATUS       : received | under_matching | matched | exception | approved | handed_over
		                                | returned_to_supplier | rejected | cancelled
		- MATCH_RESULT                  : matched | within_tolerance | exception | failed
		- MATCH_LINE_RESULT             : matched | within_tolerance | price_exception | quantity_exception
		                                | both_exception | no_receipt | no_po_line
		- MATCH_STATUS                  : draft | completed | approved | rejected | cancelled
		- MATCH_EXCEPTION_TYPE          : price_variance | quantity_variance | no_receipt | no_po | duplicate_invoice
		                                | tax_mismatch | unit_mismatch | supplier_mismatch | expired_po | over_invoiced
		                                | currency_mismatch
		- MATCH_EXCEPTION_SEVERITY      : info | warning | blocking
		- MATCH_EXCEPTION_RESOLUTION    : accept_variance | request_credit_note | return_invoice | amend_po
		                                | adjust_receipt | partial_payment | write_off
		- MATCH_EXCEPTION_STATUS        : open | under_review | pending_approval | resolved | escalated | waived
		                                | cancelled
		- AP_HANDOVER_STATUS            : prepared | submitted | accepted | rejected | posted | paid | partially_paid
		                                | cancelled

	##0.9 Contract, guarantee and claim
		- CONTRACT_TYPE                 : supply | service | works | consultancy | maintenance | lease | framework
		- CONTRACT_STATUS               : draft | under_negotiation | pending_signature | active | suspended | expired
		                                | terminated | closed | cancelled
		- CONTRACT_TERMINATION_REASON   : non_compliance | non_performance | mutual_agreement | convenience
		                                | force_majeure | insolvency | fraud
		- CONTRACT_MILESTONE_STATUS     : pending | in_progress | delivered | accepted | rejected | overdue | cancelled
		- CONTRACT_AMENDMENT_TYPE       : value | scope | duration | price | milestone | termination | renewal | party
		- CONTRACT_AMENDMENT_STATUS     : draft | submitted | approved | signed | rejected | cancelled
		- CLAUSE_TYPE                   : general | scope | payment | delivery | penalty | warranty | dispute_resolution
		                                | force_majeure | termination | confidentiality | special
		- SIGNATORY_SIDE                : supplier | witness
		- SIGNATURE_METHOD              : wet_ink | digital_certificate | otp_confirmation | portal_acceptance
		- GUARANTEE_TYPE                : bid_bond | performance_bond | advance_payment_guarantee | retention | warranty
		                                | customs_bond | parent_guarantee
		- GUARANTEE_STATUS              : pending | active | expiring | expired | partially_released | released
		                                | forfeited | extended | cancelled
		- SUPPLIER_CLAIM_TYPE           : warranty | quality | shortage | damage | late_delivery | non_performance
		                                | price_dispute | invoice_dispute | service_failure
		- CLAIM_RECOVERY_METHOD         : credit_note | replacement | repair | cash_refund | payment_deduction
		                                | bond_forfeiture | write_off
		- SUPPLIER_CLAIM_STATUS         : draft | raised | acknowledged | under_review | disputed | agreed
		                                | partially_recovered | recovered | rejected | written_off | closed

	##0.10 Import
		- SHIPMENT_MODE                 : sea | air | road | rail | courier | multimodal
		- IMPORT_PAYMENT_MODE           : letter_of_credit | tt_advance | cad | open_account | franco_valuta
		                                | consignment
		- IMPORT_SHIPMENT_STATUS        : planned | lc_opened | shipped | in_transit | arrived | under_clearance
		                                | cleared | received | costed | closed | cancelled
		- IMPORT_DOCUMENT_TYPE          : proforma_invoice | commercial_invoice | packing_list | bill_of_lading
		                                | airway_bill | certificate_of_origin | insurance_certificate | insurance_policy
		                                | lc_advice | customs_declaration | bank_permit | quality_certificate
		                                | fumigation_certificate | pre_shipment_inspection | delivery_order
		- IMPORT_CHARGE_TYPE            : freight | insurance | customs_duty | excise | surtax | vat_on_import
		                                | withholding_on_import | port_handling | demurrage | storage | inland_transport
		                                | clearing_fee | bank_charge | lc_commission | inspection_fee | other
		- CHARGE_ALLOCATION_BASIS       : value | weight | volume | quantity
		- IMPORT_CHARGE_STATUS          : estimated | actual | approved | allocated | disputed | cancelled
		- LC_AMENDMENT_TYPE             : expiry_extension | shipment_date | amount | documents | terms | other
		- LC_AMENDMENT_STATUS           : requested | approved_by_bank | rejected | cancelled

	##0.11 Supplier performance
		- SCORECARD_PERIOD_TYPE         : monthly | quarterly | semi_annual | annual | per_contract
		- SCORECARD_GRADE               : excellent | satisfactory | needs_improvement | unsatisfactory
		- SCORECARD_STATUS              : draft | calculated | reviewed | approved | published | cancelled
		- SUPPLIER_CRITERION_SOURCE     : delivery_on_time | delivery_in_full | otif | quality_acceptance | lead_time
		                                | price_variance | invoice_accuracy | responsiveness | claims | manual
		- IMPROVEMENT_ACTION_TYPE       : corrective | preventive | training | process_change | warning | probation
		                                | category_restriction
		- IMPROVEMENT_ACTION_STATUS     : open | in_progress | completed | verified | overdue | escalated | cancelled

	##0.12 Period control
		- PERIOD_LOCK_TYPE              : soft | hard
		- PERIOD_LOCK_STATUS            : open | closing | locked | temporarily_reopened | permanently_closed




#1. Foundation, policy and configuration                          [PRMS01-01]

	-- Numbering, templates and attachments are the core Document engine; the approval
	-- ladder is core Workflow; segregation of duties is Accounting's; branches are Entity.
	-- Every rule table here is effective-dated: a change ends one row and starts another.

	### ProcurementCategory [REF] -- the spend classification tree; its class decides the path a line takes
		- id
		- uuid
		- code                             -- unique per entity
		- name                             -- jsonb
		- description                      -- jsonb nullable
		- requires_inspection              -- bool -- a receipt must pass GoodsInspection
		- requires_contract                -- bool -- a PO is blocked without a ProcurementContract
		- requires_budget_line             -- bool -- a PR line is blocked without budget_line_id
		- class_lookup_value_id            -- FK LookupValue (PROCUREMENT_CLASS) -- spend class; decides the line's path
		- receipt_mode_lookup_value_id     -- FK LookupValue (PROCUREMENT_RECEIPT_MODE) -- how delivery is confirmed
		- parent_id                        -- FK self nullable -- the parent category; NULL = top level
		- entity_id                        -- XFK Entity nullable -- NULL = shared with every tenant
		- item_category_id                 -- XFK ItemCategory nullable -- the inventory category it maps to, if any
		- status_lookup_value_id           -- FK LookupValue (LOOKUP_VALUE_STATUS) -- whether the owner shares this row
		- user_id
		- state
		-- UNIQUE (entity_id, code) | INDEX (parent_id), (class_lookup_value_id)
		> examples:
			| id | code      | name (en)          | class         | parent | inspection | receipt_mode       | entity |
			| -- | --------- | ------------------ | ------------- | ------ | ---------- | ------------------ | ------ |
			| 10 | FB        | Food & Beverage    | goods         | --     | false      | goods_receipt      | 2      |
			| 11 | FB-PERISH | Perishables        | goods         | 10     | true       | goods_receipt      | 2      |
			| 20 | CAPEX-KIT | Kitchen Equipment  | capital_asset | --     | true       | goods_receipt      | 2      |
			| 30 | SVC-CLEAN | Cleaning Services  | service       | --     | false      | service_acceptance | 2      |
			| 50 | OFFICE    | Office consumables | non_stock     | --     | false      | goods_receipt      | 2      |

	### PurchaseMethod [REF] -- direct, RFQ, open or restricted tender, framework, emergency, with what each requires
		- id
		- uuid
		- code                             -- unique per entity
		- name                             -- jsonb
		- description                      -- jsonb nullable
		- minimum_quotations               -- smallint -- quotations needed before an award; 0 = none
		- requires_committee               -- bool -- a procurement committee must evaluate and award
		- requires_sealed_bid              -- bool -- bids arrive sealed and are opened together at a set time
		- requires_post_facto_approval     -- bool -- buy first, approve afterwards (emergency purchases)
		- allows_single_source             -- bool -- only one supplier may be invited
		- is_open_invitation               -- bool -- true = advertised to all qualified suppliers; false = invited only
		- entity_id                        -- XFK Entity nullable -- NULL = shared with every tenant
		- status_lookup_value_id           -- FK LookupValue (LOOKUP_VALUE_STATUS) -- whether the owner shares this row
		- user_id
		- state
		-- UNIQUE (entity_id, code)
		> examples:
			| id | code              | name (en)               | quotes | committee | sealed | open  | post_facto |
			| -- | ----------------- | ----------------------- | ------ | --------- | ------ | ----- | ---------- |
			| 1  | DIRECT            | Direct purchase         | 0      | false     | false  | false | false      |
			| 2  | RFQ               | Proforma (RFQ)          | 3      | false     | false  | false | false      |
			| 3  | OPEN_TENDER       | Open tender             | 3      | true      | true   | true  | false      |
			| 4  | RESTRICTED_TENDER | Closed tender (invited) | 3      | true      | true   | false | false      |
			| 5  | FRAMEWORK         | Framework call-off      | 0      | false     | false  | false | false      |
			| 6  | EMERGENCY         | Emergency purchase      | 0      | false     | false  | false | true       |

	### ProcurementUnit [DIST][INH] -- the buying desk: centralised or not, with a spending ceiling
		- id
		- uuid
		- code                             -- unique per entity
		- name                             -- jsonb
		- authority_ceiling                -- numeric(18,4) nullable -- largest order it may place; NULL = unlimited
		- buys_for_descendants             -- bool -- may buy for child entities of entity_id
		- mode_lookup_value_id             -- FK LookupValue (PROCUREMENT_UNIT_MODE)
		- tenant_id
		- entity_id                        -- the unit's home
		- currency_id                      -- XFK Currency -- currency of the ceiling
		- default_location_id              -- XFK Location nullable -- store that receives its goods by default
		- cost_center_dimension_id         -- XFK Accounting Dimension nullable -- cost centre charged by default
		- status_lookup_value_id           -- FK LookupValue (LOOKUP_VALUE_STATUS) -- whether the owner shares this row
		- user_id
		- state
		-- UNIQUE (entity_id, code)
		> examples:
			| id | code      | name (en)                | mode          | ceiling | buys_for_descendants | entity |
			| -- | --------- | ------------------------ | ------------- | ------- | -------------------- | ------ |
			| 1  | PU-CENT   | Central Procurement Unit | centralised   | --      | true                 | 2      |
			| 2  | PU-BRANCH | Branch Buying Desk       | hybrid        | 50000   | false                | 3      |
			| 3  | PU-SPA    | Le Spa Buying Desk       | decentralised | 20000   | false                | 6      |

	### ProcurementUnitMember [LINE] -- who requests, buys, approves or receives for a unit; RBAC must still allow it
		- id
		- uuid
		- valid_from                       -- date -- first day the role applies
		- valid_to                         -- date nullable -- last day; NULL = open-ended
		- role_lookup_value_id             -- FK LookupValue (PROCUREMENT_UNIT_ROLE)
		- procurement_unit_id              -- FK ProcurementUnit
		- member_employee_id               -- XFK Employee -- the person who holds the role
		- organization_unit_id             -- XFK HR OrganizationUnit nullable -- department served; NULL = all
		- user_id
		- state
		-- UNIQUE (procurement_unit_id, member_employee_id, role_lookup_value_id, organization_unit_id)
		-- INDEX (member_employee_id)
		> examples:
			| id | unit | employee | role          | department        | valid_from |
			| -- | ---- | -------- | ------------- | ----------------- | ---------- |
			| 1  | 2    | 88       | buyer         | --                | 2026-07-01 |
			| 2  | 2    | 90       | unit_approver | --                | 2026-07-01 |
			| 3  | 2    | 91       | receiver      | --                | 2026-07-01 |
			| 4  | 2    | 95       | requester     | 12 (F&B)          | 2026-07-01 |
			| 5  | 2    | 95       | requester     | 14 (Housekeeping) | 2026-07-01 |

	### PurchaseMethodThreshold [DIST][INH] -- the amount band that forces or permits a purchase method
		- id
		- uuid
		- minimum_amount                   -- numeric(18,4) -- lowest order value in the band
		- maximum_amount                   -- numeric(18,4) nullable -- highest value in the band; NULL = no limit
		- is_mandatory                     -- bool -- true forces the method; false only permits it
		- effective_from                   -- date -- first day the band applies
		- effective_to                     -- date nullable -- last day; NULL = still in force
		- purchase_method_id               -- FK PurchaseMethod -- the method the band forces or permits
		- procurement_category_id          -- FK ProcurementCategory nullable -- category it applies to; NULL = all
		- procurement_unit_id              -- FK ProcurementUnit nullable -- unit it applies to; NULL = all
		- tenant_id
		- entity_id
		- currency_id                      -- XFK Currency -- currency of the amounts
		- user_id
		- state
		-- INDEX (entity_id, purchase_method_id, effective_from)
		-- CHECK (app-level): no two mandatory rows overlap on (entity, category, unit) and dates
		> examples:
			| id | method      | min       | max    | mandatory | unit | entity | effective_from |
			| -- | ----------- | --------- | ------ | --------- | ---- | ------ | -------------- |
			| 1  | DIRECT      | 0         | 50000  | true      | --   | 2      | 2026-07-01     |
			| 2  | RFQ         | 50000.01  | 500000 | true      | --   | 2      | 2026-07-01     |
			| 3  | OPEN_TENDER | 500000.01 | --     | true      | --   | 2      | 2026-07-01     |
			| 4  | FRAMEWORK   | 0         | --     | false     | --   | 2      | 2026-07-01     |

	### ProcurementApprovalRoute [DIST][INH] -- picks the approval workflow by amount, category, method and unit
		- id
		- uuid
		- minimum_amount                   -- numeric(18,4) -- lowest document value the route covers
		- maximum_amount                   -- numeric(18,4) nullable -- highest value covered; NULL = no limit
		- priority                         -- smallint -- lowest wins on a tie
		- effective_from                   -- date -- first day the route applies
		- effective_to                     -- date nullable -- last day; NULL = still in force
		- procurement_category_id          -- FK ProcurementCategory nullable -- category it applies to; NULL = all
		- purchase_method_id               -- FK PurchaseMethod nullable -- method it applies to; NULL = all
		- procurement_unit_id              -- FK ProcurementUnit nullable -- unit it applies to; NULL = all
		- tenant_id
		- entity_id
		- document_type_id                 -- XFK DocumentType -- document type it routes: PREQ, PO, MTCH ...
		- workflow_id                      -- XFK Workflow -- the workflow used when this row matches
		- user_id
		- state
		-- INDEX (entity_id, document_type_id, minimum_amount)
		-- CHECK (app-level): the workflow's lookup type is the status type of the document it routes
		-- a matching row overrides the core DocumentTypeWorkflow default for that document type
		> examples:
			| id | document_type | min       | max   | category | workflow | entity |
			| -- | ------------- | --------- | ----- | -------- | -------- | ------ |
			| 1  | PREQ          | 0         | 50000 | --       | 410      | 2      |
			| 2  | PREQ          | 50000.01  | --    | --       | 411      | 2      |
			| 3  | PO            | 200000.01 | --    | 20       | 423      | 2      |

	### ProcurementAssignmentRule [DIST][INH] -- sends an approved requisition to a buying unit and a default buyer
		- id
		- uuid
		- minimum_amount                   -- numeric(18,4) nullable -- lowest requisition value caught; NULL = no floor
		- maximum_amount                   -- numeric(18,4) nullable -- highest value caught; NULL = no limit
		- priority                         -- smallint -- lowest wins on a tie
		- effective_from                   -- date -- first day the rule applies
		- effective_to                     -- date nullable -- last day; NULL = still in force
		- procurement_category_id          -- FK ProcurementCategory nullable -- category it catches; NULL = all
		- purchase_method_id               -- FK PurchaseMethod nullable -- method it catches; NULL = all
		- procurement_unit_id              -- FK ProcurementUnit -- the unit that sources it
		- origin_lookup_value_id           -- FK LookupValue (PROCUREMENT_ORIGIN) nullable -- NULL = local and foreign
		- tenant_id
		- entity_id
		- requesting_entity_id             -- XFK Entity nullable -- branch whose demand it catches; NULL = all below
		- default_buyer_employee_id        -- XFK Employee nullable -- buyer assigned; NULL = the unit lead assigns
		- user_id
		- state
		-- INDEX (entity_id, procurement_category_id, effective_from)
		> examples:
			| id | category | origin  | min | max   | unit | default_buyer | requesting_entity |
			| -- | -------- | ------- | --- | ----- | ---- | ------------- | ----------------- |
			| 1  | 11       | local   | 0   | 50000 | 2    | 88            | 3                 |
			| 2  | 20       | foreign | 0   | --    | 1    | 92            | --                |
			| 3  | 30       | local   | 0   | 20000 | 3    | --            | 6                 |

	### ProcurementCommitteeMandate [DIST][INH] -- which core Committee does what, by unit, category or value band
												-- Connects an existing core Committee to a specific procurement responsibility
												-- and defines the minimum attendance required for its decisions to count.
		- id
		- uuid
		- minimum_amount                   -- numeric(18,4) nullable -- lowest event value covered; NULL = no floor
		- maximum_amount                   -- numeric(18,4) nullable -- highest value covered; NULL = no limit
		- quorum                           -- smallint -- signed members needed for the event to count
		- effective_from                   -- date -- first day the mandate applies
		- effective_to                     -- date nullable -- last day; NULL = still in force
		- purpose_lookup_value_id          -- FK LookupValue (PROCUREMENT_COMMITTEE_PURPOSE) -- the step it performs
		- procurement_unit_id              -- FK ProcurementUnit nullable -- unit it covers; NULL = all
		- procurement_category_id          -- FK ProcurementCategory nullable -- category it covers; NULL = all
		- tenant_id
		- entity_id
		- committee_id                     -- XFK Committee -- the core committee that acts
		- user_id
		- state
		-- INDEX (entity_id, purpose_lookup_value_id, effective_from), (committee_id)
		-- resolution: category, then unit, then entity; then the band the event's value falls in
		> examples:
			| id | purpose              | committee           | unit | category | min    | quorum |
			| -- | -------------------- | ------------------- | ---- | -------- | ------ | ------ |
			| 1  | bid_opening          | 31 Tender Committee | --   | --       | 0      | 3      |
			| 2  | technical_evaluation | 32 Technical Panel  | --   | 20       | 0      | 3      |
			| 3  | inspection           | 33 Receiving Panel  | 2    | 11       | 0      | 2      |
			| 4  | award_review         | 34 Management Comm. | --   | --       | 500000 | 4      |

	### ReceiptToleranceRule [DIST][INH] -- delivery limits; most specific wins: product, supplier, category, entity
		- id
		- uuid
		- over_receipt_percent             -- numeric(18,6) -- extra delivery allowed, %; 0 blocks any
		- under_receipt_percent            -- numeric(18,6) -- shortfall, %, that still lets the line close
		- early_delivery_days              -- smallint -- days early a delivery may still be accepted
		- late_delivery_days               -- smallint -- grace days before a delivery counts as late
		- priority                         -- smallint -- lowest wins on a tie
		- effective_from                   -- date -- first day the rule applies
		- effective_to                     -- date nullable -- last day; NULL = still in force
		- over_action_lookup_value_id      -- FK LookupValue (RECEIPT_TOLERANCE_ACTION) -- action when over the limit
		- under_action_lookup_value_id     -- FK LookupValue (RECEIPT_TOLERANCE_ACTION) -- action when under the limit
		- procurement_category_id          -- FK ProcurementCategory nullable -- category it applies to; NULL = any
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier nullable -- supplier it applies to; NULL = any
		- product_id                       -- XFK Product nullable -- product it applies to; NULL = any
		- user_id
		- state
		-- INDEX (entity_id, procurement_category_id, supplier_id, product_id)
		> examples:
			| id | scope            | over % | under % | over_action      | under_action | early | late |
			| -- | ---------------- | ------ | ------- | ---------------- | ------------ | ----- | ---- |
			| 1  | entity 2 default | 0      | 0       | block            | keep_open    | 0     | 0    |
			| 2  | category 11      | 5      | 10      | require_approval | auto_close   | 2     | 1    |
			| 3  | supplier 502     | 10     | 15      | require_approval | auto_close   | 1     | 1    |

	### MatchingToleranceRule [DIST][INH] -- invoice price / quantity variance limits; kept apart from receipt tolerance
		- id
		- uuid
		- price_variance_percent           -- numeric(18,6) -- allowed unit-price difference, %
		- price_variance_amount            -- numeric(18,4) -- absolute price cap; the lower of the two governs
		- quantity_variance_percent        -- numeric(18,6) -- allowed quantity difference, %
		- total_variance_amount            -- numeric(18,4) -- allowed difference on the whole invoice
		- auto_match_enabled               -- bool -- match without a person when every variance is in the band
		- priority                         -- smallint -- lowest wins on a tie
		- effective_from                   -- date -- first day the rule applies
		- effective_to                     -- date nullable -- last day; NULL = still in force
		- match_type_lookup_value_id       -- FK LookupValue (MATCH_TYPE)
		- exception_action_lookup_value_id -- FK LookupValue (MATCH_EXCEPTION_ACTION) -- action when outside the band
		- procurement_category_id          -- FK ProcurementCategory nullable -- category it applies to; NULL = any
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier nullable -- supplier it applies to; NULL = any
		- user_id
		- state
		-- INDEX (entity_id, match_type_lookup_value_id, supplier_id)
		> examples:
			| id | scope        | match_type | price % | price cap | qty % | total cap | on_exception     | auto  |
			| -- | ------------ | ---------- | ------- | --------- | ----- | --------- | ---------------- | ----- |
			| 1  | entity 2     | three_way  | 2       | 500       | 0     | 2000      | require_approval | true  |
			| 2  | category 30  | two_way    | 0       | 0         | 0     | 0         | block            | false |
			| 3  | supplier 502 | three_way  | 5       | 1000      | 2     | 5000      | require_approval | true  |

	### ApprovalDelegation [DIST] -- a time-boxed acting approver: who approves for whom, for what, up to how much
		- id
		- uuid
		- maximum_amount                   -- numeric(18,4) nullable -- largest amount; NULL = the delegator's own limit
		- valid_from                       -- timestamp -- when the delegation starts
		- valid_to                         -- timestamp -- when it ends
		- note                             -- jsonb nullable -- reason or instructions for the delegate
		- type_lookup_value_id             -- FK LookupValue (DELEGATION_TYPE)
		- tenant_id
		- entity_id
		- delegator_user_id                -- XFK User -- the approver who is away
		- delegate_user_id                 -- XFK User -- the user who approves in their place
		- document_type_id                 -- XFK DocumentType nullable -- NULL = every procurement document type
		- document_id                      -- XFK Document nullable -- the delegation letter, when policy asks for one
		- delegation_status_lookup_value_id -- FK LookupValue (DELEGATION_STATUS)
		- user_id
		- state
		-- INDEX (delegator_user_id, valid_from), (delegate_user_id, valid_to)
		-- CHECK (app-level): delegate <> delegator; segregation-of-duties rules still apply to the delegate
		> examples:
			| id | absent | acting | doc  | max    | valid_from       | valid_to         | type          | status  |
			| -- | ------ | ------ | ---- | ------ | ---------------- | ---------------- | ------------- | ------- |
			| 1  | 90     | 93     | PO   | 200000 | 2026-09-01 00:00 | 2026-09-14 23:59 | planned_leave | active  |
			| 2  | 90     | 92     | --   | 50000  | 2026-11-09 08:00 | 2026-11-13 18:00 | travel        | active  |
			| 3  | 91     | 88     | PGRN | --     | 2026-10-12 08:00 | 2026-10-12 18:00 | sick_leave    | expired |


#2. Procurement planning                                           [PRMS01-02]

	-- Budget availability, reservation and commitment are Accounting's: procurement
	-- stores the returned BudgetCommitment id and owns only the PLAN. A plan is revised
	-- by a new version; requisitions consume the lines of the current version.

	### ProcurementPlan [DIST] -- the annual or periodic buying plan
		- id
		- uuid
		- plan_number                      -- from DocumentSequence -- the plan's printed number, e.g. PP-2026-FB
		- name                             -- jsonb
		- period_start                     -- date -- first day the plan covers
		- period_end                       -- date -- last day the plan covers
		- approved_at                      -- timestamp nullable -- when approved; the approver is on its Document
		- notes                            -- jsonb nullable -- free notes for planners and approvers
		- period_type_lookup_value_id      -- FK LookupValue (PLAN_PERIOD_TYPE)
		- procurement_unit_id              -- FK ProcurementUnit nullable -- owning unit; NULL = the whole entity
		- tenant_id
		- entity_id
		- currency_id                      -- XFK Currency -- currency of the plan's amounts
		- fiscal_year_id                   -- XFK Accounting FiscalYear -- fiscal year the plan is for
		- budget_id                        -- XFK Accounting Budget nullable -- budget the plan is checked against
		- document_id                      -- XFK Document -- the plan document: status, approvals, files
		- plan_status_lookup_value_id      -- FK LookupValue (PLAN_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, plan_number) | INDEX (entity_id, plan_status_lookup_value_id, period_start)
		> examples:
			| id  | plan_number | period_type | period_start | period_end | status   |
			| --- | ----------- | ----------- | ------------ | ---------- | -------- |
			| 300 | PP-2026-FB  | annual      | 2026-07-01   | 2027-06-30 | approved |
			| 301 | PP-2026-CX  | annual      | 2026-07-01   | 2027-06-30 | approved |
			| 302 | PP-2027-Q1  | quarterly   | 2026-07-01   | 2026-09-30 | draft    |

	### ProcurementPlanVersion [LINE] -- one row per approved state of a plan; the current version has no superseded_at
		- id
		- uuid
		- version_number                   -- smallint -- 0 = first approval
		- reason                           -- jsonb nullable -- why this revision; NULL on version 0
		- revised_at                       -- timestamp -- when this version was raised
		- superseded_at                    -- timestamp nullable -- when a newer version replaced it; NULL = current
		- procurement_plan_id              -- FK ProcurementPlan
		- document_id                      -- XFK Document nullable -- the revision memo; its workflow approves it
		- revised_by                       -- XFK User -- who raised the revision
		- plan_version_status_lookup_value_id -- FK LookupValue (PLAN_VERSION_STATUS)
		- user_id
		- state
		-- UNIQUE (procurement_plan_id, version_number) | UNIQUE (procurement_plan_id) WHERE superseded_at IS NULL
		> examples:
			| id | plan | version | reason                     | revised_at | superseded_at | status   |
			| -- | ---- | ------- | -------------------------- | ---------- | ------------- | -------- |
			| 1  | 300  | 0       | --                         | 2026-06-20 | 2026-07-25    | approved |
			| 2  | 300  | 1       | July market price revision | 2026-07-25 | --            | approved |
			| 3  | 301  | 0       | --                         | 2026-06-22 | --            | approved |

	### ProcurementPlanVersionLine [DIST] -- a planned item and its use; [DIST] because it may plan for a child entity
		- id
		- uuid
		- line_number                      -- int -- order within the version
		- description                      -- jsonb -- required when product_id is NULL
		- planned_quantity                 -- numeric(18,4) -- quantity planned, in measurement_id units
		- estimated_unit_price             -- numeric(18,4) -- expected price per unit
		- estimated_amount                 -- numeric(18,4) -- planned quantity x estimated price
		- requisitioned_quantity           -- numeric(18,4) default 0 -- quantity already requested on PRs
		- ordered_quantity                 -- numeric(18,4) default 0 -- quantity already on POs
		- received_quantity                -- numeric(18,4) default 0 -- quantity already received
		- actual_amount                    -- numeric(18,4) default 0 -- value of accepted receipts so far
		- required_from                    -- date -- start of the period it is needed in, not a delivery date
		- required_to                      -- date -- end of that period
		- is_recurring                     -- bool -- bought repeatedly through the period
		- decision_note                    -- jsonb nullable -- why the approver held or rejected this item
		- procurement_plan_version_id      -- FK ProcurementPlanVersion -- the plan version it belongs to
		- carried_from_line_id             -- FK self nullable -- same item in the previous version; counts carry over
		- procurement_category_id          -- FK ProcurementCategory -- spend category of the item
		- purchase_method_id               -- FK PurchaseMethod nullable -- planned method; NULL = decided later
		- tenant_id
		- entity_id                        -- the entity planned FOR
		- organization_unit_id             -- XFK HR OrganizationUnit nullable -- the department planned for
		- product_id                       -- XFK Product nullable -- catalogue product; NULL = free-text item
		- measurement_id                   -- XFK Measurement nullable -- unit of the planned quantity
		- location_id                      -- XFK Location nullable -- store it should be delivered to
		- budget_line_id                   -- XFK Accounting BudgetLine nullable -- budget line that funds it
		- cost_center_dimension_id         -- XFK Accounting Dimension nullable -- cost centre charged
		- plan_line_status_lookup_value_id -- FK LookupValue (PLAN_LINE_STATUS) -- approver's decision on the item
		- user_id
		- state
		-- INDEX (procurement_plan_version_id, line_number), (product_id), (budget_line_id),
		--       (organization_unit_id, plan_line_status_lookup_value_id)
		-- planning_need requisition lines that built this line, and purchase lines that consume it, both point here
		> examples:
			| id | version | line | product | dept     | planned | est_price | on_pr | on_po | received | status   |
			| -- | ------- | ---- | ------- | -------- | ------- | --------- | ----- | ----- | -------- | -------- |
			| 1  | 2       | 1    | Tomato  | 12 (F&B) | 12000   | 62.00     | 6200  | 6000  | 5840     | approved |
			| 2  | 2       | 2    | Onion   | 12 (F&B) | 9000    | 38.00     | 4100  | 4100  | 4100     | approved |
			| 3  | 2       | 3    | Mixer   | 12 (F&B) | 2       | 85000.00  | 0     | 0     | 0        | on_hold  |



#3. Supplier registration, qualification and lifecycle            [PRMS01-03 / -12]

	-- Core Party / Supplier own IDENTITY; Accounting ApSupplierProfile owns VAT and WHT.
	-- Procurement owns ELIGIBILITY: for which categories, until when, at what risk.
	-- Portal logins and supplier change requests sit here because they act on the supplier.

	### SupplierRegistration [DIST] -- officer-entered registration; approval creates the core Party and Supplier
		- id
		- uuid
		- registration_number              -- from DocumentSequence -- the SREG number staff and supplier quote
		- legal_name                       -- jsonb -- name on the trade licence
		- trade_name                       -- jsonb nullable -- name it trades under, when different
		- tin                              -- varchar -- taxpayer identification number; checked for duplicates
		- vat_registration_number          -- varchar nullable -- VAT number; NULL when not VAT-registered
		- business_license_number          -- varchar nullable -- trade licence number
		- contact_person_name              -- jsonb -- who procurement deals with at the supplier
		- email                            -- varchar -- contact email; verified, then used for the portal invite
		- phone                            -- varchar -- contact phone; verified by code
		- address                          -- jsonb -- head office address as entered
		- bank_details                     -- jsonb nullable, encrypted cast -- bank, branch, account name and number
		- email_verified_at                -- timestamp nullable -- when the supplier confirmed the email link
		- phone_verified_at                -- timestamp nullable -- when the supplier confirmed the phone code
		- verification_expires_at          -- timestamp nullable -- the link or code stops working after this
		- submitted_at                     -- timestamp nullable -- when the officer sent it for review
		- decided_at                       -- timestamp nullable -- when it was approved or rejected
		- decision_note                    -- jsonb nullable -- why it was returned or rejected
		- business_type_lookup_value_id    -- FK LookupValue (SUPPLIER_BUSINESS_TYPE) -- manufacturer, distributor ...
		- origin_lookup_value_id           -- FK LookupValue (PROCUREMENT_ORIGIN) -- becomes core SUPPLIER_TYPE
		- tenant_id
		- entity_id                        -- the buying organisation applied to
		- fiscal_year_id                   -- XFK Accounting FiscalYear nullable -- year an annual registration covers
		- party_id                         -- XFK Party nullable -- core party matched or created on approval
		- supplier_id                      -- XFK Supplier nullable -- core supplier matched or created on approval
		- document_id                      -- XFK Document -- licences and certificates attach here
		- decided_by                       -- XFK User nullable -- who approved or rejected it
		- supplier_registration_status_lookup_value_id -- FK LookupValue (SUPPLIER_REGISTRATION_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, registration_number)
		-- UNIQUE (entity_id, tin), UNIQUE (entity_id, email) WHERE status NOT IN (rejected, inactive)
		-- on approval: match or create Party + Supplier, then SupplierQualification, its categories
		--              and a SupplierUser
		> examples:
			| id | number   | legal_name           | type             | verified   | status               | supplier |
			| -- | -------- | -------------------- | ---------------- | ---------- | -------------------- | -------- |
			| 1  | SREG-041 | Lemlem Office Supply | distributor      | 2026-07-02 | approved             | 540      |
			| 2  | SREG-042 | Abay Cleaning PLC    | service_provider | --         | pending_verification | --       |
			| 3  | SREG-043 | Gondar Dairy Union   | manufacturer     | 2026-07-18 | rejected             | --       |

	### SupplierRegistrationCategory [LINE] -- the categories an applicant asks for; the approver grants some or all
		- id
		- uuid
		- is_approved                      -- bool nullable -- the approver's answer; NULL = undecided
		- supplier_registration_id         -- FK SupplierRegistration
		- procurement_category_id          -- FK ProcurementCategory -- the category the applicant wants to supply
		- user_id
		- state
		-- UNIQUE (supplier_registration_id, procurement_category_id)
		> examples:
			| id | registration | category             | is_approved |
			| -- | ------------ | -------------------- | ----------- |
			| 1  | 1            | 50 Office            | true        |
			| 2  | 1            | 10 Food & Beverage   | false       |
			| 3  | 2            | 30 Cleaning Services | --          |

	### SupplierUser [DIST] -- links a core User to a supplier for portal access; what it may do is its RBAC role
		- id
		- uuid
		- designation                      -- jsonb nullable -- job title at the supplier
		- is_primary_contact               -- bool default false -- true = the supplier's main contact for this buyer
		- status_reason                    -- jsonb nullable -- why it was suspended or revoked
		- supplier_registration_id         -- FK SupplierRegistration nullable -- registration that created it
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- the supplier this login acts for
		- portal_user_id                   -- XFK User -- the core user who signs in to the portal
		- portal_account_status_lookup_value_id -- FK LookupValue (PORTAL_ACCOUNT_STATUS)
		- user_id
		- state
		-- UNIQUE (supplier_id, entity_id, portal_user_id) | INDEX (portal_user_id, entity_id)
		> examples:
			| id | supplier | entity | portal_user | designation    | primary | status  |
			| -- | -------- | ------ | ----------- | -------------- | ------- | ------- |
			| 1  | 501      | 2      | 1201        | Sales manager  | true    | active  |
			| 2  | 503      | 2      | 1202        | Export manager | true    | active  |
			| 3  | 540      | 2      | 1203        | Owner          | true    | invited |

	### SupplierQualification [DIST][INH] -- the eligibility decision per tenant; it expires, which triggers renewal
		- id
		- uuid
		- qualification_number             -- from DocumentSequence -- the qualification's document number
		- qualified_from                   -- date nullable -- first day the supplier may be used; set on approval
		- qualified_to                     -- date nullable -- last valid day; renewal is due before it
		- maximum_order_value              -- numeric(18,4) nullable -- largest single PO allowed; NULL = no cap
		- review_notes                     -- jsonb nullable -- the reviewer's findings
		- decision_notes                   -- jsonb nullable -- why it was approved, returned or rejected
		- decided_at                       -- timestamp nullable -- when the decision was made
		- application_type_lookup_value_id -- FK LookupValue (QUALIFICATION_TYPE)
		- channel_lookup_value_id          -- FK LookupValue (SUBMISSION_CHANNEL) -- staff entry or the portal
		- supplier_registration_id         -- FK SupplierRegistration nullable -- the registration that started it
		- tenant_id
		- entity_id                        -- approval for one Org does not cover a sister Org
		- supplier_id                      -- XFK Supplier -- the supplier being qualified
		- fiscal_year_id                   -- XFK Accounting FiscalYear nullable -- year an annual qualification covers
		- currency_id                      -- XFK Currency nullable -- currency of maximum_order_value
		- document_id                      -- XFK Document -- the qualification document and its approval
		- decided_by                       -- XFK User nullable -- who made the decision
		- qualification_status_lookup_value_id -- FK LookupValue (QUALIFICATION_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, qualification_number)
		-- INDEX (supplier_id, entity_id, qualification_status_lookup_value_id), (qualified_to)
		-- CHECK (app-level): at most one approved, unexpired qualification per (supplier_id, entity_id)
		> examples:
			| id  | supplier | entity | type | channel  | qualified_from | qualified_to | max_order | status   |
			| --- | -------- | ------ | ---- | -------- | -------------- | ------------ | --------- | -------- |
			| 600 | 501      | 2      | new  | internal | 2026-07-01     | 2027-06-30   | 1500000   | approved |
			| 602 | 503      | 2      | new  | internal | 2026-08-01     | 2028-07-31   | --        | approved |
			| 604 | 540      | 2      | new  | internal | 2026-07-05     | 2027-06-30   | 200000    | approved |

	### SupplierQualificationDocument [LINE] -- compliance checklist: each required document, expiry and review
		- id
		- uuid
		- reference_number                 -- varchar nullable -- the number printed on the document
		- issued_at                        -- date nullable -- issue date on the document
		- expires_at                       -- date nullable -- expiry date; a licence renews on its own cycle
		- is_mandatory                     -- bool -- true = approval waits for this document
		- verified_at                      -- timestamp nullable -- when a reviewer checked it
		- remarks                          -- text nullable -- the reviewer's comment
		- document_type_lookup_value_id    -- FK LookupValue (SUPPLIER_DOCUMENT_TYPE)
		- review_result_lookup_value_id    -- FK LookupValue (DOCUMENT_REVIEW_RESULT) -- what the review found
		- supplier_qualification_id        -- FK SupplierQualification
		- supersedes_id                    -- FK self nullable -- the expired row a renewal replaces
		- document_attachment_id           -- XFK DocumentAttachment nullable -- the uploaded file
		- verified_by                      -- XFK User nullable -- who checked it
		- user_id
		- state
		-- INDEX (supplier_qualification_id, document_type_lookup_value_id), (expires_at)
		-- CHECK (app-level): no approval while a mandatory row is not compliant or waived
		> examples:
			| id | qualification | document_type   | reference      | expires_at | mandatory | review_result |
			| -- | ------------- | --------------- | -------------- | ---------- | --------- | ------------- |
			| 1  | 600           | trade_license   | AA/1123/18     | 2027-01-15 | true      | compliant     |
			| 2  | 600           | vat_certificate | VAT-0044821    | --         | true      | compliant     |
			| 3  | 604           | tax_clearance   | MOR-TC-2026-11 | 2026-09-30 | true      | compliant     |

	### SupplierProcurementCategory [DIST][INH] -- categories a supplier may supply, one row per supplier and entity
												-- categories the supplier is allowed to supply
		- id
		- uuid
		- is_preferred                     -- bool -- listed first in pickers
		- minimum_order_value              -- numeric(18,4) nullable -- smallest order the supplier accepts here
		- approved_at                      -- timestamp nullable -- NULL = requested on a qualification not yet approved
		- supplier_qualification_id        -- FK SupplierQualification -- the qualification that last approved it
		- procurement_category_id          -- FK ProcurementCategory -- the category it may supply
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- the supplier
		- supplier_procurement_status_lookup_value_id -- FK LookupValue (SUPPLIER_PROCUREMENT_STATUS) nullable
		- user_id
		- state
		-- UNIQUE (supplier_id, entity_id, procurement_category_id)
		-- INDEX (entity_id, procurement_category_id, supplier_procurement_status_lookup_value_id, is_preferred)
		-- a renewal or extension, once approved, re-points supplier_qualification_id; rows are never copied
		-- the status is set on approval; an expired qualification sets its categories to expired,
		-- so pickers read status = active only
		> examples:
			| id | supplier | entity | category | qualification | preferred | approved_at | status    |
			| -- | -------- | ------ | -------- | ------------- | --------- | ----------- | --------- |
			| 1  | 501      | 2      | 11       | 600           | true      | 2026-07-01  | active    |
			| 2  | 501      | 2      | 10       | 600           | false     | 2026-07-01  | suspended |
			| 3  | 503      | 2      | 20       | 602           | true      | 2026-08-01  | active    |
			| 4  | 540      | 2      | 50       | 604           | false     | 2026-07-05  | active    |

	### SupplierStatusLog [DIST] -- procurement eligibility over time; blacklisting never touches the core supplier row
		- id
		- uuid
		- reason                           -- text -- why the status changed
		- effective_from                   -- date -- first day the new status applies
		- effective_to                     -- date nullable -- last day of a time-boxed suspension; NULL = open-ended
		- changed_at                       -- timestamp -- when the change was recorded
		- supplier_qualification_id        -- FK SupplierQualification nullable -- the qualification it concerns, if any
		- supplier_procurement_category_id -- FK SupplierProcurementCategory nullable -- NULL = the whole supplier
		- from_status_lookup_value_id      -- FK LookupValue (SUPPLIER_PROCUREMENT_STATUS) nullable
		- to_status_lookup_value_id        -- FK LookupValue (SUPPLIER_PROCUREMENT_STATUS)
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- the supplier whose status changed
		- document_id                      -- XFK Document nullable -- the suspension or blacklist memo
		- changed_by                       -- XFK User -- who made the change
		- user_id
		-- INDEX (supplier_id, entity_id, changed_at), (supplier_procurement_category_id)
		-- each row also sets the status it names on the category row, or on every category row of
		-- the supplier when NULL
		> examples:
			| id | supplier | category | from      | to         | from_date  | to_date    | reason                     |
			| -- | -------- | -------- | --------- | ---------- | ---------- | ---------- | -------------------------- |
			| 1  | 502      | --       | active    | suspended  | 2026-09-14 | 2026-10-14 | Three late deliveries      |
			| 2  | 502      | --       | suspended | reinstated | 2026-10-15 | --         | Corrective action verified |
			| 3  | 501      | 2 (F&B)  | active    | suspended  | 2026-11-02 | 2026-12-02 | Short weight, 2 deliveries |

	### SupplierRiskProfile [DIST][INH] -- one current assessment per supplier per entity
		- id
		- uuid
		- risk_score                       -- numeric(18,6) nullable -- overall risk, 0 (none) to 100 (highest)
		- concentration_percent            -- numeric(18,6) nullable -- its share of category spend when assessed
		- requires_dual_approval           -- bool -- true = every PO to this supplier needs a second approver
		- restrictions                     -- jsonb nullable -- limits set by management, e.g. a lower PO cap
		- assessed_at                      -- timestamp -- when this assessment was made
		- next_review_at                   -- date nullable -- when it must be reassessed
		- notes                            -- text nullable -- the assessor's remarks
		- risk_level_lookup_value_id       -- FK LookupValue (SUPPLIER_RISK_LEVEL)
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- the supplier assessed
		- assessed_by                      -- XFK User -- who made the assessment
		- user_id
		- state
		-- UNIQUE (supplier_id, entity_id) | INDEX (entity_id, risk_level_lookup_value_id)
		> examples:
			| id | supplier | entity | risk_level | score | concentration % | dual_approval | next_review |
			| -- | -------- | ------ | ---------- | ----- | --------------- | ------------- | ----------- |
			| 1  | 501      | 2      | low        | 18    | 62.4            | false         | 2027-01-01  |
			| 2  | 502      | 2      | high       | 71    | 12.0            | true          | 2026-11-01  |
			| 3  | 503      | 2      | medium     | 44    | 100.0           | false         | 2027-02-01  |

	### SupplierRiskEvent [LINE] -- the register behind the profile: each risk, its evidence and mitigation
		- id
		- uuid
		- description                      -- jsonb
		- evidence_note                    -- jsonb nullable -- what shows the risk, e.g. receipt or claim numbers
		- mitigation                       -- jsonb nullable -- what is being done about it
		- raised_at                        -- timestamp -- when the risk was recorded
		- review_due_at                    -- date nullable -- when it must be reviewed again
		- closed_at                        -- timestamp nullable -- when it was closed
		- risk_type_lookup_value_id        -- FK LookupValue (SUPPLIER_RISK_TYPE)
		- risk_level_lookup_value_id       -- FK LookupValue (SUPPLIER_RISK_LEVEL)
		- supplier_risk_profile_id         -- FK SupplierRiskProfile
		- source_purchase_order_id         -- FK PurchaseOrder nullable  [FOLLOW-UP MIGRATION] -- the PO that showed it
		- document_attachment_id           -- XFK DocumentAttachment nullable -- the evidence file
		- reviewed_by                      -- XFK User nullable -- who last reviewed it
		- supplier_risk_event_status_lookup_value_id -- FK LookupValue (SUPPLIER_RISK_EVENT_STATUS)
		- user_id
		- state
		-- INDEX (supplier_risk_profile_id, supplier_risk_event_status_lookup_value_id), (review_due_at)
		> examples:
			| id | profile | type       | level  | description                      | raised_at  | status    |
			| -- | ------- | ---------- | ------ | -------------------------------- | ---------- | --------- |
			| 1  | 2       | delivery   | high   | Three late deliveries in a month | 2026-09-14 | mitigated |
			| 2  | 2       | financial  | medium | Tax arrears reported by MOR      | 2026-10-02 | open      |
			| 3  | 1       | compliance | low    | Trade licence expires 2027-01-15 | 2026-11-01 | open      |

	### SupplierPriceList [DIST][INH] -- agreed catalogue or contract prices; what makes a direct purchase defensible
		- id
		- uuid
		- code                             -- unique per entity
		- name                             -- jsonb
		- valid_from                       -- date -- first day the prices apply
		- valid_to                         -- date nullable -- last day; NULL = until replaced
		- includes_tax                     -- bool -- true = prices include VAT
		- includes_delivery                -- bool -- true = prices include delivery to our location
		- source_lookup_value_id           -- FK LookupValue (PRICE_LIST_SOURCE)
		- procurement_contract_id          -- FK ProcurementContract nullable  [FOLLOW-UP MIGRATION] -- its contract
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- whose prices these are
		- currency_id                      -- XFK Currency -- currency of the prices
		- price_list_status_lookup_value_id -- FK LookupValue (PRICE_LIST_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, code) | INDEX (supplier_id, entity_id, valid_from)
		> examples:
			| id  | code      | supplier | source    | valid_from | valid_to   | includes_tax | status |
			| --- | --------- | -------- | --------- | ---------- | ---------- | ------------ | ------ |
			| 700 | SPL-501-1 | 501      | catalogue | 2026-07-01 | 2026-12-31 | false        | active |
			| 701 | SPL-540-1 | 540      | catalogue | 2026-07-05 | 2027-06-30 | true         | active |
			| 702 | SPL-530-1 | 530      | contract  | 2026-07-01 | 2027-06-30 | false        | active |

	### SupplierPriceListItem [LINE] -- price breaks, lead times and service rates; a rate line has no product
		- id
		- uuid
		- supplier_item_code               -- varchar nullable -- their part number, or a skill code on a rate line
		- supplier_item_name               -- varchar nullable -- the item's name in the supplier's catalogue
		- description                      -- text nullable -- required when product_id is NULL
		- unit_price                       -- numeric(18,4) -- price per unit, in the list's currency
		- minimum_quantity                 -- numeric(18,4) default 0 -- price break: this price applies from here up
		- maximum_quantity                 -- numeric(18,4) nullable -- top of the price break; NULL = no limit
		- lead_time_days                   -- smallint nullable -- days from order to delivery the supplier quotes
		- pack_size                        -- numeric(18,4) nullable -- units per pack; orders go in whole packs
		- minimum_billable_quantity        -- numeric(18,4) nullable -- e.g. a four-hour call-out minimum
		- is_available                     -- bool -- false = the supplier cannot supply it now
		- supplier_price_list_id           -- FK SupplierPriceList
		- product_id                       -- XFK Product nullable -- our product; NULL on a service rate line
		- measurement_id                   -- XFK Measurement -- selling uom or rate basis (hour, day)
		- user_id
		- state
		-- UNIQUE (supplier_price_list_id, product_id, minimum_quantity) | INDEX (product_id)
		-- CHECK (app-level): product_id IS NOT NULL OR (supplier_item_code <> '' AND description <> '')
		> examples:
			| id | price_list | product | item_code    | min_qty | unit_price | uom  | min_billable |
			| -- | ---------- | ------- | ------------ | ------- | ---------- | ---- | ------------ |
			| 1  | 700        | Tomato  | AB-TOM-A     | 1       | 47.00      | kg   | --           |
			| 2  | 700        | Tomato  | AB-TOM-A     | 100     | 45.00      | kg   | --           |
			| 3  | 702        | --      | TECH-KITCHEN | 1       | 350.00     | hour | 4            |

	### SupplierChangeRequest [DIST] -- a proposed change to supplier data; old values stay live until approval
		- id
		- uuid
		- request_number                   -- from DocumentSequence -- the change request's number
		- current_values                   -- jsonb -- the approved values at request time
		- proposed_values                  -- jsonb -- same keys, new values
		- reason                           -- jsonb -- why the change is wanted
		- effective_from                   -- date nullable -- when the change should take effect
		- applied_at                       -- timestamp nullable -- when it was written to the supplier master
		- scope_lookup_value_id            -- FK LookupValue (SUPPLIER_CHANGE_SCOPE) -- which part of the supplier data
		- channel_lookup_value_id          -- FK LookupValue (SUBMISSION_CHANNEL) -- staff entry or the portal
		- supplier_user_id                 -- FK SupplierUser nullable -- raised on the portal
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- the supplier being changed
		- document_id                      -- XFK Document -- evidence and the approval workflow
		- supplier_change_status_lookup_value_id -- FK LookupValue (SUPPLIER_CHANGE_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, request_number) | INDEX (supplier_id, supplier_change_status_lookup_value_id)
		-- CHECK (app-level): one open request per (supplier_id, scope)
		> examples:
			| id | supplier | channel         | scope   | proposed                     | status    |
			| -- | -------- | --------------- | ------- | ---------------------------- | --------- |
			| 1  | 501      | supplier_portal | bank    | { Awash, 01320456789000 }    | approved  |
			| 2  | 502      | internal        | tax     | { vat_registered: true }     | submitted |
			| 3  | 540      | supplier_portal | contact | { phone: +251 911 22 33 44 } | draft     |


#4. Purchase requisition and demand                                [PRMS01-04]

	-- One requisition table serves the annual need list (planning_need) and the request
	-- to buy now (purchase), for stock, service, non-stock, capital and project demand.
	-- Reorder and MRP demand arrive as draft requisitions with a source_reference.

	### DemandConsolidation [DIST] -- the worksheet that merges many requisition lines into one sourcing action
		- id
		- uuid
		- code                             -- unique per entity
		- name                             -- jsonb
		- window_from                      -- date -- earliest required date of the lines gathered
		- window_to                        -- date -- latest required date of the lines gathered
		- notes                            -- jsonb nullable -- the buyer's notes
		- basis_lookup_value_id            -- FK LookupValue (CONSOLIDATION_BASIS)
		- procurement_unit_id              -- FK ProcurementUnit -- the buying unit that sources the result
		- procurement_category_id          -- FK ProcurementCategory nullable -- one category only; NULL = any
		- tenant_id
		- entity_id
		- currency_id                      -- XFK Currency -- currency of the estimates
		- consolidation_status_lookup_value_id -- FK LookupValue (CONSOLIDATION_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, code) | INDEX (entity_id, consolidation_status_lookup_value_id, window_from)
		> examples:
			| id  | code       | basis       | window_from | window_to  | status    |
			| --- | ---------- | ----------- | ----------- | ---------- | --------- |
			| 700 | DC-2026-14 | by_product  | 2026-08-12  | 2026-08-13 | converted |
			| 701 | DC-2026-15 | by_supplier | 2026-08-17  | 2026-08-21 | draft     |
			| 702 | DC-2026-16 | by_category | 2026-08-24  | 2026-08-28 | cancelled |

	### PurchaseRequisition [DIST] -- the demand document
		- id
		- uuid
		- requisition_number               -- from DocumentSequence -- the PR number everyone quotes
		- title                            -- varchar -- short subject shown in lists
		- justification                    -- jsonb nullable -- why the purchase is needed
		- required_date                    -- date -- when the goods or service are needed
		- estimated_total                  -- numeric(18,4) default 0 -- frozen at submit; decides threshold and route
		- approved_total                   -- numeric(18,4) default 0 -- frozen at approval; the amount reserved
		- submitted_at                     -- timestamp nullable -- when the requester submitted it
		- approved_at                      -- timestamp nullable -- when the last approver approved it
		- cancelled_at                     -- timestamp nullable -- when it was cancelled
		- assigned_at                      -- timestamp nullable -- when a buyer was assigned
		- assignment_note                  -- jsonb nullable -- instructions given to the buyer
		- source_reference                 -- jsonb nullable -- the reorder / MRP / renewal alert that raised it
		- notes                            -- jsonb nullable -- free remarks
		- type_lookup_value_id             -- FK LookupValue (REQUISITION_TYPE) -- annual need list or buy now
		- source_lookup_value_id           -- FK LookupValue (REQUISITION_SOURCE)
		- urgency_lookup_value_id          -- FK LookupValue (REQUISITION_URGENCY)
		- origin_lookup_value_id           -- FK LookupValue (PROCUREMENT_ORIGIN)
		- procurement_unit_id              -- FK ProcurementUnit nullable -- the unit that will buy it
		- procurement_category_id          -- FK ProcurementCategory -- spend category; decides the path
		- purchase_method_id               -- FK PurchaseMethod nullable -- from the threshold, frozen at approval
		- demand_consolidation_id          -- FK DemandConsolidation nullable -- the worksheet that gathered its lines
		- split_from_requisition_id        -- FK self nullable -- carved out of that requisition
		- tenant_id
		- entity_id                        -- who the demand is for
		- organization_unit_id             -- XFK HR OrganizationUnit nullable -- the requesting department
		- requester_employee_id            -- XFK Employee nullable -- who asked for it
		- assigned_buyer_employee_id       -- XFK Employee nullable -- buyer responsible for sourcing it
		- service_owner_employee_id        -- XFK Employee nullable -- signs the ServiceAcceptance of a service request
		- fiscal_year_id                   -- XFK Accounting FiscalYear -- budget year it is charged to
		- delivery_location_id             -- XFK Location nullable -- where to deliver
		- currency_id                      -- XFK Currency -- currency of the estimates
		- budget_commitment_id             -- XFK Accounting BudgetCommitment nullable -- reservation made on approval
		- document_id                      -- XFK Document -- the PR document: approval, notes and files
		- requisition_status_lookup_value_id -- FK LookupValue (REQUISITION_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, requisition_number)
		-- INDEX (entity_id, requisition_status_lookup_value_id, required_date), (requester_employee_id),
		--       (assigned_buyer_employee_id, requisition_status_lookup_value_id),
		--       (organization_unit_id, fiscal_year_id), (demand_consolidation_id)
		-- CHECK (app-level): over budget or unplanned needs an approved ProcurementPolicyException
		> examples:
			| id   | number  | type          | title             | source  | required   | estimated | status    |
			| ---- | ------- | ------------- | ----------------- | ------- | ---------- | --------- | --------- |
			| 4090 | PR-4090 | planning_need | F&B annual needs  | manual  | 2026-07-01 | 1086000   | approved  |
			| 4101 | PR-4101 | purchase      | Stockyard produce | manual  | 2026-08-12 | 18000     | converted |
			| 4104 | PR-4104 | purchase      | Pool bar produce  | manual  | 2026-08-13 | 2700      | converted |
			| 4108 | PR-4108 | purchase      | Le Spa produce    | reorder | 2026-08-13 | 2250      | converted |

	### PurchaseRequisitionLine [LINE] -- the approver may cut the quantity, not only approve or reject
		- id
		- uuid
		- line_number                      -- int -- order of the line on the requisition
		- description                      -- jsonb -- required when product_id is NULL
		- specification                    -- jsonb nullable -- technical details the supplier must meet
		- requested_quantity               -- numeric(18,4) -- quantity asked for, in the request unit
		- approved_quantity                -- numeric(18,4) nullable -- quantity the approver allowed
		- converted_quantity               -- numeric(18,4) default 0 -- quantity already sent to an RFQ or PO
		- cancelled_quantity               -- numeric(18,4) default 0 -- approved quantity dropped later
		- estimated_unit_price             -- numeric(18,4) -- expected price per request unit
		- estimated_amount                 -- numeric(18,4) -- requested quantity × estimated unit price
		- conversion_factor                -- numeric(18,6) default 1 -- from MeasurementConversion, then frozen
		- requested_stock_quantity         -- numeric(18,4) -- requested quantity in the stock unit
		- required_date                    -- date nullable -- per-line override of the header date
		- on_hand_at_request               -- numeric(18,4) nullable -- stock evidence at submit
		- on_order_at_request              -- numeric(18,4) nullable -- quantity already on order at submit
		- budget_available_at_request      -- numeric(18,4) nullable -- budget evidence at submit
		- service_period_from              -- date nullable -- start of the service period
		- service_period_to                -- date nullable -- end of the service period
		- purchase_requisition_id          -- FK PurchaseRequisition
		- procurement_category_id          -- FK ProcurementCategory -- spend category of the line
		- procurement_plan_version_line_id -- FK ProcurementPlanVersionLine nullable -- NULL = unplanned
		- split_from_line_id               -- FK self nullable -- the line this one was split from
		- rfq_line_id                      -- FK RfqLine nullable  [FOLLOW-UP MIGRATION] -- the RFQ line sourcing it
		- product_id                       -- XFK Product nullable -- our product; NULL on a free-text line
		- measurement_id                   -- XFK Measurement nullable -- unit the quantity is asked in
		- stock_measurement_id             -- XFK Measurement nullable -- the product's stock unit
		- location_id                      -- XFK Location nullable -- store or site the line is for
		- budget_line_id                   -- XFK Accounting BudgetLine nullable -- budget line charged
		- cost_center_dimension_id         -- XFK Accounting Dimension nullable -- cost centre charged
		- project_dimension_id             -- XFK Accounting Dimension nullable -- project charged
		- asset_category_id                -- XFK AssetCategory nullable -- capital_asset lines
		- custodian_employee_id            -- XFK Employee nullable -- future holder of a capital asset
		- suggested_supplier_id            -- XFK Supplier nullable -- a suggestion; never binds the buyer
		- requisition_line_status_lookup_value_id -- FK LookupValue (REQUISITION_LINE_STATUS)
		- user_id
		- state
		-- INDEX (purchase_requisition_id, line_number), (product_id), (procurement_plan_version_line_id),
		--       (rfq_line_id)
		-- CHECK (app-level): product_id IS NOT NULL OR description <> ''
		-- CHECK (database): (approved_quantity IS NULL AND converted_quantity = 0)
		--                   OR converted_quantity + cancelled_quantity <= approved_quantity
		-- converted_quantity is the only sourcing counter: an RFQ (direct or through a worksheet) or a
		-- direct PO adds to it in the same transaction, so sourcing the same approved quantity twice
		-- fails the CHECK. A PO made from an award does not add again (the award line counts it);
		-- quantity returned to the pool (RFQ failed or cancelled, worksheet line excluded) is
		-- subtracted and rfq_line_id is cleared
		> examples:
			| id | pr   | line | product | requested | approved | converted | est_price | plan_line | status    |
			| -- | ---- | ---- | ------- | --------- | -------- | --------- | --------- | --------- | --------- |
			| 1  | 4101 | 1    | Tomato  | 400       | 400      | 400       | 45.00     | 1         | converted |
			| 2  | 4104 | 1    | Tomato  | 60        | 60       | 60        | 45.00     | 1         | converted |
			| 3  | 4108 | 1    | Tomato  | 50        | 40       | 40        | 45.00     | 1         | converted |

	### PurchaseRequisitionStatusLog [LINE] -- every status move of a requisition
		- id
		- uuid
		- reason                           -- text nullable -- why it moved
		- changed_at                       -- timestamp -- when it moved
		- purchase_requisition_id          -- FK PurchaseRequisition
		- from_status_lookup_value_id      -- FK LookupValue (REQUISITION_STATUS) nullable
		- to_status_lookup_value_id        -- FK LookupValue (REQUISITION_STATUS)
		- changed_by                       -- XFK User nullable -- who moved it; NULL = the system
		- user_id
		-- INDEX (purchase_requisition_id, changed_at)
		> examples:
			| id | requisition | from      | to        | changed_by | reason                     |
			| -- | ----------- | --------- | --------- | ---------- | -------------------------- |
			| 1  | 4101        | submitted | approved  | 90         | Within plan and budget     |
			| 2  | 4108        | submitted | returned  | 90         | Quantity exceeds usage     |
			| 3  | 4101        | approved  | converted | 88         | Sourced through DC-2026-14 |

	### DemandConsolidationLine [LINE] -- one requisition line in one worksheet; an excluded line returns to the pool
		- id
		- uuid
		- consolidated_quantity            -- numeric(18,4) -- quantity of the requisition line gathered here
		- excluded_at                      -- timestamp nullable -- when the line was taken out; NULL = still in
		- exclusion_reason                 -- jsonb nullable -- required when excluded_at is set
		- demand_consolidation_id          -- FK DemandConsolidation
		- purchase_requisition_line_id     -- FK PurchaseRequisitionLine -- the requisition line gathered
		- user_id
		- state
		-- UNIQUE (demand_consolidation_id, purchase_requisition_line_id) | INDEX (purchase_requisition_line_id)
		-- UNIQUE (purchase_requisition_line_id) WHERE excluded_at IS NULL -- one live worksheet per requisition line
		-- CHECK (app-level): consolidated_quantity <= the requisition line's open quantity
		--                    (approved - converted - cancelled), read with that line locked
		-- cancelling the worksheet, or a failed or cancelled RFQ, sets excluded_at on its lines,
		-- so their quantity returns to the pool and can be sourced again
		> examples:
			| id | consolidation | requisition_line | quantity | excluded_at |
			| -- | ------------- | ---------------- | -------- | ----------- |
			| 1  | 700           | 1                | 400      | --          |
			| 2  | 700           | 3                | 40       | --          |
			| 3  | 700           | 2                | 60       | --          |



#5. RFQ, tender, bid and award                                     [PRMS01-05]

	-- One Rfq header for both kinds of sourcing; the purchase method says which. A tender
	-- (sealed, bonded, opened before a committee) adds the 1:1 RfqTenderDetail.
	-- BidSubmission is the receipt for a sealed envelope and carries no prices, which is
	-- what keeps "sealed" real; the prices arrive on SupplierQuotation.

	### EvaluationCriterion [DIST][INH] -- scoring rubric template; an RFQ copies the criteria it uses
		- id
		- uuid
		- code                             -- unique per entity
		- name                             -- jsonb
		- description                      -- jsonb nullable
		- weight_percent                   -- numeric(18,6) -- suggested weight; the RFQ copy may change it
		- maximum_score                    -- numeric(18,4) default 100 -- top of the scoring scale
		- minimum_pass_score               -- numeric(18,4) nullable -- below this the criterion fails; NULL = no floor
		- is_knockout                      -- bool -- a fail eliminates the bid
		- display_order                    -- smallint -- position on the scoring sheet
		- criterion_type_lookup_value_id   -- FK LookupValue (EVALUATION_CRITERION_TYPE)
		- scoring_method_lookup_value_id   -- FK LookupValue (EVALUATION_SCORING_METHOD)
		- procurement_category_id          -- FK ProcurementCategory nullable -- only for this category; NULL = all
		- tenant_id
		- entity_id
		- user_id
		- state
		-- UNIQUE (entity_id, code) | INDEX (entity_id, procurement_category_id, display_order)
		> examples:
			| id | code      | type       | weight | max | min_pass | knockout | scoring_method |
			| -- | --------- | ---------- | ------ | --- | -------- | -------- | -------------- |
			| 1  | TECH-SPEC | technical  | 40     | 100 | 60       | true     | manual         |
			| 2  | PRICE     | financial  | 40     | 100 | --       | false    | lowest_price   |
			| 3  | DELIVERY  | delivery   | 10     | 100 | --       | false    | ratio          |
			| 4  | WARRANTY  | commercial | 10     | 100 | --       | false    | manual         |

	### Rfq [DIST] -- one sourcing event, RFQ or tender; minimum_quotations is copied at issue
		- id
		- uuid
		- rfq_number                       -- from DocumentSequence -- printed on the notice and on every bid
		- title                            -- jsonb
		- scope_description                -- jsonb nullable -- what is being bought and the work involved
		- contact_information              -- jsonb nullable -- who bidders ask, as printed on the notice
		- publish_at                       -- timestamp nullable -- when the notice goes out on every channel
		- issued_at                        -- timestamp nullable -- released to suppliers; the rubric freezes here
		- closing_at                       -- timestamp -- submission deadline; an addendum may move it
		- clarification_deadline_at        -- timestamp nullable -- last moment bidders may ask questions
		- validity_days                    -- smallint -- days a quote must stay open after closing
		- estimated_value                  -- numeric(18,4) -- internal estimate; never shown on the portal
		- minimum_quotations               -- smallint -- quotes needed to award; copied from the method
		- allows_partial_bid               -- bool -- a bidder may quote a subset of the lines
		- allows_alternative_offer         -- bool -- a bidder may also offer an alternative design
		- is_public                        -- bool -- open invitation; copied from the purchase method at issue
		- delivery_terms                   -- jsonb nullable -- delivery conditions printed on the RFQ
		- payment_terms_text               -- jsonb nullable -- payment conditions as printed
		- quotations_finalized_at          -- timestamp nullable -- collection closed; no more quotes accepted
		- below_minimum_reason             -- jsonb nullable -- why it went ahead with fewer than minimum_quotations
		- cancelled_at                     -- timestamp nullable -- when the RFQ was cancelled
		- notes                            -- jsonb nullable -- internal remarks
		- procurement_unit_id              -- FK ProcurementUnit -- the buying unit running it
		- procurement_category_id          -- FK ProcurementCategory -- decides the path and who may be invited
		- purchase_method_id               -- FK PurchaseMethod -- RFQ, open tender, restricted tender ...
		- demand_consolidation_id          -- FK DemandConsolidation nullable -- the worksheet it came from
		- reissued_from_rfq_id             -- FK self nullable -- the failed round this one reissues
		- tenant_id
		- entity_id
		- currency_id                      -- XFK Currency -- currency of the estimate and the comparison
		- delivery_location_id             -- XFK Location nullable -- where the goods must be delivered
		- payment_term_id                  -- XFK PaymentTerm nullable -- the standard payment term offered
		- buyer_employee_id                -- XFK Employee -- the buyer in charge
		- document_id                      -- XFK Document -- number, approval and attachments
		- rfq_status_lookup_value_id       -- FK LookupValue (RFQ_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, rfq_number)
		-- INDEX (entity_id, rfq_status_lookup_value_id, closing_at), (reissued_from_rfq_id)
		> examples:
			| id   | number        | method            | title (en)        | closing    | estimated | status           |
			| ---- | ------------- | ----------------- | ----------------- | ---------- | --------- | ---------------- |
			| 2114 | RFQ-2026-0114 | OPEN_TENDER       | Dishwashers       | 2026-08-19 | 900000    | awarded          |
			| 2120 | RFQ-2026-0120 | RFQ               | August produce    | 2026-08-08 | 22500     | awarded          |
			| 2126 | RFQ-2026-0126 | RFQ               | Laundry chemicals | 2026-09-12 | 64000     | under_evaluation |
			| 2130 | RFQ-2026-0130 | OPEN_TENDER       | Laundry machines  | 2026-10-30 | 2400000   | under_evaluation |
			| 2131 | RFQ-2026-0131 | RESTRICTED_TENDER | Hood cleaning     | 2026-11-20 | 180000    | issued           |

	### RfqTenderDetail [LINE] -- 1:1 sidecar for a tender
		- id
		- uuid
		- is_sealed                        -- bool -- prices hidden until the opening is recorded
		- is_two_envelope                  -- bool -- technical opened and scored before financial
		- opening_at                       -- timestamp -- announced date and time of the public opening
		- opening_location                 -- varchar -- where the bids are opened
		- bid_bond_required                -- bool -- bidders must lodge a bid bond
		- bid_bond_percent                 -- numeric(18,6) nullable -- bond as a percent of the bid
		- bid_bond_amount                  -- numeric(18,4) nullable -- fixed bond amount, in the RFQ currency
		- bid_bond_validity_days           -- smallint nullable -- days the bond must stay valid after closing
		- performance_bond_percent         -- numeric(18,6) nullable -- required of the winner at contract
		- document_fee                     -- numeric(18,4) nullable -- price of the tender documents; NULL = free
		- eligibility_criteria             -- jsonb nullable -- who may bid (licence grade, experience ...), as printed
		- rfq_id                           -- FK Rfq
		- user_id
		- state
		-- UNIQUE (rfq_id)
		> examples:
			| id | rfq  | sealed | two_envelope | opening_at       | bond_required | bond % | perf_bond % | fee |
			| -- | ---- | ------ | ------------ | ---------------- | ------------- | ------ | ----------- | --- |
			| 1  | 2114 | true   | true         | 2026-08-20 10:00 | true          | 2      | 10          | 300 |
			| 2  | 2130 | true   | true         | 2026-10-31 10:00 | true          | 2      | 10          | 500 |
			| 3  | 2131 | true   | false        | 2026-11-21 10:00 | false         | --     | --          | --  |

	### RfqEvaluationCriterion [LINE] -- the rubric this RFQ announced, frozen at issue
		- id
		- uuid
		- weight_percent                   -- numeric(18,6) -- weight in this RFQ; the weights total 100
		- maximum_score                    -- numeric(18,4) -- top of the scale for this RFQ
		- minimum_pass_score               -- numeric(18,4) nullable -- below this the criterion fails; NULL = no floor
		- is_knockout                      -- bool -- a fail eliminates the bid
		- display_order                    -- smallint -- position on the scoring sheet
		- rfq_id                           -- FK Rfq
		- evaluation_criterion_id          -- FK EvaluationCriterion -- the template it was copied from
		- user_id
		- state
		-- UNIQUE (rfq_id, evaluation_criterion_id)
		-- CHECK (app-level): weights per rfq_id total 100 before issue; no change once issued_at is set
		> examples:
			| id | rfq  | criterion | weight | max | min_pass | knockout |
			| -- | ---- | --------- | ------ | --- | -------- | -------- |
			| 1  | 2114 | TECH-SPEC | 40     | 100 | 60       | true     |
			| 2  | 2114 | PRICE     | 40     | 100 | --       | false    |
			| 3  | 2114 | DELIVERY  | 10     | 100 | --       | false    |
			| 4  | 2114 | WARRANTY  | 10     | 100 | --       | false    |

	### RfqLine [LINE] -- what is being sourced; the award lines say how much went to whom
		- id
		- uuid
		- line_number                      -- int -- position on the RFQ
		- description                      -- jsonb nullable
		- specification                    -- jsonb nullable -- technical requirements a bid must meet
		- quantity                         -- numeric(18,4) -- quantity asked for, in measurement_id
		- estimated_unit_price             -- numeric(18,4) nullable -- internal; never shown on the portal
		- estimated_amount                 -- numeric(18,4) nullable -- quantity x estimated price; internal
		- required_date                    -- date nullable -- when the item is needed
		- allows_partial_quantity          -- bool -- a bidder may quote less than the full quantity
		- rfq_id                           -- FK Rfq
		- procurement_category_id          -- FK ProcurementCategory nullable -- set when it differs from the RFQ's
		- procurement_plan_version_line_id -- FK ProcurementPlanVersionLine nullable -- the plan line it buys
		- product_id                       -- XFK Product nullable -- catalogue item; NULL = described in text
		- measurement_id                   -- XFK Measurement nullable -- unit of the quantity
		- rfq_line_status_lookup_value_id  -- FK LookupValue (RFQ_LINE_STATUS)
		- user_id
		- state
		-- INDEX (rfq_id, line_number), (product_id), (procurement_plan_version_line_id)
		> examples:
			| id | rfq  | line | description             | quantity | uom | est_price | status  |
			| -- | ---- | ---- | ----------------------- | -------- | --- | --------- | ------- |
			| 1  | 2114 | 1    | Hood dishwasher         | 3        | pcs | 300000    | awarded |
			| 2  | 2120 | 1    | Tomato, grade A         | 500      | kg  | 45.00     | awarded |
			| 3  | 2130 | 1    | Washer-extractor 30 kg  | 2        | pcs | 1200000   | open    |
			| 4  | 2126 | 1    | Laundry detergent, 20 L | 100      | can | 640.00    | open    |

	### RfqSupplier [LINE] -- an invited or responding supplier; eligibility is re-checked at invitation
		- id
		- uuid
		- invited_at                       -- timestamp nullable -- invitation sent; NULL = answered a public notice
		- acknowledged_at                  -- timestamp nullable -- the supplier confirmed it received the invitation
		- responded_at                     -- timestamp nullable -- when its quotation or bid arrived
		- declined_at                      -- timestamp nullable -- the supplier said it will not bid
		- decline_reason                   -- text nullable -- the supplier's reason for not bidding
		- qualification_verified_at        -- timestamp nullable -- eligibility re-checked at invitation
		- document_fee_reference           -- varchar nullable -- receipt of the tender-document fee; NULL = not paid
		- outcome_notified_at              -- timestamp nullable -- award or regret letter sent
		- invitation_method_lookup_value_id -- FK LookupValue (RFQ_INVITATION_METHOD)
		- rfq_id                           -- FK Rfq
		- supplier_qualification_id        -- FK SupplierQualification nullable -- the qualification checked
		- supplier_id                      -- XFK Supplier -- the supplier invited or responding
		- contact_party_id                 -- XFK Party nullable -- the supplier's contact person for this RFQ
		- rfq_supplier_status_lookup_value_id -- FK LookupValue (RFQ_SUPPLIER_STATUS)
		- user_id
		- state
		-- UNIQUE (rfq_id, supplier_id) | INDEX (supplier_id, rfq_supplier_status_lookup_value_id)
		> examples:
			| id | rfq  | supplier | method | invited_at | responded_at | outcome_notified | status       |
			| -- | ---- | -------- | ------ | ---------- | ------------ | ---------------- | ------------ |
			| 1  | 2114 | 501      | email  | 2026-08-05 | --           | --               | declined     |
			| 2  | 2114 | 503      | portal | 2026-08-05 | 2026-08-18   | 2026-08-27       | responded    |
			| 3  | 2114 | 512      | portal | 2026-08-05 | 2026-08-18   | 2026-08-27       | responded    |
			| 4  | 2114 | 519      | letter | 2026-08-05 | 2026-08-19   | 2026-08-27       | disqualified |

	### RfqPublication [LINE] -- the bid announcement on one channel: what was published where, and when
		- id
		- uuid
		- announcement_text                -- jsonb -- the notice as published
		- publication_reference            -- varchar nullable -- newspaper and edition, URL, notice board
		- scheduled_at                     -- timestamp nullable -- defaults to Rfq.publish_at
		- published_at                     -- timestamp nullable -- when it actually appeared; NULL = not yet
		- withdrawn_at                     -- timestamp nullable -- notice taken down, e.g. on cancellation
		- advertisement_cost               -- numeric(18,4) nullable -- what the channel charged
		- channel_lookup_value_id          -- FK LookupValue (TENDER_PUBLICATION_CHANNEL) -- where it appeared
		- rfq_id                           -- FK Rfq
		- document_id                      -- XFK Document nullable -- the announcement, when it has its own approval
		- published_by                     -- XFK User nullable -- who confirmed it went out
		- user_id
		- state
		-- UNIQUE (rfq_id, channel_lookup_value_id) | INDEX (scheduled_at) WHERE published_at IS NULL
		> examples:
			| id | rfq  | channel         | reference                    | scheduled_at     | published_at     | cost |
			| -- | ---- | --------------- | ---------------------------- | ---------------- | ---------------- | ---- |
			| 1  | 2114 | newspaper       | Addis Zemen, 2026-08-04 p.11 | 2026-08-04 06:00 | 2026-08-04 06:00 | 4200 |
			| 2  | 2114 | supplier_portal | --                           | 2026-08-04 06:00 | 2026-08-04 06:00 | --   |
			| 3  | 2114 | ppa_portal      | PPA notice 2026/0451         | 2026-08-04 06:00 | 2026-08-04 09:30 | --   |

	### RfqRequiredDocument [LINE] -- what every bidder must submit; makes "responsive" a checklist
		- id
		- uuid
		- description                      -- jsonb nullable -- extra wording, e.g. "certified copy"
		- is_mandatory                     -- bool -- every bidder must submit it
		- is_knockout                      -- bool -- missing = non-responsive before any scoring
		- display_order                    -- smallint -- position on the checklist
		- document_type_lookup_value_id    -- FK LookupValue (SUPPLIER_DOCUMENT_TYPE)
		- envelope_type_lookup_value_id    -- FK LookupValue (BID_ENVELOPE_TYPE) nullable -- NULL on an unsealed RFQ
		- rfq_id                           -- FK Rfq
		- user_id
		- state
		-- UNIQUE (rfq_id, document_type_lookup_value_id)
		> examples:
			| id | rfq  | document_type              | envelope  | mandatory | knockout |
			| -- | ---- | -------------------------- | --------- | --------- | -------- |
			| 1  | 2114 | trade_license              | technical | true      | true     |
			| 2  | 2114 | tax_clearance              | technical | true      | true     |
			| 3  | 2114 | manufacturer_authorization | technical | true      | false    |

	### RfqSupplierDocument [LINE] -- a bidder's answer to one required document
		- id
		- uuid
		- submitted_at                     -- timestamp nullable -- NULL = not submitted
		- remark                           -- text nullable -- the reviewer's note
		- review_result_lookup_value_id    -- FK LookupValue (DOCUMENT_REVIEW_RESULT) -- what the check found
		- rfq_supplier_id                  -- FK RfqSupplier
		- rfq_required_document_id         -- FK RfqRequiredDocument -- the requirement this answers
		- document_attachment_id           -- XFK DocumentAttachment nullable -- the file submitted
		- checked_by                       -- XFK User nullable -- who reviewed it
		- user_id
		- state
		-- UNIQUE (rfq_supplier_id, rfq_required_document_id)
		-- CHECK (app-level): a missing or non-compliant knockout document makes the quotation non_responsive
		> examples:
			| id | rfq_supplier | required_doc | submitted_at | review_result | remark                    |
			| -- | ------------ | ------------ | ------------ | ------------- | ------------------------- |
			| 1  | 2 (503)      | 1            | 2026-08-18   | compliant     | --                        |
			| 2  | 3 (512)      | 3            | 2026-08-18   | non_compliant | Maker\'s letter not signed |
			| 3  | 3 (512)      | 1            | 2026-08-18   | compliant     | --                        |

	### RfqClarification [LINE] -- a published answer goes to every invited supplier
		- id
		- uuid
		- sequence_number                  -- int -- running number within the RFQ
		- question                         -- jsonb nullable -- the bidder's question; NULL on a buyer addendum
		- answer                           -- jsonb nullable -- the buyer's answer, or the addendum text
		- is_published                     -- bool -- shared with every invited supplier
		- is_addendum                      -- bool -- changes the terms; may move closing_at, Whether it changes the RFQ terms rather than merely answering a question.
		- asked_at                         -- timestamp -- when the question came in or the addendum was drafted
		- answered_at                      -- timestamp nullable -- when the answer was written
		- published_at                     -- timestamp nullable -- when it went out to every bidder
		- rfq_id                           -- FK Rfq
		- rfq_supplier_id                  -- FK RfqSupplier nullable -- who asked; NULL on a buyer-initiated addendum
		- rfq_line_id                      -- FK RfqLine nullable -- the line it is about; NULL = the whole RFQ
		- document_attachment_id           -- XFK DocumentAttachment nullable -- drawing or revised document sent
		- answered_by                      -- XFK User nullable -- the buyer who answered
		- user_id
		- state
		-- UNIQUE (rfq_id, sequence_number) | INDEX (rfq_id, is_published)
		> examples:
			| id | rfq  | seq | supplier | question                         | published | addendum |
			| -- | ---- | --- | -------- | -------------------------------- | --------- | -------- |
			| 1  | 2114 | 1   | 512      | Is 3-phase power available?      | true      | false    |
			| 2  | 2114 | 2   | --       | Closing extended to 19 Aug 17:00 | true      | true     |
			| 3  | 2114 | 3   | 503      | Can delivery come in two lots?   | true      | false    |

	### BidSubmission [LINE] -- the receipt for one sealed envelope, and what was read out when it was opened
		- id
		- uuid
		- submission_number                -- from DocumentSequence -- the receipt number given to the bidder
		- received_at                      -- timestamp -- when the envelope arrived
		- late_acceptance_reason           -- jsonb nullable -- why a late envelope was accepted; required then
		- envelope_seal_reference          -- varchar nullable -- physical seal or portal hash
		- read_out_amount                  -- numeric(18,4) nullable -- price read aloud at opening; NULL if technical
		- read_out_discount                -- jsonb nullable -- unconditional discount announced at opening
		- withdrawn_at                     -- timestamp nullable -- the bidder withdrew before closing
		- withdrawal_reason                -- jsonb nullable -- the bidder's reason for withdrawing
		- envelope_type_lookup_value_id    -- FK LookupValue (BID_ENVELOPE_TYPE)
		- rfq_id                           -- FK Rfq
		- rfq_supplier_id                  -- FK RfqSupplier -- the bidder
		- bid_opening_id                   -- FK BidOpening nullable  [FOLLOW-UP MIGRATION] -- opening that opened it
		- currency_id                      -- XFK Currency nullable -- currency of read_out_amount
		- document_id                      -- XFK Document nullable -- scan of the envelope cover or the portal upload
		- received_by                      -- XFK User -- who logged the envelope
		- bid_submission_status_lookup_value_id -- FK LookupValue (BID_SUBMISSION_STATUS)
		- user_id
		- state
		-- UNIQUE (rfq_supplier_id, envelope_type_lookup_value_id), UNIQUE (submission_number)
		-- INDEX (rfq_id, received_at)
		-- the bid bond is a SupplierGuarantee (bid_bond) pointing at this row; the document fee is on RfqSupplier
		> examples:
			| id | rfq  | rfq_supplier | envelope  | received_at      | read_out | currency | status        |
			| -- | ---- | ------------ | --------- | ---------------- | -------- | -------- | ------------- |
			| 1  | 2114 | 2 (503)      | technical | 2026-08-18 09:40 | --       | --       | opened        |
			| 2  | 2114 | 2 (503)      | financial | 2026-08-18 09:40 | 14200    | EUR      | opened        |
			| 3  | 2114 | 4 (519)      | technical | 2026-08-19 17:12 | --       | --       | rejected_late |
			| 4  | 2114 | 3 (512)      | technical | 2026-08-18 15:05 | --       | --       | opened        |
			| 5  | 2114 | 3 (512)      | financial | 2026-08-18 15:05 | 1020000  | ETB      | opened        |

	### BidOpening [LINE] -- the minuted opening of one envelope type; once finalised, change only by a correction
		- id
		- uuid
		- opening_number                   -- from DocumentSequence -- number on the minutes
		- opened_at                        -- timestamp -- when the envelopes were opened
		- opening_location                 -- varchar -- where they were opened
		- minutes                          -- jsonb -- what was read out and recorded, in words
		- finalised_at                     -- timestamp nullable -- minutes signed; the row is locked from here
		- correction_reason                -- jsonb nullable -- why a finalised opening was corrected
		- envelope_type_lookup_value_id    -- FK LookupValue (BID_ENVELOPE_TYPE)
		- correction_of_id                 -- FK self nullable -- the finalised opening this row corrects
		- rfq_id                           -- FK Rfq
		- committee_id                     -- XFK Committee -- the committee that opened the bids
		- document_id                      -- XFK Document -- signed minutes
		- bid_opening_status_lookup_value_id -- FK LookupValue (BID_OPENING_STATUS)
		- user_id
		- state
		-- UNIQUE (opening_number) | INDEX (rfq_id, envelope_type_lookup_value_id, opened_at)
		-- who attended and signed: ProcurementCommitteeAttendance (#7)
		> examples:
			| id | number     | rfq  | envelope  | opened_at        | committee | finalised_at     | status    |
			| -- | ---------- | ---- | --------- | ---------------- | --------- | ---------------- | --------- |
			| 1  | BO-2026-7  | 2114 | technical | 2026-08-20 10:00 | 31        | 2026-08-20 11:05 | finalised |
			| 2  | BO-2026-8  | 2114 | financial | 2026-08-24 10:00 | 31        | 2026-08-24 10:50 | finalised |
			| 3  | BO-2026-11 | 2130 | technical | 2026-10-31 10:00 | 31        | 2026-10-31 11:20 | finalised |

	### SupplierQuotation [DIST] -- a supplier's priced offer; evaluated_total is the normalised figure that ranks it
		- id
		- uuid
		- quotation_number                 -- from DocumentSequence -- our register number for the offer
		- supplier_reference               -- varchar nullable -- the supplier's own quotation or proforma number
		- quoted_at                        -- date -- date on the supplier's offer
		- valid_until                      -- date -- the offer expires after this date
		- subtotal                         -- numeric(18,4) default 0 -- line totals before discount and tax
		- discount_total                   -- numeric(18,4) default 0 -- total discount offered
		- tax_total                        -- numeric(18,4) default 0 -- total tax quoted
		- freight_amount                   -- numeric(18,4) default 0 -- freight quoted on top of the goods
		- other_charges                    -- numeric(18,4) default 0 -- any other quoted charge
		- grand_total                      -- numeric(18,4) default 0 -- the offer's total in currency_id, as printed
		- evaluated_total                  -- numeric(18,4) nullable -- ranking total in one currency, freight in
		- lead_time_days                   -- smallint nullable -- days from order to delivery, as offered
		- delivery_terms                   -- jsonb nullable -- delivery conditions offered
		- payment_terms_text               -- jsonb nullable -- payment conditions offered
		- warranty_terms                   -- jsonb nullable -- warranty offered
		- port_of_loading                  -- jsonb nullable -- port the goods ship from (foreign offers)
		- port_of_discharge                -- jsonb nullable -- port the goods arrive at, e.g. Djibouti
		- carrier_name                     -- jsonb nullable -- shipping line or airline, if known
		- revision_number                  -- smallint default 0 -- a revision is allowed only before closing_at
		- is_alternative_offer             -- bool -- a second offer that departs from the specification
		- non_responsive_reason            -- jsonb nullable -- required when status is non_responsive
		- total_score                      -- numeric(18,6) nullable -- weighted score; frozen on approval
		- rank                             -- smallint nullable -- 1 = best; set with total_score
		- notes                            -- jsonb nullable -- the buyer's remarks
		- rfq_id                           -- FK Rfq -- the RFQ this answers
		- rfq_supplier_id                  -- FK RfqSupplier -- the bidder
		- bid_submission_id                -- FK BidSubmission nullable -- financial envelope; NULL if unsealed
		- revised_from_id                  -- FK self nullable -- revision it replaces (now superseded)
		- tenant_id
		- entity_id
		- currency_id                      -- XFK Currency -- currency of the offer
		- payment_term_id                  -- XFK PaymentTerm nullable -- payment term offered, when standard
		- incoterm_lookup_value_id         -- FK LookupValue (INCOTERM) nullable
		- document_id                      -- XFK Document -- the scanned or uploaded offer
		- quotation_status_lookup_value_id -- FK LookupValue (QUOTATION_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, quotation_number), UNIQUE (rfq_supplier_id, is_alternative_offer, revision_number)
		-- INDEX (rfq_id, rank), (valid_until)
		-- only the latest revision that is not superseded is evaluated, ranked or awarded
		> examples:
			| id | rfq  | supplier | cur | grand_total | evaluated | incoterm | score | rank | status         |
			| -- | ---- | -------- | --- | ----------- | --------- | -------- | ----- | ---- | -------------- |
			| 1  | 2114 | 503      | EUR | 14200       | 1004000   | fob      | 79.2  | 1    | awarded        |
			| 2  | 2114 | 512      | ETB | 1020000     | 1020000   | ddp      | 68.4  | 2    | rejected       |
			| 3  | 2126 | 501      | ETB | 61000       | 61000     | ddp      | --    | --   | non_responsive |
			| 4  | 2120 | 501      | ETB | 22500       | 22500     | ddp      | --    | 1    | awarded        |
			| 5  | 2126 | 512      | ETB | 39000       | 39000     | ddp      | --    | 1    | shortlisted    |
			| 6  | 2126 | 519      | ETB | 26400       | 26400     | ddp      | --    | 2    | shortlisted    |

	### SupplierQuotationLine [LINE] -- rfq_line_id is the comparison axis: one query gives every price for a line
		- id
		- uuid
		- line_number                      -- int -- position on the quotation
		- supplier_item_code               -- varchar nullable -- the supplier's own item code
		- description                      -- text -- the item as the supplier describes it
		- quoted_quantity                  -- numeric(18,4) -- quantity offered
		- unit_price                       -- numeric(18,4) -- price per unit before discount and tax
		- discount_percent                 -- numeric(18,6) default 0 -- discount on this line, in percent
		- discount_amount                  -- numeric(18,4) default 0 -- discount on this line, in money
		- tax_amount                       -- numeric(18,4) default 0 -- tax on this line
		- line_total                       -- numeric(18,4) -- quantity x price, less discount, plus tax
		- lead_time_days                   -- smallint nullable -- delivery time for this item when it differs
		- is_alternative                   -- bool -- offered instead of the specified item
		- meets_specification              -- bool nullable -- the technical verdict; NULL = not judged yet
		- deviation_note                   -- text nullable -- where it differs from the specification
		- supplier_quotation_id            -- FK SupplierQuotation
		- rfq_line_id                      -- FK RfqLine -- the RFQ line priced
		- product_id                       -- XFK Product nullable -- our catalogue item, when matched
		- measurement_id                   -- XFK Measurement nullable -- unit of the quoted quantity
		- tax_rate_id                      -- XFK TaxRate nullable -- tax rate applied
		- brand_offered_id                 -- XFK Brand nullable -- brand offered
		- country_of_origin_id             -- XFK Country nullable -- where the item is made
		- user_id
		- state
		-- INDEX (supplier_quotation_id, line_number), (rfq_line_id)
		> examples:
			| id | quotation | rfq_line | quantity | unit_price | line_total | brand        | origin   | meets_spec |
			| -- | --------- | -------- | -------- | ---------- | ---------- | ------------ | -------- | ---------- |
			| 1  | 1         | 1        | 3        | 4733.33    | 14200      | Winterhalter | Germany  | true       |
			| 2  | 2         | 1        | 3        | 340000     | 1020000    | Elmi Olindo  | Italy    | true       |
			| 3  | 3         | 4        | 100      | 610.00     | 61000      | --           | Ethiopia | false      |
			| 4  | 4         | 2        | 500      | 45.00      | 22500      | --           | Ethiopia | true       |
			| 5  | 5         | 4        | 60       | 650.00     | 39000      | Diversey     | Kenya    | true       |
			| 6  | 6         | 4        | 40       | 660.00     | 26400      | Ecolab       | Egypt    | true       |

	### QuotationEvaluation [LINE] -- one stage of the evaluation of an RFQ, by a committee
		- id
		- uuid
		- evaluation_number                -- from DocumentSequence -- number on the evaluation report
		- evaluated_at                     -- timestamp -- when the stage was scored
		- methodology_note                 -- text nullable -- how the panel applied the rubric
		- finalised_at                     -- timestamp nullable -- report signed; change only by a correction
		- stage_lookup_value_id            -- FK LookupValue (EVALUATION_STAGE)
		- rfq_id                           -- FK Rfq
		- bid_opening_id                   -- FK BidOpening nullable -- the opening whose envelopes are scored
		- committee_id                     -- XFK Committee nullable -- the evaluating committee; NULL = the buyer alone
		- document_id                      -- XFK Document -- the signed evaluation report
		- evaluated_by                     -- XFK User -- who recorded the evaluation
		- evaluation_status_lookup_value_id -- FK LookupValue (EVALUATION_STATUS)
		- user_id
		- state
		-- UNIQUE (rfq_id, stage_lookup_value_id) | INDEX (rfq_id, evaluated_at)
		> examples:
			| id | rfq  | stage     | evaluated_at | opening | committee | status   |
			| -- | ---- | --------- | ------------ | ------- | --------- | -------- |
			| 1  | 2114 | technical | 2026-08-21   | 1       | 32        | approved |
			| 2  | 2114 | financial | 2026-08-25   | 2       | 32        | approved |
			| 3  | 2120 | combined  | 2026-08-09   | --      | --        | approved |
			| 4  | 2126 | combined  | 2026-09-14   | --      | --        | approved |

	### QuotationEvaluationScore [LINE] -- one evaluator's score of one quotation on one criterion
		- id
		- uuid
		- raw_score                        -- numeric(18,6) -- on the criterion's scale; the weighted score is computed
		- is_pass                          -- bool nullable -- result of a pass/fail or knockout criterion
		- remark                           -- text nullable -- the evaluator's reason for the score
		- quotation_evaluation_id          -- FK QuotationEvaluation
		- supplier_quotation_id            -- FK SupplierQuotation -- the offer scored
		- rfq_evaluation_criterion_id      -- FK RfqEvaluationCriterion -- the criterion scored
		- scored_by                        -- XFK User -- the evaluator
		- user_id
		- state
		-- UNIQUE (quotation_evaluation_id, supplier_quotation_id, rfq_evaluation_criterion_id, scored_by)
		-- INDEX (supplier_quotation_id)
		-- the panel average is an AVG over the evaluators' rows; no other table needed
		> examples:
			| id | evaluation | quotation | criterion | raw | is_pass | scored_by |
			| -- | ---------- | --------- | --------- | --- | ------- | --------- |
			| 1  | 1          | 1         | 1         | 88  | true    | 90        |
			| 2  | 1          | 2         | 1         | 71  | true    | 90        |
			| 3  | 1          | 1         | 1         | 85  | true    | 91        |

	### AwardRecommendation [DIST] -- who should win and why; a basis other than lowest_evaluated needs a justification
		- id
		- uuid
		- recommendation_number            -- from DocumentSequence -- number on the award memo
		- justification                    -- jsonb -- why this supplier; required when basis is not lowest_evaluated
		- negotiation_note                 -- jsonb nullable -- what was negotiated with the preferred bidder
		- negotiated_at                    -- timestamp nullable -- when the negotiation ended
		- recommended_at                   -- timestamp -- when the recommendation was made
		- approved_at                      -- timestamp nullable -- list stamp; the approver is on the document
		- award_basis_lookup_value_id      -- FK LookupValue (AWARD_BASIS)
		- rfq_id                           -- FK Rfq -- the RFQ awarded
		- quotation_evaluation_id          -- FK QuotationEvaluation -- the evaluation it rests on
		- tenant_id
		- entity_id
		- currency_id                      -- XFK Currency -- currency of the awarded amounts
		- committee_id                     -- XFK Committee nullable -- award_review committee, if the band needs one
		- document_id                      -- XFK Document -- the award memo and its approval
		- award_status_lookup_value_id     -- FK LookupValue (AWARD_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, recommendation_number) | INDEX (rfq_id, award_status_lookup_value_id)
		-- the recommended total, split-award flag and saving against estimate are computed from the lines
		> examples:
			| id | number      | rfq  | basis            | recommended_at | status    |
			| -- | ----------- | ---- | ---------------- | -------------- | --------- |
			| 1  | AWD-2026-31 | 2114 | best_value       | 2026-08-26     | converted |
			| 2  | AWD-2026-34 | 2120 | lowest_evaluated | 2026-08-09     | converted |
			| 3  | AWD-2026-38 | 2126 | lowest_evaluated | 2026-09-15     | submitted |

	### AwardRecommendationLine [LINE] -- one quoted line awarded; a split award is two rows on the same RFQ line
		- id
		- uuid
		- awarded_quantity                 -- numeric(18,4) -- quantity given to this supplier
		- awarded_unit_price               -- numeric(18,4) -- agreed price per unit, after negotiation
		- awarded_amount                   -- numeric(18,4) -- awarded quantity x price
		- converted_quantity               -- numeric(18,4) default 0 -- already ordered on a PO
		- award_recommendation_id          -- FK AwardRecommendation
		- supplier_quotation_line_id       -- FK SupplierQuotationLine -- gives the RFQ line, quotation and supplier
		- user_id
		- state
		-- INDEX (award_recommendation_id), (supplier_quotation_line_id)
		-- CHECK (app-level): SUM(awarded_quantity) per RFQ line <= RfqLine.quantity
		-- CHECK (database): converted_quantity <= awarded_quantity -- an award is ordered once
		> examples:
			| id | recommendation | quotation_line | quantity | unit_price | amount    | converted |
			| -- | -------------- | -------------- | -------- | ---------- | --------- | --------- |
			| 1  | 1              | 1 (503)        | 3        | 4733.33    | 14200 EUR | 3         |
			| 2  | 2              | 4 (501)        | 500      | 45.00      | 22500     | 500       |
			| 3  | 3              | 5 (512)        | 60       | 650.00     | 39000     | 0         |
			| 4  | 3              | 6 (519)        | 40       | 660.00     | 26400     | 0         |



#6. Purchase order and agreement                                   [PRMS01-06]

	-- The PO is the commitment: on issue it creates an Accounting BudgetCommitment and
	-- keeps the id; closing or cancelling releases the unused balance the same way. A
	-- framework call-off is a PO with framework_agreement_id set, so consumption of an
	-- agreement is a SUM over its POs, never a counter on the agreement.

	### FrameworkAgreement [DIST][INH] -- blanket order or rate contract; reaching the ceiling makes it exhausted, A framework agreement is a longer-term arrangement with a supplier.
		- id
		- uuid
		- agreement_number                 -- from DocumentSequence -- printed agreement number
		- title                            -- varchar -- short name shown in pickers, e.g. "Bakery 2026/27"
		- valid_from                       -- date -- first day call-offs may be placed
		- valid_to                         -- date -- last day call-offs may be placed
		- ceiling_amount                   -- numeric(18,4) nullable -- value cap over all call-offs; NULL = no cap
		- ceiling_quantity                 -- numeric(18,4) nullable -- quantity cap over all call-offs; NULL = no cap
		- minimum_call_off_amount          -- numeric(18,4) nullable -- smallest value one call-off PO may have
		- maximum_call_off_amount          -- numeric(18,4) nullable -- largest value one call-off PO may have
		- price_revision_allowed           -- bool -- true = agreed prices may change during the term
		- price_revision_note              -- jsonb nullable -- how prices may change, e.g. an indexation formula
		- auto_renew                       -- bool -- true = renews for another term unless notice is given
		- renewal_notice_days              -- smallint nullable -- days before valid_to that notice must be given
		- terms                            -- jsonb nullable -- delivery, payment and other agreed conditions
		- closed_at                        -- timestamp nullable -- when the agreement was closed
		- agreement_type_lookup_value_id   -- FK LookupValue (AGREEMENT_TYPE)
		- procurement_unit_id              -- FK ProcurementUnit -- buying unit that manages the agreement
		- procurement_category_id          -- FK ProcurementCategory -- what the agreement covers
		- award_recommendation_id          -- FK AwardRecommendation nullable -- award it came from; NULL = direct
		- procurement_contract_id          -- FK ProcurementContract nullable  [FOLLOW-UP MIGRATION] -- signed contract
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- supplier bound by the agreement
		- currency_id                      -- XFK Currency -- currency of prices and ceilings
		- payment_term_id                  -- XFK PaymentTerm nullable -- default payment term for call-offs
		- document_id                      -- XFK Document -- the agreement's core document: approval, signatures, files
		- agreement_status_lookup_value_id -- FK LookupValue (AGREEMENT_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, agreement_number)
		-- INDEX (entity_id, supplier_id, agreement_status_lookup_value_id), (valid_to)
		> examples:
			| id  | number      | type              | supplier | valid_to   | ceiling_qty | renew | status   |
			| --- | ----------- | ----------------- | -------- | ---------- | ----------- | ----- | -------- |
			| 800 | FA-2026-007 | quantity_contract | 501      | 2027-06-30 | 72000       | true  | active   |
			| 801 | FA-2026-008 | rate_contract     | 530      | 2027-06-30 | --          | false | active   |
			| 802 | FA-2026-009 | value_contract    | 512      | 2027-08-31 | --          | false | approved |

	### FrameworkAgreementLine [LINE] -- the agreed price book: one item, its price band and what we committed to take
		- id
		- uuid
		- line_number                      -- int -- order of the line on the agreement
		- description                      -- text -- item as written on the agreement
		- agreed_unit_price                -- numeric(18,4) -- fixed price per uom for every call-off
		- minimum_quantity                 -- numeric(18,4) nullable -- price break: the price applies from here
		- maximum_quantity                 -- numeric(18,4) nullable -- upper end of the price band
		- committed_quantity               -- numeric(18,4) nullable -- quantity we guaranteed to take over the term
		- consumed_quantity                -- numeric(18,4) default 0 -- already ordered on call-off PO lines
		- lead_time_days                   -- smallint nullable -- days from call-off to delivery
		- framework_agreement_id           -- FK FrameworkAgreement
		- product_id                       -- XFK Product nullable -- catalogue product; NULL = description only
		- measurement_id                   -- XFK Measurement nullable -- unit the price is per
		- tax_rate_id                      -- XFK TaxRate nullable -- tax applied on call-offs; NULL = untaxed
		- user_id
		- state
		-- INDEX (framework_agreement_id, line_number), (product_id)
		> examples:
			| id | agreement | line | description               | agreed_price | uom   | committed | consumed |
			| -- | --------- | ---- | ------------------------- | ------------ | ----- | --------- | -------- |
			| 1  | 800       | 1    | White loaf                | 32.00        | loaf  | 60000     | 60000    |
			| 2  | 800       | 2    | Bread roll                | 12.00        | piece | 12000     | 2100     |
			| 3  | 801       | 1    | Kitchen cleaning, monthly | 88000.00     | month | 12        | 12       |

	### PurchaseOrder [DIST] -- the commitment to a supplier; its totals are what the issued PO printed
		- id
		- uuid
		- order_number                     -- from DocumentSequence -- printed PO number; kept across amendments
		- revision_number                  -- smallint default 0 -- 0 = original; each applied amendment adds 1
		- order_date                       -- date -- date printed on the PO
		- expected_delivery_date           -- date nullable -- when we need the goods
		- promised_delivery_date           -- date nullable -- date the supplier committed to; on-time is measured on it
		- subtotal                         -- numeric(18,4) default 0 -- sum of line amounts before discount and tax
		- discount_total                   -- numeric(18,4) default 0 -- total discount printed on the PO
		- tax_total                        -- numeric(18,4) default 0 -- total VAT/tax printed on the PO
		- withholding_total                -- numeric(18,4) default 0 -- WHT shown for information; Accounting posts it
		- advance_percent                  -- numeric(18,6) nullable -- advance (ቀብድ) as a % of grand_total
		- advance_amount                   -- numeric(18,4) default 0 -- advance (ቀብድ) paid before delivery
		- freight_amount                   -- numeric(18,4) default 0 -- freight charged on the PO
		- other_charges                    -- numeric(18,4) default 0 -- other charges such as packing or insurance
		- grand_total                      -- numeric(18,4) default 0 -- total printed: lines - discount + tax + charges
		- exchange_rate                    -- numeric(18,6) nullable -- rate to birr, frozen at issue; NULL = birr
		- delivery_address_snapshot        -- jsonb nullable -- delivery address as printed at issue
		- requires_inspection              -- bool -- true = receipts wait for inspection; from the category
		- supplier_reference               -- varchar nullable -- the supplier's sales order number
		- delivery_terms                   -- jsonb nullable -- delivery conditions printed on the PO
		- payment_terms_text               -- jsonb nullable -- payment conditions printed on the PO
		- warranty_terms                   -- jsonb nullable -- warranty conditions printed on the PO
		- notes                            -- jsonb nullable -- other remarks on the PO
		- issued_at                        -- timestamp nullable -- when the PO was sent to the supplier
		- acknowledged_at                  -- timestamp nullable -- when the supplier last accepted it (an event)
		- closed_at                        -- timestamp nullable -- when the PO was closed
		- cancelled_at                     -- timestamp nullable -- when the PO was cancelled
		- cancellation_reason              -- text nullable -- why it was cancelled
		- origin_lookup_value_id           -- FK LookupValue (PROCUREMENT_ORIGIN) -- foreign = an import order
		- procurement_unit_id              -- FK ProcurementUnit -- buying unit that issued it
		- procurement_category_id          -- FK ProcurementCategory -- its class decides the receipt path
		- purchase_method_id               -- FK PurchaseMethod -- method used: direct, RFQ, tender, framework ...
		- award_recommendation_id          -- FK AwardRecommendation nullable -- award it orders; NULL = no sourcing
		- framework_agreement_id           -- FK FrameworkAgreement nullable -- set = a call-off on this agreement
		- procurement_contract_id          -- FK ProcurementContract nullable  [FOLLOW-UP MIGRATION] -- the contract
		- parent_purchase_order_id         -- FK self nullable -- cancelled PO this one replaces (supplier change)
		- supplier_qualification_id        -- FK SupplierQualification nullable -- qualification valid at issue
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- supplier the order is placed with
		- currency_id                      -- XFK Currency -- currency of prices and totals
		- delivery_location_id             -- XFK Location nullable -- store or site to deliver to
		- requesting_organization_unit_id  -- XFK HR OrganizationUnit nullable -- department the order is for
		- buyer_employee_id                -- XFK Employee nullable -- buyer who follows the order up
		- payment_term_id                  -- XFK PaymentTerm nullable -- payment term from core
		- incoterm_lookup_value_id         -- FK LookupValue (INCOTERM) nullable
		- budget_commitment_id             -- XFK Accounting BudgetCommitment nullable -- commitment made on issue
		- supplier_prepayment_id           -- XFK Accounting SupplierPrepayment nullable -- advance ledger in Accounting
		- withhold_rule_id                 -- XFK WithholdRule nullable -- withholding rule applied to the PO
		- document_id                      -- XFK Document -- core document: approval, signatures, files
		- purchase_order_status_lookup_value_id -- FK LookupValue (PURCHASE_ORDER_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, order_number) -- an amendment bumps revision_number on the same row
		-- INDEX (entity_id, purchase_order_status_lookup_value_id, order_date),
		--       (supplier_id, purchase_order_status_lookup_value_id), (framework_agreement_id),
		--       (award_recommendation_id), (buyer_employee_id, purchase_order_status_lookup_value_id)
		-- what is received, invoiced or returned is summed from the lines
		> examples:
			| id  | number       | rev | origin  | supplier | promised   | total     | agreement | status             |
			| --- | ------------ | --- | ------- | -------- | ---------- | --------- | --------- | ------------------ |
			| 455 | PO-2026-0455 | 0   | local   | 501      | 2026-07-08 | 1920000   | 800       | partially_received |
			| 501 | PO-2026-0501 | 1   | foreign | 503      | 2026-10-20 | 14200 EUR | --        | issued             |
			| 520 | PO-2026-0520 | 1   | local   | 501      | 2026-08-12 | 22500     | --        | closed             |
			| 560 | PO-2026-0560 | 0   | local   | 530      | 2027-06-30 | 1214400   | 801       | partially_received |
			| 561 | PO-2026-0561 | 0   | local   | 535      | 2027-02-28 | 483000    | --        | closed             |
			| 562 | PO-2026-0562 | 0   | foreign | 503      | 2026-11-30 | 3650 EUR  | --        | issued             |

	### PurchaseOrderLine [LINE] -- the rolling quantities in both uoms; matching uses ACCEPTED, not received
		- id
		- uuid
		- line_number                      -- int -- order of the line on the PO
		- description                      -- text -- item as printed on the PO
		- specification                    -- text nullable -- technical details the supplier must meet
		- ordered_quantity                 -- numeric(18,4) -- quantity ordered, in order uom
		- unit_price                       -- numeric(18,4) -- price per order uom before discount and tax
		- discount_percent                 -- numeric(18,6) default 0 -- discount % on this line
		- discount_amount                  -- numeric(18,4) default 0 -- discount value on this line
		- pre_tax_amount                   -- numeric(18,4) -- quantity x unit_price - discount
		- tax_amount                       -- numeric(18,4) default 0 -- VAT/tax on this line
		- withholding_amount               -- numeric(18,4) default 0 -- withholding on this line, for display
		- line_total                       -- numeric(18,4) -- pre_tax_amount + tax_amount
		- conversion_factor                -- numeric(18,6) default 1 -- order uom -> stock uom, frozen here
		- ordered_stock_quantity           -- numeric(18,4) -- ordered_quantity x conversion_factor
		- received_quantity                -- numeric(18,4) default 0 -- received so far, order uom
		- accepted_quantity                -- numeric(18,4) default 0 -- passed inspection; invoices match on this
		- rejected_quantity                -- numeric(18,4) default 0 -- failed inspection
		- returned_quantity                -- numeric(18,4) default 0 -- sent back to the supplier
		- invoiced_quantity                -- numeric(18,4) default 0 -- already on matched supplier invoices
		- cancelled_quantity               -- numeric(18,4) default 0 -- will not be delivered: cut or short-closed
		- required_date                    -- date nullable -- needed-by date when it differs from the PO
		- is_free_of_charge                -- bool default false -- samples and bonus goods; matching skips them
		- service_period_from              -- date nullable -- service lines: first day of service
		- service_period_to                -- date nullable -- service lines: last day of service
		- purchase_order_id                -- FK PurchaseOrder
		- purchase_requisition_line_id     -- FK PurchaseRequisitionLine nullable -- request line ordered directly
		- award_recommendation_line_id     -- FK AwardRecommendationLine nullable -- award line it orders
		- framework_agreement_line_id      -- FK FrameworkAgreementLine nullable -- agreement price line (call-off)
		- contract_milestone_id            -- FK ContractMilestone nullable  [FOLLOW-UP MIGRATION] -- milestone it bills
		- procurement_category_id          -- FK ProcurementCategory -- category of this line
		- product_id                       -- XFK Product nullable -- catalogue product; NULL = description only
		- measurement_id                   -- XFK Measurement -- order uom
		- stock_measurement_id             -- XFK Measurement nullable -- stock uom when it differs from the order uom
		- location_id                      -- XFK Location nullable -- store for this line; NULL = PO delivery location
		- tax_rate_id                      -- XFK TaxRate nullable -- tax rate applied; NULL = no tax
		- budget_line_id                   -- XFK Accounting BudgetLine nullable -- budget line charged
		- cost_center_dimension_id         -- XFK Accounting Dimension nullable -- cost center charged
		- project_dimension_id             -- XFK Accounting Dimension nullable -- project charged, if any
		- asset_category_id                -- XFK AssetCategory nullable -- capital_asset lines: asset class to register
		- custodian_employee_id            -- XFK Employee nullable -- capital_asset lines: who will hold the asset
		- purchase_order_line_status_lookup_value_id -- FK LookupValue (PURCHASE_ORDER_LINE_STATUS)
		- user_id
		- state
		-- INDEX (purchase_order_id, line_number), (product_id), (purchase_requisition_line_id),
		--       (framework_agreement_line_id)
		> examples:
			| id | po  | product | ordered | uom  | price     | received | accepted | invoiced | status             |
			| -- | --- | ------- | ------- | ---- | --------- | -------- | -------- | -------- | ------------------ |
			| 1  | 455 | Loaf    | 60000   | loaf | 32.00     | 11400    | 11350    | 11350    | partially_received |
			| 2  | 520 | Tomato  | 500     | kg   | 45.00     | 490      | 490      | 490      | short_closed       |
			| 3  | 520 | Tomato  | 10      | kg   | 0.00 free | 10       | 10       | 0        | closed             |
			| 4  | 501 | Washer  | 3       | pcs  | 4733.33   | 0        | 0        | 0        | open               |

	### PurchaseOrderStatusLog [LINE] -- every status move of an order
		- id
		- uuid
		- reason                           -- text nullable -- why the status moved; NULL for routine moves
		- changed_at                       -- timestamp -- when the status moved
		- purchase_order_id                -- FK PurchaseOrder
		- from_status_lookup_value_id      -- FK LookupValue (PURCHASE_ORDER_STATUS) nullable
		- to_status_lookup_value_id        -- FK LookupValue (PURCHASE_ORDER_STATUS)
		- changed_by                       -- XFK User nullable -- who moved it; NULL = the system
		- user_id
		-- INDEX (purchase_order_id, changed_at)
		> examples:
			| id | po  | from           | to                 | changed_by | reason                           |
			| -- | --- | -------------- | ------------------ | ---------- | -------------------------------- |
			| 1  | 520 | approved       | issued             | 88         | --                               |
			| 2  | 520 | fully_received | short_closed       | 90         | 10 kg shortfall inside tolerance |
			| 3  | 455 | issued         | partially_received | --         | First bakery delivery received   |

	### PurchaseOrderAmendment [LINE] -- a change to an issued PO; bumps revision_number and keeps the before-image
		- id
		- uuid
		- amendment_number                 -- smallint -- 1, 2, 3 ... per PO; becomes the PO's revision_number
		- reason                           -- jsonb -- why the order is changed
		- before_snapshot                  -- jsonb -- header + lines before the change
		- total_before                     -- numeric(18,4) -- grand_total before the change
		- total_after                      -- numeric(18,4) -- grand_total after the change
		- requires_supplier_consent        -- bool -- true = the supplier must agree before it applies
		- supplier_consented_at            -- timestamp nullable -- when the supplier agreed
		- amended_at                       -- timestamp -- when the amendment was raised
		- effective_at                     -- timestamp nullable -- when the change took effect on the PO
		- amendment_type_lookup_value_id   -- FK LookupValue (PO_AMENDMENT_TYPE)
		- purchase_order_id                -- FK PurchaseOrder
		- document_id                      -- XFK Document nullable -- amendment document when it needs its own approval
		- amended_by                       -- XFK User -- who raised the amendment
		- po_amendment_status_lookup_value_id -- FK LookupValue (PO_AMENDMENT_STATUS)
		- user_id
		- state
		-- UNIQUE (purchase_order_id, amendment_number) | INDEX (purchase_order_id, amended_at)
		-- a supplier change is cancel-and-replace (parent_purchase_order_id), never an amendment
		> examples:
			| id | po  | no | type     | before    | after     | consent | status   | reason                        |
			| -- | --- | -- | -------- | --------- | --------- | ------- | -------- | ----------------------------- |
			| 1  | 520 | 1  | line_add | 22500     | 22500     | true    | applied  | Supplier adds 10 kg free      |
			| 2  | 501 | 1  | date     | 14200 EUR | 14200 EUR | true    | applied  | Supplier asked for 2026-10-20 |
			| 3  | 455 | 1  | quantity | 1920000   | 1728000   | true    | rejected | Cut 6000 loaves: refused      |

	### DeliverySchedule [LINE] -- the instalments of an order line; location_id lets one line deliver to several stores
		- id
		- uuid
		- instalment_number                -- smallint -- 1, 2, 3 ... within the order line
		- scheduled_quantity               -- numeric(18,4) -- quantity due in this instalment, order uom
		- delivered_quantity               -- numeric(18,4) default 0 -- received against this instalment so far
		- scheduled_date                   -- date -- date agreed for this instalment
		- revised_date                     -- date nullable -- new date after a delay; NULL = on plan
		- revision_reason                  -- jsonb nullable -- why the date moved
		- purchase_order_id                -- FK PurchaseOrder
		- purchase_order_line_id           -- FK PurchaseOrderLine -- the order line split into instalments
		- location_id                      -- XFK Location nullable -- store for this instalment; NULL = line store
		- delivery_schedule_status_lookup_value_id -- FK LookupValue (DELIVERY_SCHEDULE_STATUS)
		- user_id
		- state
		-- UNIQUE (purchase_order_line_id, instalment_number)
		-- INDEX (purchase_order_id, scheduled_date), (delivery_schedule_status_lookup_value_id, scheduled_date)
		-- CHECK (app-level): scheduled quantities of a line add up to its ordered_quantity
		> examples:
			| id | po  | line | inst | quantity | delivered | scheduled  | revised    | location | status    |
			| -- | --- | ---- | ---- | -------- | --------- | ---------- | ---------- | -------- | --------- |
			| 5  | 455 | 1    | 5    | 1154     | 1154      | 2026-08-03 | --         | 41       | delivered |
			| 6  | 455 | 1    | 6    | 1154     | 1154      | 2026-08-10 | 2026-08-12 | 41       | delivered |
			| 7  | 455 | 1    | 7    | 1154     | 0         | 2026-08-17 | --         | 41       | pending   |

	### PurchaseOrderEvent [LINE] -- the supplier's answer to an issued PO, then each dated milestone to delivery
		- id
		- uuid
		- event_at                         -- timestamp -- when it happened
		- location_text                    -- varchar nullable -- where it happened, e.g. "Modjo dry port"
		- revised_expected_at              -- date nullable -- new expected date this event implies
		- comment                          -- jsonb nullable -- the supplier's or buyer's message
		- follow_up_at                     -- date nullable -- date the buyer must chase an open query
		- event_type_lookup_value_id       -- FK LookupValue (PO_EVENT_TYPE) -- the answer or milestone
		- purchase_order_id                -- FK PurchaseOrder
		- purchase_order_line_id           -- FK PurchaseOrderLine nullable -- line it concerns; NULL = the whole order
		- delivery_schedule_id             -- FK DeliverySchedule nullable -- instalment it concerns
		- purchase_order_amendment_id      -- FK PurchaseOrderAmendment nullable -- amendment that answered it
		- import_shipment_id               -- FK ImportShipment nullable  [FOLLOW-UP MIGRATION] -- shipment it tracks
		- supplier_user_id                 -- FK SupplierUser nullable -- portal user who reported it
		- reported_by                      -- XFK User nullable -- buyer who keyed it in
		- document_attachment_id           -- XFK DocumentAttachment nullable -- proof file, e.g. a bill of lading
		- user_id
		- state
		-- INDEX (purchase_order_id, event_at), (follow_up_at), (import_shipment_id, event_at)
		> examples:
			| id | po  | event                 | event_at         | location       | revised_eta | comment           |
			| -- | --- | --------------------- | ---------------- | -------------- | ----------- | ----------------- |
			| 1  | 501 | query                 | 2026-08-27 10:00 | --             | --          | 380V 3-phase?     |
			| 2  | 501 | accepted_with_changes | 2026-08-29 15:20 | --             | 2026-10-20  | Moved one week    |
			| 3  | 501 | dispatched            | 2026-09-18 14:00 | Hamburg port   | 2026-10-20  | --                |
			| 4  | 501 | under_customs         | 2026-10-14 10:00 | Modjo dry port | 2026-10-24  | --                |
			| 5  | 455 | accepted_with_changes | 2026-07-06 09:00 | --             | --          | Asks 32.50 a loaf |

	### PurchaseOrderEventLine [LINE] -- a change the supplier asked for on one PO line; only an amendment applies it
		- id
		- uuid
		- proposed_quantity                -- numeric(18,4) nullable -- quantity offered; 0 = cannot supply the line
		- proposed_unit_price              -- numeric(18,4) nullable -- price the supplier asks instead
		- proposed_delivery_date           -- date nullable -- date the supplier can deliver instead
		- proposed_terms                   -- jsonb nullable -- specification, packaging or other wording to change
		- purchase_order_event_id          -- FK PurchaseOrderEvent
		- purchase_order_line_id           -- FK PurchaseOrderLine -- the line the change is for
		- user_id
		- state
		-- UNIQUE (purchase_order_event_id, purchase_order_line_id)
		-- CHECK (app-level): at least one proposed_* is set; the event is accepted_with_changes or query
		-- the current values are on the order line; once an amendment applies, its before_snapshot keeps them
		> examples:
			| id | event | po_line    | quantity | price | date       | terms              |
			| -- | ----- | ---------- | -------- | ----- | ---------- | ------------------ |
			| 1  | 2     | 4 (Washer) | --       | --    | 2026-10-20 | --                 |
			| 2  | 1     | 4 (Washer) | --       | --    | --         | 380V 3-phase model |
			| 3  | 5     | 1 (Loaf)   | --       | 32.50 | --         | --                 |

	### ProcurementPolicyException [DIST] -- approved departures from policy; exactly one source FK is set
		- id
		- uuid
		- exception_number                 -- from DocumentSequence -- printed exception number
		- requested_amount                 -- numeric(18,4) nullable -- amount asked for, e.g. the requisition total
		- available_amount                 -- numeric(18,4) nullable -- what is allowed, e.g. budget balance at request
		- justification                    -- jsonb -- why the departure is needed
		- expires_at                       -- timestamp nullable -- reusable until then; NULL = this document only
		- exception_type_lookup_value_id   -- FK LookupValue (POLICY_EXCEPTION_TYPE) -- the rule being waived
		- purchase_requisition_id          -- FK PurchaseRequisition nullable -- requisition it covers
		- rfq_id                           -- FK Rfq nullable -- RFQ it covers
		- purchase_order_id                -- FK PurchaseOrder nullable -- PO it covers
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier nullable -- supplier it is about, e.g. an unqualified one
		- budget_line_id                   -- XFK Accounting BudgetLine nullable -- budget line that is short
		- document_id                      -- XFK Document -- the request; its workflow approves it
		- policy_exception_status_lookup_value_id -- FK LookupValue (POLICY_EXCEPTION_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, exception_number)
		-- INDEX (entity_id, exception_type_lookup_value_id, policy_exception_status_lookup_value_id)
		> examples:
			| id | number   | type                     | source   | requested | available | status    |
			| -- | -------- | ------------------------ | -------- | --------- | --------- | --------- |
			| 1  | PEX-0012 | over_budget              | PR 4140  | 900000    | 760000    | approved  |
			| 2  | PEX-0013 | single_source            | RFQ 2121 | --        | --        | submitted |
			| 3  | PEX-0014 | below_minimum_quotations | RFQ 2120 | --        | --        | approved  |


#7. Delivery, goods receipt, inspection and service acceptance      [PRMS01-07]

	-- The boundary with Inventory: procurement calls the Inventory contract, Inventory
	-- creates a PURCHASE_RECEIPT StockOperation and posts the ledger, procurement keeps
	-- stock_operation_id. Reversing a receipt never deletes stock rows: a SupplierReturn
	-- takes the stock back out with its own PURCHASE_RETURN operation.
	-- A receipt line reads its product, uoms, factor and price from its PO line.

	### DeliveryNotice [DIST] -- the supplier's notice that goods are coming: what, when, on which vehicle, to whom
		- id
		- uuid
		- notice_number                    -- from DocumentSequence -- our reference for the notice
		- supplier_notice_number           -- varchar nullable -- the supplier's own dispatch number
		- expected_at                      -- timestamp -- when the supplier says the goods arrive
		- dispatched_at                    -- timestamp nullable -- when the goods left the supplier
		- vehicle_plate                    -- varchar nullable -- plate of the delivering vehicle, for the gate
		- driver_name                      -- varchar nullable -- driver expected at the gate
		- driver_phone                     -- varchar nullable -- to reach the driver when the truck is late
		- waybill_number                   -- varchar nullable -- transporter's waybill or consignment number
		- notes                            -- jsonb nullable -- supplier's remarks on the delivery
		- purchase_order_id                -- FK PurchaseOrder -- the order being delivered
		- import_shipment_id               -- FK ImportShipment nullable  [FOLLOW-UP MIGRATION] -- import's inland leg
		- supplier_user_id                 -- FK SupplierUser nullable -- set when the supplier sent it on the portal
		- tenant_id
		- entity_id
		- location_id                      -- XFK Location -- where the goods will arrive
		- receiving_officer_employee_id    -- XFK Employee nullable -- who is told to receive the goods
		- inspector_employee_id            -- XFK Employee nullable -- who is told to inspect them on arrival
		- document_id                      -- XFK Document nullable -- the notice's core document: number, files
		- delivery_notice_status_lookup_value_id -- FK LookupValue (DELIVERY_NOTICE_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, notice_number) | INDEX (purchase_order_id), (location_id, expected_at)
		> examples:
			| id | number  | po  | expected_at      | vehicle  | location | receiving_officer | status     |
			| -- | ------- | --- | ---------------- | -------- | -------- | ----------------- | ---------- |
			| 1  | DN-0311 | 455 | 2026-08-10 07:00 | 3-A12345 | 41       | 91                | received   |
			| 2  | DN-0312 | 455 | 2026-08-17 07:00 | 3-A12345 | 41       | 91                | announced  |
			| 3  | DN-0320 | 501 | 2026-10-24 08:00 | 3-B77821 | 41       | 91                | in_transit |

	### DeliveryNoticeLine [LINE] -- what the notice announces per order line or instalment
		- id
		- uuid
		- announced_quantity               -- numeric(18,4) -- quantity on the way, in the order's unit
		- batch_number                     -- varchar nullable -- supplier's batch or lot number
		- expiry_date                      -- date nullable -- expiry printed on the batch
		- delivery_notice_id               -- FK DeliveryNotice
		- purchase_order_line_id           -- FK PurchaseOrderLine -- the order line being delivered
		- delivery_schedule_id             -- FK DeliverySchedule nullable -- the instalment it covers, if scheduled
		- user_id
		- state
		-- UNIQUE (delivery_notice_id, purchase_order_line_id, delivery_schedule_id)
		> examples:
			| id | notice | po_line | schedule | announced | batch  |
			| -- | ------ | ------- | -------- | --------- | ------ |
			| 1  | 1      | 1       | 6        | 1154      | B-0810 |
			| 2  | 2      | 1       | --       | 1154      | B-0817 |
			| 3  | 3      | 4       | --       | 3         | --     |

	### GoodsReceipt [DIST] -- the GRN: one delivery as counted at the gate
		- id
		- uuid
		- receipt_number                   -- from DocumentSequence -- our GRN number
		- received_at                      -- timestamp -- when the goods were counted at the gate
		- supplier_delivery_note           -- varchar nullable -- the supplier's delivery-note number
		- supplier_delivery_date           -- date nullable -- date printed on their delivery note
		- waybill_number                   -- varchar nullable -- transporter's waybill or consignment number
		- vehicle_plate                    -- varchar nullable -- plate of the vehicle that delivered
		- driver_name                      -- varchar nullable -- driver who handed the goods over
		- days_variance                    -- smallint nullable -- days late (+) or early (-) against the due date
		- tolerance_exception_note         -- jsonb nullable -- why an out-of-tolerance receipt was allowed
		- posted_at                        -- timestamp nullable -- when Inventory posted the stock; NULL = not yet
		- notes                            -- jsonb nullable -- receiver's remarks
		- purchase_order_id                -- FK PurchaseOrder -- the order received against
		- delivery_notice_id               -- FK DeliveryNotice nullable -- the notice it fulfils, when one was sent
		- import_shipment_id               -- FK ImportShipment nullable  [FOLLOW-UP MIGRATION] -- set for an import
		- tenant_id
		- entity_id
		- location_id                      -- XFK Location -- the receiving store
		- gate_pass_id                     -- XFK Inventory GatePass nullable -- Inventory's gate entry record
		- stock_operation_id               -- XFK Inventory StockOperation nullable -- stock posting, NULL until posted
		- document_id                      -- XFK Document -- core document: number, approvals, files
		- received_by                      -- XFK User -- who counted and signed the receipt
		- goods_receipt_status_lookup_value_id -- FK LookupValue (GOODS_RECEIPT_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, receipt_number) | INDEX (purchase_order_id, received_at),
		--       (entity_id, goods_receipt_status_lookup_value_id, received_at), (stock_operation_id)
		> examples:
			| id   | number   | po  | received_at | delivery_note | notice | days_var | stock_op | status |
			| ---- | -------- | --- | ----------- | ------------- | ------ | -------- | -------- | ------ |
			| 9912 | GRN-9912 | 455 | 2026-08-03  | DN-77412      | --     | 0        | 33401    | posted |
			| 9940 | GRN-9940 | 520 | 2026-08-12  | DN-77590      | --     | 0        | 33455    | posted |
			| 9958 | GRN-9958 | 455 | 2026-08-12  | DN-77655      | 1      | 2        | 33470    | posted |

	### GoodsReceiptLine [LINE] -- delivered (supplier's claim) vs received (counted): the shortage evidence
		- id
		- uuid
		- line_number                      -- int -- position on the receipt
		- delivered_quantity               -- numeric(18,4) -- what the supplier says it delivered, order unit
		- received_quantity                -- numeric(18,4) -- what was counted at the gate, order unit
		- accepted_quantity                -- numeric(18,4) default 0 -- taken into stock after any inspection
		- rejected_quantity                -- numeric(18,4) default 0 -- refused at the gate or by inspection
		- quarantined_quantity             -- numeric(18,4) default 0 -- held aside until inspection decides
		- returned_quantity                -- numeric(18,4) default 0 -- sent back on a SupplierReturn
		- rejection_reason                 -- jsonb nullable -- the receiver's own words on a rejection
		- manufacture_date                 -- date nullable -- production date on the pack
		- expiry_date                      -- date nullable -- expiry date on the pack
		- serial_numbers                   -- jsonb nullable -- serials of serial-tracked items, as a list
		- storage_note                     -- jsonb nullable -- how it was stored, e.g. cold room
		- tolerance_result_lookup_value_id -- FK LookupValue (RECEIPT_TOLERANCE_RESULT)
		- rejection_reason_lookup_value_id -- FK LookupValue (RECEIPT_REJECTION_REASON) nullable
		- goods_receipt_id                 -- FK GoodsReceipt
		- purchase_order_line_id           -- FK PurchaseOrderLine -- the order line; gives product, unit and price
		- delivery_schedule_id             -- FK DeliverySchedule nullable -- the instalment this delivery settles
		- delivery_notice_line_id          -- FK DeliveryNoticeLine nullable -- the announced line it matches
		- receipt_tolerance_rule_id        -- FK ReceiptToleranceRule nullable -- the tolerance rule applied
		- location_id                      -- XFK Location -- store this line went to
		- quarantine_location_id           -- XFK Location nullable -- where quarantined stock is held
		- product_batch_id                 -- XFK ProductBatch nullable -- created by Inventory on post
		- goods_receipt_line_status_lookup_value_id -- FK LookupValue (GOODS_RECEIPT_LINE_STATUS)
		- user_id
		- state
		-- INDEX (goods_receipt_id, line_number), (purchase_order_line_id), (expiry_date)
		-- CHECK (app-level): accepted + rejected + quarantined <= received
		> examples:
			| id | grn  | po_line | delivered | received | accepted | rejected | tolerance    | status             |
			| -- | ---- | ------- | --------- | -------- | -------- | -------- | ------------ | ------------------ |
			| 1  | 9912 | 1       | 1154      | 1154     | 1104     | 50       | within       | partially_accepted |
			| 2  | 9940 | 2       | 500       | 490      | 490      | 0        | under_closed | accepted           |
			| 3  | 9940 | 3       | 10        | 10       | 10       | 0        | within       | accepted           |
			| 4  | 9958 | 1       | 1154      | 1154     | 1134     | 20       | within       | partially_accepted |

	### GoodsReceiptStatusLog [LINE] -- every status move of a receipt
		- id
		- uuid
		- reason                           -- text nullable -- why the status moved
		- changed_at                       -- timestamp -- when it moved
		- goods_receipt_id                 -- FK GoodsReceipt
		- from_status_lookup_value_id      -- FK LookupValue (GOODS_RECEIPT_STATUS) nullable
		- to_status_lookup_value_id        -- FK LookupValue (GOODS_RECEIPT_STATUS)
		- changed_by                       -- XFK User nullable -- who moved it; NULL = the system
		- user_id
		-- INDEX (goods_receipt_id, changed_at)
		> examples:
			| id | grn  | from     | to       | changed_by | reason                       |
			| -- | ---- | -------- | -------- | ---------- | ---------------------------- |
			| 1  | 9940 | received | accepted | 91         | Shortfall inside tolerance   |
			| 2  | 9940 | accepted | posted   | --         | Posted to stock by Inventory |
			| 3  | 9912 | draft    | received | 91         | Counted at the gate          |

	### InspectionChecklist [DIST][INH] -- a versioned inspection template; a version in use is never edited
		- id
		- uuid
		- code                             -- unique per entity and version
		- name                             -- jsonb
		- description                      -- jsonb nullable
		- is_mandatory                     -- bool default false -- true = its receipts must be inspected
		- version_number                   -- smallint default 1 -- goes up each time the template changes
		- effective_from                   -- date -- first day this version applies
		- effective_to                     -- date nullable -- last day; NULL = still current
		- inspection_type_lookup_value_id  -- FK LookupValue (INSPECTION_TYPE) nullable
		- procurement_category_id          -- FK ProcurementCategory nullable -- the category it is used for; NULL = any
		- tenant_id
		- entity_id
		- user_id
		- state
		-- UNIQUE (entity_id, code, version_number) | INDEX (procurement_category_id, state)
		> examples:
			| id | code        | name (en)                     | type     | category | mandatory | version |
			| -- | ----------- | ----------------------------- | -------- | -------- | --------- | ------- |
			| 1  | PERISH_QC   | Perishable produce inspection | sampling | 11       | true      | 1       |
			| 2  | DISHWASH_QC | Commercial dishwasher QC      | full     | 20       | true      | 2       |
			| 3  | OFFICE_VIS  | Office supplies visual check  | visual   | 50       | false     | 1       |

	### InspectionChecklistItem [LINE] -- one question of a checklist; a measured item carries its unit and limits
		- id
		- uuid
		- line_number                      -- smallint -- order on the checklist
		- item_code                        -- varchar -- short key, unique in the checklist
		- description                      -- jsonb -- what to check
		- inspection_method                -- text nullable -- how to check it, e.g. probe thermometer
		- expected_result                  -- text nullable -- what a pass looks like, in words
		- is_mandatory                     -- bool default true -- true = failing it fails the line
		- minimum_value                    -- numeric(18,4) nullable -- lowest passing reading, in the item's unit
		- maximum_value                    -- numeric(18,4) nullable -- highest passing reading, in the item's unit
		- allowed_result_lookup_value_id   -- FK LookupValue (INSPECTION_RESULT) nullable -- the result a pass needs
		- inspection_checklist_id          -- FK InspectionChecklist
		- measurement_id                   -- XFK Measurement nullable -- unit of a measured item; NULL = yes/no check
		- user_id
		- state
		-- UNIQUE (inspection_checklist_id, line_number), UNIQUE (inspection_checklist_id, item_code)
		> examples:
			| id | checklist | line | item_code | description (en)              | measurement | min | max | mandatory |
			| -- | --------- | ---- | --------- | ----------------------------- | ----------- | --- | --- | --------- |
			| 1  | 1         | 1    | FRESH     | No mould, rot or staleness    | --          | --  | --  | true      |
			| 2  | 1         | 2    | TEMP      | Core temperature on arrival   | celsius     | 2   | 8   | true      |
			| 3  | 2         | 1    | VOLTAGE   | Runs on a 380V 3-phase supply | volt        | 370 | 400 | true      |

	### GoodsInspection [DIST] -- quality inspection of a receipt; separate from the GRN, done later by others
		- id
		- uuid
		- inspection_number                -- from DocumentSequence -- our inspection reference
		- inspected_at                     -- timestamp -- when the inspection was done
		- sample_size                      -- numeric(18,4) nullable -- units inspected when sampling
		- sample_basis                     -- jsonb nullable -- sampling plan used, e.g. "AQL 2.5"
		- conditional_note                 -- text nullable -- what a conditional pass is subject to
		- summary_note                     -- jsonb nullable -- the inspector's overall finding
		- inspector_name                   -- jsonb nullable -- a third-party inspector who is not a user
		- certificate_reference            -- jsonb nullable -- lab or third-party certificate number
		- inspection_type_lookup_value_id  -- FK LookupValue (INSPECTION_TYPE)
		- overall_result_lookup_value_id   -- FK LookupValue (INSPECTION_RESULT)
		- goods_receipt_id                 -- FK GoodsReceipt -- the receipt inspected
		- inspection_checklist_id          -- FK InspectionChecklist nullable -- the checklist version applied
		- tenant_id
		- entity_id
		- committee_id                     -- XFK Committee nullable -- the inspecting committee, if any
		- document_id                      -- XFK Document -- the signed inspection report
		- inspected_by                     -- XFK User -- who recorded the inspection
		- inspection_status_lookup_value_id -- FK LookupValue (INSPECTION_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, inspection_number) | INDEX (goods_receipt_id)
		-- committee members sign on ProcurementCommitteeAttendance
		> examples:
			| id | number     | grn  | type     | sample_size | checklist | committee | result | status    |
			| -- | ---------- | ---- | -------- | ----------- | --------- | --------- | ------ | --------- |
			| 1  | INS-2026-4 | 9940 | sampling | 50          | 1         | 33        | passed | approved  |
			| 2  | INS-2026-5 | 9958 | sampling | 50          | 1         | 33        | passed | submitted |
			| 3  | INS-2026-6 | 9912 | visual   | --          | 1         | --        | failed | approved  |

	### GoodsInspectionLine [LINE] -- the verdict on one received line; a concession is a price cut instead of a return
		- id
		- uuid
		- inspected_quantity               -- numeric(18,4) -- how many were checked
		- passed_quantity                  -- numeric(18,4) -- how many passed
		- failed_quantity                  -- numeric(18,4) -- how many failed; the disposition says what happens
		- concession_percent               -- numeric(18,6) nullable -- price cut agreed to keep goods below spec
		- concession_amount                -- numeric(18,4) default 0 -- the match treats it as an expected variance
		- inspector_comment                -- text nullable -- inspector's note on this line
		- result_lookup_value_id           -- FK LookupValue (INSPECTION_RESULT)
		- disposition_lookup_value_id      -- FK LookupValue (INSPECTION_DISPOSITION)
		- goods_inspection_id              -- FK GoodsInspection
		- goods_receipt_line_id            -- FK GoodsReceiptLine -- the received line judged
		- user_id
		- state
		-- UNIQUE (goods_inspection_id, goods_receipt_line_id)
		> examples:
			| id | inspection | grn_line | inspected | passed | failed | result | disposition | concession % |
			| -- | ---------- | -------- | --------- | ------ | ------ | ------ | ----------- | ------------ |
			| 1  | 1          | 2        | 490       | 490    | 0      | passed | accept      | --           |
			| 2  | 1          | 3        | 10        | 10     | 0      | passed | accept      | --           |
			| 3  | 3          | 1        | 1154      | 1104   | 50     | failed | return      | --           |

	### GoodsInspectionResult [LINE] -- one checklist answer for one inspected line: evidence for a pass or a fail
		- id
		- uuid
		- measured_value                   -- numeric(18,4) nullable -- the reading; required on a measured item
		- finding                          -- jsonb nullable -- what the inspector saw
		- result_lookup_value_id           -- FK LookupValue (INSPECTION_RESULT)
		- goods_inspection_line_id         -- FK GoodsInspectionLine
		- inspection_checklist_item_id     -- FK InspectionChecklistItem -- the checklist question answered
		- inspected_by                     -- XFK User nullable -- who checked this item; members may split items
		- user_id
		- state
		-- UNIQUE (goods_inspection_line_id, inspection_checklist_item_id)
		-- CHECK (app-level): a value outside the item's limits is a fail; a failed mandatory item fails the line
		--   unless its disposition is accept_with_concession
		> examples:
			| id | inspection_line | checklist_item | result | measured | finding                     |
			| -- | --------------- | -------------- | ------ | -------- | --------------------------- |
			| 1  | 1               | 1 FRESH        | passed | --       | --                          |
			| 2  | 1               | 2 TEMP         | passed | 6.5      | --                          |
			| 3  | 3               | 1 FRESH        | failed | --       | 50 loaves stale, hard crust |

	### ServiceAcceptance [DIST] -- the service twin of the GRN, signed by the service owner; no stock moves
		- id
		- uuid
		- acceptance_number                -- from DocumentSequence -- our acceptance reference
		- service_period_from              -- date -- first day of the service accepted
		- service_period_to                -- date -- last day of the service accepted
		- accepted_at                      -- timestamp -- when the service owner signed
		- deliverable_description          -- jsonb -- what was delivered in the period
		- completion_evidence              -- jsonb -- proof: timesheets, reports, photos
		- performance_note                 -- jsonb nullable -- owner's comment on quality or SLA
		- is_final_acceptance              -- bool -- closes the PO line and starts the defect-liability clock
		- acceptance_type_lookup_value_id  -- FK LookupValue (SERVICE_ACCEPTANCE_TYPE)
		- purchase_order_id                -- FK PurchaseOrder -- the service order accepted against
		- tenant_id
		- entity_id
		- service_owner_employee_id        -- XFK Employee -- the business owner who signs, not the buyer
		- document_id                      -- XFK Document -- the signed acceptance certificate
		- service_acceptance_status_lookup_value_id -- FK LookupValue (SERVICE_ACCEPTANCE_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, acceptance_number) | INDEX (purchase_order_id, accepted_at)
		-- accepted and retained amounts are summed from the lines and the contract's retention rate
		> examples:
			| id  | number     | po  | type     | period_from | period_to  | final | status    |
			| --- | ---------- | --- | -------- | ----------- | ---------- | ----- | --------- |
			| 610 | SRN-2026-6 | 560 | periodic | 2026-08-01  | 2026-08-31 | false | approved  |
			| 611 | SRN-2026-7 | 561 | final    | 2026-08-01  | 2026-08-31 | true  | approved  |
			| 612 | SRN-2026-8 | 560 | periodic | 2026-09-01  | 2026-09-30 | false | submitted |

	### ServiceAcceptanceLine [LINE] -- an SLA penalty is applied at acceptance, not argued at invoice
		- id
		- uuid
		- line_number                      -- int -- position on the acceptance
		- description                      -- text -- what this line accepts
		- accepted_quantity                -- numeric(18,4) nullable -- accepted hours, visits or units
		- accepted_percent                 -- numeric(18,6) nullable -- share of a milestone accepted
		- accepted_amount                  -- numeric(18,4) -- value accepted before deductions
		- deduction_amount                 -- numeric(18,4) default 0 -- SLA penalty taken off the accepted amount
		- deduction_reason                 -- text nullable -- why the penalty was applied
		- service_acceptance_id            -- FK ServiceAcceptance
		- purchase_order_line_id           -- FK PurchaseOrderLine -- the service line accepted
		- contract_milestone_id            -- FK ContractMilestone nullable  [FOLLOW-UP MIGRATION] -- milestone accepted
		- supplier_price_list_item_id      -- FK SupplierPriceListItem nullable -- the contracted rate it is priced at
		- user_id
		- state
		-- INDEX (service_acceptance_id, line_number), (purchase_order_line_id)
		> examples:
			| id | acceptance | line | description         | qty | accepted | deduction | reason              |
			| -- | ---------- | ---- | ------------------- | --- | -------- | --------- | ------------------- |
			| 1  | 610        | 1    | Daily cleaning, Aug | 1   | 88000    | 2000      | 2 days missed cover |
			| 2  | 611        | 1    | Laundry, Aug (last) | 1   | 35000    | 0         | --                  |
			| 3  | 612        | 1    | Daily cleaning, Sep | 1   | 88000    | 0         | --                  |

	### SupplierReturn [DIST] -- the RTV(Return to Vendor); receipt_reversal is how posted stock goes back without deleting a ledger row
		- id
		- uuid
		- return_number                    -- from DocumentSequence -- our return (RTV) number
		- returned_at                      -- timestamp -- when the goods left our store
		- replacement_due_date             -- date nullable -- when a replacement is due; NULL = none expected
		- expects_credit_note              -- bool -- true = the supplier owes us a credit note
		- supplier_acknowledged_at         -- timestamp nullable -- when the supplier confirmed getting them back
		- posted_at                        -- timestamp nullable -- when Inventory took the stock out
		- reason                           -- text -- why the goods go back
		- return_type_lookup_value_id      -- FK LookupValue (SUPPLIER_RETURN_TYPE)
		- goods_receipt_id                 -- FK GoodsReceipt -- the receipt the goods came in on
		- goods_inspection_id              -- FK GoodsInspection nullable -- the inspection that failed them
		- supplier_claim_id                -- FK SupplierClaim nullable  [FOLLOW-UP MIGRATION] -- the claim it settles
		- tenant_id
		- entity_id
		- location_id                      -- XFK Location -- store the goods leave from
		- gate_pass_id                     -- XFK Inventory GatePass nullable -- gate exit pass for the goods
		- stock_operation_id               -- XFK Inventory StockOperation nullable -- the PURCHASE_RETURN operation
		- supplier_debit_note_id           -- XFK Accounting SupplierDebitNote nullable -- debit note raised in AP
		- document_id                      -- XFK Document -- the signed return note
		- supplier_return_status_lookup_value_id -- FK LookupValue (SUPPLIER_RETURN_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, return_number) | INDEX (goods_receipt_id)
		> examples:
			| id  | number      | grn  | type    | returned_at | credit_note | debit_note | status     |
			| --- | ----------- | ---- | ------- | ----------- | ----------- | ---------- | ---------- |
			| 880 | RTV-2026-9  | 9912 | quality | 2026-08-04  | true        | 5521       | credited   |
			| 881 | RTV-2026-10 | 9958 | damaged | 2026-08-12  | false       | --         | replaced   |
			| 882 | RTV-2026-11 | 9958 | recall  | 2026-08-14  | false       | --         | dispatched |

	### SupplierReturnLine [LINE] -- one received line going back; uom, factor and price come from the receipt's PO line
		- id
		- uuid
		- line_number                      -- int -- position on the return
		- returned_quantity                -- numeric(18,4) -- quantity sent back, in the order's unit
		- replaced_quantity                -- numeric(18,4) default 0 -- how many the supplier has replaced so far
		- credited_amount                  -- numeric(18,4) default 0 -- value credited back so far
		- reason                           -- text -- why this line goes back
		- supplier_return_id               -- FK SupplierReturn
		- goods_receipt_line_id            -- FK GoodsReceiptLine -- the received line it sends back
		- product_batch_id                 -- XFK ProductBatch nullable -- the batch taken out of stock
		- user_id
		- state
		-- INDEX (supplier_return_id, line_number), (goods_receipt_line_id)
		> examples:
			| id | return | grn_line | quantity | replaced | credited | reason                            |
			| -- | ------ | -------- | -------- | -------- | -------- | --------------------------------- |
			| 1  | 880    | 1        | 50       | 0        | 1600     | Stale on arrival                  |
			| 2  | 881    | 4        | 20       | 20       | 0        | Crushed crates                    |
			| 3  | 882    | 4        | 30       | 0        | 0        | Supplier recall, flour lot F-0812 |

	### ProcurementCommitteeAttendance [DIST] -- who attended and signed a bid opening, evaluation, award or inspection
		- id
		- uuid
		- attendee_name                    -- jsonb nullable -- outsider's name; required when employee_id is NULL
		- is_present                       -- bool -- true = attended; false = invited but absent
		- signed_at                        -- timestamp nullable -- when they signed the minutes; NULL = not signed
		- remark                           -- text nullable -- an objection or dissent, kept verbatim
		- attendee_role_lookup_value_id    -- FK LookupValue (PROCUREMENT_ATTENDEE_ROLE)
		- bid_opening_id                   -- FK BidOpening nullable -- set when the event is a bid opening
		- quotation_evaluation_id          -- FK QuotationEvaluation nullable -- set when the event is an evaluation
		- award_recommendation_id          -- FK AwardRecommendation nullable -- set when the event is an award review
		- goods_inspection_id              -- FK GoodsInspection nullable -- set when the event is an inspection
		- tenant_id
		- entity_id
		- committee_member_id              -- XFK CommitteeMember nullable -- the member's seat; NULL for a non-member
		- employee_id                      -- XFK Employee nullable -- the attendee, when an employee
		- supplier_id                      -- XFK Supplier nullable -- the bidder a representative speaks for
		- user_id
		- state
		-- INDEX (bid_opening_id), (quotation_evaluation_id), (award_recommendation_id),
		--       (goods_inspection_id), (employee_id)
		-- CHECK (app-level): exactly one event FK is set; employee_id IS NOT NULL OR attendee_name IS NOT NULL;
		--   signed members >= ProcurementCommitteeMandate.quorum before the event is finalised
		> examples:
			| id | event     | role                  | attendee        | signed_at        | remark                    |
			| -- | --------- | --------------------- | --------------- | ---------------- | ------------------------- |
			| 1  | opening 1 | chair                 | emp 90          | 2026-08-20 11:05 | --                        |
			| 2  | opening 1 | auditor               | emp 97          | 2026-08-20 11:06 | --                        |
			| 3  | opening 1 | bidder_representative | Kebede, for 519 | --               | Disputes the late finding |



#8. Supplier invoice matching and AP handover                      [PRMS01-08]

	-- Accounting owns the posted payable (ap_invoices) and never gets a second one from
	-- here. Procurement keeps the supplier's paper as it arrived (SupplierInvoiceReference),
	-- the comparison run (InvoiceMatch) and the moment it says "payable" (ApHandover),
	-- which stores the ap_invoice_id Accounting creates. AP is keyed on party_id: the
	-- handover resolves supplier -> party.

	### SupplierInvoiceReference [DIST] -- the supplier's invoice as received; a UNIQUE blocks an exact duplicate
		- id
		- uuid
		- reference_number                 -- ours, from DocumentSequence
		- supplier_invoice_number          -- varchar -- the number printed on the supplier's invoice
		- supplier_invoice_date            -- date -- the date printed on the invoice
		- fiscal_invoice_number            -- varchar nullable -- Ethiopian fiscal receipt number
		- fiscal_machine_number            -- varchar nullable -- serial of the fiscal machine that printed it
		- received_at                      -- timestamp -- when the invoice reached us
		- due_date                         -- date nullable -- payment due date, from the payment term
		- subtotal                         -- numeric(18,4) -- total before discount, tax and charges
		- discount_total                   -- numeric(18,4) default 0 -- discount printed on the invoice
		- vat_amount                       -- numeric(18,4) default 0 -- VAT charged on the invoice
		- excise_amount                    -- numeric(18,4) default 0 -- excise tax charged, if any
		- withholding_amount               -- numeric(18,4) default 0 -- withholding tax to deduct at payment
		- freight_amount                   -- numeric(18,4) default 0 -- freight billed on the invoice
		- other_charges                    -- numeric(18,4) default 0 -- any other charge printed on the invoice
		- grand_total                      -- numeric(18,4) -- the amount the supplier asks to be paid
		- exchange_rate                    -- numeric(18,6) nullable -- rate to birr for a foreign-currency invoice
		- supplier_tin                     -- varchar nullable -- TIN as printed; differs from master = a finding
		- supplier_vat_number              -- varchar nullable -- VAT number as printed
		- is_vat_registered_claimed        -- bool -- true = invoice presents the supplier as VAT-registered
		- notes                            -- text nullable -- remarks by the clerk who registered it
		- invoice_type_lookup_value_id     -- FK LookupValue (SUPPLIER_INVOICE_TYPE)
		- channel_lookup_value_id          -- FK LookupValue (SUBMISSION_CHANNEL) -- staff entry or portal
		- purchase_order_id                -- FK PurchaseOrder nullable -- PO billed; NULL = non-PO invoice (exception)
		- procurement_contract_id          -- FK ProcurementContract nullable  [FOLLOW-UP MIGRATION] -- contract billed
		- duplicate_of_id                  -- FK self nullable -- suspected duplicate: same amount and date
		- submitted_by_supplier_user_id    -- FK SupplierUser nullable -- portal sender; NULL = keyed in by staff
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- the supplier who issued the invoice
		- currency_id                      -- XFK Currency -- currency the invoice is in
		- payment_term_id                  -- XFK PaymentTerm nullable -- payment term that sets due_date
		- withhold_rule_id                 -- XFK WithholdRule nullable -- withholding rule applied to the invoice
		- document_id                      -- XFK Document -- the scanned invoice and its approvals
		- registered_by                    -- XFK User -- staff member who registered the invoice
		- supplier_invoice_status_lookup_value_id -- FK LookupValue (SUPPLIER_INVOICE_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, reference_number), UNIQUE (supplier_id, entity_id, supplier_invoice_number)
		-- INDEX (entity_id, supplier_invoice_status_lookup_value_id, received_at), (purchase_order_id), (due_date)
		> examples:
			| id   | invoice_no | date       | po  | type        | grand_total | withholding | status      |
			| ---- | ---------- | ---------- | --- | ----------- | ----------- | ----------- | ----------- |
			| 7781 | INV-7781   | 2026-08-04 | 455 | standard    | 37513       | 0           | handed_over |
			| 7782 | CN-0342    | 2026-08-09 | 455 | credit_note | 577         | 0           | handed_over |
			| 7790 | INV-7790   | 2026-08-13 | 520 | standard    | 22050       | 441         | handed_over |
			| 7801 | INV-2231   | 2026-09-02 | 560 | standard    | 98900       | 1720        | handed_over |

	### SupplierInvoiceReferenceLine [LINE] -- one invoiced line as the supplier printed it
		- id
		- uuid
		- line_number                      -- int -- line order as printed
		- description                      -- text -- item text as printed
		- invoiced_quantity                -- numeric(18,4) -- quantity billed on this line
		- unit_price                       -- numeric(18,4) -- price per unit as billed
		- discount_amount                  -- numeric(18,4) default 0 -- line discount as printed
		- tax_amount                       -- numeric(18,4) default 0 -- tax charged on this line
		- line_total                       -- numeric(18,4) -- line amount as printed
		- matched_quantity                 -- numeric(18,4) default 0 -- quantity already cleared by matching
		- supplier_invoice_reference_id    -- FK SupplierInvoiceReference
		- purchase_order_line_id           -- FK PurchaseOrderLine nullable -- PO line it bills; NULL = not on the PO
		- product_id                       -- XFK Product nullable -- our product, when it can be identified
		- measurement_id                   -- XFK Measurement nullable -- unit the quantity is billed in
		- tax_rate_id                      -- XFK TaxRate nullable -- tax rate applied to the line
		- user_id
		- state
		-- INDEX (supplier_invoice_reference_id, line_number), (purchase_order_line_id)
		> examples:
			| id | invoice | line | po_line | quantity | unit_price | line_total | matched |
			| -- | ------- | ---- | ------- | -------- | ---------- | ---------- | ------- |
			| 1  | 7781    | 1    | 1       | 1154     | 32.50      | 37513      | 1104    |
			| 2  | 7790    | 1    | 2       | 490      | 45.00      | 22050      | 490     |
			| 3  | 7782    | 1    | 1       | 1154     | 0.50       | 577        | 0       |

	### InvoiceMatch [DIST] -- one comparison run and its verdict, not a posting; the tolerance rule is linked
		- id
		- uuid
		- match_number                     -- from DocumentSequence
		- matched_at                       -- timestamp -- when the comparison ran
		- is_automatic                     -- bool -- true = passed within tolerance with no person
		- po_amount                        -- numeric(18,4) -- PO value of the invoiced lines
		- received_amount                  -- numeric(18,4) -- accepted quantity × PO price
		- invoiced_amount                  -- numeric(18,4) -- amount the invoice claims for those lines
		- price_variance_amount            -- numeric(18,4) default 0 -- (invoice price − PO price) × quantity
		- quantity_variance_amount         -- numeric(18,4) default 0 -- (invoiced − accepted quantity) × price
		- total_variance_amount            -- numeric(18,4) default 0 -- tested against the rule's total cap
		- notes                            -- text nullable -- reviewer remarks on the result
		- match_type_lookup_value_id       -- FK LookupValue (MATCH_TYPE)
		- result_lookup_value_id           -- FK LookupValue (MATCH_RESULT)
		- supplier_invoice_reference_id    -- FK SupplierInvoiceReference -- the invoice being matched
		- matching_tolerance_rule_id       -- FK MatchingToleranceRule nullable -- tolerance rule applied
		- tenant_id
		- entity_id
		- document_id                      -- XFK Document nullable -- approval workflow for accepting variances
		- matched_by                       -- XFK User nullable -- person who ran it; NULL = automatic
		- match_status_lookup_value_id     -- FK LookupValue (MATCH_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, match_number) | INDEX (supplier_invoice_reference_id), (entity_id, result_lookup_value_id)
		> examples:
			| id | number     | invoice | auto  | po_amount | received | invoiced | total_var | result    | status    |
			| -- | ---------- | ------- | ----- | --------- | -------- | -------- | --------- | --------- | --------- |
			| 1  | MT-2026-88 | 7781    | false | 36928     | 35328    | 37513    | 2185      | exception | approved  |
			| 2  | MT-2026-95 | 7790    | true  | 22050     | 22050    | 22050    | 0         | matched   | completed |
			| 3  | MT-2026-97 | 7801    | true  | 88000     | 86000    | 86000    | 0         | matched   | completed |

	### InvoiceMatchLine [LINE] -- quantities and prices compared, frozen at match time; variances follow
		- id
		- uuid
		- ordered_quantity                 -- numeric(18,4) -- PO line quantity at match time
		- received_quantity                -- numeric(18,4) -- quantity received on the linked receipts
		- accepted_quantity                -- numeric(18,4) -- quantity accepted after inspection; the basis
		- invoiced_quantity                -- numeric(18,4) -- quantity billed on this invoice line
		- previously_invoiced_quantity     -- numeric(18,4) default 0 -- already billed on earlier invoices
		- po_unit_price                    -- numeric(18,4) -- unit price on the PO line
		- invoice_unit_price               -- numeric(18,4) -- unit price on the invoice line
		- result_lookup_value_id           -- FK LookupValue (MATCH_LINE_RESULT)
		- invoice_match_id                 -- FK InvoiceMatch
		- supplier_invoice_reference_line_id -- FK SupplierInvoiceReferenceLine -- the invoice line compared
		- purchase_order_line_id           -- FK PurchaseOrderLine nullable -- PO line it is compared with
		- goods_receipt_line_id            -- FK GoodsReceiptLine nullable -- receipt line giving the accepted quantity
		- service_acceptance_line_id       -- FK ServiceAcceptanceLine nullable -- acceptance line, for services
		- user_id
		- state
		-- INDEX (invoice_match_id), (purchase_order_line_id), (goods_receipt_line_id)
		> examples:
			| id | match | ordered | accepted | invoiced | prev_invoiced | po_price | inv_price | result         |
			| -- | ----- | ------- | -------- | -------- | ------------- | -------- | --------- | -------------- |
			| 1  | 1     | 60000   | 11350    | 1154     | 10246         | 32.00    | 32.50     | both_exception |
			| 2  | 2     | 500     | 490      | 490      | 0             | 45.00    | 45.00     | matched        |
			| 3  | 3     | 12      | 2        | 1        | 1             | 88000.00 | 86000.00  | matched        |

	### MatchException [LINE] -- one problem a match found; a blocking one stops the handover
		- id
		- uuid
		- variance_amount                  -- numeric(18,4) nullable -- money difference found; NULL = not a variance
		- variance_percent                 -- numeric(18,6) nullable -- difference as a percent of the PO value
		- description                      -- jsonb -- what the engine found, or the user's justification
		- resolution_note                  -- jsonb nullable -- how it was settled and why
		- raised_at                        -- timestamp -- when the exception was raised
		- resolved_at                      -- timestamp nullable -- when it was settled
		- exception_type_lookup_value_id   -- FK LookupValue (MATCH_EXCEPTION_TYPE)
		- severity_lookup_value_id         -- FK LookupValue (MATCH_EXCEPTION_SEVERITY)
		- resolution_lookup_value_id       -- FK LookupValue (MATCH_EXCEPTION_RESOLUTION) nullable
		- invoice_match_id                 -- FK InvoiceMatch
		- invoice_match_line_id            -- FK InvoiceMatchLine nullable -- NULL = a header-level exception
		- purchase_order_amendment_id      -- FK PurchaseOrderAmendment nullable -- amendment that resolved it
		- resolved_by                      -- XFK User nullable -- person who settled it
		- match_exception_status_lookup_value_id -- FK LookupValue (MATCH_EXCEPTION_STATUS)
		- user_id
		- state
		-- INDEX (invoice_match_id, match_exception_status_lookup_value_id),
		--       (match_exception_status_lookup_value_id, raised_at)
		> examples:
			| id | match | line | type              | severity | variance | resolution          | status   |
			| -- | ----- | ---- | ----------------- | -------- | -------- | ------------------- | -------- |
			| 1  | 1     | 1    | price_variance    | blocking | 577      | request_credit_note | resolved |
			| 2  | 1     | --   | tax_mismatch      | info     | 8        | accept_variance     | resolved |
			| 3  | 1     | --   | duplicate_invoice | warning  | --       | --                  | waived   |
			| 4  | 1     | 1    | quantity_variance | blocking | 1600     | request_credit_note | resolved |

	### ApHandover [DIST] -- procurement says "payable"; Accounting posts and writes back ap_invoice_id
						-- It records the moment Procurement says: “We have checked the invoice and its supporting evidence.
						-- It is ready for Accounting to process as payable.”
		- id
		- uuid
		- handover_number                  -- from DocumentSequence
		- handed_over_at                   -- timestamp -- when procurement released it to Accounting
		- payable_amount                   -- numeric(18,4) -- amount approved for payment, before withholding
		- withholding_amount               -- numeric(18,4) default 0 -- withholding tax Accounting must deduct
		- retention_amount                 -- numeric(18,4) default 0 -- amount held back under the contract's retention
		- due_date                         -- date nullable -- when payment falls due
		- is_evidence_complete             -- bool -- true = PO, receipt, inspection and match all on file
		- posted_at                        -- timestamp nullable -- when Accounting posted it (read back)
		- paid_at                          -- timestamp nullable -- when Accounting paid it (read back)
		- rejection_reason                 -- jsonb nullable -- why Accounting sent it back
		- notes                            -- jsonb nullable -- remarks for the AP clerk
		- supplier_invoice_reference_id    -- FK SupplierInvoiceReference -- the invoice handed over
		- invoice_match_id                 -- FK InvoiceMatch -- the match that cleared it
		- tenant_id
		- entity_id
		- ap_invoice_id                    -- XFK Accounting ApInvoice nullable -- Accounting's payable; NULL = none
		- ap_invoice_match_id              -- XFK Accounting ApInvoiceMatch nullable -- Accounting's own match record
		- payment_request_id               -- XFK Accounting PaymentRequest nullable -- payment request raised for it
		- withholding_tax_transaction_id   -- XFK Accounting WithholdingTaxTransaction nullable -- the WHT receipt row
		- supplier_payment_id              -- XFK Accounting SupplierPayment nullable -- the payment, read back
		- document_id                      -- XFK Document -- handover pack with its evidence files
		- handed_over_by                   -- XFK User -- person who handed it over
		- ap_handover_status_lookup_value_id -- FK LookupValue (AP_HANDOVER_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, handover_number), UNIQUE (supplier_invoice_reference_id)
		-- INDEX (entity_id, ap_handover_status_lookup_value_id, handed_over_at), (ap_invoice_id), (due_date)
		-- the read-back columns are written by a sync from Accounting, never by a procurement action
		> examples:
			| id | number      | invoice | match | payable | wht  | ap_invoice | posted_at  | paid_at    | status |
			| -- | ----------- | ------- | ----- | ------- | ---- | ---------- | ---------- | ---------- | ------ |
			| 1  | APH-2026-71 | 7790    | 2     | 22050   | 441  | 91204      | 2026-08-14 | 2026-09-12 | paid   |
			| 2  | APH-2026-72 | 7781    | 1     | 35336   | 0    | 91217      | 2026-08-15 | --         | posted |
			| 3  | APH-2026-80 | 7801    | 3     | 98900   | 1720 | 91260      | 2026-09-04 | --         | posted |


#9. Contract, guarantee, return and claim                    [PRMS01-09 / -10]

	-- Service, capital-asset and project procurement add no tables: they ride the category
	-- class, the line columns (asset category, custodian, project dimension, service
	-- period, milestone) and ServiceAcceptance. A received capital asset becomes a core
	-- Asset; its AssetDetail should point at the receipt line.
	-- A contract's terms are its clauses: penalty, dispute resolution, governing law and
	-- scope are ProcurementContractClause rows, not columns.

	### ProcurementClause [DIST][INH] -- the clause library contracts are drafted from; a used version is never edited
		- id
		- uuid
		- code                             -- unique per entity and version
		- title                            -- jsonb
		- body                             -- jsonb -- {placeholders} filled from the contract when drafting
		- is_mandatory                     -- bool -- true = always inserted and cannot be removed
		- version_number                   -- smallint default 1 -- a changed text is a new version
		- effective_from                   -- date -- first day this version may be used
		- effective_to                     -- date nullable -- last day; NULL = still current
		- display_order                    -- smallint -- position in a drafted contract
		- clause_type_lookup_value_id      -- FK LookupValue (CLAUSE_TYPE) -- e.g. payment, penalty, warranty
		- contract_type_lookup_value_id    -- FK LookupValue (CONTRACT_TYPE) nullable -- NULL = every type
		- procurement_category_id          -- FK ProcurementCategory nullable -- NULL = every category
		- tenant_id
		- entity_id
		- user_id
		- state
		-- UNIQUE (entity_id, code, version_number) | INDEX (entity_id, clause_type_lookup_value_id, effective_from)
		> examples:
			| id | code        | type               | title (en)                      | mandatory | contract | version |
			| -- | ----------- | ------------------ | ------------------------------- | --------- | -------- | ------- |
			| 1  | LD-DELAY    | penalty            | Liquidated damages for delay    | true      | supply   | 1       |
			| 2  | FM-STD      | force_majeure      | Force majeure                   | true      | --       | 1       |
			| 3  | DISPUTE-ARB | dispute_resolution | Arbitration under Ethiopian law | true      | --       | 2       |

	### ProcurementContract [DIST] -- the signed agreement; its end and defect dates drive renewal and release
		- id
		- uuid
		- contract_number                  -- from DocumentSequence
		- title                            -- jsonb
		- signed_at                        -- date nullable -- date of the last required signature
		- effective_from                   -- date -- first day the contract binds
		- effective_to                     -- date -- last day; drives the renewal reminder
		- contract_value                   -- numeric(18,4) -- value as signed; amendments hold later values
		- advance_percent                  -- numeric(18,6) nullable -- advance as a percent of the value
		- advance_amount                   -- numeric(18,4) default 0 -- advance paid before delivery
		- retention_percent                -- numeric(18,6) nullable -- share of each payment held back until release
		- defect_liability_days            -- smallint nullable -- days the supplier must fix defects after acceptance
		- defect_liability_ends_at         -- date nullable -- end of defect liability; set on final acceptance
		- auto_renew                       -- bool default false -- true = renews itself unless notice is given
		- renewal_notice_days              -- smallint nullable -- days before the end to warn the owner
		- renewal_notified_at              -- date nullable -- when the renewal reminder was sent
		- termination_notice_days          -- smallint nullable -- notice days a party must give to terminate
		- terminated_at                    -- date nullable -- date the contract was terminated
		- termination_reason               -- text nullable -- free-text detail of the termination
		- closed_at                        -- timestamp nullable -- when it was closed after final settlement
		- contract_type_lookup_value_id    -- FK LookupValue (CONTRACT_TYPE)
		- termination_reason_lookup_value_id -- FK LookupValue (CONTRACT_TERMINATION_REASON) nullable -- why it ended
		- procurement_unit_id              -- FK ProcurementUnit -- unit that manages the contract
		- procurement_category_id          -- FK ProcurementCategory -- what is bought under it
		- award_recommendation_id          -- FK AwardRecommendation nullable -- award it came from; NULL = direct
		- parent_contract_id               -- FK self nullable -- the contract this one renews
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- the contracted supplier
		- supplier_contact_party_id        -- XFK Party nullable -- the supplier's contact person
		- currency_id                      -- XFK Currency -- currency of the contract value
		- payment_term_id                  -- XFK PaymentTerm nullable -- agreed payment term
		- contract_owner_employee_id       -- XFK Employee -- the business owner, not the buyer
		- document_id                      -- XFK Document -- approval and buyer-side signatures ride it
		- contract_status_lookup_value_id  -- FK LookupValue (CONTRACT_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, contract_number)
		-- INDEX (entity_id, contract_status_lookup_value_id, effective_to), (supplier_id), (defect_liability_ends_at)
		-- current value = the latest signed amendment's value_after;
		-- consumed and retained amounts are summed from the lines and acceptances
		> examples:
			| id  | number      | type        | supplier | from       | to         | value     | renew | status     |
			| --- | ----------- | ----------- | -------- | ---------- | ---------- | --------- | ----- | ---------- |
			| 900 | CT-2026-012 | supply      | 503      | 2026-08-26 | 2027-08-25 | 14200 EUR | false | active     |
			| 901 | CT-2026-013 | maintenance | 530      | 2026-07-01 | 2027-06-30 | 1056000   | true  | active     |
			| 902 | CT-2026-005 | service     | 535      | 2026-03-01 | 2027-02-28 | 420000    | false | terminated |

	### ProcurementContractLine [LINE] -- what the contract buys, at what price and lead time
		- id
		- uuid
		- line_number                      -- int -- line order in the contract
		- description                      -- jsonb
		- contracted_quantity              -- numeric(18,4) nullable -- agreed quantity; NULL = rate only, no cap
		- unit_price                       -- numeric(18,4) nullable -- agreed price per unit, before tax
		- line_value                       -- numeric(18,4) -- agreed value of the line
		- consumed_quantity                -- numeric(18,4) default 0 -- quantity ordered so far against the line
		- consumed_value                   -- numeric(18,4) default 0 -- value ordered or accepted so far
		- lead_time_days                   -- smallint nullable -- agreed days from order to delivery
		- procurement_contract_id          -- FK ProcurementContract
		- procurement_category_id          -- FK ProcurementCategory nullable -- if it differs from the contract's
		- product_id                       -- XFK Product nullable -- contracted product; NULL = described in text
		- measurement_id                   -- XFK Measurement nullable -- unit the quantity and price are in
		- tax_rate_id                      -- XFK TaxRate nullable -- the tax the agreed price excludes
		- user_id
		- state
		-- INDEX (procurement_contract_id, line_number)
		> examples:
			| id | contract | line | description              | quantity | unit_price | line_value | consumed | lead |
			| -- | -------- | ---- | ------------------------ | -------- | ---------- | ---------- | -------- | ---- |
			| 1  | 900      | 1    | Hood dishwasher + inst.  | 3        | 4733.33    | 14200 EUR  | 0        | 55   |
			| 2  | 901      | 1    | Monthly kitchen cleaning | 12       | 88000      | 1056000    | 176000   | --   |
			| 3  | 902      | 1    | Laundry, monthly         | 12       | 35000      | 420000     | 210000   | --   |

	### ContractMilestone [LINE] -- accepting a payment-trigger milestone is what permits an invoice
		- id
		- uuid
		- milestone_number                 -- smallint -- order of the milestone in the contract
		- name                             -- jsonb
		- description                      -- jsonb nullable
		- deliverable                      -- jsonb -- what must be handed over to reach it
		- planned_date                     -- date -- date agreed in the contract
		- revised_date                     -- date nullable -- new date agreed after a delay
		- actual_date                      -- date nullable -- date it was actually reached
		- milestone_value                  -- numeric(18,4) -- contract value tied to the milestone
		- accepted_value                   -- numeric(18,4) default 0 -- value accepted so far
		- invoiced_value                   -- numeric(18,4) default 0 -- value the supplier has invoiced
		- penalty_applied                  -- numeric(18,4) default 0 -- delay penalty deducted for this milestone
		- is_payment_trigger               -- bool -- true = its acceptance allows an invoice
		- procurement_contract_id          -- FK ProcurementContract
		- procurement_contract_line_id     -- FK ProcurementContractLine nullable -- contract line it delivers, if one
		- contract_milestone_status_lookup_value_id -- FK LookupValue (CONTRACT_MILESTONE_STATUS)
		- user_id
		- state
		-- UNIQUE (procurement_contract_id, milestone_number)
		-- INDEX (contract_milestone_status_lookup_value_id, planned_date)
		> examples:
			| id | contract | no | deliverable            | planned    | value    | payment_trigger | status  |
			| -- | -------- | -- | ---------------------- | ---------- | -------- | --------------- | ------- |
			| 1  | 900      | 1  | Delivery to site       | 2026-10-20 | 9940 EUR | true            | pending |
			| 2  | 900      | 2  | Installation + testing | 2026-11-10 | 3550 EUR | true            | pending |
			| 3  | 900      | 3  | Final acceptance       | 2027-08-25 | 710 EUR  | true            | pending |

	### ContractAmendment [LINE] -- a signed change to value, scope, dates or terms; a renewal is a new contract
		- id
		- uuid
		- amendment_number                 -- smallint -- sequence within the contract
		- reason                           -- text -- why the change was agreed
		- before_snapshot                  -- jsonb -- contract header and lines before the change
		- value_before                     -- numeric(18,4) -- contract value before this amendment
		- value_after                      -- numeric(18,4) -- value after it; legal cap is against contract_value
		- effective_from                   -- date -- date the change takes effect
		- signed_at                        -- date nullable -- date both sides signed
		- amendment_type_lookup_value_id   -- FK LookupValue (CONTRACT_AMENDMENT_TYPE)
		- procurement_contract_id          -- FK ProcurementContract
		- document_id                      -- XFK Document -- amendment approval and signatures
		- amended_by                       -- XFK User -- person who prepared the amendment
		- contract_amendment_status_lookup_value_id -- FK LookupValue (CONTRACT_AMENDMENT_STATUS)
		- user_id
		- state
		-- UNIQUE (procurement_contract_id, amendment_number)
		> examples:
			| id | contract | no | type        | value_before | value_after | effective_from | status |
			| -- | -------- | -- | ----------- | ------------ | ----------- | -------------- | ------ |
			| 1  | 901      | 1  | duration    | 1056000      | 1144000     | 2027-07-01     | signed |
			| 2  | 900      | 1  | milestone   | 14200 EUR    | 14200 EUR   | 2026-10-15     | signed |
			| 3  | 902      | 1  | termination | 420000       | 210000      | 2026-09-01     | signed |

	### ProcurementContractClause [LINE] -- the clauses as agreed: library text copied in, then negotiated
		- id
		- uuid
		- clause_number                    -- varchar -- as printed, e.g. 7.2
		- title                            -- jsonb
		- body                             -- jsonb -- agreed text, frozen once signed
		- is_modified                      -- bool -- true = text differs from the library
		- display_order                    -- smallint -- position in the printed contract
		- procurement_contract_id          -- FK ProcurementContract
		- procurement_clause_id            -- FK ProcurementClause nullable -- NULL = a special condition
		- contract_amendment_id            -- FK ContractAmendment nullable -- amendment that added or replaced it
		- user_id
		- state
		-- INDEX (procurement_contract_id, display_order)
		> examples:
			| id | contract | no  | clause   | title (en)                   | modified |
			| -- | -------- | --- | -------- | ---------------------------- | -------- |
			| 1  | 900      | 7.1 | LD-DELAY | Liquidated damages for delay | true     |
			| 2  | 900      | 9.1 | FM-STD   | Force majeure                | false    |
			| 3  | 900      | 12  | --       | Operator training on site    | false    |

	### ProcurementContractSignatory [LINE] -- supplier and witness signatures; ours are core document signatures
		- id
		- uuid
		- signing_order                    -- smallint -- order in which signatures are collected
		- signer_name                      -- jsonb -- name of the person signing
		- signer_title                     -- jsonb nullable -- position of the person signing
		- is_required                      -- bool -- true = contract is not signed without it
		- signed_at                        -- timestamp nullable -- when this signature was given
		- signature_reference              -- varchar nullable -- certificate serial, OTP or portal acceptance id
		- side_lookup_value_id             -- FK LookupValue (SIGNATORY_SIDE) -- who signs: supplier or witness
		- signature_method_lookup_value_id -- FK LookupValue (SIGNATURE_METHOD) nullable -- how it was signed
		- procurement_contract_id          -- FK ProcurementContract
		- contract_amendment_id            -- FK ContractAmendment nullable -- NULL = the contract itself
		- supplier_user_id                 -- FK SupplierUser nullable -- portal user who signed
		- document_attachment_id           -- XFK DocumentAttachment nullable -- scan of the signed copy
		- user_id
		- state
		-- INDEX (procurement_contract_id, signing_order), (contract_amendment_id)
		> examples:
			| id | contract | side     | order | signer_name   | method            | signed_at        |
			| -- | -------- | -------- | ----- | ------------- | ----------------- | ---------------- |
			| 1  | 900      | supplier | 1     | Klaus Berger  | portal_acceptance | 2026-08-25 16:40 |
			| 2  | 900      | witness  | 2     | Hanna Tesfaye | wet_ink           | 2026-08-26 10:15 |
			| 3  | 901      | supplier | 1     | Dawit Alemu   | wet_ink           | 2026-06-28 11:00 |

	### SupplierGuarantee [DIST] -- procurement owns the obligation; Accounting BankGuarantee owns the instrument
		- id
		- uuid
		- guarantee_number                 -- from DocumentSequence
		- bank_reference                   -- varchar -- the issuing bank's reference
		- issuer_name                      -- varchar nullable -- bank or insurer that issued it
		- guarantee_amount                 -- numeric(18,4) -- amount the issuer guarantees
		- guarantee_percent                -- numeric(18,6) nullable -- amount as a percent of the secured value
		- issued_at                        -- date -- issue date on the instrument
		- valid_from                       -- date -- start of validity
		- valid_to                         -- date -- end of validity; drives the expiry alert
		- claim_deadline                   -- date nullable -- last day a claim can reach the issuer
		- extension_count                  -- smallint default 0 -- times the validity was extended
		- released_amount                  -- numeric(18,4) default 0 -- amount released back to the supplier
		- release_condition                -- jsonb -- what must happen before release
		- released_at                      -- timestamp nullable -- when it was released
		- release_reason                   -- jsonb nullable -- why it was released
		- forfeited_amount                 -- numeric(18,4) default 0 -- amount claimed from the issuer
		- forfeited_at                     -- timestamp nullable -- when it was forfeited
		- forfeiture_reason                -- jsonb nullable -- why it was forfeited
		- warranty_start_at                -- date nullable -- start of the warranty it covers
		- warranty_end_at                  -- date nullable -- end of the warranty it covers
		- guarantee_type_lookup_value_id   -- FK LookupValue (GUARANTEE_TYPE)
		- procurement_contract_id          -- FK ProcurementContract nullable -- contract it secures
		- purchase_order_id                -- FK PurchaseOrder nullable -- PO it secures
		- framework_agreement_id           -- FK FrameworkAgreement nullable -- framework agreement it secures
		- bid_submission_id                -- FK BidSubmission nullable -- the bid it secures (bid bond)
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- supplier who provided it
		- currency_id                      -- XFK Currency -- currency of the amount
		- bank_guarantee_id                -- XFK Accounting BankGuarantee nullable -- Accounting's instrument row
		- document_id                      -- XFK Document -- scanned guarantee and its approvals
		- released_by                      -- XFK User nullable -- person who released it
		- guarantee_status_lookup_value_id -- FK LookupValue (GUARANTEE_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, guarantee_number)
		-- INDEX (entity_id, guarantee_status_lookup_value_id, valid_to), (supplier_id), (procurement_contract_id)
		-- CHECK (app-level): not released while the securing contract is active and release_condition is unmet
		> examples:
			| id | type                      | bank_reference | amount   | valid_to   | contract | bid | status   |
			| -- | ------------------------- | -------------- | -------- | ---------- | -------- | --- | -------- |
			| 1  | bid_bond                  | CBE/BG/99120   | 18000    | 2026-11-18 | --       | 1   | released |
			| 2  | performance_bond          | CBE/BG/99340   | 1420 EUR | 2027-09-25 | 900      | --  | active   |
			| 3  | advance_payment_guarantee | AIB/AP/5521    | 4260 EUR | 2026-12-31 | 900      | --  | active   |

	### SupplierClaim [DIST] -- claimed vs agreed vs recovered; the gap is a performance signal
							-- A supplier claim is a formal demand raised against a supplier because the supplier failed to meet an obligation.
		- id
		- uuid
		- claim_number                     -- from DocumentSequence
		- recovered_amount                 -- numeric(18,4) default 0 -- amount actually recovered so far
		- raised_at                        -- timestamp -- when the claim was raised
		- response_due_at                  -- date nullable -- date the supplier must answer by
		- supplier_responded_at            -- timestamp nullable -- when the supplier answered
		- supplier_response                -- jsonb nullable -- the supplier's answer
		- resolved_at                      -- timestamp nullable -- when the claim was settled
		- dispute_note                     -- jsonb nullable -- why the claim is disputed
		- escalation_level                 -- smallint default 0 -- 0 buyer, 1 manager, 2 legal, 3 arbitration
		- description                      -- jsonb
		- resolution_note                  -- jsonb nullable -- how it was settled
		- claim_type_lookup_value_id       -- FK LookupValue (SUPPLIER_CLAIM_TYPE)
		- recovery_method_lookup_value_id  -- FK LookupValue (CLAIM_RECOVERY_METHOD) nullable
		- purchase_order_id                -- FK PurchaseOrder nullable -- PO the claim is about
		- goods_receipt_id                 -- FK GoodsReceipt nullable -- receipt where the problem was found
		- goods_inspection_id              -- FK GoodsInspection nullable -- inspection that found it
		- procurement_contract_id          -- FK ProcurementContract nullable -- contract whose terms were breached
		- supplier_guarantee_id            -- FK SupplierGuarantee nullable -- guarantee claimed against, if any
		- supplier_return_id               -- FK SupplierReturn nullable -- return that sent the goods back
		- supplier_invoice_reference_id    -- FK SupplierInvoiceReference nullable -- invoice disputed, if any
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- supplier claimed against
		- currency_id                      -- XFK Currency -- currency of the amounts
		- supplier_debit_note_id           -- XFK Accounting SupplierDebitNote nullable -- debit note Accounting raised
		- document_id                      -- XFK Document -- claim letter and evidence
		- raised_by                        -- XFK User -- person who raised the claim
		- supplier_claim_status_lookup_value_id -- FK LookupValue (SUPPLIER_CLAIM_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, claim_number)
		-- INDEX (entity_id, supplier_claim_status_lookup_value_id, raised_at), (supplier_id), (response_due_at)
		-- claimed and agreed amounts are summed from the lines
		> examples:
			| id | number      | type            | supplier | recovered | recovery_method   | escalation | status    |
			| -- | ----------- | --------------- | -------- | --------- | ----------------- | ---------- | --------- |
			| 1  | CLM-2026-18 | quality         | 501      | 1600      | credit_note       | 0          | recovered |
			| 2  | CLM-2026-22 | late_delivery   | 501      | 8000      | payment_deduction | 1          | recovered |
			| 3  | CLM-2026-25 | service_failure | 530      | 0         | --                | 0          | raised    |

	### SupplierClaimLine [LINE] -- one claimed item or charge
		- id
		- uuid
		- line_number                      -- int -- line order in the claim
		- description                      -- jsonb
		- claimed_quantity                 -- numeric(18,4) nullable -- quantity claimed; NULL = money-only claim
		- claimed_amount                   -- numeric(18,4) -- amount we claim
		- agreed_quantity                  -- numeric(18,4) nullable -- quantity the supplier accepted
		- agreed_amount                    -- numeric(18,4) default 0 -- amount the supplier accepted
		- supplier_claim_id                -- FK SupplierClaim
		- purchase_order_line_id           -- FK PurchaseOrderLine nullable -- PO line affected
		- goods_receipt_line_id            -- FK GoodsReceiptLine nullable -- receipt line affected
		- product_id                       -- XFK Product nullable -- product affected
		- measurement_id                   -- XFK Measurement nullable -- unit of the claimed quantity
		- user_id
		- state
		-- INDEX (supplier_claim_id, line_number)
		> examples:
			| id | claim | line | description               | claimed_qty | claimed | agreed |
			| -- | ----- | ---- | ------------------------- | ----------- | ------- | ------ |
			| 1  | 1     | 1    | Stale loaves, GRN-9912    | 50          | 1600    | 1600   |
			| 2  | 2     | 1    | 2 late instalments, LDs   | --          | 24000   | 8000   |
			| 3  | 3     | 1    | Third-party hood re-clean | --          | 14000   | 0      |



#10. Import procurement and landed cost                            [PRMS01-11]

	-- Accounting owns landed cost and its ALLOCATION onto stock value. Procurement owns
	-- the SHIPMENT: which POs travel together, which documents customs needs, what each
	-- charge was, and the Ethiopian instruments an import runs on (LC, TT, bank permit,
	-- franco valuta). The handover is landed_cost_id. Document numbers (permit, bill of
	-- lading, airway bill, customs declaration) live once, on ImportDocument.

	### ImportShipment [DIST] -- one shipment, often several POs; exchange_rate is the customs valuation rate
		- id
		- uuid
		- shipment_number                  -- from DocumentSequence
		- letter_of_credit_number          -- varchar nullable -- the bank's LC number; NULL when not paid by LC
		- letter_of_credit_date            -- date nullable -- when the bank opened the LC
		- letter_of_credit_expiry          -- date nullable -- current LC expiry; earlier ones are in ImportLcAmendment
		- letter_of_credit_amount          -- numeric(18,4) nullable -- LC face value, in the shipment currency
		- latest_shipment_date             -- date nullable -- last day the LC allows the goods to ship
		- insurance_policy_number          -- varchar nullable -- marine or air cargo policy number
		- insured_value                    -- numeric(18,4) nullable -- cover amount, in the shipment currency
		- container_numbers                -- jsonb nullable -- list of container numbers, e.g. ["MSCU1234567"]
		- vessel_or_flight                 -- varchar nullable -- vessel name or flight number carrying the goods
		- port_of_loading                  -- jsonb nullable -- port the goods were loaded at, e.g. Hamburg
		- port_of_discharge                -- jsonb nullable -- port the goods are unloaded at, e.g. Djibouti
		- final_destination                -- varchar nullable -- inland delivery point, e.g. Modjo dry port
		- shipped_at                       -- date nullable -- date on the bill of lading or airway bill
		- estimated_arrival_at             -- date nullable -- expected arrival at the port of discharge
		- actual_arrival_at                -- date nullable -- when the goods actually arrived
		- customs_cleared_at               -- date nullable -- when customs released the goods
		- gross_weight                     -- numeric(18,4) nullable -- weight with packing, in kg
		- net_weight                       -- numeric(18,4) nullable -- weight of the goods alone, in kg
		- volume_cbm                       -- numeric(18,4) nullable -- shipped volume in cubic metres
		- goods_value_fob                  -- numeric(18,4) -- FOB value of the goods, in the shipment currency
		- exchange_rate                    -- numeric(18,6) nullable -- birr per unit, frozen at customs declaration
		- demurrage_days                   -- smallint default 0 -- days charged for containers kept past free time
		- notes                            -- text nullable -- free remarks for the import officer
		- shipment_mode_lookup_value_id    -- FK LookupValue (SHIPMENT_MODE)
		- payment_mode_lookup_value_id     -- FK LookupValue (IMPORT_PAYMENT_MODE)
		- incoterm_lookup_value_id         -- FK LookupValue (INCOTERM)
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- the foreign supplier shipping the goods
		- clearing_agent_supplier_id       -- XFK Supplier nullable -- customs clearing agent; it has its own service PO
		- commission_agent_supplier_id     -- XFK Supplier nullable -- the foreign supplier's local commission agent
		- insurer_supplier_id              -- XFK Supplier nullable -- insurance company that issued the policy
		- inland_transporter_supplier_id   -- XFK Supplier nullable -- trucker moving the goods from port to store
		- currency_id                      -- XFK Currency -- currency of the LC, FOB value and insurance
		- lc_bank_account_id               -- XFK Accounting BankAccount nullable -- account the LC or TT is paid from
		- location_id                      -- XFK Location nullable -- store the goods finally go to
		- landed_cost_id                   -- XFK Accounting LandedCost nullable -- landed cost handed to Accounting
		- document_id                      -- XFK Document -- the shipment file: number, approvals, attachments
		- import_shipment_status_lookup_value_id -- FK LookupValue (IMPORT_SHIPMENT_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, shipment_number)
		-- INDEX (entity_id, import_shipment_status_lookup_value_id, estimated_arrival_at), (supplier_id),
		--       (letter_of_credit_expiry)
		-- charge totals and landed value are summed from ImportCharge
		> examples:
			| id | number       | mode | payment_mode     | lc_number | eta        | fob_value | rate    | status     |
			| -- | ------------ | ---- | ---------------- | --------- | ---------- | --------- | ------- | ---------- |
			| 31 | IMP-2026-031 | sea  | letter_of_credit | 4410/26   | 2026-10-12 | 14200     | 71.4200 | in_transit |
			| 32 | IMP-2026-032 | air  | tt_advance       | --        | 2026-11-20 | 1250      | 72.1500 | shipped    |
			| 33 | IMP-2026-033 | sea  | letter_of_credit | 4472/26   | 2026-12-05 | 2400      | --      | planned    |

	### ImportLcAmendment [LINE] -- each change the bank makes to the LC(Letter of Credit); the shipment keeps current values
		- id
		- uuid
		- amendment_number                 -- smallint -- 1, 2, 3 … per shipment
		- requested_at                     -- date -- when the bank was asked to amend
		- bank_reference                   -- varchar nullable -- the bank's amendment reference
		- previous_expiry                  -- date nullable -- LC expiry before this change
		- new_expiry                       -- date nullable -- LC expiry after it; NULL = unchanged
		- previous_latest_shipment_date    -- date nullable -- last shipment date before this change
		- new_latest_shipment_date         -- date nullable -- last shipment date after it; NULL = unchanged
		- new_expected_arrival_at          -- date nullable -- arrival date this change implies
		- previous_amount                  -- numeric(18,4) nullable -- LC amount before this change
		- new_amount                       -- numeric(18,4) nullable -- LC amount after it; NULL = unchanged
		- bank_charge                      -- numeric(18,4) default 0 -- bank fee, also booked as an ImportCharge
		- reason                           -- jsonb -- why the LC is being changed
		- supplier_accepted_at             -- timestamp nullable -- when the supplier, as beneficiary, accepted it
		- amendment_type_lookup_value_id   -- FK LookupValue (LC_AMENDMENT_TYPE) -- which LC term changes
		- import_shipment_id               -- FK ImportShipment
		- document_attachment_id           -- XFK DocumentAttachment nullable -- the bank's amendment advice
		- lc_amendment_status_lookup_value_id -- FK LookupValue (LC_AMENDMENT_STATUS) -- approved_by_bank applies it
		- user_id
		- state
		-- UNIQUE (import_shipment_id, amendment_number)
		-- on approved_by_bank the new values are copied to the shipment
		> examples:
			| id | shipment | no | type             | from       | to         | charge | status           |
			| -- | -------- | -- | ---------------- | ---------- | ---------- | ------ | ---------------- |
			| 1  | 31       | 1  | shipment_date    | 2026-09-10 | 2026-09-25 | 2850   | approved_by_bank |
			| 2  | 31       | 2  | expiry_extension | 2026-10-31 | 2026-11-30 | 1900   | approved_by_bank |
			| 3  | 31       | 3  | documents        | --         | --         | 950    | requested        |

	### ImportShipmentOrder [LINE] -- which POs travel on a shipment; one PO may ship in several
		- id
		- uuid
		- import_shipment_id               -- FK ImportShipment
		- purchase_order_id                -- FK PurchaseOrder -- an order, in whole or in part, on this shipment
		- user_id
		- state
		-- UNIQUE (import_shipment_id, purchase_order_id) | INDEX (purchase_order_id)
		> examples:
			| id | shipment | po  |
			| -- | -------- | --- |
			| 1  | 31       | 501 |
			| 2  | 32       | 562 |
			| 3  | 33       | 562 |

	### ImportDocument [LINE] -- the customs checklist; a scan does not clear customs, the original does
		- id
		- uuid
		- reference_number                 -- varchar nullable -- permit, B/L, AWB or declaration number
		- issued_at                        -- date nullable -- issue date printed on the document
		- expires_at                       -- date nullable -- when it stops being valid, e.g. a bank permit
		- received_at                      -- date nullable -- when the original reached us
		- is_mandatory                     -- bool -- true = customs or the bank requires it
		- is_original_received             -- bool default false -- true = original paper in hand, not just a scan
		- verified_at                      -- timestamp nullable -- when the import officer checked it
		- remarks                          -- jsonb nullable -- what the check found
		- document_type_lookup_value_id    -- FK LookupValue (IMPORT_DOCUMENT_TYPE)
		- review_result_lookup_value_id    -- FK LookupValue (DOCUMENT_REVIEW_RESULT) -- outcome of the officer's check
		- import_shipment_id               -- FK ImportShipment
		- document_attachment_id           -- XFK DocumentAttachment nullable -- the scanned file
		- verified_by                      -- XFK User nullable -- who checked it
		- user_id
		- state
		-- UNIQUE (import_shipment_id, document_type_lookup_value_id)
		-- CHECK (app-level): the shipment cannot reach cleared while a mandatory row is not compliant or waived
		> examples:
			| id | shipment | document_type         | reference      | mandatory | original_received | review_result |
			| -- | -------- | --------------------- | -------------- | --------- | ----------------- | ------------- |
			| 1  | 31       | bank_permit           | NBE-2026-77812 | true      | true              | compliant     |
			| 2  | 31       | bill_of_lading        | MSCU-4471029   | true      | false             | pending       |
			| 3  | 31       | certificate_of_origin | EUR1-99213     | true      | false             | pending       |

	### ImportCharge [LINE] -- one cost of an import; is_recoverable decides what may NOT be capitalised
		- id
		- uuid
		- description                      -- jsonb
		- charge_amount                    -- numeric(18,4) -- amount as invoiced, in currency_id
		- charge_currency_amount           -- numeric(18,4) nullable -- in the shipment currency, when paid abroad
		- exchange_rate                    -- numeric(18,6) nullable -- birr per unit of currency_id; NULL for birr
		- base_amount                      -- numeric(18,4) -- the charge in birr; landed cost uses this
		- is_recoverable                   -- bool -- true = recoverable tax (import VAT), never capitalised
		- is_allocatable                   -- bool -- true = added to landed cost
		- incurred_at                      -- date -- date the cost arose
		- reference_number                 -- varchar nullable -- customs receipt or agent invoice number
		- charge_type_lookup_value_id      -- FK LookupValue (IMPORT_CHARGE_TYPE)
		- allocation_basis_lookup_value_id -- FK LookupValue (CHARGE_ALLOCATION_BASIS) -- how it is spread over items
		- import_shipment_id               -- FK ImportShipment
		- purchase_order_id                -- FK PurchaseOrder nullable -- set when the cost belongs to one PO only
		- supplier_invoice_reference_id    -- FK SupplierInvoiceReference nullable -- the agent's or carrier's invoice
		- supplier_id                      -- XFK Supplier nullable -- who charged it: agent, carrier, insurer or bank
		- currency_id                      -- XFK Currency -- currency the charge was invoiced in
		- tax_rate_id                      -- XFK TaxRate nullable -- rate applied, for duty and tax charges
		- landed_cost_allocation_line_id   -- XFK Accounting LandedCostAllocationLine nullable -- set by Accounting
		- document_attachment_id           -- XFK DocumentAttachment nullable -- the receipt or invoice scan
		- import_charge_status_lookup_value_id -- FK LookupValue (IMPORT_CHARGE_STATUS)
		- user_id
		- state
		-- INDEX (import_shipment_id, charge_type_lookup_value_id), (purchase_order_id),
		--       (import_charge_status_lookup_value_id)
		-- estimated -> actual: stock is valued on arrival and corrected when the agent invoices;
		-- Accounting posts the delta
		> examples:
			| id | shipment | charge_type   | base_amount | recoverable | allocatable | basis | status    |
			| -- | -------- | ------------- | ----------- | ----------- | ----------- | ----- | --------- |
			| 1  | 31       | customs_duty  | 213400      | false       | true        | value | actual    |
			| 2  | 31       | vat_on_import | 182000      | true        | false       | value | actual    |
			| 3  | 31       | port_handling | 41000       | false       | true        | value | estimated |


#11. Supplier performance                                          [PRMS01-13]

	-- A scorecard is computed from facts already stored: on-time from receipt dates
	-- against promised and instalment dates, in-full from received vs ordered, quality
	-- from inspection lines, price variance from match lines, invoice accuracy from
	-- matches without exceptions, responsiveness from RFQ and claim response times.
	-- Spend analysis needs no cube table: its dimensions sit on PurchaseOrder and its lines.

	### SupplierPerformanceCriterion [DIST][INH] -- the KPIs and weights a scorecard is computed from
		- id
		- uuid
		- code                             -- unique per entity, category and start date
		- name                             -- jsonb
		- weight_percent                   -- numeric(18,6) -- share of the overall score; weights in force total 100
		- target_value                     -- numeric(18,6) nullable -- at or past it = full marks
		- floor_value                      -- numeric(18,6) nullable -- at or before it = zero; linear in between
		- display_order                    -- smallint -- position on the scorecard
		- effective_from                   -- date -- first day this KPI and weight apply
		- effective_to                     -- date nullable -- last day; NULL = still in force
		- source_lookup_value_id           -- FK LookupValue (SUPPLIER_CRITERION_SOURCE) -- manual = scored by people
		- procurement_category_id          -- FK ProcurementCategory nullable -- NULL = the default set
		- tenant_id
		- entity_id
		- user_id
		- state
		-- UNIQUE (entity_id, procurement_category_id, code, effective_from)
		-- CHECK (app-level): weights in force for one (entity, category) total 100
		> examples:
			| id | code    | source             | weight | target | floor | category |
			| -- | ------- | ------------------ | ------ | ------ | ----- | -------- |
			| 1  | OTD     | delivery_on_time   | 35     | 95     | 60    | --       |
			| 2  | QUALITY | quality_acceptance | 35     | 99     | 80    | --       |
			| 3  | PRICE   | price_variance     | 20     | 0      | 5     | --       |
			| 4  | COMMS   | manual             | 10     | 5      | 1     | --       |

	### SupplierRatingBand [DIST][INH] -- which overall score earns which grade, and what the grade triggers
		- id
		- uuid
		- minimum_score                    -- numeric(18,6) -- lowest overall score in the band
		- maximum_score                    -- numeric(18,6) -- highest overall score in the band
		- consequence                      -- jsonb nullable -- what the grade means, e.g. "preferred in pickers"
		- requires_improvement_action      -- bool -- true = the grade opens a SupplierImprovementAction
		- effective_from                   -- date -- first day the band applies
		- effective_to                     -- date nullable -- last day; NULL = still in force
		- grade_lookup_value_id            -- FK LookupValue (SCORECARD_GRADE)
		- tenant_id
		- entity_id
		- user_id
		- state
		-- UNIQUE (entity_id, grade_lookup_value_id, effective_from)
		-- CHECK (app-level): bands in force do not overlap and cover 0..100
		> examples:
			| id | grade             | min | max   | improvement_action |
			| -- | ----------------- | --- | ----- | ------------------ |
			| 1  | excellent         | 85  | 100   | false              |
			| 2  | satisfactory      | 70  | 84.99 | false              |
			| 3  | needs_improvement | 50  | 69.99 | true               |
			| 4  | unsatisfactory    | 0   | 49.99 | true               |

	### SupplierScorecard [DIST] -- one supplier's evaluation for one period; the band it falls in gives the grade
		- id
		- uuid
		- scorecard_number                 -- from DocumentSequence
		- evaluation_period_start          -- date -- first day of the period scored
		- evaluation_period_end            -- date -- last day of the period scored
		- overall_score                    -- numeric(18,6) -- weighted total of the lines, 0..100
		- review_note                      -- jsonb nullable -- the reviewer's remarks before approval
		- recommendation                   -- jsonb nullable -- what procurement should do next with the supplier
		- published_at                     -- timestamp nullable -- when it was shown to the supplier; NULL = internal
		- period_type_lookup_value_id      -- FK LookupValue (SCORECARD_PERIOD_TYPE)
		- procurement_category_id          -- FK ProcurementCategory nullable -- category scored; NULL = all spend
		- supplier_rating_band_id          -- FK SupplierRatingBand -- band the overall score fell in; gives the grade
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- the supplier evaluated
		- evaluated_by                     -- XFK User -- who prepared the scorecard
		- document_id                      -- XFK Document -- the scorecard's approval document
		- scorecard_status_lookup_value_id -- FK LookupValue (SCORECARD_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, scorecard_number),
		--        UNIQUE (entity_id, supplier_id, procurement_category_id, evaluation_period_start)
		-- INDEX (supplier_id, evaluation_period_end)
		-- previous score and trend are read from the supplier's previous scorecard
		> examples:
			| id | supplier | period    | start      | end        | overall | band                | status    |
			| -- | -------- | --------- | ---------- | ---------- | ------- | ------------------- | --------- |
			| 1  | 501      | quarterly | 2026-07-01 | 2026-09-30 | 79.3    | 2 satisfactory      | approved  |
			| 2  | 502      | quarterly | 2026-07-01 | 2026-09-30 | 58.2    | 3 needs_improvement | published |
			| 3  | 503      | quarterly | 2026-07-01 | 2026-09-30 | 88.6    | 1 excellent         | reviewed  |

	### SupplierScorecardLine [LINE] -- one KPI on one scorecard; a manual KPI may have one row per evaluator
		- id
		- uuid
		- measured_value                   -- numeric(18,6) nullable -- derived metric, e.g. % on time; NULL if manual
		- score                            -- numeric(18,6) -- 0..100 after target and floor; the criterion weights it
		- comment                          -- jsonb nullable -- evaluator's remark, mostly on manual KPIs
		- supplier_scorecard_id            -- FK SupplierScorecard
		- supplier_performance_criterion_id -- FK SupplierPerformanceCriterion -- the KPI row in force for the period
		- evaluator_employee_id            -- XFK Employee nullable -- who scored a manual KPI; NULL when derived
		- user_id
		- state
		-- UNIQUE (supplier_scorecard_id, supplier_performance_criterion_id, evaluator_employee_id)
		> examples:
			| id | scorecard | criterion | measured | score | evaluator | comment                    |
			| -- | --------- | --------- | -------- | ----- | --------- | -------------------------- |
			| 1  | 1         | OTD       | 88.0     | 80.0  | --        | --                         |
			| 2  | 1         | QUALITY   | 97.5     | 92.1  | --        | --                         |
			| 3  | 1         | COMMS     | --       | 75.0  | 91        | Slow to answer on weekends |
			| 4  | 1         | PRICE     | 2.1      | 58.0  | --        | --                         |

	### SupplierImprovementAction [DIST] -- a corrective or improvement action required of a supplier, and its result
		- id
		- uuid
		- code                             -- unique per entity
		- title                            -- jsonb
		- finding                          -- jsonb -- the weakness found
		- required_action                  -- jsonb -- what the supplier must do
		- target_date                      -- date -- when the action is due
		- completed_at                     -- timestamp nullable -- when the supplier reported it done
		- verification_note                -- jsonb nullable -- what the check of the completed work found
		- verified_at                      -- timestamp nullable -- when procurement confirmed it was done
		- effectiveness_note               -- jsonb nullable -- whether the problem stayed fixed afterwards
		- effectiveness_verified_at        -- timestamp nullable -- when the lasting effect was confirmed
		- action_type_lookup_value_id      -- FK LookupValue (IMPROVEMENT_ACTION_TYPE)
		- supplier_scorecard_id            -- FK SupplierScorecard nullable -- the scorecard that raised it, if any
		- supplier_claim_id                -- FK SupplierClaim nullable -- the claim that raised it, if any
		- tenant_id
		- entity_id
		- supplier_id                      -- XFK Supplier -- the supplier who must act
		- owner_employee_id                -- XFK Employee -- staff member who follows it up
		- improvement_action_status_lookup_value_id -- FK LookupValue (IMPROVEMENT_ACTION_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, code)
		-- INDEX (supplier_id, improvement_action_status_lookup_value_id),
		--       (target_date, improvement_action_status_lookup_value_id), (owner_employee_id)
		> examples:
			| id | code     | supplier | type       | scorecard | claim | target_date | completed_at | status      |
			| -- | -------- | -------- | ---------- | --------- | ----- | ----------- | ------------ | ----------- |
			| 1  | SIA-0007 | 502      | corrective | 2         | --    | 2026-11-15  | --           | open        |
			| 2  | SIA-0008 | 501      | preventive | --        | 2     | 2026-10-31  | 2026-10-25   | verified    |
			| 3  | SIA-0009 | 502      | warning    | 2         | --    | 2026-12-31  | --           | in_progress |


#12. Procurement period control                                    [PRMS01-14]

	-- Accounting owns the fiscal calendar and the GL close. Procurement needs a lock per
	-- DOCUMENT TYPE ("no new POs dated into August"), decided on another day by another
	-- person. A reopen is time-boxed and re-locks itself.

	### ProcurementPeriodLock [DIST][INH] -- a period closed for one procurement document type, or for all
		- id
		- uuid
		- period_from                      -- date -- first day locked
		- period_to                        -- date -- last day locked
		- allows_backdated_receipt         -- bool default false -- true = goods that arrived earlier may still be keyed
		- locked_at                        -- timestamp nullable -- when the lock took effect
		- reopen_expires_at                -- timestamp nullable -- while reopened: when the job locks it again
		- notes                            -- jsonb nullable -- remarks shown to users who hit the lock
		- lock_type_lookup_value_id        -- FK LookupValue (PERIOD_LOCK_TYPE) -- soft warns, hard blocks
		- tenant_id
		- entity_id
		- document_type_id                 -- XFK DocumentType nullable -- NULL = every procurement document type
		- accounting_period_id             -- XFK Accounting AccountingPeriod nullable -- the matching GL period
		- fiscal_year_id                   -- XFK Accounting FiscalYear -- fiscal year of the period
		- locked_by                        -- XFK User nullable -- who applied the lock
		- period_lock_status_lookup_value_id -- FK LookupValue (PERIOD_LOCK_STATUS)
		- user_id
		- state
		-- UNIQUE (entity_id, document_type_id, period_from, period_to)
		-- INDEX (entity_id, period_lock_status_lookup_value_id, period_from), (reopen_expires_at)
		-- each reopen, with its reason and request, is a ProcurementPeriodLockLog row
		-- soft lets a user override with a reason; hard blocks the document
		> examples:
			| id | doc_type | from       | to         | type | backdated | reopen_until     | status               |
			| -- | -------- | ---------- | ---------- | ---- | --------- | ---------------- | -------------------- |
			| 1  | PO       | 2026-07-01 | 2026-07-31 | hard | false     | --               | locked               |
			| 2  | PGRN     | 2026-07-01 | 2026-07-31 | soft | true      | 2026-08-16 18:00 | temporarily_reopened |
			| 3  | -- (all) | 2026-06-01 | 2026-06-30 | hard | false     | --               | permanently_closed   |

	### ProcurementPeriodLockLog [LINE] -- every lock and reopen, with its reason and the request that approved it
		- id
		- uuid
		- reason                           -- text -- why it was locked or reopened
		- affected_document_count          -- int nullable -- documents still open when the status changed
		- changed_at                       -- timestamp -- when the status changed
		- procurement_period_lock_id       -- FK ProcurementPeriodLock
		- from_status_lookup_value_id      -- FK LookupValue (PERIOD_LOCK_STATUS) nullable
		- to_status_lookup_value_id        -- FK LookupValue (PERIOD_LOCK_STATUS)
		- document_id                      -- XFK Document nullable -- the reopen request; its workflow approves it
		- changed_by                       -- XFK User -- who made the change; the system user for the job
		- user_id
		-- INDEX (procurement_period_lock_id, changed_at)
		> examples:
			| id | lock | from   | to                   | changed_by | reason                      |
			| -- | ---- | ------ | -------------------- | ---------- | --------------------------- |
			| 1  | 2    | open   | locked               | 90         | July procurement close      |
			| 2  | 2    | locked | temporarily_reopened | 90         | Correct mis-costed GRN-9880 |
			| 3  | 1    | open   | locked               | 90         | July PO close               |
