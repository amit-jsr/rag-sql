-- ============================================================
-- Synthetic real-estate-domain schema for local Text2SQL development.
-- Models a residential/commercial developer's sales + collections business:
-- pre-sales (lead/opportunity) -> booking -> milestone-based payment plan
-- (EMI/construction-linked) -> demand -> collection (cash/bank receipt),
-- plus the org, project/inventory, and channel-partner masters around it.
-- Mounted into the postgres container's /docker-entrypoint-initdb.d.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS public;

-- ---------- location & org masters ----------

CREATE TABLE country (
    country_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    iso_code TEXT
);
COMMENT ON TABLE country IS 'Country master.';

CREATE TABLE state (
    state_id SERIAL PRIMARY KEY,
    country_id INTEGER NOT NULL REFERENCES country(country_id),
    name TEXT NOT NULL,
    code TEXT
);
COMMENT ON TABLE state IS 'State/province master.';

CREATE TABLE city (
    city_id SERIAL PRIMARY KEY,
    state_id INTEGER NOT NULL REFERENCES state(state_id),
    name TEXT NOT NULL
);
COMMENT ON TABLE city IS 'City master.';

CREATE TABLE branch (
    branch_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    city_id INTEGER NOT NULL REFERENCES city(city_id),
    address_line1 TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true
);
COMMENT ON TABLE branch IS 'A sales office/branch of the developer.';

CREATE TABLE department (
    department_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE     -- Sales, CRM, Finance, Legal, Construction, Marketing
);
COMMENT ON TABLE department IS 'Organizational department.';

CREATE TABLE designation (
    designation_id SERIAL PRIMARY KEY,
    title TEXT NOT NULL UNIQUE,   -- Sales Executive, Relationship Manager, Sales Head, Accountant
    department_id INTEGER NOT NULL REFERENCES department(department_id),
    seniority_level INTEGER NOT NULL DEFAULT 1
);
COMMENT ON TABLE designation IS 'Job title, scoped to a department, with a seniority rank.';

CREATE TABLE employee (
    employee_id SERIAL PRIMARY KEY,
    branch_id INTEGER NOT NULL REFERENCES branch(branch_id),
    department_id INTEGER NOT NULL REFERENCES department(department_id),
    designation_id INTEGER NOT NULL REFERENCES designation(designation_id),
    manager_id INTEGER REFERENCES employee(employee_id),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    hire_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true
);
COMMENT ON TABLE employee IS 'Staff member (sales, CRM, finance, etc.); manager_id self-references for reporting hierarchy.';

-- ---------- project & inventory masters ----------

CREATE TABLE project (
    project_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    city_id INTEGER NOT NULL REFERENCES city(city_id),
    address_line1 TEXT,
    project_type TEXT NOT NULL,        -- residential, commercial, mixed_use
    total_units INTEGER,
    launch_date DATE,
    possession_date DATE,
    status TEXT NOT NULL DEFAULT 'under_construction',  -- upcoming, under_construction, ready, completed
    rera_number TEXT
);
COMMENT ON TABLE project IS 'A real-estate development project (a "society"/complex), possibly multiple towers.';

CREATE TABLE tower (
    tower_id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES project(project_id),
    name TEXT NOT NULL,
    total_floors INTEGER
);
COMMENT ON TABLE tower IS 'A tower/block within a project.';

CREATE TABLE floor (
    floor_id SERIAL PRIMARY KEY,
    tower_id INTEGER NOT NULL REFERENCES tower(tower_id),
    floor_number INTEGER NOT NULL
);
COMMENT ON TABLE floor IS 'A floor within a tower.';

CREATE TABLE unit_type (
    unit_type_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,               -- 1BHK, 2BHK, 3BHK, Villa, Retail Shop, Office
    carpet_area_sqft NUMERIC(8,2),
    description TEXT
);
COMMENT ON TABLE unit_type IS 'Unit configuration/typology, e.g. 2BHK, Villa, Retail Shop.';

CREATE TABLE amenity (
    amenity_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,        -- Clubhouse, Swimming Pool, Gym, Covered Parking
    category TEXT
);
COMMENT ON TABLE amenity IS 'A project-level amenity/facility offered.';

CREATE TABLE charge_master (
    charge_master_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,        -- BSP, PLC, Club Membership, Car Parking, GST, Stamp Duty, Registration Fee
    charge_type TEXT NOT NULL,        -- base_price, additional_charge, tax, statutory, penalty
    is_taxable BOOLEAN NOT NULL DEFAULT true
);
COMMENT ON TABLE charge_master IS 'Master of chargeable line items that make up a unit cost sheet (price components, taxes, statutory fees).';

CREATE TABLE unit (
    unit_id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES project(project_id),
    tower_id INTEGER NOT NULL REFERENCES tower(tower_id),
    floor_id INTEGER NOT NULL REFERENCES floor(floor_id),
    unit_type_id INTEGER NOT NULL REFERENCES unit_type(unit_type_id),
    unit_number TEXT NOT NULL,
    carpet_area_sqft NUMERIC(8,2),
    super_built_up_area_sqft NUMERIC(8,2),
    base_price NUMERIC(14,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'available',  -- available, blocked, booked, sold, cancelled
    facing TEXT
);
COMMENT ON TABLE unit IS 'A single sellable inventory unit (flat/villa/shop) within a tower/floor.';

-- ---------- channel & marketing masters ----------

CREATE TABLE lead_source (
    lead_source_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE     -- Website, Walk-in, Referral, Channel Partner, Ad Campaign, Property Portal
);
COMMENT ON TABLE lead_source IS 'How a lead originated.';

CREATE TABLE channel_partner (
    channel_partner_id SERIAL PRIMARY KEY,
    firm_name TEXT NOT NULL,
    rera_registration_no TEXT,
    contact_phone TEXT,
    contact_email TEXT,
    empanelment_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT true
);
COMMENT ON TABLE channel_partner IS 'An external broker/agency firm empaneled to source bookings, earning commission.';

CREATE TABLE channel_partner_agent (
    channel_partner_agent_id SERIAL PRIMARY KEY,
    channel_partner_id INTEGER NOT NULL REFERENCES channel_partner(channel_partner_id),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    email TEXT
);
COMMENT ON TABLE channel_partner_agent IS 'An individual agent working under a channel partner firm.';

-- ---------- customer & documents ----------

CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    date_of_birth DATE,
    pan_number TEXT,
    address_line1 TEXT,
    city_id INTEGER REFERENCES city(city_id),
    occupation TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);
COMMENT ON TABLE customer IS 'A prospective or actual buyer.';

CREATE TABLE document_type (
    document_type_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,    -- PAN Card, Aadhaar, Booking Form, Agreement for Sale, Payment Receipt, Sale Deed
    category TEXT                 -- kyc, sales, finance, legal
);
COMMENT ON TABLE document_type IS 'Master of document categories tracked across the sales/finance lifecycle.';

CREATE TABLE document (
    document_id SERIAL PRIMARY KEY,
    document_type_id INTEGER NOT NULL REFERENCES document_type(document_type_id),
    customer_id INTEGER REFERENCES customer(customer_id),
    booking_id INTEGER,            -- FK to booking added below after booking table exists
    file_name TEXT,
    uploaded_at TIMESTAMP NOT NULL DEFAULT now()
);
COMMENT ON TABLE document IS 'A file tied to a customer and/or a booking (KYC doc, agreement copy, receipt scan, etc.).';

-- ---------- pre-sales: lead / opportunity ----------

CREATE TABLE lead (
    lead_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customer(customer_id),
    lead_source_id INTEGER NOT NULL REFERENCES lead_source(lead_source_id),
    channel_partner_agent_id INTEGER REFERENCES channel_partner_agent(channel_partner_agent_id),
    assigned_employee_id INTEGER REFERENCES employee(employee_id),
    project_id INTEGER REFERENCES project(project_id),
    status TEXT NOT NULL DEFAULT 'new',   -- new, contacted, qualified, lost, converted
    created_at TIMESTAMP NOT NULL DEFAULT now()
);
COMMENT ON TABLE lead IS 'An initial buyer inquiry, before it is qualified into an opportunity.';

CREATE TABLE opportunity (
    opportunity_id SERIAL PRIMARY KEY,
    lead_id INTEGER NOT NULL REFERENCES lead(lead_id),
    customer_id INTEGER NOT NULL REFERENCES customer(customer_id),
    unit_id INTEGER REFERENCES unit(unit_id),
    assigned_employee_id INTEGER NOT NULL REFERENCES employee(employee_id),
    stage TEXT NOT NULL DEFAULT 'prospecting',  -- prospecting, site_visit_scheduled, negotiation, booked, lost
    expected_value NUMERIC(14,2),
    probability_pct NUMERIC(5,2),
    expected_close_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    closed_at TIMESTAMP,
    lost_reason TEXT
);
COMMENT ON TABLE opportunity IS 'A qualified deal being actively pursued for a specific (or yet-to-be-picked) unit.';

CREATE TABLE opportunity_stage_history (
    opportunity_stage_history_id SERIAL PRIMARY KEY,
    opportunity_id INTEGER NOT NULL REFERENCES opportunity(opportunity_id),
    stage TEXT NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT now(),
    changed_by INTEGER REFERENCES employee(employee_id),
    notes TEXT
);
COMMENT ON TABLE opportunity_stage_history IS 'Audit trail of stage transitions for an opportunity (sales pipeline funnel).';

CREATE TABLE site_visit (
    site_visit_id SERIAL PRIMARY KEY,
    opportunity_id INTEGER NOT NULL REFERENCES opportunity(opportunity_id),
    scheduled_at TIMESTAMP NOT NULL,
    conducted_by INTEGER REFERENCES employee(employee_id),
    feedback TEXT,
    status TEXT NOT NULL DEFAULT 'scheduled'  -- scheduled, completed, no_show
);
COMMENT ON TABLE site_visit IS 'A scheduled/completed project site visit tied to an opportunity.';

CREATE TABLE quotation (
    quotation_id SERIAL PRIMARY KEY,
    opportunity_id INTEGER NOT NULL REFERENCES opportunity(opportunity_id),
    unit_id INTEGER NOT NULL REFERENCES unit(unit_id),
    quoted_price NUMERIC(14,2) NOT NULL,
    discount_pct NUMERIC(5,2) NOT NULL DEFAULT 0,
    valid_until DATE,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    created_by INTEGER REFERENCES employee(employee_id)
);
COMMENT ON TABLE quotation IS 'A price quote offered to a customer for a unit, with a cost breakup in quotation_item.';

CREATE TABLE quotation_item (
    quotation_item_id SERIAL PRIMARY KEY,
    quotation_id INTEGER NOT NULL REFERENCES quotation(quotation_id),
    charge_master_id INTEGER NOT NULL REFERENCES charge_master(charge_master_id),
    description TEXT,
    amount NUMERIC(14,2) NOT NULL
);
COMMENT ON TABLE quotation_item IS 'One cost-sheet line item (BSP, PLC, GST, etc.) within a quotation.';

-- ---------- booking & sales ----------

CREATE TABLE booking (
    booking_id SERIAL PRIMARY KEY,
    opportunity_id INTEGER NOT NULL UNIQUE REFERENCES opportunity(opportunity_id),
    unit_id INTEGER NOT NULL REFERENCES unit(unit_id),
    customer_id INTEGER NOT NULL REFERENCES customer(customer_id),
    channel_partner_id INTEGER REFERENCES channel_partner(channel_partner_id),
    booked_by INTEGER NOT NULL REFERENCES employee(employee_id),
    booking_date DATE NOT NULL,
    agreement_value NUMERIC(14,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',   -- active, cancelled, completed
    created_at TIMESTAMP NOT NULL DEFAULT now()
);
COMMENT ON TABLE booking IS 'A confirmed unit sale converted from an opportunity; the anchor for payment plan and collections.';

ALTER TABLE document
    ADD CONSTRAINT fk_document_booking FOREIGN KEY (booking_id) REFERENCES booking(booking_id);

CREATE TABLE booking_co_applicant (
    booking_co_applicant_id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES booking(booking_id),
    customer_id INTEGER NOT NULL REFERENCES customer(customer_id),
    relationship_to_primary TEXT,
    ownership_pct NUMERIC(5,2) NOT NULL DEFAULT 0
);
COMMENT ON TABLE booking_co_applicant IS 'A co-applicant/co-owner on a booking, alongside the primary customer.';

CREATE TABLE booking_cost_sheet_item (
    booking_cost_sheet_item_id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES booking(booking_id),
    charge_master_id INTEGER NOT NULL REFERENCES charge_master(charge_master_id),
    description TEXT,
    amount NUMERIC(14,2) NOT NULL
);
COMMENT ON TABLE booking_cost_sheet_item IS 'Final agreed cost-sheet line items for a booking (locks in the quotation breakup at sale time).';

CREATE TABLE agreement (
    agreement_id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL UNIQUE REFERENCES booking(booking_id),
    agreement_number TEXT UNIQUE NOT NULL,
    agreement_date DATE NOT NULL,
    registration_date DATE,
    registration_office TEXT,
    stamp_duty_amount NUMERIC(12,2),
    registration_fee_amount NUMERIC(12,2)
);
COMMENT ON TABLE agreement IS 'The Agreement for Sale / Sale Deed executed for a booking.';

CREATE TABLE cancellation (
    cancellation_id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL UNIQUE REFERENCES booking(booking_id),
    cancelled_at TIMESTAMP NOT NULL DEFAULT now(),
    reason TEXT,
    refund_amount NUMERIC(14,2),
    cancellation_charges NUMERIC(14,2),
    approved_by INTEGER REFERENCES employee(employee_id)
);
COMMENT ON TABLE cancellation IS 'Records a booking cancellation, the resulting refund and any cancellation charges withheld.';

-- ---------- payment plan & milestones (EMI layer) ----------

CREATE TABLE payment_plan_template (
    payment_plan_template_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,           -- '10:80:10 Construction Linked', '20:80 Down Payment', 'Time Linked 30:70'
    plan_type TEXT NOT NULL       -- construction_linked, time_linked, down_payment
);
COMMENT ON TABLE payment_plan_template IS 'A reusable payment plan definition offered to buyers.';

CREATE TABLE payment_milestone_template (
    payment_milestone_template_id SERIAL PRIMARY KEY,
    payment_plan_template_id INTEGER NOT NULL REFERENCES payment_plan_template(payment_plan_template_id),
    sequence_number INTEGER NOT NULL,
    milestone_name TEXT NOT NULL,     -- On Booking, On Foundation, On Slab Completion, On Possession
    percentage_of_agreement_value NUMERIC(5,2) NOT NULL,
    trigger_type TEXT NOT NULL,       -- booking, construction_stage, fixed_date, possession
    days_from_booking INTEGER
);
COMMENT ON TABLE payment_milestone_template IS 'One installment definition within a payment plan template (its % share and what triggers it due).';

CREATE TABLE payment_plan (
    payment_plan_id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL UNIQUE REFERENCES booking(booking_id),
    payment_plan_template_id INTEGER NOT NULL REFERENCES payment_plan_template(payment_plan_template_id),
    total_amount NUMERIC(14,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);
COMMENT ON TABLE payment_plan IS 'The payment plan template instantiated for one specific booking.';

CREATE TABLE milestone (
    milestone_id SERIAL PRIMARY KEY,
    payment_plan_id INTEGER NOT NULL REFERENCES payment_plan(payment_plan_id),
    payment_milestone_template_id INTEGER REFERENCES payment_milestone_template(payment_milestone_template_id),
    sequence_number INTEGER NOT NULL,
    milestone_name TEXT NOT NULL,
    due_amount NUMERIC(14,2) NOT NULL,
    due_date DATE,
    status TEXT NOT NULL DEFAULT 'pending',  -- pending, due, partially_paid, paid, overdue
    triggered_at TIMESTAMP,
    trigger_event_id INTEGER          -- FK to milestone_trigger_event added below after that table exists
);
COMMENT ON TABLE milestone IS 'A single EMI/installment instance due against a booking''s payment plan.';

CREATE TABLE milestone_trigger_event (
    milestone_trigger_event_id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES project(project_id),
    tower_id INTEGER REFERENCES tower(tower_id),
    construction_stage TEXT NOT NULL,   -- Foundation Completed, Slab 5 Completed, Possession Ready
    achieved_date DATE NOT NULL,
    verified_by INTEGER REFERENCES employee(employee_id)
);
COMMENT ON TABLE milestone_trigger_event IS 'A construction-stage completion event that makes construction-linked milestones fall due.';

ALTER TABLE milestone
    ADD CONSTRAINT fk_milestone_trigger_event FOREIGN KEY (trigger_event_id) REFERENCES milestone_trigger_event(milestone_trigger_event_id);

-- ---------- demand, collection & payments (cash layer) ----------

CREATE TABLE demand_letter (
    demand_letter_id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES booking(booking_id),
    milestone_id INTEGER NOT NULL REFERENCES milestone(milestone_id),
    demand_number TEXT UNIQUE NOT NULL,
    demand_date DATE NOT NULL,
    due_date DATE NOT NULL,
    total_amount NUMERIC(14,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'issued'   -- issued, paid, partially_paid, overdue
);
COMMENT ON TABLE demand_letter IS 'An invoice/demand raised against a booking for a due milestone.';

CREATE TABLE demand_letter_item (
    demand_letter_item_id SERIAL PRIMARY KEY,
    demand_letter_id INTEGER NOT NULL REFERENCES demand_letter(demand_letter_id),
    charge_master_id INTEGER NOT NULL REFERENCES charge_master(charge_master_id),
    description TEXT,
    amount NUMERIC(14,2) NOT NULL
);
COMMENT ON TABLE demand_letter_item IS 'Cost-sheet line item breakup of one demand letter.';

CREATE TABLE payment_mode (
    payment_mode_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE   -- Cash, Cheque, NEFT, RTGS, UPI, Credit Card, Home Loan Disbursement
);
COMMENT ON TABLE payment_mode IS 'How a collection was received.';

CREATE TABLE bank_account (
    bank_account_id SERIAL PRIMARY KEY,
    account_name TEXT NOT NULL,
    bank_name TEXT NOT NULL,
    account_number TEXT NOT NULL,
    ifsc_code TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true
);
COMMENT ON TABLE bank_account IS 'A developer collection bank account that receipts get deposited into.';

CREATE TABLE receipt (
    receipt_id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES booking(booking_id),
    demand_letter_id INTEGER REFERENCES demand_letter(demand_letter_id),
    receipt_number TEXT UNIQUE NOT NULL,
    receipt_date DATE NOT NULL,
    amount NUMERIC(14,2) NOT NULL,
    payment_mode_id INTEGER NOT NULL REFERENCES payment_mode(payment_mode_id),
    bank_account_id INTEGER REFERENCES bank_account(bank_account_id),
    reference_number TEXT,        -- cheque no / UTR / transaction id
    collected_by INTEGER REFERENCES employee(employee_id),
    status TEXT NOT NULL DEFAULT 'cleared'   -- cleared, bounced, pending_clearance
);
COMMENT ON TABLE receipt IS 'An actual cash/bank collection from a customer against a booking (and usually a demand letter).';

CREATE TABLE receipt_allocation (
    receipt_allocation_id SERIAL PRIMARY KEY,
    receipt_id INTEGER NOT NULL REFERENCES receipt(receipt_id),
    milestone_id INTEGER NOT NULL REFERENCES milestone(milestone_id),
    allocated_amount NUMERIC(14,2) NOT NULL
);
COMMENT ON TABLE receipt_allocation IS 'How a receipt''s amount is split across one or more milestones (a receipt can partially settle, or span, milestones).';

CREATE TABLE bank_deposit (
    bank_deposit_id SERIAL PRIMARY KEY,
    receipt_id INTEGER NOT NULL REFERENCES receipt(receipt_id),
    bank_account_id INTEGER NOT NULL REFERENCES bank_account(bank_account_id),
    deposit_date DATE NOT NULL,
    cleared_date DATE,
    status TEXT NOT NULL DEFAULT 'pending'   -- pending, cleared, bounced
);
COMMENT ON TABLE bank_deposit IS 'Bank-side deposit/clearance tracking for a receipt (reconciliation).';

CREATE TABLE refund (
    refund_id SERIAL PRIMARY KEY,
    cancellation_id INTEGER NOT NULL REFERENCES cancellation(cancellation_id),
    receipt_id INTEGER REFERENCES receipt(receipt_id),
    amount NUMERIC(14,2) NOT NULL,
    refund_date DATE,
    payment_mode_id INTEGER REFERENCES payment_mode(payment_mode_id),
    status TEXT NOT NULL DEFAULT 'initiated'   -- initiated, processed, completed
);
COMMENT ON TABLE refund IS 'A refund paid out to a customer following a booking cancellation.';

-- ---------- charges, penalties & approvals ----------

CREATE TABLE late_payment_penalty (
    late_payment_penalty_id SERIAL PRIMARY KEY,
    milestone_id INTEGER NOT NULL REFERENCES milestone(milestone_id),
    penalty_amount NUMERIC(12,2) NOT NULL,
    calculated_at TIMESTAMP NOT NULL DEFAULT now(),
    waived BOOLEAN NOT NULL DEFAULT false,
    waived_by INTEGER REFERENCES employee(employee_id),
    reason TEXT
);
COMMENT ON TABLE late_payment_penalty IS 'Interest/penalty charged for a milestone paid past its due date, optionally waived.';

CREATE TABLE discount_approval (
    discount_approval_id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES booking(booking_id),
    requested_by INTEGER NOT NULL REFERENCES employee(employee_id),
    approved_by INTEGER REFERENCES employee(employee_id),
    discount_amount NUMERIC(12,2) NOT NULL,
    reason TEXT,
    status TEXT NOT NULL DEFAULT 'pending',   -- pending, approved, rejected
    requested_at TIMESTAMP NOT NULL DEFAULT now(),
    decided_at TIMESTAMP
);
COMMENT ON TABLE discount_approval IS 'A sales discount on a booking requiring managerial sign-off.';

CREATE TABLE commission_payment (
    commission_payment_id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES booking(booking_id),
    channel_partner_id INTEGER NOT NULL REFERENCES channel_partner(channel_partner_id),
    commission_pct NUMERIC(5,2) NOT NULL,
    commission_amount NUMERIC(12,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',   -- pending, paid
    paid_date DATE
);
COMMENT ON TABLE commission_payment IS 'Brokerage payable to a channel partner for a booking they sourced.';

CREATE TABLE employee_target (
    employee_target_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employee(employee_id),
    period_month DATE NOT NULL,      -- first-of-month
    target_amount NUMERIC(14,2) NOT NULL,
    achieved_amount NUMERIC(14,2) NOT NULL DEFAULT 0
);
COMMENT ON TABLE employee_target IS 'Monthly sales target vs. achieved value for a sales employee.';

CREATE TABLE approval_workflow (
    approval_workflow_id SERIAL PRIMARY KEY,
    entity_type TEXT NOT NULL,       -- discount_approval, cancellation, refund
    entity_id INTEGER NOT NULL,
    requested_by INTEGER NOT NULL REFERENCES employee(employee_id),
    approver_id INTEGER REFERENCES employee(employee_id),
    status TEXT NOT NULL DEFAULT 'pending',   -- pending, approved, rejected
    requested_at TIMESTAMP NOT NULL DEFAULT now(),
    decided_at TIMESTAMP,
    comments TEXT
);
COMMENT ON TABLE approval_workflow IS 'Generic approval-chain record referencing another entity by type + id (polymorphic).';

CREATE TABLE audit_log (
    audit_log_id SERIAL PRIMARY KEY,
    entity_type TEXT NOT NULL,
    entity_id INTEGER NOT NULL,
    action TEXT NOT NULL,            -- insert, update, delete
    performed_by INTEGER REFERENCES employee(employee_id),
    performed_at TIMESTAMP NOT NULL DEFAULT now(),
    details TEXT
);
COMMENT ON TABLE audit_log IS 'Generic change-audit trail across entities (polymorphic, like approval_workflow).';
