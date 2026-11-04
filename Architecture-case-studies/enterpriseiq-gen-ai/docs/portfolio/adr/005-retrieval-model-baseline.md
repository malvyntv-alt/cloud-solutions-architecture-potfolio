# ADR-005: Use S3 Vectors and Nova Lite as the DEV baseline

- Status: accepted for the current DEV demonstration
- Recorded: November 3, 2026 (retrospective documentation of implemented decisions)
- Scope: personal project using fictional policies; not approval for enterprise production

## Business context

The project needs a working managed retrieval and generation baseline before optimization.

## Decision

Use the Terraform-provisioned S3 Vectors index, Titan Embeddings v2 and regional Nova Lite through Bedrock.

## Alternatives considered

OpenSearch or database vector search; alternative Bedrock generation models; custom reranking.

## Business benefit

A working integration with a managed vector store and a lightweight generation model.

## Consequences and risks

Model and vector-store selections have not been benchmarked for quality, latency or cost against alternatives. The current embedding/index dimension is 1024.

## Revisit trigger

Measured quality, metadata filtering, throughput, latency or cost requirements justify a controlled comparison.

## Supporting material

[Implementation, evidence or evaluation reference](../trade-offs.md). These records document engineering decisions; they do not imply stakeholder consultation, measured ROI or production governance approval.
