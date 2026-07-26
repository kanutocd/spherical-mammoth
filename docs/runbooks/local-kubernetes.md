# Runbook: Local Kubernetes

The fast local Kubernetes target uses kind. The same cluster-neutral Helm chart
is intended for kind, K3s, EKS, and GKE; only values and infrastructure differ.

## Prerequisites

- Docker
- kind
- kubectl
- Helm 3
- the sibling Mammoth checkout at `../mammoth`, or a published Mammoth chart
  available from GHCR

## One-command verification

```bash
make kind-verify
```

The command:

1. creates or reuses the `spherical-mammoth` kind cluster;
2. packages the local Mammoth `1.5.3` chart as the umbrella dependency;
3. builds and loads the bridge, email sink, web, and Mammoth images;
4. installs or upgrades the Spherical Mammoth Helm release;
5. waits for every workload;
6. forwards Kratos, the lifecycle bridge, Mailpit, and web services; and
7. runs the same external signup scenario used by Compose.

The local endpoints used during the test are:

- web: `http://localhost:18080`;
- Kratos: `http://localhost:14433`;
- lifecycle bridge: `http://localhost:18081`;
- Mailpit: `http://localhost:18025`.

Port-forwards exist only for the duration of the verification command.

Delete the disposable cluster with:

```bash
make kind-delete
```

## OCI installation

After the Mammoth and Spherical Mammoth charts are published, no source checkout
is required:

```bash
helm install spherical-mammoth \
  oci://ghcr.io/kanutocd/charts/spherical-mammoth \
  --version 0.1.0 \
  --namespace spherical-mammoth \
  --create-namespace
```

OCI registries do not use `helm repo add`. Fetch without installing with:

```bash
helm pull oci://ghcr.io/kanutocd/charts/spherical-mammoth --version 0.1.0
```

Do not use the checked-in development secrets for an exposed environment.
Override them from a protected values source or external secret integration.
