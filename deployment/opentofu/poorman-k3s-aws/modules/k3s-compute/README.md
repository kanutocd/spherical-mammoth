# Single-node K3s compute

The ASG maintains one immutable K3s server. Its control-plane datastore, server
token, local-path volumes, chart artifacts, and backups all live on the
reattachable EBS volume. The root disk and instance remain disposable.
