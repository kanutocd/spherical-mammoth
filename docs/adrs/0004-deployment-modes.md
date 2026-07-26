# ADR-0004: Support Compose and Kubernetes as First-Class Modes

- Status: Accepted

## Decision

The same logical services, contracts, and scenarios must run through:

- Docker Compose;
- local Kubernetes using kind;
- Kubernetes using Helm;
- an AWS reference environment provisioned with OpenTofu.

OpenTofu provisions cloud infrastructure. Helm owns application installation into Kubernetes.
