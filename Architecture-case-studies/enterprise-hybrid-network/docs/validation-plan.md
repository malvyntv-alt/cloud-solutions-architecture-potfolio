# Validation and portfolio evidence

> Live-session update: the full lab was deployed and tested on November 6, 2026. See [observed results and cleanup status](live-validation-2026-11-06.md); failover recovery remains unfinished. Earlier pending-status text below describes the predeployment baseline.


Status: all live AWS tests pending. A diagram, Terraform validation, or route-table inspection is not proof of end-to-end connectivity.

| Test | Expected result | Evidence |
| --- | --- | --- |
| Production ↔ shared approved service | Pass | TCP probe, matching routes and security rules |
| Development ↔ shared approved service | Pass | TCP probe and return path |
| Production ↔ restricted approved service | Pass | TCP probe and return path |
| Development → production, and reverse | Fail | Route inspection plus failed probe to a known listening service |
| Development → restricted, and reverse | Fail | Route inspection plus failed probe |
| Shared → restricted, and reverse | Fail | Route inspection plus failed probe |
| Workloads in each AZ | Match policy | Repeat probes from both AZs |
| Flow logging | Traffic recorded | Timestamped records; diagnose SG/NACL versus absent routes separately |
| VPN/BGP later | Intended prefixes learned | Tunnel and BGP status; route snapshots |
| VPN tunnel interruption later | Connectivity recovers on remaining tunnel | Timestamped before/during/after results and measured outage |
| Hybrid DNS later | Intended names resolve both directions | DNS queries, forwarding rules and endpoint configuration |

Use known listeners and positive controls so a timeout is not mistaken for segmentation. Record source/destination private IPs, ports, timestamps and deployed commit. Restrict test security groups to required peers/ports. Do not publish credentials, VPN secrets, state or private keys.

Before any deployment: review the plan, selected account/region, address overlap, routes, resource count and costs. After testing, destroy using this project's own root and state, then verify the created resources were removed. Do not touch the application's state.

## Local implementation checks

Verified on November 6, 2026:

- Provider initialization: passed with AWS provider v5.100.0 using a local archive whose SHA-256 matched HashiCorp's published Windows AMD64 checksum.
- `terraform fmt -check -recursive terraform`: passed.
- `terraform validate`: passed.
- `terraform test`: passed (3 tests, 0 failures). The mocked IAM policy-document data source supplies valid JSON for provider validation.

The provider lock file currently contains the Windows AMD64 checksum. Add checksums with `terraform providers lock -platform=linux_amd64` before using a different platform.

The test checks the exact approved route matrix, both-AZ workload routes, absence of broad workload destinations and flow-log coverage. It does not test AWS connectivity or the contents of the real IAM policies. No AWS deployment or live traffic tests were performed.

Optional hybrid/test-host configuration also passes a mocked plan. This checks selective propagation, return-route count, BGP mode, router forwarding and AWS test-host/endpoint counts. See [hybrid runbook](hybrid-runbook.md) for live checks. No AWS plan, deployment, tunnel, DNS or traffic results are available yet.

Hybrid DNS now has a mocked apply test checking endpoint address counts, selective forwarding associations, host-specific Shared return routes and separate namespaces. This uses only the mock provider and performs no AWS operations. DNS bootstrap and live query behavior are still unverified. See [DNS validation guide](hybrid-dns.md).
