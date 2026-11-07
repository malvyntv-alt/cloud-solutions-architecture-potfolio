# Hybrid lab deployment and evidence runbook

> Live-session update: the full lab was deployed and tested on November 6, 2026. See [observed results and cleanup status](live-validation-2026-11-06.md); failover recovery remains unfinished. Earlier pending-status text below describes the predeployment baseline.


Status: Terraform validates and three mocked tests pass. Router bootstrap, IPsec/BGP, SSM access and packet forwarding have not been tested on AWS. Hybrid DNS is optionally implemented; see [DNS guide](hybrid-dns.md).

## Enable and review

Set `enable_hybrid = true` and `enable_test_hosts = true` in the local lab tfvars. Defaults remain false. Confirm the AWS profile, account and region; run `terraform plan -out=lab.tfplan` and review before applying. Plans and state contain VPN secrets: keep both private.

The optional setup adds one public-facing router with an EIP, nine private test hosts, ten SSM interface endpoints (the eight AWS endpoints span two AZs), a Site-to-Site VPN and its TGW attachment. Include EC2/EBS, public IPv4, endpoint AZ-hours, VPN, TGW and logging in the cost review. No deployment was performed during implementation.

Ubuntu 24.04 AWS images supply Python and the SSM agent. The router installs strongSwan, FRR and boto3 using its internet route; a package repository failure will prevent bootstrap. Test hosts have no internet route. The router role can describe VPN connections account-wide because that API lacks resource-level IAM support; use an isolated lab account. It stores retrieved PSKs in root-only `/etc/ipsec.secrets`. Never capture that file or VPN customer configuration in portfolio evidence.

## Topology and policy

The simulated data center is `172.16.0.0/16`, with router subnet `172.16.0.0/24` and private test subnet `172.16.1.0/24`. It has no direct TGW VPC attachment. Private subnet routes send Production and Shared traffic to the router ENI, whose source/destination check is disabled.

Without DNS, the router advertises only `172.16.1.0/24` using ASN 65010. It accepts only Production `10.10.0.0/16` and Shared `10.30.0.0/16` from AWS ASN 64512. Two VTI interfaces carry BGP over IKEv2 IPsec tunnels with AES256/SHA256 and DH group 14. The VPN attachment is associated with a separate hybrid TGW table; BGP routes propagate only into Production and Shared tables. No default/aggregate route permits access to Development or Restricted.

UDP 500/4500 are exposed in the router SG to permit AWS-assigned tunnel peers without a Terraform dependency cycle. Bootstrap host firewall rules limit those ports to the two peer addresses. There is no SSH ingress. Keep this distinction visible when reviewing security controls.

## Verify after deployment

Use `terraform output test_hosts`, `terraform output hybrid`, and `terraform output onprem_test_host` for instance IDs and addresses. Open sessions with `aws ssm start-session --target <instance-id>` (requires your local Session Manager plugin and appropriate operator IAM permissions).

On the router, check:

```sh
sudo cloud-init status --wait
sudo systemctl status hybrid-router strongswan-starter frr
sudo ipsec statusall
sudo vtysh -c 'show bgp summary'
sudo vtysh -c 'show ip route'
ip -s link show vti1
ip -s link show vti2
```

Both peers must reach Established. Record learned/exported prefixes and check the TGW tables against the policy. Check `journalctl -u hybrid-router` and `/var/log/cloud-init-output.log` on failure; do not publish raw logs without checking for sensitive information.

On every test host, verify `systemctl status network-test` and `curl --max-time 5 http://127.0.0.1:8080/`. Probe peer private IPs with `curl --connect-timeout 5 --max-time 10 http://<destination-ip>:8080/`. Repeat the validation matrix from both AWS AZs and both directions. Production/shared must reach the on-premises host and vice versa. Development/restricted must remain unreachable from on-premises.

Security groups also deny forbidden peers. A failed probe alone therefore cannot prove route isolation: retain route-table evidence and known-listener positive controls. Use a separately reviewed temporary test SG rule if you need to isolate routing from SG enforcement; remove it afterward.

## Failover experiment

Keep timestamped TCP probes running from the on-premises host to Production. On the router, run `sudo ipsec down aws1`, wait for BGP withdrawal, and verify continued traffic through tunnel 2. Restore with `sudo ipsec up aws1` and wait for both peers to recover. Repeat for `aws2`. Record actual outage duration and route changes; do not assume zero packet loss. Avoid rebooting or manually restarting the bootstrap service during this experiment.

Two tunnels share one EC2 router and one simulated site. This tests tunnel redundancy, not router/site resilience. The bootstrap service configures VTI interfaces at boot; use a reboot rather than rerunning it on already-created interfaces.

## DNS, evidence and cleanup

Hybrid DNS is an optional implementation: enable it and follow the [DNS guide](hybrid-dns.md) for inbound/outbound Resolver endpoints, conditional forwarding, router DNS and TCP/UDP 53 validation. SSM endpoint private DNS does not provide hybrid DNS.

Record UTC timestamps, commit, source/destination, expected/actual results and measured outage in the validation plan. No live results are claimed yet. Run `terraform destroy` in this root after testing, then verify removal of the VPN, endpoints, router/EIP, hosts and TGW attachments.

## Production Direct Connect design

A production extension would use redundant customer routers, diverse circuits/locations, transit virtual interfaces, a Direct Connect gateway and a TGW association. A private VIF serves a virtual private gateway design; this TGW design uses transit VIFs. Choose BGP policy so Direct Connect is preferred and VPN supplies backup, then measure failover. Define encryption requirements separately: use appropriate supported encryption or VPN over the chosen transport. No circuit is purchased and no Direct Connect performance or failover is claimed.

## References

- [strongSwan route-based VPN](https://docs.strongswan.org/docs/latest/features/routeBasedVpn.html)
- [Terraform AWS VPN connection](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/vpn_connection)
- [AWS Site-to-Site VPN guide](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html)

## Live failover test caution

Do not block a peer and then run an unbounded `ipsec down`: shutdown may wait for an acknowledgement that the block prevents. Use bounded, automatically restored packet-interruption rules and separate monitoring. Require both BGP peers and a stable TCP/DNS baseline before each independent interruption. The first live session exposed recovery issues; the simple procedure above is not yet a verified automatic recovery workflow. See the live validation report for failed probe counts and the next investigation.
