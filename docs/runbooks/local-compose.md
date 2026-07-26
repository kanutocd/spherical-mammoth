# Runbook: Local Compose

The Compose stack is the default developer and demonstration environment.

Start the implemented services:

```bash
make compose-up
```

Open the web application at `http://localhost:3000` and Mailpit at
`http://localhost:8025`.

Run the current lifecycle acceptance smoke:

```bash
make smoke-lifecycle
```

The smoke exercises the complete committed-event path through PostgreSQL
logical replication, Mammoth routing, the transactional email sink, and
Mailpit.
