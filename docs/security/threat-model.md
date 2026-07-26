# Initial Threat Model

## Protected assets

- identity credentials and sessions;
- verification and recovery material;
- customer and organization data;
- OAuth clients and secrets;
- email provider credentials;
- PostgreSQL replication credentials;
- Mammoth operational state.

## Initial controls

- Kratos and Hydra administrative APIs are private;
- secrets are never committed;
- replication uses a dedicated least-privilege user;
- sink delivery requires signed requests or an equivalent authenticated channel;
- event payloads exclude credentials and verification secrets;
- email delivery is idempotent;
- external provider errors are classified without leaking sensitive content.
