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
- network access to `ghcr.io`
- the `spherical-mammoth:0.1.1` chart and `v1.5.3` application images published to GHCR

## Set the release variables

The umbrella chart is published as `spherical-mammoth`. Set the release and
chart versions explicitly so the verification is reproducible:

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

For a deterministic local run, preload the published application images into
the kind node. Images in the host Docker cache are not automatically visible to
kind:

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

If you skip this step, the kind node must pull the images directly from GHCR.

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
kubectl -n "$HELM_NAMESPACE" port-forward service/"$HELM_RELEASE-web" 18080:80
kubectl -n "$HELM_NAMESPACE" port-forward service/"$HELM_RELEASE-kratos" 14433:4433
kubectl -n "$HELM_NAMESPACE" port-forward service/"$HELM_RELEASE-mailpit" 18025:8025
```

Open `http://localhost:18080` for the web UI and `http://localhost:18025` for
Mailpit. Run each port-forward in its own terminal; stop them with `Ctrl-C`.

The lifecycle bridge can be checked directly at `http://localhost:18081` with:

```bash
kubectl -n "$HELM_NAMESPACE" port-forward \
  service/"$HELM_RELEASE-identity-lifecycle-bridge" 18081:8080
```

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
