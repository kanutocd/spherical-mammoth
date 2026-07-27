# Cloud-native Mammoth OSS deployment

This is the deliberately boring procedure for deploying the open-source
Mammoth PostgreSQL CDC data plane.

The sequence is always explicit:

1. Provision cloud infrastructure.
2. Connect `kubectl` to the intended cluster.
3. Prepare PostgreSQL logical replication.
4. Create Kubernetes secrets.
5. Render and review Helm manifests.
6. Install the pinned Mammoth chart.
7. Wait for readiness.
8. Insert one non-sensitive test row and verify delivery.

There is no automatic credential discovery, implicit database bootstrap, or
infrastructure command that silently installs an application release.

## Architecture and ownership

```text
RDS or Cloud SQL PostgreSQL
          | logical replication slot + publication
          v
Mammoth OSS Helm release (one replica)
          | signed webhook delivery
          v
your webhook receiver
```


The AWS and GCP OpenTofu roots provision the cloud substrate and managed
PostgreSQL. Helm installs Mammoth. OpenTofu intentionally does not put database
passwords, SQL grants, or Helm release state into infrastructure state.

The Spherical Mammoth umbrella chart installs the reference SaaS around
Mammoth. Its checked-in defaults are development defaults; use the standalone
Mammoth chart for a plain cloud data-plane deployment unless every umbrella
value has been reviewed and overridden.

## Release inputs

Pin every release input. Do not use `latest` for a production change.

```bash
export MAMMOTH_CHART_VERSION=1.5.3
export MAMMOTH_RELEASE=mammoth
export MAMMOTH_NAMESPACE=mammoth
```

The published chart is:

```text
oci://ghcr.io/kanutocd/charts/mammoth
```

Confirm it before changing a cluster:

```bash
helm show chart \
  oci://ghcr.io/kanutocd/charts/mammoth \
  --version "$MAMMOTH_CHART_VERSION"
```

The chart version and `appVersion` should match the release record. Record the
image tag separately; the published image uses the `v1.5.3` tag. Keep the
rendered manifest from each deployment review.

## Operator prerequisites

- OpenTofu;
- Helm 3;
- kubectl;
- AWS CLI for EKS or Google Cloud CLI for GKE;
- `psql` for the controlled database bootstrap; and
- cloud account/project and GHCR access.

```bash
helm registry login ghcr.io
kubectl version --client
tofu version
```

A private package requires a GitHub token with `read:packages`:

```bash
printf '%s' "$GHCR_READ_TOKEN" | helm registry login ghcr.io \
  --username "$GITHUB_USER" \
  --password-stdin
```

Before provisioning, record the account/project, region, environment, API
access CIDRs, PostgreSQL version and tier, replication role, publication, slot,
destination URL, signing-secret owner, backup retention, deletion-protection
decision, chart version, and image version.

Never use `0.0.0.0/0` for a production Kubernetes API endpoint. Never commit
passwords to `terraform.tfvars`, Helm values, shell history, or tickets.

## AWS EKS

### Provision the substrate

The AWS root expects an S3 state backend. Create that bucket through your
standard bootstrap process; the root cannot safely create the bucket in which
it stores its first state.

```bash
cd deployment/opentofu/aws
cp environments/dev/backend.hcl.example environments/dev/backend.hcl
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
```

Set the region, environment, restricted `cluster_public_access_cidrs`, valid
`cluster_admin_principal_arns`, node sizing, RDS sizing, backup retention, and
deletion protection. Review and apply:

```bash
tofu init -backend-config=environments/dev/backend.hcl
tofu fmt -check -recursive
tofu validate
tofu plan -var-file=environments/dev/terraform.tfvars
tofu apply -var-file=environments/dev/terraform.tfvars
```

Read the plan before applying it. Confirm the account, region, CIDRs, node
capacity, RDS settings, and administrator access.

### Connect to EKS

Use the cluster name from the OpenTofu output:

```bash
aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$EKS_CLUSTER_NAME"
kubectl config current-context
kubectl get nodes
```

Do not continue until the context is the new cluster and every expected node is
`Ready`.

### Prepare RDS logical replication

Retrieve the RDS administrator credential through the approved AWS secret path
and connect through the private network, bastion, or approved database path:

```bash
psql "$RDS_ADMIN_DATABASE_URL"
```

Run a reviewed SQL bootstrap that creates the application database, a `LOGIN
REPLICATION` Mammoth role, least-privilege `CONNECT`/schema/table `SELECT`
grants, and the publication containing the tables to capture.

The resulting values should be equivalent to:

```text
host: <private-rds-endpoint>
port: 5432
database: spherical_mammoth
username: mammoth
slot: spherical_mammoth
publication: spherical_mammoth_publication
```

Do not grant superuser access as a shortcut. Keep the role specific to the
captured database and tables.

### Create Kubernetes secrets

Use External Secrets or your approved secret controller in a real environment.
The explicit baseline is:

```bash
kubectl create namespace "$MAMMOTH_NAMESPACE" --dry-run=client -o yaml \
  | kubectl apply -f -
kubectl -n "$MAMMOTH_NAMESPACE" create secret generic mammoth-postgres \
  --from-literal=password="$MAMMOTH_POSTGRES_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "$MAMMOTH_NAMESPACE" create secret generic mammoth-webhook \
  --from-literal=signing-secret="$MAMMOTH_WEBHOOK_SIGNING_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -
```

The names and keys must match the Helm values file.

### Render and install Mammoth

Create an uncommitted values file outside the repository. The important parts
are shown below:

```yaml
image:
  repository: ghcr.io/kanutocd/mammoth
  tag: "v1.5.3"
  pullPolicy: IfNotPresent

mammoth:
  name: spherical_mammoth

node:
  node_id: eks-spherical-mammoth-01
  node_name: eks-spherical-mammoth
  environment: production

postgres:
  host: <private-rds-endpoint>
  port: 5432
  database: spherical_mammoth
  username: mammoth
  existingSecret:
    name: mammoth-postgres
    key: password

replication:
  slot: spherical_mammoth
  publications:
    - spherical_mammoth_publication
  auto_create_slot: false
  temporary_slot: false

destinations:
  - name: primary_webhook
    type: webhook
    enabled: true
    url: https://receiver.example.com/mammoth
    signing:
      algorithm: hmac_sha256
      secret_env: MAMMOTH_WEBHOOK_SIGNING_SECRET
      signature_header: X-Mammoth-Signature
      timestamp_header: X-Mammoth-Timestamp
    existingSecret:
      name: mammoth-webhook
      keys:
        MAMMOTH_WEBHOOK_SIGNING_SECRET: signing-secret

persistence:
  storage: 10Gi
```

Render and review before install:

```bash
helm template "$MAMMOTH_RELEASE" \
  oci://ghcr.io/kanutocd/charts/mammoth \
  --version "$MAMMOTH_CHART_VERSION" \
  --namespace "$MAMMOTH_NAMESPACE" \
  --values /secure/path/mammoth-eks-values.yaml \
  > /tmp/mammoth-eks-rendered.yaml
```

Check the host, image, secret references, destination, and replication values.
Then install:

```bash
helm upgrade --install "$MAMMOTH_RELEASE" \
  oci://ghcr.io/kanutocd/charts/mammoth \
  --version "$MAMMOTH_CHART_VERSION" \
  --namespace "$MAMMOTH_NAMESPACE" \
  --create-namespace \
  --values /secure/path/mammoth-eks-values.yaml \
  --wait \
  --timeout 10m
```

### Verify EKS

```bash
kubectl -n "$MAMMOTH_NAMESPACE" get pods,pvc,secret
kubectl -n "$MAMMOTH_NAMESPACE" rollout status deployment/mammoth --timeout=5m
kubectl -n "$MAMMOTH_NAMESPACE" logs deployment/mammoth --tail=100
```

Insert one non-sensitive test row into a published table and confirm the
receiver validates the signature and records one event. Do not use customer
data for the first test.

## GCP GKE

### Provision the substrate

Create the state GCS bucket through your standard bootstrap process:

```bash
cd deployment/opentofu/gcp
cp environments/dev/backend.hcl.example environments/dev/backend.hcl
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
gcloud auth login
gcloud auth application-default login
gcloud config set project "$GCP_PROJECT_ID"
```

Set the project, region, environment, authorized API networks, node sizing,
Cloud SQL tier, and deletion protection. Review and apply:

```bash
tofu init -backend-config=environments/dev/backend.hcl
tofu fmt -check -recursive
tofu validate
tofu plan -var-file=environments/dev/terraform.tfvars
tofu apply -var-file=environments/dev/terraform.tfvars
```

### Connect to GKE

```bash
gcloud container clusters get-credentials "$GKE_CLUSTER_NAME" \
  --region "$GCP_REGION" \
  --project "$GCP_PROJECT_ID"
kubectl config current-context
kubectl get nodes
```

Do not continue until the context is correct and every expected node is
`Ready`.

### Prepare Cloud SQL and secrets

Cloud SQL must have logical decoding enabled. Through the approved private
database access path, run the same reviewed bootstrap as AWS: create the
Mammoth `LOGIN REPLICATION` role, least-privilege grants, publication, and
documented slot.

Create `mammoth-postgres` and `mammoth-webhook` in the namespace using the same
secret names and keys shown in the AWS procedure, or bind them with Secret
Manager and your approved Kubernetes secret controller.

### Install and verify GKE

Reuse the AWS values structure, changing the PostgreSQL host to the private
Cloud SQL address and the node identity to the GKE cluster. Render first:

```bash
helm template "$MAMMOTH_RELEASE" \
  oci://ghcr.io/kanutocd/charts/mammoth \
  --version "$MAMMOTH_CHART_VERSION" \
  --namespace "$MAMMOTH_NAMESPACE" \
  --values /secure/path/mammoth-gke-values.yaml \
  > /tmp/mammoth-gke-rendered.yaml
```

Install and wait:

```bash
helm upgrade --install "$MAMMOTH_RELEASE" \
  oci://ghcr.io/kanutocd/charts/mammoth \
  --version "$MAMMOTH_CHART_VERSION" \
  --namespace "$MAMMOTH_NAMESPACE" \
  --create-namespace \
  --values /secure/path/mammoth-gke-values.yaml \
  --wait \
  --timeout 10m
kubectl -n "$MAMMOTH_NAMESPACE" get pods,pvc,secret
kubectl -n "$MAMMOTH_NAMESPACE" rollout status deployment/mammoth --timeout=5m
kubectl -n "$MAMMOTH_NAMESPACE" logs deployment/mammoth --tail=100
```

Insert one non-sensitive test row and confirm one signed webhook at the
receiver.

## Upgrades, rollback, and teardown

Inspect history before changing anything:

```bash
helm history "$MAMMOTH_RELEASE" -n "$MAMMOTH_NAMESPACE"
```

Render and review the new version before upgrading. Roll back with:

```bash
helm rollback "$MAMMOTH_RELEASE" <REVISION> \
  -n "$MAMMOTH_NAMESPACE" --wait
```

Remove only the application release with:

```bash
helm uninstall "$MAMMOTH_RELEASE" -n "$MAMMOTH_NAMESPACE"
```

Destroying EKS/GKE, RDS/Cloud SQL, or storage is a separate reviewed action:

```bash
tofu plan -destroy -var-file=environments/dev/terraform.tfvars
```

Never delete the Mammoth PVC casually. It contains operational state used for
checkpoints, retries, dead letters, and delivery continuity.

## Troubleshooting

### Helm cannot read the chart

```bash
helm registry login ghcr.io
helm show chart oci://ghcr.io/kanutocd/charts/mammoth --version 1.5.3
```

Check the package path, version, token scope, and package visibility.

### Mammoth cannot connect to PostgreSQL

Check private DNS/routing, firewall rules, the secret key name, username,
database, port, and the Mammoth pod logs.

### Slot or publication failure

Confirm logical decoding, publication membership, role grants, slot name, WAL
continuity, and that no second Mammoth process is using the slot.

### Webhook delivery failure

Check the URL, DNS, egress policy, TLS, signing secret, receiver status code,
and Mammoth retry/dead-letter logs. Do not disable signing to make a test pass.

## Definition of done

- OpenTofu state is remote and the plan was reviewed.
- The cloud account/project and Kubernetes context were verified.
- Logical decoding, role grants, publication, and slot are documented.
- Secrets came from an approved secret path.
- Chart and image versions are recorded and pinned.
- Helm reports the release as `deployed` and the pod is `Ready`.
- One non-sensitive test row produced one signed webhook.
- Rollback and deletion decisions are documented.
