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

The smoke currently submits the Mammoth delivery envelope directly to the sink.
The Mammoth service remains behind the `implemented` Compose profile until its
version-specific destination and routing configuration is finalized.
