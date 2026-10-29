CREATE TABLE IF NOT EXISTS quotes (
 id TEXT PRIMARY KEY, owner_id TEXT NOT NULL, owner_email TEXT NOT NULL,
 idempotency_key TEXT NOT NULL, request_hash TEXT NOT NULL, data_json TEXT NOT NULL,
 created_at DOUBLE PRECISION NOT NULL, expires_at DOUBLE PRECISION NOT NULL,
 UNIQUE(owner_id, idempotency_key)
);
CREATE TABLE IF NOT EXISTS outbox_events (
 event_id TEXT PRIMARY KEY, quote_id TEXT NOT NULL REFERENCES quotes(id),
 event_type TEXT NOT NULL, payload_json TEXT NOT NULL,
 created_at DOUBLE PRECISION NOT NULL, published_at DOUBLE PRECISION,
 attempts INTEGER NOT NULL DEFAULT 0, available_at DOUBLE PRECISION NOT NULL,
 lease_until DOUBLE PRECISION, lease_owner TEXT, last_error TEXT
);
CREATE INDEX IF NOT EXISTS outbox_pending ON outbox_events(published_at, available_at, created_at);
CREATE INDEX IF NOT EXISTS quotes_owner ON quotes(owner_id, created_at);
CREATE TABLE IF NOT EXISTS notification_ledger (
 event_id TEXT PRIMARY KEY REFERENCES outbox_events(event_id), status TEXT NOT NULL,
 lease_until DOUBLE PRECISION, lease_owner TEXT, ses_message_id TEXT,
 updated_at DOUBLE PRECISION NOT NULL
);
CREATE TABLE IF NOT EXISTS demo_queue (
 message_id TEXT PRIMARY KEY, event_id TEXT NOT NULL, body_json TEXT NOT NULL,
 created_at DOUBLE PRECISION NOT NULL
);
CREATE TABLE IF NOT EXISTS demo_inbox (
 id TEXT PRIMARY KEY, event_id TEXT NOT NULL UNIQUE, quote_id TEXT NOT NULL,
 owner_id TEXT NOT NULL, subject TEXT NOT NULL, body TEXT NOT NULL,
 created_at DOUBLE PRECISION NOT NULL
);
CREATE TABLE IF NOT EXISTS demo_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);
