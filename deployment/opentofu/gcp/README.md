# GCP OpenTofu reference

This is the GCP counterpart to the AWS stack.

```text
Internet/operator
        |
   GKE control plane + load balancers
        |
 private GKE nodes -- Workload Identity --> Secret Manager / GCS
        |
 private Cloud SQL PostgreSQL (logical decoding enabled)
```

It creates a custom VPC with secondary pod/service ranges and Cloud NAT, private
service networking, a regional private-node GKE cluster, private Cloud SQL
PostgreSQL 17, Secret Manager containers, Cloud Storage, and a workload-bound
Google service account.

## Run

Create the state GCS bucket once, then:

```bash
cp environments/dev/backend.hcl.example environments/dev/backend.hcl
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
tofu init -backend-config=environments/dev/backend.hcl
tofu plan -var-file=environments/dev/terraform.tfvars
```

The dev overlay uses Spot nodes and zonal Cloud SQL. Staging demonstrates
on-demand nodes, regional Cloud SQL, and deletion protection.

As on AWS, secret values and SQL grants are a post-provisioning concern. Populate
the secret versions out of band and run a database bootstrap to create the
administrator password, logical-replication role, grants, and publication.
Cloud SQL enables `cloudsql.logical_decoding`, but OpenTofu deliberately does not
put database passwords into state.
