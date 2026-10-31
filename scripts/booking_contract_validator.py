#!/usr/bin/env python3
"""Executable draft validator for the DOJO WALK canonical booking v1 contract.

This validates JSON Schema structure and a small set of explicit semantic rules.
It does NOT validate authorization, Firestore Rules, provider payment, availability,
service-zone geometry, assignment, or app integration.
"""
from __future__ import annotations

import copy
import json
import sys
from pathlib import Path

try:
    from jsonschema import Draft202012Validator
except ImportError:
    print("DEPENDENCY_MISSING: install requirements-booking-contract.txt", file=sys.stderr)
    raise

ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = ROOT / "docs/contracts/schemas/booking-v1.schema.json"
FIXTURE_PATH = ROOT / "docs/contracts/fixtures/booking-v1-validation-fixtures-draft.json"


def load_json(path: Path):
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def mutate(case_id: str, source: dict) -> dict:
    value = copy.deepcopy(source)
    schedule = value.get("schedule", {})
    pickup = value.get("pickup", {})
    if case_id == "N01":
        value["schemaVersion"] = 2
    elif case_id == "N02":
        value["bookingType"] = "weekly_plan"
    elif case_id == "N03":
        value.pop("customerId", None)
    elif case_id == "N04":
        pickup["latitude"] = 190
        pickup["longitude"] = 77.4
        pickup["locationAccuracyMeters"] = 10
    elif case_id == "N05":
        pickup["latitude"] = 28.6
        pickup["longitude"] = 77.4
        pickup.pop("locationAccuracyMeters", None)
    elif case_id == "N06":
        schedule["walks"][0]["preferredTime"] = "6:30 AM"
    elif case_id == "N07":
        schedule["walks"][0]["durationMinutes"] = 15
    elif case_id == "N08":
        value["clientCalculatedPrice"] = 199
    elif case_id == "N09":
        value["bookingType"] = "temporary_booking"
        schedule.pop("endDate", None)
    elif case_id == "N10":
        value["bookingType"] = "monthly_package"
        schedule.pop("endDate", None)
    elif case_id == "N11":
        value["bookingType"] = "daily_continuous"
        schedule.pop("cyclePolicyId", None)
        schedule.pop("paymentCadence", None)
    elif case_id == "N12":
        value["bookingType"] = "daily_continuous"
        schedule["cyclePolicyId"] = "PENDING_APPROVAL"
        schedule["paymentCadence"] = "auto_pay"
    elif case_id == "N15":
        value["bookingType"] = "temporary_booking"
        schedule["startDate"] = "2026-11-02"
        schedule["endDate"] = "2026-11-06"
        schedule["selectedDates"] = ["2026-11-04", "2026-11-04"]
    else:
        raise ValueError(f"No schema mutation defined for {case_id}")
    return value


def semantic_errors(booking: dict) -> list[str]:
    """Only deterministic rules that are settled enough for this draft."""
    errors = []
    booking_type = booking.get("bookingType")
    schedule = booking.get("schedule", {})
    if booking_type == "temporary_booking":
        start = schedule.get("startDate")
        end = schedule.get("endDate")
        dates = schedule.get("selectedDates", [])
        if start and end and start > end:
            errors.append("temporary_range_reversed")
        if start and end and any(date < start or date > end for date in dates):
            errors.append("temporary_selected_date_outside_range")
    if booking_type == "monthly_package":
        start = schedule.get("startDate")
        end = schedule.get("endDate")
        if start and end:
            from datetime import date, timedelta

            start_date = date.fromisoformat(start)
            next_month_year = start_date.year + (1 if start_date.month == 12 else 0)
            next_month = 1 if start_date.month == 12 else start_date.month + 1
            try:
                same_day_next_month = date(
                    next_month_year, next_month, start_date.day
                )
            except ValueError:
                errors.append("monthly_month_end_policy_required")
            else:
                expected = (same_day_next_month - timedelta(days=1)).isoformat()
                if end != expected:
                    errors.append("monthly_end_date_not_calendar_monthly")
    return errors


def main() -> int:
    schema = load_json(SCHEMA_PATH)
    fixtures = load_json(FIXTURE_PATH)
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema)
    passed = failed = blocked = 0

    for name, booking in fixtures["positive"].items():
        errors = sorted(validator.iter_errors(booking), key=lambda e: list(e.path))
        if errors:
            failed += 1
            print(f"FAIL POSITIVE {name}: " + "; ".join(e.message for e in errors))
        else:
            passed += 1
            print(f"PASS POSITIVE {name}")

    schema_cases = {"N01", "N02", "N03", "N04", "N05", "N06", "N07", "N08",
                    "N09", "N10", "N11", "N12", "N15"}
    positive_base = fixtures["positive"]["single_walk"]
    for case in fixtures["negative"]:
        case_id = case["id"]
        if case_id in schema_cases:
            changed = mutate(case_id, positive_base)
            # Use a type-appropriate base where the case requires type-specific fields.
            if case_id in {"N09", "N10", "N11", "N12", "N15"}:
                changed = mutate(case_id, fixtures["positive"]["temporary_booking"]
                                 if case_id in {"N09", "N15"}
                                 else fixtures["positive"]["monthly_package"])
            errors = list(validator.iter_errors(changed))
            if errors:
                passed += 1
                print(f"PASS {case_id} rejected by JSON Schema")
            else:
                failed += 1
                print(f"FAIL {case_id}: invalid mutation was accepted by JSON Schema")
        elif case_id in {"N13", "N14"}:
            if case_id == "N13":
                changed = copy.deepcopy(fixtures["positive"]["temporary_booking"])
                changed["schedule"]["selectedDates"] = ["2026-11-07"]
                expected = "temporary_selected_date_outside_range"
            else:
                changed = copy.deepcopy(fixtures["positive"]["monthly_package"])
                changed["schedule"]["endDate"] = "2026-12-04"
                expected = "monthly_end_date_not_calendar_monthly"
            found = semantic_errors(changed)
            if expected in found:
                passed += 1
                print(f"PASS {case_id} rejected by semantic validator")
            else:
                failed += 1
                print(f"FAIL {case_id}: expected semantic error {expected}, got {found}")
        else:
            blocked += 1
            print(f"BLOCKED {case_id}: requires backend/security/Firebase policy evidence")

    print(f"SUMMARY passed={passed} failed={failed} blocked={blocked}")
    print("SCOPE: schema + limited semantic checks only; security/backend tests are blocked, not passed.")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
