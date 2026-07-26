# Identity lifecycle bridge

The Go bridge converts identity lifecycle notifications into application-owned
signup projections and semantic domain events. Projection and event changes are
committed in the same PostgreSQL transaction.

Endpoints:

- `POST /v1/lifecycle/verification-requested`
- `POST /v1/lifecycle/signup-completed`
- `GET /health/live`
- `GET /health/ready`
