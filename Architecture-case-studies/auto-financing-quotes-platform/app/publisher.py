"""Leased, at-least-once publisher. Never keep a row lock across an SQS call."""
import json
import logging
import os
import random
import time
import uuid
from . import config
from .db import connect

log = logging.getLogger(__name__)


def setting(name):
    with connect() as db:
        row = db.one("SELECT value FROM demo_settings WHERE key=?", (name,))
        return row and row["value"] == "true"


def claim(now=None):
    now = now or time.time()
    token = str(uuid.uuid4())
    with connect(write=True) as db:
        suffix = " FOR UPDATE SKIP LOCKED" if db.postgres else ""
        row = db.one("""SELECT * FROM outbox_events WHERE published_at IS NULL
            AND available_at<=? AND (lease_until IS NULL OR lease_until<?)
            ORDER BY created_at LIMIT 1""" + suffix, (now, now))
        if not row:
            return None
        db.execute("UPDATE outbox_events SET lease_owner=?, lease_until=?, attempts=attempts+1 WHERE event_id=?",
                   (token, now + 60, row["event_id"]))
        return {**row, "lease_owner": token, "attempts": row["attempts"] + 1}


def send(event):
    if config.MODE == "local":
        if setting("sqs_down"):
            raise RuntimeError("SIMULATED_SQS_UNAVAILABLE")
        with connect(write=True) as db:
            db.execute("INSERT INTO demo_queue(message_id,event_id,body_json,created_at) VALUES (?,?,?,?)",
                       (str(uuid.uuid4()), event["event_id"], event["payload_json"], time.time()))
        if setting("ambiguous_ack"):
            # Message was durably queued but the producer never saw the acknowledgment.
            raise RuntimeError("SIMULATED_ACK_LOST_MESSAGE_MAY_EXIST")
        return
    import boto3
    from botocore.config import Config
    boto3.client("sqs", region_name=config.REGION,
                 config=Config(connect_timeout=3, read_timeout=5, retries={"max_attempts": 2})).send_message(
                     QueueUrl=config.QUEUE_URL, MessageBody=event["payload_json"])


def publish_one():
    event = claim()
    if not event:
        return False
    started = time.monotonic()
    try:
        send(event)
    except Exception as error:
        # Only an error category is persisted: no credentials or payloads in logs.
        category = str(error) if config.MODE == "local" else type(error).__name__
        delay = min(60, 2 ** min(event["attempts"], 6)) + random.random()
        with connect(write=True) as db:
            db.execute("""UPDATE outbox_events SET available_at=?,lease_owner=NULL,lease_until=NULL,last_error=?
                WHERE event_id=? AND lease_owner=?""",
                (time.time() + delay, category, event["event_id"], event["lease_owner"]))
        log.warning(json.dumps({"event": "publish_failed", "event_id": event["event_id"], "category": category}))
        return False
    with connect(write=True) as db:
        db.execute("""UPDATE outbox_events SET published_at=?,lease_owner=NULL,lease_until=NULL,last_error=NULL
            WHERE event_id=? AND lease_owner=?""", (time.time(), event["event_id"], event["lease_owner"]))
    log.info(json.dumps({"event": "published", "event_id": event["event_id"], "duration_ms": round((time.monotonic()-started)*1000)}))
    return True


def emit_metrics():
    with connect() as db:
        row = db.one("SELECT COUNT(*) AS count, MIN(created_at) AS oldest FROM outbox_events WHERE published_at IS NULL")
    now = time.time()
    print(json.dumps({"_aws": {"Timestamp": int(now * 1000), "CloudWatchMetrics": [{
        "Namespace": "DriveQuote", "Dimensions": [["Project"]], "Metrics": [
            {"Name": "OldestPendingSeconds", "Unit": "Seconds"},
            {"Name": "PendingEvents", "Unit": "Count"}]}]},
        "Project": os.getenv("PROJECT", "drivequote"), "PendingEvents": row["count"],
        "OldestPendingSeconds": max(0, now-row["oldest"]) if row["oldest"] else 0}), flush=True)


def main():
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    last_metrics = 0
    while True:
        try:
            if time.monotonic() - last_metrics > 30:
                emit_metrics()
                last_metrics = time.monotonic()
            if config.PUBLISH_ENABLED:
                for _ in range(20):
                    if not publish_one():
                        break
        except Exception:
            log.exception("publisher_iteration_failed")
        time.sleep(2)


if __name__ == "__main__":
    main()
