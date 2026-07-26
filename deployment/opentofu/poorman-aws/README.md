# Poor Man's AWS: Golden Mammoth

Except where otherwise noted, this directory is licensed under Apache-2.0.
Redistributions must retain the accompanying `LICENSE` and `NOTICE` files.

This is an independent OpenTofu root. It does not import, call, or share state
with `../aws`; commands run here cannot modify the EKS/RDS stack.

```text
operator / CI
     |
 IAM + EICE tunnel
     |
sealed private subnet (no IGW, NAT, public IPv4)
     |
ASG 1/1/1: Golden Mammoth AMI
     ├── disposable 8 GiB root
     └── persistent 22 GiB EBS
              |
       S3 gateway endpoint
              |
 private deployment + backup bucket

ASG launch -> EventBridge -> EBS Ballerina Lambda
                           -> safe attach -> CONTINUE
```

## What it creates

- one small VPC and one private subnet in a fixed AZ;
- no internet gateway, NAT gateway, public IPv4, load balancer, EKS, or RDS;
- a free S3 gateway endpoint and EC2 Instance Connect Endpoint;
- a `1/1/1` ASG using a baked Golden Mammoth AMI;
- an independently managed encrypted EBS data volume protected by
  `prevent_destroy`;
- EventBridge/Lambda lifecycle automation that attaches the volume before the
  instance enters service;
- an SSE-S3 deployment/backup bucket;
- least-privilege instance, Lambda, and operator IAM policies.

## 1. Bake the AMI

The production subnet is sealed, so package installation belongs in the image:

```bash
cd packer
cp example.pkrvars.hcl local.pkrvars.hcl
packer init .
packer validate -var-file=local.pkrvars.hcl .
packer build -var-file=local.pkrvars.hcl .
```

The AMI includes patched Amazon Linux 2023, Docker, Compose, AWS CLI, XFS tools,
zstd, PostgreSQL client tools, EICE support, the release activator, and selected
preloaded container images.

## 2. Plan the isolated root

Create the remote-state bucket once, then:

```bash
cp environments/dev/backend.hcl.example environments/dev/backend.hcl
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
# Put the Packer AMI ID and your operator role ARN in terraform.tfvars.
tofu init -backend-config=environments/dev/backend.hcl
tofu plan -var-file=environments/dev/terraform.tfvars
tofu apply -var-file=environments/dev/terraform.tfvars
```

## 3. Deploy through EICE

Build and compress the application image without ECR:

```bash
docker save spherical-mammoth:dev | zstd -T0 -19 -o image.tar.zst
AWS_REGION=ap-southeast-1 \
DEPLOYMENT_BUCKET="$(tofu output -raw deployment_bucket)" \
EICE_ENDPOINT_ID="$(tofu output -raw instance_connect_endpoint_id)" \
ASG_NAME="$(tofu output -raw autoscaling_group_name)" \
./scripts/deploy-through-eice image.tar.zst compose.production.yaml runtime.env
```

The script uploads artifacts through the operator's internet connection, pushes
an ephemeral SSH key, opens an EICE tunnel, and asks the host to atomically
activate the release from S3.

## Safety and cost reality

The Lambda refuses to detach the data volume from a running instance. This
chooses downtime over potential PostgreSQL split-brain. `prevent_destroy` also
means intentionally deleting or replacing the data volume requires a reviewed
configuration change.

“Zero cost” is a target, not an OpenTofu guarantee. EC2/EBS eligibility varies
by account and time; S3 storage/requests, Lambda, logs, data transfer, and the
temporary Packer builder can accrue charges. Add AWS Budgets outside this stack
before treating a billing estimate as a control.

This root is a single-host availability model. The EBS volume is AZ-bound and
is not a substitute for tested PostgreSQL backups. The next rung is the
three-node `pg_auto_failover` design, which should be another independent root.
