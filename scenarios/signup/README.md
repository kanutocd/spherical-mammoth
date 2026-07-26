# End-to-end signup Compose scenario

After starting the Compose stack, run:

```bash
make e2e-signup
```

The scenario:

1. initializes a credentialed Kratos browser registration flow;
2. submits its CSRF token, identity traits, and password;
3. records the application-owned verification-requested transition;
4. waits for both the Kratos code and Mammoth-routed notification in Mailpit;
5. submits the code through the Kratos browser verification flow;
6. records signup completion and waits for the Mammoth-routed welcome email.

Override `KRATOS_URL`, `BRIDGE_URL`, `MAILPIT_URL`, `WEB_ORIGIN`, or
`E2E_TIMEOUT_SECONDS` to run the same external scenario against another
environment.
