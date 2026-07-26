# Architecture Overview

## Purpose

Spherical Mammoth is a believable SaaS reference implementation whose primary purpose is to exercise Mammoth under realistic application and operational conditions.

It is not intended to become a feature-complete commercial SaaS. Its business surface remains deliberately constrained while its identity, event-delivery, deployment, observability, failure, and recovery behavior remain production-shaped.

## System context

```text
Users
  |
  v
Web UI ───────────────> Ory Kratos
  |                         |
  v                         v
SaaS API             Identity Lifecycle Bridge (Go)
  |                         |
  +──────────────┬──────────+
                 v
            PostgreSQL
                 |
                 | logical replication
                 v
              Mammoth
              /  |   \
             v   v    v
       Email Sink Audit Webhook Receiver
        (Python)
             |
       Mailpit / SES / Resend
```

## Core ownership boundaries

- **Ory Kratos** owns credentials, sessions, self-service registration, verification, recovery, and MFA.
- **Ory Hydra** owns OAuth 2.0 and OpenID Connect flows when the OAuth milestone is enabled.
- **The SaaS domain** owns accounts, signup lifecycle projections, organizations, memberships, projects, and semantic domain events.
- **PostgreSQL** owns committed domain state.
- **Mammoth** owns reliable movement of committed changes to downstream sinks.
- **Sinks** own side effects, projections, idempotency, and provider-specific integration.
- **The DevOps boundary** owns deployment, observability, secrets, backups, incident response, and environment promotion.

## Initial lifecycle

### Verification requested

1. A user submits the signup form.
2. Kratos creates the identity and initiates its supported verification flow.
3. The Go lifecycle bridge records an application-owned `signup_request` and `identity.verification_requested` event in one transaction.
4. PostgreSQL commits.
5. Mammoth captures the event.
6. The Python email sink validates and deduplicates the delivery.
7. Mailpit receives the email by default; SES or Resend may be selected by configuration.

### Signup completed

1. The user completes email verification through Kratos.
2. The lifecycle bridge updates the application-owned projection and records `identity.signup_completed`.
3. Mammoth captures the committed transaction.
4. The email sink sends the welcome email.
5. Audit and future analytics sinks receive the same event independently.

## Contract boundaries

Cross-language integration uses:

- JSON Schema for semantic events and Mammoth delivery envelopes;
- OpenAPI for synchronous service APIs;
- PostgreSQL constraints for authoritative write-side consistency;
- HTTP for initial sink delivery.

Ruby libraries are not the canonical contract for non-Ruby services.
