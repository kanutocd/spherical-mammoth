# Web

React registration and verification UX for the initial identity lifecycle.

The SPA uses Kratos browser flows with credentialed requests, CSRF tokens from
the flow UI nodes, and Kratos-provided submission actions. Registration follows
the returned verification continuation, renders Kratos validation messages, and
supports verification-code submission and resend. The application-owned
lifecycle bridge is notified only after Kratos accepts each transition.

## Development

```bash
pnpm install
pnpm dev
```

Create a production build with `pnpm build`.
