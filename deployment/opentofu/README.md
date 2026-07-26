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

## Hungry Dev caveat

The two `poorman-*aws` roots are intentionally cheap, single-host deployment
shapes—not highly available replacements for EKS/RDS. Each requires a Golden
AMI baked with its exact runtime ingredients before OpenTofu can launch the
host. The example files contain the dummy AMI ID `ami-0123456789abcdef0`.

The maintainer's current Golden AMI is private to the owning AWS account, so it
is not a public artifact and cannot be launched by other accounts. Operators
must replace the example value in their ignored local `terraform.tfvars` with
an AMI ID they own or have been explicitly granted permission to use.

## Which Hungry Dev shape should I use?

| Shape | Runtime contract | Best fit |
| --- | --- | --- |
| `poorman-aws` | Docker Compose on one private EC2 host | The smallest operational footprint, demos, prototypes, UAT, and low-traffic staging |
| `poorman-k3s-aws` | Helm release on single-node K3s | Kubernetes-shaped development, Helm validation, edge pilots, and teams preparing for EKS/GKE |

Both roots use the same sealed-subnet pattern: no NAT gateway, load balancer,
public IPv4 address, EKS control plane, or managed RDS instance. Operators reach
the host through an EC2 Instance Connect Endpoint (EICE), and deployment
artifacts move through a private S3 bucket. The persistent EBS volume carries
the application data across an instance replacement in the same Availability
Zone.

The savings are architectural, not magical. Avoiding always-on managed control
planes, NAT gateways, load balancers, and managed database premiums can make a
small, eligible account approach `$0` incremental spend or fit within free-tier
allowances. AWS billing still varies by account, region, free-tier status,
storage, requests, logs, data transfer, backups, and the temporary Packer
builder. Set a budget alert and treat the estimate as a target—not a promise.

## Is Helm used?

Only `poorman-k3s-aws` uses Helm: the baked K3s image contains Helm and the
deployment helper installs the Spherical Mammoth chart from a locally delivered
package. This preserves the same application contract used by kind, EKS, and
GKE while keeping the control plane on the single EC2 host.

`poorman-aws` deliberately does not use Kubernetes or Helm. It runs the Compose
stack directly and transfers a Compose file, runtime environment file, and
preloaded image archive through EICE/S3. Choose it when Compose is the thing you
want to operate; choose the K3s root when Kubernetes behavior is part of what
you need to test.

Neither shape is a highly available production replacement for EKS/RDS. They
are useful stepping stones: start cheaply, validate the data plane and release
process, then move the same Helm contract to managed Kubernetes when traffic,
availability, compliance, or team size justifies it.
