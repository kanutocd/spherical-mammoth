# Spherical Mammoth

**Spherical Mammoth** is a production-shaped, cloud-native reference SaaS used to demonstrate, validate, benchmark, and eventually operate the Mammoth PostgreSQL CDC data plane.

The application is intentionally small but realistic: users can register through Ory Kratos, verify their email, complete signup, and receive transactional email. Business state is committed to PostgreSQL, captured by Mammoth, and delivered to independent polyglot sinks.

## Initial vertical slice

```text
React / TypeScript signup UI
        ↓
Ory Kratos registration
        ↓
Go identity lifecycle bridge
        ↓
PostgreSQL commit
        ↓
Mammoth data plane
        ↓
Python transactional email sink
        ↓
Mailpit by default; Amazon SES or Resend optionally
```

The verification-completed transition follows the same path and emits a welcome email.

## Deployment targets

- Docker Compose for local development, CI, and demonstrations.
- Kubernetes with Helm for production-shaped operation.
- kind for local Kubernetes validation.
- OpenTofu for an AWS reference environment and infrastructure refresher.

## Repository status

Milestone 1 is in progress. The repository now includes the React identity UX,
Go lifecycle bridge, transactional PostgreSQL projection/event writes, Python
email sink, Mailpit integration, and an idempotency smoke scenario. Mammoth route
configuration and a complete Kratos-to-Mammoth acceptance scenario remain.

## Repository map

```text
apps/          customer and operator-facing applications
services/      independently deployable polyglot services
platform/      Mammoth, Ory, PostgreSQL, and observability configuration
contracts/     language-neutral event and delivery contracts
deployment/    Compose, kind, Helm, OpenTofu, and GitOps assets
scenarios/     deterministic acceptance and failure scenarios
docs/          architecture, ADRs, runbooks, SLOs, and security material
```

See [docs/architecture/overview.md](docs/architecture/overview.md) and [docs/roadmap.md](docs/roadmap.md).
