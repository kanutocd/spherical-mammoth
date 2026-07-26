# Golden K3s AMI

This image bakes the exact K3s binary and its air-gap image archive, Helm, AWS
CLI, EICE support, XFS tools, and the chart deployment helper. The sealed
runtime instance performs no internet installation.

```bash
packer init .
packer validate -var-file=example.pkrvars.hcl .
packer build -var-file=example.pkrvars.hcl .
```

The default is K3s `v1.36.1+k3s1` and Helm `v4.1.4`. Test upgrades against a
snapshot of the identity EBS volume before replacing the production AMI.
