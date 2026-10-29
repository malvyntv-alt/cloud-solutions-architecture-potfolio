import json
import time
from concurrent.futures import ThreadPoolExecutor
import pytest
from app.db import connect
from app.quotes import save, list_quotes, events
from app.publisher import publish_one, claim
from app.notifications import local_consume_one, process
from app.domain import ValidationError


def fault(name, enabled):
    with connect(write=True) as db:
        db.execute("INSERT INTO demo_settings(key,value) VALUES (?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value",
                   (name, str(enabled).lower()))
        db.execute("UPDATE outbox_events SET available_at=0")


def test_quote_and_event_roll_back_together(quote_input, owner):
    with connect(write=True) as db:
        db.execute("CREATE TRIGGER fail_outbox BEFORE INSERT ON outbox_events BEGIN SELECT RAISE(ABORT, 'injected failure'); END")
    with pytest.raises(Exception):
        save(quote_input, owner, "rollback-key")
    with connect() as db:
        assert db.one("SELECT COUNT(*) AS count FROM quotes")["count"] == 0


def test_concurrent_save_is_idempotent(quote_input, owner):
    with ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(lambda _: save(quote_input, owner, "same-request-key"), range(4)))
    assert len({q["id"] for q, _ in results}) == 1
    assert sum(created for _, created in results) == 1
    assert len(events(owner["sub"])) == 1
    with pytest.raises(ValidationError):
        save({**quote_input, "vehicle_price": "36000"}, owner, "same-request-key")


def test_other_owner_cannot_list_quote(quote_input, owner):
    save(quote_input, owner, "ownership-key")
    assert not list_quotes("bob")
    assert not events("bob")


def test_sqs_outage_preserves_quote_and_event(quote_input, owner):
    save(quote_input, owner, "sqs-failure-key")
    fault("sqs_down", True)
    assert publish_one() is False
    assert len(list_quotes(owner["sub"])) == 1
    event = events(owner["sub"])[0]
    assert event["published_at"] is None
    assert event["attempts"] == 1
    fault("sqs_down", False)
    assert publish_one()
    assert local_consume_one()
    assert events(owner["sub"])[0]["notification_status"] == "ACCEPTED"


def test_ambiguous_ack_can_duplicate_but_local_inbox_dedupes(quote_input, owner):
    save(quote_input, owner, "lost-ack-key")
    fault("ambiguous_ack", True)
    assert not publish_one()
    fault("ambiguous_ack", False)
    assert publish_one()
    assert local_consume_one()
    assert local_consume_one()
    with connect() as db:
        assert db.one("SELECT COUNT(*) AS count FROM demo_inbox")["count"] == 1


def test_publisher_crash_lease_can_be_reclaimed(quote_input, owner):
    save(quote_input, owner, "lease-crash-key")
    first = claim()
    assert claim() is None
    second = claim(time.time() + 61)
    assert first["event_id"] == second["event_id"]
    assert first["lease_owner"] != second["lease_owner"]


def test_email_outage_does_not_delete_queued_work(quote_input, owner):
    save(quote_input, owner, "email-outage-key")
    assert publish_one()
    fault("email_down", True)
    with pytest.raises(RuntimeError):
        local_consume_one()
    with connect() as db:
        assert db.one("SELECT COUNT(*) AS count FROM demo_queue")["count"] == 1
    fault("email_down", False)
    assert local_consume_one()


def test_expired_quote_is_not_emailed(quote_input, owner):
    quote, _ = save(quote_input, owner, "expired-quote-key")
    with connect(write=True) as db:
        db.execute("UPDATE quotes SET expires_at=0 WHERE id=?", (quote["id"],))
    assert publish_one()
    assert local_consume_one()
    assert events(owner["sub"])[0]["notification_status"] == "EXPIRED"
    with connect() as db:
        assert db.one("SELECT COUNT(*) AS count FROM demo_inbox")["count"] == 0


def test_message_cannot_select_a_different_quote(quote_input, owner):
    first, _ = save(quote_input, owner, "first-quote-key")
    second, _ = save(quote_input, owner, "second-quote-key")
    event = events(owner["sub"])[-1]
    with pytest.raises(ValueError):
        process({"schema_version": 1, "event_type": "QuoteCommitted", "event_id": event["event_id"], "quote_id": second["id"]})


def test_lambda_reports_only_failed_records(monkeypatch):
    from app import lambda_handler
    def consume(event):
        if event["fail"]:
            raise RuntimeError("injected failure")
    monkeypatch.setattr(lambda_handler, "process", consume)
    result = lambda_handler.handler({"Records": [
        {"messageId": "ok", "body": json.dumps({"fail": False})},
        {"messageId": "bad", "body": json.dumps({"fail": True})}]}, None)
    assert result == {"batchItemFailures": [{"itemIdentifier": "bad"}]}

