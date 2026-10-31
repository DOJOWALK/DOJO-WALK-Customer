# DOJO WALK — Canonical Booking v1 JSON Schema & Validation Specification

**Status:** DRAFT — REVIEW ONLY — NOT APPROVED  
**Date:** 2026-10-30  
**Schema file:** `docs/contracts/schemas/booking-v1.schema.json`  
**Source policy:** Notion POL-006; pricing/payment references POL-011  
**Consumers:** Customer, Admin, Partner, Firebase/backend

> This is a proposed contract artifact, not a deployed schema. It does not authorize Firestore writes, Rules changes, Cloud Functions, payment/assignment implementation, migration or PR merge. The JSON Schema is a structural proposal; several product decisions remain open in the Decision Register.

## 1. Contract boundary

The schema describes a proposed canonical booking document. It does not describe the legacy document shape. Legacy records remain read through a conservative adapter and must not be rewritten just to satisfy this schema.

- Customer submits booking intent and pickup/schedule preferences.
- Backend validates service eligibility, zone, availability, quote, payment and assignment.
- Firebase/backend owns persisted authoritative lifecycle and server-generated fields.
- Apps render normalized read models and do not promote client input into trusted server state.
- No client-selected service zone; backend resolves pickup against active verified zone geometry.
- No automatic payment debit. Manual payment only where approved and enabled.

## 2. Files and identifiers

- JSON Schema draft: `docs/contracts/schemas/booking-v1.schema.json`
- Schema dialect: JSON Schema Draft 2020-12.
- Proposed canonical version: `schemaVersion: 1`.
- Canonical type IDs: `single_walk`, `temporary_booking`, `monthly_package`, `daily_continuous`.
- Date-only format: `YYYY-MM-DD`; time format: 24-hour `HH:mm`.
- Proposed service timezone: `Asia/Kolkata`; timezone policy still requires backend approval.

The schema uses `additionalProperties: false` at defined object boundaries to expose unexpected fields during contract review. Before production, the owners must decide whether extension fields require a namespaced `extensions` object or a version increment. Do not loosen this silently.

## 3. Proposed document envelope

| Field | Type | Required | Authority / meaning |
|---|---|---:|---|
| `schemaVersion` | integer, const 1 | Yes | Backend contract discriminator |
| `bookingId` | stable ID string | Yes | Server/backend-owned identity; idempotent creation design pending |
| `bookingType` | enum | Yes | One of four approved product types |
| `customerId` | ID string | Yes | Authenticated customer identity; backend validates ownership |
| `dogId` | ID string | Yes | Selected dog reference; backend validates ownership |
| `pickup` | object | Yes | Address/location evidence supplied by customer |
| `serviceZone` | object or null | No | Backend-only resolution result and catalogue version |
| `schedule` | object | Yes | Date/time preferences, validated against enabled service config |
| `lifecycle` | object | Yes | Independent booking/payment/assignment/walk state dimensions |
| `quote` | object or null | No | Server-generated quote and pricing-policy version |
| `payment` | object or null | No | Server/provider-verified manual payment state |
| `assignment` | object or null | No | Trusted backend assignment evidence |
| `createdAt`, `updatedAt` | timestamp binding | Yes | Server timestamps in storage; API serialization to be specified |

The JSON Schema currently permits timestamp strings or objects as a placeholder because Firestore Timestamp and JSON API serialization are different bindings. Backend must choose the storage/API representation and test it explicitly before implementation.

## 4. Type-specific structural rules

| Booking type | Structural requirement in schema | Additional semantic validation required |
|---|---|---|
| `single_walk` | one walk entry; one walk/day; end date null if present | Exactly one local service date and one actual walk; immediate/ASAP resolution rules |
| `temporary_booking` | start date, end date and selected dates required | Inclusive bounds; start ≤ end; every selected date inside range; selected dates unique and sorted |
| `monthly_package` | start and end dates required | Exactly 28 consecutive local calendar dates; end = start + 27 days |
| `daily_continuous` | start date, cycle policy ID and manual payment cadence required | Approved month-end anchor rule; billing due dates and cycle transitions |

The JSON Schema cannot by itself prove date ordering, date arithmetic, selected-date containment, schedule capacity, service hours or availability. These require deterministic backend/domain validators with unit and integration tests.

**Important unresolved limits:** the schema intentionally does not hard-code a maximum `walksPerDay`; that limit must come from an approved service catalogue. Walk duration is represented as 20–60 minutes based on the current product requirement, but the enabled duration options still need authoritative configuration. Do not treat schema constraints as proof that a service slot is available.

## 5. Field-level validation rules

### 5.1 IDs and ownership
- IDs are stable, non-empty identifiers; display names and translated labels are not identifiers.
- Backend must verify that the authenticated customer owns the dog and any saved pickup address.
- Client-supplied `customerId`, `bookingId`, timestamps and lifecycle fields must not be trusted merely because they validate structurally.
- ID generation/idempotency format is a separate backend decision.

### 5.2 Pickup and coordinates
- Accept address reference, formatted address and/or a coordinate pair according to the approved location-capture path.
- Latitude must be within -90..90; longitude within -180..180.
- If coordinates are present, accuracy metadata is required by this draft.
- GPS capture timestamp/source should be retained when available.
- Coordinate freshness and acceptable accuracy thresholds are unresolved and must be approved by Safety/Backend.
- Address text is not proof of geocoding or zone membership.
- Do not infer a service zone on device. Backend polygon resolution is authoritative.

### 5.3 Schedule and dates
- Use date-only values in the approved service timezone; do not derive a local date by truncating UTC timestamps.
- Time uses 24-hour `HH:mm`.
- Time slots are `morning`, `afternoon`, `evening`, `night`; these are schedule attributes, not booking types.
- Enforce uniqueness, ordering, date bounds, allowed service hours, schedule capacity and dog-count policy in semantic validators.
- Dog count and booking schedule limits must come from approved policy/service configuration, not inferred from this schema.

### 5.4 Quote and payment
- Quote amount is an integer in minor currency units; currency is INR.
- Quote must reference a pricing policy version and expiry.
- The client cannot set an authoritative quote, price or payment state.
- Payment is manual; a provider reference alone is not proof of payment.
- `paid` requires trusted backend/provider verification and a recorded verification event.
- No Auto-Pay field is defined.

### 5.5 Assignment
- Assignment data is server-owned.
- A Walker ID alone is not sufficient proof of confirmed assignment.
- Backend must record eligibility, offer/acceptance and assignment transition evidence.
- Partner must only see/act on bookings authorized for that Walker.

## 6. Lifecycle enum proposal

The schema includes candidate values for four independent state dimensions:

- Booking: request received, validating, availability confirmed, quote ready, awaiting payment, confirmed, in service, completed, cancelled, needs review, unknown.
- Payment: not started, quote pending, awaiting payment, pending verification, paid, failed, refunded, partially refunded, unknown.
- Assignment: not started, searching, offered, accepted, assigned, reassignment required, unassigned, unknown.
- Walk: not started, scheduled, Walker en route, in progress, handover pending, completed, interrupted, unknown.

These are proposed vocabulary only. The exact transition graph, terminal states, retry behavior, cancellation rules and ownership of each transition remain pending backend/product approval. A structurally valid enum value does not authorize a transition.

Unknown legacy values must be preserved in the adapter's raw evidence and surfaced as `unknown`/review; never coerce them into a positive state.

## 7. Write ownership matrix

| Data group | Customer client may propose? | Backend writes/validates? | Apps may treat as authoritative? |
|---|---:|---:|---:|
| Customer/dog references | Yes | Yes, ownership validation | Only after authorized read |
| Pickup preference | Yes | Yes, validation and zone resolution | Raw input is not zone proof |
| Schedule preference | Yes | Yes, capacity/service-hour validation | Only after server acceptance |
| Service zone | No | Yes | Yes, only from trusted backend result |
| Booking lifecycle | No | Yes | Yes, from trusted server state |
| Quote/pricing version | No | Yes | Yes, from trusted quote |
| Payment verification | No | Yes/provider verification | Yes, after verification |
| Walker assignment | No | Yes | Yes, after trusted assignment |
| Created/updated timestamps | No | Yes | Server values only |

The eventual Firestore Rules must enforce field ownership and allowed transitions. JSON Schema validation is not an authorization system and does not replace Rules or backend checks.

## 8. Cross-app behavior

- **Customer:** submit intent; show request/availability/quote/payment/confirmation/assignment as distinct states; never show zone selector or false assignment/payment claims.
- **Admin:** read operational state and review flags; do not gain assignment authority from this schema.
- **Partner:** receive authorized assigned/offer records through trusted backend access; do not infer assignment from a booking document's arbitrary fields.
- **Firebase/backend:** validate writes, resolve zone, compute quote, verify payment, assign Walker and own lifecycle transitions.

Legacy documents remain on the existing legacy path until a separately approved migration. Current Firestore Rules accept a legacy field allowlist; this proposed canonical shape is not currently proven accepted by those Rules. Do not send it to production Firestore.

## 9. Validation layers and test cases

1. **JSON Schema tests:** required fields, wrong types, invalid enum, unexpected properties, malformed dates/times, coordinate ranges.
2. **Semantic domain tests:** Monthly Package 28-day arithmetic, Temporary range containment, date uniqueness/order, timezone boundaries, Daily Continuous month-end policy after approval.
3. **Security tests:** spoofed customer/dog/address IDs, client lifecycle/quote/payment/assignment attempts, unauthorized app reads.
4. **Compatibility tests:** all synthetic legacy fixtures retain classification and raw evidence; no automatic type/payment/zone/assignment inference.
5. **Cross-app parity:** same approved fixtures yield equivalent normalized classification and lifecycle meaning in Customer, Admin and Partner.
6. **Emulator/API tests:** Rules and backend endpoints reject unauthorized or incomplete writes and accept only approved server-generated transitions.

Tests have not been run by creating this specification. Record exact command, toolchain, commit, environment and run result before marking any test passed.

## 10. Open approvals before schema freeze

See the Shared Booking Contract v1 Final Decision Register. Blocking items include:

- Formal approval of four booking types and exact customer wording.
- Daily Continuous month-end anchor policy.
- Manual billing cadence, due/overdue/grace/refund behavior.
- Exact legacy mapping and lifecycle transition tables.
- Pickup coordinate source, freshness and accuracy requirements.
- Service-zone resolution response and catalogue version.
- Timestamp serialization, ID/idempotency design and extension strategy.
- Approved schedule capacity and walks/day limits.
- Firestore/backend ownership and security validation.

## 11. Release gate

**NO-GO** for production writes, Firestore Rules changes, Functions/API implementation, migration/backfill, payment/assignment changes, production rollout or PR merge until the schema is approved, server ownership is defined, all required decisions are recorded and automated security/compatibility tests have evidence.

This file and the companion JSON Schema are drafts for review. They are not production-ready contracts.
