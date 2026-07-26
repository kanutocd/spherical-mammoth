# Poor Man's K3s AWS

Except where otherwise noted, this directory is licensed under Apache-2.0.
Redistributions must retain the accompanying `LICENSE` and `NOTICE` files.

This sibling root keeps the cheap, sealed AWS foundation while matching the
workload shape of EKS:

```text
operator / CI
     |
 EICE private tunnels
     |
single private EC2, ASG 1/1/1
     |
Golden K3s AMI
├── Kubernetes API
├── Traefik ingress
├── local-path storage
└── Helm release: Spherical Mammoth
     |
persistent encrypted EBS
├── K3s SQLite datastore
├── K3s server token and certificates
├── local-path workload volumes
├── chart releases
└── backups

ASG launch -> EventBridge -> EBS Ballerina -> attach -> boot K3s
```

It has independent state and names, so it cannot modify `../aws` or
`../poorman-aws`. It reuses only the latter's low-level networking, storage,
operator-access, and safe-volume-attachment module source.

## Why this shape

| Concern | Managed AWS | Hungry Dev K3s |
| --- | --- | --- |
| Kubernetes | EKS control plane | K3s on the EC2 host |
| Compute | Managed node group | ASG `1/1/1` |
| Application contract | Helm | The same Helm contract |
| Database | RDS PostgreSQL | PostgreSQL workload on persistent EBS |
| Pod identity | IRSA | EC2 instance role |
| Ingress | AWS load balancer | Private Traefik through EICE |
| Recovery | EKS/RDS | ASG + EBS Ballerina + K3s reconciliation |

This is Kubernetes-native but not highly available. Control plane and workloads
share one machine and one AZ. Host recovery requires instance replacement,
volume attachment, K3s startup, and workload reconciliation.

## Air-gapped Golden AMI

The sealed subnet has no internet route. Build the image first:

```bash
cd packer
cp example.pkrvars.hcl local.pkrvars.hcl
packer init .
packer validate -var-file=local.pkrvars.hcl .
packer build -var-file=local.pkrvars.hcl .
```

The image contains K3s and its exact air-gap archive, Helm, AWS tooling, XFS
support, the chart deployment helper, and preloaded application images. New
private application images can be delivered as an optional Docker
`images.tar.zst` beside a chart release.

## OpenTofu

```bash
cp environments/dev/backend.hcl.example environments/dev/backend.hcl
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
# Set the Packer AMI ID and operator role ARN.
tofu init -backend-config=environments/dev/backend.hcl
tofu plan -var-file=environments/dev/terraform.tfvars
```

## Helm release path

```bash
AWS_REGION=ap-southeast-1 \
DEPLOYMENT_BUCKET="$(tofu output -raw deployment_bucket)" \
EICE_ENDPOINT_ID="$(tofu output -raw instance_connect_endpoint_id)" \
ASG_NAME="$(tofu output -raw autoscaling_group_name)" \
./scripts/deploy-chart-through-eice \
  ../../helm/spherical-mammoth \
  values.poorman.yaml \
  images.tar.zst
```

The local and remote deployment helpers both reject a chart that renders zero
Kubernetes resources.

## Current application gate

The repository's Helm chart currently has values and notes but no workload
templates. Infrastructure and the AMI are complete and independently
validatable, but the release script will intentionally refuse installation
until Deployments, StatefulSets, Services, configuration, secrets, and
persistence templates exist.

This is useful honesty for the architecture post:

> The cheap Kubernetes substrate is ready; the existing Helm chart remains the
> application contract that must become deployable.

## Private access

EICE permits narrowly scoped tunnels to:

- `22`: SSH and deployment;
- `6443`: Kubernetes API;
- `80` and `443`: private Traefik preview.

No public application endpoint is created. Public exposure is a separate design
decision: adding an ALB creates a recurring charge, while a serverless/edge
front door needs an explicit private-origin bridge.

Back up both the K3s datastore and its server token. They reside on the identity
EBS volume, but the volume itself is not a backup.
