# OpenTofu cloud shapes

## Licensing

| Path | License |
| --- | --- |
| `deployment/opentofu/poorman-aws/**` | Apache-2.0 with `NOTICE` |
| `deployment/opentofu/poorman-k3s-aws/**` | Apache-2.0 with `NOTICE` |
| Other files in this repository | Repository-level MIT license |

The two roots intentionally expose the same responsibilities:

| Concern | AWS | GCP |
| --- | --- | --- |
| Network | VPC, public/private subnets, NAT gateway | Custom VPC, secondary ranges, Cloud NAT |
| Kubernetes | EKS managed node group | Regional GKE node pool |
| PostgreSQL | Private RDS, `rds.logical_replication=1` | Private Cloud SQL, `cloudsql.logical_decoding=on` |
| Pod identity | EKS IRSA | GKE Workload Identity Federation |
| Secrets | Secrets Manager + KMS | Secret Manager |
| Objects | Encrypted S3 | Private Cloud Storage |
| Applications | Helm after infrastructure | Helm after infrastructure |

Each cloud is an independent OpenTofu root. Pick one; do not apply both merely
to compare them. Start with its `README.md` and environment example.

`poorman-aws` is a third, deliberately different root: a sealed single EC2
host, persistent EBS identity volume, EICE, S3, and lifecycle automation. It
shares no state or modules with the managed AWS root.

`poorman-k3s-aws` adds a fourth shape: the same Hungry Dev economics with a
single-node, air-gapped K3s control plane and Helm as the common application
contract shared with EKS and GKE.
