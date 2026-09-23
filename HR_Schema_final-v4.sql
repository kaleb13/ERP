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


#8. HR -- Payroll setup

	## lookups first used in this section
		- PAYROLL_CALC_METHOD         : fixed | formula | percentage_of_basic | slab | net_to_gross | manual_input
		- PAYROLL_COMPONENT_TYPE      : earning | deduction | employer_contribution | information
		- STATUTORY_RULE_TYPE         : pension_employee | pension_employer | income_tax | overtime_rate | severance | notice_period | annual_leave_minimum | probation_maximum | working_hours_weekly
		- STATUTORY_CONFIG_KEY        : open catalogue -- percent | multiplier | first_year_days | per_extra_year_days | cap_months | max_working_days | weekly_hours | minimum_days | notice_days ...
		  -- open, like SKILL_CATALOG: a new statutory knob must not require a migration
		- STATUTORY_CONFIG_UNIT       : percent | multiplier | days | working_days | months | years | hours | amount | count
		  -- closed: units are a fixed vocabulary, and tenant-invented units would defeat the min_value / max_value validation
		- PAYDAY_RULE                 : fixed_day | last_working_day | weekday
		- PAY_FREQUENCY               : monthly | semi_monthly | weekly | daily
		- SALARY_REVISION_TYPE        : initial | annual_increment | merit | promotion | market_adjustment | correction
		- SALARY_STATE                : draft | pending | approved | active | superseded
		- BENEFIT_TYPE                : medical | life_insurance | transport | housing | meal | communication | education | fuel
		- BENEFIT_PLAN_ASSIGNMENT_STATE : pending | active | suspended | ended
		  -- used by BenefitPlanAssignment.assignment_state_lookup_value_id; mirrors BENEFIT_ENROLLMENT_STATE
		  -- kept as a separate type because plan-level assignment and individual enrollment may diverge in future
		- BENEFIT_ENROLLMENT_STATE    : pending | active | suspended | ended
		- MEDICAL_TREATMENT_TYPE      : outpatient | inpatient | dental | optical | maternity | chronic_illness | emergency | diagnostic
		- MEDICAL_CLAIM_STATE         : draft | submitted | pending_approval | assessed | approved | rejected | reimbursed | cancelled   -- new -- used by MedicalClaim
		- BONUS_BASE                  : basic_salary | gross_salary | last_month_net | flat_amount
		- BONUS_PRORATION             : none | daily | monthly | mid_month_rounding
		- BONUS_SCHEME_STATE          : draft | approved | processed | cancelled
		- PROVIDENT_FUND_STATE        : pending | active | suspended | closed
		- PER_DIEM_LOCATION           : inside_region | outside_region | abroad
		  -- used by ExpenseClaimLine.per_diem_location_lookup_value_id; determines which rate column applies on PerDiemRate

	### PayrollComponent [REF] -- one row per pay element (earning / deduction / employer contribution / information); behaviour is data
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (BASIC, HOUSE_ALLOW, TRANS_ALLOW, OT, PENSION_EE, PENSION_ER, INCOME_TAX)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- entity_id               -- FK Entity nullable -- NULL = platform seed
		- component_type_lookup_value_id -- FK LookupValue (PAYROLL_COMPONENT_TYPE: earning | deduction | employer_contribution | information)
		- calc_method_lookup_value_id -- FK LookupValue (PAYROLL_CALC_METHOD: fixed | formula | percentage_of_basic | slab | net_to_gross | manual_input)
		- is_taxable              -- bool -- enters the income-tax base
		- is_pensionable          -- bool -- enters the pension base (basic salary in Ethiopia)
		- is_statutory            -- bool -- not clear system-managed (INCOME_TAX, PENSION_EE/ER); the calc reads TaxBracket / StatutoryRule
		- prorate_on_partial_month -- bool -- mid-month joiners/leavers get (days worked / payroll_days_per_month) of this component; FALSE = full amount regardless
		- affects_net             -- bool -- false for employer_contribution / information rows
		- display_order           -- integer -- payslip print order
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		- non_taxable_ceiling_amount -- numeric(15,4) nullable -- amount up to which the component is exempt; the excess enters the tax base (transport allowance cap). NULL = is_taxable applies to the whole amount
		> examples:
			| id | code        | name (en)           | component_type        | calc_method         | is_taxable | is_pensionable | is_statutory | affects_net | state  |
			| -- | ----------- | ------------------- | --------------------- | ------------------- | ---------- | -------------- | ------------ | ----------- | ------ |
			| 1  | BASIC       | Basic Salary        | earning               | fixed               | true       | true           | false        | true        | active |
			| 2  | TRANS_ALLOW | Transport Allowance | earning               | formula             | false      | false          | false        | true        | active |
			| 3  | OT          | Overtime            | earning               | formula             | true       | false          | false        | true        | active |
			| 4  | INCOME_TAX  | Employment Income Tax | deduction           | slab                | false      | false          | true         | true        | active |
			| 5  | PENSION_ER  | Pension (Employer 11%) | employer_contribution | percentage_of_basic | false    | false          | true         | false       | active |

	### PayrollFormula [REF] -- one row per effective-dated calculation expression for a component; pay math changes without code
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- payroll_component_id    -- FK PayrollComponent -- the element this formula computes
		- entity_id               -- FK Entity nullable -- NULL = platform default; an entity row overrides for its subtree
		- expression              -- jsonb -- expression AST, e.g. { "op": "min", "args": [ { "var": "basic", "mul": 0.25 }, 2200 ] }
		- rounding                -- jsonb nullable -- { mode: "half_up", decimals: 2 }
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: variables exposed to expressions: basic, gross, taxable_gross, worked_days, period_days, ot_minutes_by_type.*, grade_level, service_years, inputs.* (PayrollInput).
		> examples:
			| id | payroll_component_id | entity_id | expression (summary)                             | effective_from | effective_to | state  |
			| -- | -------------------- | --------- | ------------------------------------------------ | -------------- | ------------ | ------ |
			| 1  | 2                    | --        | min(basic * 0.25, 2200)  -- tax-free cap         | 2026-07-08     | --           | active |
			| 2  | 3                    | --        | sum(ot_minutes_by_type * rate(overtime_rate))    | 2026-07-08     | --           | active |
			| 3  | 2                    | 7         | min(basic * 0.25, 1800)  -- retail override      | 2026-07-08     | --           | active |
			| 4  | 4                    | --        | slab(TaxBracket, taxable_gross)                  | 2026-07-08     | --           | active |
			| 5  | 2                    | --        | min(basic * 0.25, 2000)  -- superseded 2025 rule | 2025-07-08     | 2026-07-07   | active |

	### StatutoryRule [REF] -- one row per legal knob as effective-dated data (pension %, OT multipliers, severance, notice, leave minimums)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per country+type+key (ET-PENSION-EE)
		- rule_type_lookup_value_id -- FK LookupValue (STATUTORY_RULE_TYPE: pension_employee | pension_employer | income_tax | overtime_rate | severance | notice_period | annual_leave_minimum | probation_maximum | working_hours_weekly)
		- payroll_component_id    -- FK PayrollComponent nullable -- the statutory component this rule computes into (INCOME_TAX, PENSION_EE, PENSION_ER)
		- entity_id               -- FK Entity nullable -- NULL = national; entity override for voluntary top-ups
		- min_base_amount         -- numeric(15,4) nullable -- exemption floor; base below this is not subject to the rule
		- max_base_amount         -- numeric(15,4) nullable -- contribution ceiling; base above this is capped
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- is_system               -- platform-seeded row
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		- employment_type_lookup_value_id -- FK LookupValue (EMPLOYMENT_TYPE: permanent | contract | temporary | probation | part_time | intern | consultant) nullable -- rule binds only this employment type; NULL = all of them
		  -- note: the rule's VALUES live in StatutoryRuleConfig below (one typed row per knob) -- the old rule_config
		  -- jsonb is gone. min_base_amount / max_base_amount stay here: they bound the rule's BASE, not a knob's value.
		> examples:
			| id | code          | rule_type         | entity_id | payroll_component_id | is_system | effective_from | effective_to | state  |
			| -- | ------------- | ----------------- | --------- | -------------------- | --------- | -------------- | ------------ | ------ |
			| 1  | ET-PENSION-EE | pension_employee  | --        | 6 (PENSION_EE)       | true      | 2026-07-08     | --           | active |
			| 2  | ET-PENSION-ER | pension_employer  | --        | 5 (PENSION_ER)       | true      | 2026-07-08     | --           | active |
			| 3  | ET-OT-RATES   | overtime_rate     | --        | 3 (OT)               | true      | 2026-07-08     | --           | active |
			| 4  | ET-SEVERANCE  | severance         | --        | --                   | true      | 2026-07-08     | --           | active |
			| 5  | ET-PROBATION  | probation_maximum | --        | --                   | true      | 2026-07-08     | --           | active |

	### StatutoryRuleConfig [REF] -- new -- one row per typed knob inside a StatutoryRule; replaces the rule_config jsonb blob, sibling of TaxBracket
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- statutory_rule_id       -- FK StatutoryRule -- owning rule
		- config_key_lookup_value_id -- FK LookupValue (STATUTORY_CONFIG_KEY) -- which knob (percent, first_year_days, multiplier ...)
		- dimension_lookup_value_id -- FK LookupValue nullable -- the axis the knob varies over; NULL = single scalar knob. The lookup TYPE is implied by StatutoryRule.rule_type
		- numeric_value           -- numeric(15,6) -- the knob's value: 7.000000 percent, 2.500000 multiplier, 30.000000 days
		- unit_lookup_value_id    -- FK LookupValue (STATUTORY_CONFIG_UNIT: percent | multiplier | days | working_days | months | years | hours | amount | count)
		- min_value               -- numeric(15,6) nullable -- admissible floor, for UI validation and import guards
		- max_value               -- numeric(15,6) nullable -- admissible ceiling
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- is_system               -- platform-seeded row
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- UNIQUE (statutory_rule_id, config_key_lookup_value_id, dimension_lookup_value_id, effective_from)
		  -- note: dimension lookup type per rule_type -- overtime_rate -> OVERTIME_TYPE; every other rule_type
		  --       currently uses NULL. Add to this map as new dimensioned rules appear.
		  -- note: resolution order -- the calc picks the StatutoryRule current at date D (parent window = "does this
		  --       rule apply at all"), then each knob current at D (child window = "what value did this knob have").
		  --       Same two-level shape as StatutoryRule -> TaxBracket.
		> examples: (every rule_config blob above, expanded -- nothing lost)
			| id | statutory_rule_id | rule (code)   | config_key          | dimension      | numeric_value | unit         | min | max | effective_from | state  |
			| -- | ----------------- | ------------- | ------------------- | -------------- | ------------- | ------------ | --- | --- | -------------- | ------ |
			| 1  | 1                 | ET-PENSION-EE | percent             | --             | 7.000000      | percent      | 0   | 100 | 2026-07-08     | active |
			| 2  | 2                 | ET-PENSION-ER | percent             | --             | 11.000000     | percent      | 0   | 100 | 2026-07-08     | active |
			| 3  | 3                 | ET-OT-RATES   | multiplier          | normal_day     | 1.250000      | multiplier   | 1   | 5   | 2026-07-08     | active |
			| 4  | 3                 | ET-OT-RATES   | multiplier          | night          | 1.500000      | multiplier   | 1   | 5   | 2026-07-08     | active |
			| 5  | 3                 | ET-OT-RATES   | multiplier          | weekend        | 2.000000      | multiplier   | 1   | 5   | 2026-07-08     | active |
			| 6  | 3                 | ET-OT-RATES   | multiplier          | public_holiday | 2.500000      | multiplier   | 1   | 5   | 2026-07-08     | active |
			| 7  | 4                 | ET-SEVERANCE  | first_year_days     | --             | 30.000000     | days         | 0   | --  | 2026-07-08     | active |
			| 8  | 4                 | ET-SEVERANCE  | per_extra_year_days | --             | 10.000000     | days         | 0   | --  | 2026-07-08     | active |
			| 9  | 4                 | ET-SEVERANCE  | cap_months          | --             | 12.000000     | months       | 0   | --  | 2026-07-08     | active |
			| 10 | 5                 | ET-PROBATION  | max_working_days    | --             | 60.000000     | working_days | 0   | --  | 2026-07-08     | active |
		  -- the payoff: the public-holiday multiplier rising to 2.75 is a TWO-ROW edit -- stamp row 6's effective_to
		  -- and insert one successor. Rows 3, 4, 5 are untouched and the audit trail says exactly what changed.
		  -- Under the jsonb form that was a full-row supersede reporting all four multipliers as changed.

	### TaxBracket [REF] -- one row per bracket of the progressive income-tax schedule; law changes arrive as new effective-dated rows
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- country_id              -- FK Country -- ET
		- lower_bound             -- numeric(15,4) -- monthly taxable income floor (exclusive of the previous bracket)
		- upper_bound             -- numeric(15,4) nullable -- NULL = no ceiling (top bracket)
		- rate_percent            -- numeric(7,4) -- marginal rate
		- deduction_amount        -- numeric(15,4) -- shortcut constant (tax = income * rate - deduction)
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | country | lower_bound | upper_bound | rate_percent | deduction_amount | effective_from | effective_to | state  |
			| -- | ------- | ----------- | ----------- | ------------ | ---------------- | -------------- | ------------ | ------ |
			| 1  | ET      | 0.0000      | 600.0000    | 0.0000       | 0.0000           | 2026-07-08     | --           | active |
			| 2  | ET      | 600.0000    | 1650.0000   | 10.0000      | 60.0000          | 2026-07-08     | --           | active |
			| 3  | ET      | 1650.0000   | 3200.0000   | 15.0000      | 142.5000         | 2026-07-08     | --           | active |
			| 4  | ET      | 5250.0000   | 7800.0000   | 25.0000      | 565.0000         | 2026-07-08     | --           | active |
			| 5  | ET      | 10900.0000  | --          | 35.0000      | 1500.0000        | 2026-07-08     | --           | active |

	### EmployeeStatutoryExemption [DIST] -- one row per approved, bounded exemption of one employee from one statutory rule; the payroll calc skips the rule while the exemption is current
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- the exempted person
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- rule_type_lookup_value_id -- FK LookupValue (STATUTORY_RULE_TYPE: pension_employee | pension_employer | income_tax | overtime_rate | severance | notice_period | annual_leave_minimum | probation_maximum | working_hours_weekly) -- which obligation is waived
		- reason                  -- jsonb -- legal basis ({ en: "Expatriate on home-country social security -- bilateral agreement" })
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = until revoked
		- approved_by_employee_id -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: evidence letter via DocumentAttachment ('HR:EmployeeStatutoryExemption'); this is a per-employee override, never a change to the national rule.
		> examples:
			| id | employee_id | rule_type        | reason (en)                          | effective_from | effective_to | approved_by | state  |
			| -- | ----------- | ---------------- | ------------------------------------ | -------------- | ------------ | ----------- | ------ |
			| 1  | 58          | pension_employee | Expat on home social security        | 2026-03-01     | 2028-02-29   | 44          | active |
			| 2  | 58          | pension_employer | Expat on home social security        | 2026-03-01     | 2028-02-29   | 44          | active |
			| 3  | 59          | income_tax       | Diplomatic secondment -- treaty      | 2026-01-01     | 2026-12-31   | 44          | active |
			| 4  | 21          | pension_employee | Re-hired retiree already on pension  | 2026-07-01     | --           | 7           | active |
			| 5  | 21          | pension_employer | Re-hired retiree already on pension  | 2026-07-01     | --           | 7           | active |

	### PayrollGroup [DIST] -- one row per set of employees paid together (frequency + calendar + default bank source); an entity may run several
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (PG-HQ-MONTHLY, PG-RETAIL)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- paying legal entity
		- frequency_lookup_value_id -- FK LookupValue (PAY_FREQUENCY: monthly | semi_monthly | weekly | daily)
		- work_calendar_id        -- FK WorkCalendar -- day-count basis for prorations
		- currency_id             -- FK Currency -- ETB
		- entity_payment_method_id -- FK EntityPaymentMethod -- default disbursement rail (bank-transfer source account)
		- payday_rule_lookup_value_id -- FK LookupValue (PAYDAY_RULE: fixed_day | last_working_day | weekday)
		- payday_day              -- integer nullable -- day-of-month when rule = fixed_day; ISO weekday 1-7 when rule = weekday; NULL when last_working_day
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | name (en)          | entity_id | frequency | work_calendar_id | currency | payday_rule      | payday_day | state  |
			| -- | ------------- | ------------------ | --------- | --------- | ---------------- | -------- | ---------------- | ---------- | ------ |
			| 1  | PG-HQ-MONTHLY | HQ Monthly         | 3         | monthly   | 1                | ETB      | fixed_day        | 26         | active |
			| 2  | PG-BOLE       | Bole Retail        | 7         | monthly   | 2                | ETB      | fixed_day        | 26         | active |
			| 3  | PG-BDR        | Bahir Dar          | 9         | monthly   | 3                | ETB      | fixed_day        | 26         | active |
			| 4  | PG-PZA        | Piazza Shop        | 12        | monthly   | 4                | ETB      | last_working_day | --         | active |
			| 5  | PG-CASUAL     | Casual Labour      | 7         | weekly    | 2                | ETB      | weekday          | 5 (Fri)    | active |

	### SalaryStructure [DIST] -- one row per named component template for a grade/group; source for offers and salary generation
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (STR-OFFICE-B2)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- job_grade_id                -- FK JobGrade nullable -- structure targeted at a grade
		- payroll_group_id        -- FK PayrollGroup nullable -- default group for employees on this structure
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- is_system               -- platform-seeded row
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | name (en)           | entity_id | job_grade_id | payroll_group_id | effective_from | effective_to | state  |
			| -- | ------------- | ------------------- | --------- | -------- | ---------------- | -------------- | ------------ | ------ |
			| 1  | STR-OFFICE-B2 | Office Grade B2     | 3         | 5        | 1                | 2026-07-08     | --           | active |
			| 2  | STR-OFFICE-A3 | Office Grade A3     | 3         | 7        | 1                | 2026-07-08     | --           | active |
			| 3  | STR-RETAIL-C1 | Retail Grade C1     | 7         | 3        | 2                | 2026-07-08     | --           | active |
			| 4  | STR-BDR-C1    | Bahir Dar Grade C1  | 9         | 3        | 3                | 2026-07-08     | --           | active |
			| 5  | STR-PZA-C1    | Piazza Grade C1     | 12        | 3        | 4                | 2026-07-08     | --           | active |

	### SalaryStructureLine [LINE] -- one row per component inside a structure, with its default value or formula
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- salary_structure_id     -- FK SalaryStructure -- parent template
		- payroll_component_id    -- FK PayrollComponent -- UNIQUE (salary_structure_id, payroll_component_id)
		- default_amount          -- numeric(15,4) nullable -- for fixed components
		- default_percent         -- numeric(7,4) nullable -- for percentage_of_basic
		- payroll_formula_id      -- FK PayrollFormula nullable -- explicit formula pin; otherwise the current formula resolves
		- order                   -- integer
		- state                   -- active / inactive
		- is_mandatory            -- bool -- the line may not be dropped when the structure is exploded onto an employee; EmployeeSalaryComponent may override its value, never its presence
		> examples:
			| id | salary_structure_id | payroll_component_id | default_amount | default_percent | payroll_formula_id | order | state  |
			| -- | ------------------- | -------------------- | -------------- | --------------- | ------------------ | ----- | ------ |
			| 1  | 3                   | 1 (BASIC)            | 6500.0000      | --              | --                 | 1     | active |
			| 2  | 3                   | 2 (TRANS_ALLOW)      | --             | --              | 3                  | 2     | active |
			| 3  | 1                   | 1 (BASIC)            | 12000.0000     | --              | --                 | 1     | active |
			| 4  | 1                   | 2 (TRANS_ALLOW)      | --             | --              | 1                  | 2     | active |
			| 5  | 2                   | 1 (BASIC)            | 32000.0000     | --              | --                 | 1     | active |

	### EmployeeSalary [DIST] -- one row per effective-dated pay package; approval via core Workflow
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (SAL-2026-0140)
		- employee_id             -- FK Employee -- package holder
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- paying entity
		- payroll_group_id        -- FK PayrollGroup -- who pays with whom
		- salary_structure_id     -- FK SalaryStructure nullable -- template it was generated from
		- job_grade_step_id       -- FK JobGradeStep nullable -- the grade step this basic sits on
		- employee_movement_id    -- FK EmployeeMovement nullable -- the promotion / transfer / grade change that caused this revision
		- salary_state_lookup_value_id -- FK LookupValue (SALARY_STATE: draft | pending | approved | active | superseded)
		- basic_amount            -- numeric(15,4) -- headline basic, ETB; cache/denormalized copy of the BASIC component line
		- currency_id             -- FK Currency
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- change_reason           -- jsonb nullable -- free-form context for the revision
		- revision_type_lookup_value_id -- FK LookupValue (SALARY_REVISION_TYPE: initial | annual_increment | merit | promotion | market_adjustment | correction)
		- compensation_proposal_id -- FK CompensationProposal nullable -- provenance when the revision came from a review cycle
		- approved_by_employee_id -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id  | code          | employee_id | payroll_group_id | salary_state | basic_amount | currency | effective_from | effective_to | state  |
			| --- | ------------- | ----------- | ---------------- | ------------ | ------------ | -------- | -------------- | ------------ | ------ |
			| 141 | SAL-2024-0141 | 14          | 2                | active       | 6500.0000    | ETB      | 2024-06-01     | --           | active |
			| 142 | SAL-2025-0142 | 22          | 1                | active       | 12000.0000   | ETB      | 2025-07-01     | --           | active |
			| 143 | SAL-2020-0143 | 44          | 1                | active       | 32000.0000   | ETB      | 2020-03-02     | --           | active |
			| 144 | SAL-2026-0144 | 31          | 3                | active       | 7000.0000    | ETB      | 2026-02-17     | --           | active |
			| 145 | SAL-2022-0145 | 7           | 1                | active       | 14000.0000   | ETB      | 2022-01-10     | --           | active |

	### EmployeeSalaryComponent [LINE] -- one row per exploded package line; overrides structure defaults per person
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- employee_salary_id      -- FK EmployeeSalary -- parent package
		- ✅ payroll_component_id    -- FK PayrollComponent -- UNIQUE (employee_salary_id, payroll_component_id)
		- ✅ amount                  -- numeric(15,4) nullable -- fixed value for this employee
		- percent                 -- numeric(7,4) nullable -- for percentage components
		- payroll_formula_id      -- FK PayrollFormula nullable -- personal formula pin
		- effective_from          -- date nullable -- line-level effectivity (a one-year housing allowance); NULL = whole package life
		- effective_to            -- date nullable
		- order                   -- integer
		- state                   -- active / inactive
		> examples:
			| id | employee_salary_id | payroll_component_id | amount     | percent | payroll_formula_id | order | state  |
			| -- | ------------------ | -------------------- | ---------- | ------- | ------------------ | ----- | ------ |
			| 1  | 141                | 1 (BASIC)            | 6500.0000  | --      | --                 | 1     | active |
			| 2  | 141                | 2 (TRANS_ALLOW)      | 1625.0000  | --      | --                 | 2     | active |
			| 3  | 142                | 1 (BASIC)            | 12000.0000 | --      | --                 | 1     | active |
			| 4  | 142                | 2 (TRANS_ALLOW)      | 2200.0000  | --      | --                 | 2     | active |
			| 5  | 143                | 1 (BASIC)            | 32000.0000 | --      | --                 | 1     | active |

	### EmployeeLoanType [REF] -- one row per employee loan or advance product
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (SAL-ADV, EMG-LOAN)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- entity_id               -- FK Entity nullable -- NULL = platform seed
		- max_amount              -- numeric(15,4) nullable -- absolute cap
		- max_basic_multiple      -- numeric(5,2) nullable -- cap as N x basic
		- max_tenor_months        -- integer
		- min_service_months      -- integer nullable -- minimum tenure before the product may be requested
		- interest_rate_percent   -- numeric(7,4) -- 0 for interest-free advances
		- max_installment_percent_of_net -- numeric(5,2) -- deduction guardrail (e.g. 33.00 of net)
		- payroll_component_id    -- FK PayrollComponent -- deduction component installments post to
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code     | name (en)         | entity_id | max_amount  | max_basic_multiple | max_tenor_months | interest | max_inst_%_net | state  |
			| -- | -------- | ----------------- | --------- | ----------- | ------------------ | ---------------- | -------- | -------------- | ------ |
			| 1  | SAL-ADV  | Salary Advance    | 1         | --          | 1.00               | 3                | 0.0000   | 33.00          | active |
			| 2  | EMG-LOAN | Emergency Loan    | 1         | 50000.0000  | 3.00               | 12               | 0.0000   | 33.00          | active |
			| 3  | EDU-LOAN | Education Loan    | 3         | 100000.0000 | 5.00               | 24               | 5.0000   | 25.00          | active |
			| 4  | DEV-ADV  | Device Advance    | 7         | 30000.0000  | 2.00               | 10               | 0.0000   | 20.00          | active |
			| 5  | HSG-LOAN | Housing Loan      | 3         | 500000.0000 | 10.00              | 60               | 7.0000   | 33.00          | active |

	### BenefitPlan [REF] -- one row per non-cash or insured benefit (medical, insurance, transport...)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (MED-NIB, LIFE-AWASH)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- entity_id               -- FK Entity nullable -- NULL = platform seed
		- benefit_type_lookup_value_id -- FK LookupValue (BENEFIT_TYPE: medical | life_insurance | transport | housing | meal | communication | education | fuel)
		- provider_party_id       -- FK Party nullable -- insurer / vendor as a Party
		- employer_cost_amount    -- numeric(15,4) nullable -- monthly employer cost per member
		- employee_cost_amount    -- numeric(15,4) nullable -- monthly employee contribution (payroll deduction)
		- payroll_component_id    -- FK PayrollComponent nullable -- deduction/benefit component it posts through
		- percent_to_be_covered   -- Number -- percentage of the cost that the employer pays; the remainder is deducted from the employee's pay
		- covers_dependents       -- bool
		- min_service_months      -- integer nullable -- minimum tenure before enrolment; NULL = no tenure threshold  -- new
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: eligibility is min_service_months AND the grade set AND the employment-type set, with the two
		  -- sets held in BenefitPlanJobGrade / BenefitPlanEmploymentType below (replaces the old eligibility_rule
		  -- jsonb). Within a set the values are OR-ed; an EMPTY set means that dimension does not restrict.
		  -- No rows in either set and a NULL min_service_months = everyone may enrol, the old NULL semantics.
		> examples:
			| id | code       | name (en)              | benefit_type   | provider_party_id | employer_cost | employee_cost | covers_dependents | min_service_months | effective_from | state  |
			| -- | ---------- | ---------------------- | -------------- | ----------------- | ------------- | ------------- | ----------------- | ------------------ | -------------- | ------ |
			| 1  | MED-NIB    | NIB Medical Cover      | medical        | 801               | 850.0000      | 150.0000      | true              | 6                  | 2026-07-08     | active |
			| 2  | LIFE-AWASH | Awash Life Insurance   | life_insurance | 802               | 300.0000      | 0.0000        | false             | 12                 | 2026-07-08     | active |
			| 3  | TRN-BUS    | Staff Bus              | transport      | 803               | 400.0000      | 0.0000        | false             | --                 | 2026-07-08     | active |
			| 4  | MEAL-CANT  | Canteen Meal Plan      | meal           | --                | 600.0000      | 200.0000      | false             | --                 | 2026-07-08     | active |
			| 5  | COMM-AIR   | Airtime Package        | communication  | 804               | 250.0000      | 0.0000        | false             | 3                  | 2026-07-08     | active |

	### BenefitPlanJobGrade [LINE] -- new -- one row per grade a plan is open to; part of the eligibility rule that replaced the eligibility_rule jsonb
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- benefit_plan_id         -- FK BenefitPlan -- parent plan
		- job_grade_id            -- FK JobGrade -- a grade whose holders may enrol -- UNIQUE (benefit_plan_id, job_grade_id)
		- state                   -- active / inactive
		  -- note: NO rows for a plan = the plan does not restrict by grade. Rows are OR-ed with each other.
		> examples: (medical is open to every grade -- it has no rows; life cover and airtime are management-only)
			| id | benefit_plan_id        | job_grade_id | state  |
			| -- | ---------------------- | ------------ | ------ |
			| 1  | 2 (LIFE-AWASH)         | 6 (B1)       | active |
			| 2  | 2 (LIFE-AWASH)         | 7 (A3)       | active |
			| 3  | 5 (COMM-AIR)           | 5 (B2)       | active |
			| 4  | 5 (COMM-AIR)           | 6 (B1)       | active |
			| 5  | 5 (COMM-AIR)           | 7 (A3)       | active |

	### BenefitPlanEmploymentType [LINE] -- new -- one row per employment type a plan is open to; the second half of the eligibility rule
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- benefit_plan_id         -- FK BenefitPlan -- parent plan
		- employment_type_lookup_value_id -- FK LookupValue (EMPLOYMENT_TYPE: permanent | contract | temporary | probation | part_time | intern | consultant) -- UNIQUE (benefit_plan_id, employment_type_lookup_value_id)
		- state                   -- active / inactive
		  -- note: NO rows for a plan = the plan does not restrict by employment type. Rows are OR-ed with each
		  -- other and AND-ed with the grade set and min_service_months on the parent plan.
		> examples: (the staff bus carries no rows, so casual and intern staff ride it too)
			| id | benefit_plan_id | employment_type | state  |
			| -- | --------------- | --------------- | ------ |
			| 1  | 1 (MED-NIB)     | permanent       | active |
			| 2  | 1 (MED-NIB)     | contract        | active |
			| 3  | 2 (LIFE-AWASH)  | permanent       | active |
			| 4  | 4 (MEAL-CANT)   | permanent       | active |
			| 5  | 4 (MEAL-CANT)   | part_time       | active |

	### BenefitPlanAssignment [DIST] -- one row per SEAT made eligible for a plan; BenefitEnrollment is the individual employee joining it
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- position_id             -- FK JobPosition -- the seat the plan is attached to
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- benefit_plan_id         -- FK BenefitPlan -- plan joined
		- assignment_state_lookup_value_id -- FK LookupValue (BENEFIT_PLAN_ASSIGNMENT_STATE: pending | active | suspended | ended)
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | position_id             | entity_id | benefit_plan_id | assignment_state | effective_from | effective_to | state  |
			| -- | ----------------------- | --------- | --------------- | ---------------- | -------------- | ------------ | ------ |
			| 1  | 12 (HR Officer)         | 3         | 1               | active           | 2026-07-08     | --           | active |
			| 2  | 31 (Financial Account.) | 3         | 1               | active           | 2026-07-08     | --           | active |
			| 3  | 30 (Finance Manager)    | 3         | 2               | active           | 2026-07-08     | --           | active |
			| 4  | 24 (Senior Cashier)     | 7         | 3               | active           | 2026-07-08     | --           | active |
			| 5  | 40 (Procurement Off.)   | 9         | 4               | pending          | 2026-08-01     | --           | active |

	### BenefitEnrollment [DIST] -- one row per employee joined to an assigned plan; dependents ride along
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- enrolled member
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- benefit_plan_assignment_id         -- FK BenefitPlanAssignment -- plan joined
		- enrollment_state_lookup_value_id -- FK LookupValue (BENEFIT_ENROLLMENT_STATE: pending | active | suspended | ended)
		- membership_number       -- text nullable -- insurer card number
		- assigned_amount         -- numeric(15,4) nullable -- per-employee entitlement overriding the plan default (tiered benefits)
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | employee_id | benefit_plan_assignment_id | enrollment_state | dependents (pivot)     | membership_number | assigned_amount | effective_from | effective_to | state  |
			| -- | ----------- | -------------------------- | ---------------- | ---------------------- | ----------------- | --------------- | -------------- | ------------ | ------ |
			| 1  | 7           | 1                          | active           | [1, 2]                 | NIB-77120         | --              | 2026-07-08     | --           | active |
			| 2  | 22          | 2                          | active           | [3]                    | NIB-77245         | --              | 2026-07-08     | --           | active |
			| 3  | 44          | 3                          | active           | --                     | AWL-2210          | 500000.0000     | 2026-07-08     | --           | active |
			| 4  | 14          | 4                          | active           | --                     | --                | --              | 2026-07-08     | --           | active |
			| 5  | 31          | 5                          | pending          | --                     | --                | --              | 2026-08-01     | --           | active |

	### BenefitEnrollmentDependent [LINE] -- new -- one row per covered dependent on an enrollment; replaces the enrolled_dependent_ids jsonb array (FK-enforceable, queryable)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- benefit_enrollment_id   -- FK BenefitEnrollment -- parent enrollment
		- employee_dependent_id   -- FK EmployeeDependent -- the covered member -- UNIQUE (benefit_enrollment_id, employee_dependent_id)
		- state                   -- active / inactive
		> examples:
			| id | benefit_enrollment_id | employee_dependent_id | state  |
			| -- | --------------------- | --------------------- | ------ |
			| 1  | 1                     | 1                     | active |
			| 2  | 1                     | 2                     | active |
			| 3  | 2                     | 3                     | active |

	### MedicalTariff [REF] -- one row per treatment class ceiling; caps what a MedicalClaim may reimburse, at government and private rates  -- (Q8 -- confirm new table)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (TRF-OUTPATIENT, TRF-DENTAL)
		- name                    -- jsonb (localized)
		- entity_id               -- FK Entity nullable -- NULL = platform seed
		- treatment_type_lookup_value_id -- FK LookupValue (MEDICAL_TREATMENT_TYPE: outpatient | inpatient | dental | optical | maternity | chronic_illness | emergency | diagnostic)
		- benefit_plan_id         -- FK BenefitPlan nullable -- the insured plan this tariff belongs to; NULL = self-funded scheme
		- government_rate_amount  -- numeric(15,4) nullable -- ceiling when treated at a public facility
		- private_rate_amount     -- numeric(15,4) nullable -- ceiling when treated at a private facility
		- max_amount_per_year     -- numeric(15,4) nullable -- annual cap per member; NULL = uncapped
		- covers_dependents       -- bool -- dependents claim against the same ceiling as the member
		- currency_id             -- FK Currency
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code           | name (en)          | entity_id | treatment_type  | government_rate | private_rate | max_amount_per_year | covers_dependents | state  |
			| -- | -------------- | ------------------ | --------- | --------------- | --------------- | ------------ | ------------------- | ----------------- | ------ |
			| 1  | TRF-OUTPATIENT | Outpatient care    | 3         | outpatient      | 1500.0000       | 3000.0000    | 20000.0000          | true              | active |
			| 2  | TRF-INPATIENT  | Inpatient / surgery| 3         | inpatient       | 25000.0000      | 60000.0000   | 120000.0000         | true              | active |
			| 3  | TRF-DENTAL     | Dental treatment   | 3         | dental          | 1200.0000       | 2500.0000    | 8000.0000           | false             | active |
			| 4  | TRF-OPTICAL    | Optical / lenses   | 3         | optical         | 1000.0000       | 2200.0000    | 4400.0000           | false             | active |
			| 5  | TRF-MATERNITY  | Maternity care     | 3         | maternity       | 12000.0000      | 35000.0000   | 70000.0000          | true              | active |

	### MedicalClaim [DIST] -- new -- one row per medical reimbursement request (member or covered dependent); referenced by PayrollInput / PayslipComponent source_type = 'MedicalClaim'
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (MCL-2026-0021)
		- employee_id             -- FK Employee -- the claiming member
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- benefit_enrollment_id   -- FK BenefitEnrollment nullable -- the medical plan claimed against; NULL = self-funded entity scheme
		- employee_dependent_id   -- FK EmployeeDependent nullable -- set when the treated person is a covered dependent
		- medical_tariff_id       -- FK MedicalTariff nullable -- the treatment-class ceiling applied at assessment
		- provider_party_id       -- FK Party nullable -- treating facility as a Party
		- treatment_date          -- date
		- claimed_amount          -- numeric(15,4)
		- approved_amount         -- numeric(15,4) nullable -- capped by the tariff (government vs private rate) and the annual ceiling
		- currency_id             -- FK Currency
		- claim_state_lookup_value_id -- FK LookupValue (MEDICAL_CLAIM_STATE: draft | submitted | pending_approval | assessed | approved | rejected | reimbursed | cancelled)
		- assessed_by_employee_id -- FK Employee nullable
		- assessed_at             -- timestamp nullable
		- rejection_reason        -- jsonb nullable
		- user_id                 -- FK User -- who created the row (self-service or HR)
		- state                   -- active / inactive
		  -- note: receipts attach via DocumentAttachment ('HR:MedicalClaim'); approval via core Workflow; a claim settling over two periods produces two PayrollInputs, exactly like ExpenseClaim.
		> examples:
			| id | code          | employee_id | treatment_type | claimed_amount | approved_amount | claim_state | state  |
			| -- | ------------- | ----------- | -------------- | -------------- | --------------- | ----------- | ------ |
			| 21 | MCL-2026-0021 | 22          | outpatient     | 1800.0000      | 1500.0000       | reimbursed  | active |
			| 22 | MCL-2026-0022 | 14          | dental         | 2600.0000      | 2500.0000       | approved    | active |
			| 23 | MCL-2026-0023 | 7           | maternity      | 30000.0000     | --              | submitted   | active |
			| 24 | MCL-2026-0024 | 31          | optical        | 2500.0000      | --              | rejected    | active |
			| 25 | MCL-2026-0025 | 44          | inpatient      | 45000.0000     | 45000.0000      | assessed    | active |

	### BonusScheme [DIST] -- one row per mass-bonus rule set (annual, holiday, profit share); a bonus PayrollRun consumes it
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code (NEWYEAR_2026, PROFIT_SHARE_2026)
		- name                    -- jsonb (localized)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- currency_id             -- FK Currency
		- base_lookup_value_id    -- FK LookupValue (BONUS_BASE: basic_salary | gross_salary | last_month_net | flat_amount)
		- months_of_salary        -- numeric(6,2) nullable -- 1.00 = one month of the base, 0.5 = half; NULL when base = flat_amount
		- flat_amount             -- numeric(15,4) nullable -- when base = flat_amount
		- min_service_months      -- integer nullable -- eligibility gate
		- proration_lookup_value_id -- FK LookupValue (BONUS_PRORATION: none | daily | monthly | mid_month_rounding)
		- scheme_state_lookup_value_id -- FK LookupValue (BONUS_SCHEME_STATE: draft | approved | processed | cancelled)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code         | name (en)       | entity_id | base         | months_of_salary | flat_amount | min_service_months | proration          | eligible types (pivot)       | scheme_state | state  |
			| -- | ------------ | --------------- | --------- | ------------ | ---------------- | ----------- | ------------------ | ------------------ | ---------------------------- | ------------ | ------ |
			| 1  | NEWYEAR_2026 | New Year Bonus  | 3         | basic_salary | 1.00             | --          | 6                  | monthly            | [1, 2]                       | processed    | active |
			| 2  | MESKEL_2026  | Meskel Gratuity | 3         | flat_amount  | --               | 500.0000    | 3                  | none               | [1, 2, 3]                    | approved     | active |
			| 3  | PROFIT_2026  | Profit Share    | 3         | basic_salary | 0.50             | --          | 12                 | monthly            | [1]                          | approved     | active |
			| 4  | EID_2026     | Eid Bonus       | 7         | flat_amount  | --               | 750.0000    | 3                  | none               | [1, 2, 3]                    | processed    | active |
			| 5  | ANNUAL_2027  | FY2027 Annual   | 3         | gross_salary | 1.00             | --          | 12                 | mid_month_rounding | [1]                          | draft        | active |

	### BonusSchemeEmploymentType [LINE] -- new -- one row per employment type eligible under a scheme; replaces the eligible_employment_type_ids jsonb array
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- bonus_scheme_id         -- FK BonusScheme -- parent scheme
		- employment_type_lookup_value_id -- FK LookupValue (EMPLOYMENT_TYPE: permanent | contract | temporary | probation | part_time | intern | consultant) -- UNIQUE (bonus_scheme_id, employment_type_lookup_value_id)
		- state                   -- active / inactive
		> examples:
			| id | bonus_scheme_id | employment_type | state  |
			| -- | --------------- | --------------- | ------ |
			| 1  | 1               | permanent       | active |
			| 2  | 1               | contract        | active |
			| 3  | 2               | permanent       | active |

	### EmployeeProvidentFundAccount [DIST] -- one row per employee's voluntary provident fund account; distinct from the mandatory pension
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- UNIQUE -- one PF account per employee
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- code                    -- via DocumentSequence (PF-EMP-0022)
		- employee_contribution_percent -- numeric(5,2) -- % of basic the employee contributes
		- employer_match_percent  -- numeric(5,2) -- employer's matching %
		- start_date              -- date -- enrollment date
		- end_date                -- date nullable -- closure / withdrawal date
		- opening_balance         -- numeric(15,4) default 0
		- fund_state_lookup_value_id -- FK LookupValue (PROVIDENT_FUND_STATE: pending | active | suspended | closed)
		- vesting_years           -- integer nullable -- service years for full vesting; NULL = immediate
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: contributions ride payroll as PF_EMPLOYEE / PF_EMPLOYER PayrollComponent lines; the running balance is the sum of those PayslipComponent lines since start_date -- no separate ledger table.
		> examples:
			| id | employee_id | code        | employee_contribution_percent | employer_match_percent | start_date | pf_state | vesting_years | state  |
			| -- | ----------- | ----------- | ----------------------------- | ---------------------- | ---------- | -------- | ------------- | ------ |
			| 1  | 7           | PF-EMP-0007 | 5.00                          | 5.00                   | 2022-07-01 | active   | 3             | active |
			| 2  | 22          | PF-EMP-0022 | 7.50                          | 5.00                   | 2021-10-01 | active   | 3             | active |
			| 3  | 44          | PF-EMP-0044 | 10.00                         | 5.00                   | 2020-04-01 | active   | 3             | active |
			| 4  | 14          | PF-EMP-0014 | 3.00                          | 3.00                   | 2024-07-01 | active   | 3             | active |
			| 5  | 31          | PF-EMP-0031 | --                            | --                     | --         | pending  | 3             | active |

	### AdminUnitPerdiem [REF] -- one row per destination-specific daily allowance; used when the per-diem is priced by WHERE the employee travels rather than by their grade band
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- admin_unit_id           -- FK AdminUnit -- the destination (region / zone / woreda / town)
		- entity_id               -- FK Entity nullable -- NULL = platform template
		- amount                  -- numeric(15,4) -- daily allowance for travel to this destination, ETB
		- currency_id             -- FK Currency
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: EmployeePerdiem points at either this row (destination-priced) or a PerDiemRate band (grade-priced), never both.
		> examples:
			| id | admin_unit_id      | entity_id | amount     | currency | effective_from | effective_to | state  |
			| -- | ------------------ | --------- | ---------- | -------- | -------------- | ------------ | ------ |
			| 1  | 305 (Addis Ababa)  | 1         | 600.0000   | ETB      | 2026-07-08     | --           | active |
			| 2  | 401 (Bahir Dar)    | 1         | 800.0000   | ETB      | 2026-07-08     | --           | active |
			| 3  | 315 (Hawassa)      | 1         | 800.0000   | ETB      | 2026-07-08     | --           | active |
			| 4  | 420 (Semera)       | 1         | 1100.0000  | ETB      | 2026-07-08     | --           | active |
			| 5  | 305 (Addis Ababa)  | 1         | 500.0000   | ETB      | 2025-07-08     | 2026-07-07   | active |

	### PerDiemRate [REF] -- one row per per-diem entitlement band; prices EXPENSE_TYPE = per_diem instead of leaving the daily amount to the claimant  -- (Q8 -- confirm new table)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (PD-BAND-A, PD-BAND-B)
		- name                    -- jsonb (localized)
		- entity_id               -- FK Entity nullable -- NULL = platform template
		- job_grade_step_id            -- FK JobGradeStep nullable -- band keyed to a grade step; NULL = matched on the salary range instead
		- salary_amount_percent   -- numeric(5,2) nullable -- band priced as % of the employee's salary (4.00 = 4%)
		- fixed_value             -- numeric(15,4) nullable -- flat daily amount alternative (900 = any employee on this band gets 900)
		- inside_region_amount    -- numeric(15,4) -- daily allowance for travel inside the duty region
		- outside_region_amount   -- numeric(15,4) -- daily allowance for travel to another region
		- abroad_amount           -- numeric(15,4) nullable -- daily allowance for foreign travel
		- accommodation_ceiling_amount -- numeric(15,4) nullable -- lodging cap per night, claimed against a receipt
		- currency_id             -- FK Currency
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- is_system               -- platform-seeded row
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: ExpenseClaimLine.amount for a per_diem line is validated against the matching band; the band is never copied onto the line.
		> examples:
			| id | code      | name (en)         | entity_id | job_grade_step_id | salary_amount_percent | fixed_value | inside_region_amount | outside_region_amount | abroad_amount | accommodation_ceiling_amount | currency | state  |
			| -- | --------- | ----------------- | --------- | ----------------- | --------------------- | ----------- | -------------------- | --------------------- | ------------- | ---------------------------- | -------- | ------ |
			| 1  | PD-BAND-A | Executive Band    | 1         | 21                | --                    | --          | 900.0000             | 1200.0000             | 6500.0000     | 3000.0000                    | ETB      | active |
			| 2  | PD-BAND-B | Management Band   | 1         | 18                | --                    | --          | 750.0000             | 1000.0000             | 5500.0000     | 2400.0000                    | ETB      | active |
			| 3  | PD-BAND-C | Professional Band | 1         | 15                | 4.00                  | --          | 600.0000             | 800.0000              | 4500.0000     | 1800.0000                    | ETB      | active |
			| 4  | PD-BAND-D | Officer Band      | 1         | 12                | --                    | 900.0000    | 480.0000             | 650.0000              | --            | 1200.0000                    | ETB      | active |
			| 5  | PD-BAND-E | Support Band      | 1         | 9                 | --                    | 900.0000    | 380.0000             | 500.0000              | --            | 900.0000                     | ETB      | active |

	### EmployeePerdiem [DIST] -- one row per employee's per-diem entitlement; binds the employee to a band (or destination pricing); the expense claim line picks the location column
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- the entitled person
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- perdiem_rate_id         -- FK PerDiemRate nullable; either this or admin_unit_perdiem_id must be set
		- admin_unit_perdiem_id   -- FK AdminUnitPerdiem nullable -- destination-priced alternative
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: exactly one of perdiem_rate_id / admin_unit_perdiem_id is set per row.
		> examples:
			| id | employee_id | entity_id | perdiem_rate_id | admin_unit_perdiem_id | state  |
			| -- | ----------- | --------- | --------------- | --------------------- | ------ |
			| 1  | 44          | 3         | 1               | --                    | active |
			| 2  | 7           | 3         | 3               | --                    | active |
			| 3  | 22          | 3         | 3               | --                    | active |
			| 4  | 31          | 9         | --              | 2                     | active |
			| 5  | 14          | 7         | --              | 1                     | active |


#9. HR -- Payroll execution

	## lookups first used in this section
		- PAYROLL_PERIOD_STATE        : open | processing | locked | closed
		- TIMESHEET_STATE             : draft | submitted | approved | rejected | locked
		- TIMESHEET_APPROVAL_STATE    : pending | approved | rejected
		  -- used by TimesheetEntryApproval.approval_state_lookup_value_id; per-approver verdict inside the timesheet chain
		- PAYROLL_RUN_STATE           : draft | calculated | verified | approved | posted | paid | reversed
		- PAYROLL_RUN_TYPE            : regular | off_cycle | bonus | back_pay | final_settlement
		- PAYROLL_INPUT_STATE         : draft | pending | approved | rejected
		- PAYROLL_INPUT_TYPE          : overtime | bonus | commission | absence_deduction | reimbursement | adjustment
		- BACK_PAY_STATE              : draft | pending | approved | processed | cancelled
		- PAYROLL_EXCEPTION_SEVERITY  : blocking | warning
		- PAYROLL_EXCEPTION_STATE     : open | resolved | waived
		- PAYROLL_EXCEPTION_TYPE      : missing_tin | missing_pension_number | missing_bank_account | negative_net_pay | salary_variance | incomplete_attendance
		- PAYSLIP_STATE               : draft | issued | paid | reversed
		- PAYMENT_BATCH_METHOD        : bank_transfer | cash_via_cashier | cheque | mobile_money
		- PAYMENT_BATCH_STATE         : draft | pending_approval | approved | sent_to_bank | confirmed | partially_failed | cancelled
		- LOAN_STATE                  : draft | pending | approved | disbursed | repaying | settled | written_off
		- PAYMENT_INSTRUCTION_STATE   : pending | sent | confirmed | failed | returned
		- LOAN_INSTALLMENT_STATE      : scheduled | deducted | paid | skipped | waived
		- STATUTORY_REPORT_STATE      : draft | generated | filed | acknowledged
		- STATUTORY_REPORT_TYPE       : income_tax_declaration | pension_remittance
		- BONUS_STATE                 : pending | approved | paid | cancelled
		  -- used by EmployeeBonus.bonus_state_lookup_value_id; tracks the individual employee bonus transaction lifecycle
		- EMPLOYEE_DEDUCTION_STATE    : draft | pending | approved | active | completed | cancelled
		- EXPENSE_CLAIM_STATE         : draft | submitted | pending_approval | approved | rejected | reimbursed | cancelled
		- EXPENSE_TYPE                : per_diem | transport | meal | accommodation | telecom | office_supplies | training_related | fuel | mileage | other

	### PayrollPeriod [DIST] -- one row per pay window per payroll group
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per group (PP-2026-07)
		- name                    -- jsonb (localized) -- { en: "July 2026", am: "Hamle 2018" }
		- payroll_group_id        -- FK PayrollGroup -- who is paid in this window
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- period_state_lookup_value_id -- FK LookupValue (PAYROLL_PERIOD_STATE: open | processing | locked | closed)
		- start_date              -- date
		- end_date                -- date
		- pay_date                -- date -- scheduled disbursement date
		- fiscal_year_label       -- text -- "2018/2019 EC"
		- locked_at               -- timestamp nullable -- locking also locks AttendanceDay + Timesheet rows in range
		- reopened_at             -- timestamp nullable -- controlled reopen of a closed period; an audited exception, never routine
		- reopened_by_user_id     -- FK User nullable
		- reopen_reason           -- jsonb nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		- locked_by_user_id       -- FK User nullable -- who locked the period
		- closed_at               -- timestamp nullable -- when the period was closed; the reopen side is already audited, this completes the pair
		> examples:
			| id | code       | name (en)   | payroll_group_id | period_state | start_date | end_date   | pay_date   | fiscal_year  | state  |
			| -- | ---------- | ----------- | ---------------- | ------------ | ---------- | ---------- | ---------- | ------------ | ------ |
			| 6  | PP-2026-06 | June 2026   | 2                | closed       | 2026-06-01 | 2026-06-30 | 2026-06-26 | 2017/2018 EC | active |
			| 7  | PP-2026-07 | July 2026   | 2                | processing   | 2026-07-01 | 2026-07-31 | 2026-07-26 | 2018/2019 EC | active |
			| 8  | PP-2026-07H| July 2026 HQ| 1                | processing   | 2026-07-01 | 2026-07-31 | 2026-07-26 | 2018/2019 EC | active |
			| 9  | PP-2026-07B| July 2026 BD| 3                | open         | 2026-07-01 | 2026-07-31 | 2026-07-26 | 2018/2019 EC | active |
			| 10 | PP-2026-08 | August 2026 | 2                | open         | 2026-08-01 | 2026-08-31 | 2026-08-26 | 2018/2019 EC | active |

	### Timesheet [DIST] -- one row per employee per payroll period; container for entries, approval via core Workflow
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (TS-2026-07-0014)
		- employee_id             -- FK Employee -- whose time this is
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- payroll_period_id       -- FK PayrollPeriod -- the period this timesheet feeds
		- timesheet_state_lookup_value_id -- FK LookupValue (TIMESHEET_STATE: draft | submitted | approved | rejected | locked)
		- total_worked_minutes    -- integer -- cache/denormalized rollup of entries
		- total_overtime_minutes  -- integer -- cache/denormalized rollup of entries
		- submitted_at            -- timestamp nullable
		- approver_employee_id    -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id   | code            | employee_id | payroll_period_id | timesheet_state | worked_min | ot_min | approver | state  |
			| ---- | --------------- | ----------- | ----------------- | --------------- | ---------- | ------ | -------- | ------ |
			| 1101 | TS-2026-07-0007 | 7           | 7                 | approved        | 10560      | 0      | 44       | active |
			| 1102 | TS-2026-07-0014 | 14          | 7                 | approved        | 11904      | 180    | 7        | active |
			| 1103 | TS-2026-07-0022 | 22          | 7                 | submitted       | 9600       | 0      | --       | active |
			| 1104 | TS-2026-07-0031 | 31          | 7                 | draft           | 11520      | 180    | --       | active |
			| 1105 | TS-2026-06-0014 | 14          | 6                 | locked          | 11520      | 240    | 7        | active |

	### TimesheetEntry [LINE] -- one row per day (or task split) inside a timesheet; its entity_id is the cost center charged
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- timesheet_id            -- FK Timesheet -- parent document
		- date                    -- date
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- tenancy: copied from the Timesheet header (line rule)
		- cost_entity_id          -- FK Entity nullable -- new -- cost center charged when project costing overrides the header entity; NULL = header entity
		- organization_unit_id    -- FK OrganizationUnit nullable -- org unit or project charged (projects are OrganizationUnit rows with unit_type = project_office)
		- attendance_day_id       -- FK AttendanceDay nullable -- source day when auto-filled
		- worked_minutes          -- integer
		- overtime_minutes        -- integer
		- activity                -- jsonb nullable -- { task: "Stocktake", reference: "GRN-2210" }
		- notes                   -- jsonb nullable
		- workflow_id 		  -- FK Workflow nullable -- approval process instance
		- state                   -- active / inactive
		> examples:
			| id    | timesheet_id | date       | cost_entity_id | attendance_day_id | worked_min | ot_min | activity (task) | state  |
			| ----- | ------------ | ---------- | --------- | ----------------- | ---------- | ------ | --------------- | ------ |
			| 90011 | 1102         | 2026-07-27 | 7         | 810221            | 456        | 0      | --              | active |
			| 90012 | 1102         | 2026-07-26 | 7         | 810225            | 0          | 120    | Stocktake       | active |
			| 90013 | 1101         | 2026-07-27 | 3         | 810222            | 485        | 0      | --              | active |
			| 90014 | 1104         | 2026-07-27 | 9         | 810224            | 416        | 0      | --              | active |
			| 90015 | 1104         | 2026-07-28 | 12        | --                | 480        | 0      | Shop support    | active |

	### TimesheetEntryApproval [LINE] -- one row per approver per timesheet entry; approval via core Workflow
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- timesheet_entry_id      -- FK TimesheetEntry -- parent document
		- workflow_step_id        -- FK WorkflowStep -- the step in the approval workflow
		- approval_state_lookup_value_id -- FK LookupValue (TIMESHEET_APPROVAL_STATE: pending | approved | rejected) -- this step's verdict  -- new
		- approved_at             -- timestamp nullable -- when the step was acted on  -- new
		- remarks                 -- jsonb nullable -- the approver's note  -- new
		- user_id                 -- FK User -- who recorded the step (the acting approver)
		- state                   -- active / inactive
		> examples:
			| id   | timesheet_entry_id | approval_state   | state  |
			| ---- | ------------------ | ---------------- | ------ |
			| 2101 | 90011              | approved         | active |
			| 2102 | 90011              | pending          | active |
			| 2103 | 90013              | approved         | active |
			| 2104 | 90014              | rejected         | active |
			| 2105 | 90015              | pending          | active |

	### PayrollRun [DIST] -- one row per calculation batch over a period; payroll summary, approval via core Workflow, accounting posts downstream from this document
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (RUN-2026-07-002)
		- payroll_period_id       -- FK PayrollPeriod -- period calculated
		- payroll_group_id        -- FK PayrollGroup -- group calculated
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- run_type_lookup_value_id -- FK LookupValue (PAYROLL_RUN_TYPE: regular | off_cycle | bonus | back_pay | final_settlement)
		- run_state_lookup_value_id -- FK LookupValue (PAYROLL_RUN_STATE: draft | calculated | verified | approved | posted | paid | reversed)
		- employee_count          -- integer
		- total_gross             -- numeric(15,4) -- cache/denormalized rollup of payslips
		- total_deductions        -- numeric(15,4) -- cache rollup; incl. income tax + pension EE + loans
		- total_net               -- numeric(15,4) -- cache rollup
		- total_employer_cost     -- numeric(15,4) -- cache rollup; gross + employer contributions
		- currency_id             -- FK Currency
		- calculated_at           -- timestamp nullable
		- approved_by_employee_id -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- reversal_of_run_id      -- FK PayrollRun (self) nullable -- the run this one reverses
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id  | code            | payroll_period_id | run_type | run_state  | employees | total_gross  | total_deductions | total_net    | employer_cost | state  |
			| --- | --------------- | ----------------- | -------- | ---------- | --------- | ------------ | ---------------- | ------------ | ------------- | ------ |
			| 61  | RUN-2026-06-001 | 6                 | regular  | paid       | 42        | 512400.0000  | 138910.0000      | 373490.0000  | 568764.0000   | active |
			| 62  | RUN-2026-07-001 | 7                 | regular  | calculated | 43        | 528730.0000  | 143220.0000      | 385510.0000  | 586890.0000   | active |
			| 63  | RUN-2026-07-002 | 8                 | regular  | verified   | 55        | 1284500.0000 | 402180.0000      | 882320.0000  | 1425795.0000  | active |
			| 64  | RUN-2026-07-003 | 8                 | bonus    | draft      | 12        | 86000.0000   | 25800.0000       | 60200.0000   | 86000.0000    | active |
			| 65  | RUN-2026-06-009 | 6                 | regular  | reversed   | 1         | 6500.0000    | 1230.0000        | 5270.0000    | 7215.0000     | active |

	### PayrollInput [DIST] -- one row per variable per-period per-employee input feeding the calc (OT, bonus, absence deduction, reimbursement)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- payroll_period_id       -- FK PayrollPeriod -- period the input lands in
		- employee_id             -- FK Employee -- who it applies to
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- cost center charged
		- input_type_lookup_value_id -- FK LookupValue (PAYROLL_INPUT_TYPE: overtime | bonus | commission | absence_deduction | reimbursement | adjustment)
		- payroll_component_id    -- FK PayrollComponent -- component the amount posts to
		- quantity                -- numeric(10,2) nullable -- e.g. OT minutes / commission units
		- amount                  -- numeric(15,4) nullable -- direct value when not formula-derived
		- source_type             -- text -- originating document class: 'OvertimeRequest' | 'Timesheet' | 'ExpenseClaim' | 'MedicalClaim' | 'LeaveEncashmentRequest' | 'AttendanceDay' | 'TrainingCommitment' | 'SalesCommissionRun' (future Sales contract -- no such table yet) | 'Manual'
		- source_id               -- integer nullable -- primary key of that document; NULL only when source_type = 'Manual'
		  -- UNIQUE (source_type, source_id, payroll_component_id, payroll_period_id) -- feeder-side idempotency: a feeder run twice cannot create a second input, while one document settling over two periods still can
		- input_state_lookup_value_id -- FK LookupValue (PAYROLL_INPUT_STATE: draft | pending | approved | rejected) -- ad-hoc bonuses and adjustments need approval before the run consumes them
		- approved_by_employee_id -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row (person or system feeder)
		- state                   -- active / inactive
		- rate                    -- numeric(15,6) nullable -- unit rate behind quantity; mirrors PayslipComponent.rate so the calc need not re-derive it
		- processed_in_payroll_run_id -- FK PayrollRun nullable -- the run that consumed this input; blocks double payment across off-cycle and correction runs
		> examples:
			| id   | payroll_period_id | employee_id | input_type        | payroll_component_id | quantity | amount     | source_type        | source_id | state  |
			| ---- | ----------------- | ----------- | ----------------- | -------------------- | -------- | ---------- | ------------------ | --------- | ------ |
			| 2201 | 7                 | 14          | overtime          | 3 (OT)               | 180.00   | --         | OvertimeRequest    | 221       | active |
			| 2202 | 7                 | 14          | commission        | 6 (COMM)             | --       | 450.0000   | SalesCommissionRun | 88        | active |
			| 2203 | 8                 | 22          | reimbursement     | 7 (REIMB)            | --       | 1280.0000  | ExpenseClaim       | 38        | active |
			| 2204 | 8                 | 7           | bonus             | 8 (BONUS)            | --       | 3000.0000  | Manual             | --        | active |
			| 2205 | 7                 | 15          | absence_deduction | 9 (ABSENT)           | 1.00     | --         | AttendanceDay      | 810230    | active |

	### BackPayTransaction [DIST] -- one row per retro adjustment spanning one or more past periods; a back_pay PayrollRun consumes it
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (BPT-2026-0033)
		- employee_id             -- FK Employee -- who is owed the adjustment
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- payroll_group_id        -- FK PayrollGroup -- group the adjustment runs through
		- start_period_id         -- FK PayrollPeriod -- earliest period the back-pay applies to
		- end_period_id           -- FK PayrollPeriod -- last period, inclusive
		- payroll_component_id    -- FK PayrollComponent -- pay element the adjustment attaches to
		- applied_amount          -- numeric(15,4) -- amount applied PER period (times period count = total)
		- reason                  -- jsonb -- localized narrative ({ en: "Salary revision retroactive to Hamle" })
		- reference_type          -- text nullable -- pointer: 'EmployeeSalary' | 'CompensationProposal'
		- reference_id            -- integer nullable
		- back_pay_state_lookup_value_id -- FK LookupValue (BACK_PAY_STATE: draft | pending | approved | processed | cancelled)
		- approved_by_employee_id -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- processed_in_payroll_run_id -- FK PayrollRun nullable -- the back_pay run that consumed this
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: one transaction spanning N periods produces one Payslip line per period on the back_pay run.
		> examples:
			| id | code           | employee_id | start_period_id | end_period_id | payroll_component_id | monthly_amount | back_pay_state | processed_in_run | state  |
			| -- | -------------- | ----------- | --------------- | ------------- | -------------------- | -------------- | -------------- | ---------------- | ------ |
			| 33 | BPT-2026-0033  | 22          | 8               | 11            | 1 (BASIC)            | 2000.0000      | processed      | 512              | active |
			| 34 | BPT-2026-0034  | 44          | 9               | 12            | 1 (BASIC)            | 3000.0000      | approved       | --               | active |
			| 35 | BPT-2026-0035  | 14          | 12              | 12            | 7 (COMMISSION)       | 850.0000       | pending        | --               | active |
			| 36 | BPT-2026-0036  | 7           | 10              | 12            | 2 (TRANS_ALLOW)      | 500.0000       | draft          | --               | active |
			| 37 | BPT-2026-0037  | 31          | 11              | 12            | 1 (BASIC)            | 1200.0000      | processed      | 513              | active |

	### PayrollException [DIST] -- one row per per-employee blocker or warning raised while calculating a run; a run with open BLOCKING exceptions cannot be approved
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- payroll_run_id          -- FK PayrollRun -- the run that raised it
		- employee_id             -- FK Employee -- the person who failed the check
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- exception_type_lookup_value_id -- FK LookupValue (PAYROLL_EXCEPTION_TYPE: missing_tin | missing_pension_number | missing_bank_account | negative_net_pay | salary_variance | incomplete_attendance)
		- severity_lookup_value_id -- FK LookupValue (PAYROLL_EXCEPTION_SEVERITY: blocking | warning)
		- exception_state_lookup_value_id -- FK LookupValue (PAYROLL_EXCEPTION_STATE: open | resolved | waived) -- waiving is a conscious, recorded decision
		- description             -- jsonb -- what the calculation found ({ en: "Net pay -312.50 after loan installment" })
		- resolution_note         -- jsonb nullable
		- resolved_by_employee_id -- FK Employee nullable
		- resolved_at             -- timestamp nullable
		- state                   -- active / inactive
		- user_id                 -- FK User -- who created the row
		> examples:
			| id | payroll_run_id | employee_id | exception_type        | severity | exception_state | description (en)                    | resolved_by | state  |
			| -- | -------------- | ----------- | --------------------- | -------- | --------------- | ----------------------------------- | ----------- | ------ |
			| 1  | 62             | 31          | missing_bank_account  | blocking | resolved        | No verified salary account          | 7           | active |
			| 2  | 62             | 15          | negative_net_pay      | blocking | resolved        | Net -312.50 after loan installment  | 22          | active |
			| 3  | 63             | 58          | missing_pension_number| warning  | waived          | Expat -- pension exemption on file  | 44          | active |
			| 4  | 63             | 19          | salary_variance       | warning  | open            | Gross +28% vs June                  | --          | active |
			| 5  | 63             | 20          | incomplete_attendance | blocking | open            | 6 days missing punches              | --          | active |

	### Payslip [DIST] -- one row per employee per run; PDF via DocumentAttachment ('HR:Payslip')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (PSL-2026-07-0014)
		- payroll_run_id          -- FK PayrollRun -- run that produced it
		- employee_id             -- FK Employee -- who is paid
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- cost center
		- employee_salary_id      -- FK EmployeeSalary -- package version used
		- payslip_state_lookup_value_id -- FK LookupValue (PAYSLIP_STATE: draft | issued | paid | reversed)
		- worked_days             -- numeric(5,2) -- days actually worked; daily rate = basic / payroll_days_per_month
		- scheduled_days          -- numeric(4,1) -- working days the calendar expected this period
		- absent_days             -- numeric(4,1) -- unexcused; drives the absence deduction
		- leave_days              -- numeric(4,1) -- approved leave days inside the period
		- overtime_hours          -- numeric(6,2) -- approved OT consumed by this slip
		- organization_unit_id    -- FK OrganizationUnit -- cache/denormalized snapshot at run time; cost reporting survives later transfers
		- gross_amount            -- numeric(15,4)
		- taxable_amount          -- numeric(15,4)
		- income_tax_amount       -- numeric(15,4) -- from the TaxBracket slab
		- pension_employee_amount -- numeric(15,4) -- 7% of pensionable (StatutoryRule)
		- pension_employer_amount -- numeric(15,4) -- 11% of pensionable (StatutoryRule)
		- other_deductions_amount -- numeric(15,4) -- loans, benefit contributions...
		- net_amount              -- numeric(15,4)
		- currency_id             -- FK Currency
		- employee_bank_account_id -- FK EmployeeBankAccount nullable -- pay destination snapshot
		- released_at             -- timestamp nullable -- when the payslip became visible to the employee in self-service
		- job_grade_id            -- FK JobGrade -- cache/denormalized snapshot at run time, like organization_unit_id; pay-band and compa-ratio reporting survives later promotions
		- employer_contribution_amount -- numeric(15,4) -- total employer-side cost on this slip (pension employer + medical + PF match...); per-employee true cost without re-aggregating lines
		- state                   -- active / inactive
		- user_id                 -- FK User -- who created the row
		  -- note: money columns are cache/denormalized rollups of PayslipComponent lines, frozen at calculation time.
		> examples:
			| id    | code             | payroll_run_id | employee_id | worked_days | gross      | taxable    | income_tax | pension_ee | pension_er | other_ded | net        | state  |
			| ----- | ---------------- | -------------- | ----------- | ----------- | ---------- | ---------- | ---------- | ---------- | ---------- | --------- | ---------- | ------ |
			| 60214 | PSL-2026-07-0014 | 62             | 14          | 26.00       | 8575.0000  | 6950.0000  | 1172.5000  | 455.0000   | 715.0000   | 2166.6700 | 4780.8300  | active |
			| 60222 | PSL-2026-07-0022 | 63             | 22          | 22.00       | 14200.0000 | 12000.0000 | 2435.0000  | 840.0000   | 1320.0000  | 2500.0000 | 8425.0000  | active |
			| 60223 | PSL-2026-07-0023 | 63             | 23          | 22.00       | 14200.0000 | 12000.0000 | 2435.0000  | 840.0000   | 1320.0000  | 0.0000    | 10925.0000 | active |
			| 60207 | PSL-2026-07-0007 | 63             | 7           | 26.00       | 16800.0000 | 14000.0000 | 3115.0000  | 980.0000   | 1540.0000  | 0.0000    | 12705.0000 | active |
			| 60244 | PSL-2026-07-0044 | 63             | 44          | 26.00       | 38400.0000 | 32000.0000 | 9700.0000  | 2240.0000  | 3520.0000  | 7920.0000 | 18540.0000 | active |

	### PayslipComponent [LINE] -- one row per computed calc line (every earning / deduction / contribution with its value)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- payslip_id              -- FK Payslip -- parent slip
		- payroll_component_id    -- FK PayrollComponent -- element computed
		- quantity                -- numeric(10,2) nullable -- e.g. OT minutes
		- rate                    -- numeric(15,6) nullable -- unit rate used
		- amount                  -- numeric(15,4) -- computed result
		- unpaid_period_id        -- FK PayrollPeriod nullable -- set when the line retro-corrects an earlier period (BackPayTransaction output); NULL = current-period line
		- source_type             -- text -- originating document class: 'OvertimeRequest' | 'EmployeeLoanInstallment' | 'ExpenseClaim' | 'MedicalClaim' | 'PayrollInput'
		- source_id               -- integer -- primary key of that document
		- order                   -- integer -- payslip print order
		- state                   -- active / inactive
		> examples:
			| id     | payslip_id | payroll_component_id | component_type        | quantity | rate      | amount    | order | state  |
			| ------ | ---------- | -------------------- | --------------------- | -------- | --------- | --------- | ----- | ------ |
			| 800101 | 60214      | 1 (BASIC)            | earning               | --       | --        | 6500.0000 | 1     | active |
			| 800102 | 60214      | 2 (TRANS_ALLOW)      | earning               | --       | --        | 1625.0000 | 2     | active |
			| 800103 | 60214      | 3 (OT)               | earning               | 180.00   | 2.5000    | 450.0000  | 3     | active |
			| 800104 | 60214      | 4 (INCOME_TAX)       | deduction             | --       | --        | 1172.5000 | 4     | active |
			| 800105 | 60214      | 5 (PENSION_ER)       | employer_contribution | --       | 11.0000   | 715.0000  | 9     | active |

	### PaymentBatch [DIST] -- one row per disbursement batch to a bank; settles via core payment setup, bank file via DocumentAttachment ('HR:PaymentBatch')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- disbursement_method_lookup_value_id -- FK LookupValue (PAYMENT_BATCH_METHOD: bank_transfer | cash_via_cashier | cheque | mobile_money) -- default bank_transfer
		- cashier_employee_id     -- FK Employee nullable -- who dispensed cash; required when method = cash_via_cashier
		- funding_entity_id       -- FK Entity nullable -- tenant funding the batch when it differs from the employer (client_funds_employer_pays agreements); NULL = employer self-funds
		  -- Entity, not Party: the funder must own an EntityPaymentMethod account, so only a tenant client can fund
		- code                    -- via DocumentSequence (PAY-2026-07-004)
		- payroll_run_id          -- FK PayrollRun nullable -- NULL for loan disbursement / settlement batches
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- paying entity
		- entity_payment_method_id -- FK EntityPaymentMethod -- source account + rail (BANK_TRANSFER)
		- payment_provider_id     -- FK PaymentProvider nullable -- destination-side bank for a single-bank batch; NULL = mixed
		- batch_state_lookup_value_id -- FK LookupValue (PAYMENT_BATCH_STATE: draft | pending_approval | approved | sent_to_bank | confirmed | partially_failed | cancelled)
		- instruction_count       -- integer -- cache: count of PaymentInstruction rows in this batch
		- total_amount            -- numeric(15,4)
		- currency_id             -- FK Currency
		- value_date              -- date -- requested credit date
		- sent_at                 -- timestamp nullable
		- confirmed_at            -- timestamp nullable
		- approved_by_employee_id -- FK Employee nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: external clients fund via provider invoicing (Sales), never through payroll.
		> examples:
			| id  | code            | payroll_run_id | entity_id | payment_provider_id | batch_state      | instructions | total_amount | value_date | state  |
			| --- | --------------- | -------------- | --------- | ------------------- | ---------------- | ------------ | ------------ | ---------- | ------ |
			| 401 | PAY-2026-06-001 | 61             | 7         | 4                   | confirmed        | 38           | 341210.0000  | 2026-06-26 | active |
			| 402 | PAY-2026-06-002 | 61             | 7         | 7                   | confirmed        | 4            | 32280.0000   | 2026-06-26 | active |
			| 403 | PAY-2026-07-003 | 63             | 3         | 4                   | pending_approval | 41           | 664120.0000  | 2026-07-26 | active |
			| 404 | PAY-2026-07-004 | 63             | 3         | 7                   | draft            | 14           | 218200.0000  | 2026-07-26 | active |
			| 405 | PAY-2026-07-005 | --             | 3         | 4                   | approved         | 1            | 30000.0000   | 2026-07-20 | active |

	### EmployeeLoan [DIST] -- one row per issued loan or advance; approval via core Workflow, repayment via payroll deduction
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (LN-2026-0031)
		- employee_id             -- FK Employee -- borrower
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- employee_loan_type_id            -- FK EmployeeLoanType -- product the loan was issued under
		- loan_state_lookup_value_id -- FK LookupValue (LOAN_STATE: draft | pending | approved | disbursed | repaying | settled | written_off)
		- requested_amount        -- numeric(15,4) -- what the employee applied for; principal_amount is what approval granted
		- principal_amount        -- numeric(15,4)
		- interest_rate_percent   -- numeric(7,4) -- frozen from EmployeeLoanType at approval
		- tenor_months            -- integer -- repayment period in months
		- installment_amount      -- numeric(15,4) -- monthly installment amount
		- disbursed_at            -- timestamp nullable -- when the principal was released
		- disbursement_payment_batch_id -- FK PaymentBatch nullable -- paid out with / like payroll
		- outstanding_amount      -- numeric(15,4) -- cache/denormalized from installments
		- currency_id             -- FK Currency
		- approved_by_employee_id -- FK Employee nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		- employee_guarantee_id      -- FK EmployeeGuarantee nullable -- co-signer on the loan; the full surety record is EmployeeGuarantee
		> examples:
			| id | code         | employee_id | loan_type | loan_state | principal    | tenor_months | installment | outstanding  | state  |
			| -- | ------------ | ----------- | --------- | ---------- | ------------ | ------------ | ----------- | ------------ | ------ |
			| 31 | LN-2026-0031 | 14          | 1         | repaying   | 6500.0000    | 3            | 2166.6700   | 4333.3400    | active |
			| 32 | LN-2026-0032 | 22          | 2         | repaying   | 30000.0000   | 12           | 2500.0000   | 22500.0000   | active |
			| 33 | LN-2025-0033 | 44          | 5         | repaying   | 400000.0000  | 60           | 7920.0000   | 322500.0000  | active |
			| 34 | LN-2026-0034 | 31          | 1         | pending    | 7000.0000    | 3            | 2333.3300   | 7000.0000    | active |
			| 35 | LN-2024-0035 | 7           | 2         | settled    | 20000.0000   | 10           | 2000.0000   | 0.0000       | active |

	### PaymentInstruction [LINE] -- one row per credit line inside a batch (employee account, amount, bank result)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- payment_batch_id        -- FK PaymentBatch -- parent batch
		- payslip_id              -- FK Payslip nullable -- NULL for loan disbursement lines
		- employee_loan_id        -- FK EmployeeLoan nullable -- disbursement source when not a payslip
		- employee_id             -- FK Employee -- who is credited
		- employee_bank_account_id -- FK EmployeeBankAccount -- destination account snapshot
		- amount                  -- numeric(15,4)
		- currency_id             -- FK Currency
		- instruction_state_lookup_value_id -- FK LookupValue (PAYMENT_INSTRUCTION_STATE: pending | sent | confirmed | failed | returned)
		- bank_reference          -- text nullable -- bank-side transaction id
		- failure_reason          -- text nullable -- "account closed"
		- state                   -- active / inactive
		> examples:
			| id    | payment_batch_id | payslip_id | employee_id | employee_bank_account_id | amount      | instruction_state | bank_reference | state  |
			| ----- | ---------------- | ---------- | ----------- | ------------------------ | ----------- | ----------------- | -------------- | ------ |
			| 9001  | 401              | 60112      | 14          | 2                        | 4573.3300   | confirmed         | CBE-TX-882201  | active |
			| 9002  | 403              | 60207      | 7           | 1                        | 12270.0000  | pending           | --             | active |
			| 9003  | 404              | 60222      | 22          | 3                        | 6408.0000   | pending           | --             | active |
			| 9004  | 403              | 60222      | 22          | 4                        | 1602.0000   | pending           | --             | active |
			| 9005  | 405              | --         | 44          | 5                        | 30000.0000  | sent              | CBE-TX-990112  | active |

	### EmployeeLoanInstallment [LINE] -- one row per scheduled repayment; settles through a Payslip deduction line
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- employee_loan_id                 -- FK EmployeeLoan -- parent loan
		- installment_number      -- integer -- UNIQUE (employee_loan_id, installment_number)
		- due_date                -- date
		- amount                  -- numeric(15,4)
		- principal_portion       -- numeric(15,4)
		- interest_portion        -- numeric(15,4)
		- installment_state_lookup_value_id -- FK LookupValue (LOAN_INSTALLMENT_STATE: scheduled | deducted | paid | skipped | waived)
		- payslip_id              -- FK Payslip nullable -- the payslip that deducted it
		- paid_amount             -- numeric(15,4) nullable -- actually recovered; less than amount when net pay ran short
		- paid_at                 -- date nullable
		- state                   -- active / inactive
		- payroll_period_id       -- FK PayrollPeriod nullable -- period the installment is due in; saves the calc reverse-mapping due_date onto a period per group
		> examples:
			| id  | employee_loan_id | installment_number | due_date   | amount    | principal | interest | installment_state | payslip_id | state  |
			| --- | ------- | ------------------ | ---------- | --------- | --------- | -------- | ----------------- | ---------- | ------ |
			| 311 | 31      | 1                  | 2026-06-26 | 2166.6700 | 2166.6700 | 0.0000   | paid              | 60112      | active |
			| 312 | 31      | 2                  | 2026-07-26 | 2166.6700 | 2166.6700 | 0.0000   | deducted          | 60214      | active |
			| 313 | 31      | 3                  | 2026-08-26 | 2166.6600 | 2166.6600 | 0.0000   | scheduled         | --         | active |
			| 314 | 32      | 4                  | 2026-07-26 | 2500.0000 | 2500.0000 | 0.0000   | deducted          | 60222      | active |
			| 315 | 33      | 10                 | 2026-07-26 | 7920.0000 | 5586.0000 | 2334.0000| deducted          | 60244      | active |

	### StatutoryReport [DIST] -- one row per government filing per period (income-tax declaration to the Ministry of Revenues, pension remittance to POESSA); the generated file rides DocumentAttachment ('HR:StatutoryReport')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (FIL-2026-0014)
		- payroll_period_id       -- FK PayrollPeriod -- period the filing covers
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- filing legal entity
		- report_type_lookup_value_id -- FK LookupValue (STATUTORY_REPORT_TYPE: income_tax_declaration | pension_remittance)
		- report_state_lookup_value_id -- FK LookupValue (STATUTORY_REPORT_STATE: draft | generated | filed | acknowledged)
		- employee_count          -- integer -- employees covered by the filing
		- total_base_amount       -- numeric(15,4) -- taxable payroll (tax filing) or pensionable payroll (pension filing)
		- total_amount            -- numeric(15,4) -- tax withheld or pension remitted (employee + employer)
		- currency_id             -- FK Currency
		- filed_at                -- timestamp nullable
		- authority_reference     -- text nullable -- e-filing / receipt reference from the authority
		- filed_by_employee_id    -- FK Employee nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: PayrollRun holds calculation totals; this row is the FILING obligation with its own lifecycle -- unanswerable from the run alone.
		> examples:
			| id | code          | payroll_period_id | report_type            | report_state | employees | total_base_amount | total_amount | filed_at             | authority_reference | state  |
			| -- | ------------- | ----------------- | ---------------------- | ------------ | --------- | ----------------- | ------------ | -------------------- | ------------------- | ------ |
			| 14 | FIL-2026-0014 | 6                 | income_tax_declaration | acknowledged | 42        | 418200.0000       | 96410.0000   | 2026-07-05T09:00:00Z | MOR-EF-2026-118820  | active |
			| 15 | FIL-2026-0015 | 6                 | pension_remittance     | acknowledged | 40        | 305000.0000       | 54900.0000   | 2026-07-05T09:30:00Z | POESSA-2026-40112   | active |
			| 16 | FIL-2026-0016 | 7                 | income_tax_declaration | generated    | 43        | 431600.0000       | 99180.0000   | --                   | --                  | active |
			| 17 | FIL-2026-0017 | 7                 | pension_remittance     | draft        | 41        | 312400.0000       | 56232.0000   | --                   | --                  | active |
			| 18 | FIL-2026-0018 | 8                 | income_tax_declaration | filed        | 55        | 1088000.0000      | 262300.0000  | 2026-08-04T10:15:00Z | MOR-EF-2026-120544  | active |

	### EmployeeBonus [DIST] -- one row per employee's bonus transaction
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- the bonus recipient
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- bonus_scheme_id         -- FK BonusScheme -- the scheme that generated this bonus
		- payroll_run_id          -- FK PayrollRun nullable -- the payroll run that paid it; NULL = not yet paid
		- bonus_amount            -- numeric(15,4)
		- bonus_state_lookup_value_id -- FK LookupValue (BONUS_STATE: pending | approved | paid | cancelled)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | employee_id | bonus_scheme_id | payroll_run_id | bonus_amount | bonus_state | state  |
			| -- | ----------- | --------------- | -------------- | ----------- | ----------- | ------ |
			| 1  | 7           | 2               | --             | 500.0000     | pending     | active |
			| 2  | 14          | 2               | --             | 500.0000     | approved    | active |
			| 3  | 22          | 2               | --             | 500.0000     | approved    | active |

	### EmployeeDeduction [DIST] -- one row per standing or capped payroll recovery that is NOT a loan (court garnishment, salary overpayment, damage recovery, union dues)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (DED-2026-0012)
		- employee_id             -- FK Employee -- the person deducted
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- payroll_component_id    -- FK PayrollComponent -- deduction component the amount posts through
		- reason                  -- jsonb -- what is being recovered ({ en: "Till shortage of 2026-06-30" })
		- total_amount            -- numeric(15,4) nullable -- recovery target; NULL = open-ended recurring (union dues)
		- installment_amount      -- numeric(15,4) nullable -- fixed amount per period
		- installment_percent_of_net -- numeric(5,2) nullable -- percent-of-net alternative; same guardrail idea as loans
		- start_period_id         -- FK PayrollPeriod -- first period deducted
		- end_period_id           -- FK PayrollPeriod nullable -- NULL = until recovered or cancelled
		- recovered_amount        -- numeric(15,4) -- cache/denormalized sum of payslip lines to date
		- deduction_state_lookup_value_id -- FK LookupValue (EMPLOYEE_DEDUCTION_STATE: draft | pending | approved | active | completed | cancelled)
		- source_type             -- text -- originating document class: 'DisciplinaryAction' | 'ClearanceItem' | 'CourtOrder' | 'Manual'
		- source_id               -- integer nullable -- primary key of that document; NULL only when source_type = 'Manual'
		- source_document_ref     -- text nullable -- external reference when the origin is not an ERP row (court file 'FED-HC-2026-1182')
		- approved_by_employee_id -- FK Employee nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: loans keep their own EmployeeLoan ledger; this table covers every other recoverable balance.
		> examples:
			| id | code          | employee_id | reason (en)              | total_amount | installment_amount | start_period_id | recovered_amount | deduction_state | state  |
			| -- | ------------- | ----------- | ------------------------ | ------------ | ------------------ | --------------- | ---------------- | --------------- | ------ |
			| 12 | DED-2026-0012 | 15          | Till shortage 2026-06-30 | 4500.0000    | 1500.0000          | 7               | 1500.0000        | active          | active |
			| 13 | DED-2026-0013 | 22          | Union membership dues    | --           | 150.0000           | 6               | 300.0000         | active          | active |
			| 14 | DED-2026-0014 | 18          | June salary overpayment  | 2100.0000    | 2100.0000          | 8               | 0.0000           | approved        | active |
			| 15 | DED-2026-0015 | 31          | Court garnishment        | 36000.0000   | 3000.0000          | 8               | 0.0000           | pending         | active |
			| 16 | DED-2025-0016 | 14          | Lost RFID card           | 850.0000     | 850.0000           | 5               | 850.0000         | completed       | active |

	### ExpenseClaim [DIST] -- one row per reimbursement request; approved claims settle via PayrollInput on the next run
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (EXP-2026-0033)
		- employee_id             -- FK Employee -- claimant
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- period_from             -- date -- earliest expense date in the claim
		- period_to               -- date -- latest expense date
		- purpose                 -- jsonb -- localized ({ en: "Field visit to Bahir Dar for supplier audit" })
		- total_amount            -- numeric(15,4) -- cache/denormalized sum of lines
		- currency_id             -- FK Currency
		- claim_state_lookup_value_id -- FK LookupValue (EXPENSE_CLAIM_STATE: draft | submitted | pending_approval | approved | rejected | reimbursed | cancelled)
		- approved_by_employee_id -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- rejection_reason        -- jsonb nullable
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row (usually the employee)
		- state                   -- active / inactive
		  -- note: approval via core Workflow; scanned receipts attach to lines via DocumentAttachment ('HR:ExpenseClaimLine'). Reimbursement reaches the payslip through PayrollInput rows with source_type = 'ExpenseClaim'; a claim settled over two periods produces two inputs.
		> examples:
			| id | code           | employee_id | period_from | period_to  | purpose (en)                                | total_amount | claim_state       | state  |
			| -- | -------------- | ----------- | ----------- | ---------- | ------------------------------------------- | ------------ | ----------------- | ------ |
			| 33 | EXP-2026-0033  | 31          | 2026-07-05  | 2026-07-09 | Field visit to Bahir Dar for supplier audit | 4850.0000    | reimbursed        | active |
			| 34 | EXP-2026-0034  | 22          | 2026-07-14  | 2026-07-14 | Client meeting -- CBE Bole branch           | 320.0000     | approved          | active |
			| 35 | EXP-2026-0035  | 44          | 2026-07-20  | 2026-07-22 | Finance seminar -- Sheraton Addis           | 6200.0000    | pending_approval  | active |
			| 36 | EXP-2026-0036  | 7           | 2026-07-25  | 2026-07-25 | Recruitment fair transport                  | 180.0000     | submitted         | active |
			| 37 | EXP-2026-0037  | 14          | 2026-07-01  | 2026-07-31 | Monthly telebirr top-up (POS)               | 500.0000     | rejected          | active |

	### ExpenseClaimLine [LINE] -- one row per itemized expense; receipt PDF via DocumentAttachment ('HR:ExpenseClaimLine')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- expense_claim_id        -- FK ExpenseClaim -- parent claim
		- expense_type_lookup_value_id -- FK LookupValue (EXPENSE_TYPE: per_diem | transport | meal | accommodation | telecom | office_supplies | training_related | fuel | mileage | other)
		- per_diem_location_lookup_value_id -- FK LookupValue (PER_DIEM_LOCATION: inside_region | outside_region | abroad) nullable -- new -- set on per_diem lines; picks which PerDiemRate column caps the amount
		- claim_date              -- date -- when the expense was incurred
		- description             -- jsonb (localized) -- "Taxi Bole -> Piazza", "Hotel Ghion 2 nights"
		- amount                  -- numeric(15,4)
		- currency_id             -- FK Currency
		- has_receipt             -- bool -- receipt attached via DocumentAttachment for this line
		- distance_km             -- numeric(8,2) nullable -- when expense_type = mileage
		- mileage_rate            -- numeric(8,4) nullable -- ETB per km (StatutoryRule when configured)
		- reference               -- text nullable -- receipt / voucher number
		- notes                   -- jsonb nullable
		- state                   -- active / inactive
		> examples:
			| id  | expense_claim_id | expense_type    | claim_date | description (en)               | amount    | has_receipt | reference    | state  |
			| --- | ---------------- | --------------- | ---------- | ------------------------------ | --------- | ----------- | ------------ | ------ |
			| 201 | 33               | per_diem        | 2026-07-05 | Per diem day 1 (Bahir Dar)     | 800.0000  | false       | --           | active |
			| 202 | 33               | per_diem        | 2026-07-06 | Per diem day 2                 | 800.0000  | false       | --           | active |
			| 203 | 33               | accommodation   | 2026-07-06 | Ghion Hotel -- 2 nights        | 2400.0000 | true        | INV-2026-882 | active |
			| 204 | 33               | transport       | 2026-07-05 | Sky Bus AA -> Bahir Dar        | 550.0000  | true        | TKT-441290   | active |
			| 205 | 34               | transport       | 2026-07-14 | Taxi Bole -> CBE branch return | 320.0000  | true        | --           | active |


#10. HR -- Assets and benefits in kind

	## lookups first used in this section
		- EMPLOYEE_ASSET_TYPE         : laptop | phone | vehicle | uniform | id_card | key | tools | furniture | software_license | other  -- core Asset lookups own the ASSET_* namespace
		  -- ASSET_CONDITION is REUSED FROM CORE (new | excellent | good | fair | poor | damaged | unusable | lost) -- never redeclare it in this module; 'lost' is new in the core seed
		- EMPLOYEE_ASSET_STATE        : issued | returned | lost | damaged | written_off  -- distinct from core ASSET_STATUS

### BenefitInKindEntitlement [DIST] -- one row per non-cash item a grade or seat is entitled to, with its replacement cycle (uniform, PPE, fuel coupon); the issue itself is an EmployeeAsset  -- (Q8 -- confirm new table)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (BIK-UNIFORM-CASHIER, BIK-PPE-LINE)
		- name                    -- jsonb (localized) -- "Cashier uniform set", "Safety boots"
		- description             -- jsonb (localized) nullable
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- asset_type_lookup_value_id -- FK LookupValue (EMPLOYEE_ASSET_TYPE: laptop | phone | vehicle | uniform | id_card | key | tools | furniture | software_license | other)
		- job_title_id             -- FK JobTitle nullable -- role-level entitlement
		- job_grade_id            -- FK JobGrade nullable -- grade-level entitlement; exactly one of job_title_id / job_grade_id is set
		- organization_unit_id    -- FK OrganizationUnit nullable -- narrows the entitlement to one unit
		- quantity                -- numeric(10,2) -- units issued per cycle
		- cycle_months            -- integer nullable -- replacement frequency; NULL = one-off issue
		- unit_value_amount       -- numeric(15,4) nullable -- budgeting value per unit, ETB
		- currency_id             -- FK Currency nullable
		- effective_from          -- date
		- effective_to            -- date nullable -- NULL = current
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: issuing against this rule stamps EmployeeAsset.benefit_in_kind_entitlement_id and next_due_date = issued_at + cycle_months; the reminder rides the Notification engine.
		  -- note: an issue drawn from stock rides the Inventory consumption contract (common/Contracts -> auto StockOperation); HR never writes stock directly.  -- new
		> examples:
			| id | code                | name (en)          | entity_id | asset_type | job_title_id | job_grade_id | quantity | cycle_months | unit_value | state  |
			| -- | ------------------- | ------------------ | --------- | ---------- | ----------- | ------------ | -------- | ------------ | ---------- | ------ |
			| 1  | BIK-UNIFORM-CASHIER | Cashier uniform set| 7         | uniform    | 24          | --           | 2.00     | 24           | 850.0000   | active |
			| 2  | BIK-PPE-BOOTS       | Safety boots       | 9         | uniform    | --          | 3            | 1.00     | 12           | 1600.0000  | active |
			| 3  | BIK-IDCARD          | Corporate ID card  | 3         | id_card    | --          | 3            | 1.00     | --           | 120.0000   | active |
			| 4  | BIK-LAPTOP-MGT      | Management laptop  | 3         | laptop     | --          | 7            | 1.00     | 48           | 62000.0000 | active |
			| 5  | BIK-FUEL-MGR        | Fuel coupon book   | 3         | other      | 30          | --           | 1.00     | 1            | 8000.0000  | active |

	### EmployeeAsset [DIST] -- one row per company asset issued to an employee; open items force return via ClearanceItem on separation
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- current holder
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- product_id            -- FK Product nullable -- the product row this asset is an instance of; NULL = ad-hoc asset
		- asset_id              -- FK CORE Asset nullable -- new -- serialized/durable unit (laptop, vehicle, phone): custody then lives on the CORE Asset row (custody trio); this row stays the HR issue record. NULL = consumable/bulk issue (uniform, PPE, ID card)
		- quantity              -- integer -- how many of this asset are issued
		- total_cost_amount     -- numeric(15,4) nullable -- total purchase cost of the quantity issued; NULL = unknown
		- currency_id             -- FK Currency nullable
		- issued_at               -- date
		- issued_by_employee_id   -- FK Employee -- who handed it out (usually HR or IT)
		- returned_at             -- date nullable -- NULL while the asset is with the employee
		- returned_condition_lookup_value_id -- FK LookupValue (core ASSET_CONDITION: new | excellent | good | fair | poor | damaged | unusable | lost) nullable
		- asset_state_lookup_value_id -- FK LookupValue (EMPLOYEE_ASSET_STATE: issued | returned | lost | damaged | written_off)
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		- employee_guarantee_id   -- nullable new column employee guarantee for asset custody
		- expected_return_date    -- date nullable -- due back on this date for temporary issues; NULL = held until separation
		- issued_condition_lookup_value_id -- FK LookupValue (core ASSET_CONDITION: new | excellent | good | fair | poor | damaged | unusable | lost) nullable -- condition at hand-over; the baseline returned_condition is judged against
		- benefit_in_kind_entitlement_id -- FK BenefitInKindEntitlement nullable -- the entitlement rule this issue satisfies; NULL for ad-hoc issues
		- next_due_date           -- date nullable -- next replacement date for cyclical issues (issued_at + entitlement cycle_months)
		  -- note: EmployeeSeparation auto-generates a ClearanceItem for every row still issued AND for every open custody on the CORE Asset register (the open-custody read).
		> examples:
			| id | employee_id | product_id                | quantity | total_cost_amount | issued_at  | issued_condition | returned_at | returned_condition | asset_state | benefit_in_kind_entitlement_id | next_due_date | state  |
			| -- | ----------- | ------------------------- | -------- | ----------------- | ---------- | ---------------- | ----------- | ------------------ | ----------- | ------------------------------ | ------------- | ------ |
			| 1  | 22          | 5501 (Dell Latitude 5540) | 1        | 62000.0000        | 2021-09-20 | excellent        | --          | --                 | issued      | 4                              | 2025-09-20    | active |
			| 2  | 22          | 5510 (Corporate ID card)  | 1        | 120.0000          | 2021-09-15 | excellent        | --          | --                 | issued      | 3                              | --            | active |
			| 3  | 44          | 5520 (Toyota Hilux 2022)  | 1        | 2400000.0000      | 2023-01-05 | excellent        | --          | --                 | issued      | --                             | --            | active |
			| 4  | 14          | 5530 (Cashier uniform)    | 2        | 1700.0000         | 2024-06-01 | excellent        | --          | --                 | issued      | 1                              | 2026-06-01    | active |
			| 5  | 31          | 5540 (Samsung Galaxy A54) | 1        | 22000.0000        | 2025-02-17 | good             | 2026-05-30  | fair               | returned    | --                             | --            | active |


#11. HR -- Employee relations and discipline

	## lookups first used in this section
		- DISCIPLINARY_ACTION_TYPE    : verbal_warning | written_warning | final_warning | suspension_without_pay | paid_suspension | demotion | termination
		- DISCIPLINARY_OFFENSE_CATEGORY : attendance | misconduct | negligence | fraud | insubordination | policy_violation | safety
		- DISCIPLINARY_SEVERITY       : minor | moderate | severe | gross_misconduct
		- DISCIPLINARY_STATE          : reported | investigating | hearing_scheduled | decided | actioned | appealed | closed
		- GRIEVANCE_CATEGORY          : harassment | compensation | working_conditions | discrimination | management | other
		- GRIEVANCE_SEVERITY          : low | medium | high | critical
		- GRIEVANCE_STATE             : submitted | under_review | investigating | resolved | escalated | closed | withdrawn
		- INCIDENT_SEVERITY           : minor | serious | severe | fatal
		- INCIDENT_STATE              : reported | investigating | action_taken | closed
		- INCIDENT_TYPE               : injury | near_miss | occupational_illness | property_damage | commuting_accident

	### DisciplinaryOffense [REF] -- one row per named offence in the entity's disciplinary code, carrying the standard sanction and its escalation ladder  -- (Q8 -- confirm new table)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (OFF-LATE-REPEAT, OFF-TILL-SHORT)
		- name                    -- jsonb (localized) -- the offence as written in the code of conduct
		- description             -- jsonb (localized) nullable -- what conduct constitutes it
		- entity_id               -- FK Entity nullable -- NULL = platform template
		- offense_category_lookup_value_id -- FK LookupValue (DISCIPLINARY_OFFENSE_CATEGORY: attendance | misconduct | negligence | fraud | insubordination | policy_violation | safety)
		- severity_lookup_value_id -- FK LookupValue (DISCIPLINARY_SEVERITY: minor | moderate | severe | gross_misconduct)
		- default_action_type_lookup_value_id -- FK LookupValue (DISCIPLINARY_ACTION_TYPE: verbal_warning | written_warning | final_warning | suspension_without_pay | paid_suspension | demotion | termination) -- sanction for a first occurrence
		- repeat_action_type_lookup_value_id -- FK LookupValue (DISCIPLINARY_ACTION_TYPE) nullable -- sanction once the offence repeats while the earlier record is still live
		- default_suspension_days -- integer nullable -- when the default sanction is a suspension
		- default_penalty_amount  -- numeric(15,4) nullable -- standard fine, ETB
		- currency_id             -- FK Currency nullable
		- record_expiry_months    -- integer nullable -- how long the offence stays live on the record before it is spent; NULL = never expires
		- requires_hearing        -- bool -- a DisciplinaryHearing is mandatory before any decision on this offence
		- allow_appeal			  -- bool -- the employee may appeal the decision
		- appeal_due_days		   -- integer nullable -- how many days the employee has to file an appeal
		- blocks_promotion_months -- integer nullable -- promotion freeze while the record is live
		- is_system               -- platform-seeded row
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: DisciplinaryCase.disciplinary_offense_id names the offence; the decision may still depart from the default, which is why both live side by side.
		> examples:
			| id | code            | name (en)                  | entity_id | offense_category | severity        | default_action         | repeat_action          | record_expiry_months | requires_hearing | state  |
			| -- | --------------- | -------------------------- | --------- | ---------------- | --------------- | ---------------------- | ---------------------- | -------------------- | ---------------- | ------ |
			| 1  | OFF-LATE-REPEAT | Repeated lateness          | 1         | attendance       | minor           | verbal_warning         | written_warning        | 12                   | false            | active |
			| 2  | OFF-ABSENT-UNEX | Unexcused absence          | 1         | attendance       | moderate        | written_warning        | final_warning          | 12                   | false            | active |
			| 3  | OFF-TILL-SHORT  | Till shortage / cash loss  | 1         | negligence       | moderate        | written_warning        | suspension_without_pay | 24                   | true             | active |
			| 4  | OFF-INSUBORD    | Insubordination            | 1         | insubordination  | severe          | final_warning          | termination            | 24                   | true             | active |
			| 5  | OFF-FRAUD       | Theft or falsification     | 1         | fraud            | gross_misconduct| termination            | --                     | --                   | true             | active |

	### DisciplinaryCase [DIST] -- one row per misconduct file; evidence via DocumentAttachment ('HR:DisciplinaryCase'), process follows labour-law timelines
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (DSC-2026-0009)
		- employee_id             -- FK Employee -- respondent
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- offense_category_lookup_value_id -- FK LookupValue (DISCIPLINARY_OFFENSE_CATEGORY: attendance | misconduct | negligence | fraud | insubordination | policy_violation | safety)
		- severity_lookup_value_id -- FK LookupValue (DISCIPLINARY_SEVERITY: minor | moderate | severe | gross_misconduct) -- gates the sanction range and whether a hearing is mandatory
		- case_state_lookup_value_id -- FK LookupValue (DISCIPLINARY_STATE: reported | investigating | hearing_scheduled | decided | actioned | appealed | closed)
		- disciplinary_offense_id -- FK DisciplinaryOffense nullable -- the named offence from the disciplinary code; the decision may still depart from its default sanction
		- reported_by_employee_id -- FK Employee -- who reported it
		- incident_date           -- date
		- incident_summary        -- jsonb
		- investigator_employee_id -- FK Employee nullable
		- decision_summary        -- jsonb nullable
		- decided_at              -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | employee_id | offense_category | case_state        | reported_by | incident_date | investigator | state  |
			| -- | ------------- | ----------- | ---------------- | ----------------- | ----------- | ------------- | ------------ | ------ |
			| 9  | DSC-2026-0009 | 15          | attendance       | actioned          | 14          | 2026-06-12    | 7            | active |
			| 10 | DSC-2026-0010 | 18          | negligence       | hearing_scheduled | 7           | 2026-07-08    | 7            | active |
			| 11 | DSC-2026-0011 | 20          | fraud            | investigating     | 44          | 2026-07-20    | 7            | active |
			| 12 | DSC-2025-0012 | 19          | insubordination  | closed            | 7           | 2025-11-02    | 7            | active |
			| 13 | DSC-2026-0013 | 15          | attendance       | reported          | 14          | 2026-07-28    | --           | active |

	### DisciplinaryHearing [LINE] -- one row per formal hearing session on a case
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- disciplinary_case_id    -- FK DisciplinaryCase -- parent case
		- employee_representative_party_id -- FK Party nullable -- lawyer or union representative attending for the respondent; a due-process fact the minutes must carry
		- scheduled_at            -- timestamp
		- held_at                 -- timestamp nullable
		- location                -- jsonb nullable -- { room: "HQ Meeting 1" }
		- committee_id            -- FK Committee -- the hearing panel; its members are CommitteeMember rows
		- employee_statement      -- jsonb nullable -- respondent's defence summary
		- minutes_summary         -- jsonb nullable -- full minutes = DocumentAttachment ('HR:DisciplinaryHearing')
		- outcome_note            -- jsonb nullable
		- state                   -- active / inactive
		> examples:
			| id | disciplinary_case_id | scheduled_at         | held_at              | committee_id | employee_representative_party_id | outcome_note (summary) | state  |
			| -- | -------------------- | -------------------- | -------------------- | ------------ | -------------------------------- | ---------------------- | ------ |
			| 1  | 9                    | 2026-06-25T07:00:00Z | 2026-06-25T07:10:00Z | 1            | --                               | warning recommended    | active |
			| 2  | 10                   | 2026-08-05T07:00:00Z | --                   | 1            | 991 (union rep)                  | --                     | active |
			| 3  | 11                   | 2026-08-12T07:00:00Z | --                   | 1            | 992 (legal counsel)              | --                     | active |
			| 4  | 12                   | 2025-11-20T07:00:00Z | 2025-11-20T07:05:00Z | 1            | --                               | case dismissed         | active |
			| 5  | 9                    | 2026-06-18T07:00:00Z | 2026-06-18T07:00:00Z | 1            | --                               | adjourned for evidence | active |

	### DisciplinaryAction [DIST] -- one row per sanction issued (warning ladder per Ethiopian labour law); letter via LetterTemplate + DocumentAttachment ('HR:DisciplinaryAction')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (DSA-2026-0007)
		- disciplinary_case_id    -- FK DisciplinaryCase -- parent case
		- employee_id             -- FK Employee -- sanctioned person
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- action_type_lookup_value_id -- FK LookupValue (DISCIPLINARY_ACTION_TYPE: verbal_warning | written_warning | final_warning | suspension_without_pay | paid_suspension | demotion | termination)
		- suspension_days         -- integer nullable -- for suspension_without_pay; the payroll absence deduction feeds from this
		- effective_date          -- date
		- expires_at              -- date nullable -- warning validity window
		- employee_movement_id   -- FK EmployeeMovement nullable -- demotion/termination executes as a movement
		- issued_by_employee_id   -- FK Employee -- who issued the sanction
		- committee_id			-- FK Committee nullable -- if the sanction was committee-approved
		- acknowledged_at         -- timestamp nullable -- employee signed receipt
		- appeal_deadline         -- date nullable -- last day the employee may appeal
		- appealed_at             -- timestamp nullable -- appeal filed; the appeal itself is handled on the case (state = appealed)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		- penalty_amount          -- numeric(15,4) nullable -- monetary fine imposed by the decision; recovery itself runs as an EmployeeDeduction
		- currency_id             -- FK Currency nullable -- currency of penalty_amount
		> examples:
			| id | code          | disciplinary_case_id | employee_id | action_type            | effective_date | suspension_days | expires_at | issued_by | state  |
			| -- | ------------- | -------------------- | ----------- | ---------------------- | -------------- | --------------- | ---------- | --------- | ------ |
			| 7  | DSA-2026-0007 | 9                    | 15          | written_warning        | 2026-06-26     | --              | 2027-06-26 | 7         | active |
			| 8  | DSA-2025-0008 | 12                   | 19          | verbal_warning         | 2025-11-21     | --              | 2026-11-21 | 7         | active |
			| 9  | DSA-2026-0009 | 9                    | 15          | final_warning          | 2026-07-30     | --              | 2027-07-30 | 7         | active |
			| 10 | DSA-2025-0010 | 8                    | 18          | suspension_without_pay | 2025-12-01     | 5               | --         | 7         | active |
			| 11 | DSA-2024-0011 | 5                    | 21          | termination            | 2024-09-15     | --              | --         | 7         | active |

	### GrievanceCase [DIST] -- one row per employee complaint file; evidence via DocumentAttachment ('HR:GrievanceCase'), resolution flow via core Workflow
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (GRV-2026-0012)
		- employee_id             -- FK Employee -- complainant
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- category_lookup_value_id -- FK LookupValue (GRIEVANCE_CATEGORY: harassment | compensation | working_conditions | discrimination | management | other)
		- severity_lookup_value_id -- FK LookupValue (GRIEVANCE_SEVERITY: low | medium | high | critical)
		- incident_date           -- date nullable -- when the complained-of event happened, distinct from filing
		- case_state_lookup_value_id -- FK LookupValue (GRIEVANCE_STATE: submitted | under_review | investigating | resolved | escalated | closed | withdrawn)
		- against_employee_id     -- FK Employee nullable -- respondent when person-directed
		- is_confidential         -- bool -- restricts visibility to case handlers
		- summary                 -- jsonb -- complainant's statement
		- assigned_to_employee_id -- FK Employee nullable -- case handler
		- resolution_summary      -- jsonb nullable
		- resolved_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | employee_id | category           | severity | case_state    | against | confidential | assigned_to | state  |
			| -- | ------------- | ----------- | ------------------ | -------- | ------------- | ------- | ------------ | ----------- | ------ |
			| 12 | GRV-2026-0012 | 14          | working_conditions | medium   | investigating | --      | false        | 7           | active |
			| 13 | GRV-2026-0013 | 31          | management         | high     | under_review  | 44      | true         | 7           | active |
			| 14 | GRV-2026-0014 | 15          | compensation       | low      | resolved      | --      | false        | 7           | active |
			| 15 | GRV-2025-0015 | 18          | harassment         | critical | closed        | 20      | true         | 7           | active |
			| 16 | GRV-2026-0016 | 22          | other              | low      | withdrawn     | --      | false        | --          | active |

	### GrievanceUpdate [LINE] -- one row per timeline entry on a case (notes, meetings, escalations)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- grievance_case_id       -- FK GrievanceCase -- parent case
		- author_employee_id      -- FK Employee -- handler / committee member
		- committee_id 			  -- FK Committee nullable -- if the update was a committee action
		- update_note             -- jsonb -- what happened
		- new_case_state_lookup_value_id -- FK LookupValue (GRIEVANCE_STATE: submitted | under_review | investigating | resolved | escalated | closed | withdrawn) nullable -- set when the entry moved the state
		- occurred_at             -- timestamp
		- state                   -- active / inactive
		> examples:
			| id | grievance_case_id | author_employee_id | committee_id | update_note (summary)      | new_case_state | occurred_at          | state  |
			| -- | ----------------- | ------------------ | ------------ | -------------------------- | -------------- | -------------------- | ------ |
			| 1  | 12                | 7                  | --           | Site visit scheduled       | investigating  | 2026-07-18T08:00:00Z | active |
			| 2  | 12                | 7                  | --           | Ventilation vendor engaged | --             | 2026-07-24T10:00:00Z | active |
			| 3  | 13                | 7                  | 2            | Statements collected       | under_review   | 2026-07-22T09:00:00Z | active |
			| 4  | 14                | 7                  | --           | Allowance recalculated     | resolved       | 2026-07-10T12:00:00Z | active |
			| 5  | 15                | 7                  | 2            | Committee decision issued  | closed         | 2025-12-05T14:00:00Z | active |

	### WorkIncident [DIST] -- one row per workplace injury / near-miss / occupational illness; feeds statutory injury reporting and POESSA claims, evidence via DocumentAttachment ('HR:WorkIncident')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (INC-2026-0009)
		- employee_id             -- FK Employee -- the person affected
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- where it happened (branch granularity)
		- incident_type_lookup_value_id -- FK LookupValue (INCIDENT_TYPE: injury | near_miss | occupational_illness | property_damage | commuting_accident)
		- severity_lookup_value_id -- FK LookupValue (INCIDENT_SEVERITY: minor | serious | severe | fatal)
		- incident_state_lookup_value_id -- FK LookupValue (INCIDENT_STATE: reported | investigating | action_taken | closed)
		- occurred_at             -- timestamp
		- reported_at             -- timestamp
		- reported_by_employee_id -- FK Employee -- may differ from the affected employee
		- description             -- jsonb (localized) -- what happened
		- immediate_action        -- jsonb nullable -- first response taken
		- corrective_action       -- jsonb nullable -- what prevents recurrence; closure requires it for injury severities
		- lost_work_days          -- integer nullable -- absence attributable to the incident
		- linked_leave_request_id -- FK LeaveRequest nullable -- injury leave granted for it
		- reported_to_authority   -- bool -- labour inspectorate / POESSA notified
		- authority_report_ref    -- text nullable -- filing reference
		- closed_at               -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | employee_id | incident_type        | severity | inc_state     | occurred_at          | lost_work_days | linked_leave_request_id | reported_to_authority | authority_ref     | state  |
			| -- | ------------- | ----------- | -------------------- | -------- | ------------- | -------------------- | -------------- | ----------------------- | --------------------- | ----------------- | ------ |
			| 9  | INC-2026-0009 | 31          | injury               | serious  | action_taken  | 2026-06-12T10:40:00Z | 12             | 4418                    | true                  | MOLS-2026-00891   | active |
			| 10 | INC-2026-0010 | 14          | near_miss            | minor    | closed        | 2026-06-20T15:10:00Z | --             | --                      | false                 | --                | active |
			| 11 | INC-2026-0011 | 63          | injury               | minor    | closed        | 2026-07-03T09:20:00Z | 2              | 4471                    | false                 | --                | active |
			| 12 | INC-2026-0012 | 22          | commuting_accident   | serious  | investigating | 2026-07-28T07:45:00Z | --             | --                      | true                  | MOLS-2026-01044   | active |
			| 13 | INC-2026-0013 | 15          | occupational_illness | serious  | reported      | 2026-08-01T11:00:00Z | --             | --                      | false                 | --                | active |


#12. HR -- Separation and settlement

	## lookups first used in this section
		- SEPARATION_STATUS           : draft | pending | approved | in_clearance | cleared | settled | cancelled
		- SEPARATION_TYPE             : resignation | termination | end_of_contract | retirement | death | redundancy | mutual_agreement
		- CLEARANCE_ITEM_STATE        : pending | cleared | flagged | waived
		- SETTLEMENT_STATE            : draft | calculated | approved | paid
		- SETTLEMENT_LINE_TYPE        : prorated_salary | severance | notice_pay | leave_encashment | bonus | loan_recovery | deduction | other

	### EmployeeSeparation [DIST] -- one row per exit document (any leaving mode); approval via core Workflow, drives clearance + final settlement
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (SEP-2026-0011)
		- employee_id             -- FK Employee -- the person leaving
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- separation_type_lookup_value_id -- FK LookupValue (SEPARATION_TYPE: resignation | termination | end_of_contract | retirement | death | redundancy | mutual_agreement)
		- separation_state_lookup_value_id -- FK LookupValue (SEPARATION_STATUS: draft | pending | approved | in_clearance | cleared | settled | cancelled)
		- notice_date             -- date -- when notice was given
		- last_working_date       -- date
		- reason                  -- jsonb nullable -- resignation letter summary; letter scan via DocumentAttachment ('HR:EmployeeSeparation')
		- disciplinary_action_id  -- FK DisciplinaryAction nullable -- set when termination originates from discipline
		- is_rehire_eligible      -- bool nullable -- exit verdict for future applications
		- exit_interview_note     -- jsonb nullable
		- employee_movement_id   -- FK EmployeeMovement nullable -- the separation movement effected
		- approved_by_employee_id -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | employee_id | separation_type | separation_state | notice_date | last_working_date | is_rehire_eligible | state  |
			| -- | ------------- | ----------- | --------------- | ---------------- | ----------- | ----------------- | ------------------ | ------ |
			| 11 | SEP-2026-0011 | 18          | termination     | settled          | 2026-02-01  | 2026-03-02        | false              | active |
			| 12 | SEP-2026-0012 | 19          | resignation     | in_clearance     | 2026-07-01  | 2026-07-31        | true               | active |
			| 13 | SEP-2026-0013 | 20          | end_of_contract | approved         | 2026-07-15  | 2026-08-16        | true               | active |
			| 14 | SEP-2026-0014 | 21          | retirement      | cleared          | 2026-05-01  | 2026-06-30        | --                 | active |
			| 15 | SEP-2026-0015 | 15          | resignation     | draft            | 2026-07-28  | 2026-08-27        | --                 | active |

	### ClearanceItem [LINE] -- one row per departmental sign-off before settlement (assets, finance, IT access, keys)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- employee_separation_id   -- FK EmployeeSeparation -- parent exit
		- organization_unit_id           -- FK OrganizationUnit -- clearing department
		- clearance_state_lookup_value_id -- FK LookupValue (CLEARANCE_ITEM_STATE: pending | cleared | flagged | waived)
		- title                   -- jsonb (localized) -- "Return laptop", "Settle till float"
		- flagged_amount          -- numeric(15,4) nullable -- recoverable value when flagged; feeds a FinalSettlementLine deduction
		- cleared_by_employee_id  -- FK Employee nullable
		- cleared_at              -- timestamp nullable
		- notes                   -- jsonb nullable
		- state                   -- active / inactive
		- order 				  -- integer -- display order within the separation clearance checklist
		- user_id                 -- FK User -- who created the row
		> examples:
			| id | employee_separation_id | organization_unit_id | clearance_state | title (en)         | flagged_amount | cleared_by | state  |
			| -- | --------------------- | ---------------------- | --------------- | ------------------ | -------------- | ---------- | ------ |
			| 1  | 12                    | 5                      | cleared         | Revoke ERP access  | --             | 7          | active |
			| 2  | 12                    | 4                      | pending         | Return laptop      | --             | --         | active |
			| 3  | 12                    | 2                      | flagged         | Outstanding advance| 4333.3400      | 22         | active |
			| 4  | 14                    | 2                      | cleared         | Till reconciliation| --             | 22         | active |
			| 5  | 11                    | 3                      | cleared         | Uniform return     | --             | 14         | active |

	### FinalSettlement [DIST] -- one row per terminal pay computation; executes as a final_settlement PayrollRun + PaymentBatch
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (FST-2026-0008)
		- employee_separation_id   -- FK EmployeeSeparation -- UNIQUE
		- employee_id             -- FK Employee -- the person settled
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- settlement_state_lookup_value_id -- FK LookupValue (SETTLEMENT_STATE: draft | calculated | approved | paid)
		- service_years           -- numeric(5,2) -- computed tenure for severance
		- gross_amount            -- numeric(15,4) -- cache/denormalized sum of earning lines
		- deduction_amount        -- numeric(15,4) -- cache sum: loans, clearance flags, tax
		- net_amount              -- numeric(15,4)
		- currency_id             -- FK Currency
		- payroll_run_id          -- FK PayrollRun nullable -- the final_settlement run that paid it
		- approved_by_employee_id -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- paid_at                 -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | employee_separation_id | employee_id | settlement_state | service_years | gross       | deductions | net         | state  |
			| -- | ------------- | --------------------- | ----------- | ---------------- | ------------- | ----------- | ---------- | ----------- | ------ |
			| 8  | FST-2026-0008 | 11                    | 18          | paid             | 3.50          | 42100.0000  | 9400.0000  | 32700.0000  | active |
			| 9  | FST-2026-0009 | 14                    | 21          | approved         | 21.30         | 386000.0000 | 41200.0000 | 344800.0000 | active |
			| 10 | FST-2026-0010 | 12                    | 19          | calculated       | 2.10          | 21500.0000  | 6800.0000  | 14700.0000  | active |
			| 11 | FST-2026-0011 | 13                    | 20          | draft            | 1.00          | 11800.0000  | 2100.0000  | 9700.0000   | active |
			| 12 | FST-2025-0012 | 9                     | 25          | paid             | 0.80          | 8200.0000   | 1500.0000  | 6700.0000   | active |

	### FinalSettlementLine [LINE] -- one row per itemized settlement line (severance from StatutoryRule, leave encashment from LeaveBalance...)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- final_settlement_id     -- FK FinalSettlement -- parent settlement
		- line_type_lookup_value_id -- FK LookupValue (SETTLEMENT_LINE_TYPE: prorated_salary | severance | notice_pay | leave_encashment | bonus | loan_recovery | deduction | other)
		- payroll_component_id    -- FK PayrollComponent nullable -- posting component
		- description             -- jsonb -- human line label
		- quantity                -- numeric(10,2) nullable -- e.g. encashed days
		- rate                    -- numeric(15,6) nullable -- e.g. daily wage
		- amount                  -- numeric(15,4) -- signed: earnings +, deductions -
		- source_type             -- text -- originating document class: 'LeaveAllocation' | 'EmployeeLoan' | 'ClearanceItem'
		- source_id               -- integer -- primary key of that document
		- order                   -- integer
		- state                   -- active / inactive
		> examples:
			| id | final_settlement_id | line_type        | description (en)          | quantity | rate      | amount      | order | state  |
			| -- | ------------------- | ---------------- | ------------------------- | -------- | --------- | ----------- | ----- | ------ |
			| 1  | 9                   | severance        | Severance (21.3 yrs, cap) | --       | --        | 288000.0000 | 1     | active |
			| 2  | 9                   | leave_encashment | 30 unused annual days     | 30.00    | 1230.7692 | 36923.0800  | 2     | active |
			| 3  | 10                  | prorated_salary  | July worked days          | 22.00    | 250.0000  | 5500.0000   | 1     | active |
			| 4  | 10                  | loan_recovery    | Salary advance balance    | --       | --        | -4333.3400  | 3     | active |
			| 5  | 8                   | notice_pay       | Notice period pay         | 30.00    | 216.6667  | 6500.0000   | 2     | active |


#13. HR -- Letters, announcements and employee services

	## lookups first used in this section
		- LETTER_TYPE                 : employment_confirmation | experience | salary_certificate | offer | warning | promotion | transfer | termination | bank_reference
		- EMPLOYEE_LETTER_STATE       : draft | pending_approval | approved | issued | revoked
		- LETTER_DIRECTION            : outgoing | incoming
		- ANNOUNCEMENT_AUDIENCE       : all | organization_unit | grade | position | employee_list
		- ANNOUNCEMENT_STATE          : draft | scheduled | published | archived
		- HR_SERVICE_REQUEST_CATEGORY : letter | id_card | payslip_copy | data_correction | benefit_inquiry | general
		- HR_SERVICE_REQUEST_STATE    : open | assigned | in_progress | resolved | closed | cancelled

	### LetterTemplate [REF] -- one row per merge-field template for HR letters; rendered PDFs stored via DocumentAttachment on the target row
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (LT-EXP, LT-SALCERT)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- entity_id               -- FK Entity nullable -- NULL = platform seed; letterhead/logo come from EntityDetail at render time
		- letter_type_lookup_value_id -- FK LookupValue (LETTER_TYPE: employment_confirmation | experience | salary_certificate | offer | warning | promotion | transfer | termination | bank_reference)
		- document_type_id        -- FK DocumentType -- core doc type + numbering via DocumentSequence
		- body                    -- jsonb (localized) -- rich text with {{merge_fields}}: {{employee_name}}, {{position}}, {{basic_salary}}, {{hire_date}}
		- requires_approval       -- bool -- issue flow gates through core Workflow
		- is_system               -- platform-seeded row
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code       | name (en)               | letter_type            | entity_id | requires_approval | is_system | state  |
			| -- | ---------- | ----------------------- | ---------------------- | --------- | ----------------- | --------- | ------ |
			| 1  | LT-EXP     | Experience Letter       | experience             | --        | true              | true      | active |
			| 2  | LT-SALCERT | Salary Certificate      | salary_certificate     | --        | true              | true      | active |
			| 3  | LT-CONF    | Employment Confirmation | employment_confirmation| --        | false             | true      | active |
			| 4  | LT-WARN    | Warning Letter          | warning                | --        | true              | true      | active |
			| 5  | LT-BANKREF | Bank Reference          | bank_reference         | 3         | true              | false     | active |

	### EmployeeLetter [DIST] -- one row per issued letter instance (self-service requestable); PDF via DocumentAttachment ('HR:EmployeeLetter')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- direction_lookup_value_id -- FK LookupValue (LETTER_DIRECTION: outgoing | incoming) -- default outgoing; incoming = received from an external party (guarantee letter, undertaking)
		- remind_on_separation    -- bool default false -- HR is reminded to review this letter when the employee separates (bonds, guarantees, undertakings)
		- code                    -- via DocumentSequence (LTR-2026-0067)
		- employee_id             -- FK Employee -- subject of the letter
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- issuing entity
		- letter_template_id      -- FK LetterTemplate -- template rendered
		- letter_state_lookup_value_id -- FK LookupValue (EMPLOYEE_LETTER_STATE: draft | pending_approval | approved | issued | revoked)
		- merge_data              -- jsonb -- merge values frozen at issue time (salary, position, dates)
		- addressed_to            -- jsonb nullable -- { organization: "CBE Bole Branch", attention: "Loan Officer" }
		- purpose                 -- jsonb nullable -- why requested
		- requested_by_employee_id -- FK Employee -- usually self
		- issued_by_employee_id   -- FK Employee nullable
		- issued_at               -- timestamp nullable
		- revoked_at              -- timestamp nullable
		- revoke_reason           -- jsonb nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | employee_id | letter_template_id | letter_state     | addressed_to (org)   | requested_by | issued_by | issued_at            | state  |
			| -- | ------------- | ----------- | ------------------ | ---------------- | -------------------- | ------------ | --------- | -------------------- | ------ |
			| 67 | LTR-2026-0067 | 22          | 2                  | issued           | CBE Bole Branch      | 22           | 7         | 2026-07-21T08:30:00Z | active |
			| 68 | LTR-2026-0068 | 14          | 3                  | issued           | --                   | 14           | 7         | 2026-07-15T10:00:00Z | active |
			| 69 | LTR-2026-0069 | 44          | 5                  | pending_approval | Awash Bank Bole      | 44           | --        | --                   | active |
			| 70 | LTR-2026-0070 | 18          | 1                  | issued           | --                   | 18           | 7         | 2026-03-05T09:00:00Z | active |
			| 71 | LTR-2026-0071 | 15          | 4                  | draft            | --                   | 7            | --        | --                   | active |

	### Announcement [DIST] -- one row per HR notice with acknowledgment tracking; delivery rides the Notification engine, this row is the record
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (HRA-2026-0021)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- title                   -- jsonb (localized)
		- body                    -- jsonb (localized)
		- audience_lookup_value_id -- FK LookupValue (ANNOUNCEMENT_AUDIENCE: all | organization_unit | grade | position | employee_list)
		- publish_from            -- timestamp
		- publish_to              -- timestamp nullable -- NULL = stays up until archived
		- requires_acknowledgment -- bool -- TRUE = every targeted employee must confirm reading (policy-publication compliance proof)
		- acknowledgment_deadline -- date nullable
		- announcement_state_lookup_value_id -- FK LookupValue (ANNOUNCEMENT_STATE: draft | scheduled | published | archived)
		- published_by_employee_id -- FK Employee nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: attachments via DocumentAttachment ('HR:Announcement').
		> examples:
			| id | code          | title (en)               | audience      | targets (pivot)      | publish_from         | requires_ack | ack_deadline | ann_state | state  |
			| -- | ------------- | ------------------------ | ------------- | -------------------- | -------------------- | ------------ | ------------ | --------- | ------ |
			| 21 | HRA-2026-0021 | Updated Safety Policy    | all           | --                   | 2026-07-01T06:00:00Z | true         | 2026-07-15   | published | active |
			| 22 | HRA-2026-0022 | Meskel Holiday Closure   | all           | --                   | 2026-09-20T06:00:00Z | false        | --           | scheduled | active |
			| 23 | HRA-2026-0023 | New Leave Policy FY2027  | all           | --                   | 2026-07-08T06:00:00Z | true         | 2026-07-31   | published | active |
			| 24 | HRA-2026-0024 | Finance month-end freeze | organization_unit | 2 (Finance)           | 2026-07-25T06:00:00Z | false      | --           | published | active |
			| 25 | HRA-2026-0025 | Cashier uniform standard | position      | position 24            | 2026-08-01T06:00:00Z | true       | 2026-08-20   | draft     | active |

	### AnnouncementTarget [LINE] -- new -- one row per audience target of a non-'all' announcement; replaces the audience_config jsonb (queryable: who has not acknowledged, per unit)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- announcement_id         -- FK Announcement -- parent notice
		- organization_unit_id    -- FK OrganizationUnit nullable -- unit-audience target
		- job_grade_id            -- FK JobGrade nullable -- grade-audience target
		- job_position_id         -- FK JobPosition nullable -- position-audience target
		- employee_id             -- FK Employee nullable -- employee_list target
		- state                   -- active / inactive
		  -- note: exactly ONE of the four target FKs is set per row; an audience = all announcement has no rows here.
		> examples:
			| id | announcement_id | organization_unit_id | job_grade_id | job_position_id | employee_id | state  |
			| -- | --------------- | -------------------- | ------------ | --------------- | ----------- | ------ |
			| 1  | 24              | 2 (Finance)          | --           | --              | --          | active |
			| 2  | 25              | --                   | --           | 24              | --          | active |

	### AnnouncementAcknowledgment [LINE] -- one row per targeted employee; NULL acknowledged_at = not yet read (the compliance exposure list)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- announcement_id         -- FK Announcement -- UNIQUE (announcement_id, employee_id)
		- employee_id             -- FK Employee -- targeted reader
		- acknowledged_at         -- timestamp nullable -- NULL until the employee confirms
		- state                   -- active / inactive
		> examples:
			| id  | announcement_id | employee_id | acknowledged_at      | state  |
			| --- | --------------- | ----------- | -------------------- | ------ |
			| 1   | 21              | 22          | 2026-07-02T08:15:00Z | active |
			| 2   | 21              | 14          | 2026-07-03T09:40:00Z | active |
			| 3   | 21              | 31          | --                   | active |
			| 4   | 23              | 22          | 2026-07-09T10:05:00Z | active |
			| 5   | 23              | 44          | 2026-07-08T14:30:00Z | active |

	### HRServiceRequest [DIST] -- one row per employee-to-HR service ticket (ID card, payslip copy, data correction, benefit inquiry); big flows like leave keep their own typed tables
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (HSR-2026-0102)
		- employee_id             -- FK Employee -- requester
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- category_lookup_value_id -- FK LookupValue (HR_SERVICE_REQUEST_CATEGORY: letter | id_card | payslip_copy | data_correction | benefit_inquiry | general)
		- subject                 -- jsonb -- one-line ask ({ en: "Salary certificate for CBE mortgage" })
		- description             -- jsonb nullable
		- request_state_lookup_value_id -- FK LookupValue (HR_SERVICE_REQUEST_STATE: open | assigned | in_progress | resolved | closed | cancelled)
		- assigned_to_employee_id -- FK Employee nullable -- HR handler
		- linked_reference        -- jsonb nullable -- fulfilment record ({ employee_letter_id: 67 })
		- resolution_note         -- jsonb nullable
		- resolved_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row (self-service)
		- state                   -- active / inactive
		  -- note: a letter-category ticket is fulfilled by issuing an EmployeeLetter and linking it back here; grievances are never tickets -- they go to GrievanceCase.
		> examples:
			| id  | code          | employee_id | category        | subject (en)                       | request_state | assigned_to | linked_reference       | state  |
			| --- | ------------- | ----------- | --------------- | ---------------------------------- | ------------- | ----------- | ---------------------- | ------ |
			| 102 | HSR-2026-0102 | 22          | letter          | Salary certificate for CBE loan    | resolved      | 7           | employee_letter_id=67  | active |
			| 103 | HSR-2026-0103 | 14          | id_card         | Replace lost staff ID card         | in_progress   | 7           | --                     | active |
			| 104 | HSR-2026-0104 | 31          | data_correction | Birth date wrong on my profile     | assigned      | 7           | --                     | active |
			| 105 | HSR-2026-0105 | 44          | benefit_inquiry | Add newborn to NIB medical cover   | open          | --          | --                     | active |
			| 106 | HSR-2026-0106 | 15          | payslip_copy    | June + July payslip copies         | closed        | 7           | --                     | active |


#14. HR -- Performance and appraisal

	## lookups first used in this section
		- PERFORMANCE_CYCLE_STATE     : draft | goal_setting | in_progress | review | calibration | closed
		- GOAL_STATE                  : draft | active | achieved | partially_achieved | missed | cancelled
		- GOAL_TYPE                   : individual | team | organizational | developmental
		- GOAL_KPI_UNIT               : count | percent | currency | days | rating
		- APPRAISAL_STATE             : not_started | self_review | manager_review | calibration | acknowledged | completed
		- FEEDBACK_SOURCE             : self | manager | peer | subordinate | external
		- COMPETENCY_CATALOG          : open catalogue -- behavioural/functional competencies (customer_focus | integrity | teamwork | communication | accountability | innovation | leadership | problem_solving | adaptability | technical_mastery | service_excellence | safety_awareness | other); localized via LookupValue.name; platform seeds the above, tenants extend
		- IMPROVEMENT_PLAN_STATE      : draft | active | extended | passed | failed | cancelled
		- IMPROVEMENT_PLAN_ACTION_STATE : pending | in_progress | done | missed

	### LikertScale [DIST] -- one row per rating point on the entity's appraisal scale ("Outstanding" = 5 ... "Unsatisfactory" = 1); Appraisal.final_rating_label renders from these
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- name                    -- jsonb (localized) -- the rating label as it prints on the appraisal form
		- order 				  -- integer -- display order; also the numeric value the point scores
		- user_id                 -- FK User -- who created the row  -- new
		- state				   	  -- active / inactive
		> examples:
			| id | entity_id | name (en)            | order | state  |
			| -- | --------- | -------------------- | ----- | ------ |
			| 1  | 3         | Unsatisfactory       | 1     | active |
			| 2  | 3         | Needs Improvement    | 2     | active |
			| 3  | 3         | Meets Expectations   | 3     | active |
			| 4  | 3         | Exceeds Expectations | 4     | active |
			| 5  | 3         | Outstanding          | 5     | active |

	### PerformanceCycle [DIST] -- one row per appraisal season per entity (annual / semi-annual, Ethiopian-FY aligned)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (PC-2018EC-ANNUAL)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- cycle_state_lookup_value_id -- FK LookupValue (PERFORMANCE_CYCLE_STATE: draft | goal_setting | in_progress | review | calibration | closed)
		- period_start            -- date -- 2026-07-08 (Hamle 1, 2018 EC)
		- period_end              -- date -- 2027-07-07 (Sene 30, 2019 EC)
		- review_start_date       -- date nullable -- when appraisal submissions open
		- review_end_date         -- date nullable -- appraisal + calibration deadline
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code             | name (en)             | entity_id | cycle_state  | period_start | period_end | review_start_date | review_end_date | state  |
			| -- | ---------------- | --------------------- | --------- | ------------ | ------------ | ---------- | ----------------- | --------------- | ------ |
			| 1  | PC-2017EC-ANNUAL | Annual 2017 EC        | 3         | closed       | 2025-07-08   | 2026-07-07 | 2026-06-01        | 2026-07-05      | active |
			| 2  | PC-2018EC-ANNUAL | Annual 2018 EC        | 3         | goal_setting | 2026-07-08   | 2027-07-07 | 2027-06-01        | 2027-07-05      | active |
			| 3  | PC-2018EC-RETAIL | Retail Annual 2018 EC | 7         | goal_setting | 2026-07-08   | 2027-07-07 | 2027-06-01        | 2027-07-05      | active |
			| 4  | PC-2018EC-H1     | Half-year H1 2018 EC  | 9         | draft        | 2026-07-08   | 2027-01-07 | 2026-12-01        | 2027-01-05      | active |
			| 5  | PC-2018EC-SHOP   | Piazza Annual 2018 EC | 12        | draft        | 2026-07-08   | 2027-07-07 | 2027-06-01        | 2027-07-05      | active |

	### PerformanceGoal [DIST] -- one row per objective (individual, team or org level) within a cycle
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (GL-2026-0311)
		- performance_cycle_id    -- FK PerformanceCycle -- season the goal belongs to
		- employee_id             -- FK Employee nullable -- NULL for team/org goals
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning unit for team/org goals
		- goal_type_lookup_value_id -- FK LookupValue (GOAL_TYPE: individual | team | organizational | developmental)
		- goal_state_lookup_value_id -- FK LookupValue (GOAL_STATE: draft | active | achieved | partially_achieved | missed | cancelled)
		- title                   -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- parent_id          -- FK PerformanceGoal (self) nullable -- cascade: org goal -> team goal -> individual goal
		- weight_percent          -- numeric(5,2) -- share within the employee's goal set
		- due_date                -- date nullable
		- progress_percent        -- numeric(5,2) -- rollup of KPI progress
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		- organization_unit_id    -- FK OrganizationUnit nullable -- owning unit for team and organizational goals; entity_id is branch-coarse and cannot express a unit
		> examples:
			| id  | code         | cycle | employee_id | goal_type      | goal_state | title (en)                    | parent_id | weight | progress | state  |
			| --- | ------------ | ----- | ----------- | -------------- | ---------- | ----------------------------- | -------------- | ------ | -------- | ------ |
			| 301 | GL-2026-0301 | 2     | --          | organizational | active     | Grow retail revenue 20%       | --             | 100.00 | 12.00    | active |
			| 302 | GL-2026-0302 | 3     | 14          | individual     | active     | Keep cash variance < 0.1%     | 301            | 40.00  | 35.00    | active |
			| 303 | GL-2026-0303 | 2     | 22          | individual     | active     | Close monthly books by day 5  | --             | 50.00  | 20.00    | active |
			| 304 | GL-2026-0304 | 2     | 7           | developmental  | active     | Complete CIPD Level 7 module  | --             | 30.00  | 10.00    | active |
			| 305 | GL-2026-0305 | 2     | 31          | individual     | draft      | Reduce PO cycle to 5 days     | --             | 60.00  | 0.00     | active |

	### PerformanceGoalKpi [LINE] -- one row per measurable indicator under a goal
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- performance_goal_id                 -- FK PerformanceGoal -- parent goal
		- name                    -- jsonb (localized) -- "Cash variance %", "Books-closed day"
		- unit_lookup_value_id    -- FK LookupValue (GOAL_KPI_UNIT: count | percent | currency | days | rating)
		- baseline_value          -- numeric(15,4) nullable
		- target_value            -- numeric(15,4)
		- current_value           -- numeric(15,4) nullable
		- higher_is_better        -- bool
		- measured_at             -- timestamp nullable -- last update
		- state                   -- active / inactive
		> examples:
			| id  | performance_goal_id | name (en)          | unit    | baseline | target  | current | higher_is_better | state  |
			| --- | ------- | ------------------ | ------- | -------- | ------- | ------- | ---------------- | ------ |
			| 401 | 302     | Cash variance %    | percent | 0.4000   | 0.1000  | 0.2500  | false            | active |
			| 402 | 303     | Books-closed day   | days    | 9.0000   | 5.0000  | 7.0000  | false            | active |
			| 403 | 301     | Retail revenue ETB | currency| 28500000 | 34200000| 29800000| true             | active |
			| 404 | 304     | Modules completed  | count   | 0.0000   | 4.0000  | 1.0000  | true             | active |
			| 405 | 305     | PO cycle days      | days    | 12.0000  | 5.0000  | --      | false            | active |

	### Appraisal [DIST] -- one row per employee's evaluation within a cycle; calibration and approval via core Workflow
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (APR-2026-0107)
		- performance_cycle_id    -- FK PerformanceCycle -- season evaluated
		- employee_id             -- FK Employee -- UNIQUE (performance_cycle_id, employee_id)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- appraiser_employee_id   -- FK Employee -- line manager
		- appraisal_state_lookup_value_id -- FK LookupValue (APPRAISAL_STATE: not_started | self_review | manager_review | calibration | acknowledged | completed)
		- goal_score              -- numeric(5,2) nullable -- weighted goal result on the cycle scale
		- competency_score        -- numeric(5,2) nullable
		- final_score             -- numeric(5,2) nullable -- post-calibration
		- likert_scale_id         -- FK LikertScale nullable -- new -- the calibrated rating point; the printed label renders from LikertScale.name
		- manager_summary         -- jsonb nullable
		- employee_comment        -- jsonb nullable -- acknowledgment note
		- acknowledged_at         -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id  | code         | cycle | employee_id | appraiser | appraisal_state | goal_score | competency_score | final_score | final_rating         | state  |
			| --- | ------------ | ----- | ----------- | --------- | --------------- | ---------- | ---------------- | ----------- | -------------------- | ------ |
			| 101 | APR-2026-0101| 1     | 7           | 44        | completed       | 4.20       | 4.50             | 4.30        | Exceeds Expectations | active |
			| 102 | APR-2026-0102| 1     | 14          | 7         | completed       | 3.80       | 3.60             | 3.70        | Meets Expectations   | active |
			| 103 | APR-2026-0103| 1     | 22          | 44        | acknowledged    | 4.60       | 4.40             | 4.50        | Outstanding          | active |
			| 104 | APR-2026-0104| 1     | 31          | 44        | manager_review  | 2.40       | 2.80             | --          | --                   | active |
			| 105 | APR-2026-0105| 1     | 44          | --        | calibration     | 4.10       | 4.30             | --          | --                   | active |

	### AppraisalFeedback [LINE] -- one row per multi-source (360) input attached to an appraisal
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- appraisal_id            -- FK Appraisal -- parent evaluation
		- source_lookup_value_id  -- FK LookupValue (FEEDBACK_SOURCE: self | manager | peer | subordinate | external)
		- reviewer_employee_id    -- FK Employee nullable -- NULL for external reviewers
		- reviewer_party_id       -- FK Party nullable -- external reviewer identity
		- rating                  -- numeric(5,2) nullable -- on the cycle scale
		- comments                -- jsonb nullable
		- is_anonymous            -- bool -- hide the reviewer from the employee
		- submitted_at            -- timestamp
		- state                   -- active / inactive
		> examples:
			| id  | appraisal_id | source      | reviewer_employee_id | rating | is_anonymous | submitted_at         | state  |
			| --- | ------------ | ----------- | -------------------- | ------ | ------------ | -------------------- | ------ |
			| 601 | 102          | self        | 14                   | 4.00   | false        | 2026-06-20T08:00:00Z | active |
			| 602 | 102          | manager     | 7                    | 3.70   | false        | 2026-06-25T10:30:00Z | active |
			| 603 | 102          | peer        | 15                   | 3.50   | true         | 2026-06-22T12:00:00Z | active |
			| 604 | 103          | manager     | 44                   | 4.50   | false        | 2026-06-26T09:00:00Z | active |
			| 605 | 101          | subordinate | 14                   | 4.60   | true         | 2026-06-23T14:00:00Z | active |

	### AppraisalCompetency [LINE] -- one row per scored competency on an appraisal; competencies come from the central COMPETENCY_CATALOG lookup
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- appraisal_id            -- FK Appraisal -- parent evaluation
		- competency_lookup_value_id -- FK LookupValue (COMPETENCY_CATALOG) -- open catalogue; competencies are maintained centrally, never re-keyed per appraisal
		- name                    -- jsonb (localized) -- label frozen at scoring time
		- weight_percent          -- numeric(5,2)
		- self_rating             -- numeric(5,2) nullable
		- manager_rating          -- numeric(5,2) nullable
		- final_rating            -- numeric(5,2) nullable
		- comments                -- jsonb nullable
		- state                   -- active / inactive
		> examples:
			| id  | appraisal_id | competency        | name (en)         | weight | self | manager | final | state  |
			| --- | ------------ | ----------------- | ----------------- | ------ | ---- | ------- | ----- | ------ |
			| 701 | 102          | customer_focus    | Customer Focus    | 40.00  | 4.00 | 3.80    | 3.80  | active |
			| 702 | 102          | integrity         | Integrity         | 30.00  | 4.50 | 4.00    | 4.00  | active |
			| 703 | 102          | teamwork          | Teamwork          | 30.00  | 3.50 | 3.00    | 3.00  | active |
			| 704 | 103          | technical_mastery | Technical Mastery | 50.00  | 4.50 | 4.60    | 4.60  | active |
			| 705 | 103          | communication     | Communication     | 50.00  | 4.00 | 4.20    | 4.20  | active |

	### PerformanceImprovementPlan [DIST] -- one row per formal improvement plan for an underperformer (PIP); remedial, and its outcome gates disciplinary/separation; approval via core Workflow
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (PIP-2026-0006)
		- employee_id             -- FK Employee -- the person on the plan
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- appraisal_id            -- FK Appraisal nullable -- triggering appraisal
		- plan_state_lookup_value_id -- FK LookupValue (IMPROVEMENT_PLAN_STATE: draft | active | extended | passed | failed | cancelled)
		- supervisor_employee_id  -- FK Employee -- plan owner
		- start_date              -- date
		- end_date                -- date
		- extended_to_date        -- date nullable
		- objectives              -- jsonb -- summary of expectations
		- outcome_summary         -- jsonb nullable
		- closed_at               -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | employee_id | appraisal_id | plan_state | supervisor | start_date | end_date   | extended_to | state  |
			| -- | ------------- | ----------- | ------------ | --------- | ---------- | ---------- | ---------- | ----------- | ------ |
			| 6  | PIP-2026-0006 | 31          | 104          | active    | 44         | 2026-07-15 | 2026-10-15 | --          | active |
			| 7  | PIP-2026-0007 | 15          | --           | passed    | 7          | 2026-03-01 | 2026-06-01 | --          | active |
			| 8  | PIP-2025-0008 | 18          | --           | failed    | 7          | 2025-10-01 | 2026-01-01 | 2026-02-01  | active |
			| 9  | PIP-2026-0009 | 19          | --           | draft     | 44         | 2026-08-01 | 2026-11-01 | --          | active |
			| 10 | PIP-2025-0010 | 20          | --           | cancelled | 7          | 2025-09-01 | 2025-12-01 | --          | active |

	### PerformanceImprovementPlanAction [LINE] -- one row per concrete task or checkpoint inside an improvement plan
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- performance_improvement_plan_id -- FK PerformanceImprovementPlan -- parent plan
		- action_state_lookup_value_id -- FK LookupValue (IMPROVEMENT_PLAN_ACTION_STATE: pending | in_progress | done | missed)
		- title                   -- jsonb (localized)
		- success_criteria        -- jsonb nullable -- measurable target
		- due_date                -- date
		- review_note             -- jsonb nullable
		- reviewed_at             -- timestamp nullable
		- order                   -- integer
		- state                   -- active / inactive
		> examples:
			| id | plan_id | action_state | title (en)                      | due_date   | order | state  |
			| -- | ------ | ------------ | ------------------------------- | ---------- | ----- | ------ |
			| 61 | 6      | in_progress  | Weekly PO backlog review        | 2026-08-15 | 1     | active |
			| 62 | 6      | pending      | Complete procurement SOP course | 2026-09-01 | 2     | active |
			| 63 | 6      | pending      | Cut PO cycle below 8 days       | 2026-10-01 | 3     | active |
			| 64 | 7      | done         | Cash handling retraining        | 2026-04-01 | 1     | active |
			| 65 | 7      | done         | Zero till variance for 60 days  | 2026-05-30 | 2     | active |


#15. HR -- Training and development

	## lookups first used in this section
		- TRAINING_DELIVERY_METHOD    : classroom | online | on_the_job | blended | external
		- TRAINING_SESSION_STATE      : planned | open_for_enrollment | running | completed | cancelled
		- TRAINING_NEED_PRIORITY      : low | medium | high | mandatory_compliance
		- TRAINING_NEED_SOURCE        : needs_analysis | appraisal | improvement_plan | compliance | self_request | manager_nomination
		- TRAINING_NEED_STATE         : identified | planned | fulfilled | dropped
		- TRAINING_ENROLLMENT_STATE   : requested | approved | rejected | enrolled | waitlisted | withdrawn
		- TRAINING_RESULT             : in_progress | completed | failed | no_show
		- TRAINING_COMMITMENT_STATE   : draft | active | fulfilled | breached | waived
		- COMPANY_VALUE               : open catalogue -- entity-defined culture values (integrity | ownership | teamwork | care | excellence | respect | innovation | other); platform seeds common values, tenants add their own
		- RECOGNITION_TYPE            : kudos | thanks | above_beyond | innovation | teamwork | customer_hero | safety | milestone_anniversary
		- DEVELOPMENT_PLAN_STATE      : draft | active | on_track | at_risk | completed | cancelled
		- DEVELOPMENT_ACTION_STATE    : pending | in_progress | completed | skipped | overdue
		- DEVELOPMENT_ACTION_TYPE     : training_course | mentoring | project_assignment | job_shadowing | reading | certification | rotation | conference

	### TrainingCategory [REF] -- one row per course-catalogue grouping
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (TC-COMPLIANCE, TC-TECH)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- entity_id               -- FK Entity nullable -- NULL = platform seed
		- icon_id                 -- FK Icon nullable
		- order                   -- integer
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | name (en)             | entity_id | order | state  |
			| -- | ------------- | --------------------- | --------- | ----- | ------ |
			| 1  | TC-COMPLIANCE | Compliance & Safety   | --        | 1     | active |
			| 2  | TC-TECH       | Technical Skills      | --        | 2     | active |
			| 3  | TC-LEAD       | Leadership            | --        | 3     | active |
			| 4  | TC-CUSTOMER   | Customer Service      | 7         | 4     | active |
			| 5  | TC-FINANCE    | Finance & Accounting  | 3         | 5     | active |

	### TrainingCourse [REF] -- one row per catalogue course; materials via DocumentAttachment ('HR:TrainingCourse')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (CRS-POS-101)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- entity_id               -- FK Entity nullable -- NULL = platform seed
		- training_category_id    -- FK TrainingCategory -- catalogue grouping
		- delivery_method_lookup_value_id -- FK LookupValue (TRAINING_DELIVERY_METHOD: classroom | online | on_the_job | blended | external)
		- duration_hours          -- numeric(6,2) nullable
		- duration_months         -- integer nullable -- for long-term programs
		- provider_party_id       -- FK Party nullable -- external provider
		- cost_per_participant    -- numeric(15,4) nullable -- ETB
		- currency_id             -- FK Currency nullable
		- validity_months         -- integer nullable -- certification renewal window; feeds EmployeeCertification
		- is_mandatory            -- bool -- compliance training
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code         | name (en)               | category | delivery   | duration_h | cost_pp    | validity_months | mandatory | state  |
			| -- | ------------ | ----------------------- | -------- | ---------- | ---------- | ---------- | --------------- | --------- | ------ |
			| 1  | CRS-POS-101  | POS Operations Basics   | 2        | blended    | 16.00      | 1500.0000  | --              | true      | active |
			| 2  | CRS-FIRE-01  | Fire Safety             | 1        | classroom  | 4.00       | 800.0000   | 24              | true      | active |
			| 3  | CRS-IFRS-201 | IFRS Update 2026        | 5        | external   | 24.00      | 12000.0000 | --              | false     | active |
			| 4  | CRS-LEAD-301 | First-line Leadership   | 3        | classroom  | 40.00      | 18000.0000 | --              | false     | active |
			| 5  | CRS-CUST-102 | Service Excellence      | 4        | on_the_job | 8.00       | 0.0000     | --              | true      | active |

	### TrainingSession [DIST] -- one row per scheduled delivery of a course
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (TRS-2026-0044)
		- training_course_id      -- FK TrainingCourse -- course delivered
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- host / paying entity
		- session_state_lookup_value_id -- FK LookupValue (TRAINING_SESSION_STATE: planned | open_for_enrollment | running | completed | cancelled)
		- start_at                -- timestamp
		- end_at                  -- timestamp
		- location                -- jsonb nullable -- { room: "HQ Training Hall" } / { link: "..." }
		- trainer_employee_id     -- FK Employee nullable -- internal trainer
		- trainer_party_id        -- FK Party nullable -- external trainer
		- capacity                -- integer
		- total_cost              -- numeric(15,4) nullable -- ETB budget for the session
		- currency_id             -- FK Currency nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | course | session_state       | start_at             | end_at               | trainer_employee_id | capacity | total_cost  | state  |
			| -- | ------------- | ------ | ------------------- | -------------------- | -------------------- | ------------------- | -------- | ----------- | ------ |
			| 44 | TRS-2026-0044 | 1      | open_for_enrollment | 2026-08-17T06:00:00Z | 2026-08-18T14:00:00Z | 14                  | 20       | 12000.0000  | active |
			| 45 | TRS-2026-0045 | 2      | completed           | 2026-07-06T06:00:00Z | 2026-07-06T10:00:00Z | --                  | 40       | 32000.0000  | active |
			| 46 | TRS-2026-0046 | 3      | planned             | 2026-09-21T06:00:00Z | 2026-09-23T14:00:00Z | --                  | 5        | 60000.0000  | active |
			| 47 | TRS-2026-0047 | 5      | running             | 2026-07-27T06:00:00Z | 2026-07-31T14:00:00Z | 7                   | 12       | 0.0000      | active |
			| 48 | TRS-2026-0048 | 4      | cancelled           | 2026-08-03T06:00:00Z | 2026-08-07T14:00:00Z | --                  | 15       | 270000.0000 | active |

	### TrainingNeed [DIST] -- one row per identified skill gap assessment -- for an employee, a unit, or the whole entity -- captured before any course or session exists; feeds the annual training plan
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (TRN-2026-0031)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- organization_unit_id    -- FK OrganizationUnit nullable -- unit-level gap
		- employee_id             -- FK Employee nullable -- person-level gap; organization_unit_id and employee_id both NULL = entity-wide gap
		- subject                 -- jsonb -- the gap ({ en: "IFRS 17 readiness for finance staff" })
		- source_lookup_value_id  -- FK LookupValue (TRAINING_NEED_SOURCE: needs_analysis | appraisal | improvement_plan | compliance | self_request | manager_nomination)
		- priority_lookup_value_id -- FK LookupValue (TRAINING_NEED_PRIORITY: low | medium | high | mandatory_compliance)
		- need_state_lookup_value_id -- FK LookupValue (TRAINING_NEED_STATE: identified | planned | fulfilled | dropped)
		- identified_by_employee_id -- FK Employee -- who raised it
		- fulfilled_by_training_session_id -- FK TrainingSession nullable -- the session that closed the gap
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: TrainingEnrollment records who attended an EXISTING session; this table holds demand that has no session yet.
		> examples:
			| id | code          | organization_unit_id | employee_id | subject (en)                     | source             | priority             | need_state | fulfilled_by_session | state  |
			| -- | ------------- | ---------------------- | ----------- | -------------------------------- | ------------------ | -------------------- | ---------- | -------------------- | ------ |
			| 31 | TRN-2026-0031 | 2 (Finance)          | --          | IFRS 17 readiness                | needs_analysis     | high                 | planned    | --                   | active |
			| 32 | TRN-2026-0032 | 3 (Sales)            | --          | Food safety recertification      | compliance         | mandatory_compliance | fulfilled  | 45                   | active |
			| 33 | TRN-2026-0033 | --                     | 31          | Procurement SOP refresher        | improvement_plan   | high                 | planned    | --                   | active |
			| 34 | TRN-2026-0034 | --                     | 14          | Customer conflict de-escalation  | appraisal          | medium               | identified | --                   | active |
			| 35 | TRN-2026-0035 | --                     | --          | New labour proclamation briefing | needs_analysis     | high                 | identified | --                   | active |

	### TrainingEnrollment [DIST] -- one row per employee x session; request/approval via core Workflow when cost-bearing
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- training_session_id     -- FK TrainingSession -- session joined
		- employee_id             -- FK Employee -- UNIQUE (training_session_id, employee_id)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- cost center charged
		- enrollment_state_lookup_value_id -- FK LookupValue (TRAINING_ENROLLMENT_STATE: requested | approved | rejected | enrolled | waitlisted | withdrawn)
		- need_source_lookup_value_id -- FK LookupValue (TRAINING_NEED_SOURCE: needs_analysis | appraisal | improvement_plan | compliance | self_request | manager_nomination) -- what triggered this enrollment
		- requested_by_employee_id -- FK Employee -- self or manager nomination
		- approved_by_employee_id -- FK Employee nullable
		- need_commitment         -- bool default false -- true if the employee must complete the session to close a skill gap or PIP action
		- justification           -- jsonb nullable -- link to skill gap / PIP action
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id  | training_session_id | employee_id | enrollment_state | requested_by | approved_by | state  |
			| --- | ------------------- | ----------- | ---------------- | ------------ | ----------- | ------ |
			| 801 | 44                  | 14          | enrolled         | 7            | 7           | active |
			| 802 | 44                  | 15          | waitlisted       | 7            | --          | active |
			| 803 | 45                  | 7           | enrolled         | 7            | 44          | active |
			| 804 | 46                  | 22          | approved         | 22           | 44          | active |
			| 805 | 47                  | 31          | enrolled         | 44           | 44          | active |

	### TrainingCompletion [LINE] -- one row per enrollment outcome; passing may mint an EmployeeCertification, certificate PDF via DocumentAttachment ('HR:TrainingCompletion')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- training_enrollment_id  -- FK TrainingEnrollment -- UNIQUE
		- result_lookup_value_id  -- FK LookupValue (TRAINING_RESULT: in_progress | completed | failed | no_show)
		- score                   -- numeric(5,2) nullable
		- attendance_percent      -- numeric(5,2) nullable
		- completed_at            -- timestamp nullable
		- employee_certification_id -- FK EmployeeCertification nullable -- certification created on pass
		- feedback                -- jsonb nullable -- participant evaluation of the course
		- state                   -- active / inactive
		> examples:
			| id  | training_enrollment_id | result      | score | attendance_% | completed_at         | employee_certification_id | state  |
			| --- | ---------------------- | ----------- | ----- | ------------ | -------------------- | ------------------------- | ------ |
			| 901 | 803                    | completed   | 92.00 | 100.00       | 2026-07-06T10:00:00Z | --                        | active |
			| 902 | 805                    | in_progress | --    | 60.00        | --                   | --                        | active |
			| 903 | 801                    | in_progress | --    | --           | --                   | --                        | active |
			| 904 | 804                    | in_progress | --    | --           | --                   | --                        | active |
			| 905 | 802                    | no_show     | --    | 0.00         | 2026-07-06T10:00:00Z | --                        | active |

	### TrainingCommitment [DIST] -- one row per bond agreement for sponsored external training; signed bond PDF via DocumentAttachment ('HR:TrainingCommitment')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (TRC-2026-0012)
		- enrollment_type         -- text -- originating document class the bond is attached to: 'TrainingEnrollment' | 'TrainingSession'
		- enrollment_id           -- integer -- primary key of that document, resolved against enrollment_type
		- employee_id             -- FK Employee -- the bonded employee
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- sponsored_amount        -- numeric(15,4) -- total sponsorship cost (fees + allowance + travel)
		- currency_id             -- FK Currency
		- committed_service_months -- integer -- months the employee must serve post-training
		- start_date              -- date -- commitment period start (usually training end)
		- end_date                -- date -- committed until this date
		- employee_guarantee_id   -- FK EmployeeGuarantee nullable -- internal (senior employee) or external guarantor identity
		- witness_party_ids       -- FK jsonb   Party nullable
		- commitment_state_lookup_value_id -- FK LookupValue (TRAINING_COMMITMENT_STATE: draft | active | fulfilled | breached | waived)
		- breach_recovery_amount  -- numeric(15,4) nullable -- pro-rated amount to recover on early exit; settled via PayrollInput on separation
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: on separation, FinalSettlement consults active commitments with end_date > separation date; the unfulfilled fraction becomes a FinalSettlementLine (type = deduction).
		> examples:
			| id | code          | enrollment_type     | enrollment_id | employee_id | sponsored_amount | committed_service_months | start_date | end_date   | commitment_state | employee_guarantee_id | witness_party_id | state  |
			| -- | ------------- | ------------------- | ------------- | ----------- | ---------------- | ------------------------ | ---------- | ---------- | ---------------- | --------------------- | ---------------- | ------ |
			| 1  | TRC-2026-0012 | TrainingEnrollment  | 45            | 22          | 85000.0000       | 24                       | 2026-01-15 | 2028-01-14 | active           | 3                     | 512              | active |
			| 2  | TRC-2026-0013 | TrainingEnrollment  | 47            | 44          | 220000.0000      | 36                       | 2026-03-01 | 2029-02-28 | active           | 4                     | 513              | active |
			| 3  | TRC-2025-0014 | TrainingEnrollment  | 39            | 31          | 45000.0000       | 12                       | 2025-06-01 | 2026-05-31 | fulfilled        | --                    | --               | active |
			| 4  | TRC-2025-0015 | TrainingEnrollment  | 41            | 14          | 30000.0000       | 12                       | 2025-08-01 | 2026-07-31 | breached         | --                    | 514              | active |
			| 5  | TRC-2026-0016 | TrainingEnrollment  | 49            | 7           | 55000.0000       | 18                       | 2026-05-01 | 2027-10-31 | draft            | --                    | --               | active |

	### Recognition [DIST] -- one row per peer or manager kudos; optional points fuel gamification, aggregate feeds the appraisal culture score
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (REC-2026-0417)
		- from_employee_id        -- FK Employee -- giver
		- to_employee_id          -- FK Employee -- receiver (self-recognition disallowed at app level)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- recognition_type_lookup_value_id -- FK LookupValue (RECOGNITION_TYPE: kudos | thanks | above_beyond | innovation | teamwork | customer_hero | safety | milestone_anniversary)
		- company_value_lookup_value_id -- FK LookupValue (COMPANY_VALUE) nullable -- open catalogue of entity-defined culture values
		- message                 -- jsonb (localized)
		- points                  -- integer nullable -- gamification points to the receiver; NULL when the program is not enabled
		- is_public               -- bool -- visible on the entity's kudos feed
		- occurred_at             -- timestamp
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id  | code          | from_employee_id | to_employee_id | recognition_type       | company_value | message (en)                                       | points | is_public | occurred_at          | state  |
			| --- | ------------- | ---------------- | -------------- | ---------------------- | ------------- | -------------------------------------------------- | ------ | --------- | -------------------- | ------ |
			| 417 | REC-2026-0417 | 44               | 22             | above_beyond           | ownership     | Closed the quarterly VAT filing 3 days early      | 50     | true      | 2026-07-08T09:20:00Z | active |
			| 418 | REC-2026-0418 | 7                | 14             | customer_hero          | care          | Recovered an angry customer at Bole POS on Meskel | 30     | true      | 2026-07-11T18:45:00Z | active |
			| 419 | REC-2026-0419 | 22               | 31             | teamwork               | teamwork      | Stepped in on the supplier audit while I was sick | 20     | true      | 2026-07-15T14:10:00Z | active |
			| 420 | REC-2026-0420 | 31               | 44             | thanks                 | --            | Thanks for the mentoring on IFRS 16               | --     | false     | 2026-07-18T10:30:00Z | active |
			| 421 | REC-2026-0421 | 7                | 7              | milestone_anniversary  | --            | 4 years at Haleta (system-generated)              | 100    | true      | 2026-01-10T00:00:00Z | active |

	### DevelopmentPlan [DIST] -- one row per proactive career growth plan; distinct from PerformanceImprovementPlan (remedial), ties to succession and appraisal
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (DEV-2026-0055)
		- employee_id             -- FK Employee -- the person growing
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- objective               -- jsonb (localized) -- "Prepare for Senior Accountant role within 18 months"
		- target_position_id      -- FK JobPosition nullable -- aspirational role
		- start_date              -- date
		- target_end_date         -- date
		- plan_state_lookup_value_id -- FK LookupValue (DEVELOPMENT_PLAN_STATE: draft | active | on_track | at_risk | completed | cancelled)
		- mentor_employee_id      -- FK Employee nullable
		- owner_employee_id       -- FK Employee -- typically the employee themselves; may be the manager for early-career staff
		- last_review_date        -- date nullable
		- outcome_note            -- jsonb nullable -- captured on close
		- need_commitment           -- bool default false -- true if the plan is tied to a TrainingNeed or PerformanceImprovementPlan
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | employee_id | target_position_id | start_date | target_end_date | plan_state | mentor_employee_id | owner_employee_id | need_commitment | state  |
			| -- | ------------- | ----------- | ------------------ | ---------- | --------------- | ---------- | ------------------ | ----------------- | --------------- | ------ |
			| 55 | DEV-2026-0055 | 22          | 40                 | 2026-08-01 | 2028-02-01      | on_track   | 44                 | 22                | false           | active |
			| 56 | DEV-2026-0056 | 31          | 12                 | 2026-06-01 | 2027-06-01      | active     | 7                  | 44                | true            | active |
			| 57 | DEV-2026-0057 | 14          | 24                 | 2026-07-15 | 2027-07-15      | active     | --                 | 14                | false           | active |
			| 58 | DEV-2025-0058 | 22          | 31                 | 2025-01-15 | 2026-01-15      | completed  | 44                 | 22                | false           | active |
			| 59 | DEV-2026-0059 | 44          | --                 | 2026-08-01 | 2027-08-01      | at_risk    | --                 | 44                | false           | active |

	### DevelopmentPlanAction [LINE] -- one row per concrete step inside a plan (course, mentoring, rotation, reading, stretch project)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- development_plan_id     -- FK DevelopmentPlan -- parent plan
		- action_type_lookup_value_id -- FK LookupValue (DEVELOPMENT_ACTION_TYPE: training_course | mentoring | project_assignment | job_shadowing | reading | certification | rotation | conference)
		- description             -- jsonb (localized)
		- linked_ref_type         -- text nullable -- pointer: 'TrainingCourse' | 'TrainingEnrollment' | 'EmployeeMovement' (rotation)
		- linked_ref_id           -- integer nullable
		- start_date              -- date
		- due_date                -- date
		- action_state_lookup_value_id -- FK LookupValue (DEVELOPMENT_ACTION_STATE: pending | in_progress | completed | skipped | overdue)
		- outcome                 -- jsonb nullable -- captured on completion (skill leveled up, cert obtained...)
		- state                   -- active / inactive
		> examples:
			| id  | development_plan_id | action_type          | description (en)                     | linked_ref_type    | linked_ref_id | start_date | due_date   | action_state | state  |
			| --- | ------------------- | -------------------- | ------------------------------------ | ------------------ | ------------- | ---------- | ---------- | ------------ | ------ |
			| 301 | 55                  | training_course      | IFRS 16 -- Lease Accounting          | TrainingCourse     | 12            | 2026-08-05 | 2026-09-30 | in_progress  | active |
			| 302 | 55                  | certification        | ACCA Diploma in IFRS                 | --                 | --            | 2026-09-01 | 2027-06-30 | pending      | active |
			| 303 | 55                  | mentoring            | Monthly 1:1 with Rahel Girma         | --                 | --            | 2026-08-15 | 2028-02-01 | in_progress  | active |
			| 304 | 56                  | job_shadowing        | Shadow HR Officer for 2 weeks        | --                 | --            | 2026-07-01 | 2026-07-14 | completed    | active |
			| 305 | 57                  | rotation             | 3-month rotation to Bahir Dar branch | EmployeeMovement  | 92            | 2026-10-01 | 2026-12-31 | pending      | active |


#16. HR -- Talent and succession

	## lookups first used in this section
		- TALENT_POOL_TYPE            : high_potential | critical_role | leadership | technical_expert
		- SUCCESSION_READINESS        : ready_now | ready_1_year | ready_2_years | development_needed

	### TalentPool [DIST] -- one row per named pool of notable employees (high potentials, critical roles...)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (TP-HIPO-2026)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- pool_type_lookup_value_id -- FK LookupValue (TALENT_POOL_TYPE: high_potential | critical_role | leadership | technical_expert)
		- owner_employee_id       -- FK Employee -- pool curator (usually the HR lead)
		- review_cycle_months     -- integer -- membership revalidation cadence
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code         | name (en)             | entity_id | pool_type        | owner | review_months | state  |
			| -- | ------------ | --------------------- | --------- | ---------------- | ----- | ------------- | ------ |
			| 1  | TP-HIPO-2026 | High Potentials 2026  | 1         | high_potential   | 7     | 6             | active |
			| 2  | TP-CRIT-FIN  | Critical Finance      | 3         | critical_role    | 44    | 12            | active |
			| 3  | TP-LEAD-NEXT | Next Leaders          | 1         | leadership       | 7     | 6             | active |
			| 4  | TP-TECH-POS  | POS Experts           | 7         | technical_expert | 7     | 12            | active |
			| 5  | TP-CRIT-BDR  | Bahir Dar Criticals   | 9         | critical_role    | 44    | 12            | active |

	### TalentPoolMember [LINE] -- one row per pool membership, with its assessment evidence
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- talent_pool_id          -- FK TalentPool -- the pool joined
		- employee_id             -- FK Employee -- UNIQUE (talent_pool_id, employee_id)
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- nominated_by_employee_id -- FK Employee -- who put them forward (manager recommendation or self-nomination)
		- potential_rating        -- numeric(5,2) nullable -- 9-box vertical axis
		- performance_rating      -- numeric(5,2) nullable -- 9-box horizontal axis
		- readiness_lookup_value_id -- FK LookupValue (SUCCESSION_READINESS: ready_now | ready_1_year | ready_2_years | development_needed) nullable -- promotion-readiness even without a succession slot
		- joined_at               -- date
		- exited_at               -- date nullable
		- exit_reason             -- jsonb nullable
		- state                   -- active / inactive
		> examples:
			| id | talent_pool_id | employee_id | nominated_by | potential | performance | joined_at  | exited_at | state  |
			| -- | -------------- | ----------- | ------------ | --------- | ----------- | ---------- | --------- | ------ |
			| 1  | 1              | 22          | 44           | 4.50      | 4.50        | 2026-07-15 | --        | active |
			| 2  | 1              | 14          | 7            | 4.00      | 3.70        | 2026-07-15 | --        | active |
			| 3  | 2              | 22          | 44           | 4.50      | 4.50        | 2026-07-20 | --        | active |
			| 4  | 3              | 7           | 44           | 4.40      | 4.30        | 2026-07-15 | --        | active |
			| 5  | 4              | 14          | 7            | 4.00      | 3.70        | 2026-07-18 | --        | active |

	### SuccessionPlan [DIST] -- one row per coverage plan for a critical position
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (SUC-2026-0004)
		- job_position_id         -- FK JobPosition -- the covered seat
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- incumbent_employee_id   -- FK Employee nullable -- current holder
		- vacancy_risk            -- jsonb nullable -- { level: "high", note: "market demand" }
		- review_date             -- date -- next revalidation
		- owner_employee_id       -- FK Employee -- accountable planner
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | job_position_id | entity_id | incumbent_employee_id | risk (level) | review_date | owner | state  |
			| -- | ------------- | ---------------- | --------- | --------------------- | ------------ | ----------- | ----- | ------ |
			| 4  | SUC-2026-0004 | 30               | 3         | 44                    | high         | 2027-01-15  | 7     | active |
			| 5  | SUC-2026-0005 | 31               | 3         | 22                    | medium       | 2027-01-15  | 7     | active |
			| 6  | SUC-2026-0006 | 12               | 3         | 7                     | low          | 2027-06-30  | 44    | active |
			| 7  | SUC-2026-0007 | 24               | 7         | 14                    | medium       | 2026-12-31  | 7     | active
			| 8  | SUC-2026-0008 | 40          | 9         | 31                    | high         | 2026-12-31  | 44    | active |

	### Successor [LINE] -- one row per ranked candidate inside a succession plan
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- succession_plan_id      -- FK SuccessionPlan -- parent plan
		- employee_id             -- FK Employee -- UNIQUE (succession_plan_id, employee_id)
		- readiness_lookup_value_id -- FK LookupValue (SUCCESSION_READINESS: ready_now | ready_1_year | ready_2_years | development_needed)
		- rank                    -- integer -- 1 = first in line
		- assessed_at             -- date
		- state                   -- active / inactive
		> examples:
			| id | succession_plan_id | employee_id | readiness          | rank | assessed_at | state  |
			| -- | ------------------ | ----------- | ------------------ | ---- | ----------- | ------ |
			| 1  | 4                  | 22          | ready_1_year       | 1    | 2026-07-20  | active |
			| 2  | 4                  | 7           | ready_2_years      | 2    | 2026-07-20  | active |
			| 3  | 5                  | 22          | ready_now          | 1    | 2026-07-20  | active |
			| 4  | 7                  | 15          | development_needed | 1    | 2026-07-22  | active |
			| 5  | 6                  | 14          | ready_2_years      | 1    | 2026-07-22  | active |


#17. HR -- Compensation review

	## lookups first used in this section
		- COMPENSATION_CYCLE_STATE    : draft | open | review | approved | applied | closed
		- COMPENSATION_PROPOSAL_STATE : draft | submitted | approved | rejected | applied
		- COMPENSATION_PROPOSAL_TYPE  : merit_increase | promotion_increase | market_adjustment | one_time_bonus

	### CompensationCycle [DIST] -- one row per periodic pay-review campaign (merit increases, market adjustments); approval via core Workflow
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (CMP-2018EC)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- campaign owner; applies down the subtree
		- cycle_state_lookup_value_id -- FK LookupValue (COMPENSATION_CYCLE_STATE: draft | open | review | approved | applied | closed)
		- effective_date          -- date -- when applied increases hit EmployeeSalary
		- review_start_date       -- date nullable -- proposal window opens
		- review_end_date         -- date nullable -- proposal window closes
		- currency_id             -- FK Currency
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code        | name (en)               | entity_id | cycle_state | effective_date | review_start_date | review_end_date | currency | state  |
			| -- | ----------- | ----------------------- | --------- | ----------- | -------------- | ----------------- | --------------- | -------- | ------ |
			| 1  | CMP-2017EC  | FY2017 EC Merit Review  | 1         | closed      | 2025-07-08     | 2025-05-01        | 2025-06-15      | ETB      | active |
			| 2  | CMP-2018EC  | FY2018 EC Merit Review  | 1         | review      | 2026-07-08     | 2026-05-01        | 2026-06-15      | ETB      | active |
			| 3  | CMP-BDR-ADJ | Bahir Dar Market Adjust | 9         | open        | 2026-09-01     | 2026-07-15        | 2026-08-15      | ETB      | active |
			| 4  | CMP-RET-BON | Retail Perf Bonus       | 7         | approved    | 2026-08-01     | 2026-06-01        | 2026-07-10      | ETB      | active |
			| 5  | CMP-2019EC  | FY2019 EC Merit Review  | 1         | draft       | 2027-07-08     | --                | --              | ETB      | active |

	### CompensationBudget [DIST] -- one row per spend envelope per cycle x entity (cost center = Entity node)
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- compensation_cycle_id   -- FK CompensationCycle -- parent campaign
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- budgeted cost center -- UNIQUE (compensation_cycle_id, entity_id, organization_unit_id)
		- organization_unit_id    -- FK OrganizationUnit nullable -- unit-level envelope; NULL = whole entity
		- budget_amount           -- numeric(15,4) -- annualized increase budget, ETB
		- committed_amount        -- numeric(15,4) -- cache/denormalized sum of approved/applied proposals
		- currency_id             -- FK Currency
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | compensation_cycle_id | entity_id | budget_amount | committed_amount | state  |
			| -- | --------------------- | --------- | ------------- | ---------------- | ------ |
			| 1  | 2                     | 3         | 1800000.0000  | 642000.0000      | active |
			| 2  | 2                     | 7         | 650000.0000   | 213000.0000      | active |
			| 3  | 2                     | 9         | 400000.0000   | 88000.0000       | active |
			| 4  | 2                     | 12        | 150000.0000   | 0.0000           | active |
			| 5  | 4                     | 7         | 250000.0000   | 96000.0000       | active |

	### CompensationProposal [DIST] -- one row per employee's proposed change inside a cycle; applying creates a new EmployeeSalary version
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- compensation_cycle_id   -- FK CompensationCycle -- parent campaign
		- employee_id             -- FK Employee -- UNIQUE (compensation_cycle_id, employee_id)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- cost center
		- proposal_type_lookup_value_id -- FK LookupValue (COMPENSATION_PROPOSAL_TYPE: merit_increase | promotion_increase | market_adjustment | one_time_bonus)
		- proposal_state_lookup_value_id -- FK LookupValue (COMPENSATION_PROPOSAL_STATE: draft | submitted | approved | rejected | applied)
		- appraisal_id            -- FK Appraisal nullable -- rating evidence
		- current_basic           -- numeric(15,4)
		- proposed_basic          -- numeric(15,4) nullable -- NULL for one_time_bonus
		- increase_percent        -- numeric(7,4) nullable
		- bonus_amount            -- numeric(15,4) nullable
		- currency_id             -- FK Currency
		- proposed_by_employee_id -- FK Employee -- line manager
		- approved_by_employee_id -- FK Employee nullable
		- applied_employee_salary_id -- FK EmployeeSalary nullable -- the new salary version created
		- justification           -- jsonb nullable
		- state                   -- active / inactive
		> examples:
			| id | compensation_cycle_id | employee_id | proposal_type     | proposal_state | current_basic | proposed_basic | increase_% | bonus_amount | proposed_by | state  |
			| -- | --------------------- | ----------- | ----------------- | -------------- | ------------- | -------------- | ---------- | ------------ | ----------- | ------ |
			| 11 | 2                     | 14          | merit_increase    | submitted      | 6500.0000     | 6955.0000      | 7.0000     | --           | 7           | active |
			| 12 | 2                     | 22          | merit_increase    | approved       | 12000.0000    | 13200.0000     | 10.0000    | --           | 44          | active |
			| 13 | 2                     | 7           | merit_increase    | submitted      | 14000.0000    | 15120.0000     | 8.0000     | --           | 44          | active |
			| 14 | 4                     | 14          | one_time_bonus    | approved       | 6500.0000     | --             | --         | 3250.0000    | 7           | active |
			| 15 | 3                     | 31          | market_adjustment | draft          | 7000.0000     | 7420.0000      | 6.0000     | --           | 44          | active |


#18. HR -- Recruitment and onboarding (LYU-integrated)

	-- LYU BOUNDARY --------------------------------------------------------------
	-- External system LYU owns the hiring funnel: applications, exams, interviews,
	-- panel scores, ranking, announcements, appeals. ERP owns the internal demand
	-- (JobRequisition), the posting stub with lyu_job_id, the synced outcome only
	-- (RecruitmentResult: status / score / rank), and everything post-hire (JobOffer,
	-- onboarding, lifecycle). Funnel detail is fetched on demand from the LYU API,
	-- never stored here. Sync events land in the Audit module; probation follow-up
	-- is the Performance engine's job. LYU-facing tables note which columns LYU owns.
	-- ---------------------------------------------------------------------------

	## lookups first used in this section
		- CANDIDATE_SOURCE            : lyu | manual | referral
		- REQUISITION_PRIORITY        : low | medium | high | urgent
		- REQUISITION_STATE           : draft | pending | approved | rejected | filled | cancelled
		- LYU_SYNC_STATUS             : pending | pushed | synced | stale | mismatch | error
		- POSTING_CHANNEL             : internal | external | both
		- POSTING_STATE               : draft | pushed_to_lyu | published | on_hold | closed | filled
		- WORK_ARRANGEMENT            : on_site | remote | hybrid | field
		- RECRUITMENT_RESULT_STATUS   : selected | waitlisted | rejected | withdrawn
		- JOB_OFFER_STATE             : draft | pending_approval | approved | sent | accepted | declined | expired | withdrawn
		- ONBOARDING_STATE            : pending | in_progress | completed | cancelled
		- ONBOARDING_ITEM_STATE       : pending | in_progress | done | waived | overdue
		- ONBOARDING_ITEM_TYPE        : document_collection | equipment | system_access | orientation | training | compliance

	### Candidate [DIST] -- one row per person LYU sent us (or a manual/referral entry); the deep profile stays in LYU
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- tenant that received the record
		- party_id                -- FK Party -- identity anchor, created on first sync so hire linkage has a stable identity
		- lyu_candidate_id        -- text UNIQUE nullable -- LYU external ref; NULL for manual / referral entries
		- full_name_snapshot      -- text -- captured from LYU at first sync (survives Party rename downstream)
		- phone_snapshot          -- text nullable -- snapshot from LYU
		- email_snapshot          -- text nullable -- snapshot from LYU
		- nationality_country_id  -- FK Country nullable
		- source_lookup_value_id  -- FK LookupValue (CANDIDATE_SOURCE: lyu | manual | referral)
		- referred_by_employee_id -- FK Employee nullable -- referral reward eligibility; set when source = referral
		- lyu_profile_url         -- text nullable -- deep link back to the LYU candidate profile
		- lyu_last_synced_at      -- timestamp nullable -- last snapshot refresh from LYU
		- converted_employee_id   -- FK Employee nullable -- hire linkage; set only when the Offer is accepted and the Employee is created
		- is_blacklisted          -- bool -- ERP-side flag (integrity issue, fraud...); blocks future offers
		- blacklist_reason        -- jsonb nullable
		- user_id                 -- FK User -- who created the row (sync worker or recruiter)
		- state                   -- active / inactive
		  -- note: column source -- LYU owns lyu_candidate_id, lyu_profile_url, lyu_last_synced_at, the *_snapshot fields and nationality; ERP owns party_id, referral, conversion and blacklist fields.
		  -- note: UNIQUE (lyu_candidate_id) makes the sync worker's upsert idempotent; manual entries keep it NULL and skip the constraint.
		> examples:
			| id  | party_id | lyu_candidate_id       | full_name_snapshot | phone_snapshot | source   | referred_by | converted_employee_id | is_blacklisted | state  |
			| --- | -------- | ---------------------- | ------------------ | -------------- | -------- | ----------- | --------------------- | -------------- | ------ |
			| 501 | 901      | LYU-CAN-2026-014520    | Meaza Getachew     | +251912345678  | lyu      | --          | --                    | false          | active |
			| 502 | 902      | LYU-CAN-2026-014571    | Dawit Assefa       | +251911223344  | referral | 22          | --                    | false          | active |
			| 503 | 903      | LYU-CAN-2026-014610    | Bethelhem Yohannes | +251922334455  | lyu      | --          | --                    | false          | active |
			| 504 | 904      | LYU-CAN-2026-014633    | Kaleab Tesfa       | +251933445566  | lyu      | --          | --                    | true           | active |
			| 505 | 905      | --                     | Hana Molla         | +251944556677  | manual   | --          | --                    | false          | active |

	### JobRequisition [DIST] -- one row per internal demand for a hire; approval via core Workflow, precedes any LYU push
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (REQ-2026-0027)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- hiring cost center
		- job_position_id         -- FK JobPosition -- the SEAT to fill (title x unit x grade); establishment gates anchor here
		- organization_unit_id    -- FK OrganizationUnit -- cache/denormalized from the position's unit
		- requisition_state_lookup_value_id -- FK LookupValue (REQUISITION_STATE: draft | pending | approved | rejected | filled | cancelled)
		- openings_count          -- integer -- seats requested
		- employment_type_lookup_value_id -- FK LookupValue (EMPLOYMENT_TYPE: permanent | contract | temporary | probation | part_time | intern | consultant)
		- justification           -- jsonb -- replacement vs growth narrative
		- replacement_for_employee_id -- FK Employee nullable -- backfill target
		- hr_service_agreement_id -- FK HRServiceAgreement nullable -- set when hiring FOR a client under a staffing agreement (section 11); NULL = hiring for ourselves
		- client_party_id         -- FK Party nullable -- cache/denormalized client identity for requisition list screens; matches the agreement's client
		- budgeted_salary         -- numeric(15,4) nullable -- monthly, ETB
		- currency_id             -- FK Currency
		- target_start_date       -- date nullable
		- requested_by_employee_id -- FK Employee -- who raised the demand
		- hiring_manager_employee_id -- FK Employee nullable -- manager the new hire will report to; may differ from the requester and the approver
		- approved_by_employee_id -- FK Employee nullable
		- approved_at             -- timestamp nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		- priority_lookup_value_id -- FK LookupValue (REQUISITION_PRIORITY: low | medium | high | urgent) -- queues the recruitment pipeline; target_start_date is a date, not an urgency
		  -- note: column source: ERP-only.
		> examples:
			| id | code         | entity_id | job_position_id | requisition_state | openings | employment_type | replacement_for | budgeted_salary | requested_by | state  |
			| -- | ------------ | --------- | ----------- | ----------------- | -------- | --------------- | --------------- | --------------- | ------------ | ------ |
			| 27 | REQ-2026-0027| 7         | 24          | approved          | 2        | permanent       | --              | 7000.0000       | 7            | active |
			| 28 | REQ-2026-0028| 3         | 31          | approved          | 1        | permanent       | 22              | 13000.0000      | 44           | active |
			| 29 | REQ-2026-0029| 9         | 40          | pending           | 1        | contract        | --              | 7500.0000       | 44           | active |
			| 30 | REQ-2026-0030| 12        | 24          | draft             | 1        | part_time       | --              | 5500.0000       | 7            | active |
			| 31 | REQ-2025-0031| 3         | 12          | filled            | 1        | permanent       | --              | 12500.0000      | 44           | active |

	### JobPosting [DIST] -- one row per ERP-side shadow of an LYU vacancy; the LYU boundary object
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (JPO-2026-0018) -- ERP-side ref for reports and audit
		- job_requisition_id      -- FK JobRequisition -- the internal demand this posting fulfils
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- hiring entity
		- job_title_id             -- FK JobTitle -- cache/denormalized: the requisition position's title, for query speed
		- openings_count          -- integer -- seats this posting advertises; a requisition may split across several postings
		- posting_channel_lookup_value_id -- FK LookupValue (POSTING_CHANNEL: internal | external | both) -- internal-only postings never push to LYU
		- title_snapshot          -- jsonb (localized) -- last known title from LYU; drift-tolerant local mirror ERP can render offline
		- posting_date            -- date nullable -- when ERP pushed this to LYU (NULL while draft)
		- closing_date            -- date nullable -- as reported by LYU on last pull
		- location_admin_unit_id  -- FK AdminUnit nullable -- duty station (Bole, Bahir Dar)
		- salary_range_note       -- jsonb nullable -- { en: "Negotiable / per company scale" }
		- posting_state_lookup_value_id -- FK LookupValue (POSTING_STATE: draft | pushed_to_lyu | published | on_hold | closed | filled)
		- lyu_job_id              -- text UNIQUE nullable -- LYU external ref, set on first successful push (LYU-JOB-2026-00045)
		- lyu_last_pushed_at      -- timestamp nullable -- last outbound sync
		- lyu_last_pulled_at      -- timestamp nullable -- last inbound sync (metadata + results)
		- lyu_sync_status_lookup_value_id -- FK LookupValue (LYU_SYNC_STATUS: pending | pushed | synced | stale | mismatch | error)
		- lyu_sync_error          -- jsonb nullable -- last error payload for triage; NULL when sync is OK
		- lyu_profile_url         -- text nullable -- deep link back to the LYU posting page
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		- work_arrangement_lookup_value_id -- FK LookupValue (WORK_ARRANGEMENT: on_site | remote | hybrid | field) nullable -- advertised working arrangement; pushed to LYU with the posting
		  -- note: column source -- LYU owns lyu_job_id, lyu_last_pushed_at / pulled_at, lyu_sync_status, lyu_sync_error, lyu_profile_url and closing_date (refreshed by pull); ERP owns the rest.
		  -- note: a draft posting carries lyu_job_id = NULL until pushed -- reports must not join on lyu_job_id unconditionally.
		> examples:
			| id | code          | job_requisition_id | job_title_id | title (en)           | posting_date | closing_date | state         | lyu_job_id            | lyu_sync_status |
			| -- | ------------- | ------------------ | ----------- | -------------------- | ------------ | ------------ | ------------- | --------------------- | --------------- |
			| 18 | JPO-2026-0018 | 27                 | 24          | Senior Cashier       | 2026-07-10   | 2026-08-09   | published     | LYU-JOB-2026-00045    | synced          |
			| 19 | JPO-2026-0019 | 28                 | 31          | Financial Accountant | 2026-07-12   | 2026-08-01   | published     | LYU-JOB-2026-00046    | synced          |
			| 20 | JPO-2026-0020 | 29                 | 40          | Procurement Officer  | --           | --           | draft         | --                    | pending         |
			| 21 | JPO-2026-0021 | 27                 | 24          | Cashier (Piazza)     | 2026-07-15   | 2026-08-15   | on_hold       | LYU-JOB-2026-00047    | synced          |
			| 22 | JPO-2025-0022 | 31                 | 12          | HR Officer           | 2025-11-01   | 2025-11-30   | filled        | LYU-JOB-2025-00812    | synced          |

	### RecruitmentResult [DIST] -- one row per synced LYU outcome; one CURRENT row per (job_posting, candidate) pair, superseded rows kept for audit
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- job_posting_id          -- FK JobPosting -- vacancy the result belongs to
		- candidate_id            -- FK Candidate -- person the result concerns
		- result_status_lookup_value_id -- FK LookupValue (RECRUITMENT_RESULT_STATUS: selected | waitlisted | rejected | withdrawn)
		- overall_score           -- numeric(5,2) nullable -- final composite score reported by LYU (0-100)
		- rank                    -- integer nullable -- final rank among candidates for this posting
		- remarks                 -- jsonb nullable -- LYU-provided verdict text ({ en, am })
		- lyu_result_ref          -- text nullable -- LYU's opaque result id for backtrace
		- received_at             -- timestamp -- when ERP first received this result (never updated on re-sync)
		- synced_at               -- timestamp -- last upsert time (differs from received_at on re-sync)
		- sync_version            -- integer default 1 -- increments on each re-sync of the same pair
		- synced_by_user_id       -- FK User nullable -- NULL = system-triggered sync
		- is_current              -- bool default TRUE -- FALSE = superseded; only the current row drives JobOffer -- UNIQUE (job_posting_id, candidate_id) WHERE is_current = TRUE
		- superseded_by_id        -- FK RecruitmentResult (self) nullable -- forward link for the audit trail
		- state                   -- active / inactive
		  -- note: column source -- LYU owns result_status, overall_score, rank, remarks, lyu_result_ref, received_at; ERP owns the sync bookkeeping.
		  -- note: a re-sync marks the old row is_current = FALSE with superseded_by_id set, then inserts the new row with sync_version + 1; an unknown candidate is upserted first, in the same transaction.
		> examples:
			| id  | job_posting_id | candidate_id | result_status | overall_score | rank | received_at          | sync_version | is_current | superseded_by | state  |
			| --- | -------------- | ------------ | ------------- | ------------- | ---- | -------------------- | ------------ | ---------- | ------------- | ------ |
			| 801 | 18             | 501          | selected      | 88.50         | 1    | 2026-08-10T09:00:00Z | 1            | true       | --            | active |
			| 802 | 18             | 503          | waitlisted    | 76.00         | 3    | 2026-08-10T09:00:00Z | 1            | true       | --            | active |
			| 803 | 18             | 504          | rejected      | 42.00         | 8    | 2026-08-10T09:00:00Z | 1            | true       | --            | active |
			| 804 | 19             | 502          | selected      | 91.00         | 1    | 2026-08-02T09:00:00Z | 1            | false      | 805           | active |
			| 805 | 19             | 502          | selected      | 92.50         | 1    | 2026-08-04T14:20:00Z | 2            | true       | --            | active |

	### JobOffer [DIST] -- one row per offer document; letter PDF via LetterTemplate + DocumentAttachment ('HR:JobOffer'), approval via core Workflow
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (OFF-2026-0033)
		- recruitment_result_id   -- FK RecruitmentResult -- must reference a row with is_current = TRUE and result_status = selected (application-enforced)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- employing entity; this IS the branch-placement decision and may differ from the posting's entity
		- job_position_id         -- FK JobPosition -- the SEAT offered; entity_id remains the branch-placement decision
		- job_grade_id                -- FK JobGrade -- grade offered
		- salary_structure_id     -- FK SalaryStructure nullable -- package template used
		- offer_state_lookup_value_id -- FK LookupValue (JOB_OFFER_STATE: draft | pending_approval | approved | sent | accepted | declined | expired | withdrawn)
		- basic_amount            -- numeric(15,4) -- offered monthly basic, ETB
		- currency_id             -- FK Currency
		- proposed_start_date     -- date
		- expiry_date             -- date -- offer validity
		- employment_type_lookup_value_id -- FK LookupValue (EMPLOYMENT_TYPE: permanent | contract | temporary | probation | part_time | intern | consultant)
		- sent_at                 -- timestamp nullable
		- responded_at            -- timestamp nullable
		- decline_reason          -- jsonb nullable
		- approved_by_employee_id -- FK Employee nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: column source: ERP-only -- the offer package is Haleta compensation policy, not LYU's.
		> examples:
			| id | code          | recruitment_result_id | job_position_id | job_grade_id | offer_state | basic_amount | proposed_start_date | expiry_date | state  |
			| -- | ------------- | --------------------- | ----------- | -------- | ----------- | ------------ | ------------------- | ----------- | ------ |
			| 33 | OFF-2026-0033 | 805                   | 31          | 5        | sent        | 13500.0000   | 2026-09-01          | 2026-08-20  | active |
			| 34 | OFF-2026-0034 | 801                   | 24          | 3        | draft       | 7000.0000    | 2026-09-15          | 2026-08-25  | active |
			| 35 | OFF-2025-0035 | 794                   | 12          | 5        | accepted    | 12500.0000   | 2026-01-05          | 2025-12-20  | active |
			| 36 | OFF-2025-0036 | 787                   | 24          | 3        | declined    | 6200.0000    | 2025-10-01          | 2025-09-15  | active |
			| 37 | OFF-2026-0037 | 799                   | 40          | 3        | expired     | 7200.0000    | 2026-05-01          | 2026-04-15  | active |

	### JobOfferComponent [LINE] -- one row per offered package line; mirrors EmployeeSalaryComponent shape and is copied on acceptance
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- job_offer_id                -- FK JobOffer -- parent offer
		- payroll_component_id    -- FK PayrollComponent -- UNIQUE (job_offer_id, payroll_component_id)
		- amount                  -- numeric(15,4) nullable
		- percent                 -- numeric(7,4) nullable
		- notes                   -- jsonb nullable
		- order                   -- integer
		- state                   -- active / inactive
		  -- note: column source: ERP-only.
		> examples:
			| id  | job_offer_id | payroll_component_id | amount     | percent | order | state  |
			| --- | -------- | -------------------- | ---------- | ------- | ----- | ------ |
			| 331 | 33       | 1 (BASIC)            | 13500.0000 | --      | 1     | active |
			| 332 | 33       | 2 (TRANS_ALLOW)      | 2200.0000  | --      | 2     | active |
			| 333 | 34       | 1 (BASIC)            | 7000.0000  | --      | 1     | active |
			| 334 | 34       | 2 (TRANS_ALLOW)      | 1750.0000  | --      | 2     | active |
			| 335 | 35       | 1 (BASIC)            | 12500.0000 | --      | 1     | active |

	### OnboardingChecklist [REF] -- one row per onboarding task template per entity or job family
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- human-readable business code, unique per entity (ONB-RETAIL, ONB-OFFICE)
		- name                    -- jsonb (localized)
		- description             -- jsonb (localized) nullable
		- entity_id               -- FK Entity nullable -- NULL = platform seed
		- job_title_id            -- FK JobTitle nullable -- role-specific template (JobFamily does not exist in this design)
		- items_template          -- jsonb -- ordered item seeds: [{ key, type, title, due_offset_days, owner_role }]
		- is_system               -- platform-seeded row
		- status_lookup_value_id  -- FK LookupValue (core governance: pending | acceptForAll | acceptForThis | reject)
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: column source: ERP-only.
		> examples:
			| id | code       | name (en)          | entity_id | job_title_id  | items (count) | state  |
			| -- | ---------- | ------------------ | --------- | ------------- | ------------- | ------ |
			| 1  | ONB-OFFICE | Office Onboarding  | 3         | --            | 8             | active |
			| 2  | ONB-RETAIL | Retail Onboarding  | 7         | 3             | 10            | active |
			| 3  | ONB-BDR    | Bahir Dar Onboard  | 9         | --            | 9             | active |
			| 4  | ONB-FIN    | Finance Onboarding | 3         | 2             | 11            | active |
			| 5  | ONB-TPL    | Default Template   | --        | --            | 6             | active |

	### Onboarding [DIST] -- one row per new hire's onboarding case between offer acceptance and full activation; owns the task list and the overall state
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (ONB-2026-0031)
		- employee_id             -- FK Employee -- the new hire
		- job_offer_id            -- FK JobOffer nullable -- the accepted offer that started the case; NULL for legacy or manual hires
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- entity_id               -- FK Entity -- receiving branch
		- onboarding_checklist_id -- FK OnboardingChecklist -- template instantiated into items
		- onboarding_state_lookup_value_id -- FK LookupValue (ONBOARDING_STATE: pending | in_progress | completed | cancelled)
		- expected_start_date     -- date -- from the offer
		- actual_start_date       -- date nullable -- first day actually worked
		- assigned_hr_employee_id -- FK Employee nullable -- HR owner of the case
		- completed_at            -- timestamp nullable -- set when every is_mandatory item is done
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | employee_id | job_offer_id | onboarding_state | expected_start_date | actual_start_date | assigned_hr | completed_at         | state  |
			| -- | ------------- | ----------- | ------------ | ---------------- | ------------------- | ----------------- | ----------- | -------------------- | ------ |
			| 1  | ONB-2026-0031 | 31          | 35           | in_progress      | 2026-02-17          | 2026-02-17        | 7           | --                   | active |
			| 2  | ONB-2024-0014 | 14          | 29           | completed        | 2024-06-01          | 2024-06-01        | 7           | 2024-06-20T09:00:00Z | active |
			| 3  | ONB-2026-0055 | 55          | 38           | pending          | 2026-09-01          | --                | 7           | --                   | active |
			| 4  | ONB-2026-0056 | 56          | 39           | in_progress      | 2026-08-15          | 2026-08-17        | 7           | --                   | active |
			| 5  | ONB-2025-0021 | 21          | --           | cancelled        | 2025-10-01          | --                | 7           | --                   | active |

	### OnboardingItem [LINE] -- one row per instantiated checklist task for one new hire; created from the template on hire effect
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- employee_id             -- FK Employee -- the new hire
		- onboarding_id           -- FK Onboarding -- the onboarding case this task belongs to
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- owning tenant/branch
		- onboarding_checklist_id -- FK OnboardingChecklist -- template provenance
		- item_type_lookup_value_id -- FK LookupValue (ONBOARDING_ITEM_TYPE: document_collection | equipment | system_access | orientation | training | compliance)
		- item_state_lookup_value_id -- FK LookupValue (ONBOARDING_ITEM_STATE: pending | in_progress | done | waived | overdue)
		- title                   -- jsonb (localized) -- "Collect Fayda copy", "Issue POS login"
		- is_mandatory            -- bool -- must be done (not waivable) before the onboarding completes
		- owner_employee_id       -- FK Employee nullable -- responsible person
		- due_date                -- date
		- completed_at            -- timestamp nullable
		- notes                   -- jsonb nullable
		- state                   -- active / inactive
		  -- note: column source: ERP-only.
		> examples:
			| id   | employee_id | onboarding_checklist_id | item_type           | item_state  | title (en)          | owner | due_date   | state  |
			| ---- | ----------- | ----------------------- | ------------------- | ----------- | ------------------- | ----- | ---------- | ------ |
			| 7001 | 31          | 3                       | document_collection | done        | Collect Fayda copy  | 7     | 2026-02-20 | active |
			| 7002 | 31          | 3                       | compliance          | done        | Pension registration| 7     | 2026-03-01 | active |
			| 7003 | 31          | 3                       | system_access       | in_progress | ERP login + roles   | --    | 2026-02-24 | active |
			| 7004 | 31          | 3                       | equipment           | pending     | Laptop + SIM        | --    | 2026-02-28 | active |
			| 7005 | 31          | 3                       | orientation         | done        | Branch orientation  | 44    | 2026-02-19 | active |


#19. HR -- Multi-entity workforce (HR service provider / staffing / employer-of-record)

	-- SEPARATION PRINCIPLE -------------------------------------------------------
	-- Five independent facts, never assumed equal: who employs (Employee.entity_id
	-- + EmploymentContract), who receives the service (ClientAssignment client),
	-- where the work happens (client branch / department), who is responsible for
	-- payroll (HRServiceAgreement.payroll_responsibility), and who funds the
	-- payment (PaymentBatch.funding_entity_id). Clients are Haleta tenants
	-- (client_entity_id set; branch facts ride Entity FKs) or external companies
	-- (client_party_id only; billed via the provider's Sales module). Leased staff
	-- stay under the PROVIDER's tenancy; client access is Entity.path-scoped.
	-- ---------------------------------------------------------------------------

	## lookups first used in this section
		- AGREEMENT_STATE             : draft | pending_approval | active | suspended | expired | terminated
		- AGREEMENT_TYPE              : staffing | outsourcing | employer_of_record | secondment_out | consultancy
		- PAYROLL_RESPONSIBILITY      : employer_pays | client_funds_employer_pays | client_pays_directly
		- SERVICE_FEE_TYPE            : percent_of_payroll | fixed_per_employee | fixed_monthly | markup_percent
		- CLIENT_ASSIGNMENT_STATE     : draft | active | completed | recalled | terminated

	### HRServiceAgreement [DIST] -- one row per contract between a workforce provider and a client; approval via core Workflow, signed contract via DocumentAttachment ('HR:HRServiceAgreement')
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- code                    -- via DocumentSequence (HSA-2026-0003)
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- provider_entity_id      -- FK Entity -- the tenant employing and supplying the staff
		  -- this IS the table's entity_id (owning branch); the column is named for its role, so there is no separate entity_id
		- client_party_id         -- FK Party -- client identity, always set; Party carries name / tin / contacts
		  -- always set because it is the ONLY client identity an external (non-tenant) client has
		- client_entity_id        -- FK Entity nullable -- set ONLY when the client is also a Haleta tenant; unlocks branch-level FKs + cross-entity payroll funding
		  -- when set, its Entity.party_id MUST equal client_party_id -- one client, one identity, two ways to reach it
		  -- it is what gates ClientAssignment.client_branch_entity_id / client_organization_unit_id / client_position_id
		  -- and PaymentBatch.funding_entity_id; an external client leaves all of those NULL and is billed via Sales
		  -- CHECK: client_entity_id <> provider_entity_id -- a provider cannot contract with itself
		- agreement_type_lookup_value_id -- FK LookupValue (AGREEMENT_TYPE: staffing | outsourcing | employer_of_record | secondment_out | consultancy)
		- agreement_state_lookup_value_id -- FK LookupValue (AGREEMENT_STATE: draft | pending_approval | active | suspended | expired | terminated)
		- start_date              -- date
		- end_date                -- date nullable -- NULL = open-ended
		- max_employees           -- integer nullable -- headcount ceiling under this agreement; NULL = uncapped
		- payroll_responsibility_lookup_value_id -- FK LookupValue (PAYROLL_RESPONSIBILITY: employer_pays | client_funds_employer_pays | client_pays_directly)
		- service_fee_type_lookup_value_id -- FK LookupValue (SERVICE_FEE_TYPE: percent_of_payroll | fixed_per_employee | fixed_monthly | markup_percent) nullable
		- service_fee_value       -- numeric(15,4) nullable -- percent or amount per the fee type
		- billing_currency_id     -- FK Currency
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		> examples:
			| id | code          | provider_entity_id | client_party_id       | client_entity_id | agreement_type     | agr_state | start_date | payroll_responsibility      | fee                  | state  |
			| -- | ------------- | ------------------ | --------------------- | ---------------- | ------------------ | --------- | ---------- | --------------------------- | -------------------- | ------ |
			| 3  | HSA-2026-0003 | 20 (Selam Workforce)| 940 (Haleta Group)   | 1                | staffing           | active    | 2026-01-01 | client_funds_employer_pays  | percent_of_payroll 8 | active |
			| 4  | HSA-2026-0004 | 20 (Selam Workforce)| 960 (Nyala Insurance)| --               | employer_of_record | active    | 2026-03-01 | employer_pays               | fixed_per_employee 1500 | active |
			| 5  | HSA-2026-0005 | 20 (Selam Workforce)| 961 (Habesha Brew.)  | --               | outsourcing        | active    | 2026-02-01 | employer_pays               | fixed_monthly 45000  | active |
			| 6  | HSA-2025-0006 | 20 (Selam Workforce)| 940 (Haleta Group)   | 1                | staffing           | expired   | 2025-01-01 | client_funds_employer_pays  | percent_of_payroll 7 | active |
			| 7  | HSA-2026-0007 | 1  (Haleta Group)  | 962 (Zafir Hotels)   | --               | secondment_out     | pending_approval | 2026-09-01 | client_funds_employer_pays | markup_percent 12 | active |

	### ClientAssignment [DIST] -- one row per employee leased to one client for a period, under an agreement; the history answers who worked where, for whom, when
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs
		- tenant_id               -- FK Entity (tenant root) -- NOT NULL, indexed; stamped by ModelTrait, never from a payload  -- new
		- code                    -- via DocumentSequence (CAS-2026-0041)
		- employee_id             -- FK Employee -- legal employment stays with the provider; this row never changes the employer
		- hr_service_agreement_id -- FK HRServiceAgreement -- governs the assignment; the agreement carries client + payroll responsibility
		- client_branch_entity_id -- FK Entity nullable -- the client's branch (tenant clients only; Entity IS the branch granularity)
		- client_organization_unit_id    -- FK OrganizationUnit nullable -- unit inside the client's structure (tenant clients only)
		- client_position_id      -- FK JobPosition nullable -- seat in the client's structure (tenant clients only)
		- client_role_title       -- text nullable -- verbatim role at an EXTERNAL client, like EmployeeExperience.position_title; internal clients use client_position_id
		- duty_station_admin_unit_id -- FK AdminUnit nullable -- physical location; covers external clients whose structure is not modelled
		- assignment_state_lookup_value_id -- FK LookupValue (CLIENT_ASSIGNMENT_STATE: draft | active | completed | recalled | terminated)
		- start_date              -- date
		- end_date                -- date nullable -- NULL = current; history rows are never edited, a move to another client inserts a new row
		- notes                   -- jsonb nullable
		- user_id                 -- FK User -- who created the row
		- state                   -- active / inactive
		  -- note: application rule -- one ACTIVE assignment per employee at a time, unless the agreement allows split placements.
		> examples: (employee 61 Kebede moves client B -> client C with full history; employees belong to provider entity 20)
			| id | code          | employee_id | hr_service_agreement_id | client_branch_entity_id | client_position_id | client_role_title | duty_station | ca_state  | start_date | end_date   | state  |
			| -- | ------------- | ----------- | ----------------------- | ----------------------- | ------------------ | ----------------- | ------------ | --------- | ---------- | ---------- | ------ |
			| 41 | CAS-2026-0041 | 61          | 3                       | 7 (Bole Branch)         | 24 (Senior Cashier)| --                | 315          | completed | 2026-01-05 | 2026-06-30 | active |
			| 42 | CAS-2026-0042 | 61          | 4                       | --                      | --                 | Claims Clerk      | 305          | active    | 2026-07-01 | --         | active |
			| 43 | CAS-2026-0043 | 62          | 3                       | 9 (Bahir Dar Branch)    | 24 (Senior Cashier)| --                | 401          | active    | 2026-02-01 | --         | active |
			| 44 | CAS-2026-0044 | 63          | 5                       | --                      | --                 | Site Cleaner      | 320          | active    | 2026-02-15 | --         | active |
			| 45 | CAS-2025-0045 | 62          | 6                       | 12 (Piazza Shop)        | 24 (Senior Cashier)| --                | 320          | completed | 2025-03-01 | 2025-12-31 | active |

	### PayslipCostAllocation [LINE] -- one row per share of a payslip's employer cost, split across branches / units / client assignments; no rows = 100% to the assignment entity
		- id                      -- primary key
		- uuid                    -- public identifier used in URLs and APIs  -- new
		- tenant_id               -- FK Entity (tenant root) -- copied from the header via Tenancy::LINES  -- new
		- entity_id               -- FK Entity -- copied from the header via Tenancy::LINES  -- new
		- payslip_id              -- FK Payslip -- the cost being split
		- target_entity_id        -- FK Entity nullable -- target branch / cost center (Entity node); plain entity_id stays the tenancy copy of the payslip's
		- organization_unit_id    -- FK OrganizationUnit nullable -- target org unit
		- client_assignment_id    -- FK ClientAssignment nullable -- target client + agreement (leased staff)
		- percent                 -- numeric(7,4) nullable -- share of gross employer cost; one payslip's rows sum to 100
		- amount                  -- numeric(15,4) nullable -- fixed-amount alternative; a payslip uses percent OR amount rows, never mixed
		- order                   -- integer
		- state                   -- active / inactive
		  -- note: exactly ONE of target_entity_id / organization_unit_id / client_assignment_id is set per row.
		> examples: (payslip 7742 = 30,000 ETB gross split across two branches and one project unit)
			| id | payslip_id | target_entity_id     | organization_unit_id   | client_assignment_id | percent  | amount     | order | state  |
			| -- | ---------- | -------------------- | ---------------------- | -------------------- | -------- | ---------- | ----- | ------ |
			| 1  | 7742       | 7 (Bole Branch)      | --                     | --                   | 50.0000  | --         | 1     | active |
			| 2  | 7742       | 9 (Bahir Dar Branch) | --                     | --                   | 33.3300  | --         | 2     | active |
			| 3  | 7742       | --                   | 11 (Project X)         | --                   | 16.6700  | --         | 3     | active |
			| 4  | 7755       | --                   | --                     | 41                   | 100.0000 | --         | 1     | active |
			| 5  | 7761       | 7 (Bole Branch)      | --                     | --                   | --       | 15000.0000 | 1     | active |
