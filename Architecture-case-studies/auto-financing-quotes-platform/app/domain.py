"""Integer cents and illustrative pricing; not underwriting."""
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
import hashlib
import json

PRICING_VERSION = "DEMO-2026-01"
APR_BY_TIER = {"excellent": "5.49", "good": "7.49", "fair": "10.99"}


class ValidationError(ValueError):
    pass


def cents(value):
    try:
        result = Decimal(str(value))
        if not result.is_finite() or result < 0 or result > 500000:
            raise ValidationError("Amount must be between 0 and 500,000.")
        return int((result * 100).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
    except (InvalidOperation, TypeError, ValueError) as error:
        raise ValidationError("Enter a valid monetary amount.") from error


def calculate(payload):
    price = cents(payload.get("vehicle_price", ""))
    down = cents(payload.get("down_payment", ""))
    try:
        raw_term = Decimal(str(payload.get("term_months", "")))
        term = int(raw_term)
        if raw_term != term or term not in (24, 36, 48, 60, 72, 84):
            raise ValueError()
    except (ValueError, InvalidOperation, OverflowError):
        raise ValidationError("Choose a supported loan term.")
    tier = payload.get("credit_tier", "good")
    if tier not in APR_BY_TIER:
        raise ValidationError("Choose a supported illustrative credit tier.")
    if price < 100000 or down >= price:
        raise ValidationError("Vehicle price must be at least $1,000; down payment must be less than price.")
    vehicle = str(payload.get("vehicle", "2026 vehicle")).strip()
    if not vehicle or len(vehicle) > 100:
        raise ValidationError("Vehicle description must contain 1â€“100 characters.")
    principal = price - down
    apr = Decimal(APR_BY_TIER[tier])
    rate = apr / 1200
    payment = int((Decimal(principal) * rate / (1 - (1 + rate) ** -term)).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
    return {"vehicle": vehicle, "vehicle_price_cents": price, "down_payment_cents": down,
            "principal_cents": principal, "term_months": term, "credit_tier": tier,
            "apr": str(apr), "monthly_payment_cents": payment, "pricing_version": PRICING_VERSION}


def fingerprint(quote):
    return hashlib.sha256(json.dumps(quote, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
