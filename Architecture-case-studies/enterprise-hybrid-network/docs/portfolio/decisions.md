# Architecture decisions

[Project](../../README.md)

| Decision | Alternative considered | Reason and consequence |
| --- | --- | --- |
| Central TGW with explicit route tables | VPC peering mesh | Makes zone policy visible in routing domains; adds attachment/data-processing costs and hub operational responsibility |
| Static approved AWS routes, selective VPN propagation | Default association/blanket propagation | Avoids unintended Development/Production and Restricted/Shared reachability; route changes require deliberate review |
| Four AWS zones plus separate simulated data center | Reuse one existing workload VPC as on-premises | Preserves a VPN-only test path; consumes five VPCs and requires quota headroom |
| Site-to-Site VPN with strongSwan/FRR | Physical Direct Connect | Exercises encryption and BGP without a circuit; internet transport and one EC2 router do not model production dedicated-link performance or site resilience |
| Separate /28 attachment subnets and /24 workloads in two AZs | Shared attachment/workload subnets | Clarifies intent and leaves route-table roles easy to inspect; more subnet objects do not independently prove resilience |
| SSM interface endpoints, no SSH keys | Bastion or NAT egress in each spoke | Private management access without inbound SSH; endpoint AZ-hours materially affect lab cost |
| Shared inbound/outbound Resolver, distinct private suffixes | Forward directly to a VPC CIDR+2 resolver | Explicit supported hybrid forwarding path and scoped associations; endpoint cost and on-premises DNS remain operational dependencies |
| Native modules and numbered source files | Copy application infrastructure wholesale | Keeps IAM/networking understandable and separates resource purposes; requires maintaining these modules and bootstrap scripts |
| Short-lived lab with verified destroy | Permanently hosted demonstration | Controls recurring network costs; screenshots must be coordinated before teardown and recreation changes IDs/keys |

## Decision changed by evidence

VTI routing selected tunnel-inside source IPs for router-originated DNS. The inbound Resolver allowed only the router host prefix, so forwarding timed out. dnsmasq now binds upstream queries to the authorized private address, preserving the narrow SG rule. This was validated live; a clean bootstrap recreation remains pending.

## Decision still under evaluation

Two tunnels are insufficient evidence of seamless failover. Both interruptions produced failed probes and rejoin needed intervention. Keep explicit failure evidence and improve recovery before making resilience claims. See [dated observations](../live-validation-2026-11-06.md).
