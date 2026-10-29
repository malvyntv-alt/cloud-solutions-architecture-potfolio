"""Regional recovery operation. Run only AFTER fencing old publishers/consumers."""
import argparse
import time
from .db import connect


def main():
    parser = argparse.ArgumentParser(description="Replay retained, unfinished outbox events after controlled failover.")
    parser.add_argument("--execute", action="store_true", help="Actually reset publication and processing leases.")
    args = parser.parse_args()
    with connect(write=args.execute) as db:
        candidates = db.one("""SELECT COUNT(*) AS count FROM outbox_events e LEFT JOIN notification_ledger n
            ON n.event_id=e.event_id WHERE n.status IS NULL OR n.status NOT IN ('ACCEPTED','EXPIRED')""")["count"]
        print(f"Retained unfinished events: {candidates}")
        if not args.execute:
            print("Dry run. Fence old workers, validate the promoted database, then use --execute.")
            return
        db.execute("""UPDATE outbox_events SET published_at=NULL,available_at=?,lease_until=NULL,lease_owner=NULL
            WHERE event_id IN (SELECT e.event_id FROM outbox_events e LEFT JOIN notification_ledger n
            ON n.event_id=e.event_id WHERE n.status IS NULL OR n.status NOT IN ('ACCEPTED','EXPIRED'))""", (time.time(),))
        db.execute("""UPDATE notification_ledger SET status='PENDING',lease_owner=NULL,lease_until=NULL
            WHERE status NOT IN ('ACCEPTED','EXPIRED')""")
    print("Eligible events reset. Enable ONE authoritative publisher region. Duplicate email remains possible.")


if __name__ == "__main__":
    main()

