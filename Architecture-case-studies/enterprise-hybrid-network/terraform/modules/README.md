# Network modules

- `vpc`: private workload and dedicated TGW attachment subnets in two AZs, with explicit subnet route-table associations. Attachment route tables contain only local routes.
- `transit-gateway`: four attachments and routing domains with default association/propagation disabled. Only the six directed paths supplied by the root are installed.

The lab root owns address allocation, policy, workload routes, flow logs and provider configuration. Modules inherit the root provider. VPN and router simulation remain future work.
