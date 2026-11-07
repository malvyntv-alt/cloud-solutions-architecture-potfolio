# Evidence register

[Project](../../README.md) | [Dated live report](../live-validation-2026-11-06.md)

| Record | Supports | Does not establish |
| --- | --- | --- |
| [Live observations](../live-validation-2026-11-06.md) | Deployment, steady-state connectivity/DNS, failures, correction and cleanup chronology | Production readiness or a measured RTO |
| [Sanitized test results](2026-11-06-live-results.json) | Nine-host TCP matrix, DNS responses, TGW prefixes, flow samples and timestamped interruption probes | Attribution of every denial to one control, throughput or zero packet loss |
| [Independent cleanup checks](2026-11-06-cleanup.json) | Empty state, no lab compute/endpoints, deleted VPN/TGW, original default VPC and EIP count retained | Final AWS billing amount |
| [Mocked Terraform tests](../../terraform/environments/lab/tests/segmentation.tftest.hcl) | Code-level policy checks | Live AWS connectivity |

## Screenshot capture plan

Screenshots were not captured in the first session. In a future screenshot session, leave resources running until the owner explicitly requests teardown. Capture:

1. VPC inventory showing four zones and the separate simulator.
2. TGW attachments and each zone's approved route table.
3. Both VPN tunnels and router BGP summary in steady state.
4. SSM listener/connectivity results with source/destination and timestamp.
5. DNS queries in both directions and a flow-log sample.
6. Interruption and recovery observations, including failures.

Use captions with date, resource purpose, expected/observed behavior and limitations. Redact account identifiers where practical, credentials and all VPN keys. Never publish state, plans, customer-gateway configuration, raw logs or private variable files. Do not label screenshots as captured until actual image files exist.
