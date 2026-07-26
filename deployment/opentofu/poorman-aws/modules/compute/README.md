# Golden Mammoth compute

An ASG maintains exactly one private EC2 instance. The root disk is disposable;
the separate data volume is attached by lifecycle automation. The AMI must
already contain Docker Engine, the Compose plugin, XFS tools, AWS CLI, and the
application's OS-level dependencies.

User data only performs instance-specific work: wait for the persistent volume,
format it once, mount it, create data directories, and register the Compose
systemd unit.
