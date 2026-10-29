# HTTP API

AWS requests use ALB/Cognito identity and backend signature checks. Local mode uses synthetic identity. No API Gateway.

| Method | Route | Behavior |
|---|---|---|
| GET | /healthz | Unauthenticated liveness, not DB readiness |
| GET | /api/session | Identity/mode/region |
| POST | /api/quotes/preview | Calculate |
| POST | /api/quotes | Atomic save/outbox; Idempotency-Key required |
| GET | /api/quotes | Owner's quotes, maximum 100 |
| GET | /api/events | Owner's events/ledger |
| GET | /api/system | Owner's backlog/local fault settings |
| GET | /api/inbox | Local messages; empty explanatory AWS response |
| POST | /api/demo/fault | Local-only failure control |
| POST | /api/demo/tick | Local-only worker iteration |

Input fields: vehicle, vehicle_price, down_payment, term_months, credit_tier. Terms: 24/36/48/60/72/84. Tiers: excellent/good/fair.

POST requires application/json and 1–16384 body bytes. Idempotency keys are 8–128 characters, scoped by owner. Same key/input returns the existing quote; changed input is rejected.

Responses: 201 new save; 200 read/preview/retry; 400 validation; 401 identity; 404 unknown route; 405 unsupported static-resource method; 413 body size; 415 content type; 503 transient failure. Retry uncertain saves with the same key.

See app/server.py for exact route behavior.
