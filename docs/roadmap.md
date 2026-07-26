# Initial Roadmap

## Milestone 0 — Repository foundation

- [x] establish monorepo boundaries;
- [x] persist architecture and ADRs;
- [x] define initial event and delivery schemas;
- [x] create Compose, Helm, kind, and OpenTofu skeletons;
- [x] establish CI validation entry points.

## Milestone 1 — Signup verification vertical slice

- [x] React signup and verification UX;
- [ ] Kratos browser registration and verification flow;
- [x] Go identity lifecycle bridge;
- [x] application-owned signup projection and semantic events;
- [ ] Mammoth source and route configuration;
- [x] Python email sink;
- [x] Mailpit default provider;
- [x] verification and welcome templates;
- [ ] end-to-end Compose scenario.

## Milestone 2 — Kubernetes parity

- [ ] build service images;
- [ ] deploy the vertical slice to kind;
- [ ] add readiness, liveness, resources, persistence, and network policy;
- [ ] run the same signup scenario against Kubernetes.

## Milestone 3 — Reliability demonstrations

- [ ] duplicate delivery and idempotency;
- [ ] retry and backoff;
- [ ] dead-letter and replay;
- [ ] Mammoth restart recovery;
- [ ] PostgreSQL restart recovery;
- [ ] provider latency and outage scenarios.

## Milestone 4 — Team and integration workflows

- [ ] organization creation;
- [ ] member invitation and acceptance;
- [ ] customer webhook registration;
- [ ] audit sink;
- [ ] transaction and tenant-local ordering demonstrations.

## Milestone 5 — Paid ecosystem proving ground

- [ ] Mammoth Control Agent integration;
- [ ] Mammoth Control Plane registration;
- [ ] centralized observability;
- [ ] governed replay;
- [ ] fleet and configuration management.
