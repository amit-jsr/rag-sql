# Synthetic Real-Estate Schema

A 50-table synthetic Postgres schema used for local development and demos of the
Text2SQL pipeline, standing in for the real 150+ table enterprise DB described in
`../IMPLEMENTATION_GUIDE.md` until that DB is reachable. Swapping to the real DB later is a
connection-string change only (see `backend/.env.example`) — none of the pipeline code depends
on this schema specifically.

Models a residential/commercial developer's sales + collections business: pre-sales
(lead → opportunity) → booking → milestone-based payment plan (construction-linked,
down-payment, or time-linked/EMI) → demand letter → collection (cash/bank receipt),
plus the org, project/inventory, and channel-partner masters around it.

## Domain clusters

- **org & location masters**: `country`, `state`, `city`, `branch`, `department`, `designation`, `employee`
- **project & inventory masters**: `project`, `tower`, `floor`, `unit_type`, `amenity`, `charge_master`, `unit`
- **channel & marketing masters**: `lead_source`, `channel_partner`, `channel_partner_agent`
- **customer & documents**: `customer`, `document_type`, `document`
- **pre-sales**: `lead`, `opportunity`, `opportunity_stage_history`, `site_visit`, `quotation`, `quotation_item`
- **booking & sales**: `booking`, `booking_co_applicant`, `booking_cost_sheet_item`, `agreement`, `cancellation`
- **payment plan & milestones (the "EMI" layer)**: `payment_plan_template`, `payment_milestone_template`,
  `payment_plan`, `milestone`, `milestone_trigger_event`
- **demand & collection (the "cash" layer)**: `demand_letter`, `demand_letter_item`, `payment_mode`,
  `bank_account`, `receipt`, `receipt_allocation`, `bank_deposit`, `refund`
- **charges, penalties & approvals**: `late_payment_penalty`, `discount_approval`, `commission_payment`,
  `employee_target`, `approval_workflow`, `audit_log`

## Key relationships (FK graph, abridged)

```
customer 1--n lead 1--n opportunity 1--0/1 booking
opportunity 1--n opportunity_stage_history, 1--n site_visit, 1--n quotation 1--n quotation_item
unit n--1 floor n--1 tower n--1 project
booking n--1 unit, n--1 customer, n--0/1 channel_partner
booking 1--n booking_co_applicant, 1--n booking_cost_sheet_item, 1--0/1 agreement, 1--0/1 cancellation
booking 1--1 payment_plan n--1 payment_plan_template
payment_plan 1--n milestone n--1 payment_milestone_template
milestone n--0/1 milestone_trigger_event (construction-stage trigger for CLP plans)
booking 1--n demand_letter n--1 milestone; demand_letter 1--n demand_letter_item
booking 1--n receipt n--0/1 demand_letter; receipt 1--n receipt_allocation n--1 milestone
receipt 1--0/1 bank_deposit
cancellation 1--n refund
milestone 1--n late_payment_penalty
booking 1--n discount_approval, 1--n commission_payment (n--1 channel_partner)
employee 1--n employee_target; employee 0/1--n employee (manager_id, self-referencing)
```

## Deliberate test cases baked into the seed data

- **Overdue installments** (6 `milestone` rows with `status = 'overdue'`, each with a matching
  `demand_letter.status = 'overdue'`) — use this to test business-glossary terms like "overdue
  installment" or "outstanding collection" resolving to the right status filter.
- **A partially paid milestone** (booking 2's slab-mid installment: `demand_letter` DL-0020,
  `receipt` RCPT-0020 covers only part of the due amount) — tests partial-payment aggregation.
- **A cancelled booking with refund** (booking 8 / unit A-0302): cancelled after 2 of its planned
  6 milestones were paid; `cancellation` + `refund` rows show the reconciliation (amount collected
  minus cancellation charges = refund).
- **Sequential collection stalling**: several construction-linked bookings (4, 6, 10) have an
  overdue mid-construction milestone with later milestones left `pending` (no demand issued) —
  models developers withholding the next demand until the prior one clears.
- **Multi-hop join paths**: e.g. "which channel partner sourced the booking with the largest
  pending commission" requires `commission_payment -> channel_partner`, or "total collected vs.
  agreement value per project" requires `receipt -> booking -> unit -> project`.
- **Polymorphic tables**: `approval_workflow` and `audit_log` reference other rows via
  `(entity_type, entity_id)` rather than a normal FK — good for testing whether the pipeline
  handles (or correctly avoids) this pattern.
- **Ambiguous/out-of-scope questions**: nothing in this schema tracks resale/secondary-market
  listings or competitor pricing — use questions like "what's the resale value of unit X" as a
  test that the pipeline says "I don't have that data" instead of hallucinating a query.

## Running it

`docker-compose up -d` (from repo root) mounts `../docker/postgres/init/` into
`/docker-entrypoint-initdb.d/`, which runs, in order: `01_synthetic_schema.sql` (this file's DDL,
mirrored from `00_synthetic_schema_ddl.sql`), `02_seed_data.sql` (mirrored from this directory's
`01_seed_data.sql`), then `03_pgvector_ddl.sql` (the retrieval-layer tables from the root
`IMPLEMENTATION_GUIDE.md` design). These only run on first container init against an empty data
volume — see root `README.md` for a full reset.
