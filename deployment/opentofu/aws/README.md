# AWS OpenTofu reference

This stack provisions the cloud substrate; Helm installs Spherical Mammoth.

```text
Internet/operator
        |
   EKS API + load balancers
        |
  private EKS nodes -- IRSA --> Secrets Manager / S3
        |
 private RDS PostgreSQL (logical replication enabled)
```

It creates:

- a multi-AZ VPC shape with public and private subnets and NAT egress;
- EKS with private nodes, control-plane logs, managed add-ons, OIDC, and access entries;
- private encrypted RDS PostgreSQL with managed master credentials, backups, and logical replication parameters;
- KMS-encrypted secret containers and object storage;
- a least-privilege IRSA role for the Mammoth Kubernetes service account.

## Run

Create the state S3 bucket once, then:

```bash
cp environments/dev/backend.hcl.example environments/dev/backend.hcl
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
tofu init -backend-config=environments/dev/backend.hcl
tofu plan -var-file=environments/dev/terraform.tfvars
```

The example uses one NAT gateway, Spot nodes, and a small single-AZ database to
make the development shape cheaper. Staging demonstrates one NAT per AZ,
on-demand nodes, Multi-AZ RDS, and deletion protection. Restrict the EKS public
API CIDRs and replace the example cluster administrator ARN before applying.
Because bootstrap creator administration is disabled, omitting every valid
administrator access entry will leave operators unable to administer the
cluster.

## Post-provisioning boundary

OpenTofu does not store application secret values or execute SQL. Populate the
created `postgres-replication` secret, then run a controlled database bootstrap
that creates a `LOGIN REPLICATION` role, grants `SELECT` on captured tables, and
creates the publication Mammoth consumes. Helm/External Secrets binds those
values to the workload. The generated RDS master secret is for bootstrap and
break-glass administration, not normal Mammoth operation.

The S3 backend itself is intentionally bootstrapped outside this root module:
infrastructure cannot safely store its first state in a bucket it has not yet
created.
