# Signup lifecycle smoke scenario

After starting the Compose stack, run:

```bash
make smoke-lifecycle
```

The scenario records a verification-requested projection and event, submits its
delivery envelope twice, and verifies that Mailpit receives exactly one message.
It exercises the producer and sink boundary directly while Mammoth route syntax
is finalized.
