# Runbook: Local Kubernetes

The local Kubernetes target uses kind and the Helm chart.

Planned workflow:

```bash
make kind-create
make helm-install
make e2e-signup
```

The same external scenario runner must work against Compose or Kubernetes by changing only the base URL.
