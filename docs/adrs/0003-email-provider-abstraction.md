# ADR-0003: Transactional Email Provider Abstraction

- Status: Accepted

## Decision

The email sink supports interchangeable providers:

1. Mailpit as the default for local development, CI, and free demonstrations.
2. Amazon SES for AWS deployments.
3. Resend for simple hosted delivery.

The sink owns rendering, provider adaptation, idempotency, provider result capture, and failure classification. Mammoth owns transport retries and replay semantics.
