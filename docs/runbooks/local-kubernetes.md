# Runbook: Local Kubernetes

The fast local Kubernetes target uses kind. The same cluster-neutral Helm chart
is intended for kind, K3s, EKS, and GKE; only values and infrastructure differ.
This runbook deliberately uses the published OCI chart, so no source checkout
is required.

## Prerequisites

- Docker
- kind
- kubectl
- Helm 3
- network access to GHCR and Docker Hub
- the `spherical-mammoth:0.1.1` chart and `v1.5.3` application images published to GHCR

## Set the release variables

The umbrella chart is published as `spherical-mammoth`. Set the release and
chart versions explicitly so the installation uses the intended published
chart:

```bash
export HELM_RELEASE=spherical-mammoth
export HELM_NAMESPACE=spherical-mammoth
export SPHERICAL_MAMMOTH_CHART_VERSION=0.1.1
export CHART_REF=oci://ghcr.io/kanutocd/charts/spherical-mammoth
```

Check the exact chart before creating a cluster. This catches a missing or
incorrectly tagged OCI release immediately:

```bash
helm show chart "$CHART_REF" --version "$SPHERICAL_MAMMOTH_CHART_VERSION"
```

The chart pins the first-party application images at `v1.5.3`. Its bundled
third-party development images are not a complete image lock, so record their
resolved digests if you need a fully repeatable local environment.

## Create a disposable cluster

```bash
kind create cluster --name spherical-mammoth
```

Reuse an existing cluster by skipping this command. Confirm the selected
context before installing:

```bash
kubectl config use-context kind-spherical-mammoth
kubectl cluster-info
```

To avoid pulling the three published application images from GHCR during the
install, preload them into the kind node. Images in the host Docker cache are
not automatically visible to kind:

```bash
export APP_IMAGE_TAG=v1.5.3
for image in \
  ghcr.io/kanutocd/spherical-mammoth-identity-lifecycle-bridge:"$APP_IMAGE_TAG" \
  ghcr.io/kanutocd/spherical-mammoth-email-sink:"$APP_IMAGE_TAG" \
  ghcr.io/kanutocd/spherical-mammoth-web:"$APP_IMAGE_TAG"
do
  docker pull "$image"
  kind load docker-image "$image" --name spherical-mammoth
done
```

If you skip this step, the kind node pulls those images directly from GHCR. The
chart also pulls Mammoth from GHCR and PostgreSQL, Kratos, and Mailpit from
Docker Hub; those images are not covered by this optional preload.

## Install the published chart

```bash
helm upgrade --install "$HELM_RELEASE" "$CHART_REF" \
  --version "$SPHERICAL_MAMMOTH_CHART_VERSION" \
  --namespace "$HELM_NAMESPACE" \
  --create-namespace \
  --wait \
  --timeout 10m
```

The chart package contains the pinned Mammoth dependency and deploys the
PostgreSQL, Kratos, identity lifecycle bridge, email sink, Mailpit, web, and
Mammoth workloads. Do not use the development defaults for an exposed or
production environment; provide protected values or external secrets instead.

## Verify the release

```bash
kubectl -n "$HELM_NAMESPACE" get pods
kubectl -n "$HELM_NAMESPACE" get statefulsets,deployments,services
helm status "$HELM_RELEASE" --namespace "$HELM_NAMESPACE"
```

Wait for all workloads if the initial install is still progressing:

```bash
kubectl -n "$HELM_NAMESPACE" wait --for=condition=ready pod --all --timeout=10m
```

The release includes these services:

- web
- Kratos
- identity lifecycle bridge
- Mailpit

Forward them from the cluster for a browser smoke check:

```bash
kubectl -n "$HELM_NAMESPACE" port-forward service/"$HELM_RELEASE-web" 8080:80
kubectl -n "$HELM_NAMESPACE" port-forward service/"$HELM_RELEASE-kratos" 4433:4433
kubectl -n "$HELM_NAMESPACE" port-forward service/"$HELM_RELEASE-identity-lifecycle-bridge" 8081:8080
kubectl -n "$HELM_NAMESPACE" port-forward service/"$HELM_RELEASE-mailpit" 8025:8025
```

Open `http://localhost:8080` for the web UI and `http://localhost:8025` for
Mailpit. Run each port-forward in its own terminal; stop them with `Ctrl-C`.
All four forwards are required for the signup flow: the published web image
calls Kratos at `http://localhost:4433` and the lifecycle bridge at
`http://localhost:8081`.

The lifecycle bridge can be checked directly at `http://localhost:8081` with:

```bash
kubectl -n "$HELM_NAMESPACE" port-forward \
  service/"$HELM_RELEASE-identity-lifecycle-bridge" 8081:8080
```

### Troubleshoot signup

Before opening the web UI, confirm the two browser-facing APIs are reachable
from the same host as the browser:

```bash
curl --fail http://localhost:4433/health/ready
curl --fail http://localhost:8081/health/ready
```

If registration reports a connection error, check that the Kratos port-forward
is still running and that it maps local port `4433` (not `4434`, the Kratos
admin API) to service port `4433`. A browser opened at `http://127.0.0.1:8080`
is also supported; use one host consistently for the web UI and its forwarded
services.

## Pull or render without installing

```bash
helm pull "$CHART_REF" --version "$SPHERICAL_MAMMOTH_CHART_VERSION"
helm show chart "$CHART_REF" --version "$SPHERICAL_MAMMOTH_CHART_VERSION"
```

## Remove the disposable release and cluster

```bash
helm uninstall "$HELM_RELEASE" --namespace "$HELM_NAMESPACE"
kind delete cluster --name spherical-mammoth
```

Removing the Helm release does not remove resources outside the namespace or
any external cloud resources.

## OCI registry details

OCI registries do not use `helm repo add`. The chart is fetched directly by its
OCI reference and version. If a future release changes the umbrella chart
version, update `SPHERICAL_MAMMOTH_CHART_VERSION` rather than relying on a
floating tag.
