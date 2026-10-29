import json
import logging
from .notifications import process

log = logging.getLogger(__name__)
log.setLevel(logging.INFO)


def handler(event, context):
    failures = []
    for record in event.get("Records", []):
        try:
            process(json.loads(record["body"]))
        except Exception as error:
            log.error(json.dumps({"event": "notification_failed", "message_id": record["messageId"], "category": type(error).__name__}))
            failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}
