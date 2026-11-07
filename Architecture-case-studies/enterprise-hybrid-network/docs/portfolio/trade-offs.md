# Trade-offs and production boundaries

[Project](../../README.md)

| Area | Lab choice and benefit | Cost, limitation and production next step |
| --- | --- | --- |
| Segmentation | Per-zone routing tables and narrow service SGs | TGW is not an application firewall; evaluate inspection, logging and account boundaries for production |
| Connectivity | Two encrypted BGP VPN tunnels | One router/site and internet transport; observed interruption/rejoin issues remain unresolved |
| Availability | Two-AZ AWS subnets and Resolver addresses | Does not make the on-premises router/DNS redundant; add independent failure domains and test applications |
| DNS | Central conditional forwarding and explicit source binding | Router DNS is a single point of failure; verify fresh bootstrap and evaluate dedicated redundant DNS servers |
| Cost | Disposable deployment with no spoke NAT gateways | TGW, VPN, SSM and Resolver endpoints still incur charges; the $5 session target was not a hard cap or final invoice |
| Access | Private SSM management, no SSH keys | Requires endpoint reachability, instance roles and operator permissions |
| State/secrets | Independent local lab state, ignored plans/logs | VPN keys are present in state; production needs encrypted, controlled remote state with locking and recovery |
| Router IAM | Runtime DescribeVpnConnections avoids PSKs in user data | Describe API access is account-wide; use an isolated lab account and evaluate tighter secrets distribution for production |
| Evidence | Positive controls, TCP matrix, DNS and route snapshots | No throughput, MTU, production RTO, compliance or business-value claim |
| Dedicated connectivity | Direct Connect documented using transit VIF/DX gateway/TGW | No circuit purchased or tested; define redundancy, route preference and encryption requirements independently |

The remaining preproduction priority is a stable, repeatable failover test with bounded commands, clean baseline, measured recovery intervals and verified restoration. Read [actual results](../live-validation-2026-11-06.md) before treating any design intention as demonstrated behavior.
