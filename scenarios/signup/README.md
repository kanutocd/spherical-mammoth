# Signup lifecycle smoke scenario

After starting the Compose stack, run:

```bash
make smoke-lifecycle
```

The scenario records a verification-requested projection and event, waits for
Mammoth to capture and route the committed PostgreSQL row, and verifies that
Mailpit receives exactly one message.
