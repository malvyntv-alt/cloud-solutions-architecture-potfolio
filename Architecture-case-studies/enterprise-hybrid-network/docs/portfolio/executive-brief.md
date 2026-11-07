# Executive brief

[Project](../../README.md)

## Scenario and stakeholders

A fictional financial institution is migrating a Dallas data center over 12-18 months. Network operators need coexistence and diagnostic access; application teams need approved shared services; security reviewers need clear boundaries around production and restricted data. This personal portfolio lab models those needs in one AWS account.

## Intended value

Use one routing hub rather than a growing set of peer connections, explicitly separate network zones, and retain encrypted migration connectivity. Expected benefits are simpler route review and repeatable infrastructure provisioning. No operational cost saving, migration acceleration or ROI has been measured.

## Scope and ownership

Design and implement the Terraform address plan, VPC/TGW modules, approved routes, EC2 strongSwan/FRR customer-router simulator, BGP policy, SSM management, hybrid DNS and validation evidence. AWS operates the managed services. There is no real data-center integration, physical Direct Connect order or regulated production workload.

## Acceptance and observations

- Approved traffic and denied relationships: verified by 81 TCP checks including local controls and route inspection.
- Encrypted hybrid connectivity and selective BGP: verified during steady state.
- Bidirectional private DNS: verified after a query source-address correction.
- Tunnel resilience: interruptions exercised, but clean automatic recovery and a repeatable RTO are not established.
- Teardown: all 162 managed resources removed; independent checks retained.

## Next investment

Prioritize robust tunnel recovery and a fresh corrected-bootstrap deployment. Then add screenshot evidence and application-relevant MTU/throughput tests. Production design would require separate accounts, redundant routers/sites, operational ownership, encryption decisions and compliance review. See [trade-offs](trade-offs.md) and the [live report](../live-validation-2026-11-06.md).
