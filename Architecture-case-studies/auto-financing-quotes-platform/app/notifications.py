import json
import os
import time
import uuid
from . import config
from .db import connect


class Busy(Exception):
    pass


def prepare(event):
    if event.get("event_type") != "QuoteCommitted" or event.get("schema_version") != 1:
        raise ValueError("Unsupported event schema.")
    event_id = event["event_id"]
    now, token = time.time(), str(uuid.uuid4())
    with connect(write=True) as db:
        # Trust the committed outbox relation, never an arbitrary quote ID from a message.
        row = db.one("""SELECT q.* FROM quotes q JOIN outbox_events e ON e.quote_id=q.id
            WHERE e.event_id=? AND q.id=?""", (event_id, event["quote_id"]))
        if not row:
            raise ValueError("Committed quote event does not exist.")
        db.execute("""INSERT INTO notification_ledger(event_id,status,updated_at) VALUES (?,'PENDING',?)
            ON CONFLICT(event_id) DO NOTHING""", (event_id, now))
        suffix = " FOR UPDATE" if db.postgres else ""
        ledger = db.one("SELECT * FROM notification_ledger WHERE event_id=?" + suffix, (event_id,))
        if ledger["status"] in ("ACCEPTED", "EXPIRED"):
            return None
        if ledger["lease_until"] and ledger["lease_until"] > now:
            raise Busy("Another worker is handling this event.")
        if row["expires_at"] < now:
            db.execute("UPDATE notification_ledger SET status='EXPIRED',updated_at=? WHERE event_id=?", (now, event_id))
            return None
        db.execute("""UPDATE notification_ledger SET status='SENDING',lease_until=?,lease_owner=?,updated_at=?
            WHERE event_id=?""", (now + 120, token, now, event_id))
        return row, token


def process(event):
    prepared = prepare(event)
    if prepared is None:
        return
    row, token = prepared
    event_id = event["event_id"]
    data = json.loads(row["data_json"])
    subject = "Your financing estimate is ready"
    # Prefer a login-protected link over financial / personal details in email.
    origin = os.getenv("PUBLIC_ORIGIN", "http://127.0.0.1:8080").rstrip("/")
    body = ("Your saved financing estimate is ready. Sign in to view it: " + origin +
            "/#saved\nQuote reference: " + row["id"] +
            "\nThis is an illustrative estimate, not a financing approval.")
    try:
        if config.MODE == "local":
            from .publisher import setting
            if setting("email_down"):
                raise RuntimeError("SIMULATED_SES_UNAVAILABLE")
            with connect(write=True) as db:
                db.execute("""INSERT INTO demo_inbox(id,event_id,quote_id,owner_id,subject,body,created_at)
                    VALUES (?,?,?,?,?,?,?) ON CONFLICT(event_id) DO NOTHING""",
                    (str(uuid.uuid4()), event_id, row["id"], row["owner_id"], subject, body, time.time()))
            message_id = "simulated-" + event_id
        else:
            import boto3
            result = boto3.client("sesv2", region_name=config.REGION).send_email(
                FromEmailAddress=os.environ["EMAIL_FROM"], Destination={"ToAddresses": [row["owner_email"]]},
                ConfigurationSetName=os.environ["SES_CONFIGURATION_SET"],
                Content={"Simple": {"Subject": {"Data": subject}, "Body": {"Text": {"Data": body}}}},
                EmailTags=[{"Name": "event_id", "Value": event_id}])
            message_id = result["MessageId"]
        # Crash between SES acceptance and this update can result in a duplicate email.
        with connect(write=True) as db:
            db.execute("""UPDATE notification_ledger SET status='ACCEPTED',ses_message_id=?,updated_at=?,
                lease_owner=NULL,lease_until=NULL WHERE event_id=? AND lease_owner=?""",
                (message_id, time.time(), event_id, token))
    except Exception:
        with connect(write=True) as db:
            db.execute("""UPDATE notification_ledger SET status='PENDING',lease_owner=NULL,lease_until=NULL,updated_at=?
                WHERE event_id=? AND lease_owner=?""", (time.time(), event_id, token))
        raise


def local_consume_one():
    with connect() as db:
        message = db.one("SELECT * FROM demo_queue ORDER BY created_at LIMIT 1")
    if not message:
        return False
    process(json.loads(message["body_json"]))
    with connect(write=True) as db:
        db.execute("DELETE FROM demo_queue WHERE message_id=?", (message["message_id"],))
    return True
