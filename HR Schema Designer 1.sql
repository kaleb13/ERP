-- =============================================================================
--  Haleta ERP -- Human Resources (HR) Module Schema
--
--  Covers the full employee lifecycle -- hire to retire -- for multi-sector
--  tenants (one Haleta group may run a hotel, a factory and a bank):
--  employee master, org structure, calendars/shifts, attendance, leave,
--  payroll (setup + execution), recruitment, performance, training, talent,
--  employee relations, separation, HR letters, and multi-entity workforce
--  (staffing / employer-of-record: provider, client and payer separated --
--  section 11).
--
--  REUSE MAP -- these engines exist in CORE and are never redefined here:
--    * Entity / EntityType                 -> tenant scoping (entity_id) and
--                                             org hierarchy; a cost center IS
--                                             an Entity node
--    * Party                               -> unified identity: employees,
--                                             candidates, dependents and
--                                             emergency contacts each carry a
--                                             Party row (name / phone / email /
--                                             tin / id_type / id_number; Fayda
--                                             national ID = Party.id_type)
--    * User / UserDetail                   -> login; UserDetail.party_id links
--                                             an employee to a login user
--    * Role / Permission / RolePermission
--      UserRoleBinding / UserPermissionOverride -> RBAC + entity scoping
--    * LookupType / LookupValue /
--      LookupTransition                    -> every enum-ish column below;
--                                             state machines via transitions
--    * Workflow / WorkflowStep             -> approval chains (leave, overtime,
--                                             offer, movement, separation,
--                                             disciplinary, settlement...)
--    * CustomField / CustomFieldGroup /
--      CustomFieldValue                    -> per-sector extensibility (hotel
--                                             adds "uniform size", bank adds
--                                             "bonding status"); HR defines no
--                                             dynamic-field tables of its own
--    * DocumentType / DocumentSequence /
--      DocumentAttachment                  -> every generated document (payslip
--                                             PDF, offer letter, warning,
--                                             contract) and every upload (CV,
--                                             Fayda scan, certificate), via
--                                             a core Document row minted per
--                                             HR document class; see the
--                                             STANDARD COLUMNS attachment note
--    * PaymentMethod / PaymentProvider /
--      EntityPaymentMethod                 -> payroll batches settle through
--                                             core payment setup; Ethiopian
--                                             banks (CBE, Awash...) are
--                                             PaymentProviders with
--                                             method = BANK_TRANSFER
--    * Currency / Country / AdminUnit /
--      AdminLevel                          -> money + geography
--    * Icon / IconGroup                    -> department / position / shift UI
--    * Notification engine                 -> reminders (contract expiry,
--                                             certification expiry, approvals
--                                             due); no HR notification tables
--    * Audit module                        -> automatic event-stream audit
--                                             trail; no HR audit tables
--    * Reports module                      -> HR analytics/report catalogue;
--                                             no HR report tables
--    * Employee (core, thin:
--      id, uuid, entity_id, party_id, state) -> extended by EmployeeDetail +
--                                             satellites below; never altered
--
--  DYNAMIC-CONFIGURATION PRINCIPLES:
--    * Nothing sector-specific is hardcoded: leave rules, shift patterns, pay
--      components, grades and appraisal templates are DATA rows scoped by
--      entity_id (NULL entity_id on a catalogue row = platform template).
--    * Pay is formula-driven: PayrollComponent + PayrollFormula (jsonb
--      expression, effective-dated) define earnings and deductions without
--      code changes.
--    * Ethiopia statutory values are DATA, not columns: pension 7% employee /
--      11% employer and severance rules live in StatutoryRule; the progressive
--      income-tax schedule lives in TaxBracket; Fayda is an id_type
--      LookupValue on Party; the Ethiopian fiscal year (Hamle 1 - Sene 30) is
--      WorkCalendar / WorkCalendarDay data.
--    * Effective-dating wherever money or rules change over time:
--      effective_from / effective_to (NULL effective_to = current).
--    * Governance: catalogue tables carry status_lookup_value_id using the
--      CORE governance lookup (pending | acceptForAll | acceptForThis |
--      reject); the global row is a template cloned per entity, exactly as
--      document sequences do.
--
--  CROSS-MODULE CONTRACTS:
--    * Payroll batches settle via core PaymentMethod / PaymentProvider (bank
--      files); accounting posting is a downstream module consuming PayrollRun
--      as its source document.
--    * Cost distribution reuses Entity: EmploymentAssignment.entity_id is
--      simultaneously the cost center.
--    * Sales cashier shift rostering stays in the Sales module (its
--      ShiftType / ShiftAssignment are POS-session constructs); HR
--      Shift / ShiftAssignment below are labour-time constructs. The two are
--      deliberately separate concerns.
--    * Approvals: any row whose *_state lookup includes "pending" resolves its
--      approver chain through core Workflow / WorkflowStep; approval progress
--      is best-effort, never gates status bumps, and acted steps are
--      recorded in per-document approval tables (workflow_step_id ->
--      core WorkflowStep; the chain definition stays in core).
--    * Expense + medical reimbursement settle through PAYROLL           -- new
--      (PayrollInput), not accounts payable -- accounting must not      -- new
--      build a second expense flow for employees.                       -- new
--    * PaymentBatch cash_via_cashier is HR-side cash handling only;     -- new
--      it never touches the Sales cashier-session ledger.               -- new
-- =============================================================================

-- =============================================================================
--  DOCUMENT LAYOUT -- grouped by module, then by feature, in MIGRATION ORDER
--
--  Section 1 is the CORE module: tables HR references by FK but does not own.
--  Sections 2..19 are the HR module, ordered so that every table's FK targets
--  are already created by the time its own section is reached. Build, migrate,
--  seed and ship one section completely before opening the next.
--
--  Each section opens with the lookup types FIRST USED by its tables, so a
--  section is self-contained: its lookups, then its tables in creation order.
--  A lookup type is declared exactly once, in the earliest section that uses it;
--  later sections reuse it and never redeclare it.
--
--  DEFERRED FOREIGN KEYS -- the only six edges that point at a later section.
--  All are nullable provenance caches, so the column ships with its own table
--  and the constraint is wired by a follow-up migration in the later section:
--    * EmployeeDetail.hired_from_candidate_id          (s.2)  -> Candidate            (s.18)
--    * EmployeeDetail.hired_from_recruitment_result_id (s.2)  -> RecruitmentResult    (s.18)
--    * EmployeeDetail.hired_from_job_offer_id          (s.2)  -> JobOffer             (s.18)
--    * EmployeeDetail.hired_from_job_posting_id        (s.2)  -> JobPosting           (s.18)
--    * EmployeeSalary.compensation_proposal_id         (s.8)  -> CompensationProposal (s.17)
--    * JobRequisition.hr_service_agreement_id          (s.18) -> HRServiceAgreement   (s.19)
--
--  CROSS-MODULE FKs -- legal at DB level, but the code must go through
--  common/Contracts/, never a direct use of another module's classes:
--    * EmployeeAsset.product_id                  (s.10) -> Inventory.Product
--    * PayrollInput.source_type = 'SalesCommissionRun' (s.9)  -> Sales
--
--  CATALOGUE GOVERNANCE -- status_lookup_value_id on catalogue tables reuses the
--  CORE governance lookup (pending | acceptForAll | acceptForThis | reject).
--  Fayda national ID is seed data on the CORE ID_TYPE lookup (fayda | passport |
--  kebele_id | driving_license) -- not a new lookup type.
--  Permission keys live in modules/HR/Helper/Permission/PermissionList.php
--  (canViewEmployee, canManageEmployee, canRunPayroll, canApprovePayroll,
--   canManageLeave, canApproveLeave, canManageRecruitment, canViewPayslip,
--   canManagePerformance, canManageSeparation ...) -- no HR ACL tables.
--
--  LOOKUP CONSOLIDATION NOTE:
--  BENEFIT_PLAN_ASSIGNMENT_STATE and BENEFIT_ENROLLMENT_STATE share values.
--  Kept separate: plan-level assignment vs individual enrollment may diverge.
--  LANGUAGE_PROFICIENCY (composite summary) and LANGUAGE_SKILL_LEVEL (4-axis)
--  are intentionally two distinct types used on different columns of PartyLanguage.
-- =============================================================================

-- =============================================================================
--  STANDARD COLUMNS, TENANCY AND NOTATION
--
--  * Implied on EVERY table, never repeated below: created_at / updated_at
--    (timestamps) and deleted_at (soft delete).
--  * TENANCY CLASS -- every table heading carries one of three tags:
--      [DIST]  tenant-owned. Carries NOT NULL tenant_id, listed below
--              (FK tenant-root Entity, indexed, in the FK group beside
--              entity_id; in $fillable right after uuid). Stamped by
--              ModelTrait, never accepted from a payload.
--      [REF]   shared catalogue every tenant reads (entity_id NULL =
--              platform seed + governance status). No tenant column.
--      [LINE]  no entity of its own -- entity_id + tenant_id (listed below) are copied
--              down from its header via one row in
--              helper/Tenancy/Tenancy.php LINES; the model declares
--              nothing. A line inherits its header's class (a line of a
--              [REF] header is reference too).
--    The section-2 Employee profile satellites (Detail, Dependent,
--    Qualification, Certification, Experience, Skill, Language,
--    Compliance, BankAccount, EmergencyContact, Disability) are [DIST]
--    but register in LINES with Employee as their header, so an employee
--    transfer cascades entity + tenant into them.
--  * UNIQUE keys below list the BUSINESS key only. On every [DIST]/[LINE]
--    table the migration prepends tenant_id -- including uuid
--    (UNIQUE (tenant_id, uuid)), raw partial indexes, and upsert uniqueBy
--    lists.
--  * Example tables OMIT tenant_id -- its value is mechanical (the tenant root
--    of the row's entity), never business data.
--  * ATTACHMENTS / DOCUMENTS -- core DocumentAttachment is NOT           -- new
--    polymorphic: it hangs off a core Document row (document_id). Every
--    "via DocumentAttachment ('HR:X')" note below therefore means: X has
--    a core DocumentType, its code is minted by that type's
--    DocumentSequence, a core Document row is created with it, and X
--    carries an IMPLIED nullable document_id FK to that row (declared
--    explicitly only where it already existed: GuaranteeRevocation,
--    Collateral). DocumentApproval rides the same Document row.
--  * '-- new' marks every column / table / lookup value added by the
--    2026-08 review revisions -- grep it to trace the additions.
-- =============================================================================

#1. CORE MODULE -- shared identity and catalogues (owned by core, referenced by HR via FK only)


 ##1.1 Reused core anchor -- listed for reference only; the table already exists in core and no columns are added to it

	### Employee [DIST] -- REUSED FROM CORE; one row per employed person, extended 1:1 by EmployeeDetail (no columns are added here)
		- id                      -- core columns only: id, uuid, tenant_id, entity_id (FK Entity), party_id (FK Party), state
		  -- note: identity (names, phones, emails, tin, id_type / id_number incl. Fayda) lives on Party.
		  -- note: login linkage is UserDetail.party_id -- an employee may have no login user.
		> examples:
			| id | uuid     | entity_id | party_id | state  |
			| -- | -------- | --------- | -------- | ------ |
			| 7  | 9f1a...  | 3         | 107      | active |
			| 14 | 2b7c...  | 7         | 214      | active |
			| 22 | 5d0e...  | 3         | 322      | active |
			| 31 | 8a4f...  | 9         | 431      | active |
			| 44 | c3d9...  | 3         | 544      | active |


 ##1.2 Shared catalogues -- academic and institutional reference data; LYU field_of_studies and eSchool institutions map to these by code

	-- note: none of the section 1.2 - 1.4 tables exist in core today --
	-- they are NEW tables this design delivers. The Party satellites extend core
	-- parties (REFERENCE class) and belong in CORE migrations; Committee /
	-- CommitteeMember are generic panel constructs (a stock-count committee is among the
	-- examples). DECIDED: ALL section-1 tables ship as CORE migrations.

	## lookups first used in this section
		- INSTITUTION_TYPE            : university | college | tvet | high_school | professional_body | training_center | regulator

	### FieldOfStudy [REF] -- one row per academic discipline; shared catalogue for HR qualifications, position requirements and LYU postings
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique (ACCOUNTING, SOFTWARE_ENGINEERING)
		- name                    -- jsonb (localized)
		- parent_id               -- FK FieldOfStudy nullable -- hierarchy (Business -> Accounting)
		- entity_id               -- FK Entity nullable -- NULL = platform seed; tenant additions carry their entity
		- is_system               -- platform-seeded row
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- state                   -- active / inactive
		> examples:
			| id | code                | name (en)                 | parent_id | entity_id | is_system | state  |
			| -- | ------------------- | ------------------------- | --------- | --------- | --------- | ------ |
			| 1  | BUSINESS            | Business Administration   | --        | --        | true      | active |
			| 3  | ACCOUNTING          | Accounting                | 1         | --        | true      | active |
			| 7  | FINANCE             | Finance                   | 1         | --        | true      | active |
			| 9  | HRM                 | Human Resource Management | 1         | --        | true      | active |
			| 15 | SUPPLY_CHAIN        | Supply Chain Management   | 1         | --        | true      | active |

	### Institution [REF] -- one row per external education or certification body; universities, colleges, TVET, professional bodies, regulators
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique (AAU, BDU, ACCA_GLOBAL)
		- name                    -- jsonb (localized)
		- institution_type_lookup_value_id -- FK LookupValue (INSTITUTION_TYPE: university | college | tvet | high_school | professional_body | training_center | regulator)
		- country_id              -- FK Country -- home country; qualification rows never repeat it
		- admin_unit_id           -- FK AdminUnit nullable -- location within Ethiopia
		- party_id                -- FK Party nullable -- set when the institution is also a business partner (training vendor, insurer)
		- website                 -- text nullable
		- entity_id               -- FK Entity nullable -- NULL = platform seed
		- is_system               -- platform-seeded row
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- state                   -- active / inactive
		> examples:
			| id | code        | name (en)                        | institution_type  | country | admin_unit_id | is_system | state  |
			| -- | ----------- | -------------------------------- | ----------------- | ------- | ------------- | --------- | ------ |
			| 1  | AAU         | Addis Ababa University           | university        | ET      | 305           | true      | active |
			| 2  | BDU         | Bahir Dar University             | university        | ET      | 401           | true      | active |
			| 4  | ADMAS       | Admas University College         | college           | ET      | 315           | true      | active |
			| 7  | ACCA_GLOBAL | ACCA Global                      | professional_body | GB      | --            | true      | active |
			| 8  | AABE        | Accounting & Auditing Board (ET) | regulator         | ET      | 305           | true      | active |


 ##1.3 Party profile -- the 1:1 and 1:N extensions of core Party; a candidate carries these before any Employee row exists

	## lookups first used in this section
		- BLOOD_GROUP                 : a_pos | a_neg | b_pos | b_neg | ab_pos | ab_neg | o_pos | o_neg | unknown
		- GENDER_TYPE                 : male | female
		- MARITAL_STATUS              : single | married | divorced | widowed
		- NATIONALITY_TYPE            : citizen | resident_foreigner | non_resident_foreigner | dual_citizen
		  -- drives work-permit requirement and pension applicability; nationality_country_id alone cannot answer it
		- ADDRESS_TYPE                : residence | postal | work | emergency | birth_place | other
		  -- used by PartyAddress.address_type_lookup_value_id
		- DEPENDENT_RELATION          : spouse | child | parent | sibling | other
		- QUALIFICATION_LEVEL         : primary | secondary | tvet_certificate | diploma | bachelors | masters | phd
		- CERTIFICATION_CATALOG       : open catalogue -- certification/license names (acca | cpa | cfa | cia | cisa | food_handler | fire_safety | occupational_safety | first_aid | procurement_specialist | hr_professional | driving_license_b | driving_license_c | driving_license_d | driving_license_f | teaching_license | nursing_license | pharmacy_license | engineering_license | other); localized via LookupValue.name
		- EMPLOYMENT_TYPE             : permanent | contract | temporary | probation | part_time | intern | consultant
		- SKILL_CATALOG               : open catalogue -- entity-scoped skill names (ifrs_reporting | peachtree | food_safety | pos_operation | food_handler_technique | cash_management | supplier_negotiation | labour_law_compliance | customer_service | data_entry | warehouse_management | forklift_operation | barista | housekeeping | front_desk | other); platform seeds per sector, tenants extend
		- SKILL_PROFICIENCY           : beginner | intermediate | advanced | expert
		- LANGUAGE_CATALOG            : open catalogue -- languages (amharic | english | afaan_oromo | tigrinya | somali | arabic | tigre | sidama | wolaytta | hadiyya | afar | berta | gumuz | anuak | nuer | other); localized via LookupValue.name; platform seeds the above, tenants extend
		- LANGUAGE_PROFICIENCY        : basic | conversational | fluent | native
		  -- used as the overall / composite spoken proficiency summary on PartyLanguage.proficiency_lookup_value_id
		- LANGUAGE_SKILL_LEVEL        : none | basic | intermediate | advanced | native
		  -- used for the four directional skill axes on PartyLanguage: speaking, listening, reading, writing
		  -- LANGUAGE_PROFICIENCY and LANGUAGE_SKILL_LEVEL are intentionally separate:
		  -- proficiency = quick single-axis summary; skill_level = four-axis detailed breakdown

	### PartyDetail [REF] -- one row per Party; the 1:1 demographic extension of core Party (birth, gender, citizenship)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- party_id                -- FK Party -- UNIQUE (1:1); the identity this detail extends
		- gender_lookup_value_id  -- FK LookupValue (GENDER_TYPE: male | female)
		- blood_group_lookup_value_id -- FK LookupValue (BLOOD_GROUP: a_pos | a_neg | b_pos | b_neg | ab_pos | ab_neg | o_pos | o_neg | unknown) nullable
		- birth_date              -- date
		- birth_place             -- text nullable -- town of birth (Debre Markos, Hawassa)
		- nationality_country_id  -- FK Country -- citizenship -- what if the employee has multiple citizenships? => new pivot table will be added
		- state                   -- active / inactive
		- nationality_type_lookup_value_id -- FK LookupValue (NATIONALITY_TYPE: citizen | resident_foreigner | non_resident_foreigner | dual_citizen) -- drives work-permit and pension applicability; nationality_country_id alone cannot answer it
		- marital_status_lookup_value_id -- FK LookupValue (MARITAL_STATUS: single | married | divorced | widowed)
		> examples:
			| id | party_id | gender | blood_group | birth_date | birth_place  | nationality_country_id | nationality_type | marital_status | state  |
			| -- | -------- | ------ | ----------- | ---------- | ------------ | ---------------------- | ---------------- | -------------- | ------ |
			| 1  | 107      | female | o_pos       | 1990-04-18 | Addis Ababa  | ET                     | citizen          | married        | active |
			| 2  | 214      | male   | a_pos       | 1996-11-02 | Debre Markos | ET                     | citizen          | single         | active |
			| 3  | 322      | female | b_neg       | 1992-01-27 | Hawassa      | ET                     | citizen          | married        | active |
			| 4  | 431      | male   | o_neg       | 1988-07-09 | Bahir Dar    | ET                     | citizen          | divorced       | active |
			| 5  | 544      | female | ab_pos      | 1985-03-15 | Addis Ababa  | KE                     | resident_foreigner | married      | active |

	### PartyAddress [REF] -- new -- one row per address held for a Party; replaces the EmployeeDetail.residence_address jsonb (and the address jsonb on any other Party-backed row)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- party_id                -- FK Party -- whose address this is; the person or organisation, so a candidate carries it before any Employee row exists
		- address_type_lookup_value_id -- FK LookupValue (ADDRESS_TYPE: residence | postal | work | emergency | birth_place | other)
		- admin_unit_id           -- FK AdminUnit nullable -- woreda / sub-city; the geography spine, not free text
		- line                    -- text nullable -- street / locality line as written
		- house_number            -- text nullable -- house number; printed on Fayda ID registration
		- kebele                  -- text nullable -- kebele / neighbourhood unit
		- postal_code             -- text nullable
		- is_primary              -- bool -- one primary per (party_id, address_type)
		- effective_from          -- date nullable -- NULL = always been current; a move stamps the old row and inserts a new one
		- effective_to            -- date nullable -- NULL = current
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- UNIQUE (party_id, address_type_lookup_value_id, is_primary) WHERE is_primary AND effective_to IS NULL
		  -- note: admin_unit_id carries the geography; line / house_number / kebele are only what AdminUnit cannot express.
		  -- note: an employee's residence is the primary residence row of their Party -- EmployeeDetail holds no address columns.
		> examples:
			| id | party_id | address_type | admin_unit_id      | line              | house_number | kebele | is_primary | effective_from | state  |
			| -- | -------- | ------------ | ------------------ | ----------------- | ------------ | ------ | ---------- | -------------- | ------ |
			| 1  | 107      | residence    | 305 (Bole)         | Cameroon St.      | 214          | 08     | true       | 2022-01-10     | active |
			| 2  | 107      | postal       | 305 (Bole)         | P.O.Box 1176      | --           | --     | true       | 2022-01-10     | active |
			| 3  | 214      | residence    | 312 (Kirkos)       | Wollo Sefer       | 77/A         | 03     | true       | 2024-06-01     | active |
			| 4  | 322      | residence    | 401 (Bahir Dar)    | Kebele 14 road    | 9            | 14     | true       | 2021-09-15     | active |
			| 5  | 611      | emergency    | 305 (Bole)         | Behind Edna Mall  | 42           | 08     | true       | --             | active |

	### PartyDependent [REF] -- one row per dependent (spouse / child / parent); feeds benefits, tax relief and insurance
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- party_id                -- FK Party -- the HOLDER: the person the dependent belongs to
		- dependent_party_id      -- FK Party -- the DEPENDENT's own identity (name / birth info / id)
		- relation_lookup_value_id -- FK LookupValue (DEPENDENT_RELATION: spouse | child | parent | sibling | other)
		- birth_date              -- date nullable -- convenience copy; the dependent's PartyDetail (when present) is authoritative
		- benefit_notes           -- jsonb nullable -- coverage remarks (insurance card number, exclusions)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | party_id | dependent_party_id | relation | birth_date | is_beneficiary | state  |
			| -- | -------- | ------------------ | -------- | ---------- | -------------- | ------ |
			| 1  | 107      | 611                | spouse   | 1991-08-04 | true           | active |
			| 2  | 107      | 612                | child    | 2019-12-01 | true           | active |
			| 3  | 322      | 613                | child    | 2016-04-22 | true           | active |
			| 4  | 544      | 614                | spouse   | 1985-10-10 | true           | active |
			| 5  | 431      | 615                | parent   | 1966-02-14 | false          | active |

	### PartyQualification [REF] -- one row per academic credential; degree scans via DocumentAttachment ('HR:PartyQualification')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- party_id                -- FK Party -- credential holder
		- level_lookup_value_id   -- FK LookupValue (QUALIFICATION_LEVEL: primary | secondary | tvet_certificate | diploma | bachelors | masters | phd) -- it should be table => it will be table
		- field_of_study_id       -- FK FieldOfStudy -- common catalogue (0.11); joins JobPositionRequirement.field_of_study_id for gap analysis
		- institution_id          -- FK Institution -- awarding body (0.11); it carries its own country and type
		- start_date              -- date nullable -- study start
		- graduation_date         -- date nullable -- award date
		- gpa                     -- numeric(4,2) nullable -- on the 4.00 scale
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | party_id | level            | field_of_study_id | institution_id  | start_date | graduation_date | gpa  | state  |
			| -- | -------- | ---------------- | ----------------- | --------------- | ---------- | --------------- | ---- | ------ |
			| 1  | 322      | bachelors        | 3 (Accounting)    | 1 (AAU)         | 2010-09-20 | 2014-07-05      | 3.40 | active |
			| 2  | 544      | masters          | 7 (Finance)       | 1 (AAU)         | 2010-09-15 | 2012-07-07      | 3.80 | active |
			| 3  | 107      | bachelors        | 9 (HRM)           | 2 (BDU)         | 2012-09-10 | 2016-07-02      | 3.10 | active |
			| 4  | 214      | diploma          | 12 (Marketing)    | 4 (ADMAS)       | 2020-09-01 | 2022-06-25      | 3.00 | active |
			| 5  | 431      | tvet_certificate | 15 (Supply Chain) | 5 (Entoto TVET) | 2017-09-04 | 2019-06-30      | --   | active |

	### PartyCertification [REF] -- one row per professional certification or license; expiry reminders ride the Notification engine
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- party_id                -- FK Party -- certification holder
		- certification_lookup_value_id -- FK LookupValue (CERTIFICATION_CATALOG) -- open catalogue; the value carries the localized name
		- issuing_institution_id  -- FK Institution -- professional body / regulator (0.11)
		- certificate_number      -- text nullable -- the holder's own number; instance data, never catalogue data
		- issued_date             -- date
		- expiry_date             -- date nullable -- NULL = never expires
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | party_id | certification          | issuing_institution_id              | certificate_number | issued_date | expiry_date | state  |
			| -- | -------- | ---------------------- | ----------------------------------- | ------------------ | ----------- | ----------- | ------ |
			| 1  | 322      | acca                   | 7 (ACCA_GLOBAL)                     | ACCA-1188220       | 2019-06-15  | --          | active |
			| 2  | 544      | cpa                    | 8 (AABE)                            | CPA-ET-4415        | 2015-09-01  | --          | active |
			| 3  | 214      | food_handler           | 9 (AA Food & Drug Authority)        | FH-2024-88412      | 2024-06-20  | 2026-06-20  | active |
			| 4  | 431      | procurement_specialist | 10 (Federal PPA)                    | PPA-2023-1120      | 2023-04-10  | 2027-04-10  | active |
			| 5  | 107      | hr_professional        | 11 (Ethiopian Management Institute) | EMI-HR-0450        | 2021-11-05  | --          | active |

	### PartyExperience [REF] -- one row per prior job at an external employer; reference letters via DocumentAttachment ('HR:PartyExperience')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- party_id             -- FK Party -- the person whose history this is
		- employer_party_id       -- FK Party -- previous employer; its name / tin / phone live on Party, never duplicated here
		- position_title          -- text -- verbatim title at the external employer; deliberately not normalized into internal JobTitle
		- employment_type_lookup_value_id -- FK LookupValue (EMPLOYMENT_TYPE: permanent | contract | temporary | probation | part_time | intern | consultant)
		- start_date              -- date
		- end_date                -- date nullable -- NULL = still ongoing (rare)
		- responsibilities        -- jsonb nullable -- localized narrative
		- reason_for_leaving      -- jsonb nullable
		- reference_party_id      -- FK Party nullable -- reference person at that employer (name / phone / email on Party)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive

		> examples:
			| id | party_id | employer_party_id      | position_title      | employment_type | start_date | end_date   | reference_party_id | state  |
			| -- | -------- | ---------------------- | ------------------- | --------------- | ---------- | ---------- | ------------------ | ------ |
			| 1  | 322      | 930 (Zemen Bank)       | Junior Accountant   | permanent       | 2018-08-01 | 2021-08-31 | 951                | active |
			| 2  | 544      | 931 (Awash Bank)       | Branch Accountant   | permanent       | 2015-01-15 | 2020-01-31 | 952                | active |
			| 3  | 544      | 932 (Dashen Bank)      | Finance Analyst     | contract        | 2020-02-15 | 2020-02-28 | --                 | active |
			| 4  | 214      | 933 (Shoa Supermarket) | Cashier             | permanent       | 2022-03-01 | 2024-05-15 | 953                | active |
			| 5  | 431      | 934 (Kuriftu Resorts)  | Procurement Officer | permanent       | 2023-06-01 | 2025-02-10 | --                 | active |

	### PartySkill [REF] -- one row per skill an employee holds; feeds staffing, succession and training-gap analysis
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- party_id                -- FK Party -- skill holder
		- skill_lookup_value_id   -- FK LookupValue (SKILL_CATALOG) -- the open catalogue is the only skill identity, never free text -- UNIQUE (party_id, skill_lookup_value_id)
		- proficiency_lookup_value_id -- FK LookupValue (SKILL_PROFICIENCY: beginner | intermediate | advanced | expert)
		- years_of_experience     -- numeric(4,1) nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | party_id | skill                 | proficiency  | years_of_experience | state  |
			| -- | -------- | --------------------- | ------------ | ------------------- | ------ |
			| 1  | 322      | ifrs_reporting        | advanced     | 5.0                 | active |
			| 2  | 322      | peachtree             | expert       | 6.0                 | active |
			| 3  | 214      | pos_operation         | expert       | 2.0                 | active |
			| 4  | 431      | supplier_negotiation  | intermediate | 3.0                 | active |
			| 5  | 107      | labour_law_compliance | advanced     | 4.0                 | active |

	### PartyLanguage [REF] -- one row per language an employee speaks; joins JobPositionRequirement language rows for multilingual staffing
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- party_id                -- FK Party -- language holder
		- language_lookup_value_id -- FK LookupValue (LANGUAGE_CATALOG) -- open catalogue -- UNIQUE (party_id, language_lookup_value_id)
		- proficiency_lookup_value_id -- FK LookupValue (LANGUAGE_PROFICIENCY: basic | conversational | fluent | native) -- composite summary level
		- speaking_level_lookup_value_id -- FK LookupValue (LANGUAGE_SKILL_LEVEL: none | basic | intermediate | advanced | native) -- spoken level
		- listening_level_lookup_value_id -- FK LookupValue (LANGUAGE_SKILL_LEVEL: none | basic | intermediate | advanced | native) -- listening level
		- reading_level_lookup_value_id -- FK LookupValue (LANGUAGE_SKILL_LEVEL: none | basic | intermediate | advanced | native) -- reading level
		- writing_level_lookup_value_id -- FK LookupValue (LANGUAGE_SKILL_LEVEL: none | basic | intermediate | advanced | native) -- writing level
		- is_native               -- bool
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | party_id | language    | proficiency    | speaking_level | listening_level | reading_level | writing_level | is_native | state  |
			| -- | -------- | ----------- | -------------- | -------------- | --------------- | ------------- | ------------- | --------- | ------ |
			| 1  | 322      | amharic     | native         | native         | native          | native        | native        | true      | active |
			| 2  | 322      | english     | fluent         | advanced       | advanced        | advanced      | intermediate  | false     | active |
			| 3  | 214      | afaan_oromo | native         | native         | native          | native        | advanced      | true      | active |
			| 4  | 214      | amharic     | fluent         | advanced       | advanced        | advanced      | advanced      | false     | active |
			| 5  | 544      | english     | conversational | intermediate   | intermediate    | advanced      | basic         | false     | active |


 ##1.4 Committee -- generic panel construct; HR grievance, disciplinary hearing and disciplinary action all reference it

	## lookups first used in this section
		- COMMITTEE_ROLE              : chair | member | secretary | treasurer | observer
		  -- used by CommitteeMember.role_lookup_value_id

	### Committee [DIST] -- one row per standing or ad-hoc panel of employees (disciplinary hearing, grievance, recruitment, safety); members join via CommitteeMember
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (CMT-DISC, CMT-GRV)
		- name                    -- jsonb (localized) -- { en: "Disciplinary Committee", am: "..." }
		- description             -- jsonb (localized) nullable -- mandate / terms of reference
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- start_date              -- date -- when the committee was constituted
		- end_date                -- date nullable -- NULL = standing committee with no dissolution date
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code     | name (en)                | entity_id | start_date | end_date   | state  |
			| -- | -------- | ------------------------ | --------- | ---------- | ---------- | ------ |
			| 1  | CMT-DISC | Disciplinary Committee   | 3         | 2022-01-10 | --         | active |
			| 2  | CMT-GRV  | Grievance Committee      | 3         | 2022-01-10 | --         | active |
			| 3  | CMT-REC  | Recruitment Panel        | 7         | 2026-01-05 | --         | active |
			| 4  | CMT-SAFE | Safety & Health Committee| 9         | 2025-03-01 | --         | active |
			| 5  | CMT-AUD  | Stock Count Committee    | 7         | 2026-06-01 | 2026-06-30 | active |

	### CommitteeMember [LINE] -- one row per employee on a committee; joins Employee to Committee
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- employee_id             -- FK Employee
		- committee_id            -- FK Committee
		- role_lookup_value_id    -- FK LookupValue (COMMITTEE_ROLE: chair | member | secretary | treasurer | observer)
		- start_date              -- date
		- end_date                -- date nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | employee_id | committee_id | role      | start_date | end_date | state  |
			| -- | ----------- | ------------ | --------- | ---------- | -------- | ------ |
			| 1  | 7           | 1            | chair     | 2022-01-10 | --       | active |
			| 2  | 14          | 1            | member    | 2022-01-10 | --       | active |
			| 3  | 22          | 1            | secretary | 2022-01-10 | --       | active |
			| 4  | 31          | 1            | treasurer | 2022-01-10 | --       | active |
			| 5  | 44          | 2            | chair     | 2022-01-10 | --       | active |


#2. HR -- Employee master

	## lookups first used in this section
		- EMPLOYMENT_STATUS           : draft | probation | active | suspended | on_leave | separated | deactivated
		- COMPLIANCE_ITEM_TYPE        : fayda_verification | pension_registration | work_permit | medical_check | police_clearance | professional_license | tax_registration
		- COMPLIANCE_STATUS           : pending | valid | expiring | expired | waived | rejected
		- BANK_ACCOUNT_STATE          : pending_verification | verified | rejected | closed
		- EMERGENCY_RELATION          : spouse | parent | child | sibling | relative | friend | colleague
		- DISABILITY_SEVERITY         : mild | moderate | severe
		- DISABILITY_TYPE             : visual | hearing | physical | speech | intellectual | psychosocial | multiple | other
		- CONTRACT_STATE              : draft | pending_signature | active | expiring | expired | terminated | renewed
		- CONTRACT_TYPE               : indefinite | fixed_term | project_based | casual
		- GUARANTEE_PURPOSE           : cash_handling | loan | study_bond | asset_custody | general
		- GUARANTEE_STATE             : draft | active | expired | revoked | released
		- GUARANTEE_REVOCATION_STATE  : pending | approved | rejected
		  -- used by GuaranteeRevocation.approval_state_lookup_value_id
		- COLLATERAL_STATUS           : requested | approved | rejected | finished
		  -- used by Collateral.status_lookup_value_id
		- COLLATERAL_APPROVAL_STATE   : pending | approved | rejected  -- new -- per-approver verdict on CollateralApproval
		- NAME_PREFIX                 : ato | woizero | woizerit | dr | prof | eng | other
		  -- used by Collateral.name_prefix_lookup_value_id; covers Ethiopian honorific prefixes

	### EmployeeDetail [DIST] -- one row per employee; the 1:1 HR extension of core Employee (the "HR file" header)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- UNIQUE (1:1)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- cache/denormalized copy of Employee.entity_id for direct scoping
		- employee_number         -- business code, unique per entity, via DocumentSequence (EMP-0007)
		  -- note: no address columns here. The employee's residence is the primary ADDRESS_TYPE = residence row
		  -- on PartyAddress for this employee's Party (residence_admin_unit_id / residence_address / house_number moved there).
		- hire_date               -- date -- first day of employment in the group
		- probation_end_date      -- date nullable -- planned probation end
		- confirmation_date       -- date nullable -- when probation was actually confirmed; NULL while on probation or for direct hires
		- employment_type_lookup_value_id -- FK LookupValue (EMPLOYMENT_TYPE: permanent | contract | temporary | probation | part_time | intern | consultant)
		- employment_status_lookup_value_id -- FK LookupValue (EMPLOYMENT_STATUS: draft | probation | active | suspended | on_leave | separated | deactivated)
		- pension_number          -- text nullable -- POESSA pension registration number
		- tin                     -- text nullable -- Taxpayer Identification Number from the Ministry of Revenues (0045213387); printed on income-tax and pension filings and on the payslip
		- photo                   -- path on assets disk, nullable; document uploads (CV, Fayda scan) are DocumentAttachment ('HR:EmployeeDetail')
		- notes                   -- jsonb nullable -- free-form HR remarks
		- hired_from_candidate_id -- FK Candidate nullable -- the Candidate this employee was hired from
		- hired_from_recruitment_result_id -- FK RecruitmentResult nullable -- the current result row behind the offer (score / rank preserved)
		- hired_from_job_offer_id     -- FK JobOffer nullable -- the accepted offer that produced this hire
		- hired_from_job_posting_id -- FK JobPosting nullable -- cache/denormalized -- fast "which posting produced this hire" filters
		- user_id                 -- FK User -- who created the row
		- work_email              -- string nullable -- email used for work correspondence
		- signature               -- path on assets disk, nullable -- scanned specimen signature merged into letters and bank mandates
		  -- note: hired_from_* provenance is stamped on hire; NULL for legacy employees and manual back-fills.
		  -- note: tin is captured by HR at hire and is the value used on income-tax and pension filings.
		> examples:
			| id | employee_id | employee_number | tin        | hire_date  | employment_type | employment_status | hired_from_candidate_id | hired_from_recruitment_result_id | hired_from_job_offer_id | hired_from_job_posting_id | state  |
			| -- | ----------- | --------------- | ---------- | ---------- | --------------- | ----------------- | ----------------------- | -------------------------------- | ----------------------- | ------------------------- | ------ |
			| 1  | 7           | EMP-0007        | 0045213387 | 2022-01-10 | permanent       | active            | --                      | --                               | --                      | --                        | active |
			| 2  | 14          | EMP-0014        | 0051177245 | 2024-06-01 | permanent       | active            | 487                     | 774                              | 29                      | 15                        | active |
			| 3  | 22          | EMP-0022        | 0032890114 | 2021-09-15 | permanent       | active            | --                      | --                               | --                      | --                        | active |
			| 4  | 31          | EMP-0031        | 0068224531 | 2025-02-17 | contract        | probation         | 461                     | 719                              | 27                      | 14                        | active |
			| 5  | 44          | EMP-0044        | 0027745690 | 2020-03-02 | permanent       | active            | --                      | --                               | --                      | --                        | active |

	### EmployeeStatusHistory [DIST] -- one row per employment-status episode; answers "what was this employee's status on date X, and which transaction caused it"
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- the person the episode belongs to
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- status_lookup_value_id  -- FK LookupValue (EMPLOYMENT_STATUS: draft | probation | active | suspended | on_leave | separated | deactivated)
		- effective_date          -- date -- episode start
		- end_date                -- date nullable -- NULL = current episode
		- reason                  -- jsonb nullable -- narrative behind the change
		- source_type             -- text -- originating document class: 'EmployeeMovement' | 'DisciplinaryAction' | 'EmployeeSeparation'
		- source_id               -- integer -- primary key of that document
		- user_id                 -- FK User -- who created the row (person or system)
		- state                   -- active / inactive
		  -- note: EmployeeDetail.employment_status_lookup_value_id is the cache of the current episode; this table is the timeline behind it.
		> examples:
			| id | employee_id | status    | effective_date | end_date   | source (summary)              | state  |
			| -- | ----------- | --------- | -------------- | ---------- | ----------------------------- | ------ |
			| 1  | 14          | probation | 2024-06-01     | 2024-08-01 | employee_movement_id=101      | active |
			| 2  | 14          | active    | 2024-08-02     | --         | confirmation movement         | active |
			| 3  | 18          | suspended | 2025-12-01     | 2025-12-06 | disciplinary_action_id=10     | active |
			| 4  | 18          | active    | 2025-12-07     | 2026-03-02 | reinstatement                 | active |
			| 5  | 18          | separated | 2026-03-03     | --         | employee_separation_id=11     | active |

	### EmployeeDependent [DIST] -- one row per dependent (spouse / child / parent); feeds benefits, tax relief and insurance
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- the employee this dependent belongs to
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- is_beneficiary          -- bool -- included in insurance / pension survivor benefits
		- party_dependent_id      -- FK PartyDependent -- the dependent record on the identity side (relation / beneficiary / benefit notes live there)
		- state                   -- active / inactive
		> examples:
			| id | employee_id | entity_id | party_dependent_id | (relation, from PartyDependent) | state  |
			| -- | ----------- | --------- | ------------------ | ------------------------------- | ------ |
			| 1  | 7           | 3         | 1                  | spouse                          | active |
			| 2  | 7           | 3         | 2                  | child                           | active |
			| 3  | 22          | 3         | 3                  | child                           | active |
			| 4  | 44          | 3         | 4                  | spouse                          | active |
			| 5  | 31          | 9         | 5                  | parent                          | active |

	### EmployeeQualification [DIST] -- one row per academic credential; degree scans via DocumentAttachment ('HR:EmployeeQualification')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- credential holder
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- party_qualification_id  -- FK PartyQualification -- 1:1 extension of Party
		- is_verified             -- bool -- HR verified against the original
		- verified_by_employee_id -- FK Employee nullable -- who verified it
		- verified_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | employee_id | entity_id | party_qualification_id | (level, from PartyQualification) | is_verified | verified_by_employee_id | verified_at          | state  |
			| -- | ----------- | --------- | ---------------------- | -------------------------------- | ----------- | ----------------------- | -------------------- | ------ |
			| 1  | 22          | 3         | 1                      | bachelors                        | true        | 7                       | 2021-09-16T08:00:00Z | active |
			| 2  | 44          | 3         | 2                      | masters                          | true        | 7                       | 2020-03-03T08:00:00Z | active |
			| 3  | 7           | 3         | 3                      | bachelors                        | true        | 44                      | 2022-01-11T08:00:00Z | active |
			| 4  | 14          | 7         | 4                      | diploma                          | true        | 7                       | 2024-06-02T08:00:00Z | active |
			| 5  | 31          | 9         | 5                      | tvet_certificate                 | false       | --                      | --                   | active |

	### EmployeeCertification [DIST] -- one row per professional certification or license; expiry reminders ride the Notification engine
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- certification holder
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- party_certification_id  -- FK PartyCertification -- 1:1 extension of Party
		- is_verified             -- bool -- HR verified against the original
		- verified_by_employee_id -- FK Employee nullable -- who verified it
		- verified_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | employee_id | entity_id | party_certification_id | (certification, from PartyCertification) | is_verified | verified_by_employee_id | verified_at          | state  |
			| -- | ----------- | --------- | ---------------------- | ---------------------------------------- | ----------- | ----------------------- | -------------------- | ------ |
			| 1  | 22          | 3         | 1                      | acca                                     | true        | 7                       | 2021-09-16T08:00:00Z | active |
			| 2  | 44          | 3         | 2                      | cpa                                      | true        | 7                       | 2020-03-03T08:00:00Z | active |
			| 3  | 14          | 7         | 3                      | food_handler                             | true        | 7                       | 2024-06-25T08:00:00Z | active |
			| 4  | 31          | 9         | 4                      | procurement_specialist                   | true        | 7                       | 2025-02-18T08:00:00Z | active |
			| 5  | 7           | 3         | 5                      | hr_professional                          | false       | --                      | --                   | active |

	### EmployeeExperience [DIST] -- one row per prior job at an external employer; reference letters via DocumentAttachment ('HR:EmployeeExperience')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- the person whose history this is
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- party_experience_id     -- FK PartyExperience -- 1:1 extension of Party
		- is_verified             -- bool -- background check confirmed
		- verified_at             -- timestamp nullable
		- verified_by_employee_id -- FK Employee nullable -- who ran the check
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		- is_relevant			  -- bool DEFAULT TRUE -- flagged by HR as relevant to the current role; used in staffing and succession analysis
		> examples:
			| id | employee_id | entity_id | party_experience_id | (employer, from PartyExperience) | is_verified | verified_by_employee_id | is_relevant | state  |
			| -- | ----------- | --------- | ------------------- | -------------------------------- | ----------- | ----------------------- | ----------- | ------ |
			| 1  | 22          | 3         | 1                   | 930 (Zemen Bank)                 | true        | 7                       | true        | active |
			| 2  | 44          | 3         | 2                   | 931 (Awash Bank)                 | true        | 7                       | true        | active |
			| 3  | 44          | 3         | 3                   | 932 (Dashen Bank)                | true        | 7                       | false       | active |
			| 4  | 14          | 7         | 4                   | 933 (Shoa Supermarket)           | true        | 7                       | true        | active |
			| 5  | 31          | 9         | 5                   | 934 (Kuriftu Resorts)            | false       | --                      | true        | active |

	### EmployeeSkill [DIST] -- one row per skill an employee holds; feeds staffing, succession and training-gap analysis
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- skill holder
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- party_skill_id          -- FK PartySkill -- 1:1 extension of Party
		- assessed_by_employee_id -- FK Employee nullable -- manager who validated the level
		- assessed_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | employee_id | entity_id | party_skill_id | (skill, from PartySkill) | assessed_by_employee_id | assessed_at          | state  |
			| -- | ----------- | --------- | -------------- | ------------------------ | ----------------------- | -------------------- | ------ |
			| 1  | 22          | 3         | 1              | ifrs_reporting           | 44                      | 2026-01-15T08:00:00Z | active |
			| 2  | 22          | 3         | 2              | peachtree                | 44                      | 2026-01-15T08:00:00Z | active |
			| 3  | 14          | 7         | 3              | pos_operation            | 7                       | 2026-02-01T08:00:00Z | active |
			| 4  | 31          | 9         | 4              | supplier_negotiation     | 44                      | 2026-03-10T08:00:00Z | active |
			| 5  | 7           | 3         | 5              | labour_law_compliance    | --                      | --                   | active |

	### EmployeeLanguage [DIST] -- one row per language an employee speaks; joins JobPositionRequirement language rows for multilingual staffing
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- language holder
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- party_language_id       -- FK PartyLanguage -- 1:1 extension of Party
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | employee_id | entity_id | party_language_id | (language, from PartyLanguage) | state  |
			| -- | ----------- | --------- | ----------------- | ------------------------------ | ------ |
			| 1  | 22          | 3         | 1                 | amharic                        | active |
			| 2  | 22          | 3         | 2                 | english                        | active |
			| 3  | 14          | 7         | 3                 | afaan_oromo                    | active |
			| 4  | 14          | 7         | 4                 | amharic                        | active |
			| 5  | 44          | 3         | 5                 | english                        | active |

	### EmployeeCompliance [DIST] -- one row per statutory or company compliance item (Fayda verification, pension registration, permits)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- the person the item applies to
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- item_type_lookup_value_id -- FK LookupValue (COMPLIANCE_ITEM_TYPE: fayda_verification | pension_registration | work_permit | medical_check | police_clearance | professional_license | tax_registration)
		- status_lookup_value_id  -- FK LookupValue (COMPLIANCE_STATUS: pending | valid | expiring | expired | waived | rejected) -- item progress
		- reference_number        -- text nullable -- permit / clearance number
		- issued_date             -- date nullable
		- expiry_date             -- date nullable -- expiry alerting via the Notification engine
		- verified_by_employee_id -- FK Employee nullable -- who verified the item
		- verified_at             -- timestamp nullable
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | employee_id | item_type            | status  | reference_number | issued_date | expiry_date | verified_by | state  |
			| -- | ----------- | -------------------- | ------- | ---------------- | ----------- | ----------- | ----------- | ------ |
			| 1  | 7           | fayda_verification   | valid   | FYD-33018820714  | 2025-05-02  | --          | 44          | active |
			| 2  | 14          | fayda_verification   | valid   | FYD-90114522208  | 2025-08-15  | --          | 7           | active |
			| 3  | 14          | pension_registration | valid   | PN-204415        | 2024-06-20  | --          | 7           | active |
			| 4  | 31          | pension_registration | pending | --               | --          | --          | --          | active |
			| 5  | 22          | medical_check        | expiring| MC-2025-4411     | 2025-09-01  | 2026-09-01  | 7           | active |

	### EmployeeBankAccount [DIST] -- one row per salary disbursement account; banks are core PaymentProviders
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- account owner
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- payment_provider_id     -- FK PaymentProvider -- the bank (CBE, Awash, Dashen...)
		- account_number          -- text
		- account_holder_name     -- text -- as printed by the bank (may differ from Party casing)
		- branch_name             -- text nullable -- "CBE Bole Medhanealem"
		- currency_id             -- FK Currency -- ETB
		- is_primary              -- bool -- payroll pays the primary account; one primary per employee
		- split_percent           -- numeric(5,2) nullable -- multi-account split share; NULL = remainder
		- account_state_lookup_value_id -- FK LookupValue (BANK_ACCOUNT_STATE: pending_verification | verified | rejected | closed)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | employee_id | payment_provider_id | account_number | account_holder_name | branch_name          | currency | is_primary | split_percent | account_state | state  |
			| -- | ----------- | ------------------- | -------------- | ------------------- | -------------------- | -------- | ---------- | ------------- | ------------- | ------ |
			| 1  | 7           | 4                   | 1000234511209  | Selamawit Bekele    | CBE Meskel Square    | ETB      | true       | --            | verified      | active |
			| 2  | 14          | 4                   | 1000512230871  | Abebe Kebede        | CBE Bole Medhanealem | ETB      | true       | --            | verified      | active |
			| 3  | 22          | 7                   | 0134420115523  | Tigist Alemu        | Awash 22 Mazoria     | ETB      | true       | 80.00         | verified      | active |
			| 4  | 22          | 4                   | 1000778341220  | Tigist Alemu        | CBE Piassa           | ETB      | false      | 20.00         | verified      | active |
			| 5  | 44          | 7                   | 0139012254470  | Rahel Girma         | Awash Bole           | ETB      | true       | --            | verified      | active |

	### EmployeeEmergencyContact [DIST] -- one row per person to call in an emergency; contact identity lives on Party
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- the employee the contact belongs to
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- party_id                -- FK Party -- contact identity (name / phones)
		- relation_lookup_value_id -- FK LookupValue (EMERGENCY_RELATION: spouse | parent | child | sibling | relative | friend | colleague)
		- priority                -- integer -- 1 = call first
		- address                 -- jsonb nullable -- { city, sub_city, kebele }
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | employee_id | party_id | relation | priority | address (city)  | state  |
			| -- | ----------- | -------- | -------- | -------- | --------------- | ------ |
			| 1  | 7           | 611      | spouse   | 1        | Addis Ababa     | active |
			| 2  | 7           | 615      | sibling  | 2        | Addis Ababa     | active |
			| 3  | 14          | 618      | parent   | 1        | Addis Ababa     | active |
			| 4  | 22          | 620      | spouse   | 1        | Addis Ababa     | active |
			| 5  | 31          | 622      | parent   | 1        | Bahir Dar       | active |

	### EmployeeDisability [DIST] -- one row per disability an employee lives with; drives workplace accommodation and statutory affirmative-action reporting  -- (Q8 -- confirm new table)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- the person concerned
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- disability_type_lookup_value_id -- FK LookupValue (DISABILITY_TYPE: visual | hearing | physical | speech | intellectual | psychosocial | multiple | other)
		- severity_lookup_value_id -- FK LookupValue (DISABILITY_SEVERITY: mild | moderate | severe) nullable
		- is_self_declared -- bool -- true = employee declared, false = medically certified
		- certificate_reference -- text nullable -- medical board / MOLS certificate number
		- affects_work_capacity -- bool -- feeds shift assignment and job placement rules
		- is_confidential -- bool default true -- gates visibility to HR roles only
		- accommodation_notes     -- jsonb nullable -- adjustment granted (ground-floor desk, screen reader, flexible hours)
		- is_verified             -- bool -- HR verified against the disability certificate
		- verified_by_employee_id -- FK Employee nullable -- who verified it
		- verified_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: certificate scan via DocumentAttachment ('HR:EmployeeDisability'); JobPositionRequirement.physical_ability is the demand side of the same fact.
		> examples:
			| id | employee_id | disability_type | severity | is_verified | verified_by | state  |
			| -- | ----------- | --------------- | -------- | ----------- | ----------- | ------ |
			| 1  | 31          | visual          | mild     | true        | 7           | active |
			| 2  | 14          | hearing         | moderate | true        | 7           | active |
			| 3  | 22          | physical        | mild     | false       | --          | active |
			| 4  | 44          | speech          | mild     | true        | 7           | active |
			| 5  | 7           | physical        | severe   | true        | 44          | active |

	### EmploymentContract [DIST] -- one row per legal employment contract; signed PDF via DocumentAttachment ('HR:EmploymentContract')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- contract number via DocumentSequence (CTR-2026-0031)
		- employee_id             -- FK Employee -- contracted person
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- employing legal entity
		- contract_type_lookup_value_id -- FK LookupValue (CONTRACT_TYPE: indefinite | fixed_term | project_based | casual)
		- contract_state_lookup_value_id -- FK LookupValue (CONTRACT_STATE: draft | pending_signature | active | expiring | expired | terminated | renewed)
		- start_date              -- date
		- end_date                -- date nullable -- NULL for indefinite
		- probation_months        -- integer nullable -- Ethiopia's 60-working-day maximum is StatutoryRule data
		- is_working_days_only    -- bool -- true = 5-day workweek, false = 6-day workweek; drives overtime calculations
		- notice_period_days      -- integer nullable -- overrides the StatutoryRule default
		- weekly_hours            -- numeric(5,2) -- e.g. 48.00; the legal weekly ceiling is StatutoryRule data
		- renewed_from_contract_id -- FK EmploymentContract (self) nullable -- renewal chain
		- signed_at               -- timestamp nullable
		- terms                   -- jsonb nullable -- structured special clauses
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | employee_id | entity_id | contract_type | contract_state | start_date | end_date   | probation_months | weekly_hours | renewed_from | state  |
			| -- | ------------- | ----------- | --------- | ------------- | -------------- | ---------- | ---------- | ---------------- | ------------ | ------------ | ------ |
			| 1  | CTR-2022-0007 | 7           | 3         | indefinite    | active         | 2022-01-10 | --         | 2                | 48.00        | --           | active |
			| 2  | CTR-2024-0014 | 14          | 7         | indefinite    | active         | 2024-06-01 | --         | 2                | 48.00        | --           | active |
			| 3  | CTR-2021-0022 | 22          | 3         | indefinite    | active         | 2021-09-15 | --         | 2                | 40.00        | --           | active |
			| 4  | CTR-2026-0031 | 31          | 9         | fixed_term    | active         | 2026-02-17 | 2027-02-16 | 2                | 48.00        | --           | active |
			| 5  | CTR-2020-0044 | 44          | 3         | indefinite    | active         | 2020-03-02 | --         | 3                | 40.00        | --           | active |

	### EmployeeGuarantee [DIST] -- one row per surety standing behind an employee (cash-handling post, loan, sponsored study);
		-- the guarantor is an outsider guaranteeing an employee
		-- the guarantee letter rides DocumentAttachment ('HR:EmployeeGuarantee')  -- (Q8 -- confirm new table)
		-- party forms will be registered even if the fields do not exist in this table
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (GRT-2026-0014)
		- employee_id             -- FK Employee -- the guaranteed person
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- guarantor_party_id      -- FK Party -- guarantor identity (name / phone / tin); never free text
		- relation_lookup_value_id -- FK LookupValue (EMERGENCY_RELATION: spouse | parent | child | sibling | relative | friend | colleague) nullable -- how the guarantor knows the employee
		- guarantor_employer_party_id -- FK Party nullable -- the guarantor's employer, when the surety rests on their employment; the employer is a Party like any other organization
		- guarantor_monthly_income -- numeric(15,4) nullable -- capacity check, ETB
		- purpose_lookup_value_id -- FK LookupValue (GUARANTEE_PURPOSE: cash_handling | loan | study_bond | asset_custody | general)
		- guaranteed_amount       -- numeric(15,4) -- value the guarantor stands behind
		- currency_id             -- FK Currency
		- letter_number           -- text nullable -- reference printed on the guarantee letter
		- letter_date             -- date nullable
		- start_date              -- date
		- end_date                -- date nullable -- NULL = until revoked or released
		- attachment              -- path on assets disk, nullable -- scanned guarantee letter; further files ride DocumentAttachment on the guarantee's Document row
		- guarantee_state_lookup_value_id -- FK LookupValue (GUARANTEE_STATE: draft | active | expired | revoked | released)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: JobPosition.guarantee_required_amount is the demand side; a seat carrying a value is not filled until an active guarantee covers it.
		> examples:
			| id | code          | employee_id | guarantor_party_id | purpose       | guaranteed_amount | start_date | end_date   | guarantee_state | state  |
			| -- | ------------- | ----------- | ------------------ | ------------- | ----------------- | ---------- | ---------- | --------------- | ------ |
			| 1  | GRT-2024-0011 | 14          | 941                | cash_handling | 50000.0000        | 2024-06-01 | --         | active          | active |
			| 2  | GRT-2026-0014 | 31          | 942                | loan          | 30000.0000        | 2026-03-01 | 2027-03-01 | active          | active |
			| 3  | GRT-2025-0009 | 22          | 943                | study_bond    | 85000.0000        | 2025-09-01 | 2027-09-01 | active          | active |
			| 4  | GRT-2023-0004 | 44          | 944                | asset_custody | 120000.0000       | 2023-01-05 | 2026-01-05 | expired         | active |
			| 5  | GRT-2022-0002 | 7           | 945                | general       | 20000.0000        | 2022-01-10 | --         | revoked         | active |

	-- ### EmployeeGuaranteeAttachment -- removed: supporting files (guarantor ID copy,
	-- salary letter, title deed) ride DocumentAttachment on EmployeeGuarantee's core Document row
	-- (see the STANDARD COLUMNS attachment note); the letter scan stays EmployeeGuarantee.attachment.

	### GuaranteeRevocation [DIST] -- one row per request to withdraw a standing guarantee (legacy revokecollaterals); approving it moves EmployeeGuarantee to guarantee_state = revoked
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_guarantee_id   -- FK EmployeeGuarantee -- the surety being withdrawn
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- requested_date          -- date -- when the guarantor asked to be released
		- reason                  -- jsonb nullable -- why revocation was requested
		- approved_date           -- date nullable -- when HR decided
		- approved_by_user_id     -- FK User nullable -- who decided
		- comment                 -- jsonb nullable -- any comment on the approval or rejection
		- approval_state_lookup_value_id -- FK LookupValue (GUARANTEE_REVOCATION_STATE: pending | approved | rejected) -- the request's decision state
		- document_id             -- FK Document nullable -- the revocation letter
		- revoked_at              -- timestamp nullable -- set on approval; the moment the guarantor stopped standing behind the employee
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: this row is the REQUEST; the guarantee's own guarantee_state is what payroll and job-placement rules read.
		> examples:
			| id | employee_guarantee_id | requested_date | approval | approved_date | approved_by_user_id | revoked_at           | state  |
			| -- | --------------------- | -------------- | -------- | ------------- | ------------------- | -------------------- | ------ |
			| 1  | 5                     | 2026-02-10     | approved | 2026-02-18    | 12                  | 2026-02-18T09:00:00Z | active |
			| 2  | 1                     | 2026-06-01     | pending  | --            | --                  | --                   | active |
			| 3  | 2                     | 2026-05-14     | rejected | 2026-05-20    | 12                  | --                   | active |
			| 4  | 3                     | 2026-07-02     | pending  | --            | --                  | --                   | active |
			| 5  | 4                     | 2025-12-20     | approved | 2025-12-28    | 9                   | 2025-12-28T11:30:00Z | active |

	### Collateral [DIST] -- one row per case of an EMPLOYEE standing as guarantor for an outsider (legacy collaterals); the mirror image of EmployeeGuarantee
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (COL-2026-0007)
		- employee_id             -- FK Employee -- the employee acting as guarantor
		- beneficiary_party_id    -- FK Party -- who is being guaranteed
		- name_prefix_lookup_value_id -- FK LookupValue (NAME_PREFIX: ato | woizero | woizerit | dr | prof | eng | other) -- honorific printed on the letter
		- organization_party_id   -- FK Party -- the organization requesting the guarantee (bank, school, employer)
		- admin_unit_id           -- FK AdminUnit nullable -- where the requesting organization sits
		- purpose_lookup_value_id -- FK LookupValue (GUARANTEE_PURPOSE: cash_handling | loan | study_bond | asset_custody | general)
		- money_amount            -- numeric(15,4) -- value the employee stands behind
		- currency_id             -- FK Currency
		- remark                  -- jsonb nullable -- the requester's stated context
		- comment                 -- jsonb nullable -- HR's note on the decision
		- document_id             -- FK Document nullable -- the issued guarantee letter
		- status_lookup_value_id  -- FK LookupValue (COLLATERAL_STATUS: requested | approved | rejected | finished)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: an employee's exposure across open collaterals is checked before a new one is approved; the ceiling is entity policy, not a column here.
		> examples:
			| id | code          | employee_id | beneficiary_party_id | organization_party_id  | purpose | money_amount | status    | entity_id | state  |
			| -- | ------------- | ----------- | -------------------- | ---------------------- | ------- | ------------ | --------- | --------- | ------ |
			| 1  | COL-2026-0007 | 22          | 971 (Meron Tadesse)  | 980 (Awash Bank)       | loan    | 60000.0000   | approved  | 3         | active |
			| 2  | COL-2026-0008 | 44          | 972 (Yonas Bekele)   | 981 (CBE)              | loan    | 150000.0000  | requested | 3         | active |
			| 3  | COL-2026-0009 | 7           | 973 (Sara Alemu)     | 982 (Unity University) | study_bond | 40000.0000| approved  | 3         | active |
			| 4  | COL-2025-0010 | 14          | 974 (Girma Hailu)    | 980 (Awash Bank)       | general | 25000.0000   | rejected  | 7         | active |
			| 5  | COL-2025-0011 | 31          | 975 (Lily Worku)     | 983 (Zemen Bank)       | loan    | 80000.0000   | finished  | 9         | active |

	### CollateralApproval [LINE] -- one row per approval step taken on a Collateral request; the chain itself is core Workflow
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- collateral_id           -- FK Collateral -- parent request
		- workflow_step_id        -- FK WorkflowStep -- the step in the approval workflow
		- remarks                 -- jsonb nullable -- what the approver considered
		- approval_state_lookup_value_id -- FK LookupValue (COLLATERAL_APPROVAL_STATE: pending | approved | rejected) -- this step's verdict
		- approved_at             -- timestamp nullable
		- user_id                 -- FK User -- who recorded the step (the acting approver)
		- state                   -- active / inactive
		> examples:
			| id | collateral_id | workflow_step_id | approval_state | approved_at          | state  |
			| -- | ------------- | ---------------- | --------- | -------------------- | ------ |
			| 1  | 1             | 41               | approved  | 2026-03-04T08:10:00Z | active |
			| 2  | 1             | 42               | approved  | 2026-03-05T09:00:00Z | active |
			| 3  | 2             | 41               | pending   | --                   | active |
			| 4  | 4             | 41               | rejected  | 2025-11-12T10:20:00Z | active |
			| 5  | 5             | 42               | approved  | 2025-12-30T14:45:00Z | active |


#3. HR -- Organization structure

	## lookups first used in this section
		- ORG_STRUCTURE_STATE         : draft | active | superseded
		  -- multi-entity workforce (section 11)
		- ORGANIZATION_UNIT_TYPE      : open catalogue -- department | section | team | unit | division | region | project_office | branch | office | outlet | cluster | board | committee | other
		  -- single canonical type used everywhere an org-unit kind is needed (OrganizationUnit, ClientAssignment, etc.)
		  -- each tenant names its own levels; platform seeds the above values, tenants extend
		- POSITION_CATEGORY           : management | non_management | executive
		- POSITION_REQUIREMENT_TYPE   : qualification | certification | skill | experience_years | language | age_min | age_max | physical_ability | driving_license
		- HEADCOUNT_BUDGET_STATE      : draft | approved | active | closed

	### OrgStructure [DIST] -- one row per named hierarchy instance; a restructure creates a successor row instead of editing history
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (CORP-2026, REGIONAL-2026)
		- name                    -- jsonb (localized)
		- description             -- jsonb nullable
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant
		- structure_state_lookup_value_id -- FK LookupValue (ORG_STRUCTURE_STATE: draft | active | superseded)
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current; a restructure stamps this and activates the successor
		- superseded_by_id        -- FK OrgStructure (self) nullable -- forward link across restructures; past hierarchies stay queryable forever
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | name (en)              | entity_id | structure_state | effective_from | effective_to | superseded_by_id | state  |
			| -- | ------------- | ---------------------- | --------- | --------------- | -------------- | ------------ | ---------------- | ------ |
			| 1  | CORP-2026     | Corporate 2026         | 1         | active          | 2026-01-01     | --           | --               | active |
			| 2  | REGIONAL-2026 | Regional View 2026     | 1         | active          | 2026-01-01     | --           | --               | active |
			| 3  | CORP-2025     | Corporate 2025         | 1         | superseded      | 2025-01-01     | 2025-12-31   | 1                | active |
			| 4  | HOTEL-2026    | Property Structure     | 7         | active          | 2026-01-01     | --           | --               | active |
			| 5  | CORP-2027     | Corporate 2027 (+CTO)  | 1         | draft           | 2027-01-01     | --           | --               | active |

	### OrganizationUnit [DIST] -- one row per parent-child placement of a unit inside a structure; effective-dated so history survives restructures
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- code                    -- human-readable business code, unique per entity
		- name                    -- jsonb (localized) -- "HR", "Finance", "Payroll", "East Region"
		- description             -- jsonb nullable
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id 			  -- FK Entity -- owning tenant/branch
		- organization_unit_type_lookup_value_id -- FK LookupValue (ORGANIZATION_UNIT_TYPE: department | section | team | unit | division | region | project_office | branch | office | outlet | cluster | board | committee | other)
		- org_structure_id        -- FK OrgStructure -- the hierarchy the edge belongs to
		- parent_id    			  -- FK OrganizationUnit (self) nullable -- NULL = root of this structure
		- order                   -- integer -- sibling display order
		- is_visible              -- bool -- shown on the org diagram
		- path                    -- text -- materialized ancestor path (1/2/6) for subtree queries without recursion
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current -- UNIQUE (org_structure_id, id) WHERE effective_to IS NULL (one current parent per unit per structure)
		- user_id                 -- FK User -- who created the row  -- new
		- state                   -- active / inactive
		  -- note: this row is BOTH the unit and its placement in ONE structure (org_structure_id);
		  -- activating a successor OrgStructure creates NEW unit rows, so effecting a restructure
		  -- must carry every referencing FK (JobPosition, HeadcountBudget, TimesheetEntry,
		  -- ClearanceItem, Payslip, TrainingNeed, PerformanceGoal, ClientAssignment,
		  -- AnnouncementTarget, CompensationBudget) over to the successor units.
		> examples:
			| id | code       | name (en)    | org_structure_id | organization_unit_type | parent_id       | order | path  | is_visible | effective_from | effective_to | state  |
			| -- | ---------- | ------------ | ---------------- | ---------------------- | --------------- | ----- | ----- | ---------- | -------------- | ------------ | ------ |
			| 1  | OU-HR      | HR           | 1                | department             | --              | 1     | 1     | true       | 2026-01-01     | --           | active |
			| 2  | OU-FIN     | Finance      | 1                | department             | --              | 2     | 2     | true       | 2026-01-01     | --           | active |
			| 6  | OU-PAY     | Payroll      | 1                | section                | 2 (Finance)     | 1     | 2/6   | true       | 2026-01-01     | --           | active |
			| 8  | OU-EAST    | East Region  | 2                | region                 | --              | 1     | 8     | true       | 2026-01-01     | --           | active |
			| 9  | OU-PAY-E   | Payroll East | 2                | section                | 8 (East Region) | 1     | 8/9   | true       | 2026-01-01     | --           | active |

	### OrganizationUnitHead [DIST] -- one row per period an employee heads an organization unit; the unit's manager over time, independent of who sits in which seat
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- organization_unit_id    -- FK OrganizationUnit -- the unit being headed
		- employee_id             -- FK Employee -- the head
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- start_date              -- date -- when the appointment took effect
		- end_date                -- date nullable -- NULL = current head
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: one current head per unit (end_date IS NULL); an acting head is a second row with its own window.
		> examples:
			| id | organization_unit_id | employee_id | entity_id | start_date | end_date   | state  |
			| -- | -------------------- | ----------- | --------- | ---------- | ---------- | ------ |
			| 1  | 1 (HR)               | 7           | 3         | 2022-01-10 | --         | active |
			| 2  | 2 (Finance)          | 44          | 3         | 2020-03-02 | --         | active |
			| 3  | 6 (Payroll)          | 22          | 3         | 2021-09-15 | --         | active |
			| 4  | 8 (East Region)      | 31          | 9         | 2026-02-17 | --         | active |
			| 5  | 6 (Payroll)          | 44          | 3         | 2021-01-01 | 2021-09-14 | active |

	### SalaryMatrix [DIST] -- one effective-dated grade/step grid per entity; a successor row supersedes it (Q8 -- confirm new table)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- the tenant/branch this matrix applies to
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current; a new matrix stamps this and activates the successor
		- number_of_steps         -- integer -- prescriptive grid size: every JobGrade in this matrix defines exactly this many JobGradeStep rows
		- currency_id             -- FK Currency -- ETB
		- is_default 			  -- bool -- new grades attach to this matrix by default
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | entity_id | effective_from | effective_to | number_of_steps | currency | is_default | state  |
			| -- | --------- | -------------- | ------------ | --------------- | -------- | ---------- | ------ |
			| 1  | 1         | 2020-01-01     | 2023-06-30   | 5               | ETB      | false      | active |
			| 2  | 1         | 2023-07-01     | 2026-07-07   | 5               | ETB      | false      | active |
			| 3  | 1         | 2026-07-08     | --           | 7               | ETB      | true       | active |
			| 4  | 7         | 2026-07-08     | --           | 5               | ETB      | true       | active |
			| 5  | 9         | 2026-07-08     | --           | 5               | ETB      | true       | active |

	### JobGrade [DIST] -- one row per pay grade/band; salary-range guardrails live here, actual pay on EmployeeSalary
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (C1, B2, A3)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch (grades are entity-owned: their SalaryMatrix is per-entity)
		- level                   -- integer -- ordering; higher = more senior
		- base_salary              -- numeric(15,4) -- band floor, ETB -- column renamed
		- ceiling_salary              -- numeric(15,4) -- band ceiling -- column renamed
		- salary_matrix_id         -- FK SalaryMatrix
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code | name (en)  | entity_id | level | base_salary | ceiling_salary | salary_matrix_id | state  |
			| -- | ---- | ---------- | --------- | ----- | ----------- | -------------- | ---------------- | ------ |
			| 3  | C1   | Grade C1   | 1         | 3     | 5000.0000   | 9000.0000      | 3                | active |
			| 4  | C2   | Grade C2   | 1         | 4     | 8000.0000   | 13000.0000     | 3                | active |
			| 5  | B2   | Grade B2   | 1         | 5     | 11000.0000  | 18000.0000     | 3                | active |
			| 6  | B1   | Grade B1   | 1         | 6     | 17000.0000  | 27000.0000     | 3                | active |
			| 7  | A3   | Grade A3   | 1         | 7     | 26000.0000  | 40000.0000     | 3                | active |

	### JobGradeStep [LINE] -- one row per discrete step inside a grade's ladder; enables "increment by scale" movements
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- job_grade_id                -- FK JobGrade -- UNIQUE (job_grade_id, step_number)
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- cache/denormalized from Grade for query speed
		- step_number             -- integer -- 1..N, monotonically increasing (1 = entry, N = top of grade)
		- amount                  -- numeric(15,4) -- monthly base amount at this step, ETB
		- increment_years         -- integer nullable -- service years required at the previous step before advancing to this one
		- description             -- jsonb nullable -- "Entry step" / "Long-service step"
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: EmployeeMovement references the chosen step on grade_change movements.
		> examples:
			| id | job_grade_id | entity_id | step_number | amount     | increment_years | description (en)  | state  |
			| -- | ------------ | --------- | ----------- | ---------- | --------------- | ----------------- | ------ |
			| 1  | 3            | 1         | 1           | 6500.0000  | --              | Entry step        | active |
			| 2  | 3            | 1         | 2           | 7150.0000  | 2               | --                | active |
			| 3  | 3            | 1         | 3           | 7850.0000  | 2               | Long-service step | active |
			| 4  | 5            | 1         | 1           | 12000.0000 | --              | Entry step        | active |
			| 5  | 5            | 1         | 2           | 13500.0000 | 2               | --                | active |

	### JobTitle [DIST] -- one row per ROLE name in the catalogue ("HR Officer", "Senior Cashier"); reusable across units and grades, the seat itself is JobPosition
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- category_lookup_value_id -- FK LookupValue (POSITION_CATEGORY: management | non_management | executive) -- drives OT-exemption and benefit-eligibility policy
		- code                    -- human-readable business code, unique per entity (JT-HR-OFF, JT-SR-CSH)
		- name                    -- jsonb (localized) -- "HR Officer", "Senior Cashier"
		- description             -- jsonb (localized) nullable -- job summary
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- icon_id                 -- FK Icon nullable
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code        | name (en)            | category       | entity_id | icon_id | status       | state  |
			| -- | ----------- | -------------------- | -------------- | --------- | ------- | ------------ | ------ |
			| 12 | JT-HR-OFF   | HR Officer           | non_management | 3         | 21      | acceptForAll | active |
			| 24 | JT-SR-CSH   | Senior Cashier       | non_management | 7         | 22      | acceptForAll | active |
			| 31 | JT-FIN-ACC  | Financial Accountant | non_management | 3         | 23      | acceptForAll | active |
			| 40 | JT-PRC-OFF  | Procurement Officer  | non_management | 9         | 24      | acceptForAll | active |
			| 30 | JT-FIN-MGR  | Finance Manager      | management     | 3         | 25      | acceptForAll | active |

	### JobLevel [DIST] -- one row per seniority level in the career ladder (Junior, Officer, Senior, Lead); JobPosition combines it with a title and a grade
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (LVL-JR, LVL-SR)
		- name                    -- jsonb (localized) -- "Junior", "Senior", "Lead"
		- description             -- jsonb (localized) nullable -- what the level means in this entity
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state 				 -- active / inactive
		> examples:
			| id | code       | name (en)  | entity_id | status       | state  |
			| -- | ---------- | ---------- | --------- | ------------ | ------ |
			| 1  | LVL-JR     | Junior     | 1         | acceptForAll | active |
			| 2  | LVL-OFF    | Officer    | 1         | acceptForAll | active |
			| 3  | LVL-SR     | Senior     | 1         | acceptForAll | active |
			| 4  | LVL-LEAD   | Lead       | 1         | acceptForAll | active |
			| 5  | LVL-MGR    | Manager    | 1         | acceptForAll | active |

	### JobPosition [DIST] -- one row per SEAT: a JobTitle placed in one OrganizationUnit at one JobGrade and JobLevel; this is what employees are assigned to, moved between and offered
		- id                      -- primary key
		- uuid					-- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity, auto-generated on create  -- new
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- job_level_id             -- FK JobLevel -- the level of the seat
		- job_title_id             -- FK JobTitle -- the seat being filled
		- organization_unit_id      -- FK OrganizationUnit -- the department/division/branch the seat sits in
		- job_grade_id            -- FK JobGrade -- pay band of the seat
		- reports_to_position_id  -- FK JobPosition (self) nullable -- reporting line
		- authorized_headcount    -- integer -- approved seat count for this position in its unit
		- is_key_position         -- bool -- succession coverage reports flag key positions without a successor
		- guarantee_required_amount -- numeric(15,4) nullable -- surety the seat-holder must post before taking the post (cashier, storekeeper); covered by an active EmployeeGuarantee
		- user_id                 -- FK User -- who created the row  -- new
		- state 				 -- active / inactive
		> examples:
			| id | entity_id | job_title_id           | job_level_id | organization_unit_id | job_grade_id | reports_to_position_id | authorized_headcount | is_key_position | guarantee_required_amount | state  |
			| -- | --------- | ---------------------- | ------------ | -------------------- | ------------ | ---------------------- | -------------------- | --------------- | ------------------------- | ------ |
			| 12 | 3         | 12 (HR Officer)        | 2            | 1 (HR)               | 5            | 11                     | 2                    | false           | --                        | active |
			| 24 | 7         | 24 (Senior Cashier)    | 3            | 3 (Sales)            | 3            | 20                     | 4                    | false           | 50000.0000                | active |
			| 30 | 3         | 30 (Finance Manager)   | 5            | 2 (Finance)          | 7            | --                     | 1                    | true            | --                        | active |
			| 31 | 3         | 31 (Financial Account.)| 2            | 6 (Payroll)          | 5            | 30                     | 3                    | false           | --                        | active |
			| 40 | 9         | 40 (Procurement Off.)  | 2            | 4 (Procurement)      | 3            | 38                     | 2                    | false           | 20000.0000                | active |

	### JobPositionRequirement [LINE] -- one row per requirement on a position; drives recruitment matching and succession gap analysis
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- job_position_id             -- FK JobPosition -- the seat being specified
		- requirement_type_lookup_value_id -- FK LookupValue (POSITION_REQUIREMENT_TYPE: qualification | certification | skill | experience_years | language | age_min | age_max | physical_ability | driving_license)
		- description             -- jsonb (localized) -- "BSc Accounting", "Amharic fluent", "Category B driving license"
		- required_lookup_value_id -- FK LookupValue nullable -- the catalogue value required (SKILL_CATALOG / CERTIFICATION_CATALOG / LANGUAGE_CATALOG); joins PartySkill.skill_lookup_value_id for gap analysis
		- field_of_study_id       -- FK FieldOfStudy nullable -- for qualification requirements; joins PartyQualification.field_of_study_id
		- min_value               -- numeric(6,2) nullable -- threshold for years / age / proficiency level
		- max_value               -- numeric(6,2) nullable -- threshold for age / proficiency level
		- is_mandatory            -- bool -- hard filter (must have) vs preferred (nice to have)
		- weight                  -- numeric(5,2) nullable -- 0-100, for scoring candidates against requirements
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | job_position_id | requirement_type  | description (en)              | min_value | max_value | is_mandatory | weight | state  |
			| -- | --------------- | ----------------- | ----------------------------- | --------- | --------- | ------------ | ------ | ------ |
			| 1  | 31              | qualification     | BSc Accounting / Finance      | --        | --        | true         | 30.00  | active |
			| 2  | 31              | experience_years  | 3+ years in a finance role    | 3.00      | --        | true         | 25.00  | active |
			| 3  | 31              | skill             | Peachtree / QuickBooks        | 3.00      | --        | true         | 20.00  | active |
			| 4  | 31              | language          | Amharic fluent + English B2   | --        | --        | true         | 15.00  | active |
			| 5  | 31              | certification     | ACCA / CPA (preferred)        | --        | --        | false        | 10.00  | active |

	### HeadcountBudget [DIST] -- one row per approved-seat budget (position or department) per fiscal period; the hiring approval gate
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- organization_unit_id    -- FK OrganizationUnit nullable -- organization-level budget (roll-up)
		- fiscal_year             -- integer -- Ethiopian FY end year in GC (2027 = FY2019 EC = Hamle 2018 to Sene 2019 EC)
		- period_start            -- date
		- period_end              -- date
		- filled_headcount        -- integer -- cache/denormalized; recomputed nightly and on hire/separation
		- approved_headcount      -- integer -- ceiling; JobRequisition approval checks (filled + open_requisitions) < approved_headcount
		- open_requisitions       -- integer -- cache/denormalized; active JobRequisitions consuming this budget: in-progress vacancy requests
		- annual_budget_amount    -- numeric(15,4) nullable -- rolled-up salary budget for the headcount
		- currency_id             -- FK Currency nullable
		- budget_state_lookup_value_id -- FK LookupValue (HEADCOUNT_BUDGET_STATE: draft | approved | active | closed)
		- approved_by_employee_id -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: two gates coexist -- JobPosition.authorized_headcount is the structural
		  -- establishment ceiling per seat; this row is the fiscal-period money/headcount gate.
		  -- JobRequisition approval checks THIS table; effecting the hire movement checks the
		  -- seat's authorized_headcount.
		> examples:
			| id | entity_id | organization_unit_id | fiscal_year | approved_headcount | filled_headcount | open_requisitions | annual_budget_amount | budget_state | state  |
			| -- | --------- | -------------------- | ----------- | ------------------ | ---------------- | ----------------- | -------------------- | ------------ | ------ |
			| 1  | 7         | 3                    | 2027        | 12                 | 10               | 2                 | 936000.0000          | active       | active |
			| 2  | 3         | 2                    | 2027        | 8                  | 7                | 1                 | 1152000.0000         | active       | active |
			| 3  | 3         | 1                    | 2027        | 4                  | 3                | 0                 | 720000.0000          | active       | active |
			| 4  | 9         | 3                    | 2027        | 6                  | 4                | 0                 | 468000.0000          | approved     | active |
			| 5  | 7         | 5                    | 2027        | 5                  | 4                | 0                 | 900000.0000          | active       | active |


#4. HR -- Work calendar and shifts

	## lookups first used in this section
		- HOLIDAY_TYPE                : public | religious | company
		- CALENDAR_DAY_TYPE           : working | weekend | holiday | half_day
		- SHIFT_CATEGORY              : fixed | rotating | split | night | flexible
		- SHIFT_ASSIGNMENT_STATE      : planned | published | swapped | cancelled
		  -- distinct from Sales' SHIFT_ASSIGNMENT_STATUS (POS session roster) -- two deliberate vocabularies; keep the codes distinct
		- SHIFT_SWAP_STATE            : requested | accepted | approved | rejected | cancelled

	### Holiday [REF] -- one row per holiday occurrence (Ethiopian public + religious + company); applied to calendars via WorkCalendarDay
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (GENNA, FASIKA, ENKUTATASH)
		- name                    -- jsonb (localized) -- { en: "Ethiopian Christmas", am: "Genna" }
		- holiday_type_lookup_value_id -- FK LookupValue (HOLIDAY_TYPE: public | religious | company)
		- entity_id               -- FK Entity nullable -- NULL = national seed set
		- date                    -- date -- occurrence for the year; movable feasts get one row per year
		- is_recurring            -- bool -- fixed Gregorian date that repeats every year (Genna, Enkutatash); movable feasts (Fasika, Eid) get a fresh row per year
		- is_recurring_after_days -- !!! 365 /annualy 30/monthly 7/weekly
		- is_paid                 -- bool -- paid public holiday; drives the public_holiday overtime rate
		- is_system               -- platform-seeded row
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		- admin_unit_id           -- FK AdminUnit nullable -- regional / state observance that is not national; NULL = applies across the entity
		> examples:
			| id | code       | name (en)              | holiday_type | entity_id | date       | recurring | is_paid | state  |
			| -- | ---------- | ---------------------- | ------------ | --------- | ---------- | --------- | ------- | ------ |
			| 1  | GENNA      | Ethiopian Christmas    | religious    | --        | 2026-01-07 | true      | true    | active |
			| 2  | FASIKA     | Ethiopian Easter       | religious    | --        | 2026-04-12 | false     | true    | active |
			| 3  | ENKUTATASH | Ethiopian New Year     | public       | --        | 2026-09-11 | true      | true    | active |
			| 4  | MESKEL     | Finding of True Cross  | religious    | --        | 2026-09-27 | true      | true    | active |
			| 5  | HLT-DAY    | Haleta Foundation Day  | company      | 1         | 2026-11-05 | true      | true    | active |

	### WorkCalendar [REF] -- one row per named working-time calendar; an entity may run several (office vs factory vs hotel)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (CAL-OFFICE, CAL-FACTORY)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- entity_id               -- FK Entity nullable -- NULL = platform template
		- fiscal_year_start_month -- integer -- 7 = July; the Ethiopian FY (Hamle 1 ~ Jul 8) is data, not schema
		- fiscal_year_start_day   -- integer -- Gregorian day-of-month of Hamle 1 (8, or 9 after an EC leap year)
		- week_start_day          -- integer -- 1 = Monday
		- default_daily_hours     -- numeric(4,2) -- 8.00
		- default_weekly_hours    -- numeric(5,2) -- 48.00 retail; office may use 40.00
		- payroll_days_per_month  -- numeric(4,1) default 26 -- daily-rate divisor (basic / this = day rate for absence deduction and proration)
		- is_default              -- one default calendar per entity
		- is_system               -- platform-seeded row
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code        | name (en)         | entity_id | fy_start (m/d) | week_start | daily_hours | weekly_hours | is_default | state  |
			| -- | ----------- | ----------------- | --------- | -------------- | ---------- | ----------- | ------------ | ---------- | ------ |
			| 1  | CAL-OFFICE  | Office Calendar   | 3         | 7/8            | 1          | 8.00        | 40.00        | true       | active |
			| 2  | CAL-RETAIL  | Retail Calendar   | 7         | 7/8            | 1          | 8.00        | 48.00        | true       | active |
			| 3  | CAL-RETAIL2 | Retail Bahir Dar  | 9         | 7/8            | 1          | 8.00        | 48.00        | true       | active |
			| 4  | CAL-SHOP    | Piazza Shop       | 12        | 7/8            | 1          | 8.00        | 48.00        | true       | active |
			| 5  | CAL-TPL-ETH | Ethiopia Template | --        | 7/8            | 1          | 8.00        | 48.00        | false      | active |

	### WorkCalendarWeekday [LINE] -- one row per weekday of a calendar's planned week; the seed WorkCalendarDay generation expands into dates
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- work_calendar_id        -- FK WorkCalendar -- the calendar this week shape belongs to
		- weekday                 -- integer -- ISO 1 = Monday .. 7 = Sunday -- UNIQUE (work_calendar_id, weekday)
		- day_type_lookup_value_id -- FK LookupValue (CALENDAR_DAY_TYPE: working | weekend | holiday | half_day) -- default classification for this weekday
		- planned_hours           -- numeric(4,2) -- 8.00 working, 4.00 half_day, 0.00 weekend
		- state                   -- active / inactive
		> examples:
			| id | work_calendar_id | weekday | day_type | planned_hours | state  |
			| -- | ---------------- | ------- | -------- | ------------- | ------ |
			| 11 | 1 (CAL-OFFICE)   | 5 (Fri) | working  | 8.00          | active |
			| 12 | 1 (CAL-OFFICE)   | 6 (Sat) | weekend  | 0.00          | active |
			| 13 | 1 (CAL-OFFICE)   | 7 (Sun) | weekend  | 0.00          | active |
			| 26 | 2 (CAL-RETAIL)   | 6 (Sat) | working  | 8.00          | active |
			| 27 | 2 (CAL-RETAIL)   | 7 (Sun) | weekend  | 0.00          | active |

	### WorkCalendarDay [LINE] -- one row per calendar date with its day classification; generated per year, then hand-edited
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- entity_id               -- FK Entity nullable -- copied from WorkCalendar (line tenancy); NULL on a platform-template calendar's rows
		- work_calendar_id        -- FK WorkCalendar -- the calendar being classified
		- date                    -- date -- UNIQUE (work_calendar_id, date)
		- day_type_lookup_value_id -- FK LookupValue (CALENDAR_DAY_TYPE: working | weekend | holiday | half_day)
		- holiday_id              -- FK Holiday nullable -- set when day_type = holiday
		- planned_hours           -- numeric(4,2) -- 8.00 working, 4.00 half_day, 0.00 otherwise
		- state                   -- active / inactive
		> examples:
			| id   | work_calendar_id | date       | day_type | holiday_id | planned_hours | state  |
			| ---- | ---------------- | ---------- | -------- | ---------- | ------------- | ------ |
			| 9001 | 2                | 2026-07-06 | working  | --         | 8.00          | active |
			| 9002 | 2                | 2026-07-12 | weekend  | --         | 0.00          | active |
			| 9003 | 2                | 2026-09-11 | holiday  | 3          | 0.00          | active |
			| 9004 | 1                | 2026-09-27 | holiday  | 4          | 0.00          | active |
			| 9005 | 1                | 2026-01-07 | holiday  | 1          | 0.00          | active |

	### Shift [REF] -- one row per daily working window; labour-time construct (POS cashier session shifts stay in Sales)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (SH-MORN, SH-NIGHT)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- entity_id               -- FK Entity nullable -- NULL = platform template
		- category_lookup_value_id -- FK LookupValue (SHIFT_CATEGORY: fixed | rotating | split | night | flexible)
		- start_time              -- time -- 08:00
		- end_time                -- time -- 17:00; falls on the next day when is_overnight
		- is_overnight            -- bool -- end_time is next day
		- break_minutes           -- integer -- unpaid break
		- grace_in_minutes        -- integer -- late tolerance before flagging
		- grace_out_minutes       -- integer -- early-leave tolerance
		- night_hours_from        -- time nullable -- window counted as night work for the night OT rate
		- night_hours_to          -- time nullable
		- icon_id                 -- FK Icon nullable
		- is_system               -- platform-seeded row
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code     | name (en)     | entity_id | category | start | end   | overnight | break_min | grace_in | grace_out | state  |
			| -- | -------- | ------------- | --------- | -------- | ----- | ----- | --------- | --------- | -------- | --------- | ------ |
			| 1  | SH-OFF   | Office Day    | 3         | fixed    | 08:30 | 17:30 | false     | 60        | 15       | 10        | active |
			| 2  | SH-MORN  | Retail Morning| 7         | rotating | 07:00 | 15:00 | false     | 30        | 10       | 10        | active |
			| 3  | SH-EVE   | Retail Evening| 7         | rotating | 14:30 | 22:30 | false     | 30        | 10       | 10        | active |
			| 4  | SH-NIGHT | Night Guard   | 9         | night    | 22:00 | 06:00 | true      | 45        | 15       | 15        | active |
			| 5  | SH-SPLIT | Shop Split    | 12        | split    | 09:00 | 20:00 | false     | 180       | 10       | 10        | active |

	### ShiftPattern [REF] -- one row per repeating shift cycle (e.g. 2 morning, 2 evening, 2 off) assigned to employees
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (PAT-RETAIL-6D)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- entity_id               -- FK Entity nullable -- NULL = platform template
		- cycle_days              -- integer -- pattern length in days; matches the count of ShiftPatternDay rows
		- work_calendar_id        -- FK WorkCalendar -- holiday/weekend source when generating assignments
		- is_system               -- platform-seeded row
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | name (en)           | entity_id | cycle_days | work_calendar_id | state  |
			| -- | ------------- | ------------------- | --------- | ---------- | ---------------- | ------ |
			| 1  | PAT-OFF-5D    | Office Mon-Fri      | 3         | 7          | 1                | active |
			| 2  | PAT-RETAIL-6D | Retail 6-day Rota   | 7         | 7          | 2                | active |
			| 3  | PAT-2M2E2O    | 2 Morn 2 Eve 2 Off  | 7         | 6          | 2                | active |
			| 4  | PAT-GUARD-4C  | Guard 4-day Cycle   | 9         | 4          | 3                | active |
			| 5  | PAT-SHOP-6D   | Piazza Shop 6-day   | 12        | 7          | 4                | active |

	### ShiftPatternDay [LINE] -- one row per slot in a pattern cycle
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- shift_pattern_id        -- FK ShiftPattern -- the cycle the slot belongs to
		- day_index               -- integer -- 1..cycle_days -- UNIQUE (shift_pattern_id, day_index)
		- shift_id                -- FK Shift nullable -- NULL = rest day
		- state                   -- active / inactive
		> examples:
			| id | shift_pattern_id | day_index | shift_id | state  |
			| -- | ---------------- | --------- | -------- | ------ |
			| 1  | 3                | 1         | 2        | active |
			| 2  | 3                | 2         | 2        | active |
			| 3  | 3                | 3         | 3        | active |
			| 4  | 3                | 4         | 3        | active |
			| 5  | 3                | 5         | --       | active |

	### ShiftAssignment [DIST] -- one row per employee x date x shift on the roster; generated from a pattern, then editable and swappable
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- rostered person
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- work location the roster belongs to
		- date                    -- date -- UNIQUE (employee_id, date, shift_id)
		- shift_id                -- FK Shift -- the window worked
		- shift_pattern_id        -- FK ShiftPattern nullable -- generator provenance
		- assignment_state_lookup_value_id -- FK LookupValue (SHIFT_ASSIGNMENT_STATE: planned | published | swapped | cancelled)
		- swapped_with_employee_id -- FK Employee nullable -- counterparty of an approved swap
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row (roster planner)
		- state                   -- active / inactive
		> examples:
			| id    | employee_id | entity_id | date       | shift_id | shift_pattern_id | assignment_state | swapped_with | state  |
			| ----- | ----------- | --------- | ---------- | -------- | ---------------- | ---------------- | ------------ | ------ |
			| 40011 | 14          | 7         | 2026-07-27 | 2        | 3                | published        | --           | active |
			| 40012 | 14          | 7         | 2026-07-28 | 2        | 3                | published        | --           | active |
			| 40013 | 14          | 7         | 2026-07-29 | 3        | 3                | swapped          | 15           | active |
			| 40014 | 14          | 7         | 2026-07-30 | 3        | 3                | published        | --           | active |
			| 40015 | 7           | 3         | 2026-07-27 | 1        | 1                | published        | --           | active |

	### ShiftSwapRequest [DIST] -- one row per roster-swap request; counterpart accepts, supervisor approves, effect stamps both assignments 'swapped'
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (SWP-2026-0031)
		- requester_employee_id   -- FK Employee -- who initiated the swap
		- requester_shift_assignment_id -- FK ShiftAssignment -- the slot being given away
		- counterpart_employee_id -- FK Employee nullable -- NULL = open give-away; any eligible colleague may claim
		- counterpart_shift_assignment_id -- FK ShiftAssignment nullable -- the slot taken in exchange; NULL = one-way cover
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- reason                  -- jsonb nullable
		- swap_state_lookup_value_id -- FK LookupValue (SHIFT_SWAP_STATE: requested | accepted | approved | rejected | cancelled)
		- accepted_at             -- timestamp nullable -- counterpart's consent
		- approved_by_employee_id -- FK Employee nullable -- supervisor
		- approved_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | requester_employee_id | requester_assignment | counterpart_employee_id | counterpart_assignment | swap_state | accepted_at          | approved_at          | state  |
			| -- | ------------- | --------------------- | -------------------- | ----------------------- | ---------------------- | ---------- | -------------------- | -------------------- | ------ |
			| 31 | SWP-2026-0031 | 14                    | 8812                 | 18                      | 8815                   | approved   | 2026-07-18T14:00:00Z | 2026-07-18T16:30:00Z | active |
			| 32 | SWP-2026-0032 | 18                    | 8820                 | 14                      | --                     | accepted   | 2026-07-22T09:00:00Z | --                   | active |
			| 33 | SWP-2026-0033 | 14                    | 8825                 | --                      | --                     | requested  | --                   | --                   | active |
			| 34 | SWP-2026-0034 | 15                    | 8830                 | 18                      | 8831                   | rejected   | 2026-07-25T11:00:00Z | --                   | active |
			| 35 | SWP-2026-0035 | 18                    | 8840                 | 15                      | 8841                   | cancelled  | --                   | --                   | active |


#5. HR -- Movement and assignment

	## lookups first used in this section
		- MOVEMENT_STATE              : draft | pending | approved | rejected | effected | cancelled
		- MOVEMENT_TYPE               : hire | promotion | transfer | demotion | grade_change | secondment | reinstatement | employment_type_change | confirmation | suspension | separation
		- ASSIGNMENT_STATE            : draft | active | ended | cancelled
		- ASSIGNMENT_TYPE             : primary | acting | secondment | additional
		- EMPLOYEE_MOVEMENT_APPROVAL_STATE : pending | approved | rejected  -- new -- per-approver verdict on EmployeeMovementApproval

	### EmployeeMovement [DIST] -- one row per lifecycle event (hire / promote / transfer / ...) as an approvable document; approval via core Workflow
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- movement number via DocumentSequence (MOV-2026-0102)
		- employee_id             -- FK Employee -- the person being moved
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- entity the movement is raised under
		- movement_type_lookup_value_id -- FK LookupValue (MOVEMENT_TYPE: hire | promotion | transfer | demotion | grade_change | secondment | reinstatement | employment_type_change | confirmation | suspension | separation)
		- movement_state_lookup_value_id -- FK LookupValue (MOVEMENT_STATE: draft | pending | approved | rejected | effected | cancelled)
		- from_entity_id          -- FK Entity nullable -- old cost center / location
		- to_entity_id            -- FK Entity nullable -- new cost center / location
		- from_position_id        -- FK JobPosition nullable -- old seat
		- to_position_id          -- FK JobPosition nullable -- new seat
		- from_job_grade_id           -- FK JobGrade nullable -- old grade
		- to_job_grade_id             -- FK JobGrade nullable -- new grade
		- effective_date          -- date -- effecting creates/ends EmploymentAssignment rows on this date
		- reason                  -- jsonb nullable
		- workflow_id 			 -- FK Workflow -- the approval workflow instance for this movement
		- requested_by_employee_id -- FK Employee -- who raised the movement
		- effected_at             -- timestamp nullable -- when assignments were actually rewritten
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id  | code          | employee_id | movement_type | movement_state | from_entity_id | to_entity_id | from_position_id | to_position_id | from_job_grade_id | to_job_grade_id | effective_date | state  |
			| --- | ------------- | ----------- | ------------- | -------------- | -------------- | ------------ | ---------------- | -------------- | ------------- | ----------- | -------------- | ------ |
			| 101 | MOV-2024-0014 | 14          | hire          | effected       | --             | 7            | --               | 24             | --            | 3           | 2024-06-01     | active |
			| 102 | MOV-2026-0102 | 14          | promotion     | pending        | 7              | 7            | 24               | 20             | 3             | 4           | 2026-09-01     | active |
			| 103 | MOV-2026-0088 | 31          | hire          | effected       | --             | 9            | --               | 40             | --            | 3           | 2026-02-17     | active |
			| 104 | MOV-2025-0071 | 22          | grade_change  | effected       | 3              | 3            | 31               | 31             | 4             | 5           | 2025-07-01     | active |
			| 105 | MOV-2026-0110 | 7           | transfer      | draft          | 3              | 7            | 12               | 12             | 5             | 5           | 2026-10-01     | active |

	### EmployeeMovementApproval [LINE] -- one row per approver for an EmployeeMovement
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- employee_movement_id    -- FK EmployeeMovement -- the movement being approved
		- workflow_step_id        -- FK WorkflowStep -- the step in the approval workflow
		- approval_state_lookup_value_id -- FK LookupValue (EMPLOYEE_MOVEMENT_APPROVAL_STATE: pending | approved | rejected) -- this step's verdict  -- new
		- remarks                 -- jsonb nullable -- the approver's note
		- approved_at             -- timestamp nullable -- NULL = step not yet acted on
		- user_id                 -- FK User -- who recorded the step (the acting approver)
		- state                   -- active / inactive
		> examples:
			| id | employee_movement_id | workflow_step_id | remarks (en)                 | approved_at          | state  |
			| -- | -------------------- | ---------------- | ---------------------------- | -------------------- | ------ |
			| 1  | 102                  | 11               | Grade jump within band       | 2026-08-02T07:30:00Z | active |
			| 2  | 102                  | 12               | --                           | --                   | active |
			| 3  | 101                  | 11               | Hire approved as budgeted    | 2024-05-28T09:00:00Z | active |
			| 4  | 104                  | 11               | Step increment per scale     | 2025-06-20T10:15:00Z | active |
			| 5  | 103                  | 11               | Contract hire, BDR branch    | 2026-02-10T08:40:00Z | active |

	### EmploymentAssignment [DIST] -- one row per effective-dated posting: where and what the employee actually works; its entity doubles as COST CENTER
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- assigned person
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- work location AND cost center (Entity node)
		- job_position_id         -- FK JobPosition -- seat held
		- assignment_type_lookup_value_id -- FK LookupValue (ASSIGNMENT_TYPE: primary | acting | secondment | additional)
		- assignment_state_lookup_value_id -- FK LookupValue (ASSIGNMENT_STATE: draft | active | ended | cancelled)
		- reports_to_employee_id  -- FK Employee nullable -- line manager this posting reports to; overrides JobPosition.reports_to_position_id when set
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- employee_movement_id   -- FK EmployeeMovement nullable -- the movement that created this row
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		- shift_pattern_id        -- FK ShiftPattern nullable -- rota the roster generator runs for this posting; ShiftAssignment records the generated rows
		- employee_guarantee_id   -- FK EmployeeGuarantee nullable -- if the position needs a guarantor
		> examples:
			| id | employee_id | entity_id | job_position_id | assignment_type | assignment_state | reports_to_employee_id | shift_pattern_id | employee_guarantee_id | effective_from | effective_to | state  |
			| -- | ----------- | --------- | --------------- | --------------- | ---------------- | ---------------------- | ---------------- | --------------------- | -------------- | ------------ | ------ |
			| 1  | 7           | 3         | 12              | primary         | active           | 44                     | 1                | --                    | 2022-01-10     | --           | active |
			| 2  | 14          | 7         | 24              | primary         | active           | 7                      | 3                | 1                     | 2024-06-01     | --           | active |
			| 3  | 22          | 3         | 31              | primary         | active           | 44                     | 1                | --                    | 2021-09-15     | --           | active |
			| 4  | 31          | 9         | 40              | primary         | active           | 44                     | 4                | 2                     | 2026-02-17     | --           | active |
			| 5  | 44          | 3         | 30              | primary         | active           | --                     | 1                | --                    | 2020-03-02     | --           | active |


#6. HR -- Leave

	## lookups first used in this section
		- LEAVE_ACCRUAL_METHOD        : annual_grant | monthly_accrual | per_service_year | fixed
		- LEAVE_ROUNDING              : none | half_day | full_day
		- LEAVE_ALLOCATION_STATE      : draft | submitted | approved | rescheduled | consumed | cancelled
		  -- consumed = all allocated days have been taken or encashed within the period; terminal state at FY-end close
		- LEAVE_REQUEST_STATE         : draft | pending | approved | rejected | cancelled | taken
		- LEAVE_REQUEST_APPROVAL_STATE : pending | approved | rejected
		  -- used by LeaveRequestApproval.approval_state_lookup_value_id; per-approver verdict inside the leave chain
		- LEAVE_DAY_PORTION           : full | first_half | second_half
		- LEAVE_TRANSACTION_TYPE      : allocation | accrual | request | cancellation | carry_forward | encashment | expiry | adjustment

	### LeaveType [REF] -- one row per leave kind (annual, sick, maternity...); entitlement rules live in LeavePolicy, not here
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (ANNUAL, SICK, MATERNITY, PATERNITY, BEREAVEMENT, UNPAID)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- entity_id               -- FK Entity nullable -- NULL = platform seed
		- is_paid                 -- bool default true -- false = unpaid leave (absence recorded, no salary)
		- requires_attachment     -- bool -- e.g. sick note; upload via DocumentAttachment ('HR:LeaveRequest')
		- affects_attendance      -- bool -- writes on_leave into AttendanceDay
		- icon_id                 -- FK Icon nullable
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code      | name (en)       | entity_id | is_paid | requires_attachment | affects_attendance | icon_id | status       | state  |
			| -- | --------- | --------------- | --------- | ------- | ------------------- | ------------------ | ------- | ------------ | ------ |
			| 1  | ANNUAL    | Annual Leave    | --        | true    | false               | true               | 31      | acceptForAll | active |
			| 2  | SICK      | Sick Leave      | --        | true    | true                | true               | 32      | acceptForAll | active |
			| 3  | MATERNITY | Maternity Leave | --        | true    | true                | true               | 33      | acceptForAll | active |
			| 4  | PATERNITY | Paternity Leave | --        | true    | false               | true               | 34      | acceptForAll | active |
			| 5  | UNPAID    | Unpaid Leave    | --        | false   | false               | true               | 35      | acceptForAll | active |

	### LeavePolicy [DIST] -- one row per entity rulebook binding leave types to entitlement rules; sectors differ by policy rows, never by code
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (POL-OFFICE-2026, POL-RETAIL-2026)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- policy owner; applies to the subtree via Entity.path unless overridden deeper
		- work_calendar_id        -- FK WorkCalendar -- day-counting basis (skip holidays / weekends)
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code            | name (en)            | entity_id | work_calendar_id | effective_from | effective_to | state  |
			| -- | --------------- | -------------------- | --------- | ---------------- | -------------- | ------------ | ------ |
			| 1  | POL-OFFICE-2026 | Office Policy 2026   | 3         | 1                | 2026-07-08     | --           | active |
			| 2  | POL-RETAIL-2026 | Retail Policy 2026   | 7         | 2                | 2026-07-08     | --           | active |
			| 3  | POL-BDR-2026    | Bahir Dar Policy     | 9         | 3                | 2026-07-08     | --           | active |
			| 4  | POL-SHOP-2026   | Piazza Shop Policy   | 12        | 4                | 2026-07-08     | --           | active |
			| 5  | POL-OFFICE-2025 | Office Policy 2025   | 3         | 1                | 2025-07-08     | 2026-07-07   | active |

	### LeavePolicyRule [LINE] -- one row per leave type's entitlement inside a policy; Ethiopian minimums are seeded as data
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from LeavePolicy (line tenancy)
		- pay_percent             -- numeric(5,2) nullable -- percent of basic paid during this leave (100 full, 50 half, 0 unpaid); overrides is_paid when non-NULL
		- leave_policy_id         -- FK LeavePolicy -- owning rulebook
		- leave_type_id           -- FK LeaveType -- UNIQUE (leave_policy_id, leave_type_id)
		- accrual_method_lookup_value_id -- FK LookupValue (LEAVE_ACCRUAL_METHOD: annual_grant | monthly_accrual | per_service_year | fixed)
		- days_per_year               -- numeric(6,2) -- annual entitlement (16.00 statutory minimum)
		- extra_days_per_service_year -- numeric(4,2) -- +1.00 per additional service year (accrual_method = per_service_year)
		- max_days                -- numeric(6,2) nullable -- entitlement cap (30.00)
		- min_service_months      -- integer -- months of service before this leave type may be requested
		- max_carry_forward_days  -- numeric(6,2) -- 0 = use-it-or-lose-it
		- carry_forward_expiry_months -- integer nullable -- carried days expire after N months (Ethiopia: within 2 years)
		- allow_negative_balance  -- bool -- may borrow against the next allocation (negative balance)
		- allow_encashment        -- bool -- payable at separation (leave-encashment line in FinalSettlement)
		- requires_attachment     -- bool -- request must carry evidence via DocumentAttachment (sick note, court summons)
		- allow_half_day          -- bool
		- rounding_lookup_value_id -- FK LookupValue (LEAVE_ROUNDING: none | half_day | full_day)
		- gender_lookup_value_id  -- FK LookupValue (GENDER_TYPE: male | female) nullable -- maternity/paternity eligibility
		- notice_days             -- integer -- how far ahead requests must be filed
		- state                   -- active / inactive
		- max_splits_per_year     -- integer nullable -- how many separate requests the entitlement may be broken into; NULL = unlimited
		- min_days_between_requests -- integer nullable -- spacing enforced between two requests of this leave type
		> examples:
			| id | leave_policy_id | leave_type | accrual_method   | days_per_year | extra/svc_yr | max_days | carry_fwd | encash | half_day | gender | state  |
			| -- | --------------- | ---------- | ---------------- | --------- | ------------ | -------- | --------- | ------ | -------- | ------ | ------ |
			| 1  | 1               | 1 (ANNUAL) | per_service_year | 16.00     | 1.00         | 30.00    | 10.00     | true   | true     | --     | active |
			| 2  | 1               | 2 (SICK)   | annual_grant     | 30.00     | 0.00         | 180.00   | 0.00      | false  | true     | --     | active |
			| 3  | 1               | 3 (MATER.) | fixed            | 120.00    | 0.00         | 120.00   | 0.00      | false  | false    | female | active |
			| 4  | 1               | 4 (PATER.) | fixed            | 5.00      | 0.00         | 5.00     | 0.00      | false  | false    | male   | active |
			| 5  | 2               | 1 (ANNUAL) | per_service_year | 16.00     | 1.00         | 30.00    | 5.00      | true   | true     | --     | active |

	### LeaveAllocation [DIST] -- one row per annual-leave entitlement issued to an employee for a period; generated from policy each fiscal year, or manual grant
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (LAL-2026-0450)
		- employee_id             -- FK Employee -- entitlement holder
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- leave_type_id           -- FK LeaveType -- kind of leave allocated
		- leave_policy_rule_id    -- FK LeavePolicyRule nullable -- NULL for manual / ad-hoc grants
		- period_start            -- date -- Ethiopian FY start (2026-07-08)
		- period_end              -- date -- 2027-07-07
		- allocated_days          -- numeric(6,2) -- policy computation result, service-year additions applied
		- carried_forward_days    -- numeric(6,2) -- brought in from the prior period
		- notes                   -- jsonb nullable -- request reason
		- allocation_state_lookup_value_id -- FK LookupValue (LEAVE_ALLOCATION_STATE: draft | submitted | approved | rescheduled | consumed | cancelled)
		- rescheduled_from_id     -- FK LeaveAllocation (self) nullable -- forward chain when the window moves; superseded rows are never edited
		- reschedule_reason       -- jsonb nullable
		- approved_by_employee_id -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id  | code          | employee_id | leave_type | allocation_state | period_start | period_end | allocated_days | carried_forward | state  |
			| --- | ------------- | ----------- | ---------- | ---------------- | ------------ | ---------- | -------------- | --------------- | ------ |
			| 451 | LAL-2025-0451 | 7           | 1          | consumed         | 2025-07-08   | 2026-07-07 | 20.00          | 4.00            | active |
			| 452 | LAL-2026-0452 | 7           | 1          | approved         | 2026-07-08   | 2027-07-07 | 20.00          | 24.00           | active |
			| 453 | LAL-2026-0453 | 14          | 1          | approved         | 2026-07-08   | 2027-07-07 | 18.00          | 0.00            | active |
			| 454 | LAL-2026-0454 | 22          | 1          | approved         | 2026-07-08   | 2027-07-07 | 21.00          | 6.00            | active |
			| 455 | LAL-2026-0455 | 44          | 1          | approved         | 2026-07-08   | 2027-07-07 | 22.00          | 10.00           | active |

	### LeaveBalance [LINE] -- one row per employee x allocation; cache/denormalized projection of LeaveTransaction for fast reads
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- employee_id             -- FK Employee -- balance holder
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- leave_type_id           -- FK LeaveType -- kind of leave
		- leave_allocation_id     -- FK LeaveAllocation -- UNIQUE (employee_id, leave_allocation_id)
		- entitled_days           -- numeric(6,2) -- allocated + carried
		- taken_days              -- numeric(6,2)
		- pending_days            -- numeric(6,2) -- requested, not yet approved
		- encashed_days           -- numeric(6,2)
		- expired_days            -- numeric(6,2)
		- adjusted_days           -- numeric(6,2) -- net manual adjustments (signed); keeps the projection equal to the transaction ledger
		- available_days          -- numeric(6,2) -- entitled - taken - pending - encashed - expired + adjusted
		- recalculated_at         -- timestamp
		- state                   -- active / inactive
		> examples:
			| id | employee_id | leave_type | leave_allocation_id | entitled | taken | pending | encashed | expired | adjusted | available | state    |
			| -- | ----------- | ---------- | ------------------- | -------- | ----- | ------- | -------- | ------- | -------- | --------- | -------- |
			| 1  | 7           | 1          | 451                 | 24.00    | 10.00 | 0.00    | 0.00     | 0.00    | 0.00     | 14.00     | inactive |
			| 2  | 7           | 1          | 452                 | 44.00    | 3.00  | 0.00    | 0.00     | 0.00    | 0.00     | 41.00     | active   |
			| 3  | 14          | 1          | 453                 | 18.00    | 0.00  | 2.00    | 0.00     | 0.00    | 0.00     | 16.00     | active   |
			| 4  | 22          | 1          | 454                 | 27.00    | 5.00  | 0.00    | 0.00     | 0.00    | 0.00     | 22.00     | active   |
			| 5  | 44          | 1          | 455                 | 32.00    | 0.00  | 0.00    | 0.00     | 2.00    | 0.00     | 30.00     | active   |

	### LeaveRequest [DIST] -- one row per leave request document; approval chain via core Workflow, sick-note upload via DocumentAttachment ('HR:LeaveRequest')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (LVR-2026-0733)
		- employee_id             -- FK Employee -- who takes the leave
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- leave_type_id           -- FK LeaveType -- kind of leave requested
		- leave_allocation_id     -- FK LeaveAllocation nullable -- balance bucket debited; only for annual leave; NULL for sick, maternity, paternity, unpaid, etc.
		- request_state_lookup_value_id -- FK LookupValue (LEAVE_REQUEST_STATE: draft | pending | approved | rejected | cancelled | taken)
		- start_date              -- date
		- end_date                -- date
		- requested_days          -- numeric(6,2) -- working days per the policy calendar
		- approved_days           -- numeric(6,2) nullable -- days the approver actually granted (user asked 10, manager approved 6 -> 6.00)
		- reason                  -- jsonb nullable
		- handover_employee_id    -- FK Employee nullable -- covers during the absence
		- workflow_id 		      -- FK Workflow nullable -- approval process instance
		- is_half_day              -- bool -- true if the request is for a half-day; the start_date is the day, and the portion is in LeaveRequestDay.portion_lookup_value_id
		- shift_id                -- FK Shift nullable -- set when is_half_day = true: the rostered shift the half-day is taken from; NULL = chosen at approval
		- user_id                 -- FK User -- who created the row (self-service or HR on behalf)
		- state                   -- active / inactive
		- actual_return_date      -- date nullable -- the day work actually resumed; differs from end_date on early return or extension
		- recalled_at             -- timestamp nullable -- employee recalled from leave before end_date; unused days return to the balance as a LeaveTransaction
		- recall_reason           -- jsonb nullable -- why the recall was necessary
		> examples:
			| id  | code          | employee_id | leave_type | leave_allocation_id | request_state | start_date | end_date   | requested_days | approved_days  | handover_employee_id | is_half_day | state  |
			| --- | ------------- | ----------- | ---------- | ------------------- | ------------- | ---------- | ---------- | -------------- | -------------- | -------------------- | ----------- | ------ |
			| 731 | LVR-2026-0731 | 22          | 1          | 454                 | approved      | 2026-07-27 | 2026-07-31 | 5.00           | 5.00           | 44                   | false       | active |
			| 732 | LVR-2026-0732 | 14          | 1          | 453                 | pending       | 2026-08-10 | 2026-08-11 | 2.00           | --             | 15                   | false       | active |
			| 733 | LVR-2026-0733 | 7           | 1          | 452                 | taken         | 2026-07-14 | 2026-07-16 | 3.00           | 3.00           | --                   | false       | active |
			| 734 | LVR-2026-0734 | 31          | 2          | --                  | rejected      | 2026-07-21 | 2026-07-22 | 2.00           | --             | --                   | false       | active |
			| 735 | LVR-2026-0735 | 22          | 1          | 454                 | draft         | 2026-09-14 | 2026-09-14 | 0.50           | --             | --                   | true        | active |

	### LeaveRequestApproval [LINE] -- one row per approval step in the approval chain
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- leave_request_id        -- FK LeaveRequest -- parent document
		- workflow_step_id        -- FK WorkflowStep -- the step in the approval workflow
		- approval_state_lookup_value_id -- FK LookupValue (LEAVE_REQUEST_APPROVAL_STATE: pending | approved | rejected) -- this step's verdict  -- new
		- approved_at             -- timestamp nullable
		- remarks                 -- jsonb nullable
		- user_id                 -- FK User -- who recorded the step (the acting approver)
		- state                   -- active / inactive
		> examples:
			| id   | leave_request_id | approval_state   | approved_at          | remarks (en)          | state  |
			| ---- | ---------------- | ---------------- | -------------------- | --------------------- | ------ |
			| 8101 | 731              | approved         | 2026-07-28T07:10:00Z | Cover arranged        | active |
			| 8102 | 732              | pending          | --                   | --                    | active |
			| 8103 | 733              | approved         | 2026-07-28T07:12:00Z | --                    | active |
			| 8104 | 734              | rejected         | 2026-07-28T07:15:00Z | No sick note attached | active |
			| 8105 | 735              | pending          | --                   | --                    | active |

	### LeaveRequestDay [LINE] (Q15 -- keep or drop?) -- one row per exploded day of a request; enables half-days and precise attendance stamping
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- leave_request_id        -- FK LeaveRequest -- parent request
		- date                    -- date -- UNIQUE (leave_request_id, date)
		- portion_lookup_value_id -- FK LookupValue (LEAVE_DAY_PORTION: full | first_half | second_half)
		- day_value               -- numeric(3,2) -- 1.00 or 0.50
		- state                   -- active / inactive
		> examples:
			| id   | leave_request_id | date       | portion     | day_value | state  |
			| ---- | ---------------- | ---------- | ----------- | --------- | ------ |
			| 3301 | 731              | 2026-07-27 | full        | 1.00      | active |
			| 3302 | 731              | 2026-07-28 | full        | 1.00      | active |
			| 3303 | 731              | 2026-07-29 | full        | 1.00      | active |
			| 3304 | 735              | 2026-09-14 | first_half  | 0.50      | active |
			| 3305 | 733              | 2026-07-14 | full        | 1.00      | active |

	### LeaveTransaction [DIST] -- one row per balance change; immutable ledger, LeaveBalance is its projection
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- whose balance moved
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- leave_type_id           -- FK LeaveType -- kind of leave
		- leave_allocation_id     -- FK LeaveAllocation -- bucket affected
		- transaction_type_lookup_value_id -- FK LookupValue (LEAVE_TRANSACTION_TYPE: allocation | accrual | request | cancellation | carry_forward | encashment | expiry | adjustment)
		- leave_request_id        -- FK LeaveRequest nullable -- for request / cancellation rows
		- days                    -- numeric(6,2) -- signed: + credit / - debit
		- transacted_at           -- timestamp
		- notes                   -- jsonb nullable -- adjustment justification
		- user_id                 -- FK User nullable -- NULL = system job
		- state                   -- active / inactive
		> examples:
			| id    | employee_id | leave_type | leave_allocation_id | transaction_type | leave_request_id | days   | transacted_at        | state  |
			| ----- | ----------- | ---------- | ------------------- | ---------------- | ---------------- | ------ | -------------------- | ------ |
			| 12001 | 7           | 1          | 451                 | allocation       | --               | +20.00 | 2026-07-08T00:10:00Z | active |
			| 12002 | 7           | 1          | 451                 | carry_forward    | --               | +4.00  | 2026-07-08T00:10:01Z | active |
			| 12003 | 7           | 1          | 451                 | request          | 733              | -3.00  | 2026-07-12T09:14:00Z | active |
			| 12004 | 22          | 1          | 453                 | request          | 731              | -5.00  | 2026-07-20T11:40:00Z | active |
			| 12005 | 44          | 1          | 454                 | expiry           | --               | -2.00  | 2026-07-08T00:10:02Z | active |

	### LeaveEncashmentRequest [DIST] -- one in-service request to convert unused leave days into cash; exit encashment stays on FinalSettlementLine (Q8 -- confirm new table)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- text -- document number
		- employee_id             -- FK Employee
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity
		- leave_type_id           -- FK LeaveType -- must have LeavePolicyRule.allow_encashment = true
		- leave_allocation_id     -- FK LeaveAllocation -- the bucket debited
		- request_state_lookup_value_id -- FK LookupValue (LEAVE_REQUEST_STATE: draft | pending | approved | rejected | cancelled | taken)
		- requested_days          -- numeric(6,2)
		- approved_days           -- numeric(6,2) nullable
		- daily_rate              -- numeric(15,4) -- basic / WorkCalendar.payroll_days_per_month at approval time; frozen
		- amount                  -- numeric(15,4) -- approved_days x daily_rate
		- currency_id             -- FK Currency
		- reason                  -- jsonb nullable
		- approver_employee_id    -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- leave_transaction_id    -- FK LeaveTransaction nullable -- the signed ledger row that removed the days
		- user_id                 -- FK User
		- state                   -- active / inactive
		  -- note: the cash reaches the payslip through PayrollInput rows carrying source_type = 'LeaveEncashmentRequest'. The link is held on PayrollInput, not here, because one encashment may settle over several periods (1:N).
		> examples:
			| id | code        | employee_id | leave_type | requested_days | approved_days | daily_rate | amount     | request_state | state  |
			| -- | ----------- | ----------- | ---------- | -------------- | ------------- | ---------- | ---------- | ------------- | ------ |
			| 1  | LEN-2026-01 | 22 Tigist   | annual     | 10.00          | 10.00         | 461.5400   | 4615.4000  | approved      | active |
			| 2  | LEN-2026-02 | 14 Abebe    | annual     | 5.00           | --            | 250.0000   | --         | pending       | active |


#7. HR -- Attendance and time

	## lookups first used in this section
		- ATTENDANCE_DEVICE_TYPE      : biometric_fingerprint | biometric_face | rfid_card | mobile_gps | web_portal
		- DEVICE_CREDENTIAL_TYPE      : rfid_card | fingerprint_template | face_template | pin
		- ATTENDANCE_LOG_DIRECTION    : in | out
		- ATTENDANCE_LOG_SOURCE       : device | mobile | web | manual
		- ATTENDANCE_DAY_STATUS       : present | absent | late | early_leave | half_day | on_leave | holiday | weekend
		- ATTENDANCE_EXCEPTION_STATE  : open | justified | rejected | regularized
		- ATTENDANCE_EXCEPTION_TYPE   : missed_punch | late_arrival | early_departure | unscheduled_absence | device_mismatch
		- OVERTIME_COMPENSATION       : paid | compensatory_leave
		- OVERTIME_REQUEST_STATE      : draft | pending | approved | rejected | cancelled
		- OVERTIME_TYPE               : normal_day | night | weekend | public_holiday

	### AttendanceDevice [DIST] -- one row per punch source (physical or virtual) registered at a location
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (DEV-BOLE-01)
		- name                    -- jsonb (localized)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- location the device serves
		- device_type_lookup_value_id -- FK LookupValue (ATTENDANCE_DEVICE_TYPE: biometric_fingerprint | biometric_face | rfid_card | mobile_gps | web_portal)
		- serial_number           -- text nullable
		- ip_address              -- text nullable
		- geo_fence               -- jsonb nullable -- { lat, lng, radius_m } for mobile_gps punches
		- last_seen_at            -- timestamp nullable -- heartbeat
		- is_system               -- platform-seeded row
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code        | name (en)          | entity_id | device_type           | serial_number | last_seen_at         | state  |
			| -- | ----------- | ------------------ | --------- | --------------------- | ------------- | -------------------- | ------ |
			| 1  | DEV-HQ-01   | HQ Lobby Face      | 3         | biometric_face        | ZK-88121      | 2026-07-30T17:02:11Z | active |
			| 2  | DEV-BOLE-01 | Bole Fingerprint   | 7         | biometric_fingerprint | ZK-77015      | 2026-07-30T22:31:04Z | active |
			| 3  | DEV-BDR-01  | Bahir Dar Card     | 9         | rfid_card             | HID-3302      | 2026-07-30T18:10:40Z | active |
			| 4  | DEV-MOB-01  | Field Mobile Punch | 3         | mobile_gps            | --            | 2026-07-30T16:55:00Z | active |
			| 5  | DEV-PZA-01  | Piazza Web Portal  | 12        | web_portal            | --            | 2026-07-30T20:00:12Z | active |

	### EmployeeDeviceEnrollment [DIST] -- one row per device credential held by an employee; raw biometric templates stay on the device, never here
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- credential holder
		- attendance_device_id    -- FK AttendanceDevice nullable -- NULL = credential valid on every device of the entity (roaming card)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- credential_type_lookup_value_id -- FK LookupValue (DEVICE_CREDENTIAL_TYPE: rfid_card | fingerprint_template | face_template | pin)
		- credential_ref          -- text -- device-side user id / card serial / template slot -- UNIQUE (attendance_device_id, credential_type_lookup_value_id, credential_ref)
		- enrolled_at             -- timestamp
		- enrolled_by_employee_id -- FK Employee nullable: who registered the credential; NULL = self-enrolled via device
		- revoked_at              -- timestamp nullable -- lost card / separation; the sync worker then deletes it from the device
		- state                   -- active / inactive
		  -- note: punch resolution -- the device sends (device, credential_ref); this table maps it to employee_id.
		> examples:
			| id | employee_id | attendance_device_id | credential_type      | credential_ref | enrolled_at          | revoked_at           | state  |
			| -- | ----------- | -------------------- | -------------------- | -------------- | -------------------- | -------------------- | ------ |
			| 1  | 14          | 3 (DEV-BOLE-01)      | fingerprint_template | 00214          | 2024-06-02T08:00:00Z | --                   | active |
			| 2  | 14          | --                   | rfid_card            | 04A6-77-BC21   | 2024-06-02T08:05:00Z | --                   | active |
			| 3  | 22          | 1 (DEV-HQ-01)        | face_template        | 00022          | 2021-09-16T09:00:00Z | --                   | active |
			| 4  | 31          | 5 (DEV-BDR-01)       | fingerprint_template | 00318          | 2025-02-18T08:30:00Z | --                   | active |
			| 5  | 15          | --                   | rfid_card            | 04A6-77-90FF   | 2024-01-10T08:00:00Z | 2026-05-30T17:00:00Z | active |

	### AttendanceLog [DIST] -- one row per raw punch; append-only stream (corrections happen at AttendanceDay level)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- who punched
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- punch location
		- attendance_device_id    -- FK AttendanceDevice nullable -- NULL for manual entries
		- direction_lookup_value_id -- FK LookupValue (ATTENDANCE_LOG_DIRECTION: in | out)
		- source_lookup_value_id  -- FK LookupValue (ATTENDANCE_LOG_SOURCE: device | mobile | web | manual)
		- punched_at              -- timestamp -- device local time normalized to UTC
		- geo_point               -- jsonb nullable -- { lat, lng } for mobile punches
		- raw_payload             -- jsonb nullable -- device message as received
		- entered_by_user_id      -- FK User nullable -- who keyed a manual punch
		- state                   -- active / inactive; inactive = voided duplicate
		> examples:
			| id     | employee_id | entity_id | device_id | direction | source | punched_at           | state  |
			| ------ | ----------- | --------- | --------- | --------- | ------ | -------------------- | ------ |
			| 700301 | 14          | 7         | 2         | in        | device | 2026-07-27T03:58:21Z | active |
			| 700302 | 14          | 7         | 2         | out       | device | 2026-07-27T12:04:10Z | active |
			| 700303 | 7           | 3         | 1         | in        | device | 2026-07-27T05:31:44Z | active |
			| 700304 | 7           | 3         | 1         | out       | device | 2026-07-27T14:36:02Z | active |
			| 700305 | 31          | 9         | --        | in        | manual | 2026-07-27T05:45:00Z | active |

	### AttendanceDay [DIST] -- one row per employee per day; computed from logs + roster + leave, consumed by payroll
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- the person summarized
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- date                    -- date -- UNIQUE (employee_id, date)
		- shift_id                -- FK Shift nullable -- rostered shift that day
		- day_status_lookup_value_id -- FK LookupValue (ATTENDANCE_DAY_STATUS: present | absent | late | early_leave | half_day | on_leave | holiday | weekend)
		- first_in_at             -- timestamp nullable
		- last_out_at             -- timestamp nullable
		- scheduled_minutes       -- integer -- minutes the rostered shift expected that day
		- worked_minutes          -- integer -- net of breaks
		- late_minutes            -- integer
		- early_leave_minutes     -- integer
		- overtime_minutes        -- integer -- approved OT only (from OvertimeRequest)
		- leave_request_id        -- FK LeaveRequest nullable -- set when day_status = on_leave
		- is_locked               -- bool -- locked once its PayrollPeriod locks
		- recalculated_at         -- timestamp
		- state                   -- active / inactive
		> examples:
			| id     | employee_id | date       | shift_id | day_status | first_in_at          | last_out_at          | worked_min | late_min | ot_min | is_locked | state  |
			| ------ | ----------- | ---------- | -------- | ---------- | -------------------- | -------------------- | ---------- | -------- | ------ | --------- | ------ |
			| 810221 | 14          | 2026-07-27 | 2        | present    | 2026-07-27T03:58:21Z | 2026-07-27T12:04:10Z | 456        | 0        | 0      | false     | active |
			| 810222 | 7           | 2026-07-27 | 1        | present    | 2026-07-27T05:31:44Z | 2026-07-27T14:36:02Z | 485        | 1        | 0      | false     | active |
			| 810223 | 22          | 2026-07-27 | 1        | on_leave   | --                   | --                   | 0          | 0        | 0      | false     | active |
			| 810224 | 31          | 2026-07-27 | 4        | late       | 2026-07-27T19:24:00Z | 2026-07-28T03:05:00Z | 416        | 24       | 0      | false     | active |
			| 810225 | 14          | 2026-07-26 | --       | weekend    | --                   | --                   | 0          | 0        | 120    | false     | active |

	### AttendanceException [DIST] -- one row per anomaly needing HR action; regularization writes back into AttendanceDay
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- the person the anomaly concerns
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- attendance_day_id       -- FK AttendanceDay -- the day in question
		- exception_type_lookup_value_id -- FK LookupValue (ATTENDANCE_EXCEPTION_TYPE: missed_punch | late_arrival | early_departure | unscheduled_absence | device_mismatch)
		- exception_state_lookup_value_id -- FK LookupValue (ATTENDANCE_EXCEPTION_STATE: open | justified | rejected | regularized)
		- employee_note           -- jsonb nullable -- employee's justification
		- requested_first_in_at   -- timestamp nullable -- corrected clock-in the employee asks to apply on approval
		- requested_last_out_at   -- timestamp nullable -- corrected clock-out
		- reviewer_employee_id    -- FK Employee nullable
		- reviewed_at             -- timestamp nullable
		- resolution_note         -- jsonb nullable
		- user_id                 -- FK User -- who created the row (system or HR)
		- state                   -- active / inactive
		> examples:
			| id   | employee_id | attendance_day_id | exception_type      | exception_state | reviewer | reviewed_at          | state  |
			| ---- | ----------- | ----------------- | ------------------- | --------------- | -------- | -------------------- | ------ |
			| 5501 | 31          | 810224            | late_arrival        | justified       | 7        | 2026-07-28T07:10:00Z | active |
			| 5502 | 14          | 810221            | missed_punch        | regularized     | 7        | 2026-07-28T07:12:00Z | active |
			| 5503 | 22          | 810223            | unscheduled_absence | rejected        | 7        | 2026-07-28T07:15:00Z | active |
			| 5504 | 7           | 810222            | early_departure     | open            | --       | --                   | active |
			| 5505 | 44          | 810226            | device_mismatch     | open            | --       | --                   | active |

	### OvertimeRequest [DIST] -- one row per OT approval document; approved minutes land on AttendanceDay and PayrollInput, approval via core Workflow
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (OT-2026-0221)
		- employee_id             -- FK Employee -- who works the overtime
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- date                    -- date
		- attendance_day_id       -- FK AttendanceDay nullable -- the attendance day evidencing the extra time
		- overtime_type_lookup_value_id -- FK LookupValue (OVERTIME_TYPE: normal_day | night | weekend | public_holiday) -- rate multipliers (1.25 / 1.5 / 2.0 / 2.5) are StatutoryRule data
		- request_state_lookup_value_id -- FK LookupValue (OVERTIME_REQUEST_STATE: draft | pending | approved | rejected | cancelled)
		- start_at                -- timestamp
		- end_at                  -- timestamp
		- requested_minutes       -- integer
		- approved_minutes        -- integer nullable -- may be trimmed by the approver
		- compensation_lookup_value_id -- FK LookupValue (OVERTIME_COMPENSATION: paid | compensatory_leave) -- comp-off credits a LeaveTransaction adjustment instead of a PayrollInput
		- reason                  -- jsonb nullable
		- approver_employee_id    -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: approved minutes reach payroll as a PayrollInput row with source_type = 'OvertimeRequest'. Double payment is blocked there -- by the input's UNIQUE (source_type, source_id, ...) on the feeder side and processed_in_payroll_run_id on the consumption side.
		> examples:
			| id  | code         | employee_id | date       | overtime_type  | request_state | requested_min | approved_min | approver | state  |
			| --- | ------------ | ----------- | ---------- | -------------- | ------------- | ------------- | ------------ | -------- | ------ |
			| 221 | OT-2026-0221 | 14          | 2026-07-26 | weekend        | approved      | 120           | 120          | 7        | active |
			| 222 | OT-2026-0222 | 14          | 2026-07-20 | normal_day     | approved      | 90            | 60           | 7        | active |
			| 223 | OT-2026-0223 | 31          | 2026-07-27 | night          | pending       | 180           | --           | --       | active |
			| 224 | OT-2026-0224 | 22          | 2026-09-11 | public_holiday | draft         | 240           | --           | --       | active |
			| 225 | OT-2026-0225 | 14          | 2026-07-13 | weekend        | rejected      | 240           | --           | 7        | active |
