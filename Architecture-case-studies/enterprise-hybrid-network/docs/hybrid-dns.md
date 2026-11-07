# Hybrid DNS lab

> Live-session update: the full lab was deployed and tested on November 6, 2026. See [observed results and cleanup status](live-validation-2026-11-06.md); failover recovery remains unfinished. Earlier pending-status text below describes the predeployment baseline.


Status: implemented and locally checked; all live DNS and VPN results remain pending.

## Enable

Set all three switches in the local lab tfvars:

```hcl
enable_hybrid = true
enable_test_hosts = true
enable_hybrid_dns = true
```

DNS defaults to disabled. Review the AWS plan and costs before applying: inbound and outbound Resolver endpoints each allocate two billable IP addresses across two AZs, in addition to the existing lab costs. The router is also the single on-premises DNS server; there is no claim of DNS-server or site resilience.

## Query paths

- Production/Shared query their normal Amazon-provided VPC resolver for `host.onprem.lab.test`. A rule forwards this suffix through the Shared outbound endpoint to dnsmasq on the router at `172.16.0.10`, across the VPN. The answer is the on-premises test host's private address.
- The on-premises client queries `172.16.0.10` for `shared.aws.lab.test`. dnsmasq forwards that suffix to Shared inbound endpoint IPs `10.30.1.10` and `10.30.2.10`, across the VPN. The private hosted zone returns the shared test host's address.
- Only Production and Shared associate the on-premises forwarding rule and cloud private hosted zone. Development and Restricted do not receive them. DNS visibility and packet access are separate controls.

AWS requires inbound endpoints for this remote query path; do not forward on-premises queries directly to the VPC CIDR+2 resolver address. The two suffixes are deliberately distinct to avoid forwarding loops. No public hosted zone is created.

The router advertises its DNS address `172.16.0.10/32` in addition to the existing test subnet `172.16.1.0/24`. Production/Shared TGW tables learn both through the existing selective propagation. Only Shared workload tables receive the additional /32 route, so the DNS endpoints can return traffic. The rest of the router subnet is not advertised. Only the two outbound endpoint IPs and on-premises test subnet can initiate TCP/UDP 53 into dnsmasq. AWS test hosts continue using their local VPC resolver.

## Live validation

After cloud-init completes on the router, confirm `sudo systemctl status dnsmasq`, `sudo ss -lntup | grep ':53'`, and BGP routes. Ubuntu's systemd-resolved keeps its loopback listener; dnsmasq binds only `172.16.0.10`.

Use `resolvectl query host.onprem.lab.test` from Production and Shared test hosts. Confirm the answer matches `terraform output onprem_test_host`. Verify DNS name resolution is followed by a successful TCP 8080 request to that host.

From the router (which has internet package access), install `dnsutils` if necessary, then run:

```sh
dig @172.16.0.10 host.onprem.lab.test A
dig @172.16.0.10 shared.aws.lab.test A
dig +tcp @172.16.0.10 shared.aws.lab.test A
dig -b 172.16.0.10 @10.30.1.10 shared.aws.lab.test A
dig -b 172.16.0.10 +tcp @10.30.2.10 shared.aws.lab.test A
```

Repeat the first two queries from the on-premises test host if DNS tooling is available. Its private subnet has no internet package access; Python `socket.getaddrinfo` through the default resolver is not a substitute for an explicit query to the router. Do not change system resolver settings without retaining SSM service resolution.

Repeat name queries from Development/Restricted: they must not return the private lab records. Record the actual result code rather than assuming NXDOMAIN versus timeout. Repeat cross-VPN DNS checks during each tunnel interruption. Record timestamps, exact answers, TCP/UDP results and measured disruption. No such live results have been captured yet.

## Files

- `c9-01-dns-security.tf`: opt-in locals and DNS security groups.
- `c9-02-resolver-endpoints.tf`: inbound/outbound endpoint addresses and Shared return routes.
- `c9-03-dns-zones-and-rules.tf`: private hosted zone, test record and conditional forwarding associations.
- `templates/router.sh.tftpl`: dnsmasq setup and additional BGP host-prefix advertisement.

## References

- [AWS hybrid Resolver overview](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resolver-overview-DSN-queries-to-vpc.html)
- [AWS endpoint troubleshooting and port requirements](https://repost.aws/knowledge-center/route-53-fix-dns-resolution-resolver)

## Source address correction from live testing

Route-based VPN routing selects a VTI inside address for router-originated queries unless a source is specified. Inbound Resolver security groups permit only `172.16.0.10/32`, so dnsmasq forwarding uses `@172.16.0.10` on both upstream server lines. Direct `dig` tests from the router must also use `-b 172.16.0.10`. Router caching is disabled so failover probes exercise forwarding rather than cached answers. This correction was applied to the running router and the bootstrap template.
