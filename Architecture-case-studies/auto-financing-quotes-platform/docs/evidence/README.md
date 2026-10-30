# Portfolio evidence

## Live application verification

[2026-10-29 live quote-to-email exercise](dated-exercises/2026-10-29-live-verification/README.md) contains AWS application screenshots, sanitized service status, CloudWatch images, an idempotent retry observation and confirmed email receipt.

The existing standalone deployment was tested and then its regional stack was torn down; bootstrap/state storage was preserved. Copying its code into the portfolio does not create a second deployment. Email initially went to spam, then the user moved it to the inbox.

## Other records

- [Earlier demo deployment and teardown](dated-exercises/2026-10-29-demo-deployment.md)
- [Local validation](local-validation.md)
- [Historical source-project record](source-project-verification.md)
- [Portfolio layout validation](../../../../docs/portfolio-validation.md)

## Still required

Actual queue failure/recovery, controlled DLQ redrive, alarm behavior, PostgreSQL concurrency tests, backup restoration, AZ/regional drills, load/performance/cost measurements and dependable email inbox placement.

## Evidence rules

Use dated records tied to source commit, image tag/digest, region/profile/capacity, trigger, observations, timestamps and limitations. Distinguish mocked tests, local simulation, deployed configuration and measured results.

Never publish credentials, tokens, state, saved plans, raw CLI dumps or real customer information. Original email evidence is stored in ignored raw/; public records omit addresses and full identifiers.
