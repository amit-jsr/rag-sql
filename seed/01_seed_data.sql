-- ============================================================
-- Seed data for the synthetic real-estate schema (00_synthetic_schema_ddl.sql).
-- IDs rely on SERIAL auto-increment starting at 1, in the insertion order below.
-- Story: 3 projects (one under construction, one ready-but-not-fully-collected,
-- one upcoming), 10 bookings against 3 payment-plan templates (construction-linked,
-- down-payment, time-linked), with deliberate overdue/partially-paid milestones
-- (for glossary terms like "overdue installment") and one cancellation + refund.
-- "Now" for this dataset's due-date math is roughly 2024-07-28.
-- ============================================================

-- country / state / city
INSERT INTO country (name, iso_code) VALUES ('India', 'IN');

INSERT INTO state (country_id, name, code) VALUES
(1, 'Maharashtra', 'MH'),
(1, 'Karnataka', 'KA');

INSERT INTO city (state_id, name) VALUES
(1, 'Mumbai'),
(1, 'Pune'),
(2, 'Bengaluru');

-- branch
INSERT INTO branch (name, city_id, address_line1, is_active) VALUES
('Mumbai HQ', 1, 'Level 12, Skyline Corporate Park, Bandra Kurla Complex', true),
('Pune Branch', 2, 'Suite 4B, Metro Business Hub, Viman Nagar', true),
('Bengaluru Branch', 3, '2nd Floor, Tech Central Annexe, Whitefield', true);

-- department
INSERT INTO department (name) VALUES
('Sales'), ('CRM'), ('Finance'), ('Legal'), ('Construction'), ('Marketing');

-- designation
INSERT INTO designation (title, department_id, seniority_level) VALUES
('Sales Head', 1, 5),
('Relationship Manager', 1, 3),
('Sales Executive', 1, 2),
('CRM Manager', 2, 4),
('CRM Executive', 2, 2),
('Accountant', 3, 3),
('Finance Manager', 3, 4),
('Site Engineer', 5, 3),
('Legal Counsel', 4, 4),
('Marketing Executive', 6, 2);

-- employee (manager_id self-references rows above it)
INSERT INTO employee (branch_id, department_id, designation_id, manager_id, first_name, last_name, email, phone, hire_date, is_active) VALUES
(1, 1, 1, NULL, 'Arjun', 'Mehta', 'arjun.mehta@nxtrealty.example', '98200-10001', '2015-01-10', true),
(1, 1, 2, 1, 'Sneha', 'Kulkarni', 'sneha.kulkarni@nxtrealty.example', '98200-10002', '2018-04-01', true),
(1, 1, 3, 2, 'Rohan', 'Deshmukh', 'rohan.deshmukh@nxtrealty.example', '98200-10003', '2021-06-15', true),
(2, 1, 2, 1, 'Ananya', 'Rao', 'ananya.rao@nxtrealty.example', '98220-10004', '2019-02-01', true),
(2, 1, 3, 4, 'Karan', 'Joshi', 'karan.joshi@nxtrealty.example', '98220-10005', '2022-01-10', true),
(3, 1, 2, 1, 'Divya', 'Nair', 'divya.nair@nxtrealty.example', '98450-10006', '2020-07-01', true),
(1, 2, 4, NULL, 'Meera', 'Iyer', 'meera.iyer@nxtrealty.example', '98200-10007', '2017-03-01', true),
(1, 2, 5, 7, 'Vikram', 'Shetty', 'vikram.shetty@nxtrealty.example', '98200-10008', '2021-09-01', true),
(1, 3, 7, NULL, 'Pooja', 'Agarwal', 'pooja.agarwal@nxtrealty.example', '98200-10009', '2016-05-01', true),
(1, 3, 6, 9, 'Suresh', 'Pillai', 'suresh.pillai@nxtrealty.example', '98200-10010', '2019-11-01', true),
(1, 5, 8, NULL, 'Ramesh', 'Yadav', 'ramesh.yadav@nxtrealty.example', '98200-10011', '2018-01-01', true),
(1, 4, 9, NULL, 'Neha', 'Kapoor', 'neha.kapoor@nxtrealty.example', '98200-10012', '2019-08-01', true);

-- project
INSERT INTO project (name, city_id, address_line1, project_type, total_units, launch_date, possession_date, status, rera_number) VALUES
('Skyline Heights', 1, 'Off Eastern Express Highway, Mumbai', 'residential', 120, '2022-01-01', '2026-06-01', 'under_construction', 'P51700012345'),
('Green Meadows', 2, 'Viman Nagar Extension, Pune', 'residential', 80, '2021-06-01', '2024-12-01', 'ready', 'P52100054321'),
('Tech Park Central', 3, 'Whitefield Main Road, Bengaluru', 'commercial', 40, '2023-01-01', '2027-01-01', 'upcoming', 'P52200099999');

-- tower
INSERT INTO tower (project_id, name, total_floors) VALUES
(1, 'Tower A', 20),
(1, 'Tower B', 20),
(2, 'Meadow Block 1', 10),
(3, 'Tech Tower', 15);

-- floor
INSERT INTO floor (tower_id, floor_number) VALUES
(1, 3), (1, 7), (1, 12),
(2, 4), (2, 9),
(3, 2), (3, 5), (3, 8),
(4, 3), (4, 6);

-- unit_type
INSERT INTO unit_type (name, carpet_area_sqft, description) VALUES
('2BHK', 750, 'Two-bedroom apartment'),
('3BHK', 1050, 'Three-bedroom apartment'),
('1BHK', 500, 'One-bedroom apartment'),
('Villa', 2200, 'Standalone villa with private garden'),
('Office Unit', 1200, 'Commercial office floor plate');

-- amenity
INSERT INTO amenity (name, category) VALUES
('Clubhouse', 'Recreation'),
('Swimming Pool', 'Recreation'),
('Gymnasium', 'Fitness'),
('Covered Parking', 'Convenience'),
('Power Backup', 'Utility'),
('Children''s Play Area', 'Recreation');

-- charge_master
INSERT INTO charge_master (name, charge_type, is_taxable) VALUES
('Basic Sale Price (BSP)', 'base_price', true),
('Preferential Location Charge (PLC)', 'additional_charge', true),
('Club Membership Charge', 'additional_charge', true),
('Car Parking Charge', 'additional_charge', true),
('Power Backup Charge', 'additional_charge', true),
('GST', 'tax', false),
('Stamp Duty', 'statutory', false),
('Registration Fee', 'statutory', false),
('Maintenance Deposit', 'additional_charge', false),
('Legal Charges', 'additional_charge', true),
('Interest on Delayed Payment', 'penalty', false);

-- unit
INSERT INTO unit (project_id, tower_id, floor_id, unit_type_id, unit_number, carpet_area_sqft, super_built_up_area_sqft, base_price, status, facing) VALUES
(1, 1, 1, 1, 'A-0301', 750, 950, 7500000, 'sold', 'East'),
(1, 1, 2, 2, 'A-0701', 1050, 1300, 10500000, 'sold', 'North'),
(1, 1, 3, 1, 'A-1203', 750, 950, 7800000, 'booked', 'West'),
(1, 2, 4, 3, 'B-0402', 500, 650, 5200000, 'available', 'South'),
(1, 2, 5, 2, 'B-0901', 1050, 1300, 10800000, 'sold', 'East'),
(2, 3, 6, 1, 'M1-0202', 750, 940, 6200000, 'sold', 'North'),
(2, 3, 7, 4, 'M1-0501', 2200, 2600, 28000000, 'sold', 'East'),
(2, 3, 8, 1, 'M1-0803', 750, 940, 6400000, 'booked', 'West'),
(2, 3, 6, 2, 'M1-0204', 1050, 1290, 9200000, 'available', 'South'),
(3, 4, 9, 5, 'T-0301', 1200, 1450, 18000000, 'sold', 'East'),
(3, 4, 10, 5, 'T-0601', 1200, 1450, 18500000, 'available', 'North'),
(1, 1, 1, 1, 'A-0302', 750, 950, 7550000, 'cancelled', 'West'),
(2, 3, 7, 4, 'M1-0502', 2200, 2600, 28500000, 'booked', 'North'),
(3, 4, 9, 5, 'T-0302', 1200, 1450, 18200000, 'available', 'South');

-- lead_source
INSERT INTO lead_source (name) VALUES
('Website'), ('Walk-in'), ('Referral'), ('Channel Partner'), ('Property Portal'), ('Ad Campaign');

-- channel_partner
INSERT INTO channel_partner (firm_name, rera_registration_no, contact_phone, contact_email, empanelment_date, is_active) VALUES
('Horizon Realty Brokers', 'CPREG-MH-0123', '98100-20001', 'contact@horizonrealty.example', '2020-01-01', true),
('Prime Estates Associates', 'CPREG-KA-0456', '98450-20002', 'contact@primeestates.example', '2021-03-01', true);

-- channel_partner_agent
INSERT INTO channel_partner_agent (channel_partner_id, first_name, last_name, phone, email) VALUES
(1, 'Vikas', 'Shah', '98100-30001', 'vikas.shah@horizonrealty.example'),
(1, 'Anita', 'Desai', '98100-30002', 'anita.desai@horizonrealty.example'),
(2, 'Farhan', 'Sheikh', '98450-30003', 'farhan.sheikh@primeestates.example');

-- customer
INSERT INTO customer (first_name, last_name, email, phone, date_of_birth, pan_number, address_line1, city_id, occupation) VALUES
('Aditya', 'Kulkarni', 'aditya.kulkarni@example.com', '98200-40001', '1985-04-12', 'ABCDE1234F', '12 Marine Drive', 1, 'Software Engineer'),
('Priya', 'Nair', 'priya.nair@example.com', '98200-40002', '1988-07-23', 'BCDEF2345G', '45 Carter Road', 1, 'Doctor'),
('Rahul', 'Verma', 'rahul.verma@example.com', '98220-40003', '1978-11-05', 'CDEFG3456H', '78 FC Road', 2, 'Business Owner'),
('Sanjana', 'Rao', 'sanjana.rao@example.com', '98220-40004', '1990-02-18', 'DEFGH4567I', '23 Koregaon Park', 2, 'Chartered Accountant'),
('Vivek', 'Malhotra', 'vivek.malhotra@example.com', '98450-40005', '1982-09-30', 'EFGHI5678J', '9 Indiranagar 1st Stage', 3, 'IT Consultant'),
('Neha', 'Singh', 'neha.singh@example.com', '98200-40006', '1991-12-01', 'FGHIJ6789K', '56 Linking Road', 1, 'Architect'),
('Kunal', 'Bhatia', 'kunal.bhatia@example.com', '98450-40007', '1980-06-14', 'GHIJK7890L', '31 Koramangala', 3, 'Entrepreneur'),
('Ritu', 'Chawla', 'ritu.chawla@example.com', '98220-40008', '1993-03-27', 'HIJKL8901M', '18 Deccan Gymkhana', 2, 'Professor'),
('Manish', 'Agrawal', 'manish.agrawal@example.com', '98200-40009', '1975-08-19', 'IJKLM9012N', '67 Powai Vihar', 1, 'Banker'),
('Shalini', 'Menon', 'shalini.menon@example.com', '98450-40010', '1994-01-09', 'JKLMN0123O', '14 HSR Layout', 3, 'Consultant'),
('Deepak', 'Oberoi', 'deepak.oberoi@example.com', '98200-40011', '1970-05-22', 'KLMNO1234P', '3 Colaba Causeway', 1, 'Retail Owner'),
('Kavita', 'Reddy', 'kavita.reddy@example.com', '98450-40012', '1987-10-11', 'LMNOP2345Q', '22 Jayanagar 4th Block', 3, 'Doctor');

-- document_type
INSERT INTO document_type (name, category) VALUES
('PAN Card', 'kyc'),
('Aadhaar Card', 'kyc'),
('Passport', 'kyc'),
('Photograph', 'kyc'),
('Income Proof', 'kyc'),
('Booking Form', 'sales'),
('Cost Sheet', 'sales'),
('Agreement for Sale', 'legal'),
('Payment Receipt', 'finance'),
('Sale Deed', 'legal');

-- lead
INSERT INTO lead (customer_id, lead_source_id, channel_partner_agent_id, assigned_employee_id, project_id, status, created_at) VALUES
(1, 1, NULL, 3, 1, 'converted', '2024-01-05'),
(2, 3, NULL, 2, 1, 'converted', '2024-01-10'),
(3, 4, 1, 5, 2, 'converted', '2023-11-01'),
(4, 2, NULL, 4, 2, 'converted', '2023-10-15'),
(5, 5, NULL, 6, 3, 'qualified', '2024-03-01'),
(6, 1, NULL, 3, 1, 'converted', '2024-02-01'),
(7, 4, 3, 4, 2, 'converted', '2023-09-01'),
(8, 6, NULL, 5, 2, 'lost', '2024-01-20'),
(9, 3, NULL, 6, 3, 'converted', '2024-04-01'),
(10, 1, NULL, 3, 1, 'contacted', '2024-05-01'),
(11, 2, NULL, 2, 1, 'converted', '2024-01-25'),
(12, 4, 2, 6, 2, 'converted', '2023-12-01'),
(5, 5, NULL, 6, 2, 'converted', '2023-08-01');

-- opportunity
INSERT INTO opportunity (lead_id, customer_id, unit_id, assigned_employee_id, stage, expected_value, probability_pct, expected_close_date, created_at, closed_at, lost_reason) VALUES
(1, 1, 1, 3, 'booked', 7500000, 100, '2024-02-01', '2024-01-06', '2024-02-01', NULL),
(2, 2, 2, 2, 'booked', 10500000, 100, '2024-02-15', '2024-01-11', '2024-02-15', NULL),
(3, 3, 6, 5, 'booked', 6200000, 100, '2023-12-01', '2023-11-02', '2023-12-01', NULL),
(4, 4, 7, 4, 'booked', 28000000, 100, '2023-11-15', '2023-10-16', '2023-11-15', NULL),
(5, 5, 11, 6, 'negotiation', 18500000, 60, '2024-07-01', '2024-03-02', NULL, NULL),
(6, 6, 5, 3, 'booked', 10800000, 100, '2024-03-01', '2024-02-02', '2024-03-01', NULL),
(7, 7, 13, 4, 'booked', 28500000, 100, '2023-10-01', '2023-09-02', '2023-10-01', NULL),
(8, 8, 9, 5, 'lost', 9200000, 0, NULL, '2024-01-21', '2024-02-10', 'Went with a competitor project offering a larger down-payment discount'),
(9, 9, 10, 6, 'booked', 18000000, 100, '2024-05-01', '2024-04-02', '2024-05-01', NULL),
(10, 10, 4, 3, 'site_visit_scheduled', 5200000, 30, '2024-08-15', '2024-05-02', NULL, NULL),
(11, 11, 12, 2, 'booked', 7550000, 100, '2024-02-05', '2024-01-26', '2024-02-05', NULL),
(12, 12, 3, 6, 'booked', 7800000, 100, '2024-01-05', '2023-12-02', '2024-01-05', NULL),
(13, 5, 8, 6, 'booked', 6400000, 100, '2023-09-01', '2023-08-02', '2023-09-01', NULL);

-- opportunity_stage_history
INSERT INTO opportunity_stage_history (opportunity_id, stage, changed_at, changed_by, notes) VALUES
(1, 'prospecting', '2024-01-06', 3, 'Lead qualified'),
(1, 'site_visit_scheduled', '2024-01-12', 3, NULL),
(1, 'negotiation', '2024-01-20', 3, NULL),
(1, 'booked', '2024-02-01', 3, 'Booking confirmed'),
(5, 'prospecting', '2024-03-02', 6, NULL),
(5, 'site_visit_scheduled', '2024-03-10', 6, NULL),
(5, 'negotiation', '2024-04-05', 6, 'Discussing payment plan flexibility'),
(8, 'prospecting', '2024-01-21', 5, NULL),
(8, 'site_visit_scheduled', '2024-01-28', 5, NULL),
(8, 'lost', '2024-02-10', 5, 'Went with competitor project');

-- site_visit
INSERT INTO site_visit (opportunity_id, scheduled_at, conducted_by, feedback, status) VALUES
(1, '2024-01-12 10:00:00', 3, 'Liked the layout, requested cost sheet', 'completed'),
(2, '2024-01-25 11:00:00', 2, 'Interested in a higher-floor unit', 'completed'),
(3, '2023-11-10 15:00:00', 5, 'Positive, ready to proceed', 'completed'),
(4, '2023-10-20 12:00:00', 4, 'Loved the villa clubhouse view', 'completed'),
(5, '2024-03-10 10:00:00', 6, 'Requested more time to decide', 'completed'),
(7, '2023-09-15 16:00:00', 4, 'Confirmed interest immediately', 'completed'),
(8, '2024-01-28 14:00:00', 5, 'Comparing with another project', 'completed'),
(10, '2024-05-15 11:00:00', 3, NULL, 'scheduled');

-- quotation
INSERT INTO quotation (opportunity_id, unit_id, quoted_price, discount_pct, valid_until, created_at, created_by) VALUES
(1, 1, 8185500, 0, '2024-01-31', '2024-01-20', 3),
(2, 2, 11609500, 0, '2024-02-10', '2024-01-28', 2),
(3, 6, 6741000, 0, '2023-11-30', '2023-11-05', 5),
(4, 7, 30869500, 0, '2023-11-10', '2023-10-18', 4),
(5, 11, 18500000, 0, '2024-07-15', '2024-04-01', 6),
(6, 5, 11877000, 0, '2024-02-25', '2024-02-05', 3),
(7, 13, 31404500, 0, '2023-09-30', '2023-09-05', 4),
(9, 10, 19688000, 0, '2024-04-25', '2024-04-05', 6),
(10, 4, 5200000, 0, '2024-05-30', '2024-05-03', 3),
(12, 3, 8560000, 0, '2023-12-30', '2023-12-05', 6),
(11, 12, 8239000, 0, '2024-01-30', '2024-01-27', 2),
(13, 8, 6955000, 0, '2023-08-30', '2023-08-03', 6);

-- quotation_item (representative cost-sheet breakup for the first 4 quotations)
INSERT INTO quotation_item (quotation_id, charge_master_id, description, amount) VALUES
(1, 1, 'Basic Sale Price', 7500000),
(1, 2, 'Preferential Location Charge', 150000),
(1, 6, 'GST', 535500),
(2, 1, 'Basic Sale Price', 10500000),
(2, 2, 'Preferential Location Charge', 250000),
(2, 3, 'Club Membership Charge', 100000),
(2, 6, 'GST', 759500),
(3, 1, 'Basic Sale Price', 6200000),
(3, 2, 'Preferential Location Charge', 100000),
(3, 6, 'GST', 441000),
(4, 1, 'Basic Sale Price', 28000000),
(4, 2, 'Preferential Location Charge', 500000);

-- booking
INSERT INTO booking (opportunity_id, unit_id, customer_id, channel_partner_id, booked_by, booking_date, agreement_value, status) VALUES
(1, 1, 1, NULL, 3, '2024-02-01', 8185500, 'active'),
(2, 2, 2, NULL, 2, '2024-02-15', 11609500, 'active'),
(3, 6, 3, 1, 5, '2023-12-01', 6741000, 'active'),
(4, 7, 4, NULL, 4, '2023-11-15', 30869500, 'active'),
(6, 5, 6, NULL, 3, '2024-03-01', 11877000, 'active'),
(7, 13, 7, 2, 4, '2023-10-01', 31404500, 'active'),
(9, 10, 9, NULL, 6, '2024-05-01', 19688000, 'active'),
(11, 12, 11, NULL, 2, '2024-02-05', 8239000, 'cancelled'),
(12, 3, 12, 1, 6, '2024-01-05', 8560000, 'active'),
(13, 8, 5, NULL, 6, '2023-09-01', 6955000, 'active');

-- document (KYC + sales/legal docs, a mix of customer-only and booking-linked)
INSERT INTO document (document_type_id, customer_id, booking_id, file_name, uploaded_at) VALUES
(1, 2, NULL, 'priya_pan.pdf', '2024-01-20 10:00:00'),
(2, 2, NULL, 'priya_aadhaar.pdf', '2024-01-20 10:02:00'),
(6, 2, 2, 'booking2_form.pdf', '2024-02-15 11:00:00'),
(8, 2, 2, 'agreement_booking2.pdf', '2024-02-20 12:00:00'),
(9, 2, 2, 'receipt_booking2_m1.pdf', '2024-02-16 09:00:00'),
(1, 3, NULL, 'rahul_pan.pdf', '2023-11-05 10:00:00'),
(10, 3, 3, 'saledeed_booking3.pdf', '2024-01-15 12:00:00'),
(5, 4, NULL, 'sanjana_income.pdf', '2023-10-18 10:00:00'),
(8, 4, 4, 'agreement_booking4.pdf', '2023-11-25 12:00:00'),
(6, 11, 8, 'booking8_form.pdf', '2024-02-05 11:00:00');

-- booking_co_applicant
INSERT INTO booking_co_applicant (booking_id, customer_id, relationship_to_primary, ownership_pct) VALUES
(2, 9, 'spouse', 50),
(4, 10, 'spouse', 50),
(6, 12, 'business partner', 30);

-- booking_cost_sheet_item
INSERT INTO booking_cost_sheet_item (booking_id, charge_master_id, description, amount) VALUES
(1, 1, 'Basic Sale Price', 7500000),
(1, 2, 'Preferential Location Charge', 150000),
(1, 6, 'GST', 535500),
(2, 1, 'Basic Sale Price', 10500000),
(2, 2, 'Preferential Location Charge', 250000),
(2, 3, 'Club Membership Charge', 100000),
(2, 6, 'GST', 759500),
(3, 1, 'Basic Sale Price', 6200000),
(3, 2, 'Preferential Location Charge', 100000),
(3, 6, 'GST', 441000),
(4, 1, 'Basic Sale Price', 28000000),
(4, 2, 'Preferential Location Charge', 500000),
(4, 3, 'Club Membership Charge', 200000),
(4, 4, 'Car Parking Charge', 150000),
(4, 6, 'GST', 2019500),
(5, 1, 'Basic Sale Price', 10800000),
(5, 2, 'Preferential Location Charge', 300000),
(5, 6, 'GST', 777000),
(6, 1, 'Basic Sale Price', 28500000),
(6, 2, 'Preferential Location Charge', 500000),
(6, 3, 'Club Membership Charge', 200000),
(6, 4, 'Car Parking Charge', 150000),
(6, 6, 'GST', 2054500),
(7, 1, 'Basic Sale Price', 18000000),
(7, 2, 'Preferential Location Charge', 400000),
(7, 6, 'GST', 1288000),
(8, 1, 'Basic Sale Price', 7550000),
(8, 2, 'Preferential Location Charge', 150000),
(8, 6, 'GST', 539000),
(9, 1, 'Basic Sale Price', 7800000),
(9, 2, 'Preferential Location Charge', 200000),
(9, 6, 'GST', 560000),
(10, 1, 'Basic Sale Price', 6400000),
(10, 2, 'Preferential Location Charge', 100000),
(10, 6, 'GST', 455000);

-- agreement (registered for the more advanced bookings; a couple still pending registration)
INSERT INTO agreement (booking_id, agreement_number, agreement_date, registration_date, registration_office, stamp_duty_amount, registration_fee_amount) VALUES
(2, 'AGR-2024-0002', '2024-02-20', '2024-03-05', 'Sub-Registrar Mumbai City-3', 580475, 30000),
(3, 'AGR-2023-0003', '2023-12-10', '2024-01-15', 'Sub-Registrar Pune-2', 337050, 30000),
(4, 'AGR-2023-0004', '2023-11-25', NULL, NULL, NULL, NULL),
(6, 'AGR-2023-0006', '2023-10-10', '2023-12-01', 'Sub-Registrar Bengaluru East', 1570225, 30000),
(7, 'AGR-2024-0007', '2024-05-10', NULL, NULL, NULL, NULL),
(9, 'AGR-2024-0009', '2024-01-15', '2024-02-20', 'Sub-Registrar Mumbai City-3', 428000, 30000),
(10, 'AGR-2023-0010', '2023-09-10', '2023-10-25', 'Sub-Registrar Pune-2', 347500, 30000);

-- payment_plan_template
INSERT INTO payment_plan_template (name, plan_type) VALUES
('10:80:10 Construction Linked', 'construction_linked'),
('20:80 Down Payment', 'down_payment'),
('Time Linked 30:70', 'time_linked');

-- payment_milestone_template
INSERT INTO payment_milestone_template (payment_plan_template_id, sequence_number, milestone_name, percentage_of_agreement_value, trigger_type, days_from_booking) VALUES
(1, 1, 'On Booking', 10, 'booking', 0),
(1, 2, 'On Foundation Completion', 15, 'construction_stage', NULL),
(1, 3, 'On Slab Completion (Mid)', 25, 'construction_stage', NULL),
(1, 4, 'On Slab Completion (Top)', 25, 'construction_stage', NULL),
(1, 5, 'On Finishing', 15, 'construction_stage', NULL),
(1, 6, 'On Possession', 10, 'possession', NULL),
(2, 1, 'On Booking', 20, 'booking', 0),
(2, 2, 'Within 30 Days of Booking', 80, 'fixed_date', 30),
(3, 1, 'On Booking', 30, 'booking', 0),
(3, 2, 'Within 90 Days of Booking', 40, 'fixed_date', 90),
(3, 3, 'Within 180 Days of Booking', 30, 'fixed_date', 180);

-- payment_plan (one per booking; row order matches booking id 1-10)
INSERT INTO payment_plan (booking_id, payment_plan_template_id, total_amount) VALUES
(1, 1, 8185500),
(2, 1, 11609500),
(3, 2, 6741000),
(4, 1, 30869500),
(5, 3, 11877000),
(6, 1, 31404500),
(7, 2, 19688000),
(8, 1, 8239000),
(9, 3, 8560000),
(10, 1, 6955000);

-- milestone_trigger_event
INSERT INTO milestone_trigger_event (project_id, tower_id, construction_stage, achieved_date, verified_by) VALUES
(1, 1, 'Foundation Completed', '2024-03-25', 11),
(1, 1, 'Slab 5 Completed', '2024-07-20', 11),
(2, 3, 'Foundation Completed', '2022-06-01', 11),
(2, 3, 'Slab Completed (Mid)', '2022-10-01', 11),
(2, 3, 'Slab Completed (Top)', '2023-02-01', 11);

-- milestone
-- payment_plan 1 (booking 1, CLP, total 8,185,500)
INSERT INTO milestone (payment_plan_id, payment_milestone_template_id, sequence_number, milestone_name, due_amount, due_date, status, triggered_at, trigger_event_id) VALUES
(1, 1, 1, 'On Booking', 818550, '2024-02-01', 'paid', '2024-02-01', NULL),
(1, 2, 2, 'On Foundation Completion', 1227825, '2024-04-01', 'paid', '2024-03-25', 1),
(1, 3, 3, 'On Slab Completion (Mid)', 2046375, '2024-08-01', 'due', '2024-07-20', 2),
(1, 4, 4, 'On Slab Completion (Top)', 2046375, NULL, 'pending', NULL, NULL),
(1, 5, 5, 'On Finishing', 1227825, NULL, 'pending', NULL, NULL),
(1, 6, 6, 'On Possession', 818550, NULL, 'pending', NULL, NULL),
-- payment_plan 2 (booking 2, CLP, total 11,609,500)
(2, 1, 1, 'On Booking', 1160950, '2024-02-15', 'paid', '2024-02-15', NULL),
(2, 2, 2, 'On Foundation Completion', 1741425, '2024-04-01', 'paid', '2024-03-25', 1),
(2, 3, 3, 'On Slab Completion (Mid)', 2902375, '2024-08-01', 'partially_paid', '2024-07-20', 2),
(2, 4, 4, 'On Slab Completion (Top)', 2902375, NULL, 'pending', NULL, NULL),
(2, 5, 5, 'On Finishing', 1741425, NULL, 'pending', NULL, NULL),
(2, 6, 6, 'On Possession', 1160950, NULL, 'pending', NULL, NULL),
-- payment_plan 3 (booking 3, Down Payment, total 6,741,000) - fully paid
(3, 7, 1, 'On Booking', 1348200, '2023-12-01', 'paid', '2023-12-01', NULL),
(3, 8, 2, 'Within 30 Days of Booking', 5392800, '2023-12-31', 'paid', '2023-12-30', NULL),
-- payment_plan 4 (booking 4, CLP, total 30,869,500)
(4, 1, 1, 'On Booking', 3086950, '2023-11-15', 'paid', '2023-11-15', NULL),
(4, 2, 2, 'On Foundation Completion', 4630425, '2023-12-15', 'paid', '2022-06-01', 3),
(4, 3, 3, 'On Slab Completion (Mid)', 7717375, '2024-01-15', 'paid', '2022-10-01', 4),
(4, 4, 4, 'On Slab Completion (Top)', 7717375, '2024-03-01', 'overdue', '2023-02-01', 5),
(4, 5, 5, 'On Finishing', 4630425, NULL, 'pending', NULL, NULL),
(4, 6, 6, 'On Possession', 3086950, NULL, 'pending', NULL, NULL),
-- payment_plan 5 (booking 5, Time Linked, total 11,877,000)
(5, 9, 1, 'On Booking', 3563100, '2024-03-01', 'paid', '2024-03-01', NULL),
(5, 10, 2, 'Within 90 Days of Booking', 4750800, '2024-05-30', 'overdue', NULL, NULL),
(5, 11, 3, 'Within 180 Days of Booking', 3563100, '2024-08-28', 'pending', NULL, NULL),
-- payment_plan 6 (booking 6, CLP, total 31,404,500)
(6, 1, 1, 'On Booking', 3140450, '2023-10-01', 'paid', '2023-10-01', NULL),
(6, 2, 2, 'On Foundation Completion', 4710675, '2023-11-01', 'paid', '2022-06-01', 3),
(6, 3, 3, 'On Slab Completion (Mid)', 7851125, '2023-12-01', 'overdue', '2022-10-01', 4),
(6, 4, 4, 'On Slab Completion (Top)', 7851125, NULL, 'pending', NULL, NULL),
(6, 5, 5, 'On Finishing', 4710675, NULL, 'pending', NULL, NULL),
(6, 6, 6, 'On Possession', 3140450, NULL, 'pending', NULL, NULL),
-- payment_plan 7 (booking 7, Down Payment, total 19,688,000)
(7, 7, 1, 'On Booking', 3937600, '2024-05-01', 'paid', '2024-05-01', NULL),
(7, 8, 2, 'Within 30 Days of Booking', 15750400, '2024-05-31', 'overdue', NULL, NULL),
-- payment_plan 8 (booking 8, CLP, total 8,239,000) - cancelled after 2 installments
(8, 1, 1, 'On Booking', 823900, '2024-02-05', 'paid', '2024-02-05', NULL),
(8, 2, 2, 'On Foundation Completion', 1235850, '2024-04-01', 'paid', '2024-03-25', 1),
(8, 3, 3, 'On Slab Completion (Mid)', 2059750, NULL, 'pending', NULL, NULL),
-- payment_plan 9 (booking 9, Time Linked, total 8,560,000)
(9, 9, 1, 'On Booking', 2568000, '2024-01-05', 'paid', '2024-01-05', NULL),
(9, 10, 2, 'Within 90 Days of Booking', 3424000, '2024-04-04', 'paid', '2024-04-03', NULL),
(9, 11, 3, 'Within 180 Days of Booking', 2568000, '2024-07-03', 'overdue', NULL, NULL),
-- payment_plan 10 (booking 10, CLP, total 6,955,000)
(10, 1, 1, 'On Booking', 695500, '2023-09-01', 'paid', '2023-09-01', NULL),
(10, 2, 2, 'On Foundation Completion', 1043250, '2023-10-01', 'paid', '2022-06-01', 3),
(10, 3, 3, 'On Slab Completion (Mid)', 1738750, '2023-11-01', 'overdue', '2022-10-01', 4),
(10, 4, 4, 'On Slab Completion (Top)', 1738750, NULL, 'pending', NULL, NULL),
(10, 5, 5, 'On Finishing', 1043250, NULL, 'pending', NULL, NULL),
(10, 6, 6, 'On Possession', 695500, NULL, 'pending', NULL, NULL);

-- demand_letter (milestone_id order matches the milestone insert order above, 1-43)
INSERT INTO demand_letter (booking_id, milestone_id, demand_number, demand_date, due_date, total_amount, status) VALUES
(1, 1, 'DL-0001', '2024-01-25', '2024-02-01', 818550, 'paid'),
(1, 2, 'DL-0002', '2024-03-25', '2024-04-01', 1227825, 'paid'),
(2, 7, 'DL-0003', '2024-02-08', '2024-02-15', 1160950, 'paid'),
(2, 8, 'DL-0004', '2024-03-25', '2024-04-01', 1741425, 'paid'),
(3, 13, 'DL-0005', '2023-11-24', '2023-12-01', 1348200, 'paid'),
(3, 14, 'DL-0006', '2023-12-24', '2023-12-31', 5392800, 'paid'),
(4, 15, 'DL-0007', '2023-11-08', '2023-11-15', 3086950, 'paid'),
(4, 16, 'DL-0008', '2023-12-08', '2023-12-15', 4630425, 'paid'),
(4, 17, 'DL-0009', '2024-01-08', '2024-01-15', 7717375, 'paid'),
(5, 21, 'DL-0010', '2024-02-22', '2024-03-01', 3563100, 'paid'),
(6, 24, 'DL-0011', '2023-09-24', '2023-10-01', 3140450, 'paid'),
(6, 25, 'DL-0012', '2023-10-25', '2023-11-01', 4710675, 'paid'),
(7, 30, 'DL-0013', '2024-04-24', '2024-05-01', 3937600, 'paid'),
(8, 32, 'DL-0014', '2024-01-29', '2024-02-05', 823900, 'paid'),
(8, 33, 'DL-0015', '2024-03-25', '2024-04-01', 1235850, 'paid'),
(9, 35, 'DL-0016', '2023-12-29', '2024-01-05', 2568000, 'paid'),
(9, 36, 'DL-0017', '2024-03-28', '2024-04-04', 3424000, 'paid'),
(10, 38, 'DL-0018', '2023-08-25', '2023-09-01', 695500, 'paid'),
(10, 39, 'DL-0019', '2023-09-24', '2023-10-01', 1043250, 'paid'),
(2, 9, 'DL-0020', '2024-07-25', '2024-08-01', 2902375, 'partially_paid'),
(5, 22, 'DL-0021', '2024-05-23', '2024-05-30', 4750800, 'overdue'),
(7, 31, 'DL-0022', '2024-05-24', '2024-05-31', 15750400, 'overdue'),
(4, 18, 'DL-0023', '2024-02-23', '2024-03-01', 7717375, 'overdue'),
(6, 26, 'DL-0024', '2023-11-24', '2023-12-01', 7851125, 'overdue'),
(10, 40, 'DL-0025', '2023-10-25', '2023-11-01', 1738750, 'overdue'),
(9, 37, 'DL-0026', '2024-06-26', '2024-07-03', 2568000, 'overdue'),
(1, 3, 'DL-0027', '2024-07-25', '2024-08-01', 2046375, 'due');

-- demand_letter_item (one BSP-tagged line per demand letter, id order 1-27)
INSERT INTO demand_letter_item (demand_letter_id, charge_master_id, description, amount)
SELECT demand_letter_id, 1, 'Milestone installment as per payment plan', total_amount FROM demand_letter ORDER BY demand_letter_id;

-- payment_mode
INSERT INTO payment_mode (name) VALUES
('Cash'), ('Cheque'), ('NEFT'), ('RTGS'), ('UPI'), ('Home Loan Disbursement');

-- bank_account
INSERT INTO bank_account (account_name, bank_name, account_number, ifsc_code, is_active) VALUES
('NXT Realty Collection Account - HDFC', 'HDFC Bank', '00112233445566', 'HDFC0000123', true),
('NXT Realty Collection Account - ICICI', 'ICICI Bank', '99887766554433', 'ICIC0000456', true);

-- receipt (against the 19 paid demand letters, plus one partial against DL-0020)
INSERT INTO receipt (booking_id, demand_letter_id, receipt_number, receipt_date, amount, payment_mode_id, bank_account_id, reference_number, collected_by, status) VALUES
(1, 1, 'RCPT-0001', '2024-02-01', 818550, 1, NULL, NULL, 10, 'cleared'),
(1, 2, 'RCPT-0002', '2024-04-02', 1227825, 2, 1, 'CHQ-100234', 10, 'cleared'),
(2, 3, 'RCPT-0003', '2024-02-16', 1160950, 3, 1, 'UTR-2402160001', 10, 'cleared'),
(2, 4, 'RCPT-0004', '2024-04-01', 1741425, 3, 1, 'UTR-2404010002', 10, 'cleared'),
(3, 5, 'RCPT-0005', '2023-12-01', 1348200, 2, 2, 'CHQ-200011', 10, 'cleared'),
(3, 6, 'RCPT-0006', '2023-12-30', 5392800, 6, 2, 'HL-DISB-3301', 10, 'cleared'),
(4, 7, 'RCPT-0007', '2023-11-14', 3086950, 2, 1, 'CHQ-100987', 9, 'cleared'),
(4, 8, 'RCPT-0008', '2023-12-14', 4630425, 6, 1, 'HL-DISB-4402', 9, 'cleared'),
(4, 9, 'RCPT-0009', '2024-01-16', 7717375, 6, 1, 'HL-DISB-4403', 9, 'cleared'),
(5, 10, 'RCPT-0010', '2024-03-01', 3563100, 3, 1, 'UTR-2403010005', 10, 'cleared'),
(6, 11, 'RCPT-0011', '2023-10-02', 3140450, 2, 2, 'CHQ-200077', 10, 'cleared'),
(6, 12, 'RCPT-0012', '2023-11-03', 4710675, 6, 2, 'HL-DISB-6602', 10, 'cleared'),
(7, 13, 'RCPT-0013', '2024-05-02', 3937600, 5, 1, 'UPI-24050200X', 9, 'cleared'),
(8, 14, 'RCPT-0014', '2024-02-06', 823900, 1, NULL, NULL, 10, 'cleared'),
(8, 15, 'RCPT-0015', '2024-04-02', 1235850, 2, 1, 'CHQ-100555', 10, 'cleared'),
(9, 16, 'RCPT-0016', '2024-01-06', 2568000, 3, 2, 'UTR-2401060007', 10, 'cleared'),
(9, 17, 'RCPT-0017', '2024-04-05', 3424000, 3, 2, 'UTR-2404050008', 10, 'cleared'),
(10, 18, 'RCPT-0018', '2023-09-02', 695500, 2, 1, 'CHQ-100011', 9, 'cleared'),
(10, 19, 'RCPT-0019', '2023-10-02', 1043250, 2, 1, 'CHQ-100056', 9, 'pending_clearance'),
(2, 20, 'RCPT-0020', '2024-07-28', 1500000, 3, 1, 'UTR-2407280009', 10, 'cleared');

-- receipt_allocation (1:1 with the receipts above; RCPT-0020 is a partial allocation against milestone 9)
INSERT INTO receipt_allocation (receipt_id, milestone_id, allocated_amount) VALUES
(1, 1, 818550),
(2, 2, 1227825),
(3, 7, 1160950),
(4, 8, 1741425),
(5, 13, 1348200),
(6, 14, 5392800),
(7, 15, 3086950),
(8, 16, 4630425),
(9, 17, 7717375),
(10, 21, 3563100),
(11, 24, 3140450),
(12, 25, 4710675),
(13, 30, 3937600),
(14, 32, 823900),
(15, 33, 1235850),
(16, 35, 2568000),
(17, 36, 3424000),
(18, 38, 695500),
(19, 39, 1043250),
(20, 9, 1500000);

-- bank_deposit (for all non-cash receipts, i.e. all except RCPT-0001 and RCPT-0014)
INSERT INTO bank_deposit (receipt_id, bank_account_id, deposit_date, cleared_date, status) VALUES
(2, 1, '2024-04-02', '2024-04-04', 'cleared'),
(3, 1, '2024-02-16', '2024-02-18', 'cleared'),
(4, 1, '2024-04-01', '2024-04-03', 'cleared'),
(5, 2, '2023-12-01', '2023-12-04', 'cleared'),
(6, 2, '2023-12-30', '2024-01-02', 'cleared'),
(7, 1, '2023-11-14', '2023-11-16', 'cleared'),
(8, 1, '2023-12-14', '2023-12-17', 'cleared'),
(9, 1, '2024-01-16', '2024-01-18', 'cleared'),
(10, 1, '2024-03-01', '2024-03-04', 'cleared'),
(11, 2, '2023-10-02', '2023-10-04', 'cleared'),
(12, 2, '2023-11-03', '2023-11-06', 'cleared'),
(13, 1, '2024-05-02', '2024-05-02', 'cleared'),
(15, 1, '2024-04-02', '2024-04-04', 'cleared'),
(16, 2, '2024-01-06', '2024-01-09', 'cleared'),
(17, 2, '2024-04-05', '2024-04-08', 'cleared'),
(18, 1, '2023-09-02', '2023-09-05', 'cleared'),
(19, 1, '2023-10-02', NULL, 'pending'),
(20, 1, '2024-07-28', NULL, 'pending');

-- cancellation
INSERT INTO cancellation (booking_id, cancelled_at, reason, refund_amount, cancellation_charges, approved_by) VALUES
(8, '2024-04-01', 'Customer financial constraints', 1859750, 200000, 1);

-- refund
INSERT INTO refund (cancellation_id, receipt_id, amount, refund_date, payment_mode_id, status) VALUES
(1, NULL, 1859750, '2024-04-15', 3, 'completed');

-- late_payment_penalty (against the overdue milestones)
INSERT INTO late_payment_penalty (milestone_id, penalty_amount, calculated_at, waived, waived_by, reason) VALUES
(22, 95016, '2024-06-05', false, NULL, 'Interest per agreement clause 5.2'),
(31, 315008, '2024-06-05', true, 1, 'Waived as goodwill gesture - customer facing home loan disbursement delay'),
(18, 154348, '2024-03-15', false, NULL, 'Interest per agreement clause 5.2'),
(26, 157023, '2023-12-15', false, NULL, 'Interest per agreement clause 5.2'),
(40, 34775, '2023-11-15', false, NULL, 'Interest per agreement clause 5.2'),
(37, 51360, '2024-07-10', false, NULL, 'Interest per agreement clause 5.2');

-- discount_approval
INSERT INTO discount_approval (booking_id, requested_by, approved_by, discount_amount, reason, status, requested_at, decided_at) VALUES
(2, 2, 1, 90500, 'Loyalty discount for repeat customer referral', 'approved', '2024-02-10', '2024-02-12'),
(9, 6, 1, 50000, 'Corporate tie-up discount', 'approved', '2024-01-02', '2024-01-03'),
(10, 6, NULL, 75000, 'Requested cash discount for early full payment', 'rejected', '2023-08-25', '2023-08-27');

-- commission_payment
INSERT INTO commission_payment (booking_id, channel_partner_id, commission_pct, commission_amount, status, paid_date) VALUES
(3, 1, 2.0, 134820, 'paid', '2024-01-15'),
(6, 2, 1.5, 471068, 'paid', '2023-11-01'),
(9, 1, 2.0, 171200, 'pending', NULL);

-- employee_target
INSERT INTO employee_target (employee_id, period_month, target_amount, achieved_amount) VALUES
(2, '2024-01-01', 20000000, 11609500),
(2, '2024-02-01', 20000000, 8185500),
(4, '2023-11-01', 25000000, 30869500),
(4, '2024-05-01', 20000000, 0),
(6, '2023-10-01', 30000000, 31404500),
(6, '2024-01-01', 15000000, 8560000);

-- approval_workflow (polymorphic: mirrors the discount_approval and cancellation decisions above)
INSERT INTO approval_workflow (entity_type, entity_id, requested_by, approver_id, status, requested_at, decided_at, comments) VALUES
('discount_approval', 1, 2, 1, 'approved', '2024-02-10', '2024-02-12', 'Approved within RM discretion limit'),
('discount_approval', 3, 6, 1, 'rejected', '2023-08-25', '2023-08-27', 'Exceeds branch discount policy'),
('cancellation', 1, 2, 1, 'approved', '2024-03-28', '2024-04-01', 'Refund terms confirmed per policy'),
('discount_approval', 2, 6, 1, 'approved', '2024-01-02', '2024-01-03', NULL);

-- audit_log (polymorphic change trail across a few entities)
INSERT INTO audit_log (entity_type, entity_id, action, performed_by, performed_at, details) VALUES
('booking', 1, 'insert', 3, '2024-02-01 10:05:00', 'Booking created for unit A-0301'),
('booking', 8, 'update', 2, '2024-04-01 09:00:00', 'Status changed to cancelled'),
('receipt', 6, 'insert', 10, '2023-12-30 15:00:00', 'Home loan disbursement recorded'),
('unit', 12, 'update', 2, '2024-04-01 09:05:00', 'Status changed to cancelled after booking cancellation'),
('discount_approval', 3, 'update', 1, '2023-08-27 12:00:00', 'Discount request rejected'),
('milestone', 9, 'update', 9, '2024-07-28 16:00:00', 'Partial payment recorded against milestone');
