# Executive brief: EnterpriseIQ AI Knowledge Assistant

## Business use case

Employees need quick, understandable answers to policy questions without searching several documents or repeatedly asking subject-matter experts. EnterpriseIQ demonstrates a sign-in-protected chatbot that retrieves relevant policy text, generates an answer and shows source references for review.

The intended sponsor is an operations or internal knowledge-services leader; intended users are employees working with approved policy material. These are proposed stakeholders for the use case, not customers interviewed or organizations served by this personal project.

Example: an employee asks, "What is the disaster recovery RTO?" The fictional policy specifies 60 minutes. The assistant answers using retrieved policy content and displays the document location. This is policy lookup, not execution of a recovery workflow or a guarantee that the organization can recover within that time.

## Value hypothesis

The proposed benefit is less time locating policy information and fewer repetitive questions to specialists. Faster onboarding and more consistent access to policy guidance are additional hypotheses. This project has not measured employee productivity, financial return or organizational adoption.

A business pilot would compare manual lookup with assisted lookup using the same questions. Record median time to a correct, supported answer, correctness rate, unsupported-answer rate, escalation rate, user satisfaction and cost per completed question. Establish baseline values and sponsor-approved acceptance thresholds before making an ROI claim.

## Options considered

| Option | Business advantage | Constraint |
|---|---|---|
| Existing document portal/search | Lowest change to workflow; users inspect original text | Users must find and interpret passages themselves |
| Fine-tuned model | Can adapt response behavior or terminology | Policy updates still require a knowledge strategy; training adds work |
| Managed retrieval plus generation | Supports natural-language answers with refreshed document context | Retrieval and model output require evaluation; generation can be unsupported |

Selected for the demonstration: managed retrieval plus generation on AWS, with a reusable service and a small authenticated web application.

## Delivery and investment

The implemented DEV scope includes React hosting, sign-in, JWT-protected API access, private synthetic documents, vector retrieval, generated answers, source references and Terraform definitions. The owner designed and implemented the application, infrastructure and documentation, and diagnosed live retrieval and hosting defects.

Managed services reduce infrastructure administration. VPC-free Lambda and removal of the app-specific WAF reduce components with potential ongoing charges. These choices are scoped to the DEV demonstration. No measured cost comparison or monthly run-rate is claimed; Bedrock, storage, hosting, API and logging usage can still incur charges.

## Risk and pilot gates

| Business risk | Current position | Gate before a real business pilot |
|---|---|---|
| Incorrect guidance | Context-only prompting and visible retrieved references | Evaluate groundedness and unknown-answer behavior; route high-impact guidance to a human |
| Unauthorized document exposure | Invite-only sign-in, one shared synthetic corpus | Document entitlements and tenant-safe retrieval before differentiated/private datasets |
| Stale policy | Knowledge Base ingestion path exists | Named content owners, update cadence and ingestion monitoring |
| Unexpected spend or slow answers | Throttling and limited logs; no measured SLO | Usage budget, alerts, latency baseline and quota review |
| Operational interruption | DEV deployment and documented repair steps | Runbook, recovery exercise and agreed service objectives |

The next funding decision would be a bounded, measured pilot, after authorization and evaluation gates. This is a proposed decision framework, not a claim that a sponsor approved a pilot.
