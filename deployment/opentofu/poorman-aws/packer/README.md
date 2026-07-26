# Golden Mammoth AMI

The builder starts a temporary internet-connected Amazon Linux 2023 instance,
fully patches it, installs the sealed-host runtime, preloads public container
images, creates an encrypted 8 GiB AMI, then removes temporary SSH keys.

```bash
packer init .
packer fmt -check .
packer validate -var-file=example.pkrvars.hcl .
packer build -var-file=example.pkrvars.hcl .
```

Read the resulting AMI ID from `manifest.json` and place it in the OpenTofu
environment tfvars. The Packer builder itself can incur a small temporary EC2
and EBS charge if the account is not covered by free-tier or credits.

Application-owned images can be added to `preload_images`, but image releases
normally continue through the S3/EICE deployment pipeline rather than requiring
a new AMI for every application change.
