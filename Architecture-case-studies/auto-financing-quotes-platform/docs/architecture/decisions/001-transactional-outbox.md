# ADR 001: Transactional outbox

Status: implemented.

Direct DB-write-then-SQS leaves a dual-write gap. Save commits quote and intent together. A leased publisher retries stable event IDs without holding row locks across network I/O.

SQS Standard permits duplicates; a ledger avoids completed-event reprocessing but cannot atomically commit SES acceptance. Duplicate emails remain possible.

Alternatives: DynamoDB transactions/Streams, CDC or managed workflows. These change data modeling or operations. Monitor oldest pending age, test leases and define retention/replay.
