# EBS Ballerina

EventBridge forwards the ASG's initial launch lifecycle action to Lambda. Lambda
attaches the identity volume, records lifecycle heartbeats while waiting, and
continues the launch only after attachment succeeds.

It refuses to detach the volume from a running instance. This intentionally
prefers an outage over two PostgreSQL hosts believing they own the same disk.
The ASG hook abandons a launch that cannot attach safely.
