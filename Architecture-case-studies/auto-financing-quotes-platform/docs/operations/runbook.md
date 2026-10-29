# Operations

Use authenticated synthetic save/read for readiness; /healthz is only liveness.

| Signal | Investigate | Verify |
|---|---|---|
| Outbox age | Publisher/DB/SQS connectivity and IAM | Oldest age drains |
| Queue age | Mapping/Lambda/SES/DB | Acceptance and backlog drainage |
| DLQ | Error category/schema/event relationship | Fix then bounded redrive |
| Accepted email absent | SES delivery/bounce/sandbox | Acceptance versus delivery |
| ALB unhealthy | Images/startup/logs | Targets AND business path |
| Migration failure | Task logs/secret/DB | Runtime off until exit zero |

Do not reset active leases while workers process. Regional replay requires fencing; it is dry-run by default.

Record detection, impact, action, recovery times and uncertainty. AZ failure, restore, load and regional activation need dedicated exercises.

See [recovery](recovery-roadmap.md), [retention](teardown.md), [evidence](../evidence/README.md).
