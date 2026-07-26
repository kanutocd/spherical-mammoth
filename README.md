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
          ┌───────────────────┼───────────────────┐
          │                   │                   │
         kind          poorman-k3s-aws        AWS EKS / GCP GKE
          │             single EC2 + K3s       managed Kubernetes
      local test              │                   │
                         low-cost Helm       RDS / Cloud SQL
```

## Initial vertical slice

```text
                         browser
                            |
                            | HTTP: register / verify
                            v
             +-------------------------------+
             | apps/web                       |
             | React + TypeScript signup UI   |
             +---------------+---------------+
                             |
                             | Kratos self-service API
                             v
             +-------------------------------+
             | platform/kratos                |
             | Ory Kratos identity service    |
             +---------------+---------------+
                             |
                             | lifecycle events / callbacks
                             v
             +-------------------------------+
             | services/identity-lifecycle    |
             | Go signup + welcome bridge     |
             +---------------+---------------+
                             |
                             | SQL transaction
                             v
             +-------------------------------+
             | PostgreSQL                     |
             | business state + outbox/event  |
             +---------------+---------------+
                             |
                             | logical replication (CDC)
                             v
             +-------------------------------+
             | Mammoth data plane             |
             | source -> routing -> webhooks  |
             +---------------+---------------+
                             |
                             | webhook delivery
                             v
             +-------------------------------+
             | services/email-sink            |
             | Python transactional consumer  |
             +---------------+---------------+
                             |
                             | SMTP / provider API
                             v
             +-------------------------------+
             | Mailpit (default)              |
             | Amazon SES / Resend (optional) |
             +-------------------------------+
```

The verification-completed transition follows the same path and emits a welcome email.

## Deployment targets

- Docker Compose for local development, CI, and demonstrations.
- `poorman-aws` for the smallest private-EC2 Compose deployment.
- `poorman-k3s-aws` for a low-cost single-node K3s deployment using the same Helm contract.
- Kubernetes with Helm for production-shaped operation.
- kind for local Kubernetes validation.
- OpenTofu for an AWS reference environment and infrastructure refresher.

See the [OpenTofu cloud shapes](deployment/opentofu/README.md) overview for
the Hungry Dev use cases, cost boundaries, and private Golden AMI caveat.

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
