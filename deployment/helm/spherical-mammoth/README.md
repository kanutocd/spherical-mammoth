# Spherical Mammoth Helm chart

This umbrella chart installs the Spherical Mammoth reference SaaS and consumes
the canonical Mammoth chart as a versioned dependency.

## OCI install

```bash
helm install spherical-mammoth \
  oci://ghcr.io/kanutocd/charts/spherical-mammoth \
  --version 0.1.0 \
  --namespace spherical-mammoth \
  --create-namespace
```

The chart deploys PostgreSQL, Kratos, Mailpit, the identity lifecycle bridge,
the Mammoth chart, the email sink, and the web application. Disable bundled
development dependencies or override their values for managed environments.

The defaults are suitable only for an isolated development environment.
Override `secrets.*`, image versions, persistence, resources, ingress/service
exposure, and external data services before deploying outside one.

## Local verification

From the repository root:

```bash
make kind-verify
```

The local helper vendors `../mammoth/charts/mammoth` when that sibling checkout
is present and otherwise uses the checked-in dependency package.
