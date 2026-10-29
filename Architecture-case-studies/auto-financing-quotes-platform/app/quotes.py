import json
import time
import uuid
from .db import connect
from .domain import calculate, fingerprint, ValidationError


def public(row):
    return {**json.loads(row["data_json"]), "id": row["id"], "created_at": row["created_at"], "expires_at": row["expires_at"]}


def save(payload, owner, key):
    if not isinstance(key, str) or not 8 <= len(key) <= 128:
        raise ValidationError("An Idempotency-Key header of 8â€“128 characters is required.")
    data = calculate(payload)
    digest = fingerprint(data)
    now = time.time()
    quote_id, event_id = str(uuid.uuid4()), str(uuid.uuid4())
    with connect(write=True) as db:
        inserted = db.execute("""INSERT INTO quotes
            (id, owner_id, owner_email, idempotency_key, request_hash, data_json, created_at, expires_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(owner_id, idempotency_key) DO NOTHING""",
            (quote_id, owner["sub"], owner["email"], key, digest, json.dumps(data), now, now + 7 * 86400)).rowcount
        row = db.one("SELECT * FROM quotes WHERE owner_id=? AND idempotency_key=?", (owner["sub"], key))
        if row["request_hash"] != digest:
            raise ValidationError("That idempotency key was already used with different quote inputs.")
        if inserted:
            event = {"schema_version": 1, "event_id": event_id, "event_type": "QuoteCommitted", "quote_id": quote_id}
            db.execute("""INSERT INTO outbox_events
                (event_id, quote_id, event_type, payload_json, created_at, available_at)
                VALUES (?, ?, ?, ?, ?, ?)""", (event_id, quote_id, "QuoteCommitted", json.dumps(event), now, now))
        return public(row), bool(inserted)


def list_quotes(owner):
    with connect() as db:
        return [public(row) for row in db.all("SELECT * FROM quotes WHERE owner_id=? ORDER BY created_at DESC LIMIT 100", (owner,))]


def events(owner):
    with connect() as db:
        return db.all("""SELECT e.event_id, e.quote_id, e.event_type, e.created_at, e.published_at,
            e.attempts, e.last_error, n.status AS notification_status
            FROM outbox_events e JOIN quotes q ON q.id=e.quote_id
            LEFT JOIN notification_ledger n ON n.event_id=e.event_id
            WHERE q.owner_id=? ORDER BY e.created_at DESC LIMIT 100""", (owner,))
