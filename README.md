# Spherical Mammoth

**Spherical Mammoth** is a production-shaped, cloud-native reference SaaS used to demonstrate, validate, benchmark, and eventually operate the Mammoth PostgreSQL CDC data plane.

The application is intentionally small but realistic: users can register through Ory Kratos, verify their email, complete signup, and receive transactional email. Business state is committed to PostgreSQL, captured by Mammoth, and delivered to independent polyglot sinks.

## Deployment documentation

Start here for the deliberately explicit, cloud-native OSS deployment guide:

### [Deploy Mammoth on Kubernetes, AWS EKS, or GCP GKE](docs/runbooks/cloud-native-mammoth.md)

It covers infrastructure provisioning with OpenTofu, PostgreSQL logical
replication, secrets, Helm OCI installation, verification, upgrades, rollback,
and teardown. For the fast local path, use the [kind verification runbook](docs/runbooks/local-kubernetes.md).

```text
                 one Helm chart
                      │
       ┌──────────────┼──────────────┐
       │              │              │
      kind          AWS EKS        GCP GKE
       │              │              │
   local test        RDS          Cloud SQL
```

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
Go lifecycle bridge, transactional PostgreSQL projection/event writes, Mammoth
source and email routing, the Python email sink, Mailpit integration, and a CDC
smoke scenario. A complete browser-driven Kratos acceptance scenario remains.

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
