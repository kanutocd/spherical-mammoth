# Runbook: Local Compose

The Compose stack is the default developer and demonstration environment.

Start the implemented services:

```bash
make compose-up
```

Open the web application at `http://localhost:3000` and Mailpit at
`http://localhost:8025`.

If port 3000 is already occupied, an alternate binding can be used for
API-driven smoke testing:

```bash
WEB_PORT=13000 WEB_ORIGIN=http://localhost:13000 make compose-up
```

The checked-in Kratos development configuration permits both the default
`http://localhost:3000` origin and the documented `http://localhost:13000`
fallback. Other ports require a matching entry in
`platform/kratos/kratos.yml`.

Run the current lifecycle acceptance smoke:

```bash
make e2e-signup
```

The smoke exercises the complete committed-event path through PostgreSQL
logical replication, Mammoth routing, the transactional email sink, and
Mailpit.
