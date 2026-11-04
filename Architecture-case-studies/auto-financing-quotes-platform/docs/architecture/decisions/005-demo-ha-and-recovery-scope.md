# ADR-005: Keep demo cost separate from unverified HA and regional recovery targets

- Status: Implemented design; live demo decommissioned
- Recorded: November 3, 2026 (retrospective documentation)
- Scope: Implemented design from a verified, subsequently decommissioned single-region AWS demonstration. Bootstrap was retained. HA and multi-region targets are not evidence of deployed resilience.

## Business context

A portfolio needs a verifiable deployment within a bounded budget without implying enterprise availability that has not been tested.

## Decision

Use the cost-reduced single-region demo profile for the live exercise, preserve a separate HA profile in the same regional state, and label Region B and cross-region recovery as roadmap. Decommission regional resources after capturing evidence.

## Alternatives considered

Run the full HA profile continuously; deploy a second region immediately; present target diagrams without deployment caveats.

## Business benefit

Allows a real workflow demonstration with explicit teardown and controlled scope. Preserves a path for later reliability work without claiming it is complete.

## Consequences and risks

Demo has one database instance, initial web task, publisher and shared NAT. Multiple network AZs alone do not prove application failover. HA settings still require capacity and failure exercises; target RTO/RPO values are not measurements.

## Revisit trigger

A sponsor funds a sustained pilot or availability requirement; measure recovery and failover before accepting service objectives.

## Supporting material

[Implementation, operating guidance or evidence](../../operations/recovery-roadmap.md). This record documents engineering rationale; it does not imply historical stakeholder approval, measured ROI or benchmarking of alternatives.
