# Live validation session ? November 6, 2026 (America/Chicago)

The full 162-resource lab was deployed in us-east-1. Provisioning began at 2026-11-07 00:49:51 UTC (November 6, 6:49:51 PM CST). Teardown completed successfully after evidence collection. This session used uncommitted local project code, not a claimed deployed Git commit.

## Verified results

| Check | Observed result |
| --- | --- |
| Deployment | 162 additions completed successfully |
| Private administration | All ten EC2 instances registered Online with SSM |
| Known listeners | All nine test hosts had active TCP 8080 listeners |
| TCP policy matrix | 81/81 source/destination checks matched policy, including local positive controls |
| Production/shared, development/shared, production/restricted | Bidirectional connectivity passed from both AWS AZs |
| Development/production, development/restricted, shared/restricted | Probes failed as intended in both directions |
| Hybrid connectivity | On-premises reached both Production and Shared AZs, and vice versa; Development/Restricted remained unreachable |
| BGP | Both peers established; router received Production and Shared prefixes and advertised test-subnet and DNS-host prefixes |
| TGW policy | Snapshots showed on-premises prefixes only in Production/Shared routing tables |
| AWS DNS | Production/Shared in both AZs resolved both private lab names; Development/Restricted did not |
| On-premises DNS | Private client received expected on-premises/cloud A answers over UDP and TCP after the source-address correction |
| Observability | Four flow logs reported ACTIVE/SUCCESS; actual CloudWatch records were retrieved and retained |
| Local checks | Terraform validation and three mocked tests passed |

Failed probes are supported by known listening endpoints and route snapshots. Security groups also enforce the policy; these results do not independently attribute every denial to TGW rather than SG enforcement. The TCP checks establish connection success, not throughput, MTU, application resilience or production performance.

## DNS correction

Router-originated forwarding initially selected VTI inside source addresses, which the inbound Resolver SG correctly rejected. The live dnsmasq configuration and `templates/router.sh.tftpl` now force source `172.16.0.10` on both upstreams. Direct router `dig` tests also need that source. Router caching was disabled to make failover probes exercise the forwarding path. A fresh recreation of the corrected bootstrap still needs verification.

## Failover findings ? not a completed acceptance test

The packet-interruption experiments blocked UDP 500/4500 to one AWS peer at a time for 45 seconds, with timestamped on-premises TCP and uncached cloud-DNS probes. The monitor used one-second socket timeouts and attempted roughly one sample per second; failed probes can lengthen sampling intervals.

| Interrupted peer | Samples | Failed TCP samples | Failed DNS samples |
| --- | --- | --- | --- |
| Tunnel 1 | 75 | 22 | 27 |
| Tunnel 2 | 75 | 15 | 44 |

These counts are observations, not outage seconds or an established RTO. The first capture included an unstable baseline from a preceding diagnostic attempt. Traffic recovered through the remaining path, but restoration of both BGP sessions was not clean and required IPsec service intervention. A preliminary attempt also blocked the peer before `ipsec down`, making shutdown wait for an unreachable acknowledgement; it was cancelled and its rules removed.

Do not claim seamless or fully automatic VPN failover. Next work: make interruption/restoration commands bounded, enforce a stable baseline and both-peer recovery between tests, investigate IPsec/BGP rejoin behavior, then repeat with measured recovery intervals. Two tunnels on one router still do not provide router/site resilience.

## Evidence and handling

[Sanitized JSON evidence](evidence/2026-11-06-live-results.json) contains TCP/DNS results, TGW prefix snapshots, flow-log samples and failover timestamps. It excludes credentials, PSKs, state, plans and VPN customer configuration. Local raw deployment/cleanup logs, state and saved plans remain ignored.

## Cleanup

Terraform destroyed all 162 resources. Independent AWS checks at **2026-11-07 01:14:46 UTC** (November 6, 7:14:46 PM CST) confirmed:

- Only the pre-existing default VPC remains.
- No active EC2 instances, EBS volumes, network interfaces, VPC endpoints, Resolver endpoints or lab log groups remain.
- The lab VPN and TGW report deleted.
- The EIP count returned to its predeployment value of one; the existing allocation was untouched.
- `terraform state list` is empty.

See [cleanup evidence](evidence/2026-11-06-cleanup.json). Provisioning through final verification took about 25 minutes; this is not a final AWS bill or a guarantee of exact service billing duration. Billing can appear later. No lab resource remains intentionally running. Local session tfvars retain the feature switches for recreation; plans/logs/state remain private.
